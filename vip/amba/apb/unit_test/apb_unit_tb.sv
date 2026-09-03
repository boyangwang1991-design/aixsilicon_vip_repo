// =============================================================================
// File Name   : apb_unit_tb.sv
// Description : APB VIP L1 Unit Test 顶层（types + transaction + config golden vectors）
//               通过条件：各 suite FAIL_CNT==0 → UNIT_TEST_PASS
// VLNV        : aixsilicon:vip:apb:1.0.0
// =============================================================================

`ifndef APB_UNIT_TB__SV
`define APB_UNIT_TB__SV

`timescale 1ns/1ps

module apb_unit_tb;

  import apb_unit_types::*;
  import apb_unit_item::*;
  import apb_unit_config::*;

  initial begin
    $display("=== APB VIP L1 Unit Test start ===");

    // types_pkg golden vectors
    t_wait_bucket();
    t_strb_class();
    t_aligned();
    t_width_legal();
    t_pas_space();
    t_parity_group();

    // transaction（apb_item 纯对象）
    t_item_defaults();
    t_derived();
    t_randomize_safe();
    t_type_collab();

    // configuration（apb_config）
    t_version_defaults();
    apb_unit_config::t_cfg_width_legal();
    t_cap_consistency();

    $display("UNIT_TEST_SUMMARY: types=%0d FAIL types=%0d | item=%0d FAIL item=%0d | config=%0d FAIL config=%0d",
             apb_unit_types::PASS_CNT,  apb_unit_types::FAIL_CNT,
             apb_unit_item::PASS_CNT,   apb_unit_item::FAIL_CNT,
             apb_unit_config::PASS_CNT, apb_unit_config::FAIL_CNT);
    // 汇总（各 suite 独立计数；全部 0 才 PASS）
    if (apb_unit_types::FAIL_CNT  == 0 &&
        apb_unit_item::FAIL_CNT   == 0 &&
        apb_unit_config::FAIL_CNT == 0)
      $display("UNIT_TEST_PASS");
    else
      $display("UNIT_TEST_FAIL");
    $finish;
  end

endmodule

`endif // APB_UNIT_TB__SV
