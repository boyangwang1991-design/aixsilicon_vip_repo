// =============================================================================
// File Name   : axi4_stream_unit_transaction.sv
// Description : L1 Unit Test — 事务模型 golden vectors
//               覆盖：beat/packet/ready/observed/error 字段、包 API、快照独立性
// 依据        : docs/requirement.md（REQ-TXN-001..007）
// 手写期望；验证快照独立（REQ-TXN-007）与状态枚举（REQ-TXN-004）。
// =============================================================================
`ifndef AXI4_STREAM_UNIT_TRANSACTION__SV
`define AXI4_STREAM_UNIT_TRANSACTION__SV

module axi4_stream_unit_transaction;

  import uvm_pkg::*;
  import axi4_stream_unit_test_pkg::*;
  import axi4_stream_types_pkg::*;
  import axi4_stream_pkg::*;

  initial begin
    axi4_stream_packet_item pkt;
    axi4_stream_beat_item   beat;
    axi4_stream_observed_beat obs, obs_clone;
    axi4_stream_observed_packet opkt;
    axi4_stream_error_event ev;
    axi4_stream_ready_item r;
    stream_key_t key;
    byte unsigned b[$];
    int lanes;

    // ---------------- beat item 字段完整性（REQ-TXN-001）----------------
    beat = axi4_stream_beat_item::type_id::create("beat");
    beat.data = '1; beat.keep = 8'h0f; beat.strb = 8'h07; beat.last = 1'b1;
    beat.id = 32'h3; beat.dest = 32'h2; beat.user = '1;
    beat.idle_cycles = 3;
    check_int("txn_beat_idle", beat.idle_cycles, 3);
    check_bit("txn_beat_last", beat.last, 1'b1);
    check_int("txn_beat_keep", int'(beat.keep), 8'h0f);
    check_int("txn_beat_strb", int'(beat.strb), 8'h07);
    check_true("txn_beat_str", beat.convert2string() != "");

    // ---------------- packet from_bytes（REQ-TXN-002/003）----------------
    key.tid = 1; key.tdest = 2;
    lanes = 4;
    b.delete();
    for (int i = 0; i < 5; i++) b.push_back(8'h10 + i);
    pkt = axi4_stream_packet_item::type_id::create("pkt");
    check_true("txn_from_bytes_ok", pkt.from_bytes(b, key, 1'b1, lanes));
    check_int("txn_from_bytes_beats", pkt.beats.size(), 2);
    check_int("txn_from_bytes_data_cnt", pkt.data_byte_count, 5);
    check_int("txn_from_bytes_keep0", int'(pkt.beats[0].keep), 4'hf);
    check_int("txn_from_bytes_keep1", int'(pkt.beats[1].keep), 4'h1);
    check_int("txn_from_bytes_key_tid", int'(pkt.key.tid), 1);
    check_int("txn_from_bytes_key_dest", int'(pkt.key.tdest), 2);
    check_bit("txn_from_bytes_last_beat", pkt.beats[1].last, 1'b1);
    check_bit("txn_from_bytes_mid_not_last", pkt.beats[0].last, 1'b0);

    // 无 TKEEP 且长度不是整数拍：必须拒绝（不静默填充有效字节）
    pkt = axi4_stream_packet_item::type_id::create("pkt2");
    check_bit("txn_from_bytes_reject_5_no_keep", pkt.from_bytes(b, key, 1'b0, lanes), 1'b0);

    // 0 数据字节包：需要 1 拍（REQ-TXN-003）
    b.delete();
    check_bit("txn_from_bytes_zero_ok", pkt.from_bytes(b, key, 1'b1, lanes), 1'b1);
    check_int("txn_from_bytes_zero_beats", pkt.beats.size(), 1);
    check_int("txn_from_bytes_zero_keep", int'(pkt.beats[0].keep), 0);

    // 增量构造（REQ-TXN-002）
    pkt = axi4_stream_packet_item::type_id::create("pkt3");
    beat = axi4_stream_beat_item::type_id::create("b1");
    pkt.append_beat(beat);
    check_int("txn_append_beat", pkt.beats.size(), 1);

    // ---------------- 完成状态枚举（REQ-TXN-004）----------------
    begin
      axis_txn_status_e st;
      st = AXIS_ST_ACCEPTED;             check_str("txn_status_accepted", st.name(), "AXIS_ST_ACCEPTED");
      st = AXIS_ST_ABORTED_BY_RESET;     check_str("txn_status_abort", st.name(), "AXIS_ST_ABORTED_BY_RESET");
      st = AXIS_ST_CANCELED_BEFORE_VALID;check_str("txn_status_cancel", st.name(), "AXIS_ST_CANCELED_BEFORE_VALID");
      st = AXIS_ST_WATCHDOG_EXPIRED;     check_str("txn_status_watchdog", st.name(), "AXIS_ST_WATCHDOG_EXPIRED");
      st = AXIS_ST_REJECTED_CONFIG;      check_str("txn_status_reject", st.name(), "AXIS_ST_REJECTED_CONFIG");
    end

    // ---------------- ready policy 字段（REQ-SNK-001）----------------
    r = axi4_stream_ready_item::type_id::create("ready");
    r.mode = AXIS_READY_FIXED_DELAY; r.delay = 0;
    check_int("txn_ready_delay_zero", r.delay, 0);
    r.mode = AXIS_READY_PERIODIC; r.high_cycles = 2; r.low_cycles = 3;
    check_int("txn_ready_periodic_hi", r.high_cycles, 2);
    check_int("txn_ready_periodic_lo", r.low_cycles, 3);
    check_str("txn_ready_mode_name", r.mode.name(), "AXIS_READY_PERIODIC");
    begin
      axis_ready_mode_e rm;
      rm = AXIS_READY_ALWAYS;       check_str("txn_ready_always_name", rm.name(), "AXIS_READY_ALWAYS");
      rm = AXIS_READY_WAIT_VALID;   check_str("txn_ready_wait_valid_name", rm.name(), "AXIS_READY_WAIT_VALID");
      rm = AXIS_READY_BUFFER_MODEL; check_str("txn_ready_buffer_name", rm.name(), "AXIS_READY_BUFFER_MODEL");
      rm = AXIS_READY_SCRIPTED;     check_str("txn_ready_scripted_name", rm.name(), "AXIS_READY_SCRIPTED");
    end

    // ---------------- observed beat 四态保留与快照独立（REQ-MON-007/REQ-TXN-007）----
    obs = axi4_stream_observed_beat::type_id::create("obs");
    obs.data = '0; obs.data[7:0] = 8'hx0;
    obs.keep = 8'h01; obs.strb = 8'h01;
    obs.last = 1'b0; obs.id = 32'h5; obs.dest = 32'h6;
    obs.interface_id = 0; obs.reset_epoch = 1; obs.cycle = 42;
    obs.handshake = 1'b1; obs.wait_cycles = 2;
    check_true("txn_obs_x_preserved", (obs.data[7:0] === 8'hx0));
    obs_clone = obs.clone_beat();
    check_int("txn_obs_clone_cycle", int'(obs_clone.cycle), 42);
    check_bit("txn_obs_clone_hs", obs_clone.handshake, 1'b1);
    obs.id = 32'h99;
    check_int("txn_obs_clone_independent", int'(obs_clone.id), 32'h5);

    // ---------------- error event 字段（REQ-TXN-001）----------------
    ev = axi4_stream_error_event::type_id::create("ev");
    ev.rule_id = "AXIS-P004"; ev.category = "PROTOCOL";
    ev.severity = axi4_stream_types_pkg::AXIS_SEV_ERROR;
    ev.interface_id = 0; ev.reset_epoch = 0; ev.cycle = 10;
    ev.key.tid = 1; ev.key.tdest = 0;
    ev.packet_beat_index = 3;
    ev.before_sample = "data=00"; ev.after_sample = "data=ff";
    check_str("txn_err_rule", ev.rule_id, "AXIS-P004");
    check_str("txn_err_category", ev.category, "PROTOCOL");
    check_int("txn_err_beat_index", ev.packet_beat_index, 3);
    check_true("txn_err_str", ev.convert2string() != "");

    // ---------------- observed packet 汇总字段（REQ-MON-003）----------------
    opkt = axi4_stream_observed_packet::type_id::create("opkt");
    opkt.key.tid = 7; opkt.key.tdest = 1;
    opkt.data_byte_count = 5; opkt.position_byte_count = 2; opkt.null_byte_count = 1;
    opkt.end_kind = AXIS_END_TLAST;
    check_int("txn_opkt_data", opkt.data_byte_count, 5);
    check_int("txn_opkt_pos", opkt.position_byte_count, 2);
    check_int("txn_opkt_null", opkt.null_byte_count, 1);
    check_str("txn_opkt_end_name", opkt.end_kind.name(), "AXIS_END_TLAST");
    check_str("txn_opkt_key_str", axi4_stream_pkg::axis_key_string(opkt.key), "(tid=7,dest=1)");
    check_true("txn_key_equal", axi4_stream_pkg::axis_key_equal(opkt.key, opkt.key));
    begin
      axis_end_kind_e ek;
      ek = AXIS_END_SYNTHETIC; check_str("txn_end_synthetic_name", ek.name(), "AXIS_END_SYNTHETIC");
    end

    $display("transaction: PASS=%0d FAIL=%0d", PASS_CNT, FAIL_CNT);
  end

endmodule : axi4_stream_unit_transaction

`endif // AXI4_STREAM_UNIT_TRANSACTION__SV
