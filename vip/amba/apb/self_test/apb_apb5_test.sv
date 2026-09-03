// =============================================================================
// File Name   : apb_apb5_test.sv
// Description : APB5 专项实例（UT13 USER / UT14 WAKEUP / UT20 RME-PNSE / UT21 CHK）
//               需配合 tb5（HAS_PNSE/HAS_PWAKEUP/HAS_CHECK/USER 全开）
//               定向打 CP-07（PAS 4 bins：PNSE×PPROT[1]）+ CP-05 + USER 三宽度
// VLNV        : aixsilicon:vip:apb:1.0.0
// =============================================================================

`ifndef APB_APB5_TEST__SV
`define APB_APB5_TEST__SV

class apb_apb5_test extends uvm_test;

  `uvm_component_utils(apb_apb5_test)

  apb_smoke_env env;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase_);
    super.build_phase(phase_);
    env = apb_smoke_env::type_id::create("env", this);
    env.mode_apb5 = 1;
  endfunction

  task run_phase(uvm_phase phase_);
    apb_apb5_sequence sseq;
    phase_.raise_objection(this);
    sseq = apb_apb5_sequence::type_id::create("sseq");
    sseq.start(env.master_agent.sequencer);
    #200ns;
    phase_.drop_objection(this);
  endtask

endclass

`endif // APB_APB5_TEST__SV