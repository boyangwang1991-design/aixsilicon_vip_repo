// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 AIXSILICON
//
// apb_checker_assert.sv — APB 协议属性断言（SVA）。
// 与 apb_checker.sv 互补；供动态仿真与 formal 使用。
`ifndef APB_CHECKER_ASSERT_SV
`define APB_CHECKER_ASSERT_SV

module apb_checker_assert #(parameter int DATA_WIDTH = 32,
                            parameter int ADDR_WIDTH = 12) (
  input logic               pclk,
  input logic               presetn,
  input logic               psel,
  input logic               penable,
  input logic [ADDR_WIDTH-1:0] paddr,
  input logic               pwrite,
  input logic [DATA_WIDTH-1:0] pwdata,
  input logic               pready,
  input logic               pslverr
);

  // PENABLE 不允许先于 PSEL（setup 阶段必须 PSEL=1, PENABLE=0）
  a_penable_requires_psel: assert property (
    @(posedge pclk) disable iff (!presetn)
      (penable == 1'b1) |-> (psel == 1'b1));

  // ACCESS 阶段 PADDR 稳定
  a_addr_stable: assert property (
    @(posedge pclk) disable iff (!presetn)
      (psel && penable && !pready) |=> ($stable(paddr) && (psel && penable)));

  // 每次 ACCESS 最终都会完成（PREADY 终将拉高）——避免 liveness 用 assume 时除外
  a_access_terminates: assert property (
    @(posedge pclk) disable iff (!presetn)
      (psel && penable && !pready) |-> ##[1:$] pready);

endmodule : apb_checker_assert

`endif
