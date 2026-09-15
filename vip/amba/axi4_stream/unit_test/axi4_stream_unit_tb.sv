// =============================================================================
// File Name   : axi4_stream_unit_tb.sv
// Description : L1 Unit Test 顶层（无 interface/时钟/UVM 启动；纯 golden vector）
//               实例化各 suite 模块并汇总判定 → UNIT_TEST_PASS / UNIT_TEST_FAIL
// 依据        : vip-development-suite G2（compile + unit 判定）
// =============================================================================
`ifndef AXI4_STREAM_UNIT_TB__SV
`define AXI4_STREAM_UNIT_TB__SV

module axi4_stream_unit_tb;

  import axi4_stream_unit_test_pkg::*;

  // 各 suite 的 initial 块并发执行；suite 之间无依赖
  axi4_stream_unit_semantic    u_semantic();
  axi4_stream_unit_transaction u_transaction();
  axi4_stream_unit_config      u_config();
  axi4_stream_unit_checker     u_checker();

  final begin
    $display("UNIT_TEST_SUMMARY: PASS=%0d FAIL=%0d", PASS_CNT, FAIL_CNT);
    if (FAIL_CNT == 0) $display("UNIT_TEST_PASS");
    else               $display("UNIT_TEST_FAIL");
  end

endmodule : axi4_stream_unit_tb

`endif // AXI4_STREAM_UNIT_TB__SV
