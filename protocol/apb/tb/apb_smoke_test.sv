// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 AIXSILICON
//
// apb_smoke_test.sv — APB smoke 测试用例：Master 写读 loopback。
`ifndef APB_SMOKE_TEST_SV
`define APB_SMOKE_TEST_SV

package apb_smoke_pkg;

  import uvm_pkg::*;
  import apb_pkg::*;
  `include "uvm_macros.svh"

  class apb_smoke_test extends uvm_test;
    `uvm_component_utils(apb_smoke_test)

    apb_smoke_env env;

    function new(string name = "apb_smoke_test", uvm_component parent = null);
      super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      env = apb_smoke_env::type_id::create("env", this);
    endfunction

    virtual task run_phase(uvm_phase phase);
      apb_write_seq wseq;
      apb_read_seq  rseq;
      phase.raise_objection(this);
      begin
        wseq = apb_write_seq::type_id::create("wseq");
        wseq.num_trans = 8;
        wseq.start(env.apb_master.sqr);
        rseq = apb_read_seq::type_id::create("rseq");
        rseq.num_trans = 8;
        rseq.start(env.apb_master.sqr);
      end
      phase.drop_objection(this);
    endtask
  endclass : apb_smoke_test

endpackage : apb_smoke_pkg

`endif
