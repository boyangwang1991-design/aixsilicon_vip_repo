// =============================================================================
// File Name   : axi4_env.sv
// Description : AXI4 Env（uvm_env；组装 master/slave agent + checker + coverage
//               + violation injector；REQ-023/024）
// VLNV        : aixsilicon:vip:axi4:1.0.0
// =============================================================================

`ifndef AXI4_ENV__SV
`define AXI4_ENV__SV

class axi4_env extends uvm_env;

  axi4_master_agent    master_agent;
  axi4_slave_agent     slave_agent;
  axi4_checker         checker;
  axi4_coverage        coverage;
  axi4_violation_injector injector;

  axi4_configuration cfg;
  axi4_status        status;

  `uvm_component_utils(axi4_env)

  function new(string name = "axi4_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(axi4_configuration)::get(this, "", "cfg", cfg)) begin
      `uvm_fatal(get_type_name(), "未找到 axi4_configuration cfg")
    end
    if (!uvm_config_db #(axi4_status)::get(this, "", "status", status)) begin
      status = axi4_status::type_id::create("status");
    end

    // master agent
    if ((cfg.agent_mode == AXI4_ACTIVE_MASTER) || (cfg.agent_mode == AXI4_PASSIVE)) begin
      master_agent = axi4_master_agent::type_id::create("master_agent", this);
      uvm_config_db #(axi4_configuration)::set(this, "master_agent", "cfg", cfg);
      uvm_config_db #(axi4_status)::set(this, "master_agent", "status", status);
      if (cfg.agent_mode == AXI4_ACTIVE_MASTER) begin
        uvm_config_db #(axi4_configuration)::set(this, "master_agent", "cfg", cfg);
      end
    end

    // slave agent
    if ((cfg.agent_mode == AXI4_ACTIVE_SLAVE) || (cfg.agent_mode == AXI4_PASSIVE)) begin
      slave_agent = axi4_slave_agent::type_id::create("slave_agent", this);
      uvm_config_db #(axi4_configuration)::set(this, "slave_agent", "cfg", cfg);
      uvm_config_db #(axi4_status)::set(this, "slave_agent", "status", status);
    end

    // checker / coverage / injector
    if (cfg.enable_checker) begin
      checker = axi4_checker::type_id::create("checker", this);
      uvm_config_db #(axi4_configuration)::set(this, "checker", "cfg", cfg);
      uvm_config_db #(axi4_status)::set(this, "checker", "status", status);
    end
    if (cfg.enable_coverage) begin
      coverage = axi4_coverage::type_id::create("coverage", this);
      uvm_config_db #(axi4_configuration)::set(this, "coverage", "cfg", cfg);
    end
    if (cfg.enable_error_injection) begin
      injector = axi4_violation_injector::type_id::create("injector", this);
      uvm_config_db #(axi4_configuration)::set(this, "injector", "cfg", cfg);
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    // 连接 checker / coverage 到 monitor 输出
    if (master_agent != null) begin
      if (master_agent.read_monitor != null) begin
        if (checker != null) begin
          master_agent.read_monitor.request_item_port.connect(checker.monitor_imp);
        end
        if (coverage != null) begin
          master_agent.read_monitor.transaction_ap.connect(coverage.analysis_export);
        end
      end
      if (master_agent.write_monitor != null) begin
        if (checker != null) begin
          master_agent.write_monitor.request_item_port.connect(checker.monitor_imp);
        end
        if (coverage != null) begin
          master_agent.write_monitor.transaction_ap.connect(coverage.analysis_export);
        end
      end
    end
    if (slave_agent != null) begin
      if (slave_agent.read_monitor != null) begin
        if (checker != null) begin
          slave_agent.read_monitor.request_item_port.connect(checker.monitor_imp);
        end
        if (coverage != null) begin
          slave_agent.read_monitor.transaction_ap.connect(coverage.analysis_export);
        end
      end
      if (slave_agent.write_monitor != null) begin
        if (checker != null) begin
          slave_agent.write_monitor.request_item_port.connect(checker.monitor_imp);
        end
        if (coverage != null) begin
          slave_agent.write_monitor.transaction_ap.connect(coverage.analysis_export);
        end
      end
      // slave data monitor → memory（通过 write_monitor 的 transaction_ap）
      if ((slave_agent.write_monitor != null) && (slave_agent.data_monitor != null)) begin
        slave_agent.write_monitor.transaction_ap.connect(slave_agent.data_monitor.analysis_export);
      end
    end
  endfunction

endclass : axi4_env

`endif // AXI4_ENV__SV
