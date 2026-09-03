// =============================================================================
// File Name   : apb_sva_bind.sv
// Description : SVA bind module（架构 §15 末尾说明的实现载体——
//               由 self_test tb 或用户 env 编译期执行）
// VLNV        : aixsilicon:vip:apb:1.0.0
// =============================================================================

`ifndef APB_SVA_BIND__SV
`define APB_SVA_BIND__SV

// 用法（tb 顶层）：
//   bind apb_if apb_protocol_sva #(
//     .HAS_PSTRB(HAS_PSTRB), .HAS_PPROT(HAS_PPROT), .HAS_CHECK(HAS_CHECK)
//   ) u_apb_sva (.*);
//
// 说明：
// - bind 参数取自被 bind 的 apb_if 实例参数（elaboration-time，ADR-0）；
// - runtime 开关经 vif.sva_enable（interface 内 logic，env/test 可拉低）；
// - 该文件仅提供使用说明与可选的默认 bind 模板，不产生编译副作用。

`endif // APB_SVA_BIND__SV
