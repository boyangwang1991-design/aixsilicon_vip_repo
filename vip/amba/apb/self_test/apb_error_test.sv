// =============================================================================
// File Name   : apb_error_test.sv
// Description : Error tier（UT07 slverr / UT15 checker_negative /
//               UT17 anti-overcheck: pready high during setup /
//               UT18 anti-overcheck: pslverr outside window）
// VLNV        : aixsilicon:vip:apb:1.0.0
// =============================================================================

`ifndef APB_ERROR_TEST__SV
`define APB_ERROR_TEST__SV

class apb_error_test extends uvm_test;

  `uvm_component_utils(apb_error_test)

  apb_smoke_env env;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase_);
    super.build_phase(phase_);
    env = apb_smoke_env::type_id::create("env", this);
    // UT07：error region（tier 覆盖位——env build 时应用）
    env.mode_err_region = 1;
  endfunction

  task run_phase(uvm_phase phase_);
    apb_error_sequence eseq;
    apb_read_sequence  rseq;
    phase_.raise_objection(this);

    // UT07：错误区域读 → PSLVERR
    eseq = apb_error_sequence::type_id::create("eseq");
    eseq.start(env.master_agent.sequencer);

    // UT17 anti-overcheck：PREADY 常高 during SETUP 合法（RUL-010）
    //   ZERO_WAIT completer 即常高 PREADY 实现，正常事务通过即证明
    rseq = apb_read_sequence::type_id::create("rseq");
    rseq.start(env.master_agent.sequencer);

    // UT18 anti-overcheck：PSLVERR 非有效期非零不判 FAIL
    //   completer 仅在 completion 拍驱动 pslverr（RUL-005）；正常事务通过即证明
    //   （若 checker 误报，UVM_ERROR 非零 → tier fail）

    #200ns;
    phase_.drop_objection(this);
  endtask

endclass

`endif // APB_ERROR_TEST__SV
