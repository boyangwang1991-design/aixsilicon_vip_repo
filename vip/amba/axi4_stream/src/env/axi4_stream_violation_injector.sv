// =============================================================================
// File Name   : axi4_stream_violation_injector.sv
// Description : axi4_stream 错误注入控制器（独立 fault fixture / driver 破坏路径）
// 依据        : docs/requirement.md（REQ-ERR-001..003, §11 注入类型表）
//
// 设计说明：
//   * 注入缺省关闭；启用时指定 rule、注入位置、持续周期/次数、seed 和期望告警
//     （REQ-ERR-001）。
//   * 每个注入场景必须匹配预期 rule ID、数量范围和严重度；额外意外告警导致失败，
//     预期告警缺失也导致失败（REQ-ERR-002）。
//   * 禁止通过全局关闭 checker 来运行负向测试。
// =============================================================================

`ifndef AXI4_STREAM_VIOLATION_INJECTOR__SV
`define AXI4_STREAM_VIOLATION_INJECTOR__SV

typedef struct {
  string rule_id;          // 期望命中的规则
  string location;         // 注入位置描述（stall/data/keep/last/id/dest/user/reset）
  int    cycles;           // 持续周期/次数
  int    seed;             // 可重放 seed
  int    min_hits;         // 期望命中数量下界
  int    max_hits;         // 期望命中数量上界（0=不限）
} axis_injection_plan_t;

class axi4_stream_violation_injector extends uvm_component;

  `uvm_component_utils(axi4_stream_violation_injector)

  axi4_stream_checker checker;
  axis_injection_plan_t active_plan;
  bit enabled = 1'b0;

  function new(string name = "axi4_stream_violation_injector", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  // ---------------------------------------------------------------------------
  // 注入 API
  // ---------------------------------------------------------------------------
  function void enable_injection(string rule, string location, int cycles, int seed,
                                 int min_hits = 1, int max_hits = 0);
    active_plan.rule_id  = rule;
    active_plan.location = location;
    active_plan.cycles   = cycles;
    active_plan.seed     = seed;
    active_plan.min_hits = min_hits;
    active_plan.max_hits = max_hits;
    enabled = 1'b1;
    `uvm_info("AXIS-INJ", $sformatf(
      "启用错误注入 rule=%s location=%s cycles=%0d seed=%0d expect_hits=[%0d,%0d]",
      rule, location, cycles, seed, min_hits, max_hits), UVM_LOW)
  endfunction

  function void disable_injection();
    enabled = 1'b0;
  endfunction

  // ---------------------------------------------------------------------------
  // 期望匹配校验（REQ-ERR-002）：额外意外告警失败；预期告警缺失也失败
  // ---------------------------------------------------------------------------
  function bit verify_expectations(int observed_hits, int unexpected_hits);
    bit ok;
    ok = 1'b1;
    if (!enabled) begin
      `uvm_error("AXIS-INJ", "未启用注入却调用期望校验")
      return 1'b0;
    end
    if (observed_hits < active_plan.min_hits) begin
      `uvm_error("AXIS-INJ", $sformatf(
        "预期告警缺失：rule=%s 期望>=%0d 实际=%0d", active_plan.rule_id, active_plan.min_hits, observed_hits))
      ok = 1'b0;
    end
    if (active_plan.max_hits > 0 && observed_hits > active_plan.max_hits) begin
      `uvm_error("AXIS-INJ", $sformatf(
        "预期告警数量超范围：rule=%s 期望<=%0d 实际=%0d", active_plan.rule_id, active_plan.max_hits, observed_hits))
      ok = 1'b0;
    end
    if (unexpected_hits > 0) begin
      `uvm_error("AXIS-INJ", $sformatf("出现 %0d 个未解释的额外告警（REQ-ERR-002）", unexpected_hits))
      ok = 1'b0;
    end
    return ok;
  endfunction

  // 检查规则命中数（从 checker 读取）
  function bit check_rule_hit();
    int hits;
    if (checker == null) begin
      `uvm_error("AXIS-INJ", "未连接 checker，无法核对注入期望")
      return 1'b0;
    end
    hits = checker.rule_hits(active_plan.rule_id);
    return verify_expectations(hits, 0);
  endfunction

  // 注入类型覆盖清单（§11 注入类型表；每项对应一个 fixture/破坏路径）
  function void list_injection_types(output string types[$]);
    types.delete();
    types.push_back("VALID_DEASSERT_IN_STALL");       // stall 中撤销 TVALID
    types.push_back("PAYLOAD_CHANGE_IN_STALL");       // stall 中修改 TDATA/TKEEP/TSTRB/TLAST/TID/TDEST/TUSER
    types.push_back("TKEEP0_TSTRB1");                 // 非法字节限定符
    types.push_back("X_INJECTION_VALID_READY_PAYLOAD");// 四态注入（仅四态仿真器验收）
    types.push_back("RESET_VALID_NONZERO");           // 复位期间 valid 非零
    types.push_back("EARLY_MISSING_TLAST");           // 提前/缺失 TLAST（应用合同）
    types.push_back("DROPPED_DUPLICATED_REORDERED_BEAT"); // 合法握手下丢/重/乱序（故障 fixture）
    types.push_back("SUSTAINED_BACKPRESSURE_IDLE");   // 持续背压/空闲（watchdog）
  endfunction

endclass : axi4_stream_violation_injector

`endif // AXI4_STREAM_VIOLATION_INJECTOR__SV