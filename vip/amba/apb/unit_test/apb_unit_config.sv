// =============================================================================
// File Name   : apb_unit_config.sv
// Description : L1 Unit Test——configuration 层（apb_config 纯对象 golden vectors）
//               覆盖：版本能力派生（CFG-001/002）/ 位宽合法性（CFG-003..005，
//                     UT19 归位）/ 能力–接口一致性（C-8）
// VLNV        : aixsilicon:vip:apb:1.0.0
// 同步规则    : vip-development §6.1（特性实现与 unit 同步落地）
// =============================================================================

`ifndef APB_UNIT_CONFIG__SV
`define APB_UNIT_CONFIG__SV

package apb_unit_config;

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

  // 捕获 APB_CFG 的 uvm_fatal 使仿真继续；记录触发次数
  class apb_cfg_fatal_catcher extends uvm_report_catcher;
    int caught_count = 0;
    function new(string name = "apb_cfg_fatal_catcher");
      super.new(name);
    endfunction
    virtual function uvm_report_catcher::action_e catch();
      if (get_severity() == UVM_FATAL && get_id() == "APB_CFG")
        caught_count++;
      return CAUGHT;   // 阻止 fatal 中止
    endfunction
  endclass

  task t_version_defaults();
    apb_config c = apb_config::type_id::create("c");
    c.protocol_version = APB3;
    c.apply_version_defaults();
    check_bit("v3_strb_off",  !c.enable_strb,   1'b1);
    check_bit("v3_prot_off",  !c.enable_prot,   1'b1);
    check_bit("v3_wakeup_off",!c.enable_wakeup, 1'b1);
    check_bit("v3_rme_off",   !c.rme_support,   1'b1);
    check_int("v3_usern",     c.user_req_width, 0);

    c.protocol_version = APB4;
    c.apply_version_defaults();
    check_bit("v4_strb_on",    c.enable_strb,    1'b1);
    check_bit("v4_prot_on",    c.enable_prot,    1'b1);
    check_bit("v4_wakeup_off", !c.enable_wakeup, 1'b1);
    check_bit("v4_rme_off",    !c.rme_support,   1'b1);

    c.protocol_version = APB5;
    c.rme_support = 1;
    c.apply_version_defaults();
    check_bit("v5_rme_prot_on", c.enable_prot, 1'b1);   // CFG-002：rme→prot
  endtask

  task t_cfg_width_legal();
    apb_config c = apb_config::type_id::create("c");
    check_bit("dw8_ok",  apb_data_width_legal(8),   1'b1);
    check_bit("dw16_ok", apb_data_width_legal(16),  1'b1);
    check_bit("dw32_ok", apb_data_width_legal(32),  1'b1);
    check_bit("dw12_ng", !apb_data_width_legal(12), 1'b1);
    check_bit("dw64_ng", !apb_data_width_legal(64), 1'b1);
    check_bit("aw1_ok",  apb_addr_width_legal(1),   1'b1);
    check_bit("aw32_ok", apb_addr_width_legal(32),  1'b1);
    check_bit("aw33_ng", !apb_addr_width_legal(33), 1'b1);
    check_bit("aw0_ng",  !apb_addr_width_legal(0),  1'b1);
    // validate_widths 对合法值不 fatal
    c.data_width = 32; c.addr_width = 32;
    c.validate_widths();
    // 非法值应被 CFG 拒绝（fatal 被 catcher 捕获 → caught_count 增加）
    begin
      apb_cfg_fatal_catcher rc = new("dw64_catcher");
      uvm_report_cb::add(null, rc);
      c.data_width = 64;
      c.validate_widths();   // fatal → catcher 捕获
      uvm_report_cb::delete(null, rc);
      if (rc.caught_count > 0) PASS_CNT++;
      else begin
        $display("FAILED: cfg_dw64_should_fatal (fatal not raised)");
        FAIL_CNT++;
      end
    end
  endtask

  task t_cap_consistency();
    apb_config c = apb_config::type_id::create("c");
    c.data_width = 32; c.addr_width = 32;
    // enable_strb=1 但 vif HAS_PSTRB=0 → 应 fatal
    begin
      apb_cfg_fatal_catcher rc = new("strb_phys_catcher");
      uvm_report_cb::add(null, rc);
      c.enable_strb = 1;
      c.validate_interface_vs_config(/*has_pstrb*/0, /*has_pprot*/1,
          /*user_req*/0, /*user_data*/0, /*user_resp*/0,
          /*has_pwakeup*/0, /*has_pnse*/0, /*has_check*/0);
      uvm_report_cb::delete(null, rc);
      if (rc.caught_count > 0) PASS_CNT++;
      else begin
        $display("FAILED: cfg_cap_strb_missing_phys (fatal not raised)");
        FAIL_CNT++;
      end
    end
    // 一致场景不应 fatal
    begin
      apb_cfg_fatal_catcher rc = new("consistent_catcher");
      c.enable_strb = 1; c.enable_prot = 1;
      uvm_report_cb::add(null, rc);
      c.validate_interface_vs_config(/*has_pstrb*/1, /*has_pprot*/1,
          /*user_req*/0, /*user_data*/0, /*user_resp*/0,
          /*has_pwakeup*/0, /*has_pnse*/0, /*has_check*/0);
      uvm_report_cb::delete(null, rc);
      if (rc.caught_count == 0) PASS_CNT++;
      else begin
        $display("FAILED: cfg_cap_consistent_no_fatal");
        FAIL_CNT++;
      end
    end
  endtask

endpackage : apb_unit_config

// ---------------------------------------------------------------------------
// 独立执行入口（unit_tb 调用）
// ---------------------------------------------------------------------------
module apb_unit_config_exec;
  import apb_unit_config::*;
  initial begin
    t_version_defaults();
    t_cfg_width_legal();
    t_cap_consistency();
  end
endmodule

`endif // APB_UNIT_CONFIG__SV