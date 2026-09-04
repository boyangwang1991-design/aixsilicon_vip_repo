// =============================================================================
// File Name   : apb_slave_driver.sv
// Description : Completer driver——四层 responder（架构 §12.2）：
//               ① sequence responder（SEQUENCE_CONTROLLED）
//               ② memory responder（generic memory-backed，REQ §9）
//               ③ error responder（NEVER/RANDOM/ADDRESS_RANGE）
//               ④ wait policy（ZERO_WAIT/FIXED_WAIT/RANDOM_WAIT）
//               采样纪律（C-9）：输入采样经 slave_cb（#1step）；输出经 slave_cb
//               （skew #1）——ZERO_WAIT 即 PREADY 常高（RUL-010 合法实现）
// VLNV        : aixsilicon:vip:apb:1.0.0
// =============================================================================

`ifndef APB_SLAVE_DRIVER__SV
`define APB_SLAVE_DRIVER__SV

// ---------------------------------------------------------------------------
// callback（ERR-003 read-data override / 行为扩展）
// ---------------------------------------------------------------------------
class apb_slave_callback_base extends uvm_callback;
  `uvm_object_utils(apb_slave_callback_base)
  function new(string name = "apb_slave_callback_base");
    super.new(name);
  endfunction
  virtual function void post_response(apb_item it);
  endfunction
endclass

class apb_slave_driver extends uvm_driver #(apb_item);

  `uvm_component_utils(apb_slave_driver)

  virtual apb_if vif;
  apb_config     cfg;

  apb_item cur_req;      // 当前响应中事务
  int unsigned pend_wait;     // ④ wait policy 决策
  bit          pend_slverr;   // ③ error responder 决策

  // ② memory responder（关联数组稀疏存储；APB3 semantic default：全 lanes）
  bit [`APB_MAX_DATA_WIDTH-1:0] mem [logic [`APB_MAX_ADDR_WIDTH-1:0]];

  uvm_analysis_port #(apb_item) request_ap;   // 请求观察（可选消费）

  function new(string name, uvm_component parent);
    super.new(name, parent);
    request_ap = new("request_ap", this);
    pend_wait = 0;
    pend_slverr = 0;
  endfunction

  function void build_phase(uvm_phase phase_);
    super.build_phase(phase_);
    if (!uvm_config_db#(virtual apb_if)::get(this, "", "vif", vif))
      `uvm_fatal(get_type_name(), "virtual interface 'vif' not set")
    if (!uvm_config_db#(apb_config)::get(this, "", "config", cfg))
      `uvm_fatal(get_type_name(), "apb_config 'config' not set")
  endfunction

  virtual task run_phase(uvm_phase phase_);
    super.run_phase(phase_);
    drive_idle();
    forever begin
      fork
        begin : main_body
          main_loop();
        end
        begin : reset_watcher
          @(negedge vif.presetn);
          handle_reset();
        end
      join_any
      disable fork;
      wait (vif.presetn === 1'b1);
      drive_idle();
    end
  endtask

  // ---------------------------------------------------------------------------
  // 主循环：采样 SETUP（slave_cb，#1step）→ 决策 → ACCESS 驱动响应
  // ---------------------------------------------------------------------------
  task main_loop();
    forever begin
      // ZERO_WAIT 路径：PREADY 常高（RUL-010 合法——固定两周期 peripheral 语义）
      if (cfg.slave_response_mode == APB_ZERO_WAIT) begin
        vif.slave_cb.pready  <= 1'b1;
        vif.slave_cb.pslverr <= 1'b0;
        // P4 修复：ZERO_WAIT 下 PREADY 恒高，completion 与 ACCESS 首拍同沿，
        // DUT（如 x2p APB 引擎）在 (ACCESS && PREADY) 沿锁存 prdata——读数据
        // 必须在 DUT 的 ACCESS 采样沿**前**就绪。
        // 采样相位关键（C-9）：master 用 master_cb（output #1，沿后 1ns 生效）；
        // 若 slave 用 @(posedge)+顶层直读，在沿的 active 区域读到的是沿前旧值，
        // 识别 SETUP 的时刻恰好是 DUT 的 ACCESS 首拍，prdata 永远赶不上锁存。
        // 因此 ZERO_WAIT 分支必须用 slave_cb（input #1step，沿前采样）与 master_cb
        // 对齐：沿前识别 SETUP → 本沿立即预置 prdata（slave_cb output #1，沿后
        // 生效）→ DUT 下一沿（ACCESS 采样沿前 #1step）锁存到有效读数据。
        @(vif.slave_cb);
        if (vif.slave_cb.psel[0] === 1'b1) begin
          if (vif.slave_cb.penable === 1'b0) begin
            // SETUP 拍（沿前采样）：预置读数据 + 写合并（cur_req 上一笔已清）
            cur_req = null;
            build_observed_item();
          end
          else begin
            // completion 拍（零等待完成：psel&&penable&&pready 常高）：
            // 读数据已在 SETUP 拍预置（prdata 稳定）；无 SETUP 前导的容错路径
            // （FI-002 非法注入）兜底采样；完成后清 cur_req 供下一笔。
            if (cur_req == null) build_observed_item();
            cur_req = null;
          end
        end
        else begin
          cur_req = null;   // IDLE：清残留状态
        end
      end
      else begin
      // 非 ZERO_WAIT：PREADY 默认 0，SETUP 拍决策
      vif.slave_cb.pready  <= 1'b0;
      vif.slave_cb.pslverr <= 1'b0;
      @(posedge vif.pclk);
      // 容错：直接落入 ACCESS（FI-002 非法注入/无 SETUP 前导）——
      // cur_req 为空且 penable=1 时按当拍信号采样并完成响应（不当挂死）
      if (cur_req == null && vif.psel[0] === 1'b1 && vif.penable === 1'b1) begin
        build_observed_item();
        pend_wait   = 0;
        pend_slverr = decide_error(cur_req);
        if (cur_req.direction == APB_READ)
          vif.slave_cb.prdata <= rdata_view(read_mem(cur_req.addr));
        vif.slave_cb.pready  <= !vif.suppress_pready;
        vif.slave_cb.pslverr <= pend_slverr;
        @(posedge vif.pclk);
        drive_idle();
        cur_req = null;
        continue;
      end
      if (cur_req == null && vif.psel[0] === 1'b1 && vif.penable === 1'b0) begin
        // SETUP 拍：采样请求（RUL-010：此拍 PREADY 任意值合法，不判完成）
        build_observed_item();

        pend_wait   = decide_wait();
        pend_slverr = decide_error(cur_req);

        // ① SEQUENCE_CONTROLLED：item 直通（wait/slverr 由 item 指定）
        if (cfg.slave_error_mode == APB_ERR_SEQUENCE_CONTROLLED &&
            cfg.slave_response_mode == APB_SEQUENCE_CONTROLLED) begin
          seq_item_port.get_next_item(cur_req);
          pend_wait   = cur_req.requested_wait_cycles;
          pend_slverr = cur_req.slverr;
        end

        // ACCESS 相位（C-9 对齐）：沿后驱动下一拍值——
        // SETUP 拍沿已过：ACCESS 第 1..N 拍 pready=0（wait），第 N+1 拍 pready=1
        repeat (pend_wait) begin
          vif.slave_cb.pready  <= 1'b0;
          vif.slave_cb.pslverr <= 1'b0;      // RUL-005：非完成拍 REC 语义
          @(posedge vif.pclk);
        end
        // 本沿已过，决策 completion 值（下一拍沿前 NBA 生效）
        if (cur_req.direction == APB_READ)
          vif.slave_cb.prdata <= rdata_view(read_mem(cur_req.addr));
        vif.slave_cb.pready  <= !vif.suppress_pready;
        vif.slave_cb.pslverr <= pend_slverr;
        // completion 拍过去（master clocking 沿前采样到 pready=1）
        @(posedge vif.pclk);
        drive_idle();
        cur_req = null;
      end
    end
    end
  endtask

  // ---------------------------------------------------------------------------
  // SETUP/完成采样：组装观察 item（写合并 memory）
  // ---------------------------------------------------------------------------
  function void build_observed_item();
    apb_item it;
    if (cur_req != null) return;   // 非零等待已在 SETUP 采样
    it = apb_item::type_id::create("slave_req");
    it.cfg_addr_width = cfg.addr_width;
    it.cfg_data_width = cfg.data_width;
    it.direction = vif.pwrite ? APB_WRITE : APB_READ;
    it.addr      = vif.paddr;
    it.wdata     = vif.pwdata;
    // P4-深层修复：strb 必须从总线采样（此前 it.strb 恒 0 → write_mem mask
    // 全 0 → 写 memory 恒为 0，读回全 0。原实现只采样 direction/addr/wdata，
    // 漏了 pstrb；enable_strb=1 时 (cur & ~mask)|(wdata & mask)=0）。
    it.strb = '0;
    for (int b = 0; b < cfg.data_width/8; b++)
      it.strb[b] = vif.pstrb_w[b];
    it.start_time = $time;
    if (it.direction == APB_WRITE)
      write_mem(it);
    request_ap.write(it);
    cur_req = it;
    if (cfg.slave_response_mode == APB_ZERO_WAIT) begin
      // 零等待完成：读数据需在 completion 前 1 拍有效——读路径直接组合返回
      // （V1.0：ZERO_WAIT 读返回 memory 值或 0）
      if (it.direction == APB_READ)
        vif.slave_cb.prdata <= rdata_view(read_mem(it.addr));
    end
  endfunction

  // ---------------------------------------------------------------------------
  // ④ wait policy
  // ---------------------------------------------------------------------------
  function int unsigned decide_wait();
    case (cfg.slave_response_mode)
      APB_FIXED_WAIT:  return cfg.default_wait_cycles;
      APB_RANDOM_WAIT: return $urandom_range(0, cfg.max_wait_cycles);
      default:         return 0;
    endcase
  endfunction

  // ---------------------------------------------------------------------------
  // ③ error responder
  // ---------------------------------------------------------------------------
  function bit decide_error(apb_item it);
    case (cfg.slave_error_mode)
      APB_ERR_RANDOM:         return ($urandom_range(999) < int'(cfg.slave_err_prob * 1000.0));
      APB_ERR_ADDRESS_RANGE:  return in_error_region(it.addr);
      default:                return 1'b0;
    endcase
  endfunction

  function bit in_error_region(logic [`APB_MAX_ADDR_WIDTH-1:0] addr);
    foreach (cfg.slave_regions[i]) begin
      if (addr >= cfg.slave_regions[i].base && addr <= cfg.slave_regions[i].limit)
        return cfg.slave_regions[i].slverr;
    end
    return 1'b0;
  endfunction

  // ---------------------------------------------------------------------------
  // ② memory responder（strb 字节合并；APB3 全 lanes——TRN-006）
  // ---------------------------------------------------------------------------
  function bit [`APB_MAX_DATA_WIDTH-1:0] read_mem(logic [`APB_MAX_ADDR_WIDTH-1:0] addr);
    if (mem.exists(addr)) return mem[addr];
    return '0;   // 未命中 0（REQ §9）
  endfunction

  function void write_mem(apb_item it);
    logic [`APB_MAX_DATA_WIDTH-1:0] cur;
    logic [`APB_MAX_DATA_WIDTH-1:0] mask;
    int unsigned n_bytes;
    cur = read_mem(it.addr);
    mask = '0;
    n_bytes = (cfg.data_width < 8) ? 1 : cfg.data_width / 8;
    for (int b = 0; b < n_bytes; b++) begin
      if (!cfg.enable_strb || it.strb[b]) mask[b*8 +: 8] = '1;
    end
    mem[it.addr] = (cur & ~mask) | (it.wdata & mask);
  endfunction

  function logic [`APB_MAX_DATA_WIDTH-1:0] rdata_view(logic [`APB_MAX_DATA_WIDTH-1:0] d);
    return d << (`APB_MAX_DATA_WIDTH - cfg.data_width) >>>
                (`APB_MAX_DATA_WIDTH - cfg.data_width);
  endfunction

  function void drive_idle();
    // ZERO_WAIT：IDLE 期也保持常高（RUL-010：PENABLE=0 时 PREADY 任意值合法）
    vif.slave_cb.pready  <= (cfg.slave_response_mode == APB_ZERO_WAIT) ? 1'b1 : 1'b0;
    vif.slave_cb.pslverr <= 1'b0;
    vif.slave_cb.prdata  <= '0;
    cur_req = null;
  endfunction

  function void handle_reset();
    drive_idle();
  endfunction

endclass : apb_slave_driver

`endif // APB_SLAVE_DRIVER__SV
