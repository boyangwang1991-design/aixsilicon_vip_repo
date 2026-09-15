// =============================================================================
// File Name   : axi4_stream_sequencer.sv
// Description : axi4_stream sequence 调度器（多 stream 调度）
// 依据        : docs/requirement.md（REQ-SRC-004, REQ-TXN-006）
// =============================================================================

`ifndef AXI4_STREAM_SEQUENCER__SV
`define AXI4_STREAM_SEQUENCER__SV

class axi4_stream_sequencer extends uvm_sequencer #(axi4_stream_beat_item);

  `uvm_component_utils(axi4_stream_sequencer)

  function new(string name = "axi4_stream_sequencer", uvm_component parent = null);
    super.new(name, parent);
  endfunction

endclass : axi4_stream_sequencer

`endif // AXI4_STREAM_SEQUENCER__SV
