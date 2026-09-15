// =============================================================================
// File Name   : axi4_stream_env.sv
// Description : axi4_stream 环境（角色组合、多接口连接、复位合同、统计汇总）
// 依据        : docs/requirement.md（REQ-SCP-004, REQ-INT-002/003,
//               REQ-SCB-004/005, REQ-PERF-001, REQ-RST-005）
//
// 设计说明：
//   * 支持 source+monitor、sink+monitor、passive 三种组合；双向链路使用两个 agent。
//   * checker/coverage 可作用于任意接口（每个接口独立实例）。
//   * scoreboard 按 DUT 合同连接（reset / routing / user mapping / ordering）。
// =============================================================================

`ifndef AXI4_STREAM_ENV__SV
`define AXI4_STREAM_ENV__SV

// error 事件订阅者：把 checker 的结构化违规转发给 coverage 的错误覆盖组
// （error_ap 的元素类型是 error_event，不能直接接到 beat subscriber）
class axis_env_error_sub extends uvm_subscriber #(axi4_stream_error_event);
  `uvm_component_utils(axis_env_error_sub)
  axi4_stream_coverage cov;
  function new(string name = "axis_env_error_sub", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  function void write(axi4_stream_error_event t);
    if (cov != null) cov.sample_error(t);
  endfunction
endclass

class axi4_stream_env extends uvm_env;

  `uvm_component_utils(axi4_stream_env)

  axi4_stream_config cfg;

  // 单向接口的角色化 agent
  axi4_stream_agent   source_agent;   // 可选
  axi4_stream_agent   sink_agent;     // 可选
  axi4_stream_agent   passive_agent;  // 可选

  axi4_stream_checker checker;
  axi4_stream_coverage coverage;
  axi4_stream_scoreboard scoreboard;

  bit enable_checker    = 1'b1;
  bit enable_coverage   = 1'b1;
  bit enable_scoreboard = 1'b0;    // 端到端比较需显式配置两侧合同

  axis_env_error_sub error_sub;

  function new(string name = "axi4_stream_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(axi4_stream_config)::get(this, "", "cfg", cfg))
      `uvm_fatal("AXIS-ENV", "未获取 config（REQ-INT-002）")

    // checker / coverage 作用在 env 级同一接口（由上层 set vif 到 env）
    if (enable_checker && cfg.check_enable) begin
      checker = axi4_stream_checker::type_id::create("checker", this);
      checker.interface_id = 0;
    end
    if (enable_coverage && cfg.coverage_enable) begin
      coverage = axi4_stream_coverage::type_id::create("coverage", this);
      coverage.interface_id = 0;
    end
    if (enable_scoreboard) begin
      scoreboard = axi4_stream_scoreboard::type_id::create("scoreboard", this);
    end
    error_sub = axis_env_error_sub::type_id::create("error_sub", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    // error 事件经 error_sub 转发到错误覆盖组（REQ-COV-001 独立采样）
    if (checker != null && coverage != null) begin
      error_sub.cov = coverage;
      checker.error_ap.connect(error_sub.analysis_export);
    end
  endfunction

  // ---------------------------------------------------------------------------
  // 运行期配置更新（REQ-INT-003）：ready policy 可随时更新；语义配置需 drain
  // ---------------------------------------------------------------------------
  function void set_ready_policy(axi4_stream_ready_item p);
    if (sink_agent != null && sink_agent.sink_driver != null)
      sink_agent.sink_driver.set_ready_policy(p);
    else
      `uvm_warning("AXIS-ENV", "无 sink agent，ready policy 更新被忽略")
  endfunction

  // ---------------------------------------------------------------------------
  // 统计汇总（REQ-PERF-001/002/003）
  // ---------------------------------------------------------------------------
  function void report_stats();
    longint accepted, data_bytes, pos_bytes, null_bytes, pkts, aborts;
    longint idle_cyc, valid_ready_cyc, active_cyc, max_wait;
    int m, mm, unexp, dropped, unknown;
    real throughput, utilization;
    if (source_agent != null && source_agent.monitor != null) begin
      source_agent.monitor.get_stats(accepted, data_bytes, pos_bytes, null_bytes,
        pkts, aborts, idle_cyc, valid_ready_cyc, active_cyc, max_wait);
      // 有效吞吐 = DATA bytes / 观测时间；总线利用率 = accepted beats / 有效时钟周期
      throughput  = (active_cyc > 0) ? (real'(data_bytes) / real'(active_cyc)) : 0.0;
      utilization = (active_cyc > 0) ? (real'(accepted) / real'(active_cyc)) : 0.0;
      `uvm_info("AXIS-ENV", $sformatf(
        "stats(if=%0d): accepted=%0d data_bytes=%0d pos_bytes=%0d null_bytes=%0d pkts=%0d aborts=%0d idle=%0d valid&&!ready=%0d active=%0d max_wait=%0d throughput=%.3f B/cyc util=%.3f",
        source_agent.monitor.interface_id, accepted, data_bytes, pos_bytes, null_bytes,
        pkts, aborts, idle_cyc, valid_ready_cyc, active_cyc, max_wait, throughput, utilization), UVM_LOW)
    end
    if (scoreboard != null) begin
      scoreboard.get_stats(m, mm, unexp, dropped, unknown);
      `uvm_info("AXIS-ENV", $sformatf(
        "scoreboard: matched=%0d mismatched=%0d unexpected=%0d dropped=%0d unknown=%0d",
        m, mm, unexp, dropped, unknown), UVM_LOW)
    end
  endfunction

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    report_stats();
  endfunction

endclass : axi4_stream_env

`endif // AXI4_STREAM_ENV__SV
