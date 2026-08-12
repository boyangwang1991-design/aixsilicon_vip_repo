// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 AIXSILICON
//
// apb_sequencer.sv — APB 序列器。
`ifndef APB_SEQUENCER_SV
`define APB_SEQUENCER_SV

package apb_pkg;

  class apb_sequencer extends uvm_sequencer #(apb_item);
    `uvm_component_utils(apb_sequencer)

    function new(string name = "apb_sequencer", uvm_component parent = null);
      super.new(name, parent);
    endfunction
  endclass : apb_sequencer

endpackage : apb_pkg

`endif
