// =============================================================================
// File Name   : apb_types_pkg.sv
// Description : APB VIP 类型/枚举/helper（无 UVM 依赖，ADR-7/L1 unit test 复用）
//               参考 ARM IHI 0024E；能力正交（REQ §7）+ check_type（PRO-014）
// VLNV        : aixsilicon:vip:apb:1.0.0
// HWIF        : aixsilicon:hwif:apb（IFC-APB-001）—— 接口契约唯一来源
// =============================================================================

`ifndef APB_TYPES_PKG__SV
`define APB_TYPES_PKG__SV

// 最大位宽（实例化位宽由 apb_if 参数控制）
`define APB_MAX_ADDR_WIDTH  32
`define APB_MAX_DATA_WIDTH  32
`define APB_MAX_USER_WIDTH  128

package apb_types_pkg;

  // ---------------------------------------------------------------------------
  // 协议版本（APB3 ⊂ APB4 ⊂ APB5）
  // ---------------------------------------------------------------------------
  typedef enum int unsigned {
    APB3 = 3,
    APB4 = 4,
    APB5 = 5
  } apb_version_e;

  // ---------------------------------------------------------------------------
  // APB5 Interface Check 类型（REQ §2.3 CT：IHI 0024E Check_Type 仅两态）
  // ---------------------------------------------------------------------------
  typedef enum int unsigned {
    APB_CHECK_NONE                = 0,
    APB_CHECK_ODD_PARITY_BYTE_ALL = 1
  } apb_check_type_e;

  // ---------------------------------------------------------------------------
  // 传输方向 / 结果状态
  // ---------------------------------------------------------------------------
  typedef enum {
    APB_READ,
    APB_WRITE
  } apb_direction_e;

  typedef enum {
    APB_OK,       // PREADY=1, PSLVERR=0
    APB_ERROR,    // PREADY=1, PSLVERR=1
    APB_ABORTED   // PRESETn 中途复位
  } apb_status_e;

  // ---------------------------------------------------------------------------
  // Agent 模式（master = initiator，slave = target 为同义别名）
  // ---------------------------------------------------------------------------
  typedef enum {
    APB_ACTIVE_MASTER,
    APB_ACTIVE_SLAVE,
    APB_PASSIVE,
    APB_DISABLED
  } apb_agent_mode_e;

  // ---------------------------------------------------------------------------
  // PPROT：[0] privileged, [1] non-secure, [2] instruction
  // PNSE 与 PPROT[1] 组合出物理地址空间（CP-07）：
  //   PNSE=0,PPROT[1]=0 → Secure | 0,1 → Non-secure | 1,0 → Root | 1,1 → Realm
  // ---------------------------------------------------------------------------
  typedef struct packed {
    logic instruction_access;
    logic non_secure_access;
    logic privileged_access;
  } apb_protection;

  typedef enum int unsigned {
    APB_PAS_SECURE     = 0,
    APB_PAS_NON_SECURE = 1,
    APB_PAS_ROOT       = 2,
    APB_PAS_REALM      = 3
  } apb_pas_space_e;

  // ---------------------------------------------------------------------------
  // Completer 响应/错误模式（plan §8）
  // ---------------------------------------------------------------------------
  typedef enum {
    APB_ZERO_WAIT,
    APB_FIXED_WAIT,
    APB_RANDOM_WAIT,
    APB_SEQUENCE_CONTROLLED
  } apb_response_mode_e;

  typedef enum {
    APB_ERR_NEVER,
    APB_ERR_RANDOM,
    APB_ERR_ADDRESS_RANGE,
    APB_ERR_SEQUENCE_CONTROLLED
  } apb_error_mode_e;

  // ---------------------------------------------------------------------------
  // PWAKEUP 独立策略（ADR-11：always-valid 信号，不绑死 transfer phase）
  // ---------------------------------------------------------------------------
  typedef enum {
    APB_WAKEUP_FOLLOW_TRANSFER,   // 默认：transfer 期间 1
    APB_WAKEUP_MANUAL,            // 由 wakeup_level 字段直通
    APB_WAKEUP_SEQUENCE_CONTROLLED// 由 item.wakeup 直通
  } apb_wakeup_mode_e;

  // ---------------------------------------------------------------------------
  // Completer 地址段
  // ---------------------------------------------------------------------------
  typedef struct {
    logic [`APB_MAX_ADDR_WIDTH-1:0] base;
    logic [`APB_MAX_ADDR_WIDTH-1:0] limit;
    int unsigned                    wait_cycles;
    bit                             slverr;
  } apb_addr_region_s;

  // ---------------------------------------------------------------------------
  // Violation 严重级别（结构化输出）
  // ---------------------------------------------------------------------------
  typedef enum {
    APB_VIOL_INFO,
    APB_VIOL_WARN,
    APB_VIOL_ERROR,
    APB_VIOL_FATAL
  } apb_violation_severity_e;

  // ---------------------------------------------------------------------------
  // 相位模式（CP-08）
  // ---------------------------------------------------------------------------
  typedef enum {
    APB_PAT_IDLE_TO_TRANSFER,
    APB_PAT_BACK_TO_BACK,
    APB_PAT_WAIT_EXTENDED
  } apb_phase_pattern_e;

  // ---------------------------------------------------------------------------
  // Helper：等待分桶（CP-04）
  // ---------------------------------------------------------------------------
  function automatic int apb_wait_bucket(int unsigned cycles);
    if (cycles == 0)       return 0;
    else if (cycles == 1)  return 1;
    else if (cycles <= 4)  return 2;
    else if (cycles <= 15) return 3;
    else                   return 4;
  endfunction

  // Helper：对齐（TRN-004）
  function automatic bit apb_is_aligned(logic [`APB_MAX_ADDR_WIDTH-1:0] addr,
                                        int unsigned data_width);
    int unsigned n_bytes = (data_width < 8) ? 1 : data_width / 8;
    return (addr % n_bytes) == 0;
  endfunction

  // Helper：PSTRB 分类（CP-06）：0=none 1=full 2=single 3=multi-contig 4=sparse
  function automatic int apb_strb_class(logic [`APB_MAX_DATA_WIDTH/8-1:0] strb,
                                        int unsigned data_width);
    int unsigned n_bytes = (data_width < 8) ? 1 : data_width / 8;
    int unsigned cnt = 0;
    bit seen = 1'b0, gap = 1'b0, contig = 1'b1;
    for (int i = 0; i < n_bytes; i++) if (strb[i]) cnt++;
    if (cnt == 0)       return 0;
    if (cnt == n_bytes) return 1;
    for (int i = 0; i < n_bytes; i++) begin
      if (strb[i]) begin
        if (gap) contig = 1'b0;
        seen = 1'b1;
      end
      else if (seen) gap = 1'b1;
    end
    if (cnt == 1)   return 2;
    if (contig)     return 3;
    return 4;
  endfunction

  // Helper：位宽合法性（CFG-003..004）
  function automatic bit apb_data_width_legal(int unsigned dw);
    return (dw == 8) || (dw == 16) || (dw == 32);
  endfunction

  function automatic bit apb_addr_width_legal(int unsigned aw);
    return (aw >= 1) && (aw <= 32);
  endfunction

  // Helper：物理地址空间（CP-07）
  function automatic apb_pas_space_e apb_pas_space(logic nse, logic prot_ns);
    if (!nse && !prot_ns) return APB_PAS_SECURE;
    if (!nse &&  prot_ns) return APB_PAS_NON_SECURE;
    if ( nse && !prot_ns) return APB_PAS_ROOT;
    return APB_PAS_REALM;
  endfunction

  // ---------------------------------------------------------------------------
  // Helper：parity grouping（CT-4/CFG-008）
  //   每 check bit 覆盖 ≤8 bit；末 group 仅覆盖实际存在的剩余地址位
  //   （实现等价：不存在位按 0 参与——实现技巧非协议语义，架构 §8）
  // ---------------------------------------------------------------------------
  function automatic logic apb_parity_group(
      logic [`APB_MAX_ADDR_WIDTH-1:0] addr,
      int unsigned                    group_idx,
      int unsigned                    addr_width);
    int unsigned lo = group_idx * 8;
    int unsigned hi = (lo + 8 > addr_width) ? addr_width : lo + 8; // 独占上界
    logic parity = 1'b0;
    for (int b = lo; b < hi; b++) parity ^= addr[b];
    return ~parity;   // 奇校验：使组内 1 的个数（含校验位）为奇
  endfunction

  // Helper：数据/写通用奇校验（≤8bit 组）
  function automatic logic apb_parity_byte(logic [7:0] b);
    return ~(^(b));
  endfunction

endpackage : apb_types_pkg

`endif // APB_TYPES_PKG__SV
