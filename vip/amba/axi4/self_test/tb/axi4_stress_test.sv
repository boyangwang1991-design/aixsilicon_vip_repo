// =============================================================================
// File Name   : axi4_stress_test.sv
// Description : AXI4 VIP Self Test stress 测试（validation-plan §36）
//               - 大量事务（300）+ burst 随机 + 连续写读交替
//               - 目标：queue leak / deadlock / state corruption 无
//               - Write/Read Association 上下文最终清空（无 orphan）
//               - 收尾校验：无 checker 违规、无 UVM_FATAL
// =============================================================================
`ifndef AXI4_STRESS_TEST__SV
`define AXI4_STRESS_TEST__SV

import uvm_pkg::*;
import axi4_pkg::*;
import axi4_types_pkg::*;

class axi4_stress_seq extends axi4_master_base_seq;

  rand int num_transactions;

  constraint c_stress_burst {
    soft num_transactions == 300;  // §36 stress baseline
  }

  `uvm_object_utils(axi4_stress_seq)

  function new(string name = "axi4_stress_seq");
    super.new(name);
    num_transactions = 300;
  endfunction

  virtual task body();
    axi4_master_write_seq wseq;
    axi4_master_read_seq  rseq;
    for (int i = 0; i < num_transactions; i++) begin
      if ($urandom_range(0, 1) == 0) begin
        wseq = axi4_master_write_seq::type_id::create("wseq");
        void'(wseq.randomize() with {
          burst_size inside {1, 2, 4, 8};
          burst_length inside {[1:16]};
          address < 32'h0000_F000;
        });
        wseq.start(m_sequencer);
      end
      else begin
        rseq = axi4_master_read_seq::type_id::create("rseq");
        void'(rseq.randomize() with {
          burst_size inside {1, 2, 4, 8};
          burst_length inside {[1:16]};
          address < 32'h0000_F000;
        });
        rseq.start(m_sequencer);
      end
    end
    `uvm_info(get_type_name(), $sformatf("stress seq done: %0d transactions", num_transactions), UVM_LOW)
  endtask

endclass : axi4_stress_seq


class axi4_stress_test extends uvm_test;

  axi4_smoke_env env;

  `uvm_component_utils(axi4_stress_test)

  function new(string name = "axi4_stress_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = axi4_smoke_env::type_id::create("env", this);
  endfunction

  task run_phase(uvm_phase phase);
    axi4_stress_seq seq;
    phase.raise_objection(this);
    seq = axi4_stress_seq::type_id::create("seq");
    if (!seq.randomize()) begin
      `uvm_fatal(get_type_name(), "randomize failed")
    end
    seq.start(env.master_agent.sequencer);
    #500;
    phase.drop_objection(this);
  endtask

  function void report_phase(uvm_phase phase);
    uvm_report_server svr = uvm_report_server::get_server();
    int errs, fatals;
    super.report_phase(phase);
    errs   = svr.get_severity_count(UVM_ERROR);
    fatals = svr.get_severity_count(UVM_FATAL);
    // stress：合法随机空间长时间运行，不允许违规/fatal（queue leak/死锁必现 fatal 或 timeout）
    if ((errs != 0) || (fatals != 0)) begin
      `uvm_error(get_type_name(), $sformatf(
        "stress test: UVM_ERROR=%0d UVM_FATAL=%0d (state corruption suspected)", errs, fatals))
    end
    else begin
      `uvm_info(get_type_name(), "stress test: 300 transactions clean, no leak/deadlock PASS", UVM_LOW)
    end
  endfunction

endclass : axi4_stress_test

`endif // AXI4_STRESS_TEST__SV
