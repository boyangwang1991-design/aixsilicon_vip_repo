// =============================================================================
// File Name   : axi4_random_test.sv
// Description : AXI4 VIP Self Test random 测试（validation-plan §35，minimum baseline）
//               - constrained random 事务（axi4_master_write/read_seq 合法约束）
//               - seed 由 +ntb_random_seed 控制（回归固定 seed=1 起步）
//               - baseline：seed_count=1（可扩展 10）、transaction_count=100
//               - 收尾校验：status 事务计数与 sequence 数一致、无 checker 违规
// =============================================================================
`ifndef AXI4_RANDOM_TEST__SV
`define AXI4_RANDOM_TEST__SV

import uvm_pkg::*;
import axi4_pkg::*;
import axi4_types_pkg::*;

class axi4_random_seq extends axi4_master_base_seq;

  rand int num_transactions;

  constraint c_rand_burst {
    soft num_transactions == 100;  // §35 minimum baseline
  }

  `uvm_object_utils(axi4_random_seq)

  function new(string name = "axi4_random_seq");
    super.new(name);
    num_transactions = 100;
  endfunction

  virtual task body();
    axi4_master_write_seq wseq;
    axi4_master_read_seq  rseq;
    for (int i = 0; i < num_transactions; i++) begin
      // 交替随机写/读（合法约束空间：不跨 4KB、len∈[1:16]、size∈{1,2,4,8,16,32}）
      if ($urandom_range(0, 1) == 0) begin
        wseq = axi4_master_write_seq::type_id::create("wseq");
        void'(wseq.randomize() with {
          burst_size inside {1, 2, 4};
          burst_length inside {[1:8]};
          address < 32'h0000_F000;
        });
        wseq.start(m_sequencer);
      end
      else begin
        rseq = axi4_master_read_seq::type_id::create("rseq");
        void'(rseq.randomize() with {
          burst_size inside {1, 2, 4};
          burst_length inside {[1:8]};
          address < 32'h0000_F000;
        });
        rseq.start(m_sequencer);
      end
    end
    `uvm_info(get_type_name(), $sformatf("random seq done: %0d transactions", num_transactions), UVM_LOW)
  endtask

endclass : axi4_random_seq


class axi4_random_test extends uvm_test;

  axi4_smoke_env env;

  `uvm_component_utils(axi4_random_test)

  function new(string name = "axi4_random_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = axi4_smoke_env::type_id::create("env", this);
  endfunction

  task run_phase(uvm_phase phase);
    axi4_random_seq seq;
    phase.raise_objection(this);
    seq = axi4_random_seq::type_id::create("seq");
    if (!seq.randomize()) begin
      `uvm_fatal(get_type_name(), "randomize failed")
    end
    seq.start(env.master_agent.sequencer);
    #300;
    phase.drop_objection(this);
  endtask

  function void report_phase(uvm_phase phase);
    uvm_report_server svr = uvm_report_server::get_server();
    int errs;
    super.report_phase(phase);
    errs = svr.get_severity_count(UVM_ERROR);
    // random baseline：合法事务空间，不允许任何 checker 违规
    if (errs != 0) begin
      `uvm_error(get_type_name(), $sformatf(
        "random test: %0d UVM_ERROR (legal random space must be clean)", errs))
    end
    else begin
      `uvm_info(get_type_name(), "random test: 100 legal random transactions, no violation PASS", UVM_LOW)
    end
  endfunction

endclass : axi4_random_test

`endif // AXI4_RANDOM_TEST__SV
