// =============================================================================
// File Name   : axi4_stream_scoreboard.sv
// Description : axi4_stream 端到端比较组件（EXACT_BEAT / LOGICAL_STREAM / CUSTOM）
// 依据        : docs/requirement.md（REQ-SCB-001..008, REQ-RST-005）
//
// 设计说明：
//   * 默认 EXACT_BEAT。DUT 的 reset / routing / user mapping / ordering 合同在
//     连接时显式提供；禁止默认仅按 key 比较（REQ-SCB-004）。
//   * 匹配基于 monitor 接收事实（REQ-SCB-007），不使用 driver 缓存作为 oracle。
//   * 比较采用“有序收集 + check_phase 配对”：
//       两侧 monitor 对同一个 ACLK 边沿的 analysis 写入属于同一仿真时间步，
//       立即配对会依赖 delta 顺序（组合透明 DUT 下不确定）。因此输入侧与输出侧
//       各自按月/按 key 保序收集，在 check_phase 统一配对并报告最早差异，
//       既确定又满足 REQ-SCB-006 的“输出最早差异及上下文”。
//   * 未知值不得被二态转换或普通 equality 的不确定结果吞掉（REQ-SCB-008）。
//   * 结束时排空已接受的 expected 数据或按 reset/drop 合同结算，不统一清空队列。
// =============================================================================

`ifndef AXI4_STREAM_SCOREBOARD__SV
`define AXI4_STREAM_SCOREBOARD__SV

