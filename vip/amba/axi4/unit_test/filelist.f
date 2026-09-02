// =============================================================================
// axi4 VIP Unit Test Filelist（L1；顺序：types_pkg → runner → src pkg → suites → tb）
// 注意：axi4_pkg（UVM 组件）仅在 transaction/memory 组需要；semantic 组只需 types_pkg。
// =============================================================================
../src/axi4_types_pkg.sv
../src/axi4_if.sv
unit_test_runner.sv
../src/axi4_pkg.sv
axi4_unit_semantic.sv
axi4_unit_memory.sv
axi4_unit_transaction.sv
axi4_unit_tb.sv
