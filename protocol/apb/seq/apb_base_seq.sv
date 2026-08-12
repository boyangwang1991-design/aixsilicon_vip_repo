// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 AIXSILICON
//
// apb_base_seq.sv — APB 公共序列基类。
`ifndef APB_BASE_SEQ_SV
`define APB_BASE_SEQ_SV

package apb_pkg;

  class apb_base_seq extends uvm_sequence #(apb_item);
    `uvm_object_utils(apb_base_seq)

    rand int unsigned num_trans = 10;

    function new(string name = "apb_base_seq");
      super.new(name);
    endfunction

    task body();
      repeat (num_trans) begin
        `uvm_do(req)
        get_response(rsp);
      end
    endtask
  endclass : apb_base_seq

  class apb_read_seq extends apb_base_seq;
    `uvm_object_utils(apb_read_seq)
    rand bit [31:0] start_addr = 32'h0;
    function new(string name = "apb_read_seq");
      super.new(name);
    endfunction
    task body();
      repeat (num_trans) begin
        `uvm_create(req)
        req.dir = APB_READ;
        req.addr = start_addr;
        `uvm_send(req)
        get_response(rsp);
        start_addr += 4;
      end
    endtask
  endclass : apb_read_seq

  class apb_write_seq extends apb_base_seq;
    `uvm_object_utils(apb_write_seq)
    rand bit [31:0] start_addr = 32'h0;
    function new(string name = "apb_write_seq");
      super.new(name);
    endfunction
    task body();
      repeat (num_trans) begin
        `uvm_create(req)
        req.dir = APB_WRITE;
        req.addr = start_addr;
        `uvm_send(req)
        get_response(rsp);
        start_addr += 4;
      end
    endtask
  endclass : apb_write_seq

endpackage : apb_pkg

`endif
