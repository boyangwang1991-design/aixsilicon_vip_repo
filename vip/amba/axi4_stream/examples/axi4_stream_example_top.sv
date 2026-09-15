// =============================================================================
// File Name   : axi4_stream_example_top.sv
// Description : axi4_stream VIP 集成示例（Source-DUT-Sink 双侧 + 端到端比较）
// 依据        : docs/requirement.md（REQ-INT-004：文档提供 Source-DUT、DUT-Sink、
//               两侧比较和 Passive 例子）；docs/user-guide.md §38
//
// 本示例展示四种典型接法的公共骨架：
//   1. Source agent -> DUT -> Sink agent（DUT 透明：EXACT_BEAT）
//   2. 仅 Source agent（DUT 只做接收）
//   3. 仅 Passive agent（旁路观测既有总线）
//   4. 双侧 monitor -> scoreboard（DUT 非透明：LOGICAL_STREAM）
// 由 +EXAMPLE=dir|source_only|passive|logical 选择；默认 dir。
//
// 注意：本示例使用 register slice fixture 作为被验 DUT 以便直接运行；
// 真实项目应实例化自己的 DUT 并按需选择 compare_mode。
// =============================================================================

`ifndef AXI4_STREAM_EXAMPLE_TOP__SV
`define AXI4_STREAM_EXAMPLE_TOP__SV

module axi4_stream_example_top;

  import uvm_pkg::*;
  import axi4_stream_pkg::*;
  `include "uvm_macros.svh"

  localparam int DATA_WIDTH = 64;
  localparam int LANES      = DATA_WIDTH/8;
  localparam int ID_WIDTH   = 4;
  localparam int DEST_WIDTH = 2;
  localparam int USER_WIDTH = 8;

  logic aclk;
  logic aresetn;

  string example_kind = "dir";

  initial begin
    aclk = 1'b0;
    forever #5 aclk = ~aclk;
  end

  initial begin
    aresetn = 1'b0;
    repeat (5) @(posedge aclk);
    aresetn = 1'b1;
  end

  // ---------------------------------------------------------------------------
  // 两个单向接口（每个接口一个时钟域、一个 agent，REQ-SCP-004）
  // ---------------------------------------------------------------------------
  axi4_stream_if #(
    .DATA_WIDTH(DATA_WIDTH), .ID_WIDTH(ID_WIDTH), .DEST_WIDTH(DEST_WIDTH),
    .USER_WIDTH(USER_WIDTH), .HAS_TDATA(1'b1), .HAS_TREADY(1'b1),
    .HAS_TKEEP(1'b1), .HAS_TSTRB(1'b0), .HAS_TLAST(1'b1)
  ) in_if (.aclk(aclk), .aresetn(aresetn));

  axi4_stream_if #(
    .DATA_WIDTH(DATA_WIDTH), .ID_WIDTH(ID_WIDTH), .DEST_WIDTH(DEST_WIDTH),
    .USER_WIDTH(USER_WIDTH), .HAS_TDATA(1'b1), .HAS_TREADY(1'b1),
    .HAS_TKEEP(1'b1), .HAS_TSTRB(1'b0), .HAS_TLAST(1'b1)
  ) out_if (.aclk(aclk), .aresetn(aresetn));

  // ---------------------------------------------------------------------------
  // 被验 DUT（示例用 register slice；替换为真实 DUT）
  // ---------------------------------------------------------------------------
  axis_fixture_reg_slice #(
    .DATA_WIDTH(DATA_WIDTH), .HAS_KEEP(1'b1), .HAS_STRB(1'b0), .HAS_LAST(1'b1),
    .USER_WIDTH(USER_WIDTH)
  ) u_dut (
    .aclk(aclk), .aresetn(aresetn),
    .s_tdata(in_if.tdata), .s_tkeep(in_if.tkeep), .s_tstrb(in_if.tstrb),
    .s_tlast(in_if.tlast), .s_tuser(in_if.tuser),
    .s_tvalid(in_if.tvalid), .s_tready(in_if.tready),
    .m_tdata(out_if.tdata), .m_tkeep(out_if.tkeep), .m_tstrb(out_if.tstrb),
    .m_tlast(out_if.tlast), .m_tuser(), .m_tvalid(out_if.tvalid), .m_tready(out_if.tready)
  );

  // 侧带直通（reg slice fixture 不搬运侧带；透明语义下由 TB 旁路）
  assign out_if.tid   = in_if.tid;
  assign out_if.tdest = in_if.tdest;
  assign out_if.tuser = in_if.tuser;

  // ---------------------------------------------------------------------------
  // 配置与启动
  // ---------------------------------------------------------------------------
  initial begin
    axi4_stream_config in_cfg, out_cfg;
    void'($value$plusargs("EXAMPLE=%s", example_kind));

    in_cfg = axi4_stream_config::type_id::create("in_cfg");
    in_cfg.data_width = DATA_WIDTH; in_cfg.id_width = ID_WIDTH;
    in_cfg.dest_width = DEST_WIDTH; in_cfg.user_width = USER_WIDTH;
    in_cfg.role = AXIS_ROLE_SOURCE; in_cfg.role_configured = 1'b1;
    in_cfg.packet_mode = AXIS_PKT_TLAST; in_cfg.packet_mode_configured = 1'b1;
    in_cfg.compare_mode = AXIS_CMP_EXACT_BEAT;

    out_cfg = axi4_stream_config::type_id::create("out_cfg");
    out_cfg.data_width = DATA_WIDTH; out_cfg.id_width = ID_WIDTH;
    out_cfg.dest_width = DEST_WIDTH; out_cfg.user_width = USER_WIDTH;
    out_cfg.role = AXIS_ROLE_SINK; out_cfg.role_configured = 1'b1;
    out_cfg.packet_mode = AXIS_PKT_TLAST; out_cfg.packet_mode_configured = 1'b1;

    if (example_kind == "logical") begin
      // 非透明 DUT（如宽度变换）：用逻辑流比较
      in_cfg.compare_mode = AXIS_CMP_LOGICAL_STREAM;
      in_cfg.width_ratio  = 2;
    end
    if (example_kind == "source_only")  out_cfg.role = AXIS_ROLE_SINK;
    if (example_kind == "passive") begin
      in_cfg.role = AXIS_ROLE_PASSIVE; in_cfg.role_configured = 1'b1;
    end

    uvm_config_db#(virtual axi4_stream_if)::set(null, "uvm_test_top.env.src_agent", "vif", in_if);
    uvm_config_db#(axi4_stream_config)::set(null, "uvm_test_top.env.src_agent", "cfg", in_cfg);
    uvm_config_db#(virtual axi4_stream_if)::set(null, "uvm_test_top.env.snk_agent", "vif", out_if);
    uvm_config_db#(axi4_stream_config)::set(null, "uvm_test_top.env.snk_agent", "cfg", out_cfg);
    uvm_config_db#(virtual axi4_stream_if)::set(null, "uvm_test_top.env.src_checker", "vif", in_if);
    uvm_config_db#(virtual axi4_stream_if)::set(null, "uvm_test_top.env.snk_checker", "vif", out_if);

    run_test("axi4_stream_example_test");
  end

  initial begin
    #5_000_000;
    `uvm_error("AXIS-EXAMPLE", "EXAMPLE TIMEOUT")
    $finish;
  end

endmodule : axi4_stream_example_top

`endif // AXI4_STREAM_EXAMPLE_TOP__SV
