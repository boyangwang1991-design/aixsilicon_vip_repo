// =============================================================================
// File Name   : axi4_stream_dut_fixtures.sv
// Description : axi4_stream VIP Self Test DUT fixtures（参考行为可人工审查）
// 依据        : docs/requirement.md（REQ-VAL-002：直连/register slice/FIFO/
//               宽度变换/路由 fixture；oracle 不依赖被测 VIP 的规范化函数）
//
// 说明：
//   * 这些 fixture 是自验证用的小型 DUT，行为简单、可人工审查；
//     独立源文件，不 import axi4_stream_pkg，避免共享实现掩盖 VIP 自身缺陷。
//   * 参数化宽度/端口存在性；缺失端口按恒 0/恒 1 归一化（REQ-CFG-002）。
// =============================================================================

`ifndef AXI4_STREAM_DUT_FIXTURES__SV
`define AXI4_STREAM_DUT_FIXTURES__SV

// ---------------------------------------------------------------------------
// 1. Register slice（1 深度，功能透明）
// ---------------------------------------------------------------------------
module axis_fixture_reg_slice #(
  parameter int DATA_WIDTH = 64,
  parameter int KEEP_WIDTH = DATA_WIDTH/8,
  parameter bit HAS_KEEP   = 1'b1,
  parameter bit HAS_STRB   = 1'b0,
  parameter bit HAS_LAST   = 1'b1,
  parameter int USER_WIDTH = 0
) (
  input  logic                  aclk,
  input  logic                  aresetn,
  // slave (input) side
  input  logic [DATA_WIDTH-1:0] s_tdata,
  input  logic [KEEP_WIDTH-1:0] s_tkeep,
  input  logic [KEEP_WIDTH-1:0] s_tstrb,
  input  logic                  s_tlast,
  input  logic [USER_WIDTH > 0 ? USER_WIDTH : 1:0] s_tuser,
  input  logic                  s_tvalid,
  output logic                  s_tready,
  // master (output) side
  output logic [DATA_WIDTH-1:0] m_tdata,
  output logic [KEEP_WIDTH-1:0] m_tkeep,
  output logic [KEEP_WIDTH-1:0] m_tstrb,
  output logic                  m_tlast,
  output logic [USER_WIDTH > 0 ? USER_WIDTH : 1:0] m_tuser,
  output logic                  m_tvalid,
  input  logic                  m_tready
);
  localparam int UW = (USER_WIDTH > 0) ? USER_WIDTH : 1;

  logic [DATA_WIDTH-1:0] r_data;
  logic [KEEP_WIDTH-1:0] r_keep;
  logic [KEEP_WIDTH-1:0] r_strb;
  logic                  r_last;
  logic [UW-1:0]         r_user;
  logic                  r_valid;

  assign m_tdata  = r_data;
  assign m_tkeep  = HAS_KEEP ? r_keep : {KEEP_WIDTH{1'b1}};
  assign m_tstrb  = HAS_STRB ? r_strb : m_tkeep;
  assign m_tlast  = HAS_LAST ? r_last : 1'b0;
  assign m_tuser  = r_user;
  assign m_tvalid = r_valid;
  assign s_tready = !r_valid || m_tready;

  always_ff @(posedge aclk) begin
    if (!aresetn) begin
      r_valid <= 1'b0;
      r_data  <= '0;
      r_keep  <= '0;
      r_strb  <= '0;
      r_last  <= 1'b0;
      r_user  <= '0;
    end else if (s_tvalid && s_tready) begin
      r_data  <= s_tdata;
      r_keep  <= s_tkeep;
      r_strb  <= s_tstrb;
      r_last  <= s_tlast;
      r_user  <= s_tuser;
      r_valid <= 1'b1;
    end else if (r_valid && m_tready) begin
      r_valid <= 1'b0;
    end
  end
endmodule

// ---------------------------------------------------------------------------
// 2. Synchronous FIFO（深度可配置；透明保序）
// ---------------------------------------------------------------------------
module axis_fixture_sync_fifo #(
  parameter int DATA_WIDTH = 64,
  parameter int KEEP_WIDTH = DATA_WIDTH/8,
  parameter int USER_WIDTH = 0,
  parameter int DEPTH      = 4
) (
  input  logic                  aclk,
  input  logic                  aresetn,
  input  logic [DATA_WIDTH-1:0] s_tdata,
  input  logic [KEEP_WIDTH-1:0] s_tkeep,
  input  logic [KEEP_WIDTH-1:0] s_tstrb,
  input  logic                  s_tlast,
  input  logic                  s_tvalid,
  output logic                  s_tready,
  output logic [DATA_WIDTH-1:0] m_tdata,
  output logic [KEEP_WIDTH-1:0] m_tkeep,
  output logic [KEEP_WIDTH-1:0] m_tstrb,
  output logic                  m_tlast,
  output logic                  m_tvalid,
  input  logic                  m_tready
);
  localparam int PW = $clog2(DEPTH) + 1;

  logic [DATA_WIDTH-1:0] mem_data [0:DEPTH-1];
  logic [KEEP_WIDTH-1:0] mem_keep [0:DEPTH-1];
  logic [KEEP_WIDTH-1:0] mem_strb [0:DEPTH-1];
  logic                  mem_last [0:DEPTH-1];
  logic [PW-1:0]         wr_ptr, rd_ptr;
  logic                  full, empty;
  logic                  wr_en, rd_en;

  assign full   = (wr_ptr - rd_ptr) == PW'(DEPTH);
  assign empty  = (wr_ptr == rd_ptr);
  assign s_tready = !full;
  assign m_tvalid = !empty;
  assign m_tdata  = mem_data[rd_ptr[PW-2:0]];
  assign m_tkeep  = mem_keep[rd_ptr[PW-2:0]];
  assign m_tstrb  = mem_strb[rd_ptr[PW-2:0]];
  assign m_tlast  = mem_last[rd_ptr[PW-2:0]];
  assign wr_en    = s_tvalid && s_tready;
  assign rd_en    = m_tvalid && m_tready;

  always_ff @(posedge aclk) begin
    if (!aresetn) begin
      wr_ptr <= '0;
      rd_ptr <= '0;
    end else begin
      if (wr_en) begin
        mem_data[wr_ptr[PW-2:0]] <= s_tdata;
        mem_keep[wr_ptr[PW-2:0]] <= s_tkeep;
        mem_strb[wr_ptr[PW-2:0]] <= s_tstrb;
        mem_last[wr_ptr[PW-2:0]] <= s_tlast;
        wr_ptr <= wr_ptr + 1'b1;
      end
      if (rd_en) rd_ptr <= rd_ptr + 1'b1;
    end
  end
endmodule

// ---------------------------------------------------------------------------
// 3. Width converter（32 -> 64，2 拍合并为 1 拍；仅 DATA 语义）
//    变换后的输出使用紧密排列 keep/strb；比较应使用 LOGICAL_STREAM。
// ---------------------------------------------------------------------------
module axis_fixture_width_up #(
  parameter int IN_WIDTH  = 32,
  parameter int OUT_WIDTH = 64
) (
  input  logic                 aclk,
  input  logic                 aresetn,
  input  logic [IN_WIDTH-1:0]  s_tdata,
  input  logic [IN_WIDTH/8-1:0] s_tkeep,
  input  logic [IN_WIDTH/8-1:0] s_tstrb,
  input  logic                 s_tlast,
  input  logic                 s_tvalid,
  output logic                 s_tready,
  output logic [OUT_WIDTH-1:0] m_tdata,
  output logic [OUT_WIDTH/8-1:0] m_tkeep,
  output logic [OUT_WIDTH/8-1:0] m_tstrb,
  output logic                 m_tlast,
  output logic                 m_tvalid,
  input  logic                 m_tready
);
  localparam int RATIO = OUT_WIDTH / IN_WIDTH;
  localparam int IB    = IN_WIDTH / 8;
  localparam int OB    = OUT_WIDTH / 8;

  logic [OUT_WIDTH-1:0]   acc_data;
  logic [OUT_WIDTH/8-1:0] acc_keep;
  logic [OUT_WIDTH/8-1:0] acc_strb;
  logic                   acc_last;
  logic [15:0]            acc_count;
  logic                   out_valid;
  logic [OUT_WIDTH-1:0]   out_data;
  logic [OUT_WIDTH/8-1:0] out_keep;
  logic [OUT_WIDTH/8-1:0] out_strb;
  logic                   out_last;

  assign m_tdata  = out_data;
  assign m_tkeep  = out_keep;
  assign m_tstrb  = out_strb;
  assign m_tlast  = out_last;
  assign m_tvalid = out_valid;
  assign s_tready = !out_valid;

  always_ff @(posedge aclk) begin
    if (!aresetn) begin
      acc_count <= '0;
      acc_data  <= '0;
      acc_keep  <= '0;
      acc_strb  <= '0;
      acc_last  <= 1'b0;
      out_valid <= 1'b0;
    end else begin
      if (s_tvalid && s_tready) begin
        acc_data[acc_count*IN_WIDTH +: IN_WIDTH] <= s_tdata;
        acc_keep[acc_count*IB +: IB]             <= s_tkeep;
        acc_strb[acc_count*IB +: IB]             <= s_tstrb;
        if (acc_count == RATIO-1 || s_tlast) begin
          out_data  <= {acc_data[OUT_WIDTH-1:IN_WIDTH], s_tdata};
          out_keep  <= {acc_keep[OB-1:IB], s_tkeep};
          out_strb  <= {acc_strb[OB-1:IB], s_tstrb};
          out_last  <= s_tlast;
          out_valid <= 1'b1;
          acc_count <= '0;
        end else begin
          acc_count <= acc_count + 1'b1;
        end
      end else if (out_valid && m_tready) begin
        out_valid <= 1'b0;
      end
    end
  end
