// =============================================================================
// File Name   : apb_zerowait_rw_test.sv
// Description : P4 回归专项——ZERO_WAIT 下写后读回数据完整性（RTL-master 采样
//               语义：DUT 在 (ACCESS && PREADY) 沿锁存 prdata，读数据必须在
//               completion 沿前已稳定）。默认 slave_response_mode=APB_ZERO_WAIT
//               （env 默认），写特征值 → 读回比较，读错 0/旧值即失败。
//               P4 修复前：读数据在 completion 拍才 NBA 驱动 → DUT 锁到 0。
// VLNV        : aixsilicon:vip:apb:1.0.0
// =============================================================================

`ifndef APB_ZEROWAIT_RW_TEST__SV
`define APB_ZEROWAIT_RW_TEST__SV

// 定向 sequence：在 master sequencer 上逐笔写 → 读回并比较
class apb_zerowait_rw_seq extends apb_base_sequence;

  `uvm_object_utils(apb_zerowait_rw_seq)

  int errors = 0;
  int num_checks = 0;

  function new(string name = "apb_zerowait_rw_seq");
    super.new(name);
  endfunction

  virtual task body();
    bit [`APB_MAX_DATA_WIDTH-1:0] rdata;
    bit err;
    for (int i = 0; i < 8; i++) begin
      bit [`APB_MAX_DATA_WIDTH-1:0] wdata = (32'hA5A5_0000 + i);
      do_write('h1000 + i*4, wdata, 'hF);
      do_read('h1000 + i*4, rdata, err);
      num_checks++;
      if (rdata !== wdata) begin
        `uvm_error(get_type_name(), $sformatf(
          "P4-ZERO_WAIT: addr=0x%0h write=%08h read-back=%08h (mismatch — read data latched stale/0)",
          'h1000 + i*4, wdata[31:0], rdata[31:0]))
        errors++;
      end
      else begin
        `uvm_info(get_type_name(), $sformatf(
          "P4-ZERO_WAIT: addr=0x%0h read-back=%08h PASS", 'h1000 + i*4, rdata[31:0]), UVM_LOW)
      end
    end
    if (errors != 0) begin
      `uvm_error(get_type_name(), $sformatf("P4-ZERO_WAIT: %0d/%0d read-back mismatches",
                                            errors, num_checks))
    end
    else begin
      `uvm_info(get_type_name(), $sformatf("P4-ZERO_WAIT: %0d read-back checks PASS", num_checks), UVM_LOW)
    end
  endtask

endclass


class apb_zerowait_rw_test extends uvm_test;

  `uvm_component_utils(apb_zerowait_rw_test)

  apb_smoke_env env;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase_);
    super.build_phase(phase_);
    env = apb_smoke_env::type_id::create("env", this);
    // 明确 ZERO_WAIT（env 默认即 ZERO_WAIT；显式关闭其他 tier 覆盖位）
    env.mode_fixed_wait_20 = 0;
    env.mode_random_wait   = 0;
  endfunction

  task run_phase(uvm_phase phase_);
    apb_zerowait_rw_seq seq;
    phase_.raise_objection(this);
    seq = apb_zerowait_rw_seq::type_id::create("seq");
    seq.start(env.master_agent.sequencer);
    #100;
    phase_.drop_objection(this);
  endtask

  function void report_phase(uvm_phase phase_);
    uvm_report_server svr = uvm_report_server::get_server();
    int errs;
    super.report_phase(phase_);
    errs = svr.get_severity_count(UVM_ERROR);
    if (errs != 0) begin
      `uvm_error(get_type_name(), $sformatf(
        "P4-ZERO_WAIT: %0d UVM_ERROR (read-back integrity failed)", errs))
    end
    else begin
      `uvm_info(get_type_name(), "P4-ZERO_WAIT: write/read-back integrity all PASS", UVM_LOW)
    end
  endfunction

endclass

`endif // APB_ZEROWAIT_RW_TEST__SV
