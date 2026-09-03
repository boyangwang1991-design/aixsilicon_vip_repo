// =============================================================================
// File Name   : apb_violation.sv
// Description : 结构化 Violation 对象（架构 §17：rule/req/severity/time/context）
//               + UVM transaction checker（CHK-R7/R9/R10/R11/REC/X）
// VLNV        : aixsilicon:vip:apb:1.0.0
// =============================================================================

`ifndef APB_VIOLATION__SV
`define APB_VIOLATION__SV

class apb_violation extends uvm_object;

  `uvm_object_utils(apb_violation)

  string                        rule_id;      // RUL-xxx / CHK-xxx
  string                        req_id;       // REQ 溯源（RTM）
  apb_violation_severity_e      severity;
  time                          timestamp;
  string                        channel;      // setup/access/completion/reset
  string                        ctx_info;     // 事务上下文（convert2string 摘要）

  function new(string name = "apb_violation");
    super.new(name);
    timestamp = $time;
  endfunction

  virtual function string convert2string();
    return $sformatf("[%s|%s|%s@%0t|%s] %s",
                     rule_id, req_id, severity.name(), timestamp, channel, ctx_info);
  endfunction

endclass

// =============================================================================
// UVM transaction checker（订阅 monitor transaction_ap）
// =============================================================================
class apb_protocol_checker extends uvm_component;

  `uvm_component_utils(apb_protocol_checker)

  apb_config cfg;
  uvm_analysis_export #(apb_item)    analysis_export;
  uvm_analysis_port  #(apb_violation) violation_ap;

  `uvm_analysis_imp_decl(_checker)
  uvm_analysis_imp_checker #(apb_item, apb_protocol_checker) item_imp;

  // 检出计数（FI/mutation tier 统计用；rule_id → 次数）
  int hit_cnt [string];

  function new(string name, uvm_component parent);
    super.new(name, parent);
    violation_ap    = new("violation_ap", this);
    analysis_export = new("analysis_export", this);
    item_imp        = new("item_imp", this);
  endfunction

  function void build_phase(uvm_phase phase_);
    super.build_phase(phase_);
    if (!uvm_config_db#(apb_config)::get(this, "", "config", cfg))
      `uvm_fatal(get_type_name(), "apb_config 'config' not set")
  endfunction

  function void connect_phase(uvm_phase phase_);
    super.connect_phase(phase_);
    analysis_export.connect(item_imp);   // export → imp（env 经此接入）
  endfunction

  // ---------------------------------------------------------------------------
  // transaction 语义检查入口
  // ---------------------------------------------------------------------------
  virtual function void write_checker(apb_item it);
    if (!cfg.enable_checker) return;
    check_read_strb(it);         // CHK-R7（RUL-006/007）
    check_wait_timeout(it);      // CHK-R9（RUL-009/TIM-001）
    check_setup_no_completion(it); // CHK-R10（RUL-010）
    check_pslverr_recommendation(it); // CHK-REC（RUL-005）
  endfunction

  // CHK-R7：读事务 strb==0（enable_strb 时）
  function void check_read_strb(apb_item it);
    if (cfg.enable_strb && it.direction == APB_READ && it.strb != 0) begin
      report_violation("RUL-006", "REQ-RUL-006", APB_VIOL_ERROR, "access",
        $sformatf("read transfer with PSTRB=0x%0h nonzero", it.strb), it);
    end
  endfunction

  // CHK-R9：observed wait 超时（TRN-002：用 observed，不用 requested）
  function void check_wait_timeout(apb_item it);
    if (it.status == APB_ABORTED) return;
    if (cfg.timeout_cycles > 0 && it.observed_wait_cycles >= cfg.timeout_cycles) begin
      // severity=policy（ADR-10：cfg.timeout_severity）
      apb_violation_severity_e sv = sev_of(cfg.timeout_severity);
      report_violation("RUL-009", "REQ-TIM-001", sv, "access",
        $sformatf("ACCESS pending %0d cycles >= timeout %0d",
                  it.observed_wait_cycles, cfg.timeout_cycles), it);
    end
  endfunction

  // CHK-R10：SETUP 拍不判 completion（monitor 载体 + 此处 ABORTED 处理）
  function void check_setup_no_completion(apb_item it);
    if (it.status == APB_ABORTED) begin
      report_violation("CHK-ABORT", "REQ-PRO-016", APB_VIOL_WARN, "reset",
        "transaction aborted by reset", it);
    end
  endfunction

  // CHK-REC：PSLVERR recommendation（RUL-005：非 FAIL）
  // （采样窗语义由 monitor 保证；此处仅对 completion 外 slverr 非零的
  //   recommendation 统计——monitor 只发布 completion 采样值，正常为空操作）
  function void check_pslverr_recommendation(apb_item it);
    if (it.status != APB_OK && it.status != APB_ERROR) return;
  endfunction

  // ---------------------------------------------------------------------------
  // violation 输出（结构化，coding-rules #10）
  // ---------------------------------------------------------------------------
  function void report_violation(string rule_id, string req_id,
                                 apb_violation_severity_e sv,
                                 string channel, string ctx, apb_item it);
    apb_violation v = apb_violation::type_id::create("violation");
    v.rule_id   = rule_id;
    v.req_id    = req_id;
    v.severity  = sv;
    v.channel   = channel;
    v.ctx_info  = ctx;
    if (it != null) v.ctx_info = {ctx, " | ", it.convert2string()};

    violation_ap.write(v);
    hit_cnt[rule_id] = (hit_cnt.exists(rule_id)) ? hit_cnt[rule_id]+1 : 1;
    case (sv)
      APB_VIOL_INFO:  `uvm_info(get_type_name(), v.convert2string(), UVM_MEDIUM)
      APB_VIOL_WARN:  `uvm_warning(get_type_name(), v.convert2string())
      APB_VIOL_ERROR: `uvm_error(get_type_name(), v.convert2string())
      APB_VIOL_FATAL: `uvm_fatal(get_type_name(), v.convert2string())
    endcase
  endfunction

  function apb_violation_severity_e sev_of(uvm_severity s);
    case (s)
      UVM_WARNING: return APB_VIOL_WARN;
      UVM_ERROR:   return APB_VIOL_ERROR;
      UVM_FATAL:   return APB_VIOL_FATAL;
      default:     return APB_VIOL_ERROR;
    endcase
  endfunction

endclass

`endif // APB_VIOLATION__SV
