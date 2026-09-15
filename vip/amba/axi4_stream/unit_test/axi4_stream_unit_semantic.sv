// =============================================================================
// File Name   : axi4_stream_unit_semantic.sv
// Description : L1 Unit Test — 协议语义 golden vectors
//               覆盖：byte 分类、缺省归一化、byte 计数、token 化、包 API、
//               EXACT_BEAT 比较语义、配置合法性、vif/config 一致性
// 依据        : docs/requirement.md（REQ-PRO-005/006/007, REQ-CFG-002..006,
//               REQ-TXN-002/003, REQ-SCB-002/003）
// 手写 golden 期望值，不调用被验证的同一组合函数生成 oracle。
// =============================================================================
`ifndef AXI4_STREAM_UNIT_SEMANTIC__SV
`define AXI4_STREAM_UNIT_SEMANTIC__SV

module axi4_stream_unit_semantic;

  import axi4_stream_unit_test_pkg::*;
  import axi4_stream_types_pkg::*;

  initial begin
    logic [AXIS_MAX_BYTES-1:0] keep, strb;
    logic [AXIS_MAX_BITS-1:0]  data;
    int data_b, pos_b, null_b;
    bit illegal;
    axis_token_t tokens[];
    int tcount;
    string reason;
    bit ok;

    // ---------------- byte 分类（REQ-PRO-005 表）----------------
    check_int("sem_classify_data",     int'(axis_classify_byte(1'b1, 1'b1)), int'(AXIS_BYTE_DATA));
    check_int("sem_classify_position", int'(axis_classify_byte(1'b1, 1'b0)), int'(AXIS_BYTE_POSITION));
    check_int("sem_classify_null",     int'(axis_classify_byte(1'b0, 1'b0)), int'(AXIS_BYTE_NULL));
    check_int("sem_classify_illegal",  int'(axis_classify_byte(1'b0, 1'b1)), int'(AXIS_BYTE_ILLEGAL));

    // ---------------- 缺省归一化（REQ-CFG-002）----------------
    check_int("sem_keep_default", int'(axis_effective_keep(1'b0, '0, 8)), int'(axis_byte_mask(8)));
    keep = 8'h33;
    check_int("sem_strb_default_from_keep",
      int'(axis_effective_strb(1'b1, keep, 1'b0, '0, 8)), int'(keep));
    check_int("sem_keep_strb_both_default",
      int'(axis_effective_strb(1'b0, '0, 1'b0, '0, 8)), int'(axis_byte_mask(8)));
    check_int("sem_ready_default", int'(axis_effective_ready(1'b0, 1'b0)), 1);
    check_int("sem_ready_present", int'(axis_effective_ready(1'b1, 1'b0)), 0);

    // ---------------- byte 计数：稀疏 TKEEP / POSITION / 全 NULL ----------------
    // keep=0x33, strb=0xff → lane0/1/4/5 为 DATA；lane2/3/6/7 为 keep=0,strb=1（非法）
    // 因此 NULL（keep=0&&strb=0）计数为 0，非法组合计数为 4。
    keep = 8'h33; strb = 8'hff;
    data_b = axis_data_byte_count(1'b1, keep, 1'b1, strb, 8);
    pos_b  = axis_position_byte_count(1'b1, keep, 1'b1, strb, 8);
    null_b = axis_null_byte_count(1'b1, keep, 1'b1, strb, 8);
    check_int("sem_sparse_data_cnt", data_b, 4);
    check_int("sem_sparse_pos_cnt",  pos_b, 0);
    check_int("sem_sparse_null_cnt", null_b, 0);

    // 真正的稀疏 NULL：keep=0x11, strb=0x11 → DATA=2, NULL=6
    keep = 8'h11; strb = 8'h11;
    check_int("sem_sparse_null_data", axis_data_byte_count(1'b1, keep, 1'b1, strb, 8), 2);
    check_int("sem_sparse_null_cnt2", axis_null_byte_count(1'b1, keep, 1'b1, strb, 8), 6);
    check_bit("sem_sparse_illegal_cnt",
      axis_illegal_byte_present(1'b1, 8'h33, 1'b1, 8'hff, 8), 1'b1);
    check_bit("sem_sparse_no_illegal",
      axis_illegal_byte_present(1'b1, 8'h11, 1'b1, 8'h11, 8), 1'b0);

    check_int("sem_allnull_null_cnt", axis_null_byte_count(1'b1, '0, 1'b1, '0, 8), 8);
    check_int("sem_allnull_data_cnt", axis_data_byte_count(1'b1, '0, 1'b1, '0, 8), 0);

    // 非尾拍 partial（低 4 lane 有效）
    keep = 8'h0f; strb = 8'h0f;
    check_int("sem_partial_mid_cnt", axis_data_byte_count(1'b1, keep, 1'b1, strb, 8), 4);

    // POSITION（keep=1 strb=0）
    keep = 8'hff; strb = 8'h00;
    check_int("sem_position_cnt", axis_position_byte_count(1'b1, keep, 1'b1, strb, 8), 8);

    // 非法组合 keep=0 strb=1
    illegal = axis_illegal_byte_present(1'b1, 8'h00, 1'b1, 8'h01, 8);
    check_bit("sem_illegal_present", illegal, 1'b1);
    illegal = axis_illegal_byte_present(1'b1, 8'h01, 1'b1, 8'h01, 8);
    check_bit("sem_illegal_absent", illegal, 1'b0);

    // ---------------- 有效载荷 X 检查（POSITION/NULL 不检查）----------------
    data = '0;
    data[7:0] = 8'hx0;
    check_bit("sem_payload_x_data",
      axis_payload_has_unknown(data, 1'b1, 8'h01, 1'b1, 8'h01, 8), 1'b1);
    data = '0;
    data[7:0] = 8'hx0;
    check_bit("sem_payload_x_position",
      axis_payload_has_unknown(data, 1'b1, 8'h01, 1'b1, 8'h00, 8), 1'b0);

    // ---------------- token 化（REQ-SCB-002 / REQ-PRO-007）----------------
    // 全 NULL + TLAST：必须保留 END_PACKET
    axis_tokenize_beat('0, 1'b1, '0, 1'b1, '0, 1'b1, 1'b1, 8, tokens, tcount);
    check_int("sem_token_allnull_last_count", tcount, 1);
    check_int("sem_token_allnull_last_kind", int'(tokens[0].kind), int'(AXIS_TOKEN_END_PACKET));

    // 混合：DATA + POSITION + NULL + TLAST
    data = '0; data[7:0] = 8'hAA; data[23:16] = 8'hBB;
    keep = 8'h0F; strb = 8'h07;   // lane0-2 DATA, lane3 POSITION, lane4-7 NULL
    axis_tokenize_beat(data, 1'b1, keep, 1'b1, strb, 1'b1, 1'b1, 8, tokens, tcount);
    check_int("sem_token_mixed_count", tcount, 5);
    check_int("sem_token_mixed_0", int'(tokens[0].kind), int'(AXIS_TOKEN_DATA));
    check_int("sem_token_mixed_value0", int'(tokens[0].value), 8'hAA);
    check_int("sem_token_mixed_2_value", int'(tokens[2].value), 8'hBB);
    check_int("sem_token_mixed_3", int'(tokens[3].kind), int'(AXIS_TOKEN_POSITION));
    check_int("sem_token_mixed_4", int'(tokens[4].kind), int'(AXIS_TOKEN_END_PACKET));

    begin
      axis_token_t a[];
      axis_token_t b[];
      a = new[2]; b = new[2];
      a[0].kind = AXIS_TOKEN_DATA;       a[0].value = 8'h11;
      a[1].kind = AXIS_TOKEN_END_PACKET; a[1].value = 0;
      b[0].kind = AXIS_TOKEN_DATA;       b[0].value = 8'h11;
      b[1].kind = AXIS_TOKEN_END_PACKET; b[1].value = 0;
      check_bit("sem_token_equal_same", axis_token_stream_equal(a, b), 1'b1);
      b[1].kind = AXIS_TOKEN_DATA; b[1].value = 8'h22;
      check_bit("sem_token_equal_diff", axis_token_stream_equal(a, b), 1'b0);
    end

    // ---------------- 包 API（REQ-TXN-002/003）----------------
    check_int("sem_beats_for_0_bytes", axis_beat_count_for_bytes(0, 4), 1);
    check_int("sem_beats_for_1_byte",  axis_beat_count_for_bytes(1, 4), 1);
    check_int("sem_beats_for_4_bytes", axis_beat_count_for_bytes(4, 4), 1);
    check_int("sem_beats_for_5_bytes", axis_beat_count_for_bytes(5, 4), 2);
    check_int("sem_keep_beat0_of_5",   int'(axis_keep_for_beat(5, 4, 0)), 4'hf);
    check_int("sem_keep_beat1_of_5",   int'(axis_keep_for_beat(5, 4, 1)), 4'h1);
    check_bit("sem_expressible_no_keep_5", axis_bytes_expressible(5, 4, 1'b0), 1'b0);
    check_bit("sem_expressible_no_keep_4", axis_bytes_expressible(4, 4, 1'b0), 1'b1);
    check_bit("sem_expressible_with_keep_5", axis_bytes_expressible(5, 4, 1'b1), 1'b1);

    // ---------------- EXACT_BEAT 比较语义（有效 lane 值）----------------
    begin
      logic [AXIS_MAX_BITS-1:0] da, db;
      logic [AXIS_MAX_BYTES-1:0] ka, kb, sa, sb;
      da = '0; db = '0;
      // lane0 为 DATA（keep=1,strb=1）；lane1 为 POSITION（keep=1,strb=0）
      ka = 8'h03; kb = 8'h03;
      sa = 8'h01; sb = 8'h01;
      da[7:0] = 8'hAA; db[7:0] = 8'hAA;
      check_bit("sem_exact_equal", axis_exact_beat_equal(da, ka, sa, db, kb, sb, 8), 1'b1);
      // POSITION lane 的数据值不参与比较
      da[15:8] = 8'h11; db[15:8] = 8'h22;
      check_bit("sem_exact_ignore_position_lane",
        axis_exact_beat_equal(da, ka, sa, db, kb, sb, 8), 1'b1);
      // NULL lane（keep=0）的数据值也不参与比较
      da[23:16] = 8'h33; db[23:16] = 8'h44;
      check_bit("sem_exact_ignore_null_lane",
        axis_exact_beat_equal(da, ka, sa, db, kb, sb, 8), 1'b1);
      // 有效 DATA lane 数据不同必须不等
      da[7:0] = 8'h00;
      check_bit("sem_exact_detect_diff",
        axis_exact_beat_equal(da, ka, sa, db, kb, sb, 8), 1'b0);
    end

    // ---------------- 配置合法性（REQ-CFG-005/006, REQ-CFG-004）----------------
    ok = axis_config_check(1'b1, 64, 1'b1, 1'b0, 1'b1, 0, 0, 0, 0, reason);
    check_bit("cfg_valid_64", ok, 1'b1);
    ok = axis_config_check(1'b1, 24, 1'b1, 1'b1, 1'b1, 0, 0, 0, 0, reason);
    check_bit("cfg_valid_24", ok, 1'b1);
    ok = axis_config_check(1'b1, 40, 1'b1, 1'b1, 1'b1, 0, 0, 0, 0, reason);
    check_bit("cfg_valid_40", ok, 1'b1);
    ok = axis_config_check(1'b1, 96, 1'b1, 1'b1, 1'b1, 0, 0, 0, 0, reason);
    check_bit("cfg_valid_96", ok, 1'b1);
    ok = axis_config_check(1'b1, 4, 1'b1, 1'b0, 1'b1, 0, 0, 0, 0, reason);
    check_bit("cfg_invalid_width_4", ok, 1'b0);
    ok = axis_config_check(1'b1, 12, 1'b1, 1'b0, 1'b1, 0, 0, 0, 0, reason);
    check_bit("cfg_invalid_width_12", ok, 1'b0);
    ok = axis_config_check(1'b1, 8192, 1'b1, 1'b0, 1'b1, 0, 0, 0, 0, reason);
    check_bit("cfg_invalid_width_8192", ok, 1'b0);

    // HAS_TDATA=0 禁止 TKEEP/TSTRB（REQ-CFG-005）
    ok = axis_config_check(1'b0, 32, 1'b1, 1'b0, 1'b1, 0, 0, 0, 0, reason);
    check_bit("cfg_invalid_nodata_keep", ok, 1'b0);
    ok = axis_config_check(1'b0, 32, 1'b0, 1'b0, 1'b1, 0, 0, 0, 0, reason);
    check_bit("cfg_valid_side_only", ok, 1'b1);

    // ID/DEST/USER 范围
    ok = axis_config_check(1'b1, 32, 1'b1, 1'b0, 1'b1, 33, 0, 0, 0, reason);
    check_bit("cfg_invalid_id_33", ok, 1'b0);
    ok = axis_config_check(1'b1, 32, 1'b1, 1'b0, 1'b1, 0, 33, 0, 0, reason);
    check_bit("cfg_invalid_dest_33", ok, 1'b0);
    ok = axis_config_check(1'b1, 32, 1'b1, 1'b0, 1'b1, 0, 0, 4097, 0, reason);
    check_bit("cfg_invalid_user_4097", ok, 1'b0);
    ok = axis_config_check(1'b1, 32, 1'b1, 1'b0, 1'b1, 32, 32, 4096, 0, reason);
    check_bit("cfg_valid_boundary", ok, 1'b1);

    // PER_BYTE 映射才检查整除（REQ-CFG-004）
    ok = axis_config_check(1'b1, 64, 1'b1, 1'b0, 1'b1, 0, 0, 48, 8, reason);
    check_bit("cfg_valid_per_byte_48", ok, 1'b1);
    ok = axis_config_check(1'b1, 64, 1'b1, 1'b0, 1'b1, 0, 0, 47, 8, reason);
    check_bit("cfg_invalid_per_byte_47", ok, 1'b0);
    ok = axis_config_check(1'b1, 64, 1'b1, 1'b0, 1'b1, 0, 0, 47, 0, reason);
    check_bit("cfg_valid_user_47_opaque", ok, 1'b1);

    // vif 与 config 一致性（REQ-CFG-006）
    check_bit("cfg_vif_match", axis_vif_matches(1'b1, 64, 1'b1, 64), 1'b1);
    check_bit("cfg_vif_mismatch_width", axis_vif_matches(1'b1, 32, 1'b1, 64), 1'b0);
    check_bit("cfg_vif_mismatch_ready", axis_vif_matches(1'b0, 64, 1'b1, 64), 1'b0);

    $display("semantic: PASS=%0d FAIL=%0d", PASS_CNT, FAIL_CNT);
  end

endmodule : axi4_stream_unit_semantic

`endif // AXI4_STREAM_UNIT_SEMANTIC__SV
