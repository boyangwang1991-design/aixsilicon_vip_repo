// Copyright (c) 2026 AIXSILICON
// SPDX-License-Identifier: Apache-2.0
//
// hac_if_assertions: HAC-IF 协议 SVA（骨架；依据 HWIF hac_if_spec 全局不变量）。
// 可 bind 到 DUT 接口。完整集合覆盖见 docs/spec_control.md 与 docs/testplan.md。

`ifndef HAC_IF_ASSERTIONS_SV
`define HAC_IF_ASSERTIONS_SV

module hac_if_assertions
  import aix_hac_if_pkg::*;
(
  input logic clk,
  input logic rst_n,

  // HAC-CTRL
  input logic ctrl_cmd_valid,
  input logic ctrl_cmd_ready,
  input logic [7:0] ctrl_cmd_job_id,
  input logic ctrl_cpl_valid,
  input logic ctrl_cpl_ready,
  input logic [7:0] ctrl_cpl_job_id,
  input logic ctrl_quiescent,

  // HAC-MEM
  input logic mem_rsp_valid,
  input logic mem_rsp_ready,
  input logic [5:0] mem_rsp_tag
);

  // 背压期间命令 Payload 稳定
  A_CTRL_CMD_STABLE:
    assert property (
      @(posedge clk) disable iff (!rst_n)
        (ctrl_cmd_valid && !ctrl_cmd_ready) |=> ($stable(ctrl_cmd_job_id) || ctrl_cmd_ready));

  // 背压期间完成 Payload 稳定
  A_CTRL_CPL_STABLE:
    assert property (
      @(posedge clk) disable iff (!rst_n)
        (ctrl_cpl_valid && !ctrl_cpl_ready) |=> ($stable(ctrl_cpl_job_id) || ctrl_cpl_ready));

  // quiescent 时无在途访存响应（简化）
  A_QUIESCENT_NO_RSP:
    assert property (
      @(posedge clk) disable iff (!rst_n)
        ctrl_quiescent |-> !mem_rsp_valid);

  // 响应背压期间 Tag 稳定
  A_MEM_RSP_TAG_STABLE:
    assert property (
      @(posedge clk) disable iff (!rst_n)
        (mem_rsp_valid && !mem_rsp_ready) |=> ($stable(mem_rsp_tag) || mem_rsp_ready));

endmodule : hac_if_assertions

`endif
