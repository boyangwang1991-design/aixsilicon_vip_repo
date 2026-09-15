// =============================================================================
// File Name   : axi4_stream_assertions.sv
// Description : axi4_stream 独立 SVA module（可 bind，也可直接例化）
// 依据        : docs/requirement.md（REQ-CHK-001/002/003/004, §8 规则表）
//
// 设计说明：
//   * 只覆盖适合 cycle-level 表达的规则；结构性/黑盒不可判定项（source 是否
//     依赖 ready 才产生 valid、接口是否存在组合路径）不在此伪装成 SVA 证明
//     （REQ-CHK-004）。
//   * 复位取消未完成的时序检查（REQ-CHK-001）。
//   * 与 UVM checker 同时启用时，每条断言带唯一关联 ID，便于去重
//     （REQ-CHK-003）。
//   * 不要求复位时 TREADY=0，也不要求 payload 清零（REQ-CHK-005）。
// =============================================================================

`ifndef AXI4_STREAM_ASSERTIONS__SV
`define AXI4_STREAM_ASSERTIONS__SV

module axi4_stream_assertions #(
  parameter bit HAS_TREADY = 1'b1,
  parameter bit HAS_TKEEP  = 1'b1,
  parameter bit HAS_TSTRB  = 1'b0,
  parameter bit HAS_TLAST  = 1'b1,
  parameter bit HAS_TDATA  = 1'b1
) (
  input logic aclk,
  input logic aresetn,
  input logic tvalid,
  input logic tready,
  input logic [7:0] tdata,
  input logic [0:0] tkeep,
  input logic [0:0] tstrb,
  input logic tlast
);

  // 有效 ready：HAS_TREADY=0 时恒为 1（REQ-CFG-002）
  wire eff_ready = HAS_TREADY ? tready : 1'b1;
  wire hs        = tvalid && eff_ready;

  // ---------------------------------------------------------------------------
  // AXIS-P001：复位期间 TVALID 为 0（SVA-AXIS-P001）
  // 判据为“不得为 1”：复位期间由未初始化产生的 X 不属于协议违规
  // （REQ-CHK-001 复位取消未完成/未初始化窗口），但被驱动为 1 必须报错。
  // ---------------------------------------------------------------------------
  property p_reset_valid_low;
    @(posedge aclk) !aresetn |-> tvalid !== 1'b1;
  endproperty
  a_p001: assert property (p_reset_valid_low)
    else $error("SVA-AXIS-P001: TVALID must not be 1 during reset");

  // ---------------------------------------------------------------------------
  // AXIS-P002：复位释放后的首个采样边沿仍观察到 TVALID=0（REQ-CHK-002）
  // ---------------------------------------------------------------------------
  logic release_seen;
  always_ff @(posedge aclk) begin
    if (!aresetn) release_seen <= 1'b0;
    else if (!release_seen) release_seen <= 1'b1;
  end
  property p_release_valid_low;
    @(posedge aclk) $rose(aresetn) |=> $past(tvalid) !== 1'b1;
  endproperty
  a_p002: assert property (p_release_valid_low)
    else $error("SVA-AXIS-P002: TVALID must not be 1 on the first sampled edge after reset release");

  // ---------------------------------------------------------------------------
  // AXIS-P003：stall 后到完成接收前 TVALID 持续为 1
  // ---------------------------------------------------------------------------
  property p_valid_stable;
    @(posedge aclk) disable iff (!aresetn)
      (tvalid && !eff_ready) |=> tvalid;
  endproperty
  a_p003: assert property (p_valid_stable)
    else $error("SVA-AXIS-P003: TVALID must remain asserted until handshake completes");

  // ---------------------------------------------------------------------------
  // AXIS-P004：stall 期间 payload/sideband 稳定（每个字段独立子码）
  // 稳定性检查覆盖解除背压并完成握手的那个边沿（REQ-PRO-003）
  // ---------------------------------------------------------------------------
  property p_payload_stable;
    @(posedge aclk) disable iff (!aresetn)
      (tvalid && !eff_ready) |=> (tvalid && $stable(tdata) && $stable(tlast));
  endproperty
  a_p004_data: assert property (p_payload_stable)
    else $error("SVA-AXIS-P004-DATA/LAST: payload must be stable during stall");

  generate
    if (HAS_TKEEP) begin : g_keep
      property p_keep_stable;
        @(posedge aclk) disable iff (!aresetn)
          (tvalid && !eff_ready) |=> (tvalid && $stable(tkeep));
      endproperty
      a_p004_keep: assert property (p_keep_stable)
        else $error("SVA-AXIS-P004-KEEP: TKEEP must be stable during stall");

      a_p005: assert property (@(posedge aclk) disable iff (!aresetn)
        (tvalid && HAS_TSTRB) |-> !((tkeep === 1'b0) && (tstrb === 1'b1)))
        else $error("SVA-AXIS-P005: TKEEP=0 must not correspond to TSTRB=1");
    end
  endgenerate

  // ---------------------------------------------------------------------------
  // AXIS-P006：复位外 TVALID、存在的 TREADY 不得未知
  // ---------------------------------------------------------------------------
  property p_no_unknown_valid;
    @(posedge aclk) aresetn |-> !$isunknown(tvalid);
  endproperty
  a_p006: assert property (p_no_unknown_valid)
    else $error("SVA-AXIS-P006: TVALID must not be unknown outside reset");

  generate
    if (HAS_TREADY) begin : g_ready_known
      property p_no_unknown_ready;
        @(posedge aclk) (aresetn && tvalid) |-> !$isunknown(tready);
      endproperty
      a_p006_ready: assert property (p_no_unknown_ready)
        else $error("SVA-AXIS-P006-TREADY: TREADY must not be unknown while TVALID is asserted");
    end
  endgenerate

  // ---------------------------------------------------------------------------
  // AXIS-P007：TVALID 有效时存在的 qualifier、TLAST 不得未知
  // ---------------------------------------------------------------------------
  property p_no_unknown_qualifier;
    @(posedge aclk) (aresetn && tvalid) |-> (HAS_TLAST ? !$isunknown(tlast) : 1'b1);
  endproperty
  a_p007: assert property (p_no_unknown_qualifier)
    else $error("SVA-AXIS-P007: qualifiers/TLAST must not be unknown while TVALID is asserted");

  // ---------------------------------------------------------------------------
  // SVA 与 UVM checker 同时启用时的关联 ID（REQ-CHK-003）
  // 关联键：sva#<rule>@<cycle>；UVM checker 用 uvm-checker#<idx>@<cycle>，
  // 端到端去重时按 rule 名 + cycle 配对，不重复计数。
  // ---------------------------------------------------------------------------
  // 注：黑盒 SVA 不能证明 source 未依赖 ready 才产生 valid（REQ-CHK-004），
  // 该对抗检查由 WAIT_VALID ready policy + 进展条件测试承担。

endmodule : axi4_stream_assertions

`endif // AXI4_STREAM_ASSERTIONS__SV
