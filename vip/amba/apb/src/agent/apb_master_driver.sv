// =============================================================================
// File Name   : apb_master_driver.sv
// Description : Requester driver（ADR-9：completion 归还 + try_next_item peek
//               保证 back-to-back；reset 五步；SETUP 恰 1 拍 RUL-001；
//               负向注入门控 ERR-005/006）
//               采样纪律（C-9）：输出经 master_cb（skew #1）；输入采样经
//               master_cb（#1step）——不混用直接引用
// VLNV        : aixsilicon:vip:apb:1.0.0
// =============================================================================

`ifndef APB_MASTER_DRIVER__SV
`define APB_MASTER_DRIVER__SV

class apb_master_driver extends uvm_driver #(apb_item);

  `uvm_component_utils(apb_master_driver)

  virtual apb_if vif;
  apb_config     cfg;

  apb_item cur_req;   // 当前事务
  apb_item nxt_req;   // peek 的下一笔（one-entry lookahead）

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase_);
    super.build_phase(phase_);
    if (!uvm_config_db#(virtual apb_if)::get(this, "", "vif", vif))
      `uvm_fatal(get_type_name(), "virtual interface 'vif' not set")
    if (!uvm_config_db#(apb_config)::get(this, "", "config", cfg))
      `uvm_fatal(get_type_name(), "apb_config 'config' not set")
    cur_req = null;
    nxt_req = null;
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
  // 主循环：复位对齐 → IDLE → transfer 链（back-to-back）
  // ---------------------------------------------------------------------------
  task main_loop();
    // 复位对齐（C-9）：等复位释放后再对齐一个时钟沿，
    // 保证首个 drive_setup 发生在沿时刻（skew 落点 = 沿+1，采样正确）
    wait (vif.presetn === 1'b1);
    @(posedge vif.pclk);
    forever begin
      drive_idle();
      seq_item_port.get_next_item(cur_req);
      apply_config_width(cur_req);
      if (cur_req.start_delay > 0)
        repeat (cur_req.start_delay) @(posedge vif.pclk);
      // inject_illegal_penable（ERR-005，RUL-002）：IDLE 直接 ACCESS——
      // 前拍 psel=0，本拍 psel=1&&penable=1 → SVA-A2b $rose 无合法 SETUP 检出；
      // slave 容错块按当拍采样完成，无死锁
      if (cfg.allow_protocol_violation && cur_req.inject_illegal_penable) begin
        vif.master_cb.psel    <= '1;
        vif.master_cb.penable <= 1'b1;
        vif.master_cb.paddr   <= cur_req.addr << (`APB_MAX_ADDR_WIDTH - cfg.addr_width) >>> (`APB_MAX_ADDR_WIDTH - cfg.addr_width);
        vif.master_cb.pwrite  <= (cur_req.direction == APB_WRITE);
        @(posedge vif.pclk);
      end

      // transfer 链：完成一笔归还后 peek 下一笔；有则 PSEL 保持直入 SETUP
      forever begin
        drive_one_transfer(cur_req);
        capture_response(cur_req);
        seq_item_port.item_done();
        cur_req = null;

        seq_item_port.try_next_item(nxt_req);
        if (nxt_req == null) break;          // 无下一笔 → IDLE
        cur_req = nxt_req;                   // back-to-back（PSEL 保持）
        apply_config_width(cur_req);
        nxt_req = null;
        // 含 illegal_penable 注入的事务：链内先插 IDLE 拍（psel=0 前导），
        // 让 A2b 的 $rose($past psel=0) 语义成立，再由链内注入块产生违规
        if (cfg.allow_protocol_violation && cur_req.inject_illegal_penable) begin
          drive_idle();
          @(posedge vif.pclk);
          vif.master_cb.psel    <= '1;
          vif.master_cb.penable <= 1'b1;   // IDLE→ACCESS（跳过 SETUP）
          vif.master_cb.paddr   <= cur_req.addr << (`APB_MAX_ADDR_WIDTH - cfg.addr_width) >>> (`APB_MAX_ADDR_WIDTH - cfg.addr_width);
          vif.master_cb.pwrite  <= (cur_req.direction == APB_WRITE);
          @(posedge vif.pclk);
        end
      end
    end
  endtask

  // ---------------------------------------------------------------------------
  // 单笔传输：SETUP(恰 1 拍) → ACCESS(等待) → completion
  // ---------------------------------------------------------------------------
  task drive_one_transfer(apb_item it);
    drive_setup(it);
    @(posedge vif.pclk);
    // inject_extended_setup（ERR-005，RUL-001）：SETUP 延长 1 拍后恢复
    if (cfg.allow_protocol_violation && it.inject_extended_setup) begin
      drive_setup(it);
      @(posedge vif.pclk);
    end
    drive_access(it);
    @(posedge vif.pclk);
    // wait 循环（C-9 统一口径）：沿后直读（与 monitor completion 判定一致）
    while (!(vif.pready === 1'b1) && vif.presetn === 1'b1) begin
      if (cfg.allow_protocol_violation && it.inject_unstable_addr) begin
        it.addr = ~it.addr;                  // 负向：wait 期翻转地址（RUL-003）
      end
      drive_access(it);                      // 合法：字段保持稳定
      @(posedge vif.pclk);
    end
    // completion 已采样：本拍沿后立即撤销 PENABLE（RUL-004：次拍 penable=0——
    // 若 back-to-back，链首的新 SETUP 会在同拍覆盖为 psel=1/pen=0）
    vif.master_cb.penable <= 1'b0;
    it.end_time = $time;
  endtask

  // ---------------------------------------------------------------------------
  // 响应采样（completion 边沿；ADR-12：回填 request item）
  // ---------------------------------------------------------------------------
  function void capture_response(apb_item it);
    it.rdata  = vif.prdata;
    it.ruser  = vif.pruser_w;
    it.buser  = vif.pbuser_w;
    it.slverr = vif.pslverr;
    it.status = vif.pslverr ? APB_ERROR : APB_OK;
  endfunction

  // ---------------------------------------------------------------------------
  // reset 五步（架构 §12.1）
  // ---------------------------------------------------------------------------
  function void handle_reset();
    drive_idle();                            // 1. 终止总线驱动
    if (cur_req != null) begin               // 2+3. ABORTED + 完成握手
      cur_req.status = APB_ABORTED;
      seq_item_port.item_done();
      cur_req = null;
    end
    if (nxt_req != null) begin               // 4. 清空 prefetch
      nxt_req.status = APB_ABORTED;
      seq_item_port.item_done();
      nxt_req = null;
    end
    // 5. FSM 回 IDLE（run_phase 尾部 drive_idle）
  endfunction

  // ---------------------------------------------------------------------------
  // 驱动 helpers（输出经 master_cb；未启用能力恒安全值——C-8）
  // ---------------------------------------------------------------------------
  function void drive_idle();
    vif.master_cb.psel    <= '0;
    vif.master_cb.penable <= 1'b0;
    vif.master_cb.paddr   <= '0;
    vif.master_cb.pwrite  <= 1'b0;
    vif.master_cb.pwdata  <= '0;
    if (cfg.enable_strb)     vif.master_cb.pstrb_w   <= '0;
    if (cfg.enable_prot)     vif.master_cb.pprot_w   <= '0;
    if (cfg.user_req_width)  vif.master_cb.pauser_w  <= '0;
    if (cfg.user_data_width) vif.master_cb.pwuser_w  <= '0;
    if (cfg.enable_wakeup)   vif.master_cb.pwakeup_w <= 1'b0;
    if (cfg.rme_support)     vif.master_cb.pnse_w    <= 1'b0;   // RME 复位安全
  endfunction

  function void drive_setup(apb_item it);
    vif.master_cb.psel    <= '1;
    vif.master_cb.penable <= 1'b0;                       // RUL-001
    vif.master_cb.paddr   <= addr_view_of(it);
    vif.master_cb.pwrite  <= (it.direction == APB_WRITE);
    vif.master_cb.pwdata  <= (it.direction == APB_WRITE) ? wdata_view_of(it) : '0;
    if (cfg.enable_strb) begin
      if (cfg.allow_protocol_violation && it.inject_illegal_strb && it.direction == APB_READ)
        vif.master_cb.pstrb_w <= '1;                     // 负向（RUL-006）
      else
        vif.master_cb.pstrb_w <= (it.direction == APB_WRITE) ? strb_view_of(it) : '0;
    end
    if (cfg.enable_prot)     vif.master_cb.pprot_w   <= it.prot;
    if (cfg.user_req_width)  vif.master_cb.pauser_w  <= auser_view_of(it);
    if (cfg.user_data_width) vif.master_cb.pwuser_w  <= wuser_view_of(it);
    if (cfg.rme_support)     vif.master_cb.pnse_w    <= it.pnse;   // PRO-013/CP-07
    // PWAKEUP 独立策略（ADR-11）
    if (cfg.enable_wakeup) begin
      case (cfg.wakeup_mode)
        APB_WAKEUP_FOLLOW_TRANSFER:     vif.master_cb.pwakeup_w <= 1'b1;
        APB_WAKEUP_MANUAL:              vif.master_cb.pwakeup_w <= it.wakeup;
        APB_WAKEUP_SEQUENCE_CONTROLLED: vif.master_cb.pwakeup_w <= it.wakeup;
      endcase
    end
    // RUL-002 负向
    if (cfg.allow_protocol_violation && it.inject_illegal_penable)
      vif.master_cb.penable <= 1'b1;
  endfunction

  function void drive_access(apb_item it);
    vif.master_cb.penable <= 1'b1;
    vif.master_cb.paddr   <= addr_view_of(it);
    vif.master_cb.pwrite  <= (it.direction == APB_WRITE);
    vif.master_cb.pwdata  <= (it.direction == APB_WRITE) ? wdata_view_of(it) : '0;
    if (cfg.enable_strb)     vif.master_cb.pstrb_w   <= (it.direction == APB_WRITE) ? strb_view_of(it) : '0;
    if (cfg.enable_prot)     vif.master_cb.pprot_w   <= it.prot;
    if (cfg.user_req_width)  vif.master_cb.pauser_w  <= auser_view_of(it);
    if (cfg.user_data_width) vif.master_cb.pwuser_w  <= wuser_view_of(it);
    if (cfg.enable_wakeup)   vif.master_cb.pwakeup_w <= 1'b1;
    if (cfg.rme_support)     vif.master_cb.pnse_w    <= it.pnse;   // PRO-013/CP-07
    if (it.start_time == 0) it.start_time = $time;
  endfunction

  function void apply_config_width(apb_item it);
    it.cfg_addr_width = cfg.addr_width;
    it.cfg_data_width = cfg.data_width;
    it.update_derived();
    if (cfg.allow_protocol_violation && it.inject_unaligned_addr)
      it.addr = it.addr + 1;                 // TRN-005 负向
  endfunction

  function bit [`APB_MAX_ADDR_WIDTH-1:0] addr_view_of(apb_item it);
    return it.addr << (`APB_MAX_ADDR_WIDTH - cfg.addr_width) >>>
                  (`APB_MAX_ADDR_WIDTH - cfg.addr_width);
  endfunction

  function bit [`APB_MAX_DATA_WIDTH-1:0] wdata_view_of(apb_item it);
    return it.wdata << (`APB_MAX_DATA_WIDTH - cfg.data_width) >>>
                    (`APB_MAX_DATA_WIDTH - cfg.data_width);
  endfunction

  function bit [`APB_MAX_DATA_WIDTH/8-1:0] strb_view_of(apb_item it);
    int unsigned strb_w = cfg.data_width/8;
    return it.strb << (`APB_MAX_DATA_WIDTH/8 - strb_w) >>>
                    (`APB_MAX_DATA_WIDTH/8 - strb_w);
  endfunction

  function bit [`APB_MAX_USER_WIDTH-1:0] auser_view_of(apb_item it);
    if (cfg.user_req_width == 0) return '0;
    return it.auser << (`APB_MAX_USER_WIDTH - cfg.user_req_width) >>>
                     (`APB_MAX_USER_WIDTH - cfg.user_req_width);
  endfunction

  function bit [`APB_MAX_USER_WIDTH-1:0] wuser_view_of(apb_item it);
    if (cfg.user_data_width == 0) return '0;
    return it.wuser << (`APB_MAX_USER_WIDTH - cfg.user_data_width) >>>
                     (`APB_MAX_USER_WIDTH - cfg.user_data_width);
  endfunction

endclass : apb_master_driver

`endif // APB_MASTER_DRIVER__SV
