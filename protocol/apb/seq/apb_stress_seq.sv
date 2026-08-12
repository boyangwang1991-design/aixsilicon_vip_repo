// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 AIXSILICON
//
// apb_stress_seq.sv — APB 压力序列：随机 wait、地址扫描、连续读写。
`ifndef APB_STRESS_SEQ_SV
`define APB_STRESS_SEQ_SV

package apb_pkg;

  class apb_stress_seq extends apb_base_seq;
    `uvm_object_utils(apb_stress_seq)

    rand bit [31:0] addr_lo = 32'h0;
    rand bit [31:0] addr_hi = 32'h1000;

    function new(string name = "apb_stress_seq");
      super.new(name);
    endfunction

    task body();
      repeat (num_trans) begin
        `uvm_create(req)
        req.addr   = $urandom_range(addr_lo, addr_hi) & ~32'h3;
        req.dir    = apb_dir_e'($urandom_range(0,1));
        req.wait_en = $urandom & 1'b1;
        `uvm_send(req)
        get_response(rsp);
      end
    endtask
  endclass : apb_stress_seq

endpackage : apb_pkg

`endif
