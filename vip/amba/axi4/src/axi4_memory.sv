// =============================================================================
// File Name   : axi4_memory.sv
// Description : AXI4 Slave 存储镜像/行为模型（REQ-031 / §9.1）
//               - 支持 narrow / unaligned / partial（仅更新 WSTRB=1 的 byte）
//               - exclusive 独占标记与冲突检测（REQ-0103/0115）
//               - read/write/peek/poke/initialize/clear/load/partial update
// VLNV        : aixsilicon:vip:axi4:1.0.0
// =============================================================================

`ifndef AXI4_MEMORY__SV
`define AXI4_MEMORY__SV

class axi4_memory extends uvm_object;

  // 参数化：由配置驱动（通过 set_geometry 设置）
  protected int  address_width;
  protected int  data_width;
  protected int  strobe_width;
  protected int  memory_size;      // byte 数
  protected byte unsigned memory[];

  // ---- Exclusive 标记（REQ-0103/0115）----
  // 记录每个被独占读的地址：已注册 = 1（等待配对独占写）
  protected bit  exclusive_tagged[];
  protected bit  exclusive_support;

  function new(string name = "axi4_memory");
    super.new(name);
    address_width = 32;
    data_width    = 32;
    strobe_width  = 4;
    memory_size   = 1 << 16;       // 默认 64KB
    exclusive_support = 1;
    memory = new[memory_size];
    exclusive_tagged = new[memory_size];
  endfunction

  function void set_geometry(int addr_width, int data_w, int size);
    address_width = addr_width;
    data_width    = data_w;
    strobe_width  = data_w / 8;
    memory_size   = size;
    memory        = new[memory_size];
    exclusive_tagged = new[memory_size];
  endfunction

  function void set_exclusive_support(bit support);
    exclusive_support = support;
  endfunction

  // ---- 基础访问 ----
  function void initialize(byte unsigned init_val = 8'h0);
    foreach (memory[i]) begin
      memory[i] = init_val;
    end
  endfunction

  function void clear();
    initialize(8'h0);
  endfunction

  function void load_from_array(const ref byte unsigned data[], int offset = 0);
    for (int i = 0; (i < data.size()) && ((i + offset) < memory_size); i++) begin
      memory[i + offset] = data[i];
    end
  endfunction

  // peek / poke（直接访问，忽略 WSTRB/exclusive）
  function byte unsigned peek_byte(axi4_address address);
    return memory[address];
  endfunction

  function void poke_byte(axi4_address address, byte unsigned data);
    memory[address] = data;
  endfunction

  // ---- 事务级访问（narrow / unaligned / WSTRB / exclusive aware）----
  // 检查地址越界
  function bit is_valid_address(axi4_address address, int burst_length, int burst_size);
    return (address + (burst_length - 1) * burst_size) < memory_size;
  endfunction

  // 按 burst 读取：返回每个 beat 的 data（WSTRB 无关，读全宽）
  function void read_burst(
    axi4_address   base_address,
    int            burst_length,
    int            burst_size,
    int            data_bytes,
    ref axi4_data  data_out[]
  );
    data_out = new[burst_length];
    for (int i = 0; i < burst_length; i++) begin
      axi4_address beat_addr = get_beat_address(
        base_address, i, AXI4_INCREMENTING_BURST, burst_length, burst_size
      );
      data_out[i] = read_beat(beat_addr, burst_size, data_bytes);
    end
  endfunction

  // 读取单个 beat：从 beat_addr 读取 burst_size 字节（对齐到总线 lane 位置）
  // abs_addr = (beat_addr 对齐到总线宽) + global_byte —— unaligned beat 的
  // lane2/3 字节位于对齐基址+2/3，而非 beat_addr+2/3（unit test 抓出的缺陷）
  function axi4_data read_beat(axi4_address beat_addr, int burst_size, int data_bytes);
    axi4_data data = '0;
    int lane_shift = get_byte_lane_index(beat_addr, data_bytes);
    axi4_address base_addr = (beat_addr / data_bytes) * data_bytes;
    for (int b = 0; b < burst_size; b++) begin
      int global_byte = lane_shift + b;
      if (global_byte < data_bytes) begin
        axi4_address abs_addr = base_addr + global_byte;
        if (abs_addr < memory_size) begin
          data[global_byte*8 +: 8] = memory[abs_addr];
        end
      end
    end
    return data;
  endfunction

  // 写入单个 beat：仅更新 WSTRB=1 的 byte（REQ-0102/0111）
  // abs_addr 与 read_beat 同一公式（lane 语义对称，unit test 防回归）
  function void write_beat(
    axi4_address beat_addr,
    int          burst_size,
    int          data_bytes,
    axi4_data    data,
    axi4_strobe  strobe
  );
    int lane_shift = get_byte_lane_index(beat_addr, data_bytes);
    axi4_address base_addr = (beat_addr / data_bytes) * data_bytes;
    for (int b = 0; b < burst_size; b++) begin
      int global_byte = lane_shift + b;
      if ((global_byte < data_bytes) && (strobe[global_byte])) begin
        axi4_address abs_addr = base_addr + global_byte;
        if (abs_addr < memory_size) begin
          memory[abs_addr] = data[global_byte*8 +: 8];
        end
      end
    end
  endfunction

  // ---- Exclusive 语义（REQ-0103/0115）----
  // 独占读：注册独占标记
  function void exclusive_read(axi4_address address);
    if (exclusive_support && (address < memory_size)) begin
      exclusive_tagged[address] = 1;
    end
  endfunction

  // 独占写：返回 EXOKAY（标记存在且清除）或 OKAY（无标记/冲突）
  function axi4_response exclusive_write(axi4_address address);
    if (!exclusive_support || (address >= memory_size)) begin
      return AXI4_OKAY;
    end
    if (exclusive_tagged[address]) begin
      exclusive_tagged[address] = 0;
      return AXI4_EXOKAY;
    end
    return AXI4_OKAY;
  endfunction

  // 普通写/其他写者：清除独占标记
  function void clear_exclusive(axi4_address address);
    if (address < memory_size) begin
      exclusive_tagged[address] = 0;
    end
  endfunction

  function bit is_exclusive_tagged(axi4_address address);
    return (address < memory_size) && exclusive_tagged[address];
  endfunction

  `uvm_object_utils_begin(axi4_memory)
    `uvm_field_int(address_width, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(data_width, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(strobe_width, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(memory_size, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(exclusive_support, UVM_DEFAULT | UVM_BIN)
  `uvm_object_utils_end

endclass : axi4_memory

`endif // AXI4_MEMORY__SV
