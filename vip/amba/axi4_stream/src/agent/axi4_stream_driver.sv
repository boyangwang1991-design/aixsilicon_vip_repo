// =============================================================================
// File Name   : axi4_stream_driver.sv
// Description : axi4_stream Source driver（握手、预取、合法/专用非法驱动路径）
// 依据        : docs/requirement.md（REQ-SRC-001..005, REQ-PRO-002/003,
//               REQ-TXN-005/006, REQ-RST-002, REQ-ERR-001/003, REQ-INT-001）
//
// 设计说明：
//   * TVALID 拉高后直到握手完成保持 valid 与所有存在字段稳定（REQ-PRO-003），
//     包括解除背压并完成握手的那一个边沿；空闲时不限制 payload 变化。
//   * 连续每周期一节拍：在握手完成的同一时钟边沿完成 item 并零延时取下一拍、
//     立即保持 TVALID 为 1，从而不插入 source 气泡（REQ-SRC-003/ACC-004）。
//     延迟（idle_cycles）只能发生在尚未断言 TVALID 的阶段（REQ-SRC-002）。
//   * 合法生成路径与专用非法注入路径分离且默认关闭（REQ-SRC-005/REQ-ERR-003）。
//   * source 不驱动 TREADY，也不依赖 monitor 完成信息作为发送前提。
//   * 复位断言停止有效发送；排队 item 默认 FLUSH（REQ-RST-002），
//     未完成 beat 标记为 ABORTED_BY_RESET（测试软件状态，非接口响应，REQ-RST-003）。
// =============================================================================

`ifndef AXI4_STREAM_DRIVER__SV
`define AXI4_STREAM_DRIVER__SV