endmodule

// ---------------------------------------------------------------------------
// 4. Router（1 输入 -> 2 输出，按 tdest[0] 选择；显式路由合同）
// ---------------------------------------------------------------------------
module axis_fixture_router #(
  parameter int DATA_WIDTH = 64,
  parameter int KEEP_WIDTH = DATA_WIDTH/8
) (
  input  logic                  aclk,
  input  logic                  aresetn,
  input  logic [DATA_WIDTH-1:0] s_tdata,
  input  logic [KEEP_WIDTH-1:0] s_tkeep,
  input  logic [KEEP_WIDTH-1:0] s_tstrb,
  input  logic                  s_tlast,
  input  logic [1:0]            s_tdest,
  input  logic                  s_tvalid,
  output logic                  s_tready,
  output logic [DATA_WIDTH-1:0] m0_tdata,
  output logic [KEEP_WIDTH-1:0] m0_tkeep,
  output logic [KEEP_WIDTH-1:0] m0_tstrb,
  output logic                  m0_tlast,
  output logic                  m0_tvalid,
  input  logic                  m0_tready,
  output logic [DATA_WIDTH-1:0] m1_tdata,
  output logic [KEEP_WIDTH-1:0] m1_tkeep,
  output logic [KEEP_WIDTH-1:0] m1_tstrb,
  output logic                  m1_tlast,
  output logic                  m1_tvalid,
  input  logic                  m1_tready
);
  wire sel = s_tdest[0];

  assign s_tready  = sel ? m1_tready : m0_tready;

  assign m0_tdata  = s_tdata;
  assign m0_tkeep  = s_tkeep;
  assign m0_tstrb  = s_tstrb;
  assign m0_tlast  = s_tlast;
  assign m0_tvalid = s_tvalid && !sel;

  assign m1_tdata  = s_tdata;
  assign m1_tkeep  = s_tkeep;
  assign m1_tstrb  = s_tstrb;
  assign m1_tlast  = s_tlast;
  assign m1_tvalid = s_tvalid && sel;

  // 引用 aclk/aresetn 以避免未使用告警（本 fixture 组合逻辑，无内部状态）
  logic unused_ok;
  assign unused_ok = aclk ^ aresetn;
