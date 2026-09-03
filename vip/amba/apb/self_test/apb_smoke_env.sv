// =============================================================================
// File Name   : apb_smoke_env.sv
// Description : Self test env 封装——loopback 组装（master cfg + slave cfg 双
//               config 方案）：master agent（ACTIVE_MASTER）+ slave agent
//               （ACTIVE_SLAVE）+ 唯一 monitor + checker + coverage
// VLNV        : aixsilicon:vip:apb:1.0.0
// =============================================================================

`ifndef APB_SMOKE_ENV__SV
`define APB_SMOKE_ENV__SV

import uvm_pkg::*;
import apb_types_pkg::*;
import apb_pkg::*;

class apb_smoke_env extends uvm_env;

  `uvm_component_utils(apb_smoke_env)

  // 双 config：Requester / Completer（同一物理总线、同一 monitor 观察流）
  apb_config          m_cfg;      // requester 侧
  apb_config          s_cfg;      // completer 侧（行为字段由 test 修改）

  // tier 覆盖位（test 于 build_phase 顶层先设——top-down 顺序；env build 应用）
  bit                 mode_fixed_wait_20 = 0;   // UT05/06 corner
  bit                 mode_random_wait   = 0;   // random tier
  bit                 mode_err_region    = 0;   // UT07 error region
  bit                 mode_fi            = 0;   // FI tier（RUL-009 超时 + 负向门）
  bit                 mode_cov_sweep     = 0;   // G4 sweep：随机 wait + err 区域（补覆盖 hole）
  bit                 mode_apb5          = 0;   // APB5 专项（UT13/14/20/21：rme/user/wakeup/check）

  apb_master_agent    master_agent;
  apb_slave_agent     slave_agent;
  apb_monitor         monitor;
  apb_protocol_checker checker;
  apb_coverage        coverage;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual apb_if vif;   // FI tier 直读 SVA 检出计数用

  function void build_phase(uvm_phase phase_);
    super.build_phase(phase_);
    if (!uvm_config_db#(virtual apb_if)::get(this, "", "vif", vif))
      `uvm_fatal(get_type_name(), "virtual interface 'vif' not set")

    // Requester config
    m_cfg = apb_config::type_id::create("m_cfg");
    m_cfg.protocol_version = APB4;
    m_cfg.agent_mode       = APB_ACTIVE_MASTER;

    // Completer config（行为字段由 tier 覆盖位决定——env build 应用，
    // 解决 top-down 顺序下 test 不能引用 env.s_cfg 的问题）
    s_cfg = apb_config::type_id::create("s_cfg");
    s_cfg.protocol_version = APB4;
    s_cfg.agent_mode       = APB_ACTIVE_SLAVE;
    s_cfg.slave_response_mode = APB_ZERO_WAIT;
    if (mode_apb5) begin
      m_cfg.protocol_version = APB5;
      m_cfg.rme_support      = 1;          // PRO-013（PNSE×PPROT[1] → PAS）
      m_cfg.enable_wakeup    = 1;          // PRO-012（PWAKEUP）
      s_cfg.protocol_version = APB5;
      s_cfg.rme_support      = 1;
      s_cfg.enable_wakeup    = 1;
    end
    if (mode_fixed_wait_20) begin
      s_cfg.slave_response_mode = APB_FIXED_WAIT;
      s_cfg.default_wait_cycles = 20;
    end
    if (mode_random_wait) begin
      s_cfg.slave_response_mode = APB_RANDOM_WAIT;
      s_cfg.max_wait_cycles     = 8;
    end
    if (mode_err_region) begin
      apb_addr_region_s r;
      s_cfg.slave_error_mode = APB_ERR_ADDRESS_RANGE;
      r.base        = 'h3000;
      r.limit       = 'h3FFF;
      r.wait_cycles = 0;
      r.slverr      = 1'b1;
      s_cfg.slave_regions = new[1];
      s_cfg.slave_regions[0] = r;
    end
    // FI tier：FIXED_WAIT=20（>timeout 16 → RUL-009 挂死窗）+ 负向总门开
    if (mode_fi) begin
      s_cfg.slave_response_mode = APB_FIXED_WAIT;
      s_cfg.default_wait_cycles = 20;
      s_cfg.allow_protocol_violation = 1;
      m_cfg.timeout_cycles = 16;
      m_cfg.allow_protocol_violation = 1;
    end
    // G4 sweep：随机 wait + err 区域（覆盖 cp_wait 全桶 / cp_error slverr）
    if (mode_cov_sweep) begin
      s_cfg.slave_response_mode = APB_RANDOM_WAIT;
      s_cfg.max_wait_cycles     = 32;   // 覆盖 w5-15 / w16+ 桶
      s_cfg.slave_error_mode    = APB_ERR_ADDRESS_RANGE;
      begin
        apb_addr_region_s r;
        r.base = 'h7000; r.limit = 'h7FFF; r.wait_cycles = 0; r.slverr = 1'b1;
        s_cfg.slave_regions = new[1];
        s_cfg.slave_regions[0] = r;
      end
      m_cfg.seq_item_delay_max = 4;   // 事务间 IDLE（cp_pattern idle_to_transfer）
    end

    // scope 化传递：master_agent 用 m_cfg，slave_agent 用 s_cfg，
    // monitor/checker/coverage 用 m_cfg（观察与检查视角）
    uvm_config_db#(apb_config)::set(this, "master_agent*", "config", m_cfg);
    uvm_config_db#(apb_config)::set(this, "slave_agent*",  "config", s_cfg);
    uvm_config_db#(apb_config)::set(this, "monitor*",      "config", m_cfg);
    uvm_config_db#(apb_config)::set(this, "checker*",      "config", m_cfg);
    uvm_config_db#(apb_config)::set(this, "coverage*",     "config", m_cfg);

    master_agent = apb_master_agent::type_id::create("master_agent", this);
    slave_agent  = apb_slave_agent::type_id::create("slave_agent", this);
    monitor      = apb_monitor::type_id::create("monitor", this);
    checker      = apb_protocol_checker::type_id::create("checker", this);
    coverage     = apb_coverage::type_id::create("coverage", this);
  endfunction

  function void connect_phase(uvm_phase phase_);
    super.connect_phase(phase_);
    // 一条总线一个 observation stream（ADR-1）
    monitor.transaction_ap.connect(checker.analysis_export);
    monitor.transaction_ap.connect(coverage.analysis_export);
  endfunction

endclass

`endif // APB_SMOKE_ENV__SV
