// =============================================================================
// File Name   : axi4_stream_smoke_env.sv
// Description : axi4_stream VIP 集成示例环境（单 agent + checker + coverage）
// 依据        : docs/requirement.md（REQ-INT-004：Source-DUT 或 DUT-Sink 例子）
//               docs/user-guide.md §38
//
// 本文件展示最小集成方式：在用户自己的 env 中只装配一个方向的 agent，
// 并把 monitor 的 beat_ap 接到 checker/coverage。
// 与 self_test 的 axi4_stream_smoke_env（双侧 source->DUT->sink 闭环）区分。
// =============================================================================

`ifndef AXI4_STREAM_EXAMPLE_SMOKE_ENV__SV
`define AXI4_STREAM_EXAMPLE_SMOKE_ENV__SV

// error 事件订阅者：把 checker 违规转发给错误覆盖组（REQ-COV-001）
class axis_example_error_sub extends uvm_subscriber #(axi4_stream_error_event);
  `uvm_component_utils(axis_example_error_sub)
  axi4_stream_coverage cov;
  function new(string name = "axis_example_error_sub", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  function void write(axi4_stream_error_event t);
    if (cov != null) cov.sample_error(t);
  endfunction
endclass

class axi4_stream_example_smoke_env extends uvm_env;

  `uvm_component_utils(axi4_stream_example_smoke_env)

  axi4_stream_config   cfg;
  axi4_stream_agent    agent;
  axi4_stream_checker  protocol_checker;
  axi4_stream_coverage coverage;
  axis_example_error_sub error_sub;

  function new(string name = "axi4_stream_example_smoke_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(axi4_stream_config)::get(this, "agent", "cfg", cfg)) begin
      cfg = axi4_stream_config::type_id::create("cfg");
      cfg.role = AXIS_ROLE_SOURCE;
      cfg.role_configured = 1'b1;
      cfg.packet_mode = AXIS_PKT_TLAST;
      cfg.packet_mode_configured = 1'b1;
      uvm_config_db#(axi4_stream_config)::set(this, "agent", "cfg", cfg);
    end
    uvm_config_db#(axi4_stream_config)::set(this, "protocol_checker", "cfg", cfg);
    uvm_config_db#(axi4_stream_config)::set(this, "coverage", "cfg", cfg);
    agent            = axi4_stream_agent::type_id::create("agent", this);
    protocol_checker = axi4_stream_checker::type_id::create("protocol_checker", this);
    coverage         = axi4_stream_coverage::type_id::create("coverage", this);
    error_sub        = axis_example_error_sub::type_id::create("error_sub", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    agent.monitor.beat_ap.connect(coverage.analysis_export);
    error_sub.cov = coverage;
    protocol_checker.error_ap.connect(error_sub.analysis_export);
  endfunction

endclass : axi4_stream_example_smoke_env

`endif // AXI4_STREAM_EXAMPLE_SMOKE_ENV__SV
