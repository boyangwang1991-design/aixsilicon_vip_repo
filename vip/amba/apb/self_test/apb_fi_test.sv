// =============================================================================
// File Name   : apb_fi_test.sv
// Description : Fault Injection / Mutation tier（G5）：
//               FI-001 extended SETUP（RUL-001 ← SVA-A1 检出）
//               FI-002 illegal PENABLE（RUL-002 ← SVA-A2b 检出）
//               FI-003 unstable addr during wait（RUL-003 ← SVA-B1 检出）
//               FI-004 illegal read strb（RUL-006 ← SVA-F1 检出）
//               FI-005 ACCESS hang（RUL-009 ← CHK-R9 超时 violation 检出）
//               检出统计：SVA 检出经 vif.sva_hit_cnt（apb_if 内计数器）；
//               RUL-009 经 report catcher 抓 [RUL-009] 消息。
//               判定：FI_ALL_DETECTED（检出率 100%）/ FI_MISSING_DETECTION
// VLNV        : aixsilicon:vip:apb:1.0.0
// =============================================================================

`ifndef APB_FI_TEST__SV
`define APB_FI_TEST__SV

// RUL-009 检出抓取（checker 走 UVM report error，消息含 [RUL-009]）
class apb_fi_report_catcher extends uvm_report_catcher;
  `uvm_object_utils(apb_fi_report_catcher)
  int unsigned rul9_hits = 0;
  function new(string name = "apb_fi_report_catcher");
    super.new(name);
  endfunction
  virtual function action_e catch();
    string msg = get_message();
    if (get_severity() inside {UVM_ERROR, UVM_WARNING, UVM_FATAL} &&
        msg.substr(0, 6) == "[RUL-00")
      rul9_hits++;
    return THROW;
  endfunction
endclass

// FI 激励 sequence（在 master sequencer 上启动；item 级注入字段直通）
class apb_fi_sequence extends uvm_sequence #(apb_item);
  `uvm_object_utils(apb_fi_sequence)
  function new(string name = "apb_fi_sequence");
    super.new(name);
  endfunction

  task inject_item(apb_direction_e dir, bit [`APB_MAX_ADDR_WIDTH-1:0] addr,
                   bit ext_setup = 0, bit ill_pen = 0,
                   bit uns_addr = 0, bit ill_strb = 0);
    apb_item it = apb_item::type_id::create("fi_item");
    start_item(it);
    it.direction               = dir;
    it.addr                    = addr;
    it.wdata                   = $urandom;
    it.inject_extended_setup   = ext_setup;
    it.inject_illegal_penable  = ill_pen;
    it.inject_unstable_addr    = uns_addr;
    it.inject_illegal_strb     = ill_strb;
    finish_item(it);
  endtask

  virtual task body();
    inject_item(APB_WRITE, 'h1000, .ext_setup(1));   // FI-001 RUL-001
    inject_item(APB_READ,  'h1004, .ill_pen(1));     // FI-002 RUL-002
    inject_item(APB_WRITE, 'h1008, .uns_addr(1));    // FI-003 RUL-003
    inject_item(APB_READ,  'h100C, .ill_strb(1));    // FI-004 RUL-006
    inject_item(APB_READ,  'h1010);                  // FI-005 RUL-009
  endtask
endclass

class apb_fi_test extends uvm_test;

  `uvm_component_utils(apb_fi_test)

  apb_smoke_env env;
  apb_fi_report_catcher catcher;
  int unsigned rul9_hits = 0;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase_);
    super.build_phase(phase_);
    env = apb_smoke_env::type_id::create("env", this);
    // tier 覆盖位（env build 时应用：FIXED_WAIT=20 > timeout 16 → RUL-009 窗
    // + allow_protocol_violation=1 接受 inject_*）
    env.mode_fi = 1;
    // RUL-009 检出抓取
    catcher = apb_fi_report_catcher::type_id::create("catcher");
    uvm_report_cb::add_by_name("*", catcher, this);
  endfunction

  // ---------------------------------------------------------------------------
  // 检出判定（report_phase）：SVA 计数直读 vif.sva_hit_cnt；
  // RUL-009 由 catcher.rul9_hits 统计（wait=20 > timeout=16 → 必触发）
  // ---------------------------------------------------------------------------
  function void report_phase(uvm_phase phase_);
    bit all_detected;
    int c1, c2, c3, c6;
    super.report_phase(phase_);
    rul9_hits = env.checker.hit_cnt.exists("RUL-009") ? env.checker.hit_cnt["RUL-009"] : 0;
    c1 = env.vif.sva_hit_cnt.exists("RUL-001") ? env.vif.sva_hit_cnt["RUL-001"] : 0;
    c2 = env.vif.sva_hit_cnt.exists("RUL-002") ? env.vif.sva_hit_cnt["RUL-002"] : 0;
    c3 = env.vif.sva_hit_cnt.exists("RUL-003") ? env.vif.sva_hit_cnt["RUL-003"] : 0;
    c6 = env.vif.sva_hit_cnt.exists("RUL-006") ? env.vif.sva_hit_cnt["RUL-006"] : 0;
    `uvm_info(get_type_name(), $sformatf(
      "FI_SUMMARY: RUL-001=%0d RUL-002=%0d RUL-003=%0d RUL-006=%0d RUL-009=%0d",
      c1, c2, c3, c6, rul9_hits), UVM_NONE)
    all_detected = (c1 > 0) && (c2 > 0) && (c3 > 0) && (c6 > 0) && (rul9_hits > 0);
    if (all_detected) $display("FI_ALL_DETECTED");
    else              $display("FI_MISSING_DETECTION");
  endfunction

  task run_phase(uvm_phase phase_);
    apb_fi_sequence fseq;
    phase_.raise_objection(this);
    fseq = apb_fi_sequence::type_id::create("fseq");
    fseq.start(env.master_agent.sequencer);
    #300ns;
    phase_.drop_objection(this);
  endtask

endclass

`endif // APB_FI_TEST__SV