endmodule

// ---------------------------------------------------------------------------
// 4b. 异步 FIFO（CDC）：双时钟 + 双复位（REQ-RST-005 / REQ-PERF-003）
//     写侧 aclk/aresetn，读侧 bclk/bresetn；灰色码指针跨域同步。
//     用于验证数据完整性（不宣称证明亚稳态安全，见 requirement §1.2 CDC 边界）。
// ---------------------------------------------------------------------------
module axis_fixture_async_fifo #(
  parameter int DATA_WIDTH = 64,
  parameter int KEEP_WIDTH = DATA_WIDTH/8,
  parameter int DEPTH      = 8
) (
  // write domain
  input  logic                  aclk,
  input  logic                  aresetn,
  input  logic [DATA_WIDTH-1:0] s_tdata,
  input  logic [KEEP_WIDTH-1:0] s_tkeep,
  input  logic [KEEP_WIDTH-1:0] s_tstrb,
  input  logic                  s_tlast,
  input  logic                  s_tvalid,
  output logic                  s_tready,
  // read domain
  input  logic                  bclk,
  input  logic                  bresetn,
  output logic [DATA_WIDTH-1:0] m_tdata,
  output logic [KEEP_WIDTH-1:0] m_tkeep,
  output logic [KEEP_WIDTH-1:0] m_tstrb,
  output logic                  m_tlast,
  output logic [DATA_WIDTH-1:0] m_tlast_dup,
  output logic                  m_tvalid,
  input  logic                  m_tready
);
  localparam int PW = $clog2(DEPTH) + 1;

  logic [DATA_WIDTH-1:0] mem_data [0:DEPTH-1];
  logic [KEEP_WIDTH-1:0] mem_keep [0:DEPTH-1];
  logic [KEEP_WIDTH-1:0] mem_strb [0:DEPTH-1];
  logic                  mem_last [0:DEPTH-1];

  logic [PW-1:0] wbin, wgray, rbin, rgray;
  logic [PW-1:0] wgray_s1, wgray_s2, rgray_s1, rgray_s2;
  logic          wfull, rempty;

  // 二进制 <-> 灰码
  function automatic logic [PW-1:0] bin2gray(input logic [PW-1:0] b);
    return b ^ (b >> 1);
  endfunction

  // 写域
  always_ff @(posedge aclk) begin
    if (!aresetn) begin
      wbin <= '0; wgray <= '0;
    end else if (s_tvalid && s_tready) begin
      mem_data[wbin[PW-2:0]] <= s_tdata;
      mem_keep[wbin[PW-2:0]] <= s_tkeep;
      mem_strb[wbin[PW-2:0]] <= s_tstrb;
      mem_last[wbin[PW-2:0]] <= s_tlast;
      wbin  <= wbin + 1'b1;
      wgray <= bin2gray(wbin + 1'b1);
    end
  end
  // 读域指针同步到写域
  always_ff @(posedge aclk) begin
    if (!aresetn) begin rgray_s1 <= '0; rgray_s2 <= '0; end
    else begin rgray_s1 <= rgray; rgray_s2 <= rgray_s1; end
  end
  assign wfull  = (wgray == {~rgray_s2[PW-1:PW-2], rgray_s2[PW-3:0]});
  assign s_tready = !wfull;

  // 读域
  always_ff @(posedge bclk) begin
    if (!bresetn) begin
      rbin <= '0; rgray <= '0;
    end else if (m_tvalid && m_tready) begin
      rbin  <= rbin + 1'b1;
      rgray <= bin2gray(rbin + 1'b1);
    end
  end
  always_ff @(posedge bclk) begin
    if (!bresetn) begin wgray_s1 <= '0; wgray_s2 <= '0; end
    else begin wgray_s1 <= wgray; wgray_s2 <= wgray_s1; end
  end
  assign rempty = (rgray == wgray_s2);
  assign m_tvalid = !rempty;
  assign m_tdata  = mem_data[rbin[PW-2:0]];
  assign m_tkeep  = mem_keep[rbin[PW-2:0]];
  assign m_tstrb  = mem_strb[rbin[PW-2:0]];
  assign m_tlast  = mem_last[rbin[PW-2:0]];
  assign m_tlast_dup = mem_last[rbin[PW-2:0]];
endmodule

// ---------------------------------------------------------------------------
// 5. Fault fixture：直连 + 可配置故障（丢拍 / 重复 / 改数据 / 换路由）
//    用于 scoreboard 负向验证（REQ-ERR-001 表中“合法握手下丢 beat/重复/乱序”）
// ---------------------------------------------------------------------------
module axis_fixture_fault #(
  parameter int DATA_WIDTH = 64,
  parameter int KEEP_WIDTH = DATA_WIDTH/8
) (
  input  logic                  aclk,
  input  logic                  aresetn,
  input  logic                  inject_drop,      // 丢一拍
  input  logic                  inject_dup,       // 重复一拍
  input  logic                  inject_corrupt,   // 数据破坏
  input  logic [DATA_WIDTH-1:0] s_tdata,
  input  logic [KEEP_WIDTH-1:0] s_tkeep,
  input  logic [KEEP_WIDTH-1:0] s_tstrb,
  input  logic                  s_tlast,
  input  logic                  s_tvalid,
  output logic                  s_tready,
  output logic [DATA_WIDTH-1:0] m_tdata,
  output logic [KEEP_WIDTH-1:0] m_tkeep,
  output logic [KEEP_WIDTH-1:0] m_tstrb,
  output logic                  m_tlast,
  output logic                  m_tvalid,
  input  logic                  m_tready
);
  logic drop_done, dup_done, corrupt_done;

  assign s_tready = m_tready;
  assign m_tvalid = s_tvalid && !(inject_drop && !drop_done);
  assign m_tdata  = (inject_corrupt && !corrupt_done) ? ~s_tdata : s_tdata;
  assign m_tkeep  = s_tkeep;
  assign m_tstrb  = s_tstrb;
  assign m_tlast  = s_tlast;

  always_ff @(posedge aclk) begin
    if (!aresetn) begin
      drop_done <= 1'b0; dup_done <= 1'b0; corrupt_done <= 1'b0;
    end else begin
      if (s_tvalid && s_tready && inject_drop) drop_done <= 1'b1;
      if (s_tvalid && s_tready && inject_corrupt) corrupt_done <= 1'b1;
      if (m_tvalid && m_tready) dup_done <= 1'b1;
    end
  end
endmodule

`endif // AXI4_STREAM_DUT_FIXTURES__SV