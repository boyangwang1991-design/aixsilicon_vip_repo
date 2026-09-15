+incdir+../src
// =============================================================================
// axi4_stream VIP Unit Test Filelist（L1）
// 顺序：编译依赖（src 纯语义 pkg）→ runner → suites（semantic/transaction/config/checker）→ tb
//
// 说明：
//   - 所有条目使用 ../<dir>/<file> 相对形式；self_test/Makefile 在 build 内把它
//     展开为绝对路径，以保证编译 CWD 保持在 build、源仓不被写入；
//   - 每个 suite 与 src/ 特性批次同步登记：新增纯对象特性必须追加对应
//     axi4_stream_unit_<suite>.sv 并在此登记；
//   - src 依赖：axi4_stream_types_pkg.sv 无 UVM 可独立编；
//     axi4_stream_if.sv / axi4_stream_pkg.sv 引用 UVM（uvm_sequence_item），
//     需先编 UVM 库（由 -ntb_opts uvm-1.2 提供）；
//   - 信号时序 / UVM 组件协作不进此层（归 self_test）。
// =============================================================================
../src/axi4_stream_types_pkg.sv
../src/axi4_stream_if.sv
../src/axi4_stream_pkg.sv
../unit_test/unit_test_runner.sv
../unit_test/axi4_stream_unit_semantic.sv
../unit_test/axi4_stream_unit_transaction.sv
../unit_test/axi4_stream_unit_config.sv
../unit_test/axi4_stream_unit_checker.sv
../unit_test/axi4_stream_unit_tb.sv
