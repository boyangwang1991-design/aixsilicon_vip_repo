// =============================================================================
// File Name   : axi4_if.sv
// Description : AXI4 / AXI4-Lite interface（完整信号集，对齐 HWIF IFC-AXI-001）
//               含 master/slave/monitor 时钟块 + modport。
//               必选：awlock/arlock、awregion/arregion；capability 保留：awatop/*user。
// VLNV        : aixsilicon:vip:axi4:1.0.0
// =============================================================================

`ifndef AXI4_IF__SV
`define AXI4_IF__SV

interface axi4_if #(
  parameter int ID_WIDTH      = 8,
  parameter int ADDRESS_WIDTH = 32,
  parameter int DATA_WIDTH    = 32,
  parameter int USER_WIDTH    = 1
) (
  input var aclk,
  input var areset_n
);

  import axi4_types_pkg::*;

  // ---------------------------------------------------------------------------
  // 测试控制（self_test 专项用）：抑制 slave 发 R（构造 R 响应超时窗口）
  // ---------------------------------------------------------------------------
  logic suppress_r = 1'b0;

  // ---------------------------------------------------------------------------
  // 写地址通道（AW）
  // ---------------------------------------------------------------------------
  logic                       awvalid;
  logic                       awready;
  logic [ID_WIDTH-1:0]        awid;
  logic [ADDRESS_WIDTH-1:0]   awaddr;
  axi4_burst_length           awlen;
  axi4_burst_size             awsize;
  axi4_burst_type             awburst;
  axi4_lock_type              awlock;
  axi4_write_cache            awcache;
  axi4_protection             awprot;
  axi4_qos                    awqos;
  axi4_region                 awregion;
  axi4_atop                   awatop;
  logic [USER_WIDTH-1:0]      awuser;

  // ---------------------------------------------------------------------------
  // 写数据通道（W）
  // ---------------------------------------------------------------------------
  logic                       wvalid;
  logic                       wready;
  logic [DATA_WIDTH-1:0]      wdata;
  logic [DATA_WIDTH/8-1:0]    wstrb;
  logic                       wlast;
  logic [USER_WIDTH-1:0]      wuser;

  // ---------------------------------------------------------------------------
  // 写响应通道（B）
  // ---------------------------------------------------------------------------
  logic                       bvalid;
  logic                       bready;
  logic [ID_WIDTH-1:0]        bid;
  axi4_response               bresp;
  logic [USER_WIDTH-1:0]      buser;

  // ---------------------------------------------------------------------------
  // 读地址通道（AR）
  // ---------------------------------------------------------------------------
  logic                       arvalid;
  logic                       arready;
  logic [ID_WIDTH-1:0]        arid;
  logic [ADDRESS_WIDTH-1:0]   araddr;
  axi4_burst_length           arlen;
  axi4_burst_size             arsize;
  axi4_burst_type             arburst;
  axi4_lock_type              arlock;
  axi4_read_cache             arcache;
  axi4_protection             arprot;
  axi4_qos                    arqos;
  axi4_region                 arregion;
  axi4_atop                   aratop;
  logic [USER_WIDTH-1:0]      aruser;

  // ---------------------------------------------------------------------------
  // 读数据通道（R）
  // ---------------------------------------------------------------------------
  logic                       rvalid;
  logic                       rready;
  logic [ID_WIDTH-1:0]        rid;
  logic [DATA_WIDTH-1:0]      rdata;
  axi4_response               rresp;
  logic                       rlast;
  logic [USER_WIDTH-1:0]      ruser;

  // ---------------------------------------------------------------------------
  // 时钟块（Master 视角：驱动 AW/W，接收 B/R）
  // ---------------------------------------------------------------------------
  clocking master_cb @(posedge aclk, negedge areset_n);
    default input #1step output #1;
    output awvalid, awid, awaddr, awlen, awsize, awburst, awlock, awcache, awprot, awqos, awregion, awatop, awuser;
    input  awready;
    output wvalid, wdata, wstrb, wlast, wuser;
    input  wready;
    input  bvalid, bid, bresp, buser;
    output bready;
    output arvalid, arid, araddr, arlen, arsize, arburst, arlock, arcache, arprot, arqos, arregion, aratop, aruser;
    input  arready;
    input  rvalid, rid, rdata, rresp, rlast, ruser;
    output rready;
  endclocking

  // ---------------------------------------------------------------------------
  // 时钟块（Slave 视角：接收 AW/W，驱动 B/R）
  // ---------------------------------------------------------------------------
  clocking slave_cb @(posedge aclk, negedge areset_n);
    default input #1step output #1;
    input  awvalid, awid, awaddr, awlen, awsize, awburst, awlock, awcache, awprot, awqos, awregion, awatop, awuser;
    output awready;
    input  wvalid, wdata, wstrb, wlast, wuser;
    output wready;
    output bvalid, bid, bresp, buser;
    input  bready;
    input  arvalid, arid, araddr, arlen, arsize, arburst, arlock, arcache, arprot, arqos, arregion, aratop, aruser;
    output arready;
    output rvalid, rid, rdata, rresp, rlast, ruser;
    input  rready;
  endclocking

  // ---------------------------------------------------------------------------
  // 时钟块（Monitor 视角：全部采样，不驱动）
  // ---------------------------------------------------------------------------
  clocking monitor_cb @(posedge aclk);
    default input #1step;
    input areset_n;
    input awvalid, awready, awid, awaddr, awlen, awsize, awburst, awlock, awcache, awprot, awqos, awregion, awatop, awuser;
    input wvalid, wready, wdata, wstrb, wlast, wuser;
    input bvalid, bready, bid, bresp, buser;
    input arvalid, arready, arid, araddr, arlen, arsize, arburst, arlock, arcache, arprot, arqos, arregion, aratop, aruser;
    input rvalid, rready, rid, rdata, rresp, rlast, ruser;
  endclocking

  // ---------------------------------------------------------------------------
  // Modports（角色视图）
  // ---------------------------------------------------------------------------
  modport master  (clocking master_cb);
  modport slave   (clocking slave_cb);
  modport monitor (clocking monitor_cb);

  // ---------------------------------------------------------------------------
  // 时钟块边沿事件（供 driver/monitor 同步；源自 tvip-axi）
  // ---------------------------------------------------------------------------
  event at_master_cb_edge;
  event at_slave_cb_edge;
  event at_monitor_cb_edge;

  always @(master_cb) begin
    ->at_master_cb_edge;
  end

  always @(slave_cb) begin
    ->at_slave_cb_edge;
  end

  always @(monitor_cb) begin
    ->at_monitor_cb_edge;
  end

endinterface : axi4_if

`endif // AXI4_IF__SV
