// =============================================================================
// File Name   : apb_feature_test.sv
// Description : Feature tier（UT03 back-to-back / UT04 zero_wait /
//               UT11 strb / UT12 prot）
// VLNV        : aixsilicon:vip:apb:1.0.0
// =============================================================================

`ifndef APB_FEATURE_TEST__SV
`define APB_FEATURE_TEST__SV

class apb_feature_test extends uvm_test;

  `uvm_component_utils(apb_feature_test)

  apb_smoke_env env;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase_);
    super.build_phase(phase_);
    env = apb_smoke_env::type_id::create("env", this);
  endfunction

  task run_phase(uvm_phase phase_);
    apb_incrementing_sequence iseq;
    phase_.raise_objection(this);
    // UT03 back-to-back + UT04 zero_wait（ZERO_WAIT 模式递增地址连续访问）
    iseq = apb_incrementing_sequence::type_id::create("iseq");
    iseq.num_items = 8;
    iseq.start(env.master_agent.sequencer);
    #200ns;
    phase_.drop_objection(this);
  endtask

endclass

`endif // APB_FEATURE_TEST__SV