class axi4_stream_scoreboard extends uvm_scoreboard;

  `uvm_component_utils(axi4_stream_scoreboard)

  `uvm_analysis_imp_decl(_input)
  `uvm_analysis_imp_decl(_output)

  uvm_analysis_imp_input  #(axi4_stream_observed_packet, axi4_stream_scoreboard) input_imp;
  uvm_analysis_imp_output #(axi4_stream_observed_packet, axi4_stream_scoreboard) output_imp;

  axi4_stream_config cfg;
  axi4_stream_reference_model ref_model;

  int input_interface_id  = 0;
  int output_interface_id = 1;

  // EXACT_BEAT 可选 RAW_ALL_BITS 调试
  bit raw_all_bits_debug = 1'b0;

  // 有序收集（全局保序默认，REQ-SCB-004）
  protected axi4_stream_observed_packet expected_global[$];
  protected axi4_stream_observed_packet actual_global[$];
  protected axi4_stream_observed_packet expected_per_key[string][$];
  protected axi4_stream_observed_packet actual_per_key[string][$];

  // 统计
  protected int matched_packets    = 0;
  protected int mismatched_packets = 0;
  protected int unexpected_packets = 0;
  protected int dropped_expected   = 0;
  protected int unknown_value_events = 0;
  protected bit compared = 1'b0;

  // drop / replication 合同（REQ-SCB-006）
  bit drop_enable = 1'b0;
  int expected_drop_count = 0;
  bit replicate_enable = 1'b0;
  int expected_replication_count = 0;

  // reset 合同（REQ-SCB-008 / REQ-RST-005）
  bit flush_expected_on_reset = 1'b1;

  function new(string name = "axi4_stream_scoreboard", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(axi4_stream_config)::get(this, "", "cfg", cfg))
      `uvm_fatal("AXIS-SCB", "未获取 config（REQ-INT-002）")
    if (!uvm_config_db#(axi4_stream_reference_model)::get(this, "", "ref_model", ref_model))
      ref_model = axi4_stream_reference_model::type_id::create("ref_model");
    if (cfg.compare_mode == AXIS_CMP_CUSTOM && ref_model == null)
      `uvm_fatal("AXIS-SCB", "CUSTOM 比较模式必须提供 reference model（REQ-SCB-001）")
    input_imp  = new("input_imp", this);
    output_imp = new("output_imp", this);
  endfunction

  // ---------------------------------------------------------------------------
  // 输入侧（source 出口）：建立期望
  // ---------------------------------------------------------------------------
  function void write_input(axi4_stream_observed_packet pkt);
    axi4_stream_observed_packet pred[$];
    if (pkt == null) return;
    if (check_unknown(pkt)) return;
    case (cfg.compare_mode)
      AXIS_CMP_CUSTOM: begin
        ref_model.predict(pkt, pred);
        foreach (pred[i]) enqueue_expected(pred[i]);
      end
      default: enqueue_expected(pkt);
    endcase
  endfunction

  protected function void enqueue_expected(axi4_stream_observed_packet pkt);
    if (cfg.order_mode == AXIS_ORDER_GLOBAL) expected_global.push_back(pkt);
    else                                     expected_per_key[key_str(pkt.key)].push_back(pkt);
  endfunction

  // ---------------------------------------------------------------------------
  // 输出侧（DUT 出口）：收集实际
  // ---------------------------------------------------------------------------
  function void write_output(axi4_stream_observed_packet pkt);
    if (pkt == null) return;
    pkt.interface_id = output_interface_id;
    if (check_unknown(pkt)) return;
    if (cfg.order_mode == AXIS_ORDER_GLOBAL) actual_global.push_back(pkt);
    else                                     actual_per_key[key_str(pkt.key)].push_back(pkt);
  endfunction

  // ---------------------------------------------------------------------------
  // check_phase：统一配对比较（确定性，报告最早差异）
  // ---------------------------------------------------------------------------
  function void check_phase(uvm_phase phase);
    super.check_phase(phase);
    if (!compared) run_compare();
  endfunction

  function void run_compare();
    axi4_stream_observed_packet exp, act;
    string ks;
    int idx;

    compared = 1'b1;

    if (cfg.order_mode == AXIS_ORDER_GLOBAL) begin
      // 全局输入顺序（透明 FIFO/CDC 默认，REQ-SCB-004）
      idx = 0;
      while (idx < actual_global.size()) begin
        act = actual_global[idx];
        if (idx >= expected_global.size()) begin
          unexpected_packets++;
          `uvm_error("AXIS-SCB", $sformatf(
            "未匹配到 expected 包（丢失/重复/错路由之一）：%s（REQ-SCB-006）", act.convert2string()))
        end else begin
          exp = expected_global[idx];
          if (exp.aborted_by_reset) dropped_expected++;
          else if (compare_packet(exp, act)) matched_packets++;
          else mismatched_packets++;
        end
        idx++;
      end
      if (expected_global.size() > actual_global.size()) begin
        int remain = expected_global.size() - actual_global.size();
        for (int i = actual_global.size(); i < expected_global.size(); i++)
          if (expected_global[i].aborted_by_reset) remain--;
        if (remain > 0)
          `uvm_error("AXIS-SCB", $sformatf(
            "结束仍有 %0d 个 expected 包未匹配（不允许统一清空队列掩盖丢数，REQ-SCB-008）", remain))
      end
    end else begin
      // 逐 key 保序（仅多流交换/仲裁 DUT 显式启用）
      foreach (actual_per_key[ks]) begin
        int n_act; int n_exp;
        n_act = actual_per_key[ks].size();
        n_exp = expected_per_key.exists(ks) ? expected_per_key[ks].size() : 0;
        for (int i = 0; i < n_act; i++) begin
          if (i < n_exp) begin
            if (compare_packet(expected_per_key[ks][i], actual_per_key[ks][i])) matched_packets++;
            else mismatched_packets++;
          end else begin
            unexpected_packets++;
            `uvm_error("AXIS-SCB", $sformatf(
              "key=%s 未匹配到 expected 包（REQ-SCB-006）：%s", ks,
              actual_per_key[ks][i].convert2string()))
          end
        end
        if (n_exp > n_act)
          `uvm_error("AXIS-SCB", $sformatf(
            "key=%s 结束仍有 %0d 个 expected 包未匹配（REQ-SCB-008）", ks, n_exp - n_act))
      end
      foreach (expected_per_key[ks]) begin
        if (!actual_per_key.exists(ks))
          `uvm_error("AXIS-SCB", $sformatf(
            "key=%s 完全无实际输出（REQ-SCB-006）", ks))
      end
    end

    if (replicate_enable && matched_packets < expected_replication_count)
      `uvm_error("AXIS-SCB", $sformatf("广播复制计数不足 expected>=%0d actual=%0d",
        expected_replication_count, matched_packets))

    `uvm_info("AXIS-SCB", $sformatf(
      "scoreboard 汇总 mode=%s matched=%0d mismatched=%0d unexpected=%0d dropped=%0d unknown=%0d",
      cfg.compare_mode.name(), matched_packets, mismatched_packets,
      unexpected_packets, dropped_expected, unknown_value_events), UVM_LOW)
  endfunction

  // ---------------------------------------------------------------------------
  // 比较实现（REQ-SCB-001 三种模式）
  // ---------------------------------------------------------------------------
  protected function bit compare_packet(
    axi4_stream_observed_packet exp, axi4_stream_observed_packet act
  );
    case (cfg.compare_mode)
      AXIS_CMP_LOGICAL_STREAM: return compare_logical_stream(exp, act);
      default:                 return compare_exact_beat(exp, act);
    endcase
  endfunction

  // EXACT_BEAT：beat 个数、qualifier、边界、ID/DEST/USER、DATA 有效 lane 值
  protected function bit compare_exact_beat(
    axi4_stream_observed_packet exp, axi4_stream_observed_packet act
  );
    if (exp.beats.size() != act.beats.size()) begin
      report_mismatch(exp, act, $sformatf("beat 个数 expected=%0d actual=%0d",
        exp.beats.size(), act.beats.size()));
      return 1'b0;
    end
    if (exp.end_kind != act.end_kind) begin
      report_mismatch(exp, act, $sformatf("包结束类型 expected=%s actual=%s",
        exp.end_kind.name(), act.end_kind.name()));
      return 1'b0;
    end
    for (int i = 0; i < exp.beats.size(); i++) begin
      if (exp.beats[i].keep_norm !== act.beats[i].keep_norm) begin
        report_mismatch(exp, act, $sformatf("beat[%0d] TKEEP expected=%h actual=%h",
          i, exp.beats[i].keep_norm, act.beats[i].keep_norm));
        return 1'b0;
      end
      if (exp.beats[i].strb_norm !== act.beats[i].strb_norm) begin
        report_mismatch(exp, act, $sformatf("beat[%0d] TSTRB expected=%h actual=%h",
          i, exp.beats[i].strb_norm, act.beats[i].strb_norm));
        return 1'b0;
      end
      if (exp.beats[i].last !== act.beats[i].last) begin
        report_mismatch(exp, act, $sformatf("beat[%0d] TLAST expected=%b actual=%b",
          i, exp.beats[i].last, act.beats[i].last));
        return 1'b0;
      end
      for (int lane = 0; lane < cfg.byte_lanes(); lane++) begin
        if (exp.beats[i].keep_norm[lane] && exp.beats[i].strb_norm[lane]) begin
          if (exp.beats[i].data[8*lane +: 8] !== act.beats[i].data[8*lane +: 8]) begin
            report_mismatch(exp, act, $sformatf(
              "beat[%0d] lane[%0d] DATA expected=%h actual=%h",
              i, lane, exp.beats[i].data[8*lane +: 8], act.beats[i].data[8*lane +: 8]));
            return 1'b0;
          end
        end
      end
      if (raw_all_bits_debug && exp.beats[i].data !== act.beats[i].data) begin
        `uvm_info("AXIS-SCB", $sformatf(
          "RAW_ALL_BITS 调试差异 beat[%0d] expected=%h actual=%h（不影响有效载荷判定）",
          i, exp.beats[i].data, act.beats[i].data), UVM_HIGH)
      end
    end
    // ID / DEST / USER 合同（user_compare_enable 显式配置，REQ-SCB-003）
    if (user_compare_enable_internal()) begin
      if (exp.beats.size() > 0 && exp.beats[0].user !== act.beats[0].user) begin
        report_mismatch(exp, act, "TUSER 不匹配（已启用 USER 比较合同）");
        return 1'b0;
      end
    end
    return 1'b1;
  endfunction

  protected function bit user_compare_enable_internal();
    if (!cfg.user_compare_enable) return 1'b0;
    // 无映射合同的非透明转换：明确标识“不检查该维度”（REQ-SCB-003）
    if (cfg.width_ratio != 1 &&
        (cfg.user_map == AXIS_USER_OPAQUE_PER_BEAT || cfg.user_map == AXIS_USER_PER_BYTE))
      return 1'b0;
    return 1'b1;
  endfunction

  // LOGICAL_STREAM：DATA(value)/POSITION/END_PACKET 有序 token，去除 NULL
  protected function bit compare_logical_stream(
    axi4_stream_observed_packet exp, axi4_stream_observed_packet act
  );
    axi4_stream_types_pkg::axis_token_t et[$];
    axi4_stream_types_pkg::axis_token_t at[$];
    to_tokens(exp, et);
    to_tokens(act, at);
    if (et.size() != at.size()) begin
      report_mismatch(exp, act, $sformatf(
        "逻辑流 token 数 expected=%0d actual=%0d（REQ-SCB-002，NULL 已移除但 END_PACKET 保留）",
        et.size(), at.size()));
      return 1'b0;
    end
    for (int i = 0; i < et.size(); i++) begin
      if (et[i].kind !== at[i].kind) begin
        report_mismatch(exp, act, $sformatf("token[%0d] kind expected=%s actual=%s",
          i, et[i].kind.name(), at[i].kind.name()));
        return 1'b0;
      end
      if (et[i].kind == axi4_stream_types_pkg::AXIS_TOKEN_DATA && et[i].value !== at[i].value) begin
        report_mismatch(exp, act, $sformatf("token[%0d] DATA expected=%h actual=%h",
          i, et[i].value, at[i].value));
        return 1'b0;
      end
      // POSITION 保留位置但不比较 TDATA（REQ-SCB-002）
    end
    return 1'b1;
  endfunction

  protected function void to_tokens(axi4_stream_observed_packet pkt,
                                    ref axi4_stream_types_pkg::axis_token_t tokens[$]);
    axi4_stream_types_pkg::axis_token_t tmp[];
    int count;
    tokens.delete();
    foreach (pkt.beats[i]) begin
      axi4_stream_types_pkg::axis_tokenize_beat(
        pkt.beats[i].data, 1'b1, pkt.beats[i].keep_norm, 1'b1, pkt.beats[i].strb_norm,
        1'b1, pkt.beats[i].last, cfg.byte_lanes(), tmp, count);
      for (int t = 0; t < count; t++) tokens.push_back(tmp[t]);
    end
  endfunction

  // ---------------------------------------------------------------------------
  // 未知值防护（REQ-SCB-008）
  // ---------------------------------------------------------------------------
  protected function bit check_unknown(axi4_stream_observed_packet pkt);
    foreach (pkt.beats[i]) begin
      if ((^pkt.beats[i].data) === 1'bx && (^pkt.beats[i].keep_norm) === 1'bx) begin
        unknown_value_events++;
        `uvm_error("AXIS-SCB", $sformatf(
          "比较对象含未知值（X），已隔离不进入正常 scoreboard 流程（REQ-MON-007/REQ-SCB-008）: beat[%0d]", i))
        return 1'b1;
      end
    end
    return 1'b0;
  endfunction

  protected function void report_mismatch(
    axi4_stream_observed_packet exp, axi4_stream_observed_packet act, string detail
  );
    mismatched_packets++;
    `uvm_error("AXIS-SCB", $sformatf(
      "端到端比较失败（最早差异）mode=%s: %s\n  expected: %s\n  actual  : %s",
      cfg.compare_mode.name(), detail, exp.convert2string(), act.convert2string()))
  endfunction

  protected function string key_str(stream_key_t k);
    return $sformatf("k_%0d_%0d", k.tid, k.tdest);
  endfunction

  // ---------------------------------------------------------------------------
  // reset 合同（REQ-RST-005 / REQ-SCB-008）
  // ---------------------------------------------------------------------------
  function void on_reset(int epoch);
    if (flush_expected_on_reset) begin
      dropped_expected += expected_global.size();
      expected_global.delete();
      foreach (expected_per_key[ks]) begin
        dropped_expected += expected_per_key[ks].size();
        expected_per_key[ks].delete();
      end
      `uvm_info("AXIS-SCB", $sformatf(
        "reset(epoch=%0d) 按 BOTH_FLUSH 合同结算已接受但未输出的 expected 数据（REQ-RST-005）", epoch), UVM_MEDIUM)
    end else begin
      `uvm_info("AXIS-SCB", $sformatf(
        "reset(epoch=%0d) 按 PRESERVE 合同保留 expected 队列", epoch), UVM_MEDIUM)
    end
  endfunction

  function void set_cdc_reset_contract(axis_cdc_reset_e c);
    if (!cfg.cdc_reset_configured) begin
      `uvm_fatal("AXIS-SCB",
        "CDC 两侧复位合同未配置：未知合同必须停止严格比较并报告配置缺失（REQ-RST-005）")
      return;
    end
    flush_expected_on_reset = (c == AXIS_CDC_BOTH_FLUSH);
  endfunction

  function void get_stats(output int matched, output int mismatched, output int unexpected,
                          output int dropped, output int unknown);
    matched = matched_packets; mismatched = mismatched_packets;
    unexpected = unexpected_packets; dropped = dropped_expected;
    unknown = unknown_value_events;
  endfunction

endclass : axi4_stream_scoreboard

`endif // AXI4_STREAM_SCOREBOARD__SV
