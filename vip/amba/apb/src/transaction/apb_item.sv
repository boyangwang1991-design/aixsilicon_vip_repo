// =============================================================================
// File Name   : apb_item.sv
// Description : APB normalized transaction（REQ §4 / 架构 §7）
//               - requested_wait_cycles（激励约束）/ observed_wait_cycles（观察）
//               - request item 自携带响应字段（ADR-12 response ownership）
//               - 注入字段默认 0、构造钳位、randomize 不污染（C-3）
// VLNV        : aixsilicon:vip:apb:1.0.0
// =============================================================================

`ifndef APB_ITEM__SV
`define APB_ITEM__SV

class apb_item extends uvm_sequence_item;

  // ===========================================================================
  // Request 层
  // ===========================================================================
  rand apb_direction_e                direction;
  rand bit [`APB_MAX_ADDR_WIDTH-1:0]  addr;
  rand bit [`APB_MAX_DATA_WIDTH-1:0]  wdata;

  // APB4+（物理不存在时 driver/monitor 不触碰，字段恒默认值——ADR-2）
  rand bit [`APB_MAX_DATA_WIDTH/8-1:0] strb;
  rand apb_protection                  prot;

  // APB5+（USER 三宽度 / WAKEUP / RME-PNSE）
  rand bit [`APB_MAX_USER_WIDTH-1:0]   auser;   // PAUSER
  rand bit [`APB_MAX_USER_WIDTH-1:0]   wuser;   // PWUSER
  rand bit                             wakeup;  // SEQUENCE_CONTROLLED / 直通字段

  // ===========================================================================
  // Response 层（request item 自携带响应——ADR-12）
  // ===========================================================================
  bit [`APB_MAX_DATA_WIDTH-1:0]        rdata;
  bit [`APB_MAX_USER_WIDTH-1:0]        ruser;
  bit [`APB_MAX_USER_WIDTH-1:0]        buser;
  bit                                  slverr;

  // APB5 RME（PRO-013）：物理地址空间信号 PNSE（monitor 采样 vif.pnse_w；
  // APB4 无 PNSE 时恒 0 = Secure 语义），与 PPROT[1] 组合出 4 个 PAS）
  rand bit                             pnse;        // PNSE（ADVANCE / RME_Support）

  // ===========================================================================
  // Timing 层（TRN-002：requested/observed 分离）
  // ===========================================================================
  rand int unsigned                    requested_wait_cycles; // Completer 激励约束
  int unsigned                         observed_wait_cycles;  // monitor 重建，不受约束
  rand int unsigned                    start_delay;           // 事务前 IDLE 拍数

  // ===========================================================================
  // Status（PRO-016）
  // ===========================================================================
  apb_status_e                         status = APB_OK;

  // ===========================================================================
  // Observation
  // ===========================================================================
  time                                 start_time;
  time                                 end_time;
  apb_phase_pattern_e                  phase_pattern;  // CP-08（monitor/coverage 填）

  // ===========================================================================
  // Derived（helper 计算）
  // ===========================================================================
  bit                                  aligned;
  int                                  strb_class;   // 0..4
  apb_pas_space_e                      pas_space;    // CP-07（rme_support 时有意义）

  // ===========================================================================
  // 注入控制（ERR-005/006；仅 allow_protocol_violation=1 时 driver 接受；
  // 非 rand 控制位，构造默认全 0，randomize 不污染）
  // ===========================================================================
  bit inject_extended_setup    = 0;   // 延长 SETUP（RUL-001 负向）
  bit inject_illegal_penable   = 0;   // 跳过 SETUP 直接 ACCESS（RUL-002）
  bit inject_unstable_addr     = 0;   // ACCESS wait 期翻转 paddr（RUL-003）
  bit inject_illegal_strb      = 0;   // 读事务 strb!=0（RUL-006）
  bit inject_unaligned_addr    = 0;   // 未对齐地址（TRN-005 UNPREDICTABLE 分层）

  // 生效位宽（driver/monitor 由 config 赋值）
  int unsigned cfg_addr_width = 32;
  int unsigned cfg_data_width = 32;
  int unsigned cfg_user_req_width  = 0;
  int unsigned cfg_user_data_width = 0;

  // ===========================================================================
  // 约束（C-3：default-safe——对齐地址/合法 strb/激励 wait 范围）
  // ===========================================================================
  constraint c_requested_wait {
    requested_wait_cycles <= 256;   // 激励合法域宽松；completer 侧按 config 裁
  }

  constraint c_start_delay {
    start_delay <= 16;
  }

  `uvm_object_utils_begin(apb_item)
    `uvm_field_enum(apb_direction_e, direction, UVM_DEFAULT)
    `uvm_field_int(addr,    UVM_HEX)
    `uvm_field_int(wdata,   UVM_HEX)
    `uvm_field_int(strb,    UVM_HEX)
    `uvm_field_int(prot,    UVM_HEX)
    `uvm_field_int(auser,   UVM_HEX)
    `uvm_field_int(wuser,   UVM_HEX)
    `uvm_field_int(wakeup,  UVM_DEFAULT)
    `uvm_field_int(rdata,   UVM_HEX)
    `uvm_field_int(ruser,   UVM_HEX)
    `uvm_field_int(buser,   UVM_HEX)
    `uvm_field_int(slverr,  UVM_DEFAULT)
    `uvm_field_int(requested_wait_cycles, UVM_DEFAULT)
    `uvm_field_int(observed_wait_cycles,  UVM_DEFAULT)
    `uvm_field_int(start_delay, UVM_DEFAULT)
    `uvm_field_enum(apb_status_e, status, UVM_DEFAULT)
    `uvm_field_enum(apb_phase_pattern_e, phase_pattern, UVM_DEFAULT)
    `uvm_field_int(inject_extended_setup,  UVM_DEFAULT)
    `uvm_field_int(inject_illegal_penable, UVM_DEFAULT)
    `uvm_field_int(inject_unstable_addr,   UVM_DEFAULT)
    `uvm_field_int(inject_illegal_strb,    UVM_DEFAULT)
    `uvm_field_int(inject_unaligned_addr,  UVM_DEFAULT)
  `uvm_object_utils_end

  function new(string name = "apb_item");
    super.new(name);
  endfunction

  // ---------------------------------------------------------------------------
  // 有效位宽视图
  // ---------------------------------------------------------------------------
  function bit [`APB_MAX_ADDR_WIDTH-1:0] addr_view();
    return addr << (`APB_MAX_ADDR_WIDTH - cfg_addr_width) >>>
                  (`APB_MAX_ADDR_WIDTH - cfg_addr_width);
  endfunction

  // ---------------------------------------------------------------------------
  // post_randomize：derived 刷新（对齐按 default-safe 判定；注入位不受影响）
  // ---------------------------------------------------------------------------
  function void post_randomize();
    update_derived();
  endfunction

  function void update_derived();
    aligned    = apb_is_aligned(addr, cfg_data_width);
    strb_class = apb_strb_class(strb, cfg_data_width);
    // CP-07（PRO-013）：pas_space = f(PNSE, PPROT[1])——RME 语义
    //   PNSE=0,PPROT[1]=0 → Secure | 0,1 → Non-secure | 1,0 → Root | 1,1 → Realm
    //   无 PNSE（APB4/vif HAS_PNSE=0）时 pnse 恒 0：PPROT[1] 决定 Secure/Non-secure
    pas_space  = apb_pas_space(pnse, prot.non_secure_access);
  endfunction

  // ---------------------------------------------------------------------------
  // Debug（DBG-001）
  // ---------------------------------------------------------------------------
  virtual function string convert2string();
    return $sformatf(
      "apb_item[dir=%s addr=0x%0h %s=0x%0h strb=0x%0h prot=0x%0h rq_wait=%0d obs_wait=%0d slverr=%0b status=%s pat=%s inj(e/p/s/s/u)=%0b%0b%0b%0b%0b]",
      direction.name(), addr_view(),
      (direction == APB_WRITE) ? "wdata" : "rdata",
      (direction == APB_WRITE) ? wdata : rdata,
      strb, prot, requested_wait_cycles, observed_wait_cycles,
      slverr, status.name(), phase_pattern.name(),
      inject_extended_setup, inject_illegal_penable, inject_unstable_addr,
      inject_illegal_strb, inject_unaligned_addr);
  endfunction

endclass : apb_item

`endif // APB_ITEM__SV
