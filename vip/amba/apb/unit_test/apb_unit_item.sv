// =============================================================================
// File Name   : apb_unit_item.sv
// Description : L1 Unit Test——transaction 层（apb_item 纯对象 golden vectors）
//               覆盖：构造默认值 / update_derived+addr_view / randomize 派生 /
//                     constraint 合法域 / 注入位不污染（C-3）
//               对应 REQ：TRN-002/004/005、CFG-003、PRO-016、CP-01/06/07、UT19 归位
// VLNV        : aixsilicon:vip:apb:1.0.0
// 同步规则    : vip-development §6.1（特性实现与 unit 同步落地）
// =============================================================================

`ifndef APB_UNIT_ITEM__SV
`define APB_UNIT_ITEM__SV

package apb_unit_item;

  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import apb_types_pkg::*;
  import apb_pkg::*;

  int PASS_CNT = 0;
  int FAIL_CNT = 0;

  function void check_int(string case_id, int actual, int expected);
    if (actual !== expected) begin
      $display("FAILED: %s expected=%0d actual=%0d", case_id, expected, actual);
      FAIL_CNT++;
    end else PASS_CNT++;
  endfunction

  function void check_bit(string case_id, bit actual, bit expected);
    if (actual !== expected) begin
      $display("FAILED: %s expected=%0b actual=%0b", case_id, expected, actual);
      FAIL_CNT++;
    end else PASS_CNT++;
  endfunction

  // ---------------------------------------------------------------------------
  // 构造默认值（字段初始；C-3 安全默认）
  // ---------------------------------------------------------------------------
  task t_item_defaults();
    apb_item it = apb_item::type_id::create("it");
    check_bit("dw_status_ok", (it.status == APB_OK), 1'b1);
    check_int("dw_inject_es", it.inject_extended_setup, 0);
    check_int("dw_inject_ipa", it.inject_illegal_penable, 0);
    check_int("dw_inject_ua",  it.inject_unstable_addr, 0);
    check_int("dw_inject_is",  it.inject_illegal_strb, 0);
    check_int("dw_inject_unal", it.inject_unaligned_addr, 0);
    check_int("dw_rq_wait", it.requested_wait_cycles, 0);
    check_int("dw_obs_wait", it.observed_wait_cycles, 0);
    check_int("dw_cfg_dw", it.cfg_data_width, 32);
    check_int("dw_cfg_aw", it.cfg_addr_width, 32);
  endtask

  // ---------------------------------------------------------------------------
  // update_derived / addr_view（TRN-002/004、CP-06/07）
  // ---------------------------------------------------------------------------
  task t_derived();
    apb_item it = apb_item::type_id::create("it");
    it.cfg_data_width = 32;
    it.addr  = 'h1004;
    it.strb  = 'hF;
    it.prot.non_secure_access = 1'b0;
    it.update_derived();
    check_bit("drv_align32", it.aligned, 1'b1);
    check_int("drv_strb_full", it.strb_class, 1);
    // 16 位宽下 strb 2'b11 = full
    it.cfg_data_width = 16; it.addr = 'h1002; it.strb = 2'b11;
    it.update_derived();
    check_bit("drv_align16", it.aligned, 1'b1);
    check_int("drv_strb16_full", it.strb_class, 1);
    // addr_view 位宽视图（cfg_addr_width=12：地址裁剪到 12 位）
    it.cfg_addr_width = 12; it.addr = 'h0000_0ABC;
    check_int("drv_addr_view12", it.addr_view(), 'h0ABC);
  endtask

  // ---------------------------------------------------------------------------
  // randomize 派生后不变式 + 注入位默认不污染（C-3；randomize 只动 rand 字段）
  // ---------------------------------------------------------------------------
  task t_randomize_safe();
    apb_item it = apb_item::type_id::create("it");
    it.cfg_data_width = 32;
    for (int i = 0; i < 50; i++) begin
      if (!it.randomize()) begin
        $display("FAILED: randomize fail iter=%0d", i);
        FAIL_CNT++;
        break;
      end
      check_int("rnd_inject_es",  it.inject_extended_setup, 0);
      check_int("rnd_inject_ipa", it.inject_illegal_penable, 0);
      check_int("rnd_wait_le256", (it.requested_wait_cycles <= 256), 1);
      check_int("rnd_start_dle16", (it.start_delay <= 16), 1);
    end
  endtask

  // ---------------------------------------------------------------------------
  // 纯 helper 联动（item 层复用 types helper；CP-06/07 golden）
  // ---------------------------------------------------------------------------
  task t_type_collab();
    check_int("collab_strb_sparse", apb_strb_class(4'b1001, 32), 4);
    check_int("collab_pas_ns",   apb_pas_space(1'b0, 1'b1), APB_PAS_NON_SECURE);
    check_int("collab_pas_root", apb_pas_space(1'b1, 1'b0), APB_PAS_ROOT);
    check_int("collab_pas_realm",apb_pas_space(1'b1, 1'b1), APB_PAS_REALM);
  endtask

endpackage : apb_unit_item

// ---------------------------------------------------------------------------
// 独立执行入口（unit_tb 调用）
// ---------------------------------------------------------------------------
module apb_unit_item_exec;
  import apb_unit_item::*;
  initial begin
    t_item_defaults();
    t_derived();
    t_randomize_safe();
    t_type_collab();
  end
endmodule

`endif // APB_UNIT_ITEM__SV