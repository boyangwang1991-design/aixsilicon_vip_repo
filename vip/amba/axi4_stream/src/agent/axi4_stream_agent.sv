// =============================================================================
// File Name   : axi4_stream_agent.sv
// Description : axi4_stream agent（SOURCE / SINK / PASSIVE 角色组合）
// 依据        : docs/requirement.md（REQ-SCP-004/005, REQ-CFG-001 ROLE,
//               REQ-SNK-001, REQ-INT-002）
//
// 设计说明：
//   * 每个 agent 对应一个时钟域与一个单向 AXI4-Stream 接口；双向链路用两个 agent。
//   * PASSIVE：只有 monitor（+checker/coverage 由 env 决定），不创建 driver/sequencer。
//   * CHECKER_ONLY 由独立 SV 构建提供，不依赖 UVM package（见 docs/architecture.md）。
// =============================================================================

`ifndef AXI4_STREAM_AGENT__SV
`define AXI4_STREAM_AGENT__SV

class axi4_stream_agent extends uvm_agent;

  `uvm_component_utils(axi4_stream_agent)

  virtual axi4_stream_if  vif;
  axi4_stream_config      cfg;

  axi4_stream_monitor     monitor;
  axi4_stream_driver      driver;
  axi4_stream_sequencer   sequencer;
  axi4_stream_sink_driver sink_driver;

  axi4_stream_ready_item  ready_policy;

  function new(string name = "axi4_stream_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(virtual axi4_stream_if)::get(this, "", "vif", vif))
      `uvm_fatal("AXIS-AGENT", "未获取 virtual interface（REQ-INT-002）")
    if (!uvm_config_db#(axi4_stream_config)::get(this, "", "cfg", cfg))
      `uvm_fatal("AXIS-AGENT", "未获取 config（REQ-INT-002）")

    // 结构配置冻结与校验（REQ-CFG-006）
    if (!cfg.validate(get_full_name())) return;
    if (!cfg.check_vif(
          vif.exists_tready(), vif.DATA_WIDTH, vif.HAS_TDATA,
          vif.HAS_TKEEP, vif.HAS_TSTRB, vif.HAS_TLAST,
          vif.ID_WIDTH, vif.DEST_WIDTH, vif.USER_WIDTH)) return;

    // monitor 在所有 Profile 都存在（含 PASSIVE）
    uvm_config_db#(virtual axi4_stream_if)::set(this, "monitor", "vif", vif);
    uvm_config_db#(axi4_stream_config)::set(this, "monitor", "cfg", cfg);
    monitor = axi4_stream_monitor::type_id::create("monitor", this);

    if (cfg.role == AXIS_ROLE_PASSIVE) begin
      `uvm_info("AXIS-AGENT", "PASSIVE 角色：不创建 driver/sequencer/sink_driver", UVM_LOW)
      return;
    end

    if (cfg.role == AXIS_ROLE_SOURCE) begin
      uvm_config_db#(virtual axi4_stream_if)::set(this, "driver", "vif", vif);
      uvm_config_db#(axi4_stream_config)::set(this, "driver", "cfg", cfg);
      driver    = axi4_stream_driver::type_id::create("driver", this);
      sequencer = axi4_stream_sequencer::type_id::create("sequencer", this);
    end

    if (cfg.role == AXIS_ROLE_SINK) begin
      uvm_config_db#(virtual axi4_stream_if)::set(this, "sink_driver", "vif", vif);
      uvm_config_db#(axi4_stream_config)::set(this, "sink_driver", "cfg", cfg);
      if (!uvm_config_db#(axi4_stream_ready_item)::get(this, "", "ready_policy", ready_policy)) begin
        ready_policy = axi4_stream_ready_item::type_id::create("ready_policy");
        ready_policy.mode = AXIS_READY_ALWAYS;
      end
      uvm_config_db#(axi4_stream_ready_item)::set(this, "sink_driver", "ready_policy", ready_policy);
      sink_driver = axi4_stream_sink_driver::type_id::create("sink_driver", this);
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (driver != null && sequencer != null)
      driver.seq_item_port.connect(sequencer.seq_item_export);
  endfunction

  function bit is_active();
    return cfg.role != AXIS_ROLE_PASSIVE;
  endfunction

endclass : axi4_stream_agent

`endif // AXI4_STREAM_AGENT__SV
