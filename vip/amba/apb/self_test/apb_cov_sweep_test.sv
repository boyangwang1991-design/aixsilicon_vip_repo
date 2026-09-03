// =============================================================================
// File Name   : apb_cov_sweep_test.sv
// Description : G4 coverage sweep tier——定向打遍 CP/CR bins
//               配合 env.mode_cov_sweep（RANDOM_WAIT max=32 + slverr 区域）
//               覆盖：PSTRB 10 shape / PPROT×RW / 地址区域+对齐 / slverr 响应
//               + reset-abort（APB_ABORTED，PRO-016/UT10）
// VLNV        : aixsilicon:vip:apb:1.0.0
// =============================================================================

`ifndef APB_COV_SWEEP_TEST__SV
`define APB_COV_SWEEP_TEST__SV

class apb_cov_sweep_test extends uvm_test;

  `uvm_component_utils(apb_cov_sweep_test)

  apb_smoke_env env;
  virtual apb_if vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase_);
    super.build_phase(phase_);
    if (!uvm_config_db#(virtual apb_if)::get(this, "", "vif", vif))
      `uvm_fatal(get_type_name(), "virtual interface 'vif' not set")
    env = apb_smoke_env::type_id::create("env", this);
    env.mode_cov_sweep = 1;
  endfunction

  task run_phase(uvm_phase phase_);
    apb_cov_sweep_sequence sseq;
    apb_random_sequence    rseq;
    apb_write_sequence     wseq;
    phase_.raise_objection(this);
    // 定向 sweep（覆盖字段 bins）
    sseq = apb_cov_sweep_sequence::type_id::create("sseq");
    sseq.start(env.master_agent.sequencer);
    // 随机补充（wait/pattern 分布 + cross 组合）
    rseq = apb_random_sequence::type_id::create("rseq");
    rseq.num_items = 24;
    rseq.addr_min  = 'h0000;
    rseq.addr_max  = 'h8FFF;
    rseq.start(env.master_agent.sequencer);
    // reset-abort（PR0-016/UT10）：tb 层 +ntb_reset_abort 在长 wait 写事务中复位；
    // 此处仅确保存在长 ACCESS 事务供复位中断（FIXED_WAIT=32）
    begin
      env.s_cfg.slave_response_mode = APB_FIXED_WAIT;
      env.s_cfg.default_wait_cycles = 32;
      wseq = apb_write_sequence::type_id::create("wseq_abort");
      wseq.num_writes = 1;
      wseq.start(env.master_agent.sequencer);
    end
    #300ns;
    phase_.drop_objection(this);
  endtask

endclass

`endif // APB_COV_SWEEP_TEST__SV