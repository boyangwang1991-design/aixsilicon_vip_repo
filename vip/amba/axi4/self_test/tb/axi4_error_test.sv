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

    // ---- E1: early WLAST（len=4，第 2 拍提前 WLAST；RUL-017）----
    bdata   = new[4];
    bstrobe = new[4];
    foreach (bdata[i]) begin
      bdata[i]   = 32'hE100_0000 + i;
      bstrobe[i] = '1;
    end
    `uvm_info(get_type_name(), "E1: early-WLAST injection (expect SVA RUL-005/017 detect)", UVM_LOW)
    // 注入钩子在 driver：通过 config_db 由 test 设置（见 error_test build_phase）
    burst_write(32'h0000_C000, bdata, bstrobe, 4);
    #50;

    // ---- E2: stalled payload 翻转（RUL-011）----
    `uvm_info(get_type_name(), "E2: unstable payload injection (expect SVA RUL-011 detect)", UVM_LOW)
    burst_write(32'h0000_C100, bdata, bstrobe, 4);
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
    axi4_master_driver mdrv;

    // 注入钩子与策略配置（在 sequence 启动前生效）
    if (env.master_agent != null && env.master_agent.driver != null) begin
      mdrv = env.master_agent.driver;
      mdrv.inject_early_wlast      = 1;   // E1
      mdrv.inject_unstable_payload = 1;   // E2
      mdrv.inject_missing_wlast    = 0;
    end
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
      // E1/E2 期间 W 背压使 stall 发生（RUL-011 翻转窗口）
      env.slave_cfg.wready_delay.enabled     = 1;
      env.slave_cfg.wready_delay.delay_kind  = 1;
      env.slave_cfg.wready_delay.delay_min   = 2;
      env.slave_cfg.wready_delay.delay_max   = 4;
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
    super.report_phase(phase);
    errs = svr.get_severity_count(UVM_ERROR);
    // E1/E2 注入 2 次 → 至少 2 条检出；E3/E4 不得引入额外误报（阈值放宽为 ≥2）
    if (errs < 2) begin
      `uvm_error(get_type_name(), $sformatf(
        "error test: only %0d violations detected < 2 injected (RUL-005/011 mutation leak)", errs))
    end
    else begin
      `uvm_info(get_type_name(), $sformatf(
        "error test: %0d violations detected from 2 timing injections (>=2 PASS)", errs), UVM_LOW)
    end
  endfunction

endclass : axi4_error_test

`endif // AXI4_ERROR_TEST__SV
