// =============================================================================
// File Name   : axi4_sequencer.sv
// Description : AXI4 Sequencer（master/slave；标准 UVM sequencer）
// VLNV        : aixsilicon:vip:axi4:1.0.0
// =============================================================================

`ifndef AXI4_SEQUENCER__SV
`define AXI4_SEQUENCER__SV

class axi4_master_sequencer extends uvm_sequencer #(axi4_master_item);

  axi4_configuration cfg;
  axi4_status        status;

  `uvm_component_utils(axi4_master_sequencer)

  function new(string name = "axi4_master_sequencer", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(axi4_configuration)::get(this, "", "cfg", cfg)) begin
      `uvm_fatal(get_type_name(), "未找到 axi4_configuration cfg")
    end
  endfunction

endclass : axi4_master_sequencer


class axi4_slave_sequencer extends uvm_sequencer #(axi4_slave_item);

  axi4_configuration cfg;
  axi4_status        status;

  `uvm_component_utils(axi4_slave_sequencer)

  function new(string name = "axi4_slave_sequencer", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(axi4_configuration)::get(this, "", "cfg", cfg)) begin
      `uvm_fatal(get_type_name(), "未找到 axi4_configuration cfg")
    end
  endfunction

endclass : axi4_slave_sequencer

`endif // AXI4_SEQUENCER__SV