class axi4_stream_driver extends uvm_driver #(axi4_stream_beat_item);

  `uvm_component_utils(axi4_stream_driver)

  virtual axi4_stream_if vif;
  axi4_stream_config  cfg;

  // 提交意图发布（用于 driver 自身丢包对照，不作为 scoreboard 的 oracle，
  // REQ-SCB-007）
  uvm_analysis_port #(axi4_stream_beat_item) offered_ap;

  protected axi4_stream_beat_item current;
  protected bit                   in_flight     = 1'b0;
  protected bit                   stop_on_reset = 1'b0;
  protected int                   reset_epoch   = 0;
  protected longint               accepted_beats = 0;
  protected int                   local_txn_seq  = 0;
  protected int                   canceledBeats = 0;   // CANCELED_BEFORE_VALID 计数
  protected int                   abortedBeats  = 0;   // ABORTED_BY_RESET 计数
  protected int                   watchdogExpirations = 0;
  protected bit                   abort_request = 1'b0; // test policy 请求中止仿真

  // ready 等待看门狗（REQ-CFG-001 MAX_READY_WAIT；0=关闭）
  // 需求：一旦 TVALID 已拉高，正常取消或 timeout 不得撤销当前拍；
  // 默认让该拍继续等待并报告 watchdog，由 test policy 决定是否中止仿真。
  protected task watchdog_monitor();
    int wait_cycles;
    wait_cycles = 0;
    forever begin
      @(vif.drv_cb);
      if (!in_flight) begin
        wait_cycles = 0;
        continue;
      end
      wait_cycles++;
      if (cfg.max_ready_wait > 0 && wait_cycles > cfg.max_ready_wait) begin
        watchdogExpirations++;
        `uvm_warning("AXIS-DRV", $sformatf(
          "watchdog：beat 等待 ready 已 %0d 周期（阈值 %0d）。按 REQ-TXN-005 不撤销该拍，继续等待；test policy 决定是否中止",
          wait_cycles, cfg.max_ready_wait))
        if (abort_request) `uvm_fatal("AXIS-DRV", "test policy 请求中止仿真")
        wait_cycles = 0;
      end
    end
  endtask

  // 公开：请求在 watchdog 触发时中止仿真（由 test policy 调用）
  function void request_abort_on_watchdog();
    abort_request = 1'b1;
  endfunction

  function new(string name = "axi4_stream_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual axi4_stream_if)::get(this, "", "vif", vif))
      `uvm_fatal("AXIS-DRV", "未获取 virtual interface（REQ-INT-002）")
    if (!uvm_config_db#(axi4_stream_config)::get(this, "", "cfg", cfg))
      `uvm_fatal("AXIS-DRV", "未获取 config（REQ-INT-002）")
    offered_ap = new("offered_ap", this);
    init_pins();
  endfunction

  protected function void init_pins();
    vif.drv_cb.tvalid <= 1'b0;
    vif.drv_cb.tdata  <= '0;
    vif.drv_cb.tkeep  <= '0;
    vif.drv_cb.tstrb  <= '0;
    vif.drv_cb.tlast  <= 1'b0;
    vif.drv_cb.tid    <= '0;
    vif.drv_cb.tdest  <= '0;
    vif.drv_cb.tuser  <= '0;
  endfunction

  protected function bit effective_ready();
    return vif.exists_tready() ? (vif.tready === 1'b1) : 1'b1;
  endfunction

  // 复位释放且已稳定（用于驱动循环启动条件）
  protected function bit reset_released();
    return (vif.aresetn === 1'b1);
  endfunction

  // ---------------------------------------------------------------------------
  // 复位监视：异步断言、同步释放（REQ-RST-001/002）
  // ---------------------------------------------------------------------------
  // 复位响应（REQ-RST-001/002）：AXIS-P001 要求“复位期间 TVALID 为 0”，
  // 而 clocking block 驱动要到下一个时钟边沿才生效；因此复位断言时用
  // 专用直接赋值路径立即撤销 TVALID 与 payload。本路径只用于复位，不参与
  // 正常数据传输（正常驱动一律经 drv_cb）。
  protected task reset_response();
    vif.tvalid = 1'b0;
    vif.tdata  = '0;
    vif.tkeep  = '0;
    vif.tstrb  = '0;
    vif.tlast  = 1'b0;
    vif.tid    = '0;
    vif.tdest  = '0;
    vif.tuser  = '0;
  endtask

  task monitor_reset();
    forever begin
      // 同时等待时钟边沿与复位异步断言
      @(vif.drv_cb or negedge vif.aresetn);
      if (vif.aresetn === 1'b0) begin
        if (!stop_on_reset) begin
          stop_on_reset = 1'b1;
          reset_epoch++;
          // 只有已断言 TVALID 的在途 beat 才标记为复位中止；
          // 尚未开始发送的排队 item 由主循环按 FLUSH/RETAIN 配置处理（REQ-RST-002）
          if (in_flight && current != null) begin
            current.status = AXIS_ST_ABORTED_BY_RESET;
            abortedBeats++;
            `uvm_info("AXIS-DRV", $sformatf(
              "复位中止在途 beat（测试软件状态，非接口响应）: local_txn=%0d reset_epoch=%0d",
              current.local_txn_id, reset_epoch), UVM_MEDIUM)
          end
          in_flight = 1'b0;
        end
        reset_response();   // 立即撤销 TVALID（AXIS-P001）
        init_pins();
      end else begin
        stop_on_reset = 1'b0;
      end
    end
  endtask

  // ---------------------------------------------------------------------------
  // 主驱动循环（标准 get_next_item / item_done 协议 + 无气泡流水）
  // ---------------------------------------------------------------------------
  task run_phase(uvm_phase phase);
    fork
      monitor_reset();
      watchdog_monitor();
    join_none
    drive_loop();
  endtask

  // 零气泡原理：item_done() 之后立即 get_next_item()，若 sequencer 队列非空则
  // 在零仿真时间内返回；随后对同一时钟边沿再次断言 TVALID=1，与上一拍的
  // `tvalid <= 0` 在同一时间步（后者被覆盖），因此总线 TVALID 连续为 1，
  // 不产生 source 自身气泡（REQ-SRC-003 / REQ-ACC-004）。
  task drive_loop();
    if (cfg.role == AXIS_ROLE_PASSIVE) begin
      `uvm_info("AXIS-DRV", "PASSIVE 角色：driver 不参与驱动（REQ-SCP-005）", UVM_LOW)
      return;
    end
    // 启动条件：等待复位释放，避免把复位期间的首次取样误判为中止
    while (!reset_released()) @(vif.drv_cb);
    @(vif.drv_cb);

    forever begin
      seq_item_port.get_next_item(current);
      if (stop_on_reset) begin
        current.status = AXIS_ST_CANCELED_BEFORE_VALID;
        seq_item_port.item_done();
        continue;
      end
      local_txn_seq++;
      current.local_txn_id = local_txn_seq;
      current.has_local_txn_id = 1'b1;
      offered_ap.write(current);

      // 1) 发送前空闲周期（尚未断言 TVALID，延迟只允许发生在此阶段，REQ-SRC-002）
      if (current.idle_cycles > 0) begin
        vif.drv_cb.tvalid <= 1'b0;
        for (int i = 0; i < current.idle_cycles; i++) @(vif.drv_cb);
        if (stop_on_reset) begin
          current.status = AXIS_ST_CANCELED_BEFORE_VALID;
          seq_item_port.item_done();
          continue;
        end
      end

      // 2) 断言 TVALID（不等待 TREADY，REQ-PRO-002）
      apply_payload(current);
      in_flight = 1'b1;
      vif.drv_cb.tvalid <= 1'b1;

      // 3) 保持稳定直到握手完成（REQ-PRO-003）
      wait_for_handshake(current);

      in_flight = 1'b0;
      accepted_beats++;
      if (stop_on_reset) begin
        current.status = AXIS_ST_ABORTED_BY_RESET;
        seq_item_port.item_done();
        init_pins();
        continue;
      end

      // 4) 完成当前 item；下一拍在同一时间步重新断言 TVALID（无气泡）
      seq_item_port.item_done();
      current = null;
      vif.drv_cb.tvalid <= 1'b0;
    end
  endtask

  // ---------------------------------------------------------------------------
  // 等待握手：stall 期间保持 payload 稳定；非法注入走专用破坏路径
  // ---------------------------------------------------------------------------
  protected task wait_for_handshake(axi4_stream_beat_item item);
    bit              ready_now;
    int              stall_cycles;
    bit              do_inject;
    string           rule;

    do_inject = item.inject_enable && cfg.check_enable;
    rule      = item.inject_rule;
    stall_cycles = 0;
    // 必须至少等到一个 ACLK 上升沿后判定握手：TVALID 与 TREADY 只有在
    // 时钟边沿同时有效才构成一次成功传输（REQ-PRO-001）。
    // 直接在当前时间步查询 tready 会把上一周期的 ready 误判为本拍握手。
    while (!stop_on_reset) begin
      @(vif.drv_cb);
      if (effective_ready()) break;
      stall_cycles++;
      if (do_inject) begin
        case (rule)
          // stall 中撤销 TVALID（破坏 AXIS-P003）
          "AXIS-P003": begin
            vif.drv_cb.tvalid <= 1'b0;
            @(vif.drv_cb);
            vif.drv_cb.tvalid <= 1'b1;
          end
          // stall 中修改 TDATA（破坏 AXIS-P004-DATA）
          "AXIS-P004": begin
            if (vif.exists_tdata()) vif.drv_cb.tdata <= ~item.data;
          end
          // stall 中修改 TKEEP（破坏 AXIS-P004-KEEP）
          "AXIS-P004-KEEP": begin
            if (vif.exists_tkeep()) vif.drv_cb.tkeep <= ~item.keep;
          end
          // stall 中修改 TLAST（破坏 AXIS-P004-LAST）
          "AXIS-P004-LAST": begin
            if (vif.exists_tlast()) vif.drv_cb.tlast <= ~item.last;
          end
          // stall 中修改 TID（破坏 AXIS-P004-ID）
          "AXIS-P004-ID": begin
            if (vif.exists_tid()) vif.drv_cb.tid <= ~item.id[31:0];
          end
          // TKEEP=0 且 TSTRB=1（破坏 AXIS-P005）
          "AXIS-P005": begin
            if (vif.exists_tkeep() && vif.exists_tstrb()) begin
              vif.drv_cb.tkeep <= '0;
              vif.drv_cb.tstrb <= {{(axi4_stream_types_pkg::AXIS_MAX_BYTES-1){1'b0}}, 1'b1};
            end
          end
          default: ;
        endcase
      end
      ready_now = effective_ready();
    end
    `uvm_info("AXIS-DRV", $sformatf("handshake local_txn=%0d stall=%0d",
      item.local_txn_id, stall_cycles), UVM_HIGH)
  endtask

  // ---------------------------------------------------------------------------
  // payload 应用：按存在性驱动（REQ-CFG-002：未存在端口不驱动）
  // ---------------------------------------------------------------------------
  protected function void apply_payload(axi4_stream_beat_item item);
    if (vif.exists_tdata())  vif.drv_cb.tdata  <= item.data;
    if (vif.exists_tkeep())  vif.drv_cb.tkeep  <= item.keep;
    if (vif.exists_tstrb())  vif.drv_cb.tstrb  <= item.strb;
    if (vif.exists_tlast())  vif.drv_cb.tlast  <= item.last;
    if (vif.exists_tid())    vif.drv_cb.tid    <= item.id[31:0];
    if (vif.exists_tdest())  vif.drv_cb.tdest  <= item.dest[31:0];
    if (vif.exists_tuser())  vif.drv_cb.tuser  <= item.user;
  endfunction

  // ---------------------------------------------------------------------------
  // 统计与状态（REQ-PERF-001 / REQ-TXN-006）
  // ---------------------------------------------------------------------------
  function longint accepted_count();
    return accepted_beats;
  endfunction

  function int current_epoch();
    return reset_epoch;
  endfunction

  // ---------------------------------------------------------------------------
  // 取消与排空（REQ-TXN-005/006）
  //   一旦 TVALID 已拉高，取消不得撤销当前拍：cancel_pending 只作用于
  //   尚未断言 TVALID 的排队 item；在途拍按 REQ-TXN-005 继续等待。
  // ---------------------------------------------------------------------------
  // 注：try_next_item/item_done 是 task，含同步语义，故本接口为 task。
  // 返回值通过 output 参数给出。
  task cancel_pending(output int n);
    axi4_stream_beat_item tmp;
    n = 0;
    while (seq_item_port.has_do_available()) begin
      seq_item_port.try_next_item(tmp);
      if (tmp == null) break;
      tmp.status = AXIS_ST_CANCELED_BEFORE_VALID;
      seq_item_port.item_done();
      n++;
      canceledBeats++;
    end
    `uvm_info("AXIS-DRV", $sformatf("cancel_pending：撤销 %0d 个未断言 TVALID 的排队 item（在途拍不撤销）", n), UVM_LOW)
  endtask

  function int canceled_count();
    return canceledBeats;
  endfunction

  function int aborted_count();
    return abortedBeats;
  endfunction

  function int watchdog_count();
    return watchdogExpirations;
  endfunction

  // drain：等待当前在途拍完成（不撤销）
  task wait_drained();
    while (in_flight) @(vif.drv_cb);
  endtask

endclass : axi4_stream_driver

`endif // AXI4_STREAM_DRIVER__SV
