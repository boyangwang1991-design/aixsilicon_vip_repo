// =============================================================================
// File Name   : axi4_agent.sv
// Description : AXI4 Agent（master/slave；组装 monitor/sequencer/driver）
//               模式：ACTIVE_MASTER / ACTIVE_SLAVE / PASSIVE / DISABLED
// VLNV        : aixsilicon:vip:axi4:1.0.0
// =============================================================================

`ifndef AXI4_AGENT__SV
`define AXI4_AGENT__SV

class axi4_master_agent extends uvm_agent;

  axi4_master_sequencer   sequencer;
  axi4_master_driver      driver;
  axi4_master_write_monitor write_monitor;
  axi4_master_read_monitor  read_monitor;

  axi4_configuration cfg;
  axi4_status        status;

  `uvm_component_utils(axi4_master_agent)

  function new(string name = "axi4_master_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(axi4_configuration)::get(this, "", "cfg", cfg)) begin
      `uvm_fatal(get_type_name(), "未找到 axi4_configuration cfg")
    end
    if (cfg.agent_mode != AXI4_DISABLED) begin
      write_monitor = axi4_master_write_monitor::type_id::create("write_monitor", this);
      read_monitor  = axi4_master_read_monitor::type_id::create("read_monitor", this);
      uvm_config_db #(virtual axi4_if)::set(this, "write_monitor", "vif", cfg.vif);
      uvm_config_db #(axi4_configuration)::set(this, "write_monitor", "cfg", cfg);
      uvm_config_db #(virtual axi4_if)::set(this, "read_monitor", "vif", cfg.vif);
      uvm_config_db #(axi4_configuration)::set(this, "read_monitor", "cfg", cfg);
    end
    if (cfg.agent_mode == AXI4_ACTIVE_MASTER) begin
      sequencer = axi4_master_sequencer::type_id::create("sequencer", this);
      driver    = axi4_master_driver::type_id::create("driver", this);
      uvm_config_db #(virtual axi4_if)::set(this, "driver", "vif", cfg.vif);
      uvm_config_db #(axi4_configuration)::set(this, "driver", "cfg", cfg);
      uvm_config_db #(axi4_configuration)::set(this, "sequencer", "cfg", cfg);
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (driver != null) begin
      driver.seq_item_port.connect(sequencer.seq_item_export);
    end
  endfunction

endclass : axi4_master_agent


class axi4_slave_agent extends uvm_agent;

  axi4_slave_sequencer   sequencer;
  axi4_slave_driver      driver;
  axi4_slave_write_monitor write_monitor;
  axi4_slave_read_monitor  read_monitor;
  axi4_slave_data_monitor  data_monitor;

  axi4_configuration cfg;
  axi4_status        status;
  axi4_memory        memory;

  `uvm_component_utils(axi4_slave_agent)

  function new(string name = "axi4_slave_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(axi4_configuration)::get(this, "", "cfg", cfg)) begin
      `uvm_fatal(get_type_name(), "未找到 axi4_configuration cfg")
    end
    if (!uvm_config_db #(axi4_memory)::get(this, "", "memory", memory)) begin
      memory = axi4_memory::type_id::create("memory", this);
      memory.set_geometry(cfg.address_width, cfg.data_width, 1 << 16);
    end
    uvm_config_db #(axi4_memory)::set(this, "*", "memory", memory);
    if (cfg.agent_mode != AXI4_DISABLED) begin
      write_monitor = axi4_slave_write_monitor::type_id::create("write_monitor", this);
      read_monitor  = axi4_slave_read_monitor::type_id::create("read_monitor", this);
      uvm_config_db #(virtual axi4_if)::set(this, "write_monitor", "vif", cfg.vif);
      uvm_config_db #(axi4_configuration)::set(this, "write_monitor", "cfg", cfg);
      uvm_config_db #(virtual axi4_if)::set(this, "read_monitor", "vif", cfg.vif);
      uvm_config_db #(axi4_configuration)::set(this, "read_monitor", "cfg", cfg);
    end
    if (cfg.agent_mode == AXI4_ACTIVE_SLAVE) begin
      sequencer = axi4_slave_sequencer::type_id::create("sequencer", this);
      driver    = axi4_slave_driver::type_id::create("driver", this);
      uvm_config_db #(virtual axi4_if)::set(this, "driver", "vif", cfg.vif);
      uvm_config_db #(axi4_configuration)::set(this, "driver", "cfg", cfg);
      uvm_config_db #(axi4_configuration)::set(this, "sequencer", "cfg", cfg);
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (driver != null) begin
      driver.seq_item_port.connect(sequencer.seq_item_export);
    end
  endfunction

endclass : axi4_slave_agent

`endif // AXI4_AGENT__SV
