// =============================================================================
// File Name   : axi4_unit_memory.sv
// Description : L1 Unit Test — axi4_memory（byte-addressable golden 模型）
//               read/write/peek/poke / partial(WSTRB) / zero-strobe /
//               unaligned lane / exclusive 状态机
// =============================================================================
`ifndef AXI4_UNIT_MEMORY__SV
`define AXI4_UNIT_MEMORY__SV

import axi4_unit_test_pkg::*;
import axi4_types_pkg::*;

module axi4_unit_memory;

  import axi4_pkg::*;

  initial begin
    axi4_memory mem;
    axi4_data   dout[];
    axi4_data   d;
    axi4_address beat;

    mem = new("mem");
    mem.set_geometry(32, 32, 1 << 12);   // 4KB 测试空间
    mem.initialize(8'h00);

    // 1. 基本 write_beat / read_beat（full strobe，aligned）
    beat = 32'h0100;
    mem.write_beat(beat, 4, 4, 32'hDEAD_BEEF, 4'b1111);
    d = mem.read_beat(beat, 4, 4);
    check_data("mem_full_rw", d, 32'hDEAD_BEEF);

    // 2. partial write（WSTRB=0011：仅 lane0/1 更新，lane2/3 保持）
    mem.write_beat(32'h0200, 4, 4, 32'hFFFF_FFFF, 4'b1111);
    mem.write_beat(32'h0200, 4, 4, 32'hABCD_1234, 4'b0011);
    d = mem.read_beat(32'h0200, 4, 4);
    check_data("mem_partial_strobe", d, 32'hFFFF_1234);   // lane2/3=FFFF 保持

    // 3. zero-strobe：WSTRB=0 不更新（PRO-015/RUL-013）
    mem.write_beat(32'h0300, 4, 4, 32'h5555_AAAA, 4'b1111);
    mem.write_beat(32'h0300, 4, 4, 32'hFFFF_0000, 4'b0000);
    d = mem.read_beat(32'h0300, 4, 4);
    check_data("mem_zero_strobe_untouched", d, 32'h5555_AAAA);

    // 4. unaligned：beat_addr lane 偏移（addr%4=2 → lane2/3）
    // 数据按 lane 位置摆放（lane2/3 有效）：0x0000_EE55 << 16 = 0xEE55_0000
    mem.write_beat(32'h0402, 4, 4, 32'hEE55_0000, 4'b1100);
    d = mem.read_beat(32'h0402, 4, 4);
    check_data("mem_unaligned_lane", d, 32'hEE55_0000);
    // 相邻 beat（0x0406）不影响 0x0402 的 lane2/3 字节（base 对齐 0x0404）
    mem.write_beat(32'h0406, 4, 4, 32'h1122_0000, 4'b1100);
    d = mem.read_beat(32'h0402, 4, 4);
    check_data("mem_unaligned_isolation", d, 32'hEE55_0000);
    // lane0/1 直读（base=0x0400）
    d = mem.read_beat(32'h0400, 4, 4);
    check_data("mem_unaligned_base_lanes", d[15:0], 16'h0000);

    // 5. read_burst（INCR 语义，len=4）
    for (int i = 0; i < 4; i++) begin
      mem.write_beat(32'h0500 + i * 4, 4, 4, 32'h0000_0000 + (i * 32'h0101), 4'b1111);
    end
    mem.read_burst(32'h0500, 4, 4, 4, dout);
    check_int("mem_read_burst_size", dout.size(), 4);
    check_data("mem_read_burst_beat2", dout[2], 32'h0000_0202);

    // 6. peek / poke（绕过 WSTRB/ exclusive）
    mem.poke_byte(32'h0600, 8'h7A);
    check_int("mem_poke_peek", mem.peek_byte(32'h0600), 8'h7A);

    // 7. exclusive 状态机（RUL-016 纯判定部分；enum 直接比较）
    check_bit("mem_exwrite_no_tag", bit'(mem.exclusive_write(32'h0700) == AXI4_OKAY), 1'b1);
    mem.exclusive_read(32'h0700);                          // 建立标记
    check_bit("mem_ex_tagged", mem.is_exclusive_tagged(32'h0700), 1'b1);
    check_bit("mem_exwrite_hit", bit'(mem.exclusive_write(32'h0700) == AXI4_EXOKAY), 1'b1);
    check_bit("mem_ex_cleared", mem.is_exclusive_tagged(32'h0700), 1'b0);
    check_bit("mem_exwrite_second", bit'(mem.exclusive_write(32'h0700) == AXI4_OKAY), 1'b1);
    // 普通 write_beat 清除标记
    mem.exclusive_read(32'h0800);
    mem.write_beat(32'h0800, 4, 4, 32'h0, 4'b1111);
    mem.clear_exclusive(32'h0800);
    check_bit("mem_ex_cleared_by_write", mem.is_exclusive_tagged(32'h0800), 1'b0);

    // 8. clear
    mem.clear();
    d = mem.read_beat(32'h0100, 4, 4);
    check_data("mem_clear", d, 32'h0000_0000);

    $display("memory: PASS=%0d FAIL=%0d", PASS_CNT, FAIL_CNT);
  end

endmodule : axi4_unit_memory

`endif // AXI4_UNIT_MEMORY__SV
