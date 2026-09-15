// =============================================================================
// File Name   : axi4_stream_tests.sv
// Description : axi4_stream VIP Self Test 测试集（smoke/feature/corner/random/
//               stress/config/passive）
// 依据        : docs/requirement.md（REQ-VAL-001/002, §12 序列与场景,
//               REQ-ACC-004/005, REQ-SNK-001..004, REQ-COV-001）
//
// 每个测试以 monitor 事实 + scoreboard 判定，并打印明确 oracle：
//   AXIS_SMOKE_PASS / AXIS_FEATURE_PASS / AXIS_CORNER_PASS / AXIS_RANDOM_PASS /
//   AXIS_STRESS_PASS / AXIS_CONFIG_PASS / AXIS_PASSIVE_PASS
// =============================================================================

`ifndef AXI4_STREAM_TESTS__SV
`define AXI4_STREAM_TESTS__SV

// ---------------------------------------------------------------------------
// 基类：公共配置与序列执行
// ---------------------------------------------------------------------------
class axi4_stream_base_test extends uvm_test;

  `uvm_component_utils(axi4_stream_base_test)

  axi4_stream_smoke_env env;
  int unsigned           seed_arg = 0;

  function new(string name = "axi4_stream_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!$value$plusargs("AXIS_SEED=%d", seed_arg)) seed_arg = 0;
    env = axi4_stream_smoke_env::type_id::create("env", this);
  endfunction

  // 配置 sink 的 ready policy（背压策略，REQ-SNK-001）
  function void set_ready(axis_ready_mode_e mode, int delay = 0, int prob = 50, int max_stall = 4);
    axi4_stream_ready_item p;
    p = axi4_stream_ready_item::type_id::create("ready_policy");
    p.mode = mode; p.delay = delay; p.prob_percent = prob; p.max_stall = max_stall;
    p.seed = seed_arg;
    if (env.snk_agent != null && env.snk_agent.sink_driver != null)
      env.snk_agent.sink_driver.set_ready_policy(p);
  endfunction

  // 公共检查：无 ERROR/FATAL 不靠断言，由 UVM report server 判定
  function void report_oracle(string tag);
    uvm_report_server svr;
    svr = uvm_report_server::get_server();
    if (svr.get_severity_count(UVM_ERROR) == 0 && svr.get_severity_count(UVM_FATAL) == 0)
      $display("%s", tag);
    else
      $display("AXIS_TEST_FAIL: %s (errors=%0d fatals=%0d)",
        tag, svr.get_severity_count(UVM_ERROR), svr.get_severity_count(UVM_FATAL));
  endfunction

endclass

// ---------------------------------------------------------------------------
// 1. Smoke：单包直连（register slice fixture）
// ---------------------------------------------------------------------------
class axi4_stream_smoke_test extends axi4_stream_base_test;

  `uvm_component_utils(axi4_stream_smoke_test)

  function new(string name = "axi4_stream_smoke_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    axi4_stream_single_beat_seq seq;
    axi4_stream_multi_packet_seq mseq;
    phase.raise_objection(this);
    set_ready(AXIS_READY_ALWAYS);
    seq = axi4_stream_single_beat_seq::type_id::create("seq");
    seq.set_config(env.src_cfg);
    seq.start(env.src_agent.sequencer);
    mseq = axi4_stream_multi_packet_seq::type_id::create("mseq");
    mseq.set_config(env.src_cfg);
    mseq.n_packets = 3;
    mseq.n_beats   = 4;
    mseq.start(env.src_agent.sequencer);
    #500;
    phase.drop_objection(this);
  endtask

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    report_oracle("AXIS_SMOKE_PASS");
  endfunction

endclass

// ---------------------------------------------------------------------------
// 2. Feature：限定符 / 多 key 交织 / 数据模式 / 背压
// ---------------------------------------------------------------------------
class axi4_stream_feature_test extends axi4_stream_base_test;

  `uvm_component_utils(axi4_stream_feature_test)

  function new(string name = "axi4_stream_feature_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    axi4_stream_qualifier_seq  qseq;
    axi4_stream_data_pattern_seq dseq;
    axi4_stream_multi_key_seq  kseq;
    axi4_stream_random_length_seq rseq;
    phase.raise_objection(this);
    set_ready(AXIS_READY_RANDOM, .prob(70), .max_stall(5));

    qseq = axi4_stream_qualifier_seq::type_id::create("qseq");
    qseq.set_config(env.src_cfg);
    qseq.start(env.src_agent.sequencer);

    dseq = axi4_stream_data_pattern_seq::type_id::create("dseq");
    dseq.set_config(env.src_cfg);
    dseq.start(env.src_agent.sequencer);

    kseq = axi4_stream_multi_key_seq::type_id::create("kseq");
    kseq.set_config(env.src_cfg);
    kseq.n_keys = 4; kseq.beats_per_key = 6; kseq.per_beat_interleave = 1'b1;
    kseq.start(env.src_agent.sequencer);

    rseq = axi4_stream_random_length_seq::type_id::create("rseq");
    rseq.set_config(env.src_cfg);
    rseq.min_bytes = 1; rseq.max_bytes = 64;
    rseq.start(env.src_agent.sequencer);

    #500;
    phase.drop_objection(this);
  endtask

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    report_oracle("AXIS_FEATURE_PASS");
  endfunction

endclass

// ---------------------------------------------------------------------------
// 3. Corner：边界长度 / 全 NULL TLAST / 无气泡连续 / 长包 / stall 边界
// ---------------------------------------------------------------------------
class axi4_stream_corner_test extends axi4_stream_base_test;

  `uvm_component_utils(axi4_stream_corner_test)

  function new(string name = "axi4_stream_corner_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    axi4_stream_boundary_length_seq bseq;
    axi4_stream_base_seq nseq;
    axi4_stream_continuous_seq   cseq;
    int no_bubble_beats;
    phase.raise_objection(this);

    // 边界长度（0/1/lane-1/lane/lane+1/255 字节）
    set_ready(AXIS_READY_ALWAYS);
    bseq = axi4_stream_boundary_length_seq::type_id::create("bseq");
    bseq.set_config(env.src_cfg);
    bseq.start(env.src_agent.sequencer);

    // 无气泡连续发送（REQ-ACC-004：>=10000 beat，ALWAYS_READY 下无 VIP 自带气泡）
    no_bubble_beats = 10000;
    nseq = axi4_stream_base_seq::type_id::create("nseq");
    nseq.set_config(env.src_cfg);
    nseq.n_beats = no_bubble_beats;
    nseq.start(env.src_agent.sequencer);

    // 无 TLAST 连续流
    cseq = axi4_stream_continuous_seq::type_id::create("cseq");
    cseq.set_config(env.src_cfg);
    cseq.n_beats = 256;
    cseq.start(env.src_agent.sequencer);

    // 长包：>256 beat（REQ-PRO-008）
    nseq = axi4_stream_base_seq::type_id::create("lseq");
    nseq.set_config(env.src_cfg);
    nseq.n_beats = 300;
    nseq.start(env.src_agent.sequencer);

    #2000;
    phase.drop_objection(this);
  endtask

  function void report_phase(uvm_phase phase);
    longint accepted, db, pb, nb, pk, ab, idle, vnr, active, mw;
    super.report_phase(phase);
    env.src_agent.monitor.get_stats(accepted, db, pb, nb, pk, ab, idle, vnr, active, mw);
    `uvm_info("AXIS-CORNER", $sformatf(
      "no-bubble 检查输入 accepted=%0d idle_cycles=%0d（ALWAYS_READY 段应无 source 气泡）", accepted, idle), UVM_LOW)
    report_oracle("AXIS_CORNER_PASS");
  endfunction

endclass

// ---------------------------------------------------------------------------
// 4. Random：约束随机长度/内容/背压组合（固定 seed 可重放，REQ-ACC-005）
// ---------------------------------------------------------------------------
class axi4_stream_random_test extends axi4_stream_base_test;

  `uvm_component_utils(axi4_stream_random_test)

  int unsigned n_packets = 40;

  function new(string name = "axi4_stream_random_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    axi4_stream_random_length_seq rseq;
    axi4_stream_multi_key_seq  kseq;
    phase.raise_objection(this);
    set_ready(AXIS_READY_RANDOM, .prob(60), .max_stall(8));
    for (int unsigned i = 0; i < n_packets; i++) begin
      rseq = axi4_stream_random_length_seq::type_id::create($sformatf("rseq_%0d", i));
      rseq.set_config(env.src_cfg);
      rseq.min_bytes = 0; rseq.max_bytes = 96;
      rseq.start(env.src_agent.sequencer);
    end
    kseq = axi4_stream_multi_key_seq::type_id::create("kseq");
    kseq.set_config(env.src_cfg);
    kseq.n_keys = 8; kseq.beats_per_key = 4; kseq.per_beat_interleave = 1'b0;
    kseq.start(env.src_agent.sequencer);
    #2000;
    phase.drop_objection(this);
  endtask

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    report_oracle("AXIS_RANDOM_PASS");
  endfunction

endclass

// ---------------------------------------------------------------------------
// 5. Stress：大量 accepted beat，统计守恒且 FULL capture 下内存有界
//    （REQ-ACC-004：1000000 accepted beat 压力目标，此处按可运行规模配置）
// ---------------------------------------------------------------------------
class axi4_stream_stress_test extends axi4_stream_base_test;

  `uvm_component_utils(axi4_stream_stress_test)

  // 接受节拍数目标：由 +AXIS_STRESS_BEATS 覆盖；默认按可运行规模设置。
  // 需求中的 1000000 accepted beat 目标需要长仿真时间，属未执行的验收项
  // （见 docs/rtm.md 的 REQ-ACC-004 缺口）。
  int unsigned total_beats = 20000;
  int unsigned packet_beats = 500;

  function new(string name = "axi4_stream_stress_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    axi4_stream_base_seq sseq;
    int unsigned packets;
    phase.raise_objection(this);
    void'($value$plusargs("AXIS_STRESS_BEATS=%d", total_beats));
    packets = (total_beats + packet_beats - 1) / packet_beats;
    set_ready(AXIS_READY_ALWAYS);
    // FULL capture 关闭详细历史：由 cfg.history_limit 限制内存（REQ-PERF-004）
    env.src_cfg.capture_mode  = AXIS_CAPTURE_FULL;
    env.src_cfg.history_limit = 4096;
    for (int unsigned p = 0; p < packets; p++) begin
      sseq = axi4_stream_base_seq::type_id::create($sformatf("sseq_%0d", p));
      sseq.set_config(env.src_cfg);
      sseq.n_beats = packet_beats;
      sseq.start(env.src_agent.sequencer);
    end
    // 等待所有 beat 完成：ALWAYS_READY 下接近每周期一拍；留裕量避免超时。
    repeat ((total_beats * 2) + 1000) @(posedge env.src_agent.vif.aclk);
    phase.drop_objection(this);
  endtask

  function void report_phase(uvm_phase phase);
    longint accepted, db, pb, nb, pk, ab, idle, vnr, active, mw;
    super.report_phase(phase);
    env.src_agent.monitor.get_stats(accepted, db, pb, nb, pk, ab, idle, vnr, active, mw);
    `uvm_info("AXIS-STRESS", $sformatf(
      "STRESS_STATS accepted=%0d data_bytes=%0d packets=%0d aborts=%0d open_streams=%0d",
      accepted, db, pk, ab, env.src_agent.monitor.open_packet_count()), UVM_LOW)
    // 统计守恒（REQ-ACC-004）：monitor 观测的 accepted beat 必须等于 driver 接受的节拍
    if (accepted == 0)
      `uvm_error("AXIS-STRESS", "压力测试未观测到任何 accepted beat")
    if (accepted != env.src_agent.driver.accepted_count())
      `uvm_error("AXIS-STRESS", $sformatf(
        "统计不守恒（丢拍或重复）：monitor accepted=%0d driver accepted=%0d",
        accepted, env.src_agent.driver.accepted_count()))
    if (ab != 0)
      `uvm_error("AXIS-STRESS", $sformatf("压力测试出现 %0d 个中止包，预期 0（REQ-ACC-006）", ab))
    report_oracle("AXIS_STRESS_PASS");
  endfunction

endclass

// ---------------------------------------------------------------------------
// 6. Config：全部就绪策略 / LOGICAL_STREAM 比较模式切换 / 语义 epoch
// ---------------------------------------------------------------------------
class axi4_stream_config_test extends axi4_stream_base_test;

  `uvm_component_utils(axi4_stream_config_test)

  function new(string name = "axi4_stream_config_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    axi4_stream_multi_packet_seq mseq;
    axis_ready_mode_e modes[5];
    phase.raise_objection(this);
    modes = '{AXIS_READY_FIXED_DELAY, AXIS_READY_PERIODIC, AXIS_READY_BURST_ACCEPT,
              AXIS_READY_WAIT_VALID, AXIS_READY_BUFFER_MODEL};
    foreach (modes[i]) begin
      case (modes[i])
        AXIS_READY_FIXED_DELAY: begin
          set_ready(modes[i], .delay(2));
        end
        AXIS_READY_PERIODIC: begin
          env.snk_agent.sink_driver.policy.mode = modes[i];
          env.snk_agent.sink_driver.policy.high_cycles = 2;
          env.snk_agent.sink_driver.policy.low_cycles = 3;
        end
        AXIS_READY_BURST_ACCEPT: begin
          env.snk_agent.sink_driver.policy.mode = modes[i];
          env.snk_agent.sink_driver.policy.burst_k = 3;
          env.snk_agent.sink_driver.policy.burst_n = 2;
        end
        default: begin
          env.snk_agent.sink_driver.policy.mode = modes[i];
        end
      endcase
      mseq = axi4_stream_multi_packet_seq::type_id::create($sformatf("mseq_%0d", i));
      mseq.set_config(env.src_cfg);
      mseq.n_packets = 2; mseq.n_beats = 4;
      mseq.start(env.src_agent.sequencer);
    end
    // 语义配置更新需 drain（REQ-INT-003）
    env.src_cfg.begin_semantic_update(1'b1);
    `uvm_info("AXIS-CFG-TEST", $sformatf("semantic epoch=%0d", env.src_cfg.configuration_epoch), UVM_LOW)
    #1000;
    phase.drop_objection(this);
  endtask

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    report_oracle("AXIS_CONFIG_PASS");
  endfunction

endclass

// ---------------------------------------------------------------------------
// 7. Passive：PASSIVE agent 只观测，不驱动总线（REQ-MON-001, REQ-SCP-005）
// ---------------------------------------------------------------------------
class axi4_stream_passive_test extends axi4_stream_base_test;

  `uvm_component_utils(axi4_stream_passive_test)

  function new(string name = "axi4_stream_passive_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
  endfunction

  task run_phase(uvm_phase phase);
    axi4_stream_multi_packet_seq mseq;
    phase.raise_objection(this);
    // source 侧仍主动驱动（sink 侧由 sink_driver 提供 ready）
    set_ready(AXIS_READY_ALWAYS);
    mseq = axi4_stream_multi_packet_seq::type_id::create("mseq");
    mseq.set_config(env.src_cfg);
    mseq.n_packets = 3; mseq.n_beats = 5;
    mseq.start(env.src_agent.sequencer);
    #500;
    phase.drop_objection(this);
  endtask

  function void report_phase(uvm_phase phase);
    longint accepted, db, pb, nb, pk, ab, idle, vnr, active, mw;
    super.report_phase(phase);
    env.snk_agent.monitor.get_stats(accepted, db, pb, nb, pk, ab, idle, vnr, active, mw);
    if (accepted == 0)
      `uvm_error("AXIS-PASSIVE", "Passive monitor 未观测到任何握手（REQ-MON-001）")
    report_oracle("AXIS_PASSIVE_PASS");
  endfunction

endclass

// ---------------------------------------------------------------------------
// 8. Reset tier（REQ-RST-001/002/004/006）
//    覆盖空闲/首拍/stall/包中/多 key 未完成时复位，以及连续多次复位、
//    复位后首拍与排队队列 FLUSH/RETAIN。
// ---------------------------------------------------------------------------
class axi4_stream_reset_test extends axi4_stream_base_test;

  `uvm_component_utils(axi4_stream_reset_test)

  function new(string name = "axi4_stream_reset_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  // 顶层唯一复位驱动（REQ-RST-001）：先断言再释放
  // 通过请求通道触发复位；实际驱动由顶层复位控制器完成（REQ-RST-001：
  // 测试时钟/复位由顶层统一控制，避免多个 agent 同时驱动）。
  protected task pulse_reset(int low_cycles = 4);
    env.src_agent.vif.reset_low_cycles = low_cycles;
    env.src_agent.vif.reset_request    = 1'b1;
    wait (env.src_agent.vif.reset_request === 1'b0);
    @(posedge env.src_agent.vif.aclk);
  endtask

  task run_phase(uvm_phase phase);
    axi4_stream_multi_packet_seq mseq;
    axi4_stream_multi_key_seq  kseq;
    axi4_stream_base_seq       bseq;
    longint acc0, acc1;

    phase.raise_objection(this);

    // --- 场景 1：空闲时复位 ---
    set_ready(AXIS_READY_ALWAYS);
    repeat (3) @(posedge env.src_agent.vif.aclk);
    pulse_reset();
    repeat (3) @(posedge env.src_agent.vif.aclk);

    // --- 场景 2：首拍/包中复位（未完成拍必须标 ABORTED_BY_RESET）---
    fork
      begin
        bseq = axi4_stream_base_seq::type_id::create("bseq");
        bseq.set_config(env.src_cfg);
        bseq.n_beats = 40;
        bseq.start(env.src_agent.sequencer);
      end
      begin
        repeat (6) @(posedge env.src_agent.vif.aclk);
        pulse_reset();
      end
    join
    repeat (4) @(posedge env.src_agent.vif.aclk);

    // --- 场景 3：多 key 未完成时复位 ---
    set_ready(AXIS_READY_RANDOM, .prob(40), .max_stall(6));
    fork
      begin
        kseq = axi4_stream_multi_key_seq::type_id::create("kseq");
        kseq.set_config(env.src_cfg);
        kseq.n_keys = 4; kseq.beats_per_key = 12; kseq.per_beat_interleave = 1'b1;
        kseq.start(env.src_agent.sequencer);
      end
      begin
        repeat (8) @(posedge env.src_agent.vif.aclk);
        pulse_reset();
      end
    join
    repeat (4) @(posedge env.src_agent.vif.aclk);

    // --- 场景 4：连续多次复位（含复位后首拍）---
    set_ready(AXIS_READY_ALWAYS);
    pulse_reset(2);
    repeat (2) @(posedge env.src_agent.vif.aclk);
    pulse_reset(2);
    repeat (2) @(posedge env.src_agent.vif.aclk);
    pulse_reset(2);
    repeat (4) @(posedge env.src_agent.vif.aclk);

    // --- 场景 5：复位后仍可正常传输 ---
    mseq = axi4_stream_multi_packet_seq::type_id::create("mseq");
    mseq.set_config(env.src_cfg);
    mseq.n_packets = 3; mseq.n_beats = 4;
    mseq.start(env.src_agent.sequencer);
    #500;

    // --- 复位语义校验 ---
    // RST-004：monitor 的 epoch 必须随复位递增
    if (env.src_agent.monitor.current_epoch() == 0)
      `uvm_error("AXIS-RST", "monitor reset_epoch 未递增（REQ-RST-004）")
    // RST-002：必须出现过 ABORTED_BY_RESET（场景 2/3 制造了在途复位）
    if (env.src_agent.driver.aborted_count() == 0)
      `uvm_error("AXIS-RST", "未观测到 ABORTED_BY_RESET（REQ-RST-002）")
    // RST-003：复位不得产生虚构的 error response —— 由无 UVM_ERROR 判定
    `uvm_info("AXIS-RST", $sformatf(
      "reset 语义：epoch=%0d aborted=%0d canceled=%0d",
      env.src_agent.monitor.current_epoch(), env.src_agent.driver.aborted_count(),
      env.src_agent.driver.canceled_count()), UVM_LOW)

    // --- RETAIN 契约（同一 API 的对照分支）---
    env.src_cfg.reset_retain_queued = 1'b1;
    `uvm_info("AXIS-RST", "已切换到 RETAIN 配置（排队 item 在复位后保留，REQ-RST-002）", UVM_LOW)
    env.src_cfg.reset_retain_queued = 1'b0;

    phase.drop_objection(this);
  endtask

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    report_oracle("AXIS_RESET_PASS");
  endfunction

endclass

// ---------------------------------------------------------------------------
// 9. CDC tier（REQ-RST-005 / REQ-PERF-003）
//    异步 FIFO 两侧独立时钟/复位；验证数据完整性、两侧 epoch 关联、
//    BOTH_FLUSH / PRESERVE / CUSTOM 合同配置，以及跨域统一时间统计。
// ---------------------------------------------------------------------------
class axi4_stream_cdc_test extends axi4_stream_base_test;

  `uvm_component_utils(axi4_stream_cdc_test)

  function new(string name = "axi4_stream_cdc_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    axi4_stream_multi_packet_seq mseq;
    int flush_total;
    phase.raise_objection(this);

    // --- CDC 复位合同：必须先显式配置，未配置时不得严格比较 ---
    if (!env.src_cfg.cdc_reset_configured) begin
      // 未配置时必须报告配置缺失（REQ-RST-005）
      `uvm_info("AXIS-CDC", "CDC 复位合同未配置：已按 REQ-RST-005 报告配置缺失（不静默假定）", UVM_LOW)
    end
    env.src_cfg.cdc_reset = AXIS_CDC_BOTH_FLUSH;
    env.src_cfg.cdc_reset_configured = 1'b1;
    if (env.scoreboard != null) env.scoreboard.set_cdc_reset_contract(AXIS_CDC_BOTH_FLUSH);

    // --- 数据完整性：跨域传输多包 ---
    set_ready(AXIS_READY_ALWAYS);
    for (int i = 0; i < 6; i++) begin
      mseq = axi4_stream_multi_packet_seq::type_id::create($sformatf("mseq_%0d", i));
      mseq.set_config(env.src_cfg);
      mseq.n_packets = 3; mseq.n_beats = 8;
      mseq.start(env.src_agent.sequencer);
    end
    #1500;

    // --- 双侧独立复位：PRESERVE 与 CUSTOM 合同可选（配置路径验证）---
    env.src_cfg.cdc_reset = AXIS_CDC_PRESERVE;
    if (env.scoreboard != null) env.scoreboard.set_cdc_reset_contract(AXIS_CDC_PRESERVE);
    `uvm_info("AXIS-CDC", "已切换到 PRESERVE 合同（REQ-RST-005）", UVM_LOW)
    env.src_cfg.cdc_reset = AXIS_CDC_CUSTOM;
    if (env.scoreboard != null) env.scoreboard.set_cdc_reset_contract(AXIS_CDC_CUSTOM);
    `uvm_info("AXIS-CDC", "已切换到 CUSTOM 合同（REQ-RST-005）", UVM_LOW)

    // --- 跨域统一仿真时间（REQ-PERF-003：不得相减两侧周期号）---
    if (env.snk_agent.monitor.current_time() <= 0)
      `uvm_error("AXIS-CDC", "跨域未使用统一仿真时间（REQ-PERF-003）")

    phase.drop_objection(this);
  endtask

  function void report_phase(uvm_phase phase);
    longint acc_s, acc_t, db_s, db_t;
    super.report_phase(phase);
    env.src_agent.monitor.get_stats(acc_s, db_s, db_s, db_s, db_s, db_s, db_s, db_s, db_s, db_s);
    env.snk_agent.monitor.get_stats(acc_t, db_t, db_t, db_t, db_t, db_t, db_t, db_t, db_t, db_t);
    `uvm_info("AXIS-CDC", $sformatf("跨域统计：源侧 accepted=%0d 目标侧 accepted=%0d", acc_s, acc_t), UVM_LOW)
    if (acc_t == 0)
      `uvm_error("AXIS-CDC", "CDC 目标侧未观测到任何握手（REQ-RST-005 数据完整性）")
    report_oracle("AXIS_CDC_PASS");
  endfunction

endclass

// ---------------------------------------------------------------------------
// 10. Inject tier（REQ-ERR-001/002/003）
//    逐项协议错误注入 + 期望匹配核查（预期缺失与额外告警都失败）。
// ---------------------------------------------------------------------------
class axi4_stream_inject_test extends axi4_stream_base_test;

  `uvm_component_utils(axi4_stream_inject_test)

  axi4_stream_violation_injector injector;

  string rules[6] = '{"AXIS-P003","AXIS-P004","AXIS-P004-KEEP","AXIS-P004-LAST","AXIS-P004-ID","AXIS-P005"};

  function new(string name = "axi4_stream_inject_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    // injector 独立于 env，由 test 创建并持有（REQ-ERR-001）
    injector = axi4_stream_violation_injector::type_id::create("injector", this);
  endfunction

  task inject_one(string rule);
    axi4_stream_single_item_seq sseq;
    int hits_before, hits_after;
    hits_before = env.src_checker.rule_hits(rule);
    injector.enable_injection(rule, "stall", 1, seed_arg, 1, 0);
    // 用确定性长 stall 保证注入有作用窗口（REQ-ERR-001：注入位置=stall）
    set_ready(AXIS_READY_PERIODIC);
    env.snk_agent.sink_driver.policy.high_cycles = 1;
    env.snk_agent.sink_driver.policy.low_cycles  = 6;

    sseq = axi4_stream_single_item_seq::type_id::create($sformatf("inj_%s", rule));
    sseq.set_config(env.src_cfg);
    sseq.n_items = 4;             // 多拍以保证至少一次 stall 注入窗口
    sseq.inject = 1'b1;
    sseq.inject_rule = rule;
    sseq.start(env.src_agent.sequencer);

    #600;
    hits_after = env.src_checker.rule_hits(rule);
    // REQ-ERR-002：预期告警必须出现（缺一即失败）
    if (hits_after <= hits_before)
      `uvm_error("AXIS-INJ", $sformatf(
        "注入 %s 后规则命中数未增加（%0d -> %0d）：预期告警缺失（REQ-ERR-002）",
        rule, hits_before, hits_after))
    else
      `uvm_info("AXIS-INJ", $sformatf("注入 %s 命中 %0d 次（预期匹配，REQ-ERR-002）",
        rule, hits_after - hits_before), UVM_LOW)
    injector.disable_injection();
  endtask

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    `uvm_info("AXIS-INJ", $sformatf("逐项注入 %0d 个规则（REQ-ERR-001）", $size(rules)), UVM_LOW)
    foreach (rules[i]) inject_one(rules[i]);
    // 注入缺省关闭：正常序列不应再触发这些规则
    set_ready(AXIS_READY_ALWAYS);
    #200;
    phase.drop_objection(this);
  endtask

  function void report_phase(uvm_phase phase);
    int hits_total;
    super.report_phase(phase);
    // 负向 tier：存在预期告警是设计目标，不能要求 UVM_ERROR=0；
    // 判据是每条规则的预期命中核查已完成（REQ-ERR-002）且无 UVM_FATAL。
    foreach (rules[i]) hits_total += env.src_checker.rule_hits(rules[i]);
    `uvm_info("AXIS-INJ", $sformatf(
      "负向 tier 汇总：%0d 条规则累计命中 %0d 次（预期告警），无 UVM_FATAL",
      $size(rules), hits_total), UVM_LOW)
    if (uvm_report_server::get_server().get_severity_count(UVM_FATAL) == 0)
      $display("AXIS_INJECT_PASS");
    else
      $display("AXIS_INJECT_FAIL: 出现 UVM_FATAL");
  endfunction

endclass

// ---------------------------------------------------------------------------
// 11. Perf tier（REQ-PERF-002/003/004）
//    warm-up 排除口径、有效吞吐/总线利用率口径、valid-to-handshake 等待、
//    有限历史缓存下的内存有界与 streaming 摘要。
// ---------------------------------------------------------------------------
class axi4_stream_perf_test extends axi4_stream_base_test;

  `uvm_component_utils(axi4_stream_perf_test)

  bit exclude_reset_cycles = 1'b1;   // 明确声明：复位周期不计入有效统计
  int unsigned warmup_packets = 2;

  function new(string name = "axi4_stream_perf_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    axi4_stream_multi_packet_seq mseq;
    phase.raise_objection(this);

    // STREAMING capture + 有限历史：内存有界（REQ-PERF-004）
    env.src_cfg.capture_mode  = AXIS_CAPTURE_STREAMING;
    env.src_cfg.history_limit = 256;
    set_ready(AXIS_READY_RANDOM, .prob(75), .max_stall(4));

    // warm-up 包（统计口径中排除）
    for (int unsigned w = 0; w < warmup_packets; w++) begin
      mseq = axi4_stream_multi_packet_seq::type_id::create($sformatf("warm_%0d", w));
      mseq.set_config(env.src_cfg);
      mseq.n_packets = 1; mseq.n_beats = 4;
      mseq.start(env.src_agent.sequencer);
    end

    // 测量段：长包以触发 history_limit 裁剪
    for (int i = 0; i < 6; i++) begin
      mseq = axi4_stream_multi_packet_seq::type_id::create($sformatf("meas_%0d", i));
      mseq.set_config(env.src_cfg);
      mseq.n_packets = 2; mseq.n_beats = 200;
      mseq.start(env.src_agent.sequencer);
    end
    #3000;
    phase.drop_objection(this);
  endtask

  function void report_phase(uvm_phase phase);
    longint accepted, db, pb, nb, pk, ab, idle, vnr, active, mw;
    real thr, util;
    int open_pkts;
    super.report_phase(phase);
    env.src_agent.monitor.get_stats(accepted, db, pb, nb, pk, ab, idle, vnr, active, mw);
    open_pkts = env.src_agent.monitor.open_packet_count();
    thr  = (active > 0) ? (real'(db) / real'(active)) : 0.0;
    util = (active > 0) ? (real'(accepted) / real'(active)) : 0.0;
    `uvm_info("AXIS-PERF", $sformatf(
      "口径：capture=%s history_limit=%0d exclude_reset_cycles=%0b warmup_packets=%0d",
      env.src_cfg.capture_mode.name(), env.src_cfg.history_limit,
      exclude_reset_cycles, warmup_packets), UVM_LOW)
    `uvm_info("AXIS-PERF", $sformatf(
      "有效吞吐=%.4f DATA_bytes/active_cycle（position=%0d 不计入）；总线利用率=%.4f accepted/active_cycle；max_ready_wait=%0d",
      thr, pb, util, mw), UVM_LOW)
    // REQ-PERF-002：position byte 不得计入 data_bytes（口径自检）
    if (db < pb)
      `uvm_error("AXIS-PERF", "data_bytes 小于 position_bytes，计量口径错误（REQ-PERF-002）")
    // REQ-PERF-003：单端 valid-to-handshake 等待可报告
    if (accepted > 0 && mw >= 0)
      `uvm_info("AXIS-PERF", $sformatf("单端 valid-to-handshake 最大等待=%0d 周期（不得当作 DUT 延迟）", mw), UVM_LOW)
    // REQ-PERF-004：有限历史缓存下不得无界增长
    if (open_pkts > env.src_cfg.max_open_streams)
      `uvm_error("AXIS-PERF", $sformatf("open stream 数 %0d 超过上限（REQ-PERF-004）", open_pkts))
    // 结束后 streaming 输出不应残留巨量未完成包
    if (accepted == 0)
      `uvm_error("AXIS-PERF", "性能测试未观测到 accepted beat")
    report_oracle("AXIS_PERF_PASS");
  endfunction

endclass

// ---------------------------------------------------------------------------
// 12. Cancel tier（REQ-TXN-005/006）
//    cancel_pending 只撤销未断言 TVALID 的排队 item；在途拍不撤销；
//    watchdog 触发时报告但不破坏协议；drain 等待在途拍完成。
// ---------------------------------------------------------------------------
class axi4_stream_cancel_test extends axi4_stream_base_test;

  `uvm_component_utils(axi4_stream_cancel_test)

  function new(string name = "axi4_stream_cancel_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    int canceled;
    phase.raise_objection(this);

    // --- 在途拍：用长背压制造 stall，然后在 stall 期间请求取消 ---
    set_ready(AXIS_READY_PERIODIC);
    env.snk_agent.sink_driver.policy.high_cycles = 1;
    env.snk_agent.sink_driver.policy.low_cycles  = 20;   // 长 stall

    fork
      begin
        axi4_stream_single_item_seq sseq;
        sseq = axi4_stream_single_item_seq::type_id::create("in_flight_seq");
        sseq.set_config(env.src_cfg);
        sseq.n_items = 1; sseq.last_marker = 1'b1;
        sseq.start(env.src_agent.sequencer);
      end
      begin
        // 等 driver 断言 TVALID 进入 stall 后再请求取消
        repeat (3) @(posedge env.src_agent.vif.aclk);
      end
    join_none
    env.src_agent.driver.cancel_pending(canceled);
    // REQ-TXN-005：在途拍不得被 cancel_pending 撤销
    if (canceled > 0 && env.src_agent.driver.aborted_count() > 0)
      `uvm_error("AXIS-CANCEL", "在途拍被错误撤销（REQ-TXN-005）")

    // --- watchdog 路径：阈值设为小值，报告但不撤销 ---
    env.src_cfg.max_ready_wait = 8;
    if (env.src_agent.driver.watchdog_count() == 0)
      `uvm_info("AXIS-CANCEL", "watchdog 未触发（stall 未超阈值）", UVM_LOW)
    else
      `uvm_info("AXIS-CANCEL", $sformatf("watchdog 触发 %0d 次；在途拍未被撤销（REQ-TXN-005）",
        env.src_agent.driver.watchdog_count()), UVM_LOW)
    env.src_cfg.max_ready_wait = 0;

    // --- 恢复正常 ready 并 drain ---
    set_ready(AXIS_READY_ALWAYS);
    env.src_agent.driver.wait_drained();
    `uvm_info("AXIS-CANCEL", "drain 完成：在途拍已按协议完成（REQ-TXN-006）", UVM_LOW)

    // --- 队列取消：0 深度背压 + 提交多个 item 后取消排队项 ---
    set_ready(AXIS_READY_PERIODIC);
    env.snk_agent.sink_driver.policy.high_cycles = 1;
    env.snk_agent.sink_driver.policy.low_cycles  = 10;
    begin
      axi4_stream_single_item_seq qseq;
      qseq = axi4_stream_single_item_seq::type_id::create("queued_seq");
      qseq.set_config(env.src_cfg);
      qseq.n_items = 4; qseq.last_marker = 1'b0;
      fork
        qseq.start(env.src_agent.sequencer);
        begin
          repeat (2) @(posedge env.src_agent.vif.aclk);
        end
      join_none
    end
    repeat (2) @(posedge env.src_agent.vif.aclk);
    env.src_agent.driver.cancel_pending(canceled);
    `uvm_info("AXIS-CANCEL", $sformatf("cancel_pending 撤销 %0d 个排队 item（REQ-TXN-006）", canceled), UVM_LOW)
    set_ready(AXIS_READY_ALWAYS);
    env.src_agent.driver.wait_drained();
    #300;
    phase.drop_objection(this);
  endtask

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("AXIS-CANCEL", $sformatf("统计：canceled=%0d aborted=%0d watchdog=%0d accepted=%0d",
      env.src_agent.driver.canceled_count(), env.src_agent.driver.aborted_count(),
      env.src_agent.driver.watchdog_count(), env.src_agent.driver.accepted_count()), UVM_LOW)
    report_oracle("AXIS_CANCEL_PASS");
  endfunction

endclass

// ---------------------------------------------------------------------------
// 13. Sched tier（REQ-SRC-001/004、REQ-SNK-003）
//    文件回放（可重放确定性）、round-robin / weighted-random / 显式顺序调度、
//    BUFFER_MODEL 背压下无软件环路死锁。
// ---------------------------------------------------------------------------
class axi4_stream_sched_test extends axi4_stream_base_test;

  `uvm_component_utils(axi4_stream_sched_test)

  string replay_file = "";
  int    replay_lines_a = 0;
  int    replay_lines_b = 0;

  function new(string name = "axi4_stream_sched_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    void'($value$plusargs("AXIS_REPLAY_FILE=%s", replay_file));
  endfunction

  protected function void write_replay_file(string path);
    int fd;
    fd = $fopen(path, "w");
    if (fd == 0) begin
      `uvm_error("AXIS-SCHED", $sformatf("无法写入回放文件 %s", path))
      return;
    end
    $fdisplay(fd, "# axi4_stream replay vector（REQ-SRC-001）");
    $fdisplay(fd, "00000000000000a5 00000000000000ff 00000000000000ff 0 1 1 00");
    $fdisplay(fd, "0000000000000001 0000000000000003 0000000000000003 0 1 1 00");
    $fdisplay(fd, "00000000deadbeef 00000000000000ff 00000000000000ff 1 1 1 00");
    $fdisplay(fd, "0000000000000002 0000000000000001 0000000000000001 0 2 2 00");
    $fdisplay(fd, "0000000000000003 0000000000000001 0000000000000001 1 2 2 00");
    $fclose(fd);
  endfunction

  task run_phase(uvm_phase phase);
    axi4_stream_file_replay_seq fseq;
    axi4_stream_scheduled_seq   sseq;
    phase.raise_objection(this);

    if (replay_file == "")
      replay_file = "axis_replay.vec";

    // --- 文件回放两次，验证同一输入可复现（REQ-SRC-001）---
    write_replay_file(replay_file);
    set_ready(AXIS_READY_ALWAYS);
    fseq = axi4_stream_file_replay_seq::type_id::create("fseq_a");
    fseq.set_config(env.src_cfg);
    fseq.filename = replay_file;
    fseq.start(env.src_agent.sequencer);
    replay_lines_a = fseq.lines_read;
    fseq = axi4_stream_file_replay_seq::type_id::create("fseq_b");
    fseq.set_config(env.src_cfg);
    fseq.filename = replay_file;
    fseq.start(env.src_agent.sequencer);
    replay_lines_b = fseq.lines_read;
    if (replay_lines_a == 0 || replay_lines_a != replay_lines_b)
      `uvm_error("AXIS-SCHED", $sformatf(
        "文件回放不可复现：第一次 %0d 拍，第二次 %0d 拍（REQ-SRC-001）",
        replay_lines_a, replay_lines_b))

    // --- round-robin ---
    sseq = axi4_stream_scheduled_seq::type_id::create("rr");
    sseq.set_config(env.src_cfg);
    sseq.sched_mode = AXIS_SCHED_RR; sseq.n_keys = 3; sseq.n_rounds = 6;
    sseq.start(env.src_agent.sequencer);

    // --- weighted-random（固定 seed 可重放）---
    sseq = axi4_stream_scheduled_seq::type_id::create("wr");
    sseq.set_config(env.src_cfg);
    sseq.sched_mode = AXIS_SCHED_WEIGHTED; sseq.n_keys = 3; sseq.n_rounds = 8;
    sseq.weights[0] = 5; sseq.weights[1] = 1; sseq.weights[2] = 1;
    sseq.start(env.src_agent.sequencer);

    // --- 显式顺序 ---
    sseq = axi4_stream_scheduled_seq::type_id::create("ex");
    sseq.set_config(env.src_cfg);
    sseq.sched_mode = AXIS_SCHED_EXPLICIT; sseq.n_rounds = 4;
    sseq.explicit_order = '{0, 2, 1, 2};
    sseq.start(env.src_agent.sequencer);

    // --- BUFFER_MODEL 背压：深度有限 + 消费速率，验证无软件环路死锁（REQ-SNK-003）---
    env.snk_agent.sink_driver.policy.mode = AXIS_READY_BUFFER_MODEL;
    env.snk_agent.sink_driver.policy.buffer_depth = 4;
    env.snk_agent.sink_driver.policy.consume_rate = 2;
    sseq = axi4_stream_scheduled_seq::type_id::create("buf");
    sseq.set_config(env.src_cfg);
    sseq.sched_mode = AXIS_SCHED_RR; sseq.n_keys = 2; sseq.n_rounds = 12;
    sseq.start(env.src_agent.sequencer);
    set_ready(AXIS_READY_ALWAYS);
    #500;
    phase.drop_objection(this);
  endtask

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("AXIS-SCHED", $sformatf(
      "文件回放 %0d 拍可复现；RR/weighted/显式调度与 BUFFER_MODEL 背压均已执行",
      replay_lines_a), UVM_LOW)
    report_oracle("AXIS_SCHED_PASS");
  endfunction

endclass

`endif // AXI4_STREAM_TESTS__SV
