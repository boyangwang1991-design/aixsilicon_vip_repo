// =============================================================================
// File Name   : apb_smoke_tb5.sv
// Description : APB5 Self Test 顶层 testbench（UT13/14/20/21 专项）
//               - 组件 vif 类型为 virtual apb_if（默认参数）——故接口保持默认
//                 参数；RME-PNSE/WAKEUP/*CHK 语义由 env.mode_apb5 配置
//                 (cfg.rme_support=1 等) 启用，test 手动驱动 vif.pnse_w/wakeup
//               - loopback：master VIP ↔ slave VIP + monitor + checker + coverage
// VLNV        : aixsilicon:vip:apb:1.0.0
// =============================================================================

`ifndef APB_SMOKE_TB5__SV
`define APB_SMOKE_TB5__SV

`timescale 1ns/1ps

module apb_smoke_tb5;

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

  initial begin
    presetn = 1'b0;
    check_enable = 1'b1;
    #23;
    presetn = 1'b1;
  end

  // ---------------------------------------------------------------------------
  // APB 接口（默认参数——与 virtual apb_if 组件类型一致）
  // RME/WAKEUP/CHK 语义启用由 cfg 驱动（mode_apb5）；pnse_w/wakeup_w 由 test 直驱
  // ---------------------------------------------------------------------------
  apb_if u_if (.pclk(pclk), .presetn(presetn), .check_enable(check_enable));

  initial begin
    uvm_config_db#(virtual apb_if)::set(null, "*", "vif", u_if);
  end

  initial begin
    run_test("apb_apb5_test");
  end

  initial begin
    #300us;
    `uvm_fatal("TB5", "Global watchdog timeout (300us) — simulation hung")
  end

endmodule

`endif // APB_SMOKE_TB5__SV