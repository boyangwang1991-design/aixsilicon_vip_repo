+incdir+../src+./tb
// =============================================================================
// axi4_stream VIP Self Test filelist
// 编译顺序：types_pkg -> if -> assertions -> pkg -> DUT fixtures -> tb 顶层
// 由 self_test/Makefile 编译：vcs -f filelist.f（-ntb_opts uvm-1.2 在命令行）
// =============================================================================

// ---- VIP 源码（按编译依赖顺序）----
../src/axi4_stream_types_pkg.sv
../src/axi4_stream_if.sv
../src/checker/axi4_stream_assertions.sv
../src/axi4_stream_pkg.sv

// ---- Self Test DUT fixtures（独立参考 DUT，不 import VIP pkg）----
../self_test/tb/axi4_stream_dut_fixtures.sv

// ---- Self Test 顶层（含 env / tests）----
../self_test/tb/axi4_stream_smoke_tb.sv
