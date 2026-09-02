// =============================================================================
// File Name   : unit_test_runner.sv
// Description : AXI4 VIP L1 Unit Test 总控（无 UVM 依赖，纯 golden vector 断言）
//               覆盖组：semantic / transaction / memory / configuration / policy
//               通过：PASS_CNT 全绿、FAIL_CNT==0、打印 UNIT_TEST_PASS
//               失败：打印 FAILED: <case> 并置 UNIT_TEST_FAIL
//               （validation-plan L1 Component Validation 的 Unit Test 机制化）
// =============================================================================
`ifndef AXI4_UNIT_TEST_RUNNER__SV
`define AXI4_UNIT_TEST_RUNNER__SV

package axi4_unit_test_pkg;
  import axi4_types_pkg::*;

  int PASS_CNT = 0;
  int FAIL_CNT = 0;

  // golden vector 断言（32 位截断打印辅助）
  function void check_int(string case_id, int actual, int expected);
    if (actual !== expected) begin
      $display("FAILED: %s expected=%0d actual=%0d", case_id, expected, actual);
      FAIL_CNT++;
    end
    else begin
      PASS_CNT++;
    end
  endfunction

  function void check_addr(string case_id, axi4_address actual, axi4_address expected);
    if (actual !== expected) begin
      $display("FAILED: %s expected=%0h actual=%0h", case_id, expected, actual);
      FAIL_CNT++;
    end
    else begin
      PASS_CNT++;
    end
  endfunction

  function void check_bit(string case_id, bit actual, bit expected);
    if (actual !== expected) begin
      $display("FAILED: %s expected=%0b actual=%0b", case_id, expected, actual);
      FAIL_CNT++;
    end
    else begin
      PASS_CNT++;
    end
  endfunction

  function void check_data(string case_id, axi4_data actual, axi4_data expected);
    if (actual !== expected) begin
      $display("FAILED: %s expected=%08h actual=%08h", case_id, expected[31:0], actual[31:0]);
      FAIL_CNT++;
    end
    else begin
      PASS_CNT++;
    end
  endfunction

  function void check_str(string case_id, string actual, string expected);
    if (actual != expected) begin
      $display("FAILED: %s expected=%s actual=%s", case_id, expected, actual);
      FAIL_CNT++;
    end
    else begin
      PASS_CNT++;
    end
  endfunction

endpackage

`endif // AXI4_UNIT_TEST_RUNNER__SV
