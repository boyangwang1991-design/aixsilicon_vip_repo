// =============================================================================
// File Name   : apb_if.sv
// Description : APB interface（ADR-0/ADR-2 两层能力分离）
//               - elaboration-time：ADDR_WIDTH/DATA_WIDTH/HAS_*/USER_*_WIDTH 参数
//                 （HAS_* 用于 validate_interface_vs_config 一致性校验 + SVA generate）
//               - 可选信号线以参数化宽度恒存在（宽度 0 时 1 位占位恒 0，
//                 "语义不存在"由恒 0 + driver/monitor/checker 条件化表达；
//                 严格物理省略需 generate clocking——V1.0 采用通行做法，见 LIM-006）
//               - PADDRCHK 宽度 = ceil(ADDR_WIDTH/8)（CT-4/CFG-008）
// VLNV        : aixsilicon:vip:apb:1.0.0
// =============================================================================

`ifndef APB_IF__SV
`define APB_IF__SV

interface apb_if #(
  parameter int ADDR_WIDTH       = 32,
  parameter int DATA_WIDTH       = 32,   // ∈ {8,16,32}
  parameter bit HAS_PSTRB        = 1,    // APB4+（PSTRB）
  parameter bit HAS_PPROT        = 1,    // APB4+（PPROT）
  parameter int USER_REQ_WIDTH   = 0,    // 0 = PAUSER 语义不存在
  parameter int USER_DATA_WIDTH  = 0,    // 0 = PWUSER/PRUSER 语义不存在
  parameter int USER_RESP_WIDTH  = 0,    // 0 = PBUSER 语义不存在
  parameter bit HAS_PWAKEUP      = 0,    // Wakeup_Signal property
  parameter bit HAS_PNSE         = 0,    // RME_Support
  parameter bit HAS_CHECK        = 0,    // Check_Type != False（*CHK 族）
  parameter int NUM_SLAVES       = 1     // psel 总线宽度（monitor 观察）
) (
  input var logic pclk,
  input var logic presetn,
  input var logic check_enable                   // APB5 Check Enable（外部）
);

  import apb_types_pkg::*;

  localparam int STRB_WIDTH      = DATA_WIDTH/8;
  localparam int PADDRCHK_WIDTH  = (ADDR_WIDTH + 7) / 8;       // CT-4
  localparam int PWDATACHK_WIDTH = (DATA_WIDTH + 7) / 8;
  localparam int PSTRBCHK_WIDTH  = (STRB_WIDTH + 7) / 8;

  // 宽度参数化（0 → 1 位占位恒 0）
  localparam int UW_REQ   = (USER_REQ_WIDTH  > 0) ? USER_REQ_WIDTH  : 1;
  localparam int UW_DATA  = (USER_DATA_WIDTH > 0) ? USER_DATA_WIDTH : 1;
  localparam int UW_RESP  = (USER_RESP_WIDTH > 0) ? USER_RESP_WIDTH : 1;

  // ---------------------------------------------------------------------------
  // 测试控制（self_test 专项）：抑制 completer PREADY（超时窗口）
  // ---------------------------------------------------------------------------
  logic suppress_pready = 1'b0;

  // runtime 门（SVA 用；由 env/test 经 vif 赋值——ADR-0：generate 不依赖它）
  logic sva_enable = 1'b1;

  // ===========================================================================
  // APB3 必选信号（Y）。P3 修复：不再用声明初值 + initial 块驱动（VCS 视其为
  // procedural 驱动源，真实 RTL APB-master 结构驱动时报 ICPSD/ICPSD_INIT 编译
  // 失败）。改为纯声明，复位期 0 由 Requester driver / SVA（G1 RUL-008）保证；
  // 复位释放前 RTL master 输出的确定值由外部 reset 语义保证。
  // ===========================================================================
  logic [NUM_SLAVES-1:0]   psel;
  logic                    penable;
  logic [ADDR_WIDTH-1:0]   paddr;
  logic                    pwrite;
  logic [DATA_WIDTH-1:0]   pwdata;
  logic [DATA_WIDTH-1:0]   prdata;
  logic                    pready;    // OO-1：VIP 端口恒存在
  logic                    pslverr;   // OO-1

  // ===========================================================================
  // 可选信号（*_w 命名；能力关闭时 driver/monitor 恒 0——C-8 存在性语义）
  // ===========================================================================
  logic [STRB_WIDTH-1:0]   pstrb_w;
  apb_protection           pprot_w;
  logic [UW_REQ-1:0]       pauser_w;
  logic [UW_DATA-1:0]      pwuser_w;
  logic [UW_DATA-1:0]      pruser_w;
  logic [UW_RESP-1:0]      pbuser_w;
  logic                    pwakeup_w;
  logic                    pnse_w;

  // *CHK 族（HAS_CHECK=0 时恒 0）
  logic [PADDRCHK_WIDTH-1:0]  paddrchk_w;
  logic                       pctrlchk_w;
  logic [NUM_SLAVES-1:0]      pselchk_w;
  logic                       penablechk_w;
  logic [PWDATACHK_WIDTH-1:0] pwdatachk_w;
  logic [PSTRBCHK_WIDTH-1:0]  pstrbchk_w;
  logic                       preadychk_w;
  logic [PWDATACHK_WIDTH-1:0] prdatachk_w;
  logic                       pslverrchk_w;   // OC
  logic                       pwakeupchk_w;   // C：Check & Wakeup

  // ===========================================================================
  // 复位安全清零（可选信号专用）：P3 修复——必选信号（psel/penable/paddr/pwrite/
  // pwdata/prdata/pready/pslverr）被真实 RTL APB-master 结构驱动，带初值会触发
  // ICPSD/ICPSD_INIT，故改为纯声明；可选信号（pstrb_w/pprot_w/*user_w/pwakeup_w/
  // pnse_w/*chk_w）RTL 一般空接/不驱动，保留 initial 清零可消除无驱动 X
  // （否则 SVA 如 F1_read_strb_zero 对 X 判定失败）。
  // ===========================================================================
  initial begin
    pstrb_w     = '0;
    pprot_w     = '0;
    pauser_w    = '0;
    pwuser_w    = '0;
    pruser_w    = '0;
    pbuser_w    = '0;
    pwakeup_w   = 1'b0;
    pnse_w      = 1'b0;
    paddrchk_w  = '0;
    pctrlchk_w  = 1'b0;
    pselchk_w   = '0;
    penablechk_w= 1'b0;
    pwdatachk_w = '0;
    pstrbchk_w  = '0;
    preadychk_w = 1'b0;
    prdatachk_w = '0;
    pslverrchk_w= 1'b0;
    pwakeupchk_w= 1'b0;
  end

  // ===========================================================================
  // 时钟块（具体 skew 属 implementation，C-9；race-free 由 self_test 证明）
  // ===========================================================================
  clocking master_cb @(posedge pclk, negedge presetn);
    default input #1step output #1;
    output psel, penable, paddr, pwrite, pwdata;
    output pstrb_w, pprot_w, pauser_w, pwuser_w, pwakeup_w, pnse_w;
    input  pready, pslverr, prdata, pruser_w, pbuser_w;
  endclocking

  clocking slave_cb @(posedge pclk, negedge presetn);
    default input #1step output #1;
    input  psel, penable, paddr, pwrite, pwdata;
    input  pstrb_w, pprot_w, pauser_w, pwuser_w, pwakeup_w, pnse_w;
    output pready, pslverr, prdata, pruser_w, pbuser_w;
  endclocking

  clocking monitor_cb @(posedge pclk);
    default input #1step;
    input presetn, check_enable;
    input psel, penable, paddr, pwrite, pwdata;
    input pready, pslverr, prdata;
    input pstrb_w, pprot_w, pauser_w, pwuser_w, pruser_w, pbuser_w;
    input pwakeup_w, pnse_w;
    input paddrchk_w, pctrlchk_w, pselchk_w, penablechk_w;
    input pwdatachk_w, pstrbchk_w, preadychk_w, prdatachk_w, pslverrchk_w, pwakeupchk_w;
  endclocking

  // ===========================================================================
  // Modports
  // ===========================================================================
  modport master  (clocking master_cb);
  modport slave   (clocking slave_cb);
  modport monitor (clocking monitor_cb);

  event clock_edge_event;
  always @(posedge pclk) -> clock_edge_event;

  // ===========================================================================
  // 组合 Helper（RUL-010 载体：completion 仅由三信号与定义）
  // ===========================================================================
  function automatic logic apb_transfer_done();
    return psel[0] && penable && pready;
  endfunction

  function automatic logic apb_setup_phase();
    return psel[0] && !penable;
  endfunction

  function automatic logic apb_access_phase();
    return psel[0] && penable;
  endfunction

  // ===========================================================================
  // SVA protocol checker（ADR-0/blocker②：generate-if 只依赖 elaboration
  // 参数 HAS_*；runtime 门 sva_enable；anti-overcheck：C2/E1 无强断言）
  // SVA 检出计数（FI tier 统计用；$error 动作内递增）
  // ===========================================================================
  int unsigned sva_hit_cnt [string];   // "RUL-001" → 检出次数

  generate
    // A1：SETUP 恰 1 拍且次拍进入 ACCESS（RUL-001）
    property p_setup_one_cycle;
      @(posedge pclk) disable iff (!presetn || !sva_enable)
        (psel[0] && !penable) |=> (psel[0] && penable);
    endproperty
    A1_setup_one_cycle: assert property (p_setup_one_cycle)
      else begin
        if (sva_hit_cnt.exists("RUL-001")) sva_hit_cnt["RUL-001"]++;
        else sva_hit_cnt["RUL-001"] = 1;
        $error("[RUL-001] SETUP must last exactly 1 cycle and proceed to ACCESS");
      end

    // A2：PENABLE 仅 ACCESS（RUL-002）
    // A2a：无 PSEL 的 PENABLE 禁止
    property p_penable_in_access;
      @(posedge pclk) disable iff (!presetn || !sva_enable)
        penable |-> psel[0];
    endproperty
    A2_penable_in_access: assert property (p_penable_in_access)
      else begin
        if (sva_hit_cnt.exists("RUL-002")) sva_hit_cnt["RUL-002"]++;
        else sva_hit_cnt["RUL-002"] = 1;
        $error("[RUL-002] PENABLE asserted without PSEL");
      end

    // A2b：PSEL 与 PENABLE 不得同拍起（跳过 SETUP 检出，FI-002）——
    //      合法序列 psel 先于 penable 一拍起；IDLE 直接 ACCESS 时
    //      (psel&&penable) 的 $rose 前拍 psel=0 → 检出
    property p_penable_after_setup;
      @(posedge pclk) disable iff (!presetn || !sva_enable)
        $rose(penable && psel[0]) |-> $past(psel[0] && !penable);
    endproperty
    A2b_penable_after_setup: assert property (p_penable_after_setup)
      else begin
        if (sva_hit_cnt.exists("RUL-002")) sva_hit_cnt["RUL-002"]++;
        else sva_hit_cnt["RUL-002"] = 1;
        $error("[RUL-002] PENABLE asserted without preceding SETUP phase");
      end

    // B1：wait 期 request 字段稳定（RUL-003）
    property p_addr_stable;
      @(posedge pclk) disable iff (!presetn || !sva_enable)
        (psel[0] && penable && !pready) |=> (psel[0] && $stable(paddr) && $stable(pwrite));
    endproperty
    B1_addr_stable: assert property (p_addr_stable)
      else begin
        if (sva_hit_cnt.exists("RUL-003")) sva_hit_cnt["RUL-003"]++;
        else sva_hit_cnt["RUL-003"] = 1;
        $error("[RUL-003] PADDR/PWRITE/PSEL must be stable during wait states");
      end

    // C1：completion 次拍 PENABLE 撤销（RUL-004）
    property p_completion_exit;
      @(posedge pclk) disable iff (!presetn || !sva_enable)
        (psel[0] && penable && pready) |=> !penable;
    endproperty
    C1_completion_exit: assert property (p_completion_exit)
      else begin
        if (sva_hit_cnt.exists("RUL-004")) sva_hit_cnt["RUL-004"]++;
        else sva_hit_cnt["RUL-004"] = 1;
        $error("[RUL-004] PENABLE must deassert after completion");
      end

    // G1：复位期 PSEL=0（RUL-008）
    property p_reset_idle;
      @(posedge pclk) disable iff (!sva_enable)
        !presetn |-> (!psel[0] && !penable);
    endproperty
    G1_reset_idle: assert property (p_reset_idle)
      else begin
        if (sva_hit_cnt.exists("RUL-008")) sva_hit_cnt["RUL-008"]++;
        else sva_hit_cnt["RUL-008"] = 1;
        $error("[RUL-008] PSEL/PENABLE must be 0 during reset");
      end

    // H1：PENABLE 无 PSEL 禁止（RUL-011 辅助）——与 A2 同表达式，
    //     由 A2 承载（disable iff 复位门一致），此处不再重复

    // 条件规则：HAS_PSTRB / HAS_PPROT（elaboration——blocker②）
    if (HAS_PSTRB) begin : g_sva_strb
      // B1-strb：wait 期 PSTRB 稳定
      property p_strb_stable;
        @(posedge pclk) disable iff (!presetn || !sva_enable)
          (psel[0] && penable && !pready) |=> $stable(pstrb_w);
      endproperty
      B1_strb_stable: assert property (p_strb_stable)
        else begin
          if (sva_hit_cnt.exists("RUL-003")) sva_hit_cnt["RUL-003"]++;
          else sva_hit_cnt["RUL-003"] = 1;
          $error("[RUL-003] PSTRB must be stable during wait states");
        end

      // F1：读传输 PSTRB==0（RUL-006）
      property p_read_strb_zero;
        @(posedge pclk) disable iff (!presetn || !sva_enable)
          (psel[0] && !pwrite) |-> (pstrb_w == '0);
      endproperty
      F1_read_strb_zero: assert property (p_read_strb_zero)
        else begin
          if (sva_hit_cnt.exists("RUL-006")) sva_hit_cnt["RUL-006"]++;
          else sva_hit_cnt["RUL-006"] = 1;
          $error("[RUL-006] PSTRB must be 0 for read transfers");
        end
    end

    if (HAS_PPROT) begin : g_sva_pprot
      // B1-pprot：wait 期 PPROT 稳定
      property p_pprot_stable;
        @(posedge pclk) disable iff (!presetn || !sva_enable)
          (psel[0] && penable && !pready) |=> $stable(pprot_w);
      endproperty
      B1_pprot_stable: assert property (p_pprot_stable)
        else begin
          if (sva_hit_cnt.exists("RUL-003")) sva_hit_cnt["RUL-003"]++;
          else sva_hit_cnt["RUL-003"] = 1;
          $error("[RUL-003] PPROT must be stable during wait states");
        end
    end

    // C2（RUL-010）/E1（RUL-005）：anti-overcheck——无强断言（UT17/UT18 验证）；
    // completion/PSLVERR 采样语义由 monitor 保证（apb_monitor.sv）。
  endgenerate

endinterface : apb_if

`endif // APB_IF__SV
