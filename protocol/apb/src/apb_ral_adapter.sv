// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 AIXSILICON
//
// apb_ral_adapter.sv — APB UVM RAL 适配器（Service Layer）。
// 提供 reg2bus / bus2reg，与 predictor 配合完成前门访问。
`ifndef APB_RAL_ADAPTER_SV
`define APB_RAL_ADAPTER_SV

package apb_pkg;

  class apb_ral_adapter extends uvm_reg_adapter;
    `uvm_object_utils(apb_ral_adapter)

    function new(string name = "apb_ral_adapter");
      super.new(name);
      supports_byte_enable = 0'b0;
      provides_responses   = 1'b1;
    endfunction

    virtual function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
      apb_item t = apb_item::type_id::create("t");
      t.addr = rw.addr;
      t.dir  = (rw.kind == UVM_WRITE) ? APB_WRITE : APB_READ;
      t.data = rw.data;
      return t;
    endfunction

    virtual function void bus2reg(uvm_sequence_item bus_item, ref uvm_reg_bus_op rw);
      apb_item t;
      if (!$cast(t, bus_item))
        `uvm_fatal("BADITEM", "bus_item 不是 apb_item")
      rw.kind  = (t.dir == APB_WRITE) ? UVM_WRITE : UVM_READ;
      rw.addr  = t.addr;
      rw.data  = t.data;
      rw.status = t.error_en ? UVM_NOT_OK : UVM_IS_OK;
    endfunction
  endclass : apb_ral_adapter

endpackage : apb_pkg

`endif
