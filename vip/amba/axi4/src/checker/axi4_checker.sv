// =============================================================================
// File Name   : axi4_checker.sv
// Description : AXI4 协议检查器（uvm_scoreboard；AXI4-REQ-VER-009 / §3 + §5.1）
//               - 规则检查：AXI4-REQ-RUL-001~019 + 0110~0116
//               - AXI Ordering Model（按 ID 的请求/响应队列）
//               - 结构化违规输出（AXI4-REQ-API-008）：rule/severity/channel/time/context
//               - 与 Violation Injector 联动（Mutation 检测率，AXI4-REQ-QLF-005）
// VLNV        : aixsilicon:vip:axi4:1.0.0
// =============================================================================

`ifndef AXI4_CHECKER__SV
`define AXI4_CHECKER__SV

// 违规报告对象（AXI4-REQ-API-008 结构化输出）
class axi4_violation extends uvm_sequence_item;

  string   rule_id;         // 例如 "AXI4-REQ-RUL-003"
  string   rule_name;
  string   severity;        // ERROR / WARNING
  string   channel;         // AW / W / B / AR / R
  time     time_stamp;
  axi4_item item;           // 事务上下文（可选）

  function new(string name = "axi4_violation");
    super.new(name);
  endfunction

  virtual function string convert2string();
    return $sformatf(
      "VIOLATION [%s] %s %s @%0t %s", rule_id, severity, rule_name, time_stamp,
      (item != null) ? item.convert2string() : ""
    );
  endfunction

  `uvm_object_utils_begin(axi4_violation)
    `uvm_field_string(rule_id, UVM_DEFAULT)
    `uvm_field_string(rule_name, UVM_DEFAULT)
    `uvm_field_string(severity, UVM_DEFAULT)
    `uvm_field_string(channel, UVM_DEFAULT)
    `uvm_field_int(time_stamp, UVM_DEFAULT | UVM_TIME)
  `uvm_object_utils_end

endclass : axi4_violation


class axi4_checker extends uvm_scoreboard;

  // ---- 配置 / 状态 ----
  axi4_configuration cfg;
  axi4_status        status;

  // ---- 输入 analysis imp（monitor 发布）----
  uvm_analysis_imp_axi4_request  #(axi4_item, axi4_checker) request_imp;
  uvm_analysis_imp_axi4_response #(axi4_item, axi4_checker) response_imp;
  uvm_analysis_imp_axi4_monitor  #(axi4_item, axi4_checker) monitor_imp;

  // ---- 违规输出 port（AXI4-REQ-API-008 订阅）----
  uvm_analysis_port #(axi4_violation) violation_ap;

  // ---- AXI Ordering Model（§5.1）----
  axi4_item read_request_queue[axi4_id][$];
  axi4_item write_request_queue[axi4_id][$];
  axi4_item read_response_queue[axi4_id][$];
  axi4_item write_response_queue[axi4_id][$];

  // 统计
  int check_count;
  int violation_count;

  `uvm_component_utils(axi4_checker)

  function new(string name = "axi4_checker", uvm_component parent = null);
    super.new(name, parent);
    violation_ap = new("violation_ap", this);
    check_count = 0;
    violation_count = 0;
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(axi4_configuration)::get(this, "", "cfg", cfg)) begin
      `uvm_fatal(get_type_name(), "未找到 axi4_configuration cfg")
    end
    request_imp = new("request_imp", this);
    response_imp = new("response_imp", this);
    monitor_imp = new("monitor_imp", this);
  endfunction

  // ===========================================================================
  // analysis 入口（monitor 发布 request/response）
  // ===========================================================================
  function void write_axi4_request(axi4_item item);
    check_count++;
    if (cfg.enable_checker) begin
      check_request_rules(item);
      enqueue_request(item);
    end
  endfunction

  function void write_axi4_response(axi4_item item);
    check_count++;
    if (cfg.enable_checker) begin
      check_response_rules(item);
      enqueue_response(item);
    end
  endfunction

  function void write_axi4_monitor(axi4_item item);
    // monitor 完整事务流（用于派生字段/统计）
    check_count++;
    if (cfg.enable_checker) begin
      check_transaction_rules(item);
    end
  endfunction

  // ===========================================================================
  // 违规上报（AXI4-REQ-API-008）
  // ===========================================================================
  function void report_violation(
    string   rule_id,
    string   rule_name,
    string   severity,
    string   channel,
    axi4_item item = null
  );
    axi4_violation v = axi4_violation::type_id::create("violation");
    v.rule_id    = rule_id;
    v.rule_name  = rule_name;
    v.severity   = severity;
    v.channel    = channel;
    v.time_stamp = $time;
    v.item       = item;
    violation_count++;
    if (status != null) begin
      status.incr_violation();
    end
    `uvm_error(rule_id, v.convert2string())
    violation_ap.write(v);
  endfunction

  // ===========================================================================
  // 规则检查 — 请求（AW/AR）
  // ===========================================================================
  protected function void check_request_rules(axi4_item item);
    // ---- AXI4-REQ-PRO-010：突发长度合法性 ----
    if (cfg.protocol == AXI4_PROTOCOL) begin
      if (item.burst_type == AXI4_INCREMENTING_BURST) begin
        if (!(item.burst_length inside {[1:256]})) begin
          report_violation("AXI4-REQ-PRO-010", "INCR 突发长度非法", "ERROR",
                           item.is_read() ? "AR" : "AW", item);
        end
      end
      else if (item.burst_type == AXI4_FIXED_BURST) begin
        if (!(item.burst_length inside {[1:16]})) begin
          report_violation("AXI4-REQ-PRO-010", "FIXED 突发长度非法", "ERROR",
                           item.is_read() ? "AR" : "AW", item);
        end
      end
      else if (item.burst_type == AXI4_WRAPPING_BURST) begin
        if (!(item.burst_length inside {2, 4, 8, 16})) begin
          report_violation("AXI4-REQ-PRO-010", "WRAP 突发长度非法", "ERROR",
                           item.is_read() ? "AR" : "AW", item);
        end
      end
    end
    else begin
      // AXI4-Lite：单拍（len=0），burst=FIXED
      if (item.burst_length != 1) begin
        report_violation("AXI4-REQ-PRO-010", "AXI4-Lite 仅支持单拍", "ERROR",
                         item.is_read() ? "AR" : "AW", item);
      end
    end

    // ---- AXI4-REQ-PRO-012 / AXI4-REQ-RUL-003：4KB 边界 ----
    if (item.check_boundary()) begin
      report_violation("AXI4-REQ-RUL-003", "突发跨越 4KB 边界", "ERROR",
                       item.is_read() ? "AR" : "AW", item);
    end

    // ---- AXI4-REQ-PRO-012：WRAP 地址对齐（wrap boundary）----
    if (item.burst_type == AXI4_WRAPPING_BURST) begin
      int wrap_size = item.burst_size * item.burst_length;
      if ((item.address % wrap_size) != 0) begin
        report_violation("AXI4-REQ-PRO-012", "WRAP 起始地址未对齐 wrap boundary", "ERROR",
                         item.is_read() ? "AR" : "AW", item);
      end
    end

    // ---- AXI4-REQ-RUL-010：Lite 不允许 exclusive ----
    if ((cfg.protocol == AXI4LITE_PROTOCOL) && (item.lock == AXI4_EXCLUSIVE_LOCK)) begin
      report_violation("AXI4-REQ-RUL-010", "AXI4-Lite 不支持 exclusive", "ERROR",
                       item.is_read() ? "AR" : "AW", item);
    end
  endfunction

  // ===========================================================================
  // 规则检查 — 响应（B/R）
  // ===========================================================================
  protected function void check_response_rules(axi4_item item);
    // ---- AXI4-REQ-RUL-010：响应编码 ----
    foreach (item.response[i]) begin
      axi4_response r = item.response[i];
      if (!(r inside {AXI4_OKAY, AXI4_EXOKAY, AXI4_SLAVE_ERROR, AXI4_DECODE_ERROR})) begin
        report_violation("AXI4-REQ-RUL-010", "非法响应编码", "ERROR",
                         item.is_read() ? "R" : "B", item);
      end
    end

    // ---- AXI4-REQ-RUL-007：EXOKAY 仅用于 exclusive ----
    if (!(item.lock == AXI4_EXCLUSIVE_LOCK)) begin
      foreach (item.response[i]) begin
        if (item.response[i] == AXI4_EXOKAY) begin
          report_violation("AXI4-REQ-RUL-007", "非 exclusive 事务返回 EXOKAY", "ERROR",
                           item.is_read() ? "R" : "B", item);
        end
      end
    end
  endfunction

  // ===========================================================================
  // 规则检查 — 完整事务（monitor 流）
  // ===========================================================================
  protected function void check_transaction_rules(axi4_item item);
    // ---- AXI4-REQ-RUL-005/016：响应 beat 数与突发长度一致 ----
    // 注意：monitor_imp 收到的可能是"请求阶段"（response 未完成）的 item，
    // 此时 response.size()==0 属正常；仅对已带响应的完整事务检查。
    // 写事务：B 响应每事务 1 拍；读事务：R 响应 beat 数 == burst_length。
    if (item.has_response && (item.response.size() > 0)) begin
      if (item.is_read()) begin
        if (item.response.size() != item.burst_length) begin
          report_violation("AXI4-REQ-RUL-007", "R 响应 beat 数与突发长度不一致", "ERROR", "R", item);
        end
      end
      else begin
        if (item.response.size() != 1) begin
          report_violation("AXI4-REQ-RUL-007", "B 响应应为 1 拍/事务", "ERROR", "B", item);
        end
      end
    end

    // ---- AXI4-REQ-RUL-017：burst 完整性（写侧 W beat 数 == awlen+1）----
    // monitor 重建的 data 已按"实际接收的 W beat 数"（WLAST 时 resize）；
    // 实际拍数 != awlen+1 → 缩短/超长违规；合法事务必定相等（不误报）。
    if (item.is_write() && item.has_response &&
        (item.data.size() > 0) && (item.data.size() != item.burst_length)) begin
      report_violation("AXI4-REQ-RUL-017",
                       $sformatf("写事务 W 实际 %0d beat != 突发长度 %0d（burst 完整性违规）",
                                 item.data.size(), item.burst_length), "ERROR", "W", item);
    end

    // ---- AXI4-REQ-RUL-005：burst 完成必须有 WLAST（missing-WLAST 注入检测）----
    // monitor 依 WLAST 触发 end_write_data；missing-WLAST 时 data 收满 burst_length
    // 但 write_data_ended 未置位 → 该笔事务"数据齐而无 WLAST"即缺失违规。
    if (item.is_write() && item.has_response &&
        (item.data.size() == item.burst_length) &&
        (item.write_data_ended_status() == 0) &&
        (item.burst_length > 1)) begin
      report_violation("AXI4-REQ-RUL-005",
                       "写事务数据收满但无 WLAST（burst 未正常终止）", "ERROR", "W", item);
    end
  endfunction

  // ===========================================================================
  // Ordering Model（§5.1）：入队
  // ===========================================================================
  protected function void enqueue_request(axi4_item item);
    if (item.is_read()) begin
      read_request_queue[item.id].push_back(item);
    end
    else begin
      write_request_queue[item.id].push_back(item);
    end
  endfunction

  protected function void enqueue_response(axi4_item item);
    if (item.is_read()) begin
      read_response_queue[item.id].push_back(item);
    end
    else begin
      write_response_queue[item.id].push_back(item);
    end
  endfunction

  // ===========================================================================
  // 报告
  // ===========================================================================
  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info(get_type_name(),
      $sformatf("检查 %0d 笔事务，违规 %0d 个", check_count, violation_count), UVM_LOW)
  endfunction

endclass : axi4_checker

`endif // AXI4_CHECKER__SV
