// =============================================================================
// File Name   : apb_smoke_tb.sv
// Description : APB VIP Self Test 顶层 testbench（loopback：master VIP ↔ slave VIP）
//               - apb_if 实例（APB4 基线：HAS_PSTRB/HAS_PPROT=1）
//               - SVA bind（elaboration 参数，ADR-0）
//               - env：master+slave agent + 唯一 monitor + checker + coverage
//               - UT17/UT18 anti-overcheck 在 error test 中执行
// VLNV        : aixsilicon:vip:apb:1.0.0
// =============================================================================

`ifndef APB_SMOKE_TB__SV
`define APB_SMOKE_TB__SV

`timescale 1ns/1ps

module apb_smoke_tb;

  import uvm_pkg::*;
  import apb_types_pkg::*;
  import apb_pkg::*;

  logic pclk;
  logic presetn;
  logic check_enable;

  initial begin
    pclk = 1'b0;
    forever #5 pclk = ~pclk;
  end

  // reset-abort 窗口（G4：APB_ABORTED 覆盖；+ntb_reset_abort 触发）
  reg reset_abort_done = 0;
  initial begin
    presetn = 1'b0;
    check_enable = 1'b1;
    #23;
    presetn = 1'b1;
    // cov_sweep 带 +ntb_reset_abort=1：单次复位打断 rseq 中某 read →
    // READ×ABORTED（CR-02 read×aborted）。注：实测多次 timing reset 会干扰
    // 采样（feature 100%→85%），故只保留一次。
    if ($value$plusargs("ntb_reset_abort=%d", reset_abort_done) && reset_abort_done >= 1) begin
      #10_000_000ps;
      presetn = 1'b0;
      #20;
      presetn = 1'b1;
      $display("=== TB: reset-abort#1 (read segment) ===");
    end
  end

  // ---------------------------------------------------------------------------
  // APB interface（APB4 基线实例）
  // ---------------------------------------------------------------------------
  apb_if #(
    .ADDR_WIDTH      (32),
    .DATA_WIDTH      (32),
    .HAS_PSTRB       (1'b1),
    .HAS_PPROT       (1'b1),
    .USER_REQ_WIDTH  (0),
    .USER_DATA_WIDTH (0),
    .USER_RESP_WIDTH (0),
    .HAS_PWAKEUP     (1'b0),
    .HAS_PNSE        (1'b0),
    .HAS_CHECK       (1'b0)
  ) u_if (
    .pclk         (pclk),
    .presetn      (presetn),
    .check_enable (check_enable)
  );

  // SVA 检查：apb_if 内部已内嵌（generate-if 参数化——ADR-0/blocker②）

  // ---------------------------------------------------------------------------
  // config_db 注入：vif 由 tb 注入（env 侧 cfg 由 apb_smoke_env 构造）
  // ---------------------------------------------------------------------------
  initial begin
    uvm_config_db#(virtual apb_if)::set(null, "*", "vif", u_if);
  end

  // ---------------------------------------------------------------------------
  // UVM 启动（run_test）+ 全局 watchdog（300us，防挂死）
  // ---------------------------------------------------------------------------
  initial begin
    run_test("apb_smoke_test");
  end

  initial begin
    #300us;
    `uvm_fatal("TB", "Global watchdog timeout (300us) — simulation hung")
  end

endmodule

`endif // APB_SMOKE_TB__SV
