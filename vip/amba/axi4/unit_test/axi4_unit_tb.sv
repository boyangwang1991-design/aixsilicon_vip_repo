// =============================================================================
// File Name   : axi4_unit_tb.sv
// Description : L1 Unit Test 顶层（无 interface/时钟/UVM 启动；纯 $static 语义）
//               汇总三组 suite 结果 → UNIT_TEST_PASS / UNIT_TEST_FAIL
// =============================================================================
`ifndef AXI4_UNIT_TB__SV
`define AXI4_UNIT_TB__SV

module axi4_unit_tb;

  import axi4_unit_test_pkg::*;

  // 各 suite 的 initial 块在各文件中独立执行；本顶层只负责收尾判定。
  // 执行顺序：semantic → memory → transaction（同一 time-0 区域，顺序编译保证）。
  axi4_unit_semantic u_semantic();
  axi4_unit_memory   u_memory();
  axi4_unit_transaction u_transaction();

  final begin
    $display("UNIT_TEST_SUMMARY: PASS=%0d FAIL=%0d", PASS_CNT, FAIL_CNT);
    if (FAIL_CNT == 0) begin
      $display("UNIT_TEST_PASS");
    end
    else begin
      $display("UNIT_TEST_FAIL");
    end
  end

endmodule : axi4_unit_tb

`endif // AXI4_UNIT_TB__SV
