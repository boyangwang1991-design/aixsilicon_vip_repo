// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 AIXSILICON
//
// apb_smoke_tb.sv — APB smoke 顶层：时钟/复位、接口、最小 DUT 占位与 UVM harness。
`ifndef APB_SMOKE_TB_SV
`define APB_SMOKE_TB_SV

`timescale 1ns/1ps

module apb_smoke_tb;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  logic pclk;
  logic presetn;

  apb_if #(.DATA_WIDTH(32), .ADDR_WIDTH(12)) u_apb_if (.pclk(pclk), .presetn(presetn));

  // 最小 DUT 占位（真实测试使用黄金 DUT / 参考模型）
  apb_smoke_dut u_dut (
    .pclk   (pclk),
    .presetn(presetn),
    .psel   (u_apb_if.psel),
    .penable(u_apb_if.penable),
    .paddr  (u_apb_if.paddr),
    .pwrite (u_apb_if.pwrite),
    .pwdata (u_apb_if.pwdata),
    .prdata (u_apb_if.prdata),
    .pready (u_apb_if.pready),
    .pslverr(u_apb_if.pslverr)
  );

  initial begin
    pclk = 1'b0;
    forever #5 pclk = ~pclk;
  end

  initial begin
    presetn = 1'b0;
    repeat (3) @(posedge pclk);
    presetn = 1'b1;
    uvm_config_db#(virtual apb_if)::set(null, "uvm_test_top.env.apb_master.*", "vif", u_apb_if);
    uvm_config_db#(virtual apb_if)::set(null, "uvm_test_top.env.apb_slave.*",  "vif", u_apb_if);
    run_test("apb_smoke_test");
  end

  initial begin
    #100_000;
    $display("TIMEOUT: apb_smoke_tb 超时");
    $finish;
  end

endmodule : apb_smoke_tb

// 最小 APB 寄存器 DUT（仅用于 smoke，非正式 VIP 内容）
module apb_smoke_dut (
  input logic               pclk,
  input logic               presetn,
  input logic               psel,
  input logic               penable,
  input logic [11:0]        paddr,
  input logic               pwrite,
  input logic [31:0]        pwdata,
  output logic [31:0]       prdata,
  output logic              pready,
  output logic              pslverr
);
  logic [31:0] mem [256];
  assign pready  = 1'b1;
  assign pslverr = 1'b0;
  always_ff @(posedge pclk or negedge presetn) begin
    if (!presetn) begin
      prdata <= '0;
    end else if (psel && penable) begin
      if (pwrite) mem[paddr[11:2]] <= pwdata;
      else        prdata <= mem[paddr[11:2]];
    end
  end
endmodule : apb_smoke_dut

`endif
