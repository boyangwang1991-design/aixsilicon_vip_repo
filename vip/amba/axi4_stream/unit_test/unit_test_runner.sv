// =============================================================================
// File Name   : unit_test_runner.sv
// Description : axi4_stream VIP L1 Unit Test 总控（纯 golden vector 断言）
//               通过：FAIL_CNT==0 且打印 UNIT_TEST_PASS；失败打印 FAILED: <case_id>
//               本 runner 不 import 协议 pkg；各 suite（axi4_stream_unit_*.sv）
//               自行 import 所需 types/pkg 后调用 check_* 断言。
// 依据        : vip-development-suite G2（compile + unit 判定）
// =============================================================================
`ifndef AXI4_STREAM_UNIT_TEST_RUNNER__SV
`define AXI4_STREAM_UNIT_TEST_RUNNER__SV

package axi4_stream_unit_test_pkg;

  int PASS_CNT = 0;
  int FAIL_CNT = 0;

  // golden vector 断言（case 失败必须输出 FAILED: <case_id> expected=... actual=...）
  function void check_int(string case_id, int actual, int expected);
    if (actual !== expected) begin
      $display("FAILED: %s expected=%0d actual=%0d", case_id, expected, actual);
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

  function void check_str(string case_id, string actual, string expected);
    if (actual != expected) begin
      $display("FAILED: %s expected=%s actual=%s", case_id, expected, actual);
      FAIL_CNT++;
    end
    else begin
      PASS_CNT++;
    end
  endfunction

  // 成功断言（expect 1）
  function void check_true(string case_id, bit actual);
    check_bit(case_id, actual, 1'b1);
  endfunction

endpackage

`endif // AXI4_STREAM_UNIT_TEST_RUNNER__SV