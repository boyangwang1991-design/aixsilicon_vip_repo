// =============================================================================
// File Name   : axi4_driver.sv
// Description : AXI4 Driver
//               - axi4_master_driver：驱动 AW/W/AR，接收 B/R（REQ-026）
//               - axi4_slave_driver ：接收 AW/W/AR，驱动 B/R（延迟/响应/排序）
// VLNV        : aixsilicon:vip:axi4:1.0.0
// =============================================================================

`ifndef AXI4_DRIVER__SV
`define AXI4_DRIVER__SV

// =============================================================================
// Master Driver
// =============================================================================
class axi4_master_driver extends uvm_driver #(axi4_master_item);

  virtual axi4_if   vif;
  axi4_configuration cfg;
  axi4_status        status;

  `uvm_component_utils(axi4_master_driver)

  function new(string name = "axi4_master_driver", uvm_component parent = null);
    super.new(name, parent);
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

  function void reset_signals();
    vif.master_cb.awvalid <= 0;
    vif.master_cb.awid    <= '0;
    vif.master_cb.awaddr  <= '0;
    vif.master_cb.awlen   <= '0;
    vif.master_cb.awsize  <= AXI4_BURST_SIZE_1_BYTE;
    vif.master_cb.awburst <= AXI4_FIXED_BURST;
    vif.master_cb.awlock  <= AXI4_NORMAL_LOCK;
    vif.master_cb.awcache <= '0;
    vif.master_cb.awprot  <= '0;
    vif.master_cb.awqos   <= '0;
    vif.master_cb.awregion<= '0;
    vif.master_cb.wvalid  <= 0;
    vif.master_cb.wdata   <= '0;
    vif.master_cb.wstrb   <= '0;
    vif.master_cb.wlast   <= 0;
    vif.master_cb.bready  <= cfg.default_bready;
    vif.master_cb.arvalid <= 0;
    vif.master_cb.arid    <= '0;
    vif.master_cb.araddr  <= '0;
    vif.master_cb.arlen   <= '0;
    vif.master_cb.arsize  <= AXI4_BURST_SIZE_1_BYTE;
    vif.master_cb.arburst <= AXI4_FIXED_BURST;
    vif.master_cb.arlock  <= AXI4_NORMAL_LOCK;
    vif.master_cb.arcache <= '0;
    vif.master_cb.arprot  <= '0;
    vif.master_cb.arqos   <= '0;
    vif.master_cb.arregion<= '0;
    vif.master_cb.rready  <= cfg.default_rready;
  endfunction

  protected task drive_address(axi4_master_item item);
    vif.master_cb.awvalid <= 0;
    vif.master_cb.arvalid <= 0;
    // 请求开始延迟（REQ-050）
    repeat (cfg.request_start_delay.get_delay()) @(vif.master_cb);
    if (item.is_write()) begin
      vif.master_cb.awvalid <= 1;
      vif.master_cb.awid    <= item.id;
      vif.master_cb.awaddr  <= item.address;
      vif.master_cb.awlen   <= pack_burst_length(item.burst_length);
      vif.master_cb.awsize  <= pack_burst_size(item.burst_size);
      vif.master_cb.awburst <= item.burst_type;
      vif.master_cb.awlock  <= item.lock;
      vif.master_cb.awcache <= encode_memory_type(item.memory_type, 0);
      vif.master_cb.awprot  <= item.protection;
      vif.master_cb.awqos   <= item.qos;
      vif.master_cb.awregion<= item.region;
      do @(vif.master_cb); while (!(vif.master_cb.awready === 1'b1));
      item.begin_address();
      vif.master_cb.awvalid <= 0;
    end
    else begin
      vif.master_cb.arvalid <= 1;
      vif.master_cb.arid    <= item.id;
      vif.master_cb.araddr  <= item.address;
      vif.master_cb.arlen   <= pack_burst_length(item.burst_length);
      vif.master_cb.arsize  <= pack_burst_size(item.burst_size);
      vif.master_cb.arburst <= item.burst_type;
      vif.master_cb.arlock  <= item.lock;
      vif.master_cb.arcache <= encode_memory_type(item.memory_type, 1);
      vif.master_cb.arprot  <= item.protection;
      vif.master_cb.arqos   <= item.qos;
      vif.master_cb.arregion<= item.region;
      do @(vif.master_cb); while (!(vif.master_cb.arready === 1'b1));
      item.begin_address();
      vif.master_cb.arvalid <= 0;
    end
  endtask

  protected task drive_write_data(axi4_master_item item);
    vif.master_cb.wvalid <= 0;
    if (item.is_write()) begin
      for (int i = 0; i < item.burst_length; i++) begin
        if (cfg.write_data_delay.get_delay() > 0) begin
          vif.master_cb.wvalid <= 0;
          repeat (cfg.write_data_delay.get_delay()) @(vif.master_cb);
        end
        vif.master_cb.wvalid <= 1;
        vif.master_cb.wdata  <= (i < item.data.size())   ? item.data[i]   : '0;
        vif.master_cb.wstrb  <= (i < item.strobe.size()) ? item.strobe[i] : '1;
        vif.master_cb.wlast  <= (i == item.burst_length - 1);
        do @(vif.master_cb); while (!(vif.master_cb.wready === 1'b1));
      end
      vif.master_cb.wvalid <= 0;
      vif.master_cb.wlast  <= 0;
      item.end_write_data();
    end
  endtask

  protected task receive_write_response(axi4_master_item item);
    axi4_response resp[$];
    vif.master_cb.bready <= 1;
    fork
      begin
        forever begin
          @(vif.master_cb);
          if (vif.master_cb.bvalid === 1'b1) begin
            resp.push_back(vif.master_cb.bresp);
            if (vif.master_cb.bid == item.id) begin
              break;
            end
          end
        end
      end
      begin
        if (cfg.enable_timeout) begin
          repeat (cfg.timeout_cycles) @(vif.master_cb);
          if (resp.size() == 0) begin
            `uvm_error(get_type_name(), $sformatf("B 响应超时 (id=%0d)", item.id))
            if (status != null) status.incr_timeout();
          end
          disable fork;
        end
      end
    join_any
    item.response = new[resp.size()];
    foreach (resp[i]) item.response[i] = resp[i];
    item.has_response = 1;
    item.end_response();
  endtask

  protected task receive_read_response(axi4_master_item item);
    axi4_response resp[$];
    axi4_data     rdata[$];
    bit           done;
    vif.master_cb.rready <= 1;
    fork
      begin
        done = 0;
        while (!done) begin
          @(vif.master_cb);
          if (vif.master_cb.rvalid === 1'b1) begin
            resp.push_back(vif.master_cb.rresp);
            rdata.push_back(vif.master_cb.rdata);
            if (vif.master_cb.rlast === 1'b1) begin
              done = 1;
            end
          end
        end
      end
      begin
        if (cfg.enable_timeout) begin
          repeat (cfg.timeout_cycles) @(vif.master_cb);
          if (!done) begin
            `uvm_error(get_type_name(), $sformatf("R 响应超时 (id=%0d)", item.id))
            if (status != null) status.incr_timeout();
          end
          disable fork;
        end
      end
    join_any
    item.response = new[resp.size()];
    item.data     = new[rdata.size()];
    foreach (resp[i])  item.response[i] = resp[i];
    foreach (rdata[i]) item.data[i]     = rdata[i];
    item.has_response = 1;
    item.end_response();
  endtask

  virtual task run_phase(uvm_phase phase);
    // 复位期间保持 VALID=0，等待复位释放后再驱动（REQ-018）
    reset_signals();
    @(posedge vif.aclk iff (vif.areset_n === 1'b1));
    forever begin
      axi4_master_item item;
      seq_item_port.get_next_item(item);
      drive_address(item);
      if (item.is_write()) begin
        drive_write_data(item);
        receive_write_response(item);
      end
      else begin
        receive_read_response(item);
      end
      seq_item_port.item_done();
    end
  endtask

endclass : axi4_master_driver


// =============================================================================
// Slave Driver（接收 AW/W/AR，驱动 B/R）
// =============================================================================
class axi4_slave_driver extends uvm_driver #(axi4_slave_item);

  virtual axi4_if   vif;
  axi4_configuration cfg;
  axi4_status        status;
  axi4_memory        memory;

  `uvm_component_utils(axi4_slave_driver)

  function new(string name = "axi4_slave_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(virtual axi4_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal(get_type_name(), "未找到 virtual axi4_if vif")
    end
    if (!uvm_config_db #(axi4_configuration)::get(this, "", "cfg", cfg)) begin
      `uvm_fatal(get_type_name(), "未找到 axi4_configuration cfg")
    end
    if (!uvm_config_db #(axi4_memory)::get(this, "", "memory", memory)) begin
      memory = null;
    end
  endfunction

  function void reset_signals();
    vif.slave_cb.awready <= cfg.default_awready;
    vif.slave_cb.wready  <= cfg.default_wready;
    vif.slave_cb.bvalid  <= 0;
    vif.slave_cb.bid     <= '0;
    vif.slave_cb.bresp   <= AXI4_OKAY;
    vif.slave_cb.arready <= cfg.default_arready;
    vif.slave_cb.rvalid  <= 0;
    vif.slave_cb.rid     <= '0;
    vif.slave_cb.rdata   <= '0;
    vif.slave_cb.rresp   <= AXI4_OKAY;
    vif.slave_cb.rlast   <= 0;
  endfunction

  // 等待写事务完整到达（AW + 全部 W 数据）
  protected task wait_for_write_request(ref axi4_item item);
    axi4_payload_store store;
    axi4_payload_store wdata_store;
    axi4_data data[$];
    axi4_strobe strobe[$];
    bit done;

    store = new;
    done = 0;
    while (!done) begin
      @(vif.slave_cb);
      if (vif.slave_cb.awvalid === 1'b1) begin
        // 采样 AW
        axi4_item req = axi4_item::type_id::create("req");
        req.access_type = AXI4_WRITE_ACCESS;
        req.id           = vif.slave_cb.awid;
        req.address      = vif.slave_cb.awaddr;
        req.burst_length = unpack_burst_length(vif.slave_cb.awlen);
        req.burst_size   = unpack_burst_size(vif.slave_cb.awsize);
        req.burst_type   = vif.slave_cb.awburst;
        req.lock         = vif.slave_cb.awlock;
        req.memory_type  = decode_memory_type(vif.slave_cb.awcache, 0);
        req.protection   = vif.slave_cb.awprot;
        req.qos          = vif.slave_cb.awqos;
        req.region       = vif.slave_cb.awregion;
        req.data         = new[0];
        req.strobe       = new[0];
        item = req;
        // 采样全部 W 数据
        while (data.size() < item.burst_length) begin
          @(vif.slave_cb);
          if (vif.slave_cb.wvalid === 1'b1) begin
            data.push_back(vif.slave_cb.wdata);
            strobe.push_back(vif.slave_cb.wstrb);
          end
        end
        item.data   = new[data.size()];
        item.strobe = new[strobe.size()];
        foreach (data[i])  item.data[i]   = data[i];
        foreach (strobe[i]) item.strobe[i] = strobe[i];
        item.end_write_data();
        done = 1;
      end
    end
  endtask

  // 等待读请求（AR）
  protected task wait_for_read_request(ref axi4_item item);
    forever begin
      @(vif.slave_cb);
      if (vif.slave_cb.arvalid === 1'b1) begin
        axi4_item req = axi4_item::type_id::create("req");
        req.access_type = AXI4_READ_ACCESS;
        req.id           = vif.slave_cb.arid;
        req.address      = vif.slave_cb.araddr;
        req.burst_length = unpack_burst_length(vif.slave_cb.arlen);
        req.burst_size   = unpack_burst_size(vif.slave_cb.arsize);
        req.burst_type   = vif.slave_cb.arburst;
        req.lock         = vif.slave_cb.arlock;
        req.memory_type  = decode_memory_type(vif.slave_cb.arcache, 1);
        req.protection   = vif.slave_cb.arprot;
        req.qos          = vif.slave_cb.arqos;
        req.region       = vif.slave_cb.arregion;
        item = req;
        return;
      end
    end
  endtask

  // 写响应：B 通道
  protected task drive_write_response(axi4_item item, axi4_response resp_status);
    axi4_response final_resp;
    final_resp = resp_status;
    // exclusive 写：若 memory 支持，返回 EXOKAY（REQ-0115）
    if ((item.lock == AXI4_EXCLUSIVE_LOCK) && (memory != null)) begin
      final_resp = memory.exclusive_write(item.address);
    end
    repeat (cfg.response_start_delay.get_delay()) @(vif.slave_cb);
    vif.slave_cb.bvalid <= 1;
    vif.slave_cb.bid    <= item.id;
    vif.slave_cb.bresp  <= final_resp;
    do @(vif.slave_cb); while (!(vif.slave_cb.bready === 1'b1));
    vif.slave_cb.bvalid <= 0;
  endtask

  // 读响应：R 通道（可交织，REQ-009）
  protected task drive_read_response(axi4_item item, axi4_response resp_status);
    axi4_data rdata[];
    if (memory != null) begin
      memory.read_burst(item.address, item.burst_length, item.burst_size,
                        cfg.data_width / 8, rdata);
      // exclusive 读：注册独占标记（REQ-0103）
      if (item.lock == AXI4_EXCLUSIVE_LOCK) begin
        memory.exclusive_read(item.address);
      end
    end
    repeat (cfg.response_start_delay.get_delay()) @(vif.slave_cb);
    for (int i = 0; i < item.burst_length; i++) begin
      vif.slave_cb.rvalid <= 1;
      vif.slave_cb.rid    <= item.id;
      vif.slave_cb.rdata  <= (memory != null) ? rdata[i] : '0;
      vif.slave_cb.rresp  <= resp_status;
      vif.slave_cb.rlast  <= (i == item.burst_length - 1);
      do @(vif.slave_cb); while (!(vif.slave_cb.rready === 1'b1));
    end
    vif.slave_cb.rvalid <= 0;
    vif.slave_cb.rlast  <= 0;
  endtask

  virtual task run_phase(uvm_phase phase);
    axi4_item item;
    axi4_response resp_status;
    reset_signals();
    @(posedge vif.aclk iff (vif.areset_n === 1'b1));
    fork
      // 写路径：等 AW + W，发 B
      begin
        forever begin
          wait_for_write_request(item);
          resp_status = AXI4_OKAY;
          drive_write_response(item, resp_status);
        end
      end
      // 读路径：等 AR，发 R
      begin
        forever begin
          wait_for_read_request(item);
          resp_status = AXI4_OKAY;
          drive_read_response(item, resp_status);
        end
      end
    join
  endtask

endclass : axi4_slave_driver

`endif // AXI4_DRIVER__SV
