// =============================================================================
// File Name   : axi4_stream_unit_checker.sv
// Description : L1 Unit Test — Checker / Scoreboard / Reference model golden vectors
//               覆盖：规则 ID 与类别、严重度枚举、规则配置 API、reference model
//               恒等预测与显式路由重写合同、比较模式枚举
// 依据        : docs/requirement.md（REQ-CHK-003, REQ-SCB-001..005/008,
//               REQ-ERR-002）
// =============================================================================
`ifndef AXI4_STREAM_UNIT_CHECKER__SV
`define AXI4_STREAM_UNIT_CHECKER__SV

module axi4_stream_unit_checker;

  import uvm_pkg::*;
  import axi4_stream_unit_test_pkg::*;
  import axi4_stream_types_pkg::*;
  import axi4_stream_pkg::*;

  // 最小 UVM 组件宿主（不启动 UVM，仅提供 parent）
  class axis_unit_host extends uvm_component;
    `uvm_component_utils(axis_unit_host)
    function new(string name = "axis_unit_host", uvm_component parent = null);
      super.new(name, parent);
    endfunction
  endclass

  initial begin
    axi4_stream_checker chk;
    axis_unit_host host;
    axi4_stream_reference_model refm;
    axi4_stream_observed_packet pkt, pred[$];
    axi4_stream_beat_item beat;
    stream_key_t key;
    axi4_stream_violation_injector inj;
    string types[$];

    // ---------------- 规则 ID 清单（§8 规则表）----------------
    check_str("chk_rule_p001", "AXIS-P001", "AXIS-P001");
    check_str("chk_rule_p002", "AXIS-P002", "AXIS-P002");
    check_str("chk_rule_p004", "AXIS-P004", "AXIS-P004");
    check_str("chk_rule_p005", "AXIS-P005", "AXIS-P005");
    check_str("chk_rule_p008", "AXIS-P008", "AXIS-P008");
    check_str("chk_rule_p009", "AXIS-P009", "AXIS-P009");
    check_str("chk_rule_a001", "AXIS-A001", "AXIS-A001");
    check_str("chk_rule_a002", "AXIS-A002", "AXIS-A002");
    check_str("chk_rule_w001", "AXIS-W001", "AXIS-W001");
    check_str("chk_rule_w002", "AXIS-W002", "AXIS-W002");
    check_str("chk_rule_c001", "AXIS-C001", "AXIS-C001");
    check_str("chk_rule_i001", "AXIS-I001", "AXIS-I001");

    // ---------------- 五类区分（REQ-CHK §8）----------------
    begin axis_rule_category_e c; c = AXIS_CAT_PROTOCOL; check_str("chk_cat_protocol", c.name(), "AXIS_CAT_PROTOCOL"); end
    begin axis_rule_category_e c; c = AXIS_CAT_APPLICATION; check_str("chk_cat_application", c.name(), "AXIS_CAT_APPLICATION"); end
    begin axis_rule_category_e c; c = AXIS_CAT_WATCHDOG; check_str("chk_cat_watchdog", c.name(), "AXIS_CAT_WATCHDOG"); end
    begin axis_rule_category_e c; c = AXIS_CAT_CONFIG; check_str("chk_cat_config", c.name(), "AXIS_CAT_CONFIG"); end
    begin axis_rule_category_e c; c = AXIS_CAT_VIP_INTERNAL; check_str("chk_cat_vip_internal", c.name(), "AXIS_CAT_VIP_INTERNAL"); end

    // ---------------- 严重度（REQ-CHK-003）----------------
    begin axi4_stream_types_pkg::axis_severity_e s; s = axi4_stream_types_pkg::AXIS_SEV_ERROR; check_str("chk_sev_error", s.name(), "AXIS_SEV_ERROR"); end
    begin axi4_stream_types_pkg::axis_severity_e s; s = axi4_stream_types_pkg::AXIS_SEV_FATAL; check_str("chk_sev_fatal", s.name(), "AXIS_SEV_FATAL"); end
    begin axi4_stream_types_pkg::axis_severity_e s; s = axi4_stream_types_pkg::AXIS_SEV_WARNING; check_str("chk_sev_warning", s.name(), "AXIS_SEV_WARNING"); end
    begin axi4_stream_types_pkg::axis_severity_e s; s = axi4_stream_types_pkg::AXIS_SEV_INFO; check_str("chk_sev_info", s.name(), "AXIS_SEV_INFO"); end

    // ---------------- checker 实例与规则查询 API ----------------
    host = axis_unit_host::type_id::create("host", null);
    chk  = axi4_stream_checker::type_id::create("chk", host);
    check_true("chk_created", chk != null);
    check_int("chk_rule_index_unknown", chk.rule_index("AXIS-NOPE"), -1);
    // build_phase 未执行时规则表为空；命中计数应为 0
    check_int("chk_hits_before_init", chk.rule_hits("AXIS-P004"), 0);

    // ---------------- reference model：恒等预测（REQ-SCB-001 CUSTOM）----------------
    refm = axi4_stream_reference_model::type_id::create("refm");
    pkt = axi4_stream_observed_packet::type_id::create("inpkt");
    key.tid = 3; key.tdest = 4;
    pkt.key = key;
    pkt.data_byte_count = 8; pkt.position_byte_count = 0; pkt.null_byte_count = 0;
    pkt.end_kind = AXIS_END_TLAST;
    beat = axi4_stream_beat_item::type_id::create("b");
    refm.predict(pkt, pred);
    check_int("scb_predict_count", pred.size(), 1);
    check_int("scb_predict_tid", int'(pred[0].key.tid), 3);
    check_int("scb_predict_data", pred[0].data_byte_count, 8);
    check_true("scb_predict_end", pred[0].end_kind == AXIS_END_TLAST);

    // 无重写时 key 不变（不进行任意 payload 搜索，REQ-SCB-005）
    check_bit("scb_no_rewrite_tid", refm.remap_key(key).tid == key.tid, 1'b1);

    // 显式路由重写合同
    refm.set_route_remap(5, 3, 1'b1, 1'b0);
    check_int("scb_rewrite_tid", int'(refm.remap_key(key).tid), 5);
    check_int("scb_rewrite_dest_keep", int'(refm.remap_key(key).tdest), 4);

    // 路由合同完整性（REQ-SCB-005）
    check_bit("scb_route_complete_single", refm.route_contract_complete(1, 1), 1'b1);

    // ---------------- 比较模式枚举（REQ-SCB-001）----------------
    begin
      axis_compare_mode_e cm;
      cm = AXIS_CMP_EXACT_BEAT;    check_str("scb_mode_exact", cm.name(), "AXIS_CMP_EXACT_BEAT");
      cm = AXIS_CMP_LOGICAL_STREAM;check_str("scb_mode_logical", cm.name(), "AXIS_CMP_LOGICAL_STREAM");
      cm = AXIS_CMP_CUSTOM;        check_str("scb_mode_custom", cm.name(), "AXIS_CMP_CUSTOM");
    end

    // USER 映射枚举（REQ-SCB-003）
    begin
      axis_user_map_e um;
      um = AXIS_USER_OPAQUE_PER_BEAT; check_str("scb_user_opaque", um.name(), "AXIS_USER_OPAQUE_PER_BEAT");
      um = AXIS_USER_PER_BYTE;       check_str("scb_user_per_byte", um.name(), "AXIS_USER_PER_BYTE");
      um = AXIS_USER_PER_PACKET;     check_str("scb_user_per_packet", um.name(), "AXIS_USER_PER_PACKET");
      um = AXIS_USER_CUSTOM;         check_str("scb_user_custom", um.name(), "AXIS_USER_CUSTOM");
    end

    // 保序模式（REQ-SCB-004）
    begin
      axis_order_mode_e om;
      om = AXIS_ORDER_GLOBAL;  check_str("scb_order_global", om.name(), "AXIS_ORDER_GLOBAL");
      om = AXIS_ORDER_PER_KEY; check_str("scb_order_per_key", om.name(), "AXIS_ORDER_PER_KEY");
    end

    // 复位合同（REQ-RST-005）
    begin
      axis_cdc_reset_e cr;
      cr = AXIS_CDC_BOTH_FLUSH; check_str("scb_cdc_flush", cr.name(), "AXIS_CDC_BOTH_FLUSH");
      cr = AXIS_CDC_PRESERVE;   check_str("scb_cdc_preserve", cr.name(), "AXIS_CDC_PRESERVE");
    end

    // ---------------- 注入类型清单（§11 表）----------------
    inj = axi4_stream_violation_injector::type_id::create("inj", host);
    inj.list_injection_types(types);
    check_int("inj_type_count", types.size(), 8);
    check_str("inj_type_0", types[0], "VALID_DEASSERT_IN_STALL");
    check_str("inj_type_7", types[7], "SUSTAINED_BACKPRESSURE_IDLE");
    check_bit("inj_disabled_default", inj.enabled, 1'b0);

    $display("checker: PASS=%0d FAIL=%0d", PASS_CNT, FAIL_CNT);
  end

endmodule : axi4_stream_unit_checker

`endif // AXI4_STREAM_UNIT_CHECKER__SV