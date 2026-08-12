// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 AIXSILICON
//
// apb_error_seq.sv — APB 负向序列：注入 slave error，供 checker 负向测试。
`ifndef APB_ERROR_SEQ_SV
`define APB_ERROR_SEQ_SV

package apb_pkg;

  class apb_error_seq extends apb_base_seq;
    `uvm_object_utils(apb_error_seq)

    function new(string name = "apb_error_seq");
      super.new(name);
    endfunction

    task body();
      repeat (num_trans) begin
        `uvm_create(req)
        req.error_en = 1'b1;
        req.wait_en  = $urandom & 1'b1;
        `uvm_send(req)
        get_response(rsp);
      end
    endtask
  endclass : apb_error_seq

endpackage : apb_pkg

`endif
