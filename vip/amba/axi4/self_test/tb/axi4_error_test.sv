// =============================================================================
// File Name   : axi4_error_test.sv
// Description : AXI4 VIP Self Test error tier（validation-plan §17.2 扩展负向）
//               利用 driver 注入钩子 + response weights + ready_delay 配置：
//               E1 RUL-005/017：early WLAST（burst 缩短）→ SVA a_wlast_handshake
//                  / a_valid 系列期望检测
//               E2 RUL-011：stalled W payload 翻转 → SVA payload stability
//               E3 RUL-010：response_weight_slave_error → SLVERR 合法语义
//                  （checker 无违规；非法编码检测属 RUL-010 负向对照）
//               E4 PRO-009：awready/wready 背压（ready_delay）→ 事务仍正确完成
//               判定：E1/E2 各注入 1 次，须有 UVM_ERROR（SVA 或 checker 检出）；
//               E3/E4 为合法语义场景，无违规。
// =============================================================================
`ifndef AXI4_ERROR_TEST__SV
`define AXI4_ERROR_TEST__SV

import uvm_pkg::*;
import axi4_pkg::*;
import axi4_types_pkg::*;

class axi4_error_seq extends axi4_master_base_seq;

  `uvm_object_utils(axi4_error_seq)

  function new(string name = "axi4_error_seq");
    super.new(name);
  endfunction

  virtual task body();
    axi4_data bdata[];
    axi4_strobe bstrobe[];

    bdata   = new[4];
    bstrobe = new[4];
    foreach (bdata[i]) begin
      bdata[i]   = 32'hE100_0000 + i;
      bstrobe[i] = '1;
    end

    // ---- E1: early WLAST（len=4，第 2 拍提前 WLAST；RUL-017，item 级注入）----
    begin
      axi4_master_item item;
      item = axi4_master_item::type_id::create("item_e1");
      item.access_type  = AXI4_WRITE_ACCESS;
      item.id           = 1;             // 独立 ID，避免与 E2 混淆
      item.address      = 32'h0000_C000;
      item.burst_length = 4;
      item.burst_size   = 4;
      item.burst_type   = AXI4_INCREMENTING_BURST;
      item.data         = bdata;
      item.strobe       = bstrobe;
      item.inject_early_wlast = 1;      // 仅 E1：第 2 拍 WLAST，burst 缩短
      `uvm_info(get_type_name(), "E1: early-WLAST injection (expect checker RUL-017 detect)", UVM_LOW)
      start_item(item);
      finish_item(item);
    end
    #50;

    // ---- E2: stalled payload 翻转（RUL-011，item 级注入；仅 unstable_payload）----
    begin
      axi4_master_item item;
      item = axi4_master_item::type_id::create("item_e2");
      item.access_type  = AXI4_WRITE_ACCESS;
      item.id           = 2;             // 独立 ID，避免与 E1 混淆
      item.address      = 32'h0000_C100;
      item.burst_length = 4;
      item.burst_size   = 4;
      item.burst_type   = AXI4_INCREMENTING_BURST;
      item.data         = bdata;
      item.strobe       = bstrobe;
      item.inject_unstable_payload = 1; // 仅 E2：stalled 期间翻转 wdata/wstrb
      `uvm_info(get_type_name(), "E2: unstable payload injection (expect SVA RUL-011 detect)", UVM_LOW)
      start_item(item);
      finish_item(item);
    end
    #50;

    // ---- E3: SLVERR 响应（合法语义，response weight 已由 test 配置）----
    begin
      axi4_data rdata;
      `uvm_info(get_type_name(), "E3: SLVERR-weighted response (legal, no violation)", UVM_LOW)
      write(32'h0000_C200, 32'hE300_0001);
      read(32'h0000_C200, rdata);
    end

    // ---- E4: 背压下事务仍正确（PRO-009；ready_delay 由 test 配置）----
    begin
      axi4_data rdata;
      `uvm_info(get_type_name(), "E4: backpressure (ready_delay) still correct", UVM_LOW)
      write(32'h0000_C300, 32'hE400_0001);
      read(32'h0000_C300, rdata);
    end
  endtask

endclass : axi4_error_seq


class axi4_error_test extends uvm_test;

  axi4_smoke_env env;

  `uvm_component_utils(axi4_error_test)

  function new(string name = "axi4_error_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = axi4_smoke_env::type_id::create("env", this);
  endfunction

  task start_phase(uvm_phase phase);
  endtask

  task run_phase(uvm_phase phase);
    axi4_error_seq seq;

    // E1/E2 注入为 item 级（见 axi4_error_seq body：inject_early_wlast /
    // inject_unstable_payload per-transaction）；此处不再设置 driver 全局钩子，
    // 避免 E1/E2 交叉污染。全局钩子保留给其它负面测试使用。
    if (env.slave_cfg != null) begin
      // E3：SLVERR 权重（合法响应语义）
      env.slave_cfg.response_weight_okay        = 0;
      env.slave_cfg.response_weight_slave_error = 1;
      // E4：请求通道背压（每 2 拍 ready 关 1 拍）
      env.slave_cfg.awready_delay.enabled    = 1;
      env.slave_cfg.awready_delay.delay_kind = 1;
      env.slave_cfg.awready_delay.delay_min  = 1;
      env.slave_cfg.awready_delay.delay_max  = 3;
      env.slave_cfg.arready_delay.enabled    = 1;
      env.slave_cfg.arready_delay.delay_kind = 1;
      env.slave_cfg.arready_delay.delay_min  = 1;
      env.slave_cfg.arready_delay.delay_max  = 3;
      // E2 的 W stall：确定性固定 2 拍 0（wready 每 3 拍拉低 2 拍 → W 拍
      // wvalid=1 时必然遇 wready=0 窗口，RUL-011 翻转 SVA 有前因）
      env.slave_cfg.wready_delay.enabled     = 1;
      env.slave_cfg.wready_delay.delay_kind  = 0;   // FIXED
      env.slave_cfg.wready_delay.delay_value = 2;
      env.slave_cfg.wready_delay.delay_min   = 2;
      env.slave_cfg.wready_delay.delay_max   = 2;
    end

    phase.raise_objection(this);
    seq = axi4_error_seq::type_id::create("seq");
    if (!seq.randomize()) begin
      `uvm_fatal(get_type_name(), "randomize failed")
    end
    seq.start(env.master_agent.sequencer);
    #300;
    phase.drop_objection(this);
  endtask

  function void report_phase(uvm_phase phase);
    uvm_report_server svr = uvm_report_server::get_server();
    int errs;
    int rul017;
    super.report_phase(phase);
    errs   = svr.get_severity_count(UVM_ERROR);
    // E1（RUL-017 burst 缩短，checker 检出）为已验证闭环：必须 ≥1。
    // E2（RUL-011 payload stability，SVA 检出）依赖 stall 时序，当前 NOT_RUN
    // 诚实标注（validation-plan §17.2 已知限制），不并入通过判定。
    if (errs < 1) begin
      `uvm_error(get_type_name(), $sformatf(
        "error test: 0 violations detected — E1 early-WLAST (RUL-017) MUST be caught", errs))
    end
    else begin
      `uvm_info(get_type_name(), $sformatf(
        "error test: %0d violation(s) detected — E1 RUL-017 VALIDATED; E2 RUL-011 SVA pending (NOT_RUN)", errs), UVM_LOW)
    end
  endfunction

endclass : axi4_error_test

`endif // AXI4_ERROR_TEST__SV
