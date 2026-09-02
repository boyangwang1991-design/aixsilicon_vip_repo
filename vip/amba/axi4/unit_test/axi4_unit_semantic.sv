// =============================================================================
// File Name   : axi4_unit_semantic.sv
// Description : L1 Unit Test — Semantic Helper golden vectors
//               get_beat_address / get_byte_lane_index / is_crossing_4kb /
//               pack/unpack burst length & size / memory_type encode-decode
//               （D5/D7 两个 4KB 缺陷与 WRAP 推进的 unit 防线）
// =============================================================================
`ifndef AXI4_UNIT_SEMANTIC__SV
`define AXI4_UNIT_SEMANTIC__SV

import axi4_unit_test_pkg::*;
import axi4_types_pkg::*;

module axi4_unit_semantic;

  initial begin
    axi4_address beat;
    int lane;

    // ------------------------------------------------------------------
    // 1. pack / unpack burst length（awlen 0-based）
    // ------------------------------------------------------------------
    check_int("unpack_len_1",  unpack_burst_length(axi4_burst_length'(0)),  1);
    check_int("unpack_len_16", unpack_burst_length(axi4_burst_length'(15)), 16);
    check_int("unpack_len_256",unpack_burst_length(axi4_burst_length'(255)),256);
    check_int("pack_len_1",    int'(pack_burst_length(1)),   0);
    check_int("pack_len_16",   int'(pack_burst_length(16)),  15);
    check_int("pack_len_256",  int'(pack_burst_length(256)), 255);

    // ------------------------------------------------------------------
    // 2. pack / unpack burst size（size enum：1/2/4/8/16/32/64/128 byte）
    // ------------------------------------------------------------------
    check_int("unpack_size_1",  unpack_burst_size(AXI4_BURST_SIZE_1_BYTE),  1);
    check_int("unpack_size_4",  unpack_burst_size(AXI4_BURST_SIZE_4_BYTES), 4);
    check_int("unpack_size_32", unpack_burst_size(AXI4_BURST_SIZE_32_BYTES),32);
    check_int("pack_size_4",    int'(pack_burst_size(4)),  int'(AXI4_BURST_SIZE_4_BYTES));
    check_int("pack_size_32",   int'(pack_burst_size(32)), int'(AXI4_BURST_SIZE_32_BYTES));

    // ------------------------------------------------------------------
    // 3. get_beat_address — INCR aligned / unaligned
    // ------------------------------------------------------------------
    // INCR aligned：addr=0x2000, size=4, len=4 → 0x2000/0x2004/0x2008/0x200C
    beat = get_beat_address(32'h2000, 0, AXI4_INCREMENTING_BURST, 4, 4);
    check_addr("incr_aligned_beat0", beat, 32'h2000);
    beat = get_beat_address(32'h2000, 3, AXI4_INCREMENTING_BURST, 4, 4);
    check_addr("incr_aligned_beat3", beat, 32'h200C);
    // INCR unaligned：addr=0x5002, size=4, len=3 → 0x5002/0x5006/0x500A
    beat = get_beat_address(32'h5002, 1, AXI4_INCREMENTING_BURST, 3, 4);
    check_addr("incr_unaligned_beat1", beat, 32'h5006);
    beat = get_beat_address(32'h5002, 2, AXI4_INCREMENTING_BURST, 3, 4);
    check_addr("incr_unaligned_beat2", beat, 32'h500A);

    // ------------------------------------------------------------------
    // 4. get_beat_address — FIXED（每拍同址）
    // ------------------------------------------------------------------
    beat = get_beat_address(32'h3004, 0, AXI4_FIXED_BURST, 4, 4);
    check_addr("fixed_beat0", beat, 32'h3004);
    beat = get_beat_address(32'h3004, 3, AXI4_FIXED_BURST, 4, 4);
    check_addr("fixed_beat3", beat, 32'h3004);

    // ------------------------------------------------------------------
    // 5. get_beat_address — WRAP（boundary = size*len 对齐；回绕到 low boundary）
    // ------------------------------------------------------------------
    // WRAP len=4 size=4 @0x2010：boundary 0x2010~0x201F，无回绕
    beat = get_beat_address(32'h2010, 0, AXI4_WRAPPING_BURST, 4, 4);
    check_addr("wrap4_beat0", beat, 32'h2010);
    beat = get_beat_address(32'h2010, 3, AXI4_WRAPPING_BURST, 4, 4);
    check_addr("wrap4_beat3", beat, 32'h201C);
    // WRAP len=8 size=4 @0x20E0：boundary 0x20E0~0x20FF；beat5 → 0x20F4
    beat = get_beat_address(32'h20E0, 5, AXI4_WRAPPING_BURST, 8, 4);
    check_addr("wrap8_beat5", beat, 32'h20F4);
    // WRAP len=4 size=4 @0x20F8（对齐 boundary 0x20F8~0x2107）：
    // beat2 = 0x2100 → 回绕到 lower boundary 0x20F0
    beat = get_beat_address(32'h20F8, 2, AXI4_WRAPPING_BURST, 4, 4);
    check_addr("wrap4_beat2_wrap", beat, 32'h20F0);
    // WRAP len=2 size=8 @0x3FF0：boundary 0x3FF0~0x3FFF；beat1 → 0x3FF8
    beat = get_beat_address(32'h3FF0, 1, AXI4_WRAPPING_BURST, 2, 8);
    check_addr("wrap2_beat1", beat, 32'h3FF8);
    // WRAP len=16 size=4 @0x20C0：beat9 → 0x20E4
    beat = get_beat_address(32'h20C0, 9, AXI4_WRAPPING_BURST, 16, 4);
    check_addr("wrap16_beat9", beat, 32'h20E4);

    // ------------------------------------------------------------------
    // 6. get_byte_lane_index（beat_addr % data_bytes）
    // ------------------------------------------------------------------
    lane = get_byte_lane_index(32'h2000, 4);
    check_int("lane_2000_w4", lane, 0);
    lane = get_byte_lane_index(32'h5002, 4);
    check_int("lane_5002_w4", lane, 2);
    lane = get_byte_lane_index(32'h5006, 4);
    check_int("lane_5006_w4", lane, 2);
    lane = get_byte_lane_index(32'h2001, 8);
    check_int("lane_2001_w8", lane, 1);
    lane = get_byte_lane_index(32'h2007, 8);
    check_int("lane_2007_w8", lane, 7);

    // ------------------------------------------------------------------
    // 7. is_crossing_4kb — 合法边界 / 跨界 / 单拍 / unaligned（D5 防线）
    // ------------------------------------------------------------------
    check_bit("4kb_ok_edge",  is_crossing_4kb(32'h00FFF8, 2, 4), 1'b0); // 0xFFF8~0xFFFF
    check_bit("4kb_cross",    is_crossing_4kb(32'h00FFFC, 4, 4), 1'b1); // → 0x10008
    check_bit("4kb_single",   is_crossing_4kb(32'h010000, 1, 4), 1'b0); // 单拍永不跨
    check_bit("4kb_unaligned",is_crossing_4kb(32'h3FFE,   7, 8), 1'b1); // 0x3FFE+48=0x402E（D7 防线）
    check_bit("4kb_unalign_ok",is_crossing_4kb(32'h3FC0,  6, 8), 1'b0); // 0x3FC0+40=0x3FE8
    check_bit("4kb_exactly",  is_crossing_4kb(32'h3FF8,   2, 4), 1'b0); // 0x3FF8~0x3FFF

    // ------------------------------------------------------------------
    // 8. memory_type encode / decode（cache 与 prot 组合）
    // ------------------------------------------------------------------
    check_int("enc_dev_nn", int'(encode_memory_type(AXI4_DEVICE_NON_BUFFERABLE, 0)),
                             int'(AXI4_DEVICE_NON_BUFFERABLE));
    // decode → enum 值直接比较（VCS module 上下文对枚举字面量 .name() 受限）
    begin
      axi4_memory_type mt;
      mt = decode_memory_type(encode_memory_type(AXI4_NORMAL_NON_CACHEABLE_BUFFERABLE, 0), 0);
      check_bit("dec_norm_wb", bit'(mt == AXI4_NORMAL_NON_CACHEABLE_BUFFERABLE), 1'b1);
      mt = decode_memory_type(encode_memory_type(AXI4_DEVICE_NON_BUFFERABLE, 1), 1);
      check_bit("dec_dev_nb", bit'(mt == AXI4_DEVICE_NON_BUFFERABLE), 1'b1);
    end

    $display("semantic: PASS=%0d FAIL=%0d", PASS_CNT, FAIL_CNT);
  end

endmodule : axi4_unit_semantic

`endif // AXI4_UNIT_SEMANTIC__SV
