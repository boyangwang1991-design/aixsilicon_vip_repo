// =============================================================================
// File Name   : apb_config.sv
// Description : APB VIP runtime policy 配置（ADR-0：仅承载行为策略；
//               物理能力在 apb_if elaboration-time 参数）。
//               一致性校验：apply_version_defaults() + validate_interface_vs_config()
// VLNV        : aixsilicon:vip:apb:1.0.0
// =============================================================================

`ifndef APB_CONFIG__SV
`define APB_CONFIG__SV

class apb_config extends uvm_object;

  // ===========================================================================
  // Protocol（版本运行时声明；与 vif HAS_* 一致性由 validate_interface_vs_config）
  // ===========================================================================
  apb_version_e    protocol_version = APB4;

  int unsigned     addr_width       = 32;
  int unsigned     data_width       = 32;   // ∈ {8,16,32}（CFG-003）
  int unsigned     user_req_width   = 0;    // 与 vif USER_REQ_WIDTH 对应（0=不存在）
  int unsigned     user_data_width  = 0;
  int unsigned     user_resp_width  = 0;

  bit              enable_strb      = 1;    // runtime"使用"开关（物理存在见 vif）
  bit              enable_prot      = 1;
  bit              enable_wakeup    = 0;    // Wakeup_Signal property 映射
  apb_wakeup_mode_e wakeup_mode     = APB_WAKEUP_FOLLOW_TRANSFER; // ADR-11
  bit              rme_support      = 0;    // RME→PNSE（CFG-002: rme→prot）
  apb_check_type_e check_type       = APB_CHECK_NONE;

  // ===========================================================================
  // Agent（四种模式；role 为同义别名）
  // ===========================================================================
  apb_agent_mode_e agent_mode       = APB_PASSIVE;
  apb_agent_mode_e role             = APB_PASSIVE;

  // ===========================================================================
  // Verification（runtime 检查策略）
  // ===========================================================================
  bit              enable_checker   = 1;
  bit              enable_coverage  = 1;
  bit              check_pslverr_recommendation = 0;  // RUL-005 REC（默认关）
  bit              enable_x_check   = 1;          // VER-013 X/Z check（默认开）

  // ===========================================================================
  // Timing（仅 Completer 行为 + 超时）
  // ===========================================================================
  int unsigned     default_wait_cycles = 0;   // FIXED_WAIT
  int unsigned     max_wait_cycles     = 16;  // RANDOM_WAIT 上限（仅约束激励，TRN-002）
  int unsigned     timeout_cycles      = 1000;// ACCESS 挂起超时（0=禁用）
  uvm_severity     timeout_severity    = UVM_ERROR; // TIM-001：severity=policy（ADR-10）

  // ===========================================================================
  // Safety（负向总门；默认绝不产生非法协议）
  // ===========================================================================
  bit              allow_protocol_violation = 0;

  // ===========================================================================
  // Completer 行为（四层 responder，架构 §12.2）
  // ===========================================================================
  apb_response_mode_e slave_response_mode = APB_ZERO_WAIT;
  apb_error_mode_e    slave_error_mode    = APB_ERR_NEVER;
  real                slave_err_prob      = 0.0;
  apb_addr_region_s   slave_regions[];

  // ===========================================================================
  // Requester 行为
  // ===========================================================================
  int unsigned     seq_item_delay_max = 0;   // 事务间 IDLE 拍数上限（0=不空闲）

  // ===========================================================================
  // metadata/debug（ADR-8：tied 信息不关 checker）
  // ===========================================================================
  bit              dut_pready_tied_high = 0;
  bit              dut_pslverr_tied_low = 0;

  // ===========================================================================
  // Object utils
  // ===========================================================================
  `uvm_object_utils_begin(apb_config)
    `uvm_field_enum(apb_version_e,    protocol_version, UVM_DEFAULT)
    `uvm_field_int(addr_width,        UVM_DEFAULT)
    `uvm_field_int(data_width,        UVM_DEFAULT)
    `uvm_field_int(user_req_width,    UVM_DEFAULT)
    `uvm_field_int(user_data_width,   UVM_DEFAULT)
    `uvm_field_int(user_resp_width,   UVM_DEFAULT)
    `uvm_field_int(enable_strb,       UVM_DEFAULT)
    `uvm_field_int(enable_prot,       UVM_DEFAULT)
    `uvm_field_int(enable_wakeup,     UVM_DEFAULT)
    `uvm_field_enum(apb_wakeup_mode_e, wakeup_mode, UVM_DEFAULT)
    `uvm_field_int(rme_support,       UVM_DEFAULT)
    `uvm_field_enum(apb_check_type_e, check_type, UVM_DEFAULT)
    `uvm_field_enum(apb_agent_mode_e, agent_mode, UVM_DEFAULT)
    `uvm_field_int(enable_checker,    UVM_DEFAULT)
    `uvm_field_int(enable_coverage,   UVM_DEFAULT)
    `uvm_field_int(check_pslverr_recommendation, UVM_DEFAULT)
    `uvm_field_int(enable_x_check,    UVM_DEFAULT)
    `uvm_field_int(default_wait_cycles, UVM_DEFAULT)
    `uvm_field_int(max_wait_cycles,   UVM_DEFAULT)
    `uvm_field_int(timeout_cycles,    UVM_DEFAULT)
    `uvm_field_enum(uvm_severity, timeout_severity, UVM_DEFAULT)
    `uvm_field_int(allow_protocol_violation, UVM_DEFAULT)
    `uvm_field_enum(apb_response_mode_e, slave_response_mode, UVM_DEFAULT)
    `uvm_field_enum(apb_error_mode_e, slave_error_mode, UVM_DEFAULT)
    `uvm_field_real(slave_err_prob,   UVM_DEFAULT)
    `uvm_field_int(seq_item_delay_max, UVM_DEFAULT)
    `uvm_field_int(dut_pready_tied_high, UVM_DEFAULT)
    `uvm_field_int(dut_pslverr_tied_low, UVM_DEFAULT)
  `uvm_object_utils_end

  function new(string name = "apb_config");
    super.new(name);
    apply_version_defaults();   // CFG-001 派生
  endfunction

  // ---------------------------------------------------------------------------
  // 版本能力派生（CFG-001/002/006）
  // ---------------------------------------------------------------------------
  virtual function void apply_version_defaults();
    case (protocol_version)
      APB3: begin
        enable_strb     = 0;
        enable_prot     = 0;
        enable_wakeup   = 0;
        rme_support     = 0;
        check_type      = APB_CHECK_NONE;
        user_req_width  = 0;
        user_data_width = 0;
        user_resp_width = 0;
      end
      APB4: begin
        enable_strb     = 1;
        enable_prot     = 1;
        enable_wakeup   = 0;
        rme_support     = 0;
        check_type      = APB_CHECK_NONE;
        user_req_width  = 0;
        user_data_width = 0;
        user_resp_width = 0;
      end
      APB5: ;  // 正交位由用户设置
      default: ;
    endcase
    if (rme_support) enable_prot = 1;   // CFG-002
  endfunction

  // ---------------------------------------------------------------------------
  // 位宽合法性（CFG-003..005；非法 → fatal）
  // ---------------------------------------------------------------------------
  virtual function void validate_widths();
    if (!apb_data_width_legal(data_width))
      `uvm_fatal("APB_CFG", $sformatf("data_width=%0d illegal (must be 8/16/32)", data_width))
    if (!apb_addr_width_legal(addr_width))
      `uvm_fatal("APB_CFG", $sformatf("addr_width=%0d illegal (1..32)", addr_width))
  endfunction

  // ---------------------------------------------------------------------------
  // 物理能力 vs runtime policy 一致性（C-8：blocker① 纽带）
  // HAS_*/WIDTH 为 elaboration 常量，经 env 传入字符串开关（vif_caps）
  // ---------------------------------------------------------------------------
  virtual function void validate_interface_vs_config(
      bit has_pstrb, bit has_pprot,
      int unsigned user_req_w, int unsigned user_data_w, int unsigned user_resp_w,
      bit has_pwakeup, bit has_pnse, bit has_check);
    validate_widths();
    if (enable_strb     && !has_pstrb)   `uvm_fatal("APB_CFG", "enable_strb=1 but vif HAS_PSTRB=0")
    if (enable_prot     && !has_pprot)   `uvm_fatal("APB_CFG", "enable_prot=1 but vif HAS_PPROT=0")
    if (user_req_width  && !user_req_w)  `uvm_fatal("APB_CFG", "user_req_width>0 but vif USER_REQ_WIDTH=0")
    if (user_data_width && !user_data_w) `uvm_fatal("APB_CFG", "user_data_width>0 but vif USER_DATA_WIDTH=0")
    if (user_resp_width && !user_resp_w) `uvm_fatal("APB_CFG", "user_resp_width>0 but vif USER_RESP_WIDTH=0")
    if (enable_wakeup   && !has_pwakeup) `uvm_fatal("APB_CFG", "enable_wakeup=1 but vif HAS_PWAKEUP=0")
    if (rme_support     && !has_pnse)    `uvm_fatal("APB_CFG", "rme_support=1 but vif HAS_PNSE=0")
    if (check_type != APB_CHECK_NONE && !has_check)
      `uvm_fatal("APB_CFG", "check_type!=NONE but vif HAS_CHECK=0")
  endfunction

endclass : apb_config

`endif // APB_CONFIG__SV
