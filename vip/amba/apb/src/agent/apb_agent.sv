// =============================================================================
// File Name   : apb_agent.sv
// Description : Requester/Completer agent（ADR-1：agent 内无 monitor——
//               env 级唯一 apb_monitor 承载观察流；agent_mode 裁剪）
// VLNV        : aixsilicon:vip:apb:1.0.0
// =============================================================================

`ifndef APB_AGENT__SV
`define APB_AGENT__SV

class apb_master_agent extends uvm_agent;

  `uvm_component_utils(apb_master_agent)

  apb_config           cfg;
  apb_master_sequencer sequencer;
  apb_master_driver    driver;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase_);
    super.build_phase(phase_);
    if (!uvm_config_db#(apb_config)::get(this, "", "config", cfg))
      `uvm_fatal(get_type_name(), "apb_config 'config' not set")

    if (cfg.agent_mode == APB_ACTIVE_MASTER) begin
      sequencer = apb_master_sequencer::type_id::create("sequencer", this);
      driver    = apb_master_driver::type_id::create("driver", this);
    end
    // PASSIVE/DISABLED：不创建 driver/sequencer（ADR-1 观察流由 env monitor 承载）
  endfunction

  function void connect_phase(uvm_phase phase_);
    super.connect_phase(phase_);
    if (cfg.agent_mode == APB_ACTIVE_MASTER)
      driver.seq_item_port.connect(sequencer.seq_item_export);
  endfunction

endclass

class apb_slave_agent extends uvm_agent;

  `uvm_component_utils(apb_slave_agent)

  apb_config          cfg;
  apb_slave_sequencer sequencer;
  apb_slave_driver    driver;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase_);
    super.build_phase(phase_);
    if (!uvm_config_db#(apb_config)::get(this, "", "config", cfg))
      `uvm_fatal(get_type_name(), "apb_config 'config' not set")

    if (cfg.agent_mode == APB_ACTIVE_SLAVE) begin
      sequencer = apb_slave_sequencer::type_id::create("sequencer", this);
      driver    = apb_slave_driver::type_id::create("driver", this);
    end
  endfunction

  function void connect_phase(uvm_phase phase_);
    super.connect_phase(phase_);
    if (cfg.agent_mode == APB_ACTIVE_SLAVE)
      driver.seq_item_port.connect(sequencer.seq_item_export);
  endfunction

endclass

`endif // APB_AGENT__SV
