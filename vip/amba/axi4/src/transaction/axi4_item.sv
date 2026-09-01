// =============================================================================
// File Name   : axi4_item.sv
// Description : AXI4 事务类（REQ-0106/0107）
//               - axi4_item：字段分类（request/response/observation/derived）
//               - axi4_payload_store：事务负载暂存（gapped 写数据、交织重建）
//               - axi4_master_item / axi4_slave_item
// VLNV        : aixsilicon:vip:axi4:1.0.0
// =============================================================================

`ifndef AXI4_ITEM__SV
`define AXI4_ITEM__SV

class axi4_item extends uvm_sequence_item;

  // ===========================================================================
  // Request Fields（REQ-0106）
  // ===========================================================================
  rand axi4_access_type   access_type;
  rand axi4_id            id;
  rand axi4_address       address;
  rand int                burst_length;
  rand int                burst_size;
  rand axi4_burst_type    burst_type;
  rand axi4_memory_type   memory_type;
  rand axi4_protection    protection;
  rand axi4_qos           qos;
  rand axi4_region        region;
  rand axi4_lock_type     lock;
  rand axi4_data          data[];
  rand axi4_strobe        strobe[];

  // ===========================================================================
  // Response Fields
  // ===========================================================================
  rand axi4_response      response[];
  rand bit                has_response;

  // ===========================================================================
  // Observation Fields
  // ===========================================================================
  time start_time;
  time end_time;
  time address_time;
  time write_data_end_time;
  time response_time;

  // ===========================================================================
  // Derived Fields（REQ-0106）
  // ===========================================================================
  axi4_address effective_address;
  int          total_bytes;
  bit          aligned;
  bit          boundary_crossing;

  // ===========================================================================
  // Timing / Delay（受配置约束；用于 driver 与 slave 响应）
  // ===========================================================================
  rand int start_delay;
  rand int address_ready_delay;
  rand int write_data_ready_delay[];
  rand int response_start_delay;
  rand int response_delay[];

  // ===========================================================================
  // 内部状态（事件：address/write_data/response 的 begin/end）
  // ===========================================================================
  protected bit  address_began;
  protected bit  address_ended;
  protected bit  write_data_began;
  protected bit  write_data_ended;
  protected bit  response_began;
  protected bit  response_ended;

  // ===========================================================================
  // 约束
  // ===========================================================================

  constraint c_default_burst {
    soft burst_length == 1;
    soft burst_size   == 4;
    soft burst_type   == AXI4_INCREMENTING_BURST;
    soft lock         == AXI4_NORMAL_LOCK;
    soft memory_type  == AXI4_NORMAL_NON_CACHEABLE_BUFFERABLE;
    soft has_response == 1;
  }

  // 数据/strobe 数组长度与 burst_length 一致
  constraint c_data_length {
    data.size()   == burst_length;
    strobe.size() == burst_length;
  }

  // 响应数组长度与 burst_length 一致
  constraint c_response_length {
    response.size() == (has_response ? burst_length : 0);
  }

  function new(string name = "axi4_item");
    super.new(name);
    access_type       = AXI4_WRITE_ACCESS;
    id                = '0;
    address           = '0;
    burst_length      = 1;
    burst_size        = 4;
    burst_type        = AXI4_INCREMENTING_BURST;
    memory_type       = AXI4_NORMAL_NON_CACHEABLE_BUFFERABLE;
    protection        = '0;
    qos               = '0;
    region            = '0;
    lock              = AXI4_NORMAL_LOCK;
    data              = new[1];
    strobe            = new[1];
    response          = new[0];
    has_response      = 1;
    start_delay       = 0;
    address_ready_delay = 0;
    response_start_delay = 0;
    start_time        = 0;
    end_time          = 0;
  endfunction

  // ===========================================================================
  // 辅助谓词
  // ===========================================================================
  function bit is_read();
    return (access_type == AXI4_READ_ACCESS);
  endfunction

  function bit is_write();
    return (access_type == AXI4_WRITE_ACCESS);
  endfunction

  function int get_burst_length();
    return burst_length;
  endfunction

  function int get_burst_size();
    return burst_size;
  endfunction

  // ===========================================================================
  // 事务辅助函数（REQ-0107，统一语义计算层）
  // ===========================================================================

  // 是否对齐（地址相对传输大小）
  function bit is_aligned();
    return (address % burst_size) == 0;
  endfunction

  // 有效传输字节（address 低 bit 决定首拍有效 lane）
  function int get_transfer_size();
    return burst_size;
  endfunction

  // 首拍有效起始 byte lane（相对总线）
  function int get_start_byte_lane(int data_bytes);
    return int'(address % data_bytes);
  endfunction

  // 支付大小（总字节数）
  function int get_payload_size();
    return burst_length * burst_size;
  endfunction

  // 事务长度（beats）
  function int get_transaction_length();
    return burst_length;
  endfunction

  // 第 index beat 的实际字节地址
  function axi4_address get_beat_address(int index);
    return axi4_types_pkg::get_beat_address(
      address, index, burst_type, burst_length, burst_size
    );
  endfunction

  // 第 index beat 的起始 byte lane
  function int get_byte_lane(int index, int data_bytes);
    return axi4_types_pkg::get_byte_lane_index(get_beat_address(index), data_bytes);
  endfunction

  // 是否跨越 4KB 边界
  function bit check_boundary();
    return axi4_types_pkg::is_crossing_4kb(address, burst_length, burst_size);
  endfunction

  // 派生字段计算（事务完成后调用）
  function void derive_fields(int data_bytes);
    effective_address = address;
    total_bytes       = get_payload_size();
    aligned           = is_aligned();
    boundary_crossing = check_boundary();
  endfunction

  // ===========================================================================
  // begin/end 事件管理（供 driver/monitor 记录时序）
  // ===========================================================================
  function void begin_address();
    address_began = 1;
    address_time  = $time;
  endfunction

  function void end_address();
    address_ended = 1;
    address_time  = $time;
  endfunction

  function void begin_write_data();
    write_data_began = 1;
  endfunction

  function void end_write_data();
    write_data_ended = 1;
    write_data_end_time = $time;
  endfunction

  function void begin_response();
    response_began = 1;
  endfunction

  function void end_response();
    response_ended = 1;
    response_time  = $time;
    end_time       = $time;
    if (start_time == 0) begin
      start_time = response_time;
    end
  endfunction

  function bit is_write_data_began();
    return write_data_began;
  endfunction

  function bit response_ended_status();
    return response_ended;
  endfunction

  // ===========================================================================
  // 字段级 compare policy（REQ-0106；不使用裸 uvm_object::compare）
  // ===========================================================================
  function bit axi4_compare(axi4_item rhs, bit compare_response = 1);
    if (rhs == null) begin
      return 0;
    end
    if (access_type != rhs.access_type) return 0;
    if (id          != rhs.id)          return 0;
    if (address     != rhs.address)     return 0;
    if (burst_length != rhs.burst_length) return 0;
    if (burst_size  != rhs.burst_size)  return 0;
    if (burst_type  != rhs.burst_type)  return 0;
    if (memory_type != rhs.memory_type) return 0;
    if (protection  != rhs.protection)  return 0;
    if (qos         != rhs.qos)         return 0;
    if (region      != rhs.region)      return 0;
    if (lock        != rhs.lock)        return 0;
    if (data.size() != rhs.data.size()) return 0;
    foreach (data[i]) begin
      if (data[i] != rhs.data[i]) return 0;
    end
    if (compare_response) begin
      if (response.size() != rhs.response.size()) return 0;
      foreach (response[i]) begin
        if (response[i] != rhs.response[i]) return 0;
      end
    end
    return 1;
  endfunction

  // ===========================================================================
  // UVM
  // ===========================================================================
  virtual function string convert2string();
    string s;
    s = $sformatf(
      "type=%s id=%0d addr=0x%0h len=%0d size=%0d burst=%s mem=%s prot=%b qos=%0d region=%0d lock=%s strobe=%p",
      (is_read() ? "READ" : "WRITE"), id, address, burst_length, burst_size,
      burst_type.name(), memory_type.name(), protection, qos, region, lock.name(),
      strobe
    );
    return s;
  endfunction

  virtual function void do_print(uvm_printer printer);
    super.do_print(printer);
    printer.print_string("access_type", (is_read() ? "READ" : "WRITE"));
    printer.print_field_int("id", id, $bits(axi4_id));
    printer.print_field_int("address", address, $bits(axi4_address));
    printer.print_field_int("burst_length", burst_length, 8, UVM_DEC);
    printer.print_field_int("burst_size", burst_size, 8, UVM_DEC);
    printer.print_string("burst_type", burst_type.name());
    printer.print_string("memory_type", memory_type.name());
    printer.print_field_int("qos", qos, 4);
    printer.print_field_int("region", region, 4);
    printer.print_string("lock", lock.name());
    // data/strobe/response 数组信息由 convert2string() 提供
  endfunction

  `uvm_object_utils_begin(axi4_item)
    `uvm_field_enum(axi4_access_type, access_type, UVM_DEFAULT)
    `uvm_field_int(id, UVM_DEFAULT | UVM_HEX)
    `uvm_field_int(address, UVM_DEFAULT | UVM_HEX)
    `uvm_field_int(burst_length, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(burst_size, UVM_DEFAULT | UVM_DEC)
    `uvm_field_enum(axi4_burst_type, burst_type, UVM_DEFAULT)
    `uvm_field_enum(axi4_memory_type, memory_type, UVM_DEFAULT | UVM_NOCOMPARE)
    `uvm_field_int(protection, UVM_DEFAULT | UVM_BIN)
    `uvm_field_int(qos, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(region, UVM_DEFAULT | UVM_DEC)
    `uvm_field_enum(axi4_lock_type, lock, UVM_DEFAULT)
    `uvm_field_array_int(data, UVM_DEFAULT | UVM_HEX)
    `uvm_field_array_int(strobe, UVM_DEFAULT | UVM_HEX)
    `uvm_field_array_enum(axi4_response, response, UVM_DEFAULT)
    `uvm_field_int(has_response, UVM_DEFAULT | UVM_BIN)
  `uvm_object_utils_end

endclass : axi4_item


// =============================================================================
// Payload Store：事务负载暂存（支持 gapped 写数据、交织重建；REQ-026/027）
// =============================================================================
class axi4_payload_store extends uvm_object;

  axi4_item      item;
  axi4_data      data[$];
  axi4_strobe    strobe[$];
  axi4_response  response[$];

  `uvm_object_utils(axi4_payload_store)

  function new(string name = "axi4_payload_store");
    super.new(name);
  endfunction


  function void store_write_data(axi4_data d, axi4_strobe s);
    data.push_back(d);
    strobe.push_back(s);
  endfunction

  function void store_response(axi4_response r, axi4_data d);
    response.push_back(r);
    data.push_back(d);
  endfunction

  // 将暂存数据写回 item（供 slave driver / monitor 完成重建）
  function void commit_to_item();
    if (item != null) begin
      if (data.size() > 0) begin
        item.data   = new[data.size()];
        item.strobe = new[strobe.size()];
        foreach (data[i]) begin
          item.data[i] = data[i];
        end
        foreach (strobe[i]) begin
          item.strobe[i] = strobe[i];
        end
      end
      if (response.size() > 0) begin
        item.response = new[response.size()];
        foreach (response[i]) begin
          item.response[i] = response[i];
        end
      end
    end
  endfunction

endclass : axi4_payload_store


// =============================================================================
// Master Item
// =============================================================================
class axi4_master_item extends axi4_item;

  constraint c_master_legal {
    soft id        == 0;
  }

  function new(string name = "axi4_master_item");
    super.new(name);
  endfunction

  `uvm_object_utils(axi4_master_item)

endclass : axi4_master_item


// =============================================================================
// Slave Item（Slave 侧响应事务：含响应状态/数据/延迟，供 slave driver 执行）
// =============================================================================
class axi4_slave_item extends axi4_item;

  rand axi4_response slave_response[];
  rand bit           respond;

  constraint c_slave_response_length {
    slave_response.size() == (respond ? burst_length : 0);
  }

  constraint c_default_slave {
    soft respond == 1;
  }

  function new(string name = "axi4_slave_item");
    super.new(name);
    slave_response = new[0];
    respond        = 1;
  endfunction

  `uvm_object_utils_begin(axi4_slave_item)
    `uvm_field_array_enum(axi4_response, slave_response, UVM_DEFAULT)
    `uvm_field_int(respond, UVM_DEFAULT | UVM_BIN)
  `uvm_object_utils_end

endclass : axi4_slave_item

`endif // AXI4_ITEM__SV
