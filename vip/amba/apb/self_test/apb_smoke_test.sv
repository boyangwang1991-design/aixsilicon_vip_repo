// =============================================================================
// File Name   : apb_smoke_test.sv
// Description : Smoke test（UT01/UT02：basic write/read 回环）
// VLNV        : aixsilicon:vip:apb:1.0.0
// =============================================================================

`ifndef APB_SMOKE_TEST__SV
`define APB_SMOKE_TEST__SV

class apb_smoke_test extends uvm_test;

  `uvm_component_utils(apb_smoke_test)

  apb_smoke_env env;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase_);
    super.build_phase(phase_);
    env = apb_smoke_env::type_id::create("env", this);
  endfunction

  task run_phase(uvm_phase phase_);
    apb_write_sequence wseq;
    apb_read_sequence  rseq;
    phase_.raise_objection(this);
    wseq = apb_write_sequence::type_id::create("wseq");
    rseq = apb_read_sequence::type_id::create("rseq");
    wseq.num_writes = 4;
    rseq.num_reads  = 4;
    // 经 master sequencer 启动（env.agent.sequencer 由 ADR-1 结构提供）
    // loopback 场景中 slave agent 的 completer 已激活
    wseq.start(env.master_agent.sequencer);
    rseq.start(env.master_agent.sequencer);
    #200ns;
    phase_.drop_objection(this);
  endtask

endclass

`endif // APB_SMOKE_TEST__SV
