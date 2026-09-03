// =============================================================================
// File Name   : apb_sequencer.sv
// Description : Requester/Completer sequencer（uvm_sequencer#(apb_item)）
// VLNV        : aixsilicon:vip:apb:1.0.0
// =============================================================================

`ifndef APB_SEQUENCER__SV
`define APB_SEQUENCER__SV

class apb_master_sequencer extends uvm_sequencer #(apb_item);
  `uvm_component_utils(apb_master_sequencer)
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
endclass

class apb_slave_sequencer extends uvm_sequencer #(apb_item);
  `uvm_component_utils(apb_slave_sequencer)
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
endclass

`endif // APB_SEQUENCER__SV
