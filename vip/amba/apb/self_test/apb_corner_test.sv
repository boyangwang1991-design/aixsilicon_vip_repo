// =============================================================================
// File Name   : apb_corner_test.sv
// Description : Corner tier（UT05 random_wait / UT06 long_wait——FIXED_WAIT 配置）
// VLNV        : aixsilicon:vip:apb:1.0.0
// =============================================================================

`ifndef APB_CORNER_TEST__SV
`define APB_CORNER_TEST__SV

class apb_corner_test extends uvm_test;

  `uvm_component_utils(apb_corner_test)

  apb_smoke_env env;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase_);
    super.build_phase(phase_);
    env = apb_smoke_env::type_id::create("env", this);
    // UT06：长 wait（tier 覆盖位——env build 时应用）
    env.mode_fixed_wait_20 = 1;
  endfunction

  task run_phase(uvm_phase phase_);
    apb_write_sequence wseq;
    phase_.raise_objection(this);
    wseq = apb_write_sequence::type_id::create("wseq");
    wseq.num_writes = 4;
    wseq.start(env.master_agent.sequencer);
    #400ns;
    phase_.drop_objection(this);
  endtask

endclass

`endif // APB_CORNER_TEST__SV
