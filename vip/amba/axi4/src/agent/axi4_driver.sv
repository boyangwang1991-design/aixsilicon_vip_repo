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

  // ===========================================================================
  // 注入钩子（RUL-005/011/017 负向能力；默认关闭，由 negative test 置位）
  //   inject_early_wlast     : 最后第 2 拍就拉 WLAST（burst 缩短 → RUL-017/SVA）
  //   inject_missing_wlast   : 末拍不拉 WLAST（RUL-005/SVA）
  //   inject_unstable_payload: W 数据在等待 READY 期间翻转（RUL-011/SVA）
  // ===========================================================================
  bit inject_early_wlast;
  bit inject_missing_wlast;
  bit inject_unstable_payload;

  // ===========================================================================
  // AW/W 解耦驱动形态（PRO-019）：
  //   0 = AW before W（默认，AXI 常规顺序）
  //   1 = W before AW（数据先于地址；验证 slave/monitor 的解耦重建）
  // ===========================================================================
  bit decouple_w_before_aw;

  // ===========================================================================
  // outstanding 读（PRO-008 完整并发）：
  //   async_read = 1 时读请求阶段完成即 item_done，R 由后台线程按 per-ID FIFO
  //   收取并回填 item（sequence 不依赖同步 rdata；多 ID 可交织）。
  //   默认 0（同步读，现有 sequence 兼容）。
  // ===========================================================================
  bit async_read;

  protected axi4_master_item outstanding_rd[axi4_id][$];

  `uvm_component_utils(axi4_master_driver)

  function new(string name = "axi4_master_driver", uvm_component parent = null);
    super.new(name, parent);
    inject_early_wlast      = 0;
    inject_missing_wlast    = 0;
    inject_unstable_payload = 0;
    decouple_w_before_aw    = 0;
    async_read              = 0;
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
    // 先同步到 clocking 沿：确保 AW/AR valid（output #1）先写入接口，
    // 下一沿 slave（input #1step）才能采样到；否则 master 在同沿采样到
    // READY=1 立即完成握手并撤 valid，slave 因 skew 永远采不到（握手错位）。
    @(vif.master_cb);
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
      // M1/RUL-001 负向：VALID 提前撤销（stall 一拍后拉低 ARVALID 再重试，
      // SVA a_arvalid_stable 应检出；之后恢复正常握手完成本笔读）
      if (item.inject_valid_drop) begin
        @(vif.master_cb);
        if (!(vif.master_cb.arready === 1'b1)) begin
          vif.master_cb.arvalid <= 0;   // 未握手即撤销 → RUL-001 违规
          @(vif.master_cb);
          vif.master_cb.arvalid <= 1;   // 恢复（本注入只制造一次违规）
          `uvm_info(get_type_name(),
            $sformatf("VALID_DROP injected @addr=0x%0h（ARVALID 提前撤销）",
                      item.address), UVM_LOW)
        end
      end
      do @(vif.master_cb); while (!(vif.master_cb.arready === 1'b1));
      item.begin_address();
      vif.master_cb.arvalid <= 0;
    end
  endtask

  protected task drive_write_data(axi4_master_item item);
    bit do_early_wlast;
    bit do_unstable;
    bit do_missing_wlast;
    // clocking output 付值必须先同步到 clocking event（AW-first 路径由
    // drive_address 的 @(master_cb) 提供同步；decouple 的 W-first 路径
    // 此处是 item 处理入口，无同步则首次付值落非法窗口被丢弃 → C3 丢 W）
    @(vif.master_cb);
    vif.master_cb.wvalid <= 0;
    // 注入钩子：item 级优先（per-transaction，sequence 可独立控制注入），
    // 回退 driver 全局 bit（负面 test 批量注入时仍可用）。
    do_early_wlast   = inject_early_wlast   | item.inject_early_wlast;
    do_unstable      = inject_unstable_payload | item.inject_unstable_payload;
    do_missing_wlast = inject_missing_wlast | item.inject_missing_wlast;
    if (item.is_write()) begin
      for (int i = 0; i < item.burst_length; i++) begin
        if (cfg.write_data_delay.get_delay() > 0) begin
          vif.master_cb.wvalid <= 0;
          repeat (cfg.write_data_delay.get_delay()) @(vif.master_cb);
        end
        vif.master_cb.wvalid <= 1;
        vif.master_cb.wdata  <= (i < item.data.size())   ? item.data[i]   : '0;
        vif.master_cb.wstrb  <= (i < item.strobe.size()) ? item.strobe[i] : '1;
        // WLAST 判定（注入钩子，默认合法：仅末拍拉 WLAST）
        // early-WLAST 语义：第 2 拍（index 1）就拉 WLAST 并终止 burst → 实际
        // 发 2 beat（len>=4 时）而非"倒数第 2 拍"（len=4 时 index=2 已发 3 拍）。
        if (do_early_wlast && (i == 1)) begin
          // RUL-017/RUL-005 负向：第 2 拍提前拉 WLAST 并终止 burst（缩短为 2 beat）
          vif.master_cb.wlast <= 1;
          do @(vif.master_cb); while (!(vif.master_cb.wready === 1'b1));
          vif.master_cb.wvalid <= 0;
          vif.master_cb.wlast  <= 0;
          `uvm_info(get_type_name(),
            $sformatf("EARLY_WLAST injected @addr=0x%0h len=%0d → 实际 2 beat 后 WLAST（缩短）",
                      item.address, item.burst_length), UVM_LOW)
          item.end_write_data();
          return;
        end
        else if (do_missing_wlast && (i == item.burst_length - 1)) begin
          // RUL-005 负向：末拍缺失 WLAST
          vif.master_cb.wlast <= 0;
          `uvm_info(get_type_name(),
            $sformatf("MISSING_WLAST injected @addr=0x%0h（末拍缺失 WLAST）",
                      item.address), UVM_LOW)
        end
        else begin
          vif.master_cb.wlast <= (i == item.burst_length - 1);
        end
        // RUL-011 负向：等待 READY 期间翻转 payload。
        // 确定性语义：持续等待 stall 拍（wready=0），**本拍（stall 采样沿）立即
        // 翻转 wdata/wstrb**——SVA `(wvalid && !wready) |=> (payload != $past)`
        // 前因是 stall 拍，而翻转须紧随其后；在 stall 采样沿后的付值窗口内
        // 翻转，使 T+1 检查捕获变化（T 为 stall 前因拍）。
        if (do_unstable) begin
          fork
            begin
              forever begin
                @(vif.master_cb);
                if (!(vif.master_cb.wready === 1'b1)) begin
                  // stall 拍到：立即翻转 payload（付值窗口，本沿后生效）
                  `uvm_info(get_type_name(),
                    $sformatf("RUL011_STALL hit @beat=%0d addr=0x%0h wready=0 → flip wdata/wstrb",
                              i, item.address), UVM_LOW)
                  vif.master_cb.wdata <= ~item.data[i];
                  vif.master_cb.wstrb <= ~item.strobe[i];
                  break;
                end
              end
            end
          join_none
        end
        do @(vif.master_cb); while (!(vif.master_cb.wready === 1'b1));
        disable fork;
        disable fork;
      end
      vif.master_cb.wvalid <= 0;
      vif.master_cb.wlast  <= 0;
      item.end_write_data();
    end
  endtask

  protected task receive_write_response(axi4_master_item item);
    axi4_response resp[$];
    bit           done_b;
    vif.master_cb.bready <= 1;
    done_b = 0;
    fork
      begin : b_rx
        while (!done_b) begin
          @(vif.master_cb);
          if (vif.master_cb.bvalid === 1'b1) begin
            resp.push_back(vif.master_cb.bresp);
            if (vif.master_cb.bid == item.id) begin
              done_b = 1;
            end
          end
        end
      end
      begin : b_to
        // 修复：enable_timeout=0 时本分支不得立即完成（否则 join_any 提前返回、
        // B 响应未等到、resp.size()==0）。禁用超时则与接收分支同步等待。
        if (cfg.enable_timeout) begin
          repeat (cfg.timeout_cycles) @(vif.master_cb);
          if (!done_b) begin
            `uvm_error(get_type_name(), $sformatf("B 响应超时 (id=%0d)", item.id))
            if (status != null) status.incr_timeout();
            done_b = 1;
          end
        end
        else begin
          while (!done_b) @(vif.master_cb);
        end
      end
    join_any
    disable fork;
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
    done = 0;
    fork
      begin : r_rx
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
      begin : r_to
        // 修复：enable_timeout=0 时本分支不得立即完成（否则 join_any 提前返回、
        // R 响应未等到、rdata.size()==0）。禁用超时则与接收分支同步等待。
        if (cfg.enable_timeout) begin
          repeat (cfg.timeout_cycles) @(vif.master_cb);
          if (!done) begin
            `uvm_error(get_type_name(), $sformatf("R 响应超时 (id=%0d)", item.id))
            if (status != null) status.incr_timeout();
            done = 1;
          end
        end
        else begin
          while (!done) @(vif.master_cb);
        end
      end
    join_any
    disable fork;
    item.response = new[resp.size()];
    item.data     = new[rdata.size()];
    foreach (resp[i])  item.response[i] = resp[i];
    foreach (rdata[i]) item.data[i]     = rdata[i];
    item.has_response = 1;
    item.end_response();
  endtask

  // ===========================================================================
  // 写响应后台线程（PRO-007 outstanding 写）：按 FIFO 顺序收取 B 并配对队头。
  // 主线程发完 AW+W 即 item_done → 多笔写可同时在途（B 延迟不阻塞新写）。
  // ===========================================================================
  protected axi4_master_item outstanding_wr[$];

  protected task write_response_thread();
    axi4_master_item wr;
    axi4_response resp[$];
    bit done_b;
    forever begin
      if (outstanding_wr.size() == 0) begin
        @(vif.master_cb);
        continue;
      end
      wr = outstanding_wr[0];
      resp.delete();
      done_b = 0;
      while (!done_b) begin
        @(vif.master_cb);
        if (vif.master_cb.bvalid === 1'b1) begin
          resp.push_back(vif.master_cb.bresp);
          if (vif.master_cb.bid == wr.id) begin
            done_b = 1;
          end
        end
      end
      wr.response    = new[resp.size()];
      foreach (resp[i]) wr.response[i] = resp[i];
      wr.has_response = 1;
      wr.end_response();
      void'(outstanding_wr.pop_front());
    end
  endtask

  // ===========================================================================
  // 读响应后台线程（PRO-008 outstanding 读 / async_read=1）：
  //   任一 ID 的 R 拍到达时，按 per-ID FIFO 找到最早的未完成 read context 回填。
  //   R 数据（含 RLAST）按 monitor 相同语义重建：rid 匹配 + RLAST 结束。
  // ===========================================================================
  // async 读的单笔 R 收集进程：与 receive_read_response 相同的 master_cb 采样
  // 结构（同步读已验证可靠），由主循环在 AR 完成时 fork（C2 写 outstanding
  // 的 join_none 同款模式）；收集完 RLAST 后回填 item。
  protected task async_read_collect(axi4_master_item item);
    axi4_response resp[$];
    axi4_data rdata[$];
    bit done;
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
    fork
      write_response_thread();
    join_none
    forever begin
      axi4_master_item item;
      seq_item_port.get_next_item(item);
      if (item.is_write()) begin
        if (decouple_w_before_aw) begin
          // PRO-019：W before AW 形态——数据先于地址（解耦重建验证）
          drive_write_data(item);
          drive_address(item);
        end
        else begin
          drive_address(item);
          drive_write_data(item);
        end
        // 写：请求阶段完成即 item_done，B 由后台线程收取（outstanding 并发）
        outstanding_wr.push_back(item);
        item.has_response = 0;
        seq_item_port.item_done();
      end
      else begin
        drive_address(item);
        if (async_read) begin
          // outstanding 读（PRO-008）：AR 完成即 item_done，R 由本 item 的
          // 独立收集进程回填（fork join_none，C2 写 outstanding 同款模式）
          item.has_response = 0;
          fork
            async_read_collect(item);
          join_none
          seq_item_port.item_done();
        end
        else begin
          // 同步读（默认，现有 sequence 兼容）
          receive_read_response(item);
          seq_item_port.item_done();
        end
      end
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

  // ===========================================================================
  // 响应注入钩子（G4/FI-013；默认关）：
  //   inject_illegal_resp_b: B 通道发非法编码（RUL-010 检出）
  //   inject_illegal_resp_r: R 通道发非法编码（RUL-010 检出）
  // ===========================================================================
  bit inject_illegal_resp_b;
  bit inject_illegal_resp_r;

  `uvm_component_utils(axi4_slave_driver)

  function new(string name = "axi4_slave_driver", uvm_component parent = null);
    super.new(name, parent);
    inject_illegal_resp_b = 0;
    inject_illegal_resp_r = 0;
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

  // ===========================================================================
  // 背压（PRO-009）：按 ready_delay 配置周期性拉低 READY（请求通道背压）
  // 全部未启用时不启动（默认合法路径不受影响）
  // ===========================================================================
  protected task backpressure_proc();
    if (!cfg.awready_delay.enabled && !cfg.wready_delay.enabled &&
        !cfg.arready_delay.enabled) begin
      return;
    end
    fork
      forever begin
        if (cfg.awready_delay.enabled) begin
          repeat (cfg.awready_delay.get_delay()) vif.slave_cb.awready <= 0;
          vif.slave_cb.awready <= 1;
        end
        if (cfg.wready_delay.enabled) begin
          // 跨时钟沿拉低：每拍保持 wready=0 达 delay 个沿后再恢复为 1。
          // 旧实现 `repeat(delay) <=0; <=1` 是 delta 循环无沿间隔，实际恒为 1。
          repeat (cfg.wready_delay.get_delay()) begin
            @(vif.slave_cb);
            vif.slave_cb.wready <= 0;
          end
          @(vif.slave_cb);
          vif.slave_cb.wready <= 1;
        end
        if (cfg.arready_delay.enabled) begin
          // 跨沿拉低（与 wready_delay 同款修复；delta 循环无沿间隔恒为 1）
          repeat (cfg.arready_delay.get_delay()) begin
            @(vif.slave_cb);
            vif.slave_cb.arready <= 0;
          end
          @(vif.slave_cb);
          vif.slave_cb.arready <= 1;
        end
        @(vif.slave_cb);
      end
    join_none
  endtask

  // ===========================================================================
  // 响应状态选择（response policy 子集：PRO-010 / RUL-010 注入钩子）
  // 按 response_weight_* 加权；默认全 OKAY（合法回归不受影响）
  // ===========================================================================
  protected function axi4_response pick_response_status();
    int total, pick;
    total = cfg.response_weight_okay + cfg.response_weight_exokay +
            cfg.response_weight_slave_error + cfg.response_weight_decode_error;
    if (total <= 0) begin
      return AXI4_OKAY;
    end
    pick = $urandom_range(0, total - 1);
    if (pick < cfg.response_weight_okay) return AXI4_OKAY;
    pick -= cfg.response_weight_okay;
    if (pick < cfg.response_weight_exokay) return AXI4_EXOKAY;
    pick -= cfg.response_weight_exokay;
    if (pick < cfg.response_weight_slave_error) return AXI4_SLAVE_ERROR;
    return AXI4_DECODE_ERROR;
  endfunction

  // ===========================================================================
  // W 预收队列（PRO-019 解耦）：后台线程持续吸收先于 AW 到达的 W 拍，
  // wait_for_write_request 优先从队列取（W before AW 数据不丢）
  // ===========================================================================
  protected axi4_data   w_pre_data[$];
  protected axi4_strobe w_pre_strb[$];

  protected task w_pre_collect_thread();
    // 仅采集"已握手"的 W 拍（wvalid && wready）：AXI 传输以两者同时为高为准。
    // 统一采样沿：用 @(posedge aclk) + 接口顶层信号（与 master 驱动的真实总线
    // 值对齐），避免 slave_cb(input #1step) 与 master_cb(output #1) 的沿错位
    // 导致 W-before-AW 预收漏采（P0-2/C3 修复）。
    forever begin
      @(posedge vif.aclk);
      if ((vif.wvalid === 1'b1) &&
          (vif.wready === 1'b1) &&
          !$isunknown(vif.wdata)) begin
        w_pre_data.push_back(vif.wdata);
        w_pre_strb.push_back(vif.wstrb);
      end
    end
  endtask

  // 等待写事务完整到达（AW + 全部 W 数据；支持 W-before-AW 预收）
  protected task wait_for_write_request(ref axi4_item item);
    axi4_payload_store store;
    axi4_payload_store wdata_store;
    axi4_data data[$];
    axi4_strobe strobe[$];
    bit done;
    axi4_item req;

    store = new;
    done = 0;
    // slave_cb（input #1step）采样：master output#1 驱动后的稳定值。
    // 注：P0-2 曾改 posedge+顶层——posedge 时刻 output#1 尚未更新（读到旧值），
    // M2 的 AW 恰逢相位错位漏采 → slave 不发 B（cover_b=0 证据）；已回退。
    // C3 的正确修复是 master 侧 drive_write_data 开头补 @(master_cb) 同步。
    while (!done) begin
      @(vif.slave_cb);
      if (vif.slave_cb.awvalid === 1'b1) begin
        // 采样 AW（req 在 task 顶部声明，避免 VCS 嵌套 block 声明解析问题）
        req = axi4_item::type_id::create("req");
        req.access_type = AXI4_WRITE_ACCESS;
        req.id           = vif.awid;
        req.address      = vif.awaddr;
        req.burst_length = unpack_burst_length(vif.awlen);
        req.burst_size   = unpack_burst_size(vif.awsize);
        req.burst_type   = vif.awburst;
        req.lock         = vif.awlock;
        req.memory_type  = decode_memory_type(vif.awcache, 0);
        req.protection   = vif.awprot;
        req.qos          = vif.awqos;
        req.region       = vif.awregion;
        req.data         = new[0];
        req.strobe       = new[0];
        item = req;
        // 消化预收队列（W-before-AW 已到数据）
        while ((data.size() < item.burst_length) && (w_pre_data.size() > 0)) begin
          data.push_back(w_pre_data.pop_front());
          strobe.push_back(w_pre_strb.pop_front());
        end
        // 采样其余 W 数据：预收队列优先（预收线程是唯一采集者，
        // 避免双采集竞争）；W 停发 16 拍 → 强制完成（缩短容错，
        // monitor 重建拍数与 awlen 不一致 → checker RUL-007 检出）
        begin
          int stall_cnt;
          stall_cnt = 0;
          while (data.size() < item.burst_length) begin
            if (w_pre_data.size() > 0) begin
              data.push_back(w_pre_data.pop_front());
              strobe.push_back(w_pre_strb.pop_front());
            end
            else begin
              @(vif.slave_cb);
              stall_cnt++;
              if (stall_cnt > 16) begin
                break;
              end
            end
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
  // ① 仅在 ARVALID && ARREADY 同拍握手时采样（AXI 传输语义）；旧实现只看
  //    arvalid，VALID 在 stall 拍提前撤销（RUL-001 注入）时 slave 会采到
  //    未完成握手的请求并提前发 R → 与 master 状态机失配死锁。
  // ② slave_cb（input #1step）采样：master output#1 驱动后的稳定值。
  protected task wait_for_read_request(ref axi4_item item);
    axi4_item req;
    forever begin
      @(vif.slave_cb);
      if ((vif.slave_cb.arvalid === 1'b1) &&
          (vif.arready === 1'b1)) begin
        `uvm_info(get_type_name(),
          $sformatf("SLAVE_AR sampled id=%0d addr=0x%0h t=%0t",
                    vif.slave_cb.arid, vif.slave_cb.araddr, $time), UVM_LOW)
        req = axi4_item::type_id::create("req");
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
    bit          do_write = 1;
    final_resp = resp_status;
    // 写路径核心：把 W 数据按 burst/WSTRB 写入 memory（REQ-0102/0111）。
    // 此前仅 exclusive 时调用 exclusive_write，普通写从未更新 memory → 读回全 0。
    if (memory != null) begin
      // exclusive 写：先判定独占状态（EXOKAY 才允许写数据）
      if (item.lock == AXI4_EXCLUSIVE_LOCK) begin
        final_resp = memory.exclusive_write(item.address);
        do_write   = (final_resp == AXI4_EXOKAY);
      end
      if (do_write) begin
        for (int i = 0; i < item.burst_length; i++) begin
          axi4_address beat_addr = axi4_types_pkg::get_beat_address(
            item.address, i, item.burst_type, item.burst_length, item.burst_size
          );
          axi4_data   beat_data = (i < item.data.size())   ? item.data[i]   : '0;
          axi4_strobe beat_stb  = (i < item.strobe.size()) ? item.strobe[i] : '1;
          memory.write_beat(beat_addr, item.burst_size, cfg.data_width / 8, beat_data, beat_stb);
        end
        // 非 exclusive 写使独占标记失效（REQ-RUL-016）
        if (item.lock != AXI4_EXCLUSIVE_LOCK) begin
          memory.clear_exclusive(item.address);
        end
      end
    end
    repeat (cfg.response_start_delay.get_delay()) @(vif.slave_cb);
    vif.slave_cb.bvalid <= 1;
    vif.slave_cb.bid    <= item.id;
    // FI-013 注入：非法响应编码（RUL-010；enum {OKAY=000,EXOKAY=001,SLVERR=010,
    // DECODE=011} → 3'b100 超出枚举域，为未定义非法编码）
    if (inject_illegal_resp_b) begin
      vif.slave_cb.bresp <= axi4_response'(3'b100);
      `uvm_info(get_type_name(),
        $sformatf("ILLEGAL_RESP_B injected @id=%0d（bresp=3'b100 非法编码）", item.id), UVM_LOW)
    end
    else begin
      vif.slave_cb.bresp <= final_resp;
    end
    do @(vif.slave_cb); while (!(vif.slave_cb.bready === 1'b1));
    vif.slave_cb.bvalid <= 0;
  endtask

  // 读响应：R 通道（可交织，REQ-009）
  protected task drive_read_response(axi4_item item, axi4_response resp_status);
    axi4_data rdata[];
    // 测试控制：suppress_r=1 时抑制 R 发送（构造 master R 超时窗口，
    // timeout 专项用；正常回归恒 0 不影响）
    if (vif.suppress_r === 1'b1) begin
      `uvm_info(get_type_name(),
        $sformatf("R suppressed (suppress_r=1) id=%0d addr=0x%0h — timeout window",
                  item.id, item.address), UVM_LOW)
      return;
    end
    if (memory != null) begin
      rdata = new[item.burst_length];
      // 逐 beat 按 burst_type 计算地址读取（INCR/WRAP/FIXED 均正确；
      // 原 read_burst 硬编码 INCR，WRAP/FIXED 读会错）
      for (int i = 0; i < item.burst_length; i++) begin
        axi4_address beat_addr = axi4_types_pkg::get_beat_address(
          item.address, i, item.burst_type, item.burst_length, item.burst_size
        );
        rdata[i] = memory.read_beat(beat_addr, item.burst_size, cfg.data_width / 8);
      end
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
      // FI-013 注入：R 通道非法响应编码（RUL-010；3'b101 超出枚举域）
      if (inject_illegal_resp_r) begin
        vif.slave_cb.rresp <= axi4_response'(3'b101);
        `uvm_info(get_type_name(),
          $sformatf("ILLEGAL_RESP_R injected @id=%0d beat=%0d（rresp=3'b101 非法编码）",
                    item.id, i), UVM_LOW)
      end
      else begin
        vif.slave_cb.rresp <= resp_status;
      end
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
    backpressure_proc();
    fork
      w_pre_collect_thread();
    join_none
    fork
      // 写路径：等 AW + W，发 B（resp status 按 policy 权重选择）
      begin
        forever begin
          wait_for_write_request(item);
          resp_status = pick_response_status();
          drive_write_response(item, resp_status);
        end
      end
      // 读路径：等 AR，发 R（resp status 按 policy 权重选择）
      begin
        forever begin
          wait_for_read_request(item);
          resp_status = pick_response_status();
          drive_read_response(item, resp_status);
        end
      end
    join
  endtask

endclass : axi4_slave_driver

`endif // AXI4_DRIVER__SV
