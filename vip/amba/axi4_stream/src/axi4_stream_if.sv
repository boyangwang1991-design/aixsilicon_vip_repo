// =============================================================================
// File Name   : axi4_stream_if.sv
// Description : axi4_stream 参数化接口（信号 + clocking + modport + 存在性 adapter）
// 依据        : docs/requirement.md（REQ-CFG-001/002/005, REQ-PRO-003, REQ-INT-001）
//
// 设计说明：
//   * 每个 agent 对应一个时钟域与一个单向 AXI4-Stream 接口（REQ-SCP-004）。
//   * 缺省端口的物理占位宽度至少 1 bit，避免 [-1:0]（REQ-CFG-005）；
//     端口“是否存在”由 HAS_* 参数表达，行为与检查按存在性裁剪。
//   * 未存在的物理信号不得参加 X/stability 检查（REQ-CFG-002）。
//   * clocking 采用 input #1step 采样（采样边沿前的稳定值）与 output #0 驱动，
//     与 monitor 对同一边沿的解释保持一致，避免 blocking assignment race（REQ-INT-001）。
//
// HWIF 说明：公共 HWIF 若已提供 AXI4-Stream 契约，应以该契约为 SSOT；当前仓库
// HWIF 未提供该接口契约，本文件作为明确命名的 development binding 提供独立
// 测试用信号集合（详见 docs/architecture.md §6 与 docs/requirement.md §23）。
// =============================================================================

`ifndef AXI4_STREAM_IF__SV
`define AXI4_STREAM_IF__SV

interface axi4_stream_if #(
  parameter int DATA_WIDTH  = 64,
  parameter int ID_WIDTH    = 0,
  parameter int DEST_WIDTH  = 0,
  parameter int USER_WIDTH  = 0,
  parameter bit HAS_TDATA   = 1'b1,
  parameter bit HAS_TREADY  = 1'b1,
  parameter bit HAS_TKEEP   = 1'b1,
  parameter bit HAS_TSTRB   = 1'b0,
  parameter bit HAS_TLAST   = 1'b1
) (
  input logic aclk,
  input logic aresetn
);

  // 有效端口宽度：缺省端口保留 1 bit 占位（REQ-CFG-005）
  localparam int DATA_BITS = (DATA_WIDTH > 0) ? DATA_WIDTH : 1;
  localparam int BYTE_LANES = (DATA_WIDTH > 0) ? (DATA_WIDTH / 8) : 1;
  localparam int ID_BITS   = (ID_WIDTH   > 0) ? ID_WIDTH   : 1;
  localparam int DEST_BITS = (DEST_WIDTH > 0) ? DEST_WIDTH : 1;
  localparam int USER_BITS = (USER_WIDTH > 0) ? USER_WIDTH : 1;

  // ---------------------------------------------------------------------------
  // 协议信号（AXI4-Stream 传统信号集合，ARM IHI 0051A 基线）
  // ---------------------------------------------------------------------------
  logic [DATA_BITS-1:0] tdata;
  logic [BYTE_LANES-1:0] tkeep;
  logic [BYTE_LANES-1:0] tstrb;
  logic                 tlast;
  logic                 tvalid;
  logic                 tready;
  logic [ID_BITS-1:0]   tid;
  logic [DEST_BITS-1:0] tdest;
  logic [USER_BITS-1:0] tuser;

  // ---------------------------------------------------------------------------
  // 复位请求通道（REQ-RST-001）：流 agent 只“响应”复位，不拥有驱动权。
  // test policy 通过置位 reset_request 请求一次复位；顶层复位控制器负责在
  // aclk/bclk 上实际驱动 aresetn/bresetn（唯一驱动者）。
  // ---------------------------------------------------------------------------
  bit reset_request    = 1'b0;
  int reset_low_cycles = 4;

  // 存在性视图：供 monitor/checker 判定是否参与检查（REQ-CFG-002）
  function automatic bit exists_tdata();  return HAS_TDATA;  endfunction
  function automatic bit exists_tready(); return HAS_TREADY; endfunction
  function automatic bit exists_tkeep();  return HAS_TKEEP;  endfunction
  function automatic bit exists_tstrb();  return HAS_TSTRB;  endfunction
  function automatic bit exists_tlast();  return HAS_TLAST;  endfunction
  function automatic bit exists_tid();    return ID_WIDTH   > 0; endfunction
  function automatic bit exists_tdest();  return DEST_WIDTH > 0; endfunction
  function automatic bit exists_tuser();  return USER_WIDTH > 0; endfunction
  function automatic int  byte_lanes();   return BYTE_LANES; endfunction

  // ---------------------------------------------------------------------------
  // Clocking blocks
  //   drv_cb：driver 在采样边沿之后驱动下一周期的值（output #0）
  //   mon_cb：monitor/checker 采样采样边沿前已稳定的值（input #1step）
  // ---------------------------------------------------------------------------
  clocking drv_cb @(posedge aclk);
    default input #1step output #0;
    output tdata, tkeep, tstrb, tlast, tvalid, tid, tdest, tuser;
    input  tready;
  endclocking

  clocking mon_cb @(posedge aclk);
    default input #1step;
    input tdata, tkeep, tstrb, tlast, tvalid, tready, tid, tdest, tuser;
  endclocking

  // sink 只驱动 TREADY，并观察 TVALID 以形成背压决策（REQ-SNK-001）
  clocking ready_cb @(posedge aclk);
    default input #1step output #0;
    output tready;
    input  tvalid;
  endclocking

  // ---------------------------------------------------------------------------
  // Modports
  // ---------------------------------------------------------------------------
  modport source  (clocking drv_cb);
  modport sink    (clocking ready_cb);
  modport monitor (clocking mon_cb);
  modport vif     (clocking mon_cb);   // 观察/断言统一入口
  modport drv     (clocking drv_cb);   // 兼容别名

  // 复位有效性（高有效 aresetn=0 表示复位有效）
  function automatic bit in_reset(logic aresetn_val);
    return (aresetn_val === 1'b0);
  endfunction

endinterface : axi4_stream_if

`endif // AXI4_STREAM_IF__SV
