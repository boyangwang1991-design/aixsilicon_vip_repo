// =============================================================================
// File Name   : apb_random_test.sv
// Description : Random tier（constrained random baseline，seed=1 可复现）
// VLNV        : aixsilicon:vip:apb:1.0.0
// =============================================================================

`ifndef APB_RANDOM_TEST__SV
`define APB_RANDOM_TEST__SV

class apb_random_test extends uvm_test;

  `uvm_component_utils(apb_random_test)

  apb_smoke_env env;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase_);
    super.build_phase(phase_);
    env = apb_smoke_env::type_id::create("env", this);
    env.mode_random_wait = 1;
  endfunction

  task run_phase(uvm_phase phase_);
    apb_random_sequence rseq;
    phase_.raise_objection(this);
    rseq = apb_random_sequence::type_id::create("rseq");
    rseq.num_items = 16;
    rseq.start(env.master_agent.sequencer);
    #300ns;
    phase_.drop_objection(this);
  endtask

endclass

`endif // APB_RANDOM_TEST__SV
