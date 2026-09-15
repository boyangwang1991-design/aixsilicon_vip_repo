// =============================================================================
// File Name   : axi4_stream_smoke_tb.sv
// Description : axi4_stream VIP Self Test 顶层（source -> DUT -> sink）
//               例化两侧 interface、DUT fixture、配置 vif/cfg、启动 UVM
// 依据        : docs/requirement.md（REQ-VAL-001/002, REQ-SCP-004,
//               REQ-INT-001/002, REQ-INT-004）
//
// DUT 类型由 +DUT=dir|regslice|fifo|widthup|router 选择；默认 dir（直连）。
// =============================================================================

`ifndef AXI4_STREAM_SMOKE_TB__SV
`define AXI4_STREAM_SMOKE_TB__SV

module axi4_stream_smoke_tb;

  import uvm_pkg::*;
  import axi4_stream_pkg::*;
  `include "uvm_macros.svh"
  `include "axi4_stream_smoke_env.sv"
  `include "axi4_stream_tests.sv"

  // ---------------------------------------------------------------------------
  // 参数
  // ---------------------------------------------------------------------------
  localparam int DATA_WIDTH = 64;
  localparam int LANES      = DATA_WIDTH/8;
  localparam int ID_WIDTH   = 4;
  localparam int DEST_WIDTH = 2;
  localparam int USER_WIDTH = 8;

  string dut_kind = "dir";

  // ---------------------------------------------------------------------------
  // 时钟 / 复位（顶层专用 agent 拥有驱动权，REQ-RST-001）
  // ---------------------------------------------------------------------------
  logic aclk;
  logic aresetn;
  logic bclk;        // CDC 读侧独立时钟（REQ-RST-005）
  logic bresetn;

  initial begin
    aclk = 1'b0;
    forever #5 aclk = ~aclk;   // 100MHz
  end

  initial begin
    bclk = 1'b0;
    forever #7 bclk = ~bclk;   // ~71MHz，异频异相
  end

  // ---------------------------------------------------------------------------
  // 接口实例：source 侧与 sink 侧各一个（REQ-SCP-004）
  // ---------------------------------------------------------------------------
  axi4_stream_if #(
    .DATA_WIDTH(DATA_WIDTH), .ID_WIDTH(ID_WIDTH), .DEST_WIDTH(DEST_WIDTH),
    .USER_WIDTH(USER_WIDTH), .HAS_TDATA(1'b1), .HAS_TREADY(1'b1),
    .HAS_TKEEP(1'b1), .HAS_TSTRB(1'b1), .HAS_TLAST(1'b1)
  ) src_vif (.aclk(aclk), .aresetn(aresetn));

  // 接收侧时钟/复位：DUT 为组合/同步路径时用 aclk（同域）；
  // DUT=cdc 时用 bclk/bresetn（异步 FIFO 读侧，REQ-RST-005）。
  logic snk_clk;
  logic snk_rstn;

  axi4_stream_if #(
    .DATA_WIDTH(DATA_WIDTH), .ID_WIDTH(ID_WIDTH), .DEST_WIDTH(DEST_WIDTH),
    .USER_WIDTH(USER_WIDTH), .HAS_TDATA(1'b1), .HAS_TREADY(1'b1),
    .HAS_TKEEP(1'b1), .HAS_TSTRB(1'b1), .HAS_TLAST(1'b1)
  ) snk_vif (.aclk(snk_clk), .aresetn(snk_rstn));

  // ---------------------------------------------------------------------------
  // DUT
  // ---------------------------------------------------------------------------
  logic snk_tready_int;

  // 直连路径（dir / fifo / router 的默认）
  logic [DATA_WIDTH-1:0] dut_tdata;
  logic [LANES-1:0]      dut_tkeep;
  logic [LANES-1:0]      dut_tstrb;
  logic                  dut_tlast;
  logic                  dut_tvalid;
  logic                  dut_tready;

  // DUT 选择：+DUT=regslice（默认） | cdc（异步 FIFO）
  bit use_cdc = 1'b0;

  // 源侧 DUT：register slice（1 深度，透明）
  axis_fixture_reg_slice #(
    .DATA_WIDTH(DATA_WIDTH), .HAS_KEEP(1'b1), .HAS_STRB(1'b1), .HAS_LAST(1'b1),
    .USER_WIDTH(USER_WIDTH)
  ) u_reg_slice (
    .aclk(aclk), .aresetn(aresetn),
    .s_tdata(src_vif.tdata), .s_tkeep(src_vif.tkeep), .s_tstrb(src_vif.tstrb),
    .s_tlast(src_vif.tlast), .s_tuser(src_vif.tuser),
    .s_tvalid(src_vif.tvalid), .s_tready(dut_s_ready),
    .m_tdata(dut_tdata), .m_tkeep(dut_tkeep), .m_tstrb(dut_tstrb),
    .m_tlast(dut_tlast), .m_tuser(), .m_tvalid(dut_tvalid), .m_tready(dut_tready)
  );
  logic dut_s_ready;

  // CDC 路径：异步 FIFO（aclk -> bclk，双复位）。仅在 +DUT=cdc 时使用；
  // 非 CDC 模式下 reset 输入被拉高以保持 quiescent。
  logic [DATA_WIDTH-1:0] cdc_tdata;
  logic [LANES-1:0]      cdc_tkeep;
  logic [LANES-1:0]      cdc_tstrb;
  logic                  cdc_tlast;
  logic                  cdc_tvalid;
  logic                  cdc_tready;
  logic                  cdc_aresetn_i;
  logic                  cdc_bresetn_i;

  axis_fixture_async_fifo #(
    .DATA_WIDTH(DATA_WIDTH), .KEEP_WIDTH(LANES), .DEPTH(8)
  ) u_async_fifo (
    .aclk(aclk), .aresetn(cdc_aresetn_i),
    .s_tdata(src_vif.tdata), .s_tkeep(src_vif.tkeep), .s_tstrb(src_vif.tstrb),
    .s_tlast(src_vif.tlast), .s_tvalid(src_vif.tvalid), .s_tready(cdc_s_ready),
    .bclk(bclk), .bresetn(cdc_bresetn_i),
    .m_tdata(cdc_tdata), .m_tkeep(cdc_tkeep), .m_tstrb(cdc_tstrb),
    .m_tlast(cdc_tlast), .m_tlast_dup(),
    .m_tvalid(cdc_tvalid), .m_tready(cdc_tready)
  );
  logic cdc_s_ready;
  assign snk_clk  = use_cdc ? bclk : aclk;
  assign snk_rstn = use_cdc ? bresetn : aresetn;
  assign cdc_aresetn_i = use_cdc ? aresetn : 1'b1;
  assign cdc_bresetn_i = use_cdc ? bresetn : 1'b1;

  // 输出选择（源侧 ready 由被选 DUT 提供；src_vif.tready 只能有一个驱动源）
  assign src_vif.tready = use_cdc ? cdc_s_ready : dut_s_ready;
  assign snk_vif.tdata  = use_cdc ? cdc_tdata  : dut_tdata;
  assign snk_vif.tkeep  = use_cdc ? cdc_tkeep  : dut_tkeep;
  assign snk_vif.tstrb  = use_cdc ? cdc_tstrb  : dut_tstrb;
  assign snk_vif.tlast  = use_cdc ? cdc_tlast  : dut_tlast;
  assign snk_vif.tvalid = use_cdc ? cdc_tvalid : dut_tvalid;
  assign cdc_tready     = snk_vif.tready;
  assign dut_tready     = snk_vif.tready;
  // TID/TDEST 直通（fixture 不搬运侧带；透明语义下由 TB 旁路）
  assign snk_vif.tid    = src_vif.tid;
  assign snk_vif.tdest  = src_vif.tdest;
  assign snk_vif.tuser  = src_vif.tuser;

  // ---------------------------------------------------------------------------
  // 独立 SVA 绑定（REQ-CHK-001：可 bind，也可直接例化）
  // 直接例化在 source 侧接口的时钟/复位上，覆盖 P001/P002/P003/P004/P005/P006/P007。
  // ---------------------------------------------------------------------------
  axi4_stream_assertions #(
    .HAS_TREADY(1'b1), .HAS_TKEEP(1'b1), .HAS_TSTRB(1'b1), .HAS_TLAST(1'b1), .HAS_TDATA(1'b1)
  ) u_src_sva (
    .aclk(aclk), .aresetn(aresetn),
    .tvalid(src_vif.tvalid), .tready(src_vif.tready), .tdata(src_vif.tdata),
    .tkeep(src_vif.tkeep), .tstrb(src_vif.tstrb), .tlast(src_vif.tlast)
  );

  // ---------------------------------------------------------------------------
  // 复位序列
  // ---------------------------------------------------------------------------
  // 顶层复位控制器：唯一驱动 aresetn/bresetn 的进程（REQ-RST-001）。
  // 1) 上电复位；2) 之后响应 src_vif.reset_request 的按需复位（可重复多次）。
  initial begin
    aresetn = 1'b0;
    bresetn = 1'b0;
    repeat (5) @(posedge aclk);
    aresetn = 1'b1;
    repeat (5) @(posedge bclk);
    bresetn = 1'b1;

    forever begin
      @(posedge aclk);
      if (src_vif.reset_request) begin
        aresetn = 1'b0;
        bresetn = 1'b0;
        repeat ((src_vif.reset_low_cycles > 0) ? src_vif.reset_low_cycles : 1) @(posedge aclk);
        aresetn = 1'b1;
        repeat (2) @(posedge bclk);
        bresetn = 1'b1;
        // 等两个时钟域都稳定后再确认请求完成
        repeat (2) @(posedge aclk);
        repeat (2) @(posedge bclk);
        src_vif.reset_request = 1'b0;
      end
    end
  end

  // ---------------------------------------------------------------------------
  // UVM 配置与启动
  // ---------------------------------------------------------------------------
  axi4_stream_config src_cfg;
  axi4_stream_config snk_cfg;

  string cov_export_file = "";

  initial begin
    void'($value$plusargs("DUT=%s", dut_kind));
    void'($value$plusargs("AXIS_COV_FILE=%s", cov_export_file));
    use_cdc = (dut_kind == "cdc");

    src_cfg = axi4_stream_config::type_id::create("src_cfg");
    src_cfg.data_width = DATA_WIDTH;
    src_cfg.id_width   = ID_WIDTH;
    src_cfg.dest_width = DEST_WIDTH;
    src_cfg.user_width = USER_WIDTH;
    src_cfg.has_tkeep  = 1'b1;
    src_cfg.has_tstrb  = 1'b1;
    src_cfg.has_tlast  = 1'b1;
    src_cfg.role       = AXIS_ROLE_SOURCE;
    src_cfg.role_configured = 1'b1;
    src_cfg.packet_mode = AXIS_PKT_TLAST;
    src_cfg.packet_mode_configured = 1'b1;

    snk_cfg = axi4_stream_config::type_id::create("snk_cfg");
    snk_cfg.data_width = DATA_WIDTH;
    snk_cfg.id_width   = ID_WIDTH;
    snk_cfg.dest_width = DEST_WIDTH;
    snk_cfg.user_width = USER_WIDTH;
    snk_cfg.has_tkeep  = 1'b1;
    snk_cfg.has_tstrb  = 1'b1;
    snk_cfg.has_tlast  = 1'b1;
    snk_cfg.role       = AXIS_ROLE_SINK;
    snk_cfg.role_configured = 1'b1;
    snk_cfg.packet_mode = AXIS_PKT_TLAST;
    snk_cfg.packet_mode_configured = 1'b1;

    uvm_config_db#(virtual axi4_stream_if)::set(null, "uvm_test_top.env.src_agent", "vif", src_vif);
    uvm_config_db#(axi4_stream_config)::set(null, "uvm_test_top.env.src_agent", "cfg", src_cfg);

    uvm_config_db#(virtual axi4_stream_if)::set(null, "uvm_test_top.env.snk_agent", "vif", snk_vif);
    uvm_config_db#(axi4_stream_config)::set(null, "uvm_test_top.env.snk_agent", "cfg", snk_cfg);

    uvm_config_db#(virtual axi4_stream_if)::set(null, "uvm_test_top.env.*checker", "vif", src_vif);
    uvm_config_db#(virtual axi4_stream_if)::set(null, "uvm_test_top.env.snk_checker", "vif", snk_vif);

    // 覆盖率 bin 导出路径下发给 env（G4 证据）
    if (cov_export_file != "")
      uvm_config_db#(string)::set(null, "uvm_test_top.env", "cov_export_file", cov_export_file);

    run_test("axi4_stream_smoke_test");
  end

  // ---------------------------------------------------------------------------
  // 超时保护
  // ---------------------------------------------------------------------------
  initial begin
    #10_000_000;
    `uvm_error("SMOKE", "AXI4-STREAM SMOKE TIMEOUT")
    $finish;
  end

endmodule : axi4_stream_smoke_tb

`endif // AXI4_STREAM_SMOKE_TB__SV
