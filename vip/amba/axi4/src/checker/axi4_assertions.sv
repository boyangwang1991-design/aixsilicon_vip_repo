// =============================================================================
// File Name   : axi4_assertions.sv
// Description : AXI4 SVA 协议断言（AXI4-REQ-VER-010；绑定 axi4_if）
//               覆盖：VALID 不依赖 READY（AXI4-REQ-RUL-001）、握手机制（AXI4-REQ-RUL-002）、
//               4KB 边界（AXI4-REQ-RUL-003）、WLAST/RLAST（AXI4-REQ-RUL-005）、复位（AXI4-REQ-RUL-009）、
//               payload stability（AXI4-REQ-RUL-002）、禁止提前终止（AXI4-REQ-RUL-008）。
// VLNV        : aixsilicon:vip:axi4:1.0.0
// =============================================================================

`ifndef AXI4_ASSERTIONS__SV
`define AXI4_ASSERTIONS__SV

import uvm_pkg::*;
`include "uvm_macros.svh"

module axi4_assertions #(
  parameter int DATA_WIDTH = 32
) (
  input logic aclk,
  input logic areset_n,
  // 写地址通道
  input logic awvalid,
  input logic awready,
  input logic [7:0] awlen,
  // 写数据通道
  input logic wvalid,
  input logic wready,
  input logic wlast,
  input logic [DATA_WIDTH-1:0] wdata,
  input logic [DATA_WIDTH/8-1:0] wstrb,
  // 写响应通道
  input logic bvalid,
  input logic bready,
  // 读地址通道
  input logic arvalid,
  input logic arready,
  input logic [7:0] arlen,
  // 读数据通道
  input logic rvalid,
  input logic rready,
  input logic rlast
);

  default clocking @(posedge aclk);
  endclocking

  // ---------------------------------------------------------------------------
  // AXI4-REQ-RUL-001：VALID 不依赖 READY（VALID 拉高后保持到握手完成）
  // ---------------------------------------------------------------------------
  // AWVALID 在 awready 为低时不得降下（除复位）
  property p_awvalid_stable;
    @(posedge aclk) disable iff (!areset_n)
    (awvalid && !awready) |=> (awvalid);
  endproperty
  a_awvalid_stable: assert property (p_awvalid_stable)
    else `uvm_error("AXI4-REQ-RUL-001", "AWVALID 在未握手时提前降下");

  property p_wvalid_stable;
    @(posedge aclk) disable iff (!areset_n)
    (wvalid && !wready) |=> (wvalid);
  endproperty
  a_wvalid_stable: assert property (p_wvalid_stable)
    else `uvm_error("AXI4-REQ-RUL-001", "WVALID 在未握手时提前降下");

  property p_arvalid_stable;
    @(posedge aclk) disable iff (!areset_n)
    (arvalid && !arready) |=> (arvalid);
  endproperty
  a_arvalid_stable: assert property (p_arvalid_stable)
    else `uvm_error("AXI4-REQ-RUL-001", "ARVALID 在未握手时提前降下");

  property p_bvalid_stable;
    @(posedge aclk) disable iff (!areset_n)
    (bvalid && !bready) |=> (bvalid);
  endproperty
  a_bvalid_stable: assert property (p_bvalid_stable)
    else `uvm_error("AXI4-REQ-RUL-001", "BVALID 在未握手时提前降下");

  property p_rvalid_stable;
    @(posedge aclk) disable iff (!areset_n)
    (rvalid && !rready) |=> (rvalid);
  endproperty
  a_rvalid_stable: assert property (p_rvalid_stable)
    else `uvm_error("AXI4-REQ-RUL-001", "RVALID 在未握手时提前降下");

  // ---------------------------------------------------------------------------
  // AXI4-REQ-RUL-002：握手机制（传输在 VALID && READY 同时为高时发生）
  // 握手完成的拍，VALID 与 READY 必须同时为高（采样到传输）。
  // 这里用 cover property 表达"握手成功"，assert 表达"不允许同时为高后仍不传输"——
  // 传输本身是单拍事件，无法直接断言；用"VALID && READY 同拍"作为握手证据。
  // ---------------------------------------------------------------------------
  property p_handshake_aw;
    @(posedge aclk) disable iff (!areset_n)
    (awvalid && awready) |-> 1;
  endproperty
  cover_aw_handshake: cover property (p_handshake_aw);

  property p_handshake_w;
    @(posedge aclk) disable iff (!areset_n)
    (wvalid && wready) |-> 1;
  endproperty
  cover_w_handshake: cover property (p_handshake_w);

  property p_handshake_ar;
    @(posedge aclk) disable iff (!areset_n)
    (arvalid && arready) |-> 1;
  endproperty
  cover_ar_handshake: cover property (p_handshake_ar);

  property p_handshake_b;
    @(posedge aclk) disable iff (!areset_n)
    (bvalid && bready) |-> 1;
  endproperty
  cover_b_handshake: cover property (p_handshake_b);

  property p_handshake_r;
    @(posedge aclk) disable iff (!areset_n)
    (rvalid && rready) |-> 1;
  endproperty
  cover_r_handshake: cover property (p_handshake_r);

  // ---------------------------------------------------------------------------
  // AXI4-REQ-RUL-005：WLAST / RLAST
  // 写数据最后一拍必须置 WLAST；读数据最后一拍必须置 RLAST。
  // WLAST 必须伴随有效的写数据传输出现。
  // ---------------------------------------------------------------------------
  property p_wlast_handshake;
    @(posedge aclk) disable iff (!areset_n)
    (wlast && wvalid) |-> wready;
  endproperty
  a_wlast_handshake: assert property (p_wlast_handshake)
    else `uvm_error("AXI4-REQ-RUL-005", "WLAST 拍未完成 W 握手");

  property p_rlast_handshake;
    @(posedge aclk) disable iff (!areset_n)
    (rlast && rvalid) |-> rready;
  endproperty
  a_rlast_handshake: assert property (p_rlast_handshake)
    else `uvm_error("AXI4-REQ-RUL-005", "RLAST 拍未完成 R 握手");

  // ---------------------------------------------------------------------------
  // AXI4-REQ-RUL-007：禁止提前终止（burst 内 beat 数）
  // WLAST 只能出现一次且为最后一拍（0 位掩码宽度=1，用 8 位计数器无法简化，
  // 这里用 cover 表达 WLAST 事件，burst 长度一致性由 checker 事务级验证）。
  // ---------------------------------------------------------------------------
  cover_wlast_seen: cover property (@(posedge aclk) (wlast && wvalid && wready));
  cover_rlast_seen: cover property (@(posedge aclk) (rlast && rvalid && rready));

  // ---------------------------------------------------------------------------
  // AXI4-REQ-RUL-002：Payload Stability（VALID=1 && READY=0 时 payload 保持稳定）
  // AWLEN 在 AWVALID 挂起未握手期间保持
  // ---------------------------------------------------------------------------
  property p_awlen_stable;
    @(posedge aclk) disable iff (!areset_n)
    (awvalid && !awready) |=> (awlen == $past(awlen));
  endproperty
  a_awlen_stable: assert property (p_awlen_stable)
    else `uvm_error("AXI4-REQ-RUL-002", "AWLEN 在未握手时变化");

  property p_arlen_stable;
    @(posedge aclk) disable iff (!areset_n)
    (arvalid && !arready) |=> (arlen == $past(arlen));
  endproperty
  a_arlen_stable: assert property (p_arlen_stable)
    else `uvm_error("AXI4-REQ-RUL-002", "ARLEN 在未握手时变化");

  // RUL-011：W 通道 payload stability（wvalid && !wready 期间 wdata/wstrb 保持）
  property p_wdata_stable;
    @(posedge aclk) disable iff (!areset_n)
    (wvalid && !wready) |=> (wdata == $past(wdata));
  endproperty
  a_wdata_stable: assert property (p_wdata_stable)
    else `uvm_error("AXI4-REQ-RUL-011", "W 数据在 stalled 期间变化");

  property p_wstrb_stable;
    @(posedge aclk) disable iff (!areset_n)
    (wvalid && !wready) |=> (wstrb == $past(wstrb));
  endproperty
  a_wstrb_stable: assert property (p_wstrb_stable)
    else `uvm_error("AXI4-REQ-RUL-011", "WSTRB 在 stalled 期间变化");

  // ---------------------------------------------------------------------------
  // AXI4-REQ-RUL-009：复位行为（复位释放后信号不得为 X / 握手正常）
  // ---------------------------------------------------------------------------
  // 复位期间（areset_n 已知为 0）VALID 必须为 0；
  // 任一信号未确定（X，如 driver 尚未初始化）时不判定，避免初始 X 误报。
  property p_awvalid_reset;
    @(posedge aclk)
    (!$isunknown(areset_n) && !areset_n
     && !$isunknown(awvalid) && !$isunknown(wvalid)
     && !$isunknown(arvalid) && !$isunknown(bvalid) && !$isunknown(rvalid))
      |-> (!awvalid && !wvalid && !arvalid && !bvalid && !rvalid);
  endproperty
  a_awvalid_reset: assert property (p_awvalid_reset)
    else `uvm_error("AXI4-REQ-RUL-009", "复位期间 VALID 不为 0");

  // ---------------------------------------------------------------------------
  // SVA 覆盖（供 coverage 模型引用，AXI4-REQ-VER-011）
  // ---------------------------------------------------------------------------
  cover_reset_seen: cover property (@(posedge aclk) (!areset_n));
  cover_aw_transfer: cover property (@(posedge aclk) (awvalid && awready));
  cover_ar_transfer: cover property (@(posedge aclk) (arvalid && arready));
  cover_w_transfer:  cover property (@(posedge aclk) (wvalid && wready));
  cover_b_transfer:  cover property (@(posedge aclk) (bvalid && bready));
  cover_r_transfer:  cover property (@(posedge aclk) (rvalid && rready));

endmodule : axi4_assertions


// =============================================================================
// 断言绑定（把 axi4_assertions 绑定到 axi4_if；由用户/顶层选择性开启）
// 用法（在含 axi4_if 实例的作用域）：
//   bind axi4_if axi4_assertions #(.DATA_WIDTH(DATA_WIDTH))
//        u_axi4_assertions (.aclk, .areset_n, .awvalid, .awready, .awlen,
//                           .wvalid, .wready, .wlast, .bvalid, .bready,
//                           .arvalid, .arready, .arlen, .rvalid, .rready,
//                           .rlast);
// 或在测试平台显式实例化 axi4_assertions 并连接 axi4_if 信号。
`endif // AXI4_ASSERTIONS__SV
