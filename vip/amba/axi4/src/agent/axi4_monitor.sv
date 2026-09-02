// =============================================================================
// File Name   : axi4_monitor.sv
// Description : AXI4 Monitor（被动采样 → 事务重建 → transaction_ap）
//               - axi4_write_monitor：AW/W/B 通道重建写事务
//               - axi4_read_monitor ：AR/R 通道重建读事务
//               - axi4_slave_data_monitor：W 数据专项（更新 memory）
//               Monitor 只负责 Observe + Reconstruct，不做协议判断（交给 Checker/SVA）。
// VLNV        : aixsilicon:vip:axi4:1.0.0
// =============================================================================

`ifndef AXI4_MONITOR__SV
`define AXI4_MONITOR__SV

virtual class axi4_monitor_base extends uvm_monitor;

  virtual axi4_if   vif;
  axi4_configuration cfg;
  axi4_status        status;

  uvm_analysis_port #(axi4_item) transaction_ap;
  uvm_analysis_port #(axi4_item) request_item_port;
  uvm_analysis_port #(axi4_item) response_item_port;
  uvm_analysis_port #(axi4_item) error_ap;

  // 事务暂存（address 已握手、data/response 未完成的 item，按 ID 暂存）
  protected axi4_item address_stores[$];

  function new(string name = "axi4_monitor_base", uvm_component parent = null);
    super.new(name, parent);
    transaction_ap     = new("transaction_ap", this);
    request_item_port  = new("request_item_port", this);
    response_item_port = new("response_item_port", this);
    error_ap           = new("error_ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(virtual axi4_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal(get_type_name(), "未找到 virtual axi4_if vif")
    end
    if (!uvm_config_db #(axi4_configuration)::get(this, "", "cfg", cfg)) begin
      `uvm_fatal(get_type_name(), "未找到 axi4_configuration cfg")
    end
  endfunction

  // 供派生类定义：是否是写通道监控
  pure virtual function bit is_write_component();
  pure virtual function axi4_item create_monitor_item();
  pure virtual function string channel_name();

  // 按 ID 查找暂存 item
  protected function int find_address_store(axi4_id id);
    foreach (address_stores[i]) begin
      if (address_stores[i] != null && address_stores[i].id == id) begin
        return i;
      end
    end
    return -1;
  endfunction

endclass : axi4_monitor_base


// =============================================================================
// 写通道监控（AW/W/B）
// =============================================================================
virtual class axi4_write_monitor extends axi4_monitor_base;

  function new(string name = "axi4_write_monitor", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function bit is_write_component();
    return 1;
  endfunction

  function string channel_name();
    return "AW/W/B";
  endfunction

  function axi4_item create_monitor_item();
    axi4_item item = axi4_item::type_id::create("item");
    item.access_type = AXI4_WRITE_ACCESS;
    return item;
  endfunction

  // 采样地址通道（AWVALID && AWREADY）
  protected task sample_address();
    forever begin
      @(posedge vif.aclk);
      if (vif.awvalid && vif.awready && !$isunknown(vif.awaddr)) begin
        axi4_item item = create_monitor_item();
        item.id           = vif.awid;
        item.address      = vif.awaddr;
        item.burst_length = unpack_burst_length(vif.awlen);
        item.burst_size   = unpack_burst_size(vif.awsize);
        item.burst_type   = vif.awburst;
        item.memory_type  = decode_memory_type(vif.awcache, 0);
        item.protection   = vif.awprot;
        item.qos          = vif.awqos;
        item.region       = vif.awregion;
        item.lock         = vif.awlock;
        // data/strobe 初始为 burst_length 个 'x 占位；实际收到的 W beat 由
        // wdata_index_advance 逐个填充。early-WLAST/缩短注入时实际 beat 数
        // < burst_length（尾部仍为 'x），checker RUL-017 依非-'x 拍数对账。
        item.data         = new[item.burst_length];
        item.strobe       = new[item.burst_length];
        item.response     = new[0];
        item.begin_address();
        request_item_port.write(item);
        address_stores.push_back(item);   // 暂存等待 W 数据与 B 响应
      end
    end
  endtask

  // 采样写数据通道（WVALID && WREADY）
  // W 无 ID：依到达顺序归属下一笔"W 阶段未结束"的写事务。
  // early-WLAST/缩短时：WLAST 提前到达 → 该笔 data resize 为实际拍数并结束 W；
  // 后续 W 归属下一笔（跳过已结束项，但**不 delete**——store 项须保留至 B 匹配删除，
  // 否则 B 到达时 find_address_store 匹配失败 → orphan，事务丢失）。
  protected task sample_write_data();
    axi4_item item;
    int widx;
    forever begin
      @(posedge vif.aclk);
      if (vif.wvalid && vif.wready && !$isunknown(vif.wdata)) begin
        if (address_stores.size() == 0) begin
          continue;
        end
        // 找第一笔 W 阶段未结束的写事务（跳过已 WLAST 的，但保留在 store）
        item = null;
        foreach (address_stores[i]) begin
          if (address_stores[i] != null && !(address_stores[i].write_data_ended_status())) begin
            item = address_stores[i];
            break;
          end
        end
        if (item == null) begin
          // 所有事务 W 均已结束（合法 0 数据等异常）
          continue;
        end
        widx = wdata_index_advance(item);
        if (widx < 0 || widx >= item.burst_length) begin
          // 该笔已收满（合法 burst 完成）且未 WLAST：跳过，等待下一拍决策
          continue;
        end
        item.data[widx]   = vif.wdata;
        item.strobe[widx] = vif.wstrb;
        if (vif.wlast) begin
          item.wlast_seen = 1;   // RUL-005 检测依据（missing-WLAST 判定）
          // WLAST：该笔 W 阶段结束 → resize 到实际拍数（截掉尾部 'x）
          begin
            axi4_data dtmp[];
            axi4_strobe stmp[];
            dtmp = new[widx + 1];
            stmp = new[widx + 1];
            foreach (item.data[i]) begin
              if (i <= widx) begin
                dtmp[i] = item.data[i];
                stmp[i] = item.strobe[i];
              end
            end
            item.data   = dtmp;
            item.strobe = stmp;
          end
          item.end_write_data();
        end
        else if (widx == item.burst_length - 1) begin
          // 容错"收满即终"（P3-3b）：最后一拍已填但无 WLAST（missing-WLAST
          // 注入/协议违规）→ 立即结束该笔 W 阶段，后续 W 归属下一笔；
          // 缺失违规由 checker RUL-005 检测器依 wlast_seen==0 判定。
          item.end_write_data();
        end
      end
    end
  endtask

  protected function int wdata_index_advance(axi4_item item);
    // 返回下一个空闲 W 数据索引（0-based）；W 阶段已结束 → -1。
    // 容错"收满即终"（P3-3b）：数据收满 burst_length 而无 WLAST（missing-WLAST
    // 注入/协议违规）时，立即结束该笔 W 阶段——后续 W 归属下一笔（不连锁吞并）；
    // 缺 WLAST 本身由 checker RUL-005 检测器依 wlast_seen 标志判定。
    int idx;
    if (item == null || item.write_data_ended_status()) begin
      return -1;
    end
    idx = item.burst_length;
    foreach (item.data[i]) begin
      if (item.data[i] === 'x) begin
        idx = i;
        break;
      end
    end
    if (idx >= item.burst_length) begin
      // 收满但无 WLAST：容错收满即终（RUL-005 违规由 checker 判定）
      item.end_write_data();
      return -1;
    end
    return idx;
  endfunction

  // 采样写响应通道（BVALID && BREADY）
  protected task sample_response();
    forever begin
      @(posedge vif.aclk);
      if (vif.bvalid && vif.bready && !$isunknown(vif.bid)) begin
        int idx = find_address_store(vif.bid);
        `uvm_info(get_type_name(),
          $sformatf("B sampled bid=%0d stores=%0d idx=%0d t=%0t",
                    vif.bid, address_stores.size(), idx, $time), UVM_LOW)
        if (idx >= 0) begin
          axi4_item item = address_stores[idx];
          address_stores.delete(idx);
          item.has_response = 1;
          item.response = new[1];
          item.response[0] = vif.bresp;
          item.end_response();
          item.derive_fields(cfg.data_width / 8);
          transaction_ap.write(item);
          response_item_port.write(item);
        end
        else begin
          // 未匹配地址的事务（交织场景由 check 层处理）
          axi4_item orphan = create_monitor_item();
          orphan.id = vif.bid;
          orphan.has_response = 1;
          orphan.response = new[1];
          orphan.response[0] = vif.bresp;
          response_item_port.write(orphan);
        end
      end
    end
  endtask

  virtual task run_phase(uvm_phase phase);
    fork
      sample_address();
      sample_write_data();
      sample_response();
    join
  endtask

endclass : axi4_write_monitor


// =============================================================================
// 读通道监控（AR/R）
// =============================================================================
virtual class axi4_read_monitor extends axi4_monitor_base;

  function new(string name = "axi4_read_monitor", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function bit is_write_component();
    return 0;
  endfunction

  function string channel_name();
    return "AR/R";
  endfunction

  function axi4_item create_monitor_item();
    axi4_item item = axi4_item::type_id::create("item");
    item.access_type = AXI4_READ_ACCESS;
    return item;
  endfunction

  // 采样读地址通道（ARVALID && ARREADY）
  protected task sample_address();
    forever begin
      @(posedge vif.aclk);
      if (vif.arvalid && vif.arready && !$isunknown(vif.araddr)) begin
        axi4_item item = create_monitor_item();
        item.id           = vif.arid;
        item.address      = vif.araddr;
        item.burst_length = unpack_burst_length(vif.arlen);
        item.burst_size   = unpack_burst_size(vif.arsize);
        item.burst_type   = vif.arburst;
        item.memory_type  = decode_memory_type(vif.arcache, 1);
        item.protection   = vif.arprot;
        item.qos          = vif.arqos;
        item.region       = vif.arregion;
        item.lock         = vif.arlock;
        item.data         = new[item.burst_length];
        item.strobe       = new[item.burst_length];
        item.response     = new[0];
        item.begin_address();
        request_item_port.write(item);
        address_stores.push_back(item);   // 暂存等待 R 数据
      end
    end
  endtask

  // 采样读数据通道（RVALID && RREADY）
  protected task sample_response();
    forever begin
      @(posedge vif.aclk);
      if (vif.rvalid && vif.rready && !$isunknown(vif.rid)) begin
        int idx = find_address_store(vif.rid);
        if (idx >= 0) begin
          axi4_item item = address_stores[idx];
          // 追加读数据
          axi4_data rdata_queue[$];
          axi4_response rresp_queue[$];
          // 统计已接收 beat（RLAST 前）
          int beat = 0;
          foreach (item.data[i]) begin
            if (item.data[i] !== 'x) begin
              beat++;
            end
          end
          if (beat < item.burst_length) begin
            item.data[beat]   = vif.rdata;
            if (item.response.size() == 0) begin
              item.response = new[item.burst_length];
            end
            item.response[beat] = vif.rresp;
          end
          if (vif.rlast) begin
            address_stores.delete(idx);
            item.has_response = 1;
            item.end_response();
            item.derive_fields(cfg.data_width / 8);
            transaction_ap.write(item);
            response_item_port.write(item);
          end
        end
        else begin
          axi4_item orphan = create_monitor_item();
          orphan.id = vif.rid;
          orphan.has_response = 1;
          orphan.response = new[1];
          orphan.response[0] = vif.rresp;
          orphan.data = new[1];
          orphan.data[0] = vif.rdata;
          response_item_port.write(orphan);
        end
      end
    end
  endtask

  virtual task run_phase(uvm_phase phase);
    fork
      sample_address();
      sample_response();
    join
  endtask

endclass : axi4_read_monitor


// =============================================================================
// 具体监控类（master/slave 视角）
// =============================================================================
class axi4_master_write_monitor extends axi4_write_monitor;
  `uvm_component_utils(axi4_master_write_monitor)
  function new(string name = "axi4_master_write_monitor", uvm_component parent = null);
    super.new(name, parent);
  endfunction
endclass : axi4_master_write_monitor

class axi4_master_read_monitor extends axi4_read_monitor;
  `uvm_component_utils(axi4_master_read_monitor)
  function new(string name = "axi4_master_read_monitor", uvm_component parent = null);
    super.new(name, parent);
  endfunction
endclass : axi4_master_read_monitor

class axi4_slave_write_monitor extends axi4_write_monitor;
  `uvm_component_utils(axi4_slave_write_monitor)
  function new(string name = "axi4_slave_write_monitor", uvm_component parent = null);
    super.new(name, parent);
  endfunction
endclass : axi4_slave_write_monitor

class axi4_slave_read_monitor extends axi4_read_monitor;
  `uvm_component_utils(axi4_slave_read_monitor)
  function new(string name = "axi4_slave_read_monitor", uvm_component parent = null);
    super.new(name, parent);
  endfunction
endclass : axi4_slave_read_monitor


// =============================================================================
// Slave Data Monitor（W 数据专项：更新 memory，REQ-0102/0111）
// =============================================================================
class axi4_slave_data_monitor extends uvm_subscriber #(axi4_item);

  axi4_memory   memory;
  axi4_configuration cfg;

  `uvm_component_utils(axi4_slave_data_monitor)

  function new(string name = "axi4_slave_data_monitor", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(axi4_memory)::get(this, "", "memory", memory)) begin
      if (!uvm_config_db #(axi4_configuration)::get(this, "", "cfg", cfg)) begin
        `uvm_fatal(get_type_name(), "未找到 axi4_configuration cfg")
      end
      memory = axi4_memory::type_id::create("memory");
      memory.set_geometry(cfg.address_width, cfg.data_width, 1 << 16);
    end
  endfunction

  function void write(axi4_item t);
    // 仅处理写事务：将 W 数据按 beat 写入 memory（WSTRB 感知）
    if (t.is_write() && (t.data.size() > 0)) begin
      for (int i = 0; i < t.data.size(); i++) begin
        axi4_address beat_addr = t.get_beat_address(i);
        memory.write_beat(
          beat_addr,
          t.burst_size,
          cfg.data_width / 8,
          t.data[i],
          (i < t.strobe.size()) ? t.strobe[i] : '1
        );
      end
      // 普通写清除 exclusive 标记（REQ-0115）
      memory.clear_exclusive(t.address);
    end
  endfunction

endclass : axi4_slave_data_monitor

`endif // AXI4_MONITOR__SV
