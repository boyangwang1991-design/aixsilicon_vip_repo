// =============================================================================
// File Name   : apb_protocol_sva.sv
// Description : SVA-first protocol checker（checker module，bind 到 apb_if）
//               ADR-0/ADR-2：generate-if 只依赖 interface elaboration 参数
//               （HAS_*），UVM runtime config 永不进入 generate（G1 blocker②）。
//               runtime 门经 sva_enable（RUL-001..008/010，anti-overcheck
//               语义：C2/E1 不写强断言——UT17/UT18 防过严）。
//               端口为 interface 类型（无 modport，bind 语义）。
// VLNV        : aixsilicon:vip:apb:1.0.0
// =============================================================================

`ifndef APB_PROTOCOL_SVA__SV
`define APB_PROTOCOL_SVA__SV

module apb_protocol_sva #(
  parameter bit HAS_PSTRB  = 1,
  parameter bit HAS_PPROT  = 1,
  parameter bit HAS_CHECK  = 0,
  parameter int ADDR_WIDTH = 32,
  parameter int DATA_WIDTH = 32,
  parameter int NUM_SLAVES = 1
) (
  input logic pclk,
  input logic presetn,
  input logic sva_enable,
  input logic [NUM_SLAVES-1:0] psel,
  input logic penable,
  input logic pready,
  input logic pwrite,
  input logic [ADDR_WIDTH-1:0] paddr,
  input logic [DATA_WIDTH/8-1:0] pstrb_w,
  input logic [2:0] pprot_w
);
  // 说明：由 apb_if 内部实例化连接（elaboration-time 参数——ADR-0/blocker②）

  // ---------------------------------------------------------------------------
  // A1：SETUP 恰 1 拍且次拍进入 ACCESS（PSEL 保持 + PENABLE=1）（RUL-001）
  // ---------------------------------------------------------------------------
  property p_setup_one_cycle;
    @(posedge pclk) disable iff (!presetn || !sva_enable)
      (psel[0] && !penable) |=> (psel[0] && penable);
  endproperty
  A1_setup_one_cycle: assert property (p_setup_one_cycle)
    else $error("[RUL-001] SETUP must last exactly 1 cycle and proceed to ACCESS");

  // ---------------------------------------------------------------------------
  // A2：PENABLE 仅出现在 ACCESS（无 PSEL 的 PENABLE 禁止）（RUL-002）
  // ---------------------------------------------------------------------------
  property p_penable_in_access;
    @(posedge pclk) disable iff (!presetn || !sva_enable)
      penable |-> psel[0];
  endproperty
  A2_penable_in_access: assert property (p_penable_in_access)
    else $error("[RUL-002] PENABLE asserted without PSEL");

  // ---------------------------------------------------------------------------
  // B1：ACCESS 延长期（PREADY=0）request 字段稳定（RUL-003）
  //     恒查：paddr/pwrite/psel；条件查按 HAS_*（elaboration，blocker②）
  // ---------------------------------------------------------------------------
  property p_addr_stable;
    @(posedge pclk) disable iff (!presetn || !sva_enable)
      (psel[0] && penable && !pready) |=> (psel[0] && $stable(paddr) && $stable(pwrite));
  endproperty
  B1_addr_stable: assert property (p_addr_stable)
    else $error("[RUL-003] PADDR/PWRITE/PSEL must be stable during wait states");

  generate
    if (HAS_PSTRB) begin : g_b1_strb
      property p_strb_stable;
        @(posedge pclk) disable iff (!presetn || !sva_enable)
          (psel[0] && penable && !pready) |=> $stable(pstrb_w);
      endproperty
      B1_strb_stable: assert property (p_strb_stable)
        else $error("[RUL-003] PSTRB must be stable during wait states");
    end
    if (HAS_PPROT) begin : g_b1_pprot
      property p_pprot_stable;
        @(posedge pclk) disable iff (!presetn || !sva_enable)
          (psel[0] && penable && !pready) |=> $stable(pprot_w);
      endproperty
      B1_pprot_stable: assert property (p_pprot_stable)
        else $error("[RUL-003] PPROT must be stable during wait states");
    end
  endgenerate

  // ---------------------------------------------------------------------------
  // C1：completion 次拍 PENABLE 撤销（或直入下一笔 SETUP——PENABLE 撤销等价）（RUL-004）
  // ---------------------------------------------------------------------------
  property p_completion_exit;
    @(posedge pclk) disable iff (!presetn || !sva_enable)
      (psel[0] && penable && pready) |=> !penable;
  endproperty
  C1_completion_exit: assert property (p_completion_exit)
    else $error("[RUL-004] PENABLE must deassert after completion");

  // ---------------------------------------------------------------------------
  // C2：completion 定义载体（RUL-010）——anti-overcheck：
  //     SETUP 拍（PENABLE=0）PREADY 任意值合法（UT17 验证不误报）。
  //     completion 只在 ACCESS 判定，无需强断言（monitor/checker 同口径）。
  // ---------------------------------------------------------------------------

  // ---------------------------------------------------------------------------
  // E1：PSLVERR 语义窗（RUL-005）——anti-overcheck：
  //     不写 pslverr==0 强断言（非有效期非零仅 recommendation，UT18 验证）；
  //     采样语义由 monitor（仅 completion 拍采样）保证。
  // ---------------------------------------------------------------------------

  // ---------------------------------------------------------------------------
  // F1：读传输 PSTRB==0（RUL-006，HAS_PSTRB 时编译）
  // ---------------------------------------------------------------------------
  generate
    if (HAS_PSTRB) begin : g_f1
      property p_read_strb_zero;
        @(posedge pclk) disable iff (!presetn || !sva_enable)
          (psel[0] && !pwrite) |-> (pstrb_w == '0);
      endproperty
      F1_read_strb_zero: assert property (p_read_strb_zero)
        else $error("[RUL-006] PSTRB must be 0 for read transfers");
    end
  endgenerate

  // ---------------------------------------------------------------------------
  // G1：复位期间 PSEL=0（RUL-008）
  // ---------------------------------------------------------------------------
  property p_reset_idle;
    @(posedge pclk) disable iff (sva_enable === 1'b0)
      !presetn |-> (!psel[0] && !penable);
  endproperty
  G1_reset_idle: assert property (p_reset_idle)
    else $error("[RUL-008] PSEL/PENABLE must be 0 during reset");

  // ---------------------------------------------------------------------------
  // H1：validity 辅助（RUL-011）——penable 无 psel 禁止（与 A2 互备，
  //     不同 disable 条件：复位期也生效）
  // ---------------------------------------------------------------------------
  property p_validity_penable;
    @(posedge pclk) disable iff (!sva_enable)
      penable && !psel[0];
  endproperty
  H1_validity_penable: assert property (p_validity_penable)
    else $error("[RUL-011] PENABLE valid only when PSEL asserted");

endmodule

// ---------------------------------------------------------------------------
// bind（tb/env 侧执行）：
//   bind apb_if apb_protocol_sva #(
//     .HAS_PSTRB(HAS_PSTRB), .HAS_PPROT(HAS_PPROT), .HAS_CHECK(HAS_CHECK)
//   ) u_apb_sva (bus(u_if));
// 注：bind 的端口连接写法为 (bus(u_if))——将 interface 实例传入 bus 端口。
// ---------------------------------------------------------------------------
`endif // APB_PROTOCOL_SVA__SV
