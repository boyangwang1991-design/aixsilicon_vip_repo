// =============================================================================
// File Name   : axi4_stream_smoke_env.sv
// Description : axi4_stream VIP Self Test 环境（source -> DUT -> sink 双侧闭环）
// 依据        : docs/requirement.md（REQ-VAL-001/002, REQ-SCB-007,
//               REQ-SCP-004, REQ-INT-002）
//
// 设计说明：
//   * 独立验证结构：source agent 驱动 fixture，sink agent 接收；两侧各自 monitor
//     采样 → scoreboard 比较（monitor 事实，不使用 driver 缓存作为 oracle）。
//   * 直连/透明 DUT 时 compare_mode=EXACT_BEAT；宽度变换时 LOGICAL_STREAM。
// =============================================================================

`ifndef AXI4_STREAM_SMOKE_ENV__SV
`define AXI4_STREAM_SMOKE_ENV__SV

// reset 事件转发订阅者（一个组件只能有一个同名 write 回调，因此用独立订阅者）
class axis_reset_sub extends uvm_subscriber #(axi4_stream_observed_packet);
  `uvm_component_utils(axis_reset_sub)
  axi4_stream_coverage cov;
  function new(string name = "axis_reset_sub", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  function void write(axi4_stream_observed_packet t);
    if (cov != null) cov.sample_reset(4, 1'b1);
  endfunction
endclass

// error 事件转发订阅者（error_ap -> 错误覆盖组）
class axis_error_sub extends uvm_subscriber #(axi4_stream_error_event);
  `uvm_component_utils(axis_error_sub)
  axi4_stream_coverage cov;
  function new(string name = "axis_error_sub", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  function void write(axi4_stream_error_event t);
    if (cov != null) cov.sample_error(t);
  endfunction
endclass

class axi4_stream_smoke_env extends uvm_env;

  `uvm_component_utils(axi4_stream_smoke_env)

  axi4_stream_config  src_cfg;
  axi4_stream_config  snk_cfg;
  axi4_stream_agent   src_agent;
  axi4_stream_agent   snk_agent;
  axi4_stream_checker src_checker;
  axi4_stream_checker snk_checker;
  axi4_stream_coverage src_cov;
  axi4_stream_coverage snk_cov;
  axi4_stream_scoreboard scoreboard;

  bit enable_scoreboard = 1'b1;
  bit enable_checker    = 1'b1;
  bit enable_coverage   = 1'b1;

  axis_reset_sub src_reset_sub;
  axis_reset_sub snk_reset_sub;
  axis_error_sub src_error_sub;
  axis_error_sub snk_error_sub;

  function new(string name = "axi4_stream_smoke_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    string cfg_cov_file;
    super.build_phase(phase);
    if (uvm_config_db#(string)::get(this, "", "cov_export_file", cfg_cov_file))
      cov_export_file = cfg_cov_file;
    if (!uvm_config_db#(axi4_stream_config)::get(this, "src_agent", "cfg", src_cfg))
      `uvm_fatal("AXIS-ENV", "缺少 src_cfg（REQ-INT-002）")
    if (!uvm_config_db#(axi4_stream_config)::get(this, "snk_agent", "cfg", snk_cfg))
      `uvm_fatal("AXIS-ENV", "缺少 snk_cfg（REQ-INT-002）")

    // 两个单向 agent（REQ-SCP-004：双向链路使用两个 agent）
    uvm_config_db#(axi4_stream_config)::set(this, "src_agent", "cfg", src_cfg);
    uvm_config_db#(axi4_stream_config)::set(this, "snk_agent", "cfg", snk_cfg);
    src_agent = axi4_stream_agent::type_id::create("src_agent", this);
    snk_agent = axi4_stream_agent::type_id::create("snk_agent", this);

    if (enable_checker) begin
      uvm_config_db#(axi4_stream_config)::set(this, "src_checker", "cfg", src_cfg);
      uvm_config_db#(axi4_stream_config)::set(this, "snk_checker", "cfg", snk_cfg);
      src_checker = axi4_stream_checker::type_id::create("src_checker", this);
      snk_checker = axi4_stream_checker::type_id::create("snk_checker", this);
      src_checker.interface_id = 0;
      snk_checker.interface_id = 1;
    end
    if (enable_coverage) begin
      uvm_config_db#(axi4_stream_config)::set(this, "src_cov", "cfg", src_cfg);
      uvm_config_db#(axi4_stream_config)::set(this, "snk_cov", "cfg", snk_cfg);
      src_cov = axi4_stream_coverage::type_id::create("src_cov", this);
      snk_cov = axi4_stream_coverage::type_id::create("snk_cov", this);
      src_cov.interface_id = 0;
      snk_cov.interface_id = 1;
    end
    if (enable_scoreboard) begin
      uvm_config_db#(axi4_stream_config)::set(this, "scoreboard", "cfg", src_cfg);
      scoreboard = axi4_stream_scoreboard::type_id::create("scoreboard", this);
    end
    src_reset_sub = axis_reset_sub::type_id::create("src_reset_sub", this);
    snk_reset_sub = axis_reset_sub::type_id::create("snk_reset_sub", this);
    src_error_sub = axis_error_sub::type_id::create("src_error_sub", this);
    snk_error_sub = axis_error_sub::type_id::create("snk_error_sub", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    // error_ap 的元素类型为 error_event，必须经 error_sub 转发到覆盖组
    if (src_checker != null && src_cov != null) begin
      src_error_sub.cov = src_cov;
      src_checker.error_ap.connect(src_error_sub.analysis_export);
    end
    if (snk_checker != null && snk_cov != null) begin
      snk_error_sub.cov = snk_cov;
      snk_checker.error_ap.connect(snk_error_sub.analysis_export);
    end
    // scoreboard：输入侧 = source 方向 monitor 组包；输出侧 = sink 方向 monitor 组包
    if (scoreboard != null) begin
      src_agent.monitor.packet_ap.connect(scoreboard.input_imp);
      snk_agent.monitor.packet_ap.connect(scoreboard.output_imp);
    end
    // reset 覆盖独立采样（REQ-COV-001）
    if (src_cov != null) begin
      src_agent.monitor.beat_ap.connect(src_cov.analysis_export);
      src_reset_sub.cov = src_cov;
      src_agent.monitor.reset_ap.connect(src_reset_sub.analysis_export);
    end
    if (snk_cov != null) begin
      snk_agent.monitor.beat_ap.connect(snk_cov.analysis_export);
      snk_reset_sub.cov = snk_cov;
      snk_agent.monitor.reset_ap.connect(snk_reset_sub.analysis_export);
    end
  endfunction

  function void start_of_simulation_phase(uvm_phase phase);
    super.start_of_simulation_phase(phase);
    if (src_cov != null) src_cov.sample_config();
    if (snk_cov != null) snk_cov.sample_config();
  endfunction

  // 覆盖率 bin 导出：写入 build 内文件（G4 需要完整 bin->hit 映射）
  string cov_export_file = "";
  bit    cov_exported    = 1'b0;

  function void export_coverage_bins();
    int fd;
    if (cov_exported) return;
    cov_exported = 1'b1;
    if (cov_export_file == "") return;
    fd = $fopen(cov_export_file, "w");
    if (fd == 0) begin
      `uvm_error("AXIS-ENV", $sformatf("无法写入覆盖率导出文件 %s", cov_export_file))
      return;
    end
    $fdisplay(fd, "VIP_COVERAGE_BEGIN");
    if (src_cov != null) begin
      $fdisplay(fd, "SRC.feature=%s", src_cov.feature_bins_json());
      $fdisplay(fd, "SRC.cross=%s", src_cov.cross_bins_json());
      $fdisplay(fd, "SRC.groups=%s", src_cov.groups_json());
    end
    if (snk_cov != null) begin
      $fdisplay(fd, "SNK.feature=%s", snk_cov.feature_bins_json());
      $fdisplay(fd, "SNK.cross=%s", snk_cov.cross_bins_json());
      $fdisplay(fd, "SNK.groups=%s", snk_cov.groups_json());
    end
    $fdisplay(fd, "VIP_COVERAGE_END");
    $fclose(fd);
    `uvm_info("AXIS-ENV", $sformatf("覆盖率 bin 已导出到 %s", cov_export_file), UVM_LOW)
  endfunction

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    report_stats();
    export_coverage_bins();
  endfunction

  function void report_stats();
    longint accepted, data_bytes, pos_bytes, null_bytes, pkts, aborts;
    longint idle_cyc, vnr, active_cyc, max_wait;
    int m, mm, unexp, dropped, unknown;
    real throughput, utilization;
    src_agent.monitor.get_stats(accepted, data_bytes, pos_bytes, null_bytes,
      pkts, aborts, idle_cyc, vnr, active_cyc, max_wait);
    throughput  = (active_cyc > 0) ? (real'(data_bytes) / real'(active_cyc)) : 0.0;
    utilization = (active_cyc > 0) ? (real'(accepted) / real'(active_cyc)) : 0.0;
    `uvm_info("AXIS-ENV", $sformatf(
      "SRC if=0 accepted=%0d data_bytes=%0d pos=%0d null=%0d pkts=%0d aborts=%0d idle=%0d valid&&!ready=%0d active=%0d max_wait=%0d throughput=%.3f util=%.3f",
      accepted, data_bytes, pos_bytes, null_bytes, pkts, aborts, idle_cyc, vnr,
      active_cyc, max_wait, throughput, utilization), UVM_LOW)
    if (scoreboard != null) begin
      scoreboard.get_stats(m, mm, unexp, dropped, unknown);
      `uvm_info("AXIS-ENV", $sformatf(
        "SCOREBOARD matched=%0d mismatched=%0d unexpected=%0d dropped=%0d unknown=%0d",
        m, mm, unexp, dropped, unknown), UVM_LOW)
    end
  endfunction

endclass : axi4_stream_smoke_env

`endif // AXI4_STREAM_SMOKE_ENV__SV
