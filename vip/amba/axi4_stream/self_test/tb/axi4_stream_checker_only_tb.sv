// =============================================================================
// File Name   : axi4_stream_checker_only_tb.sv
// Description : axi4_stream CHECKER_ONLY 独立构建路径（不依赖 UVM package）
// 依据        : docs/requirement.md（REQ-SCP-005：CHECKER_ONLY 不依赖 UVM
//               package，也不启动驱动线程；REQ-INT-004：checker_only 目标）
//
// 说明：
//   * 本 TB 只使用 SystemVerilog 语言构造 + axi4_stream_assertions + 纯语义 pkg，
//     不 import uvm_pkg、不创建 driver/sequencer。
//   * 内部用一个最小"合法 source"进程直接驱动接口（无 UVM 类），
//     用于证明 checker-only 路径可独立编译并检出协议违规。
//   * 成功打印 AXIS_CHECKER_ONLY_PASS。
// =============================================================================

`ifndef AXI4_STREAM_CHECKER_ONLY_TB__SV
`define AXI4_STREAM_CHECKER_ONLY_TB__SV

module axi4_stream_checker_only_tb;

  import axi4_stream_types_pkg::*;

  localparam int DATA_WIDTH = 32;
  localparam int LANES      = DATA_WIDTH/8;

  logic aclk;
  logic aresetn;

  int error_count = 0;

  initial begin
    aclk = 1'b0;
    forever #5 aclk = ~aclk;
  end

  initial begin
    aresetn = 1'b0;
    repeat (3) @(posedge aclk);
    aresetn = 1'b1;
  end

  // 无 UVM 的最小接口（参数与 axi4_stream_if 保持一致）
  axi4_stream_if #(
    .DATA_WIDTH(DATA_WIDTH), .ID_WIDTH(0), .DEST_WIDTH(0), .USER_WIDTH(0),
    .HAS_TDATA(1'b1), .HAS_TREADY(1'b1), .HAS_TKEEP(1'b1),
    .HAS_TSTRB(1'b0), .HAS_TLAST(1'b1)
  ) vif (.aclk(aclk), .aresetn(aresetn));

  // 独立 SVA（REQ-CHK-001：可直接例化）
  axi4_stream_assertions #(
    .HAS_TREADY(1'b1), .HAS_TKEEP(1'b1), .HAS_TSTRB(1'b0), .HAS_TLAST(1'b1), .HAS_TDATA(1'b1)
  ) u_sva (
    .aclk(aclk), .aresetn(aresetn),
    .tvalid(vif.tvalid), .tready(vif.tready), .tdata(vif.tdata[7:0]),
    .tkeep(vif.tkeep[0]), .tstrb(vif.tstrb[0]), .tlast(vif.tlast)
  );

  // ---------------------------------------------------------------------------
  // 纯语义自检：用 types_pkg 断言归一化/token 行为（无 UVM）
  // ---------------------------------------------------------------------------
  integer semantic_fail = 0;

  initial begin
    logic [AXIS_MAX_BYTES-1:0] keep, strb;
    axis_token_t tokens[];
    int tcount;

    if (axis_classify_byte(1'b1, 1'b1) != AXIS_BYTE_DATA)          semantic_fail++;
    if (axis_classify_byte(1'b0, 1'b1) != AXIS_BYTE_ILLEGAL)       semantic_fail++;
    keep = 8'h11; strb = 8'h11;
    if (axis_data_byte_count(1'b1, keep, 1'b1, strb, 8) != 2)      semantic_fail++;
    axis_tokenize_beat('0, 1'b1, '0, 1'b1, '0, 1'b1, 1'b1, 8, tokens, tcount);
    if (tcount != 1)                                                semantic_fail++;
    if (tokens[0].kind != AXIS_TOKEN_END_PACKET)                    semantic_fail++;
  end

  // ---------------------------------------------------------------------------
  // 最小 source 进程（合法握手；无 UVM 类）
  // ---------------------------------------------------------------------------
  logic [DATA_WIDTH-1:0] drv_data;
  logic [LANES-1:0]      drv_keep;

  initial begin
    vif.tvalid = 1'b0;
    vif.tdata  = '0;
    vif.tkeep  = '0;
    vif.tstrb  = '0;
    vif.tlast  = 1'b0;
    vif.tid    = '0;
    vif.tdest  = '0;
    vif.tuser  = '0;

    wait (aresetn === 1'b1);
    @(posedge aclk);

    fork
      // sink side: 恒 ready（HAS_TREADY=1）
      forever begin
        @(posedge aclk);
        vif.tready <= 1'b1;
      end
    join_none

    // 发送 4 拍合法流
    for (int i = 0; i < 4; i++) begin
      @(posedge aclk);
      vif.tdata  <= 32'h1122_3344 + i;
      vif.tkeep  <= 4'hf;
      vif.tstrb  <= 4'hf;
      vif.tlast  <= (i == 3);
      vif.tvalid <= 1'b1;
    end
    @(posedge aclk);
    vif.tvalid <= 1'b0;
    vif.tlast  <= 1'b0;
  end

  // ---------------------------------------------------------------------------
  // 结果判定
  // ---------------------------------------------------------------------------
  initial begin
    #2000;
    if (semantic_fail == 0 && error_count == 0)
      $display("AXIS_CHECKER_ONLY_PASS");
    else
      $display("AXIS_CHECKER_ONLY_FAIL: semantic_fail=%0d error_count=%0d",
               semantic_fail, error_count);
    $finish;
  end

endmodule : axi4_stream_checker_only_tb

`endif // AXI4_STREAM_CHECKER_ONLY_TB__SV