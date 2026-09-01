// =============================================================================
// File Name   : axi4_smoke_env.sv
// Description : AXI4 VIP Self Test smoke 环境（master + slave 环回）
//               master_agent 激励 + slave_agent 自动响应 + checker + coverage
// =============================================================================

`ifndef AXI4_SMOKE_ENV__SV
`define AXI4_SMOKE_ENV__SV

import uvm_pkg::*;
import axi4_pkg::*;
import axi4_types_pkg::*;

class axi4_smoke_env extends uvm_env;

  axi4_master_agent master_agent;
  axi4_slave_agent  slave_agent;
  axi4_checker      checker;
  axi4_coverage     coverage;

  axi4_configuration master_cfg;
  axi4_configuration slave_cfg;
  axi4_status        status;

  `uvm_component_utils(axi4_smoke_env)

  function new(string name = "axi4_smoke_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    // 配置：master / slave 各自 profile
    if (!uvm_config_db #(axi4_configuration)::get(this, "", "master_cfg", master_cfg)) begin
      master_cfg = axi4_configuration::type_id::create("master_cfg");
      void'(master_cfg.randomize() with {
        protocol    == AXI4_PROTOCOL;
        agent_mode  == AXI4_ACTIVE_MASTER;
      });
    end
    if (!uvm_config_db #(axi4_configuration)::get(this, "", "slave_cfg", slave_cfg)) begin
      slave_cfg = axi4_configuration::type_id::create("slave_cfg");
      void'(slave_cfg.randomize() with {
        protocol    == AXI4_PROTOCOL;
        agent_mode  == AXI4_ACTIVE_SLAVE;
      });
    end
    if (!uvm_config_db #(axi4_status)::get(this, "", "status", status)) begin
      status = axi4_status::type_id::create("status");
    end

    // 共享同一 vif（master/slave 环回）
    if (!uvm_config_db #(virtual axi4_if)::get(this, "", "vif", master_cfg.vif)) begin
      `uvm_fatal(get_type_name(), "未找到 virtual axi4_if vif")
    end
    slave_cfg.vif = master_cfg.vif;

    // master agent
    master_agent = axi4_master_agent::type_id::create("master_agent", this);
    uvm_config_db #(axi4_configuration)::set(this, "master_agent", "cfg", master_cfg);
    uvm_config_db #(axi4_status)::set(this, "master_agent", "status", status);

    // slave agent
    slave_agent = axi4_slave_agent::type_id::create("slave_agent", this);
    uvm_config_db #(axi4_configuration)::set(this, "slave_agent", "cfg", slave_cfg);
    uvm_config_db #(axi4_status)::set(this, "slave_agent", "status", status);

    // checker / coverage
    if (master_cfg.enable_checker) begin
      checker = axi4_checker::type_id::create("checker", this);
      uvm_config_db #(axi4_configuration)::set(this, "checker", "cfg", master_cfg);
      uvm_config_db #(axi4_status)::set(this, "checker", "status", status);
    end
    if (master_cfg.enable_coverage) begin
      coverage = axi4_coverage::type_id::create("coverage", this);
      uvm_config_db #(axi4_configuration)::set(this, "coverage", "cfg", master_cfg);
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    // master monitor（完整事务）→ checker / coverage
    // 请求级规则（RUL-003/PRO-010/PRO-012）仅接 master monitor 的 request 流
    // （slave monitor 对同一事务重复报会导致违规重复计数）
    // 响应级规则（RUL-010）接两侧 response 流
    // 完整事务流 → checker.monitor_imp（RUL-007 响应拍数检查）
    if (checker != null) begin
      if (master_agent.read_monitor != null) begin
        master_agent.read_monitor.request_item_port.connect(checker.request_imp);
        master_agent.read_monitor.response_item_port.connect(checker.response_imp);
        master_agent.read_monitor.response_item_port.connect(checker.monitor_imp);
      end
      if (master_agent.write_monitor != null) begin
        master_agent.write_monitor.request_item_port.connect(checker.request_imp);
        master_agent.write_monitor.response_item_port.connect(checker.response_imp);
        master_agent.write_monitor.response_item_port.connect(checker.monitor_imp);
      end
      if (slave_agent.read_monitor != null) begin
        slave_agent.read_monitor.response_item_port.connect(checker.response_imp);
        slave_agent.read_monitor.response_item_port.connect(checker.monitor_imp);
      end
      if (slave_agent.write_monitor != null) begin
        slave_agent.write_monitor.response_item_port.connect(checker.response_imp);
        slave_agent.write_monitor.response_item_port.connect(checker.monitor_imp);
      end
    end
    if (coverage != null) begin
      if (master_agent.read_monitor != null) begin
        master_agent.read_monitor.transaction_ap.connect(coverage.analysis_export);
      end
      if (master_agent.write_monitor != null) begin
        master_agent.write_monitor.transaction_ap.connect(coverage.analysis_export);
      end
      if (slave_agent.read_monitor != null) begin
        slave_agent.read_monitor.transaction_ap.connect(coverage.analysis_export);
      end
      if (slave_agent.write_monitor != null) begin
        slave_agent.write_monitor.transaction_ap.connect(coverage.analysis_export);
      end
    end
  endfunction

endclass : axi4_smoke_env

`endif // AXI4_SMOKE_ENV__SV
