// =============================================================================
// File Name   : axi4_stream_unit_config.sv
// Description : L1 Unit Test — 配置对象 golden vectors
//               覆盖：缺省值、byte lanes、profile、语义 epoch、比较/复位/覆盖合同
// 依据        : docs/requirement.md（REQ-CFG-001..007, REQ-SCB-003/004,
//               REQ-INT-003, REQ-RST-002/005, REQ-COV-003）
// =============================================================================
`ifndef AXI4_STREAM_UNIT_CONFIG__SV
`define AXI4_STREAM_UNIT_CONFIG__SV

module axi4_stream_unit_config;

  import uvm_pkg::*;
  import axi4_stream_unit_test_pkg::*;
  import axi4_stream_types_pkg::*;
  import axi4_stream_pkg::*;

  initial begin
    axi4_stream_config cfg;

    // ---------------- 缺省值（REQ-CFG-001 表）----------------
    cfg = axi4_stream_config::type_id::create("cfg");
    check_int("cfg_default_data_width", cfg.data_width, 64);
    check_bit("cfg_default_has_tdata", cfg.has_tdata, 1'b1);
    check_bit("cfg_default_has_tready", cfg.has_tready, 1'b1);
    check_bit("cfg_default_has_tkeep", cfg.has_tkeep, 1'b1);
    check_bit("cfg_default_has_tstrb", cfg.has_tstrb, 1'b0);
    check_bit("cfg_default_has_tlast", cfg.has_tlast, 1'b1);
    check_int("cfg_default_id_width", cfg.id_width, 0);
    check_int("cfg_default_dest_width", cfg.dest_width, 0);
    check_int("cfg_default_user_width", cfg.user_width, 0);
    check_int("cfg_default_open_streams", cfg.max_open_streams, 256);
    check_int("cfg_default_packet_beats", cfg.max_packet_beats, 65536);
    check_int("cfg_default_ready_wait", cfg.max_ready_wait, 0);
    check_int("cfg_default_packet_idle", cfg.max_packet_idle, 0);
    check_true("cfg_default_compare", cfg.compare_mode == AXIS_CMP_EXACT_BEAT);
    check_true("cfg_default_packet_mode", cfg.packet_mode == AXIS_PKT_TLAST);
    check_true("cfg_default_order", cfg.order_mode == AXIS_ORDER_GLOBAL);
    check_true("cfg_default_capture", cfg.capture_mode == AXIS_CAPTURE_FULL);
    check_bit("cfg_default_reset_flush", cfg.reset_retain_queued, 1'b0);
    check_int("cfg_default_epoch", cfg.configuration_epoch, 0);
    check_int("cfg_default_byte_lanes", cfg.byte_lanes(), 8);
    check_int("cfg_default_queue_depth", cfg.max_queue_depth, 64);
    check_bit("cfg_default_role_not_configured", cfg.role_configured, 1'b0);
    check_bit("cfg_default_pkt_mode_not_configured", cfg.packet_mode_configured, 1'b0);

    // 非 2 的幂宽度 byte lanes（REQ-CFG-001）
    cfg.data_width = 24;
    check_int("cfg_lanes_24", cfg.byte_lanes(), 3);
    cfg.data_width = 40;
    check_int("cfg_lanes_40", cfg.byte_lanes(), 5);
    cfg.data_width = 96;
    check_int("cfg_lanes_96", cfg.byte_lanes(), 12);
    cfg.data_width = 4096;
    check_int("cfg_lanes_4096", cfg.byte_lanes(), 512);

    // ---------------- profile（§7.5）----------------
    cfg = axi4_stream_config::type_id::create("cfg2");
    cfg.apply_profile(AXIS_PROFILE_STRESS);
    check_true("cfg_profile_stress", cfg.profile == AXIS_PROFILE_STRESS);
    check_true("cfg_profile_stress_capture", cfg.capture_mode == AXIS_CAPTURE_STREAMING);
    check_int("cfg_profile_stress_beats", cfg.max_packet_beats, 1000000);

    cfg.apply_profile(AXIS_PROFILE_PASSIVE);
    check_true("cfg_profile_passive_role", cfg.role == AXIS_ROLE_PASSIVE);
    check_bit("cfg_profile_passive_configured", cfg.role_configured, 1'b1);

    cfg.apply_profile(AXIS_PROFILE_HEAVY_BACKPRESSURE);
    check_int("cfg_profile_heavy_queue", cfg.max_queue_depth, 256);

    // ---------------- 语义配置更新需 drain（REQ-INT-003）----------------
    cfg = axi4_stream_config::type_id::create("cfg3");
    check_int("cfg_epoch_before", cfg.configuration_epoch, 0);
    cfg.begin_semantic_update(1'b1);
    check_int("cfg_epoch_after_drained", cfg.configuration_epoch, 1);
    cfg.begin_semantic_update(1'b1);
    check_int("cfg_epoch_after_two", cfg.configuration_epoch, 2);

    // ---------------- 比较合同（REQ-SCB-003/004）----------------
    cfg = axi4_stream_config::type_id::create("cfg4");
    check_true("cfg_user_map_default", cfg.user_map == AXIS_USER_OPAQUE_PER_BEAT);
    check_bit("cfg_user_compare_default", cfg.user_compare_enable, 1'b1);
    cfg.user_map = AXIS_USER_PER_BYTE;
    check_true("cfg_user_map_per_byte", cfg.user_map == AXIS_USER_PER_BYTE);
    cfg.user_map = AXIS_USER_PER_PACKET;
    check_true("cfg_user_map_per_packet", cfg.user_map == AXIS_USER_PER_PACKET);
    cfg.user_map = AXIS_USER_CUSTOM;
    check_true("cfg_user_map_custom", cfg.user_map == AXIS_USER_CUSTOM);
    cfg.order_mode = AXIS_ORDER_PER_KEY;
    check_true("cfg_order_per_key", cfg.order_mode == AXIS_ORDER_PER_KEY);
    check_int("cfg_width_ratio_default", cfg.width_ratio, 1);

    // ---------------- 复位合同（REQ-RST-002 / REQ-RST-005）----------------
    cfg = axi4_stream_config::type_id::create("cfg5");
    check_true("cfg_cdc_default", cfg.cdc_reset == AXIS_CDC_BOTH_FLUSH);
    check_bit("cfg_cdc_not_configured_default", cfg.cdc_reset_configured, 1'b0);
    cfg.reset_retain_queued = 1'b1;
    check_bit("cfg_reset_retain", cfg.reset_retain_queued, 1'b1);
    cfg.cdc_reset = AXIS_CDC_PRESERVE;
    check_true("cfg_cdc_preserve", cfg.cdc_reset == AXIS_CDC_PRESERVE);

    // ---------------- 覆盖裁剪开关（REQ-COV-003）----------------
    cfg = axi4_stream_config::type_id::create("cfg6");
    check_bit("cfg_cov_handshake_default", cfg.cov_handshake_enable, 1'b1);
    check_bit("cfg_cov_packet_default", cfg.cov_packet_enable, 1'b1);
    check_bit("cfg_cov_qualifier_default", cfg.cov_qualifier_enable, 1'b1);
    check_bit("cfg_cov_stream_default", cfg.cov_stream_enable, 1'b1);
    check_bit("cfg_cov_sideband_default", cfg.cov_sideband_enable, 1'b1);
    check_bit("cfg_cov_reset_default", cfg.cov_reset_enable, 1'b1);
    check_bit("cfg_cov_errors_default", cfg.cov_errors_enable, 1'b1);
    check_bit("cfg_cov_transform_default", cfg.cov_transform_enable, 1'b1);
    cfg.cov_reset_enable = 1'b0;
    check_bit("cfg_cov_reset_off", cfg.cov_reset_enable, 1'b0);

    // ---------------- 检查/抓取开关 ----------------
    cfg = axi4_stream_config::type_id::create("cfg7");
    check_bit("cfg_check_default", cfg.check_enable, 1'b1);
    check_bit("cfg_coverage_default", cfg.coverage_enable, 1'b1);
    check_true("cfg_capture_default", cfg.capture_mode == AXIS_CAPTURE_FULL);

    // ---------------- 角色与组包模式（REQ-CFG-001/003）----------------
    cfg = axi4_stream_config::type_id::create("cfg8");
    begin
      axis_role_e rr;
      axis_packet_mode_e pm;
      rr = AXIS_ROLE_SOURCE;  check_str("cfg_role_source", rr.name(), "AXIS_ROLE_SOURCE");
      rr = AXIS_ROLE_SINK;    check_str("cfg_role_sink", rr.name(), "AXIS_ROLE_SINK");
      rr = AXIS_ROLE_PASSIVE; check_str("cfg_role_passive", rr.name(), "AXIS_ROLE_PASSIVE");
      pm = AXIS_PKT_TLAST;    check_str("cfg_pkt_tlast", pm.name(), "AXIS_PKT_TLAST");
      pm = AXIS_PKT_CONTINUOUS; check_str("cfg_pkt_continuous", pm.name(), "AXIS_PKT_CONTINUOUS");
      pm = AXIS_PKT_FIXED_BEATS; check_str("cfg_pkt_fixed", pm.name(), "AXIS_PKT_FIXED_BEATS");
    end

    check_true("cfg_str", cfg.convert2string() != "");

    $display("config: PASS=%0d FAIL=%0d", PASS_CNT, FAIL_CNT);
  end

endmodule : axi4_stream_unit_config

`endif // AXI4_STREAM_UNIT_CONFIG__SV
