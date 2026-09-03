// =============================================================================
// File Name   : apb_env.sv
// Description : VIP env（架构 §10：agents[无 monitor] + 唯一 monitor +
//               checker + coverage + predictor（P1）；C-8 一致性校验纽带）
// VLNV        : aixsilicon:vip:apb:1.0.0
// =============================================================================

`ifndef APB_ENV__SV
`define APB_ENV__SV

class apb_env extends uvm_env;

  `uvm_component_utils(apb_env)

  apb_config           cfg;
  virtual apb_if       vif;

  apb_master_agent     master_agent;
  apb_slave_agent      slave_agent;
  apb_monitor          monitor;       // ADR-1：唯一 authoritative monitor
  apb_protocol_checker checker;
  apb_coverage         coverage;
  apb_reg_predictor    predictor;     // P1（enable_coverage 组装开关可裁）

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase_);
    super.build_phase(phase_);

    if (!uvm_config_db#(apb_config)::get(this, "", "config", cfg))
      `uvm_fatal(get_type_name(), "apb_config 'config' not set")
    if (!uvm_config_db#(virtual apb_if)::get(this, "", "vif", vif))
      `uvm_fatal(get_type_name(), "virtual interface 'vif' not set")

    // C-8：物理能力 vs runtime policy 一致性（blocker① 纽带）
    cfg.validate_interface_vs_config(
      vif.HAS_PSTRB, vif.HAS_PPROT,
      vif.USER_REQ_WIDTH, vif.USER_DATA_WIDTH, vif.USER_RESP_WIDTH,
      vif.HAS_PWAKEUP, vif.HAS_PNSE, vif.HAS_CHECK);

    // ADR-13：Public API 仅 sequence + RAL 两入口——env 无 blocking API

    // agents（无 monitor——ADR-1）
    if (cfg.agent_mode inside {APB_ACTIVE_MASTER, APB_PASSIVE}) begin
      // ACTIVE_MASTER 或纯观察时仍实例化 master_agent（仅当 ACTIVE）
      if (cfg.agent_mode == APB_ACTIVE_MASTER)
        master_agent = apb_master_agent::type_id::create("master_agent", this);
    end
    if (cfg.agent_mode == APB_ACTIVE_SLAVE)
      slave_agent = apb_slave_agent::type_id::create("slave_agent", this);

    // 唯一 monitor
    monitor = apb_monitor::type_id::create("monitor", this);

    // Qualification Model
    if (cfg.enable_checker)
      checker = apb_protocol_checker::type_id::create("checker", this);
    if (cfg.enable_coverage)
      coverage = apb_coverage::type_id::create("coverage", this);
    // P1 predictor：随 RAL 使用组装（always 创建，不连接则不消耗）
    predictor = apb_reg_predictor::type_id::create("predictor", this);
  endfunction

  function void connect_phase(uvm_phase phase_);
    super.connect_phase(phase_);
    // observation stream（一条总线一个流）
    monitor.transaction_ap.connect(predictor.analysis_export);
    if (cfg.enable_checker)
      monitor.transaction_ap.connect(checker.analysis_export);
    if (cfg.enable_coverage)
      monitor.transaction_ap.connect(coverage.analysis_export);
  endfunction

endclass

`endif // APB_ENV__SV
