// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 AIXSILICON
//
// apb_coverage.sv — APB 功能覆盖（对应 docs/coverage_plan.md 的 COV-APB-*）。
`ifndef APB_COVERAGE_SV
`define APB_COVERAGE_SV

package apb_pkg;

  class apb_coverage extends uvm_subscriber #(apb_item);
    `uvm_component_utils(apb_coverage)

    function new(string name = "apb_coverage", uvm_component parent = null);
      super.new(name, parent);
    endfunction

    // COV-APB-002：读写交叉
    covergroup cg_rw;
      option.per_instance = 1;
      cp_dir: coverpoint item.dir {
        bins rd = {APB_READ};
        bins wr = {APB_WRITE};
      }
    endgroup

    // COV-APB-003：wait 状态覆盖
    covergroup cg_wait;
      option.per_instance = 1;
      cp_wait: coverpoint item.wait_cycles {
        bins none = {0};
        bins one  = {1};
        bins many = {[2:4]};
        bins more = {[5:$]};
      }
    endgroup

    // COV-APB-004：error 响应覆盖
    covergroup cg_err;
      option.per_instance = 1;
      cp_err: coverpoint item.error_en;
    endgroup

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      cg_rw   = new();
      cg_wait = new();
      cg_err  = new();
    endfunction

    virtual function void write(apb_item t);
      item = t;
      cg_rw.sample();
      cg_wait.sample();
      cg_err.sample();
    endfunction
  endclass : apb_coverage

endpackage : apb_pkg

`endif
