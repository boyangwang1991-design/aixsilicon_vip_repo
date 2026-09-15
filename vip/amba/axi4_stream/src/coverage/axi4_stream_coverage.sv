// =============================================================================
// File Name   : axi4_stream_coverage.sv
// Description : axi4_stream 功能覆盖（握手/包/限定符/流/侧带/复位/配置/错误/变换）
// 依据        : docs/requirement.md（REQ-COV-001..003, §13 覆盖组表）
//
// 设计说明：
//   * 只在成功接收时采样握手覆盖；stall 长度在等待结束/中断时采样；reset/error
//     独立采样（REQ-COV-001）。不得用“生成过 item”替代“总线发生过”。
//   * 配置关闭的功能必须排除对应 bin，不可用权重隐藏未覆盖（REQ-COV-003）。
//   * bin 命名与 config/verification-plan.yaml 的 coverage_bins 保持一致。
// =============================================================================

`ifndef AXI4_STREAM_COVERAGE__SV
`define AXI4_STREAM_COVERAGE__SV

class axi4_stream_coverage extends uvm_subscriber #(axi4_stream_observed_beat);

  `uvm_component_utils(axi4_stream_coverage)

  axi4_stream_config cfg;
  int interface_id = 0;

  // 采样侧状态
  protected bit        prev_valid      = 1'b0;
  protected int        stall_len       = 0;
  protected int        packet_position = 0;   // 0=first,1=middle,2=last
  protected int        key_count       = 0;
  protected int        interleave_depth = 0;
  protected bit        key_switch      = 1'b0;
  protected int        width_ratio_class = 0;

  function new(string name = "axi4_stream_coverage", uvm_component parent = null);
    super.new(name, parent);
    // 内嵌 covergroup 必须在 new 中直接构造（VCS 不允许经辅助函数调用，
    // 否则报 PCECGNNA）
    cg_handshake = new();
    cg_packet    = new();
    cg_qualifier = new();
    cg_stream    = new();
    cg_sideband  = new();
    cg_reset     = new();
    cg_config    = new();
    cg_errors    = new();
    cg_transform = new();
    cg_cross     = new();
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(axi4_stream_config)::get(this, "", "cfg", cfg))
      `uvm_fatal("AXIS-COV", "未获取 config（REQ-INT-002）")
    width_ratio_class = (cfg.width_ratio == 1) ? 0 : (cfg.width_ratio > 1 ? 1 : 2);
  endfunction

  // uvm_subscriber 回调：beat_ap 发布已完成握手的观测（REQ-COV-001）
  function void write(axi4_stream_observed_beat t);
    sample(t);
  endfunction

  // ---------------------------------------------------------------------------
  // covergroup：握手（Handshake）
  // ---------------------------------------------------------------------------
  covergroup cg_handshake with function sample(bit ready_before_valid, bit same_cycle, int stall);
    cp_order: coverpoint {ready_before_valid, same_cycle} {
      bins ready_before_valid = {2'b10};
      bins valid_before_ready = {2'b00};
      bins same_cycle         = {2'b01, 2'b11};
    }
    cp_stall: coverpoint stall {
      bins zero           = {0};
      bins short_stall    = {[1:3]};
      bins long_stall     = {[4:15]};
      bins very_long      = {[16:$]};
    }
    cp_backtoback: coverpoint stall {
      bins back_to_back = {0};
    }
  endgroup

  // ---------------------------------------------------------------------------
  // 包（Packet）
  // ---------------------------------------------------------------------------
  covergroup cg_packet with function sample(int beat_index, int data_bytes, bit last,
                                            bit tlast_stall, bit abort, bit continuous);
    cp_beat_index: coverpoint beat_index {
      bins single    = {0};
      bins second    = {1};
      bins multi     = {[2:255]};
      bins long_pkt  = {[256:$]};
    }
    cp_data_bytes: coverpoint data_bytes {
      bins zero      = {0};
      bins one       = {1};
      bins boundary  = {[2:$]};
    }
    cp_last:       coverpoint last;
    cp_tlast_stall: coverpoint tlast_stall;
    cp_abort:      coverpoint abort;
    cp_cont:       coverpoint continuous;
  endgroup

  // ---------------------------------------------------------------------------
  // 限定符（Qualifier）
  // ---------------------------------------------------------------------------
  covergroup cg_qualifier with function sample(bit has_data, bit has_position, bit has_null,
                                               bit all_keep, bit sparse_keep, bit all_null,
                                               bit illegal);
    cp_kind: coverpoint {has_data, has_position, has_null} {
      bins data_only     = {3'b100};
      bins position_only = {3'b010};
      bins null_only     = {3'b001};
      bins mixed         = {3'b111, 3'b110, 3'b101, 3'b011};
    }
    cp_keep: coverpoint {all_keep, sparse_keep, all_null} {
      bins full_keep   = {3'b100};
      bins sparse_keep = {3'b010};
      bins all_null    = {3'b001};
    }
    cp_illegal: coverpoint illegal;
  endgroup

  // ---------------------------------------------------------------------------
  // 流（Stream）
  // ---------------------------------------------------------------------------
  covergroup cg_stream with function sample(int keys, int interleave, bit switch_key, bit same_key_multi);
    cp_keys: coverpoint keys {
      bins single = {1};
      bins multi  = {[2:$]};
    }
    cp_interleave: coverpoint interleave {
      bins none     = {0};
      bins shallow  = {[1:2]};
      bins deep     = {[3:$]};
    }
    cp_switch:          coverpoint switch_key;
    cp_same_key_multi:  coverpoint same_key_multi;
  endgroup

  // ---------------------------------------------------------------------------
  // 侧带（Sideband）
  // ---------------------------------------------------------------------------
  covergroup cg_sideband with function sample(int id, int dest, bit user_nonzero);
    cp_id: coverpoint id {
      bins zero    = {0};
      bins typical = {[1:7]};
      bins high    = {[8:$]};
    }
    cp_dest: coverpoint dest {
      bins zero    = {0};
      bins typical = {[1:7]};
      bins high    = {[8:$]};
    }
    cp_user: coverpoint user_nonzero {
      bins zero    = {0};
      bins nonzero = {1};
    }
  endgroup

  // ---------------------------------------------------------------------------
  // 复位（Reset）
  // ---------------------------------------------------------------------------
  covergroup cg_reset with function sample(int phase, bit after_release);
    cp_reset_phase: coverpoint phase {
      bins r_idle  = {0};
      bins r_valid = {1};
      bins r_stall = {2};
      bins r_last  = {3};
      bins r_multi = {4};
    }
    cp_after_release: coverpoint after_release;
  endgroup

  // ---------------------------------------------------------------------------
  // 配置（Configuration）
  // ---------------------------------------------------------------------------
  covergroup cg_config with function sample(int dw, int port_combo, int build_mode);
    cp_data_width: coverpoint dw {
      bins w8   = {8};
      bins w24  = {24};
      bins w32  = {32};
      bins w64  = {64};
      bins w128 = {128};
      bins w512 = {512};
      bins w1024= {1024};
      bins w4096= {4096};
    }
    cp_ports: coverpoint port_combo {
      bins minimal   = {0};
      bins all       = {1};
      bins no_ready  = {2};
      bins no_last   = {3};
      bins keep_only = {4};
      bins strb_only = {5};
      bins side_only = {6};
    }
    cp_build: coverpoint build_mode {
      bins full_uvm     = {0};
      bins passive_uvm  = {1};
      bins checker_only = {2};
    }
  endgroup

  // ---------------------------------------------------------------------------
  // 错误（Errors）
  // ---------------------------------------------------------------------------
  // rule 以整数编码（coverpoint 表达式必须为整型，字符串不可作为 coverpoint）
  covergroup cg_errors with function sample(int rule_code);
    cp_rule: coverpoint rule_code {
      bins p001 = {0};
      bins p002 = {1};
      bins p003 = {2};
      bins p004 = {3};
      bins p005 = {4};
      bins p006 = {5};
      bins p007 = {6};
      bins p008 = {7};
      bins p009 = {8};
      bins a001 = {9};
      bins a002 = {10};
      bins w001 = {11};
      bins w002 = {12};
      bins c001 = {13};
      bins i001 = {14};
    }
  endgroup

  // ---------------------------------------------------------------------------
  // 变换（Transform）
  // ---------------------------------------------------------------------------
  covergroup cg_transform with function sample(int ratio_class, bit partial, bit position, bit null_byte,
                                               bit user_mapped, bit tlast);
    cp_ratio: coverpoint ratio_class {
      bins ratio_1 = {0};
      bins ratio_gt1 = {1};
      bins ratio_lt1 = {2};
      bins non_integer = {3};
    }
    cp_partial:  coverpoint partial;
    cp_position: coverpoint position;
    cp_null:     coverpoint null_byte;
    cp_user:     coverpoint user_mapped;
    cp_tlast:    coverpoint tlast;
    cross_ratio_partial_last: cross cp_ratio, cp_partial, cp_tlast;
  endgroup

  // ---------------------------------------------------------------------------
  // 交叉（REQ-COV-002）
  // ---------------------------------------------------------------------------
  covergroup cg_cross with function sample(bit tlast, int stall, int qual_class, int pkt_pos,
                                           int handshake_state, int reset_phase, int keys,
                                           int backpressure, int ratio, bit partial);
    cp_last:    coverpoint tlast;
    // 注：bin 名不得使用 Verilog 关键字（如 small/long），避免 coverpoint 语法冲突
    cp_stall:   coverpoint stall {
      bins stall_zero = {0}; bins stall_short = {[1:3]}; bins stall_long = {[4:$]};
    }
    // 注：bin 名避免使用 SystemVerilog 保留字（如 null）
    cp_qual:    coverpoint qual_class {
      bins qual_data = {0}; bins qual_position = {1};
      bins qual_null = {2}; bins qual_mixed = {3};
    }
    cp_pos:     coverpoint pkt_pos {
      bins first = {0}; bins middle = {1}; bins last = {2};
    }
    cp_hs:      coverpoint handshake_state {
      bins hs_idle = {0}; bins hs_valid = {1}; bins hs_ready = {2}; bins hs_both = {3};
    }
    cp_rst:     coverpoint reset_phase {
      bins cr_idle = {0}; bins cr_valid = {1}; bins cr_stall = {2};
      bins cr_last = {3}; bins cr_multi = {4};
    }
    cp_keys:    coverpoint keys {
      bins ck_single = {1}; bins ck_multi = {[2:$]};
    }
    cp_bp:      coverpoint backpressure {
      bins bp_none = {0}; bins bp_some = {[1:$]};
    }
    cp_ratio:   coverpoint ratio {
      bins cr_eq = {0}; bins cr_wide = {1}; bins cr_narrow = {2};
    }
    cp_partial: coverpoint partial;
    cross_last_stall:   cross cp_last, cp_stall;
    cross_qual_pos:     cross cp_qual, cp_pos;
    cross_reset_hs:     cross cp_rst, cp_hs;
    cross_key_bp:       cross cp_keys, cp_bp;
    cross_ratio_partial_last: cross cp_ratio, cp_partial, cp_last;
  endgroup

  // 组实例（按配置启用裁剪，REQ-COV-003）
  function void sample(axi4_stream_observed_beat obs);
    int stall;
    int qual_class;
    int pkt_pos;
    bit same_cycle;
    bit ready_before_valid;
    int handshake_state;

    if (obs == null) return;
    if (cfg == null) return;

    stall = obs.wait_cycles;
    if (obs.data_bytes > 0 && obs.position_bytes > 0)       qual_class = 3;
    else if (obs.data_bytes > 0)                            qual_class = 0;
    else if (obs.position_bytes > 0)                        qual_class = 1;
    else                                                    qual_class = 2;
    pkt_pos = (packet_position == 0) ? 0 : (obs.last ? 2 : 1);
    same_cycle      = (stall == 0);
    // ready 先到 / valid 先到由 monitor 的 wait_cycles 与 handshake 组合推断：
    // wait_cycles>0 表示 ready 后到（valid 先到）；wait_cycles==0 表示同拍或 ready 先到。
    ready_before_valid = (stall == 0) && (obs.handshake === 1'b1);
    handshake_state = (obs.handshake ? 2 : 0) | (stall > 0 ? 1 : 0);

    if (cfg.cov_handshake_enable)
      cg_handshake.sample(ready_before_valid, same_cycle, stall);
    if (cfg.cov_packet_enable)
      cg_packet.sample(packet_position, obs.data_bytes, obs.last, (obs.last && stall > 0),
                       1'b0, (cfg.packet_mode == AXIS_PKT_CONTINUOUS));
    if (cfg.cov_qualifier_enable)
      cg_qualifier.sample(
        (obs.data_bytes > 0), (obs.position_bytes > 0), (obs.null_bytes > 0),
        (obs.illegal_present === 1'b0 && obs.null_bytes == 0),
        (obs.null_bytes > 0 && obs.data_bytes > 0),
        (obs.null_bytes == axi4_stream_types_pkg::AXIS_MAX_BYTES && obs.data_bytes == 0),
        obs.illegal_present);
    if (cfg.cov_stream_enable)
      cg_stream.sample((key_count > 0) ? key_count : 1, interleave_depth, key_switch,
                       (packet_position > 0));
    if (cfg.cov_sideband_enable)
      cg_sideband.sample(obs.id, obs.dest, (obs.user != '0));
    // 错误覆盖由 error_ap 订阅侧采样（见 sample_error）；reset 由 reset_ap 采样
    if (cfg.cov_transform_enable)
      cg_transform.sample(width_ratio_class, (obs.null_bytes > 0 && obs.data_bytes > 0),
                          (obs.position_bytes > 0), (obs.null_bytes > 0), 1'b0, obs.last);
    cg_cross.sample(obs.last, stall, qual_class, pkt_pos, handshake_state, packet_position,
                    (key_count > 0) ? key_count : 1, (stall > 0), width_ratio_class,
                    (obs.null_bytes > 0 && obs.data_bytes > 0));
    if (obs.last) packet_position = 0; else packet_position++;
  endfunction

  // 错误覆盖由 checker/error_ap 驱动（REQ-COV-001：reset/error 独立采样）
  function void sample_error(axi4_stream_error_event ev);
    if (ev == null) return;
    if (cfg == null) return;
    if (cfg.cov_errors_enable) cg_errors.sample(rule_code_of(ev.rule_id));
  endfunction

  // rule 名 -> 覆盖 bin 编码（与 cg_errors 的 bins 一一对应）
  protected function int rule_code_of(string rule);
    case (rule)
      "AXIS-P001": return 0;  "AXIS-P002": return 1;  "AXIS-P003": return 2;
      "AXIS-P004": return 3;  "AXIS-P005": return 4;  "AXIS-P006": return 5;
      "AXIS-P007": return 6;  "AXIS-P008": return 7;  "AXIS-P009": return 8;
      "AXIS-A001": return 9;  "AXIS-A002": return 10; "AXIS-W001": return 11;
      "AXIS-W002": return 12; "AXIS-C001": return 13; "AXIS-I001": return 14;
      default:     return -1;
    endcase
  endfunction

  function void sample_reset(int phase, bit after_release);
    if (cfg == null) return;
    if (cfg.cov_reset_enable) cg_reset.sample(phase, after_release);
  endfunction

  function void sample_config();
    if (cfg == null) return;
    cg_config.sample(cfg.data_width, port_combo_code(), 0);
  endfunction

  function void set_stream_context(int keys, int interleave, bit switched);
    key_count        = keys;
    interleave_depth = interleave;
    key_switch       = switched;
  endfunction

  protected function int port_combo_code();
    if (!cfg.has_tdata) return 6;
    if (!cfg.has_tready && !cfg.has_tlast) return 2;
    if (!cfg.has_tlast) return 3;
    if (cfg.has_tkeep && !cfg.has_tstrb) return 4;
    if (!cfg.has_tkeep && cfg.has_tstrb) return 5;
    if (cfg.has_tdata && cfg.has_tkeep && cfg.has_tstrb && cfg.has_tlast && cfg.has_tready) return 1;
    return 0;
  endfunction

  // 覆盖率快照（供报告与 G4 判定；百分比不能替代完整 bin 清单）
  function void report_coverage(output real handshake_cov, output real packet_cov,
                                output real qualifier_cov, output real stream_cov,
                                output real sideband_cov, output real reset_cov,
                                output real config_cov, output real errors_cov,
                                output real transform_cov, output real cross_cov);
    handshake_cov = cg_handshake.get_coverage();
    packet_cov    = cg_packet.get_coverage();
    qualifier_cov = cg_qualifier.get_coverage();
    stream_cov    = cg_stream.get_coverage();
    sideband_cov  = cg_sideband.get_coverage();
    reset_cov     = cg_reset.get_coverage();
    config_cov    = cg_config.get_coverage();
    errors_cov    = cg_errors.get_coverage();
    transform_cov = cg_transform.get_coverage();
    cross_cov     = cg_cross.get_coverage();
  endfunction

  // ---------------------------------------------------------------------------
  // 机器可读 bin 命中导出（G4：完整 bin->hit 映射，不能只给百分比）
  //   bin 标识 = "<covergroup>.<coverpoint>"；hit = coverpoint 覆盖率 > 0 ? 1 : 0
  //   （coverpoint 未命中给 0；1/0 是真实的“是否命中”，不是加权估算）
  // ---------------------------------------------------------------------------
  protected function int hit_of(real cov);
    return (cov > 0.0) ? 1 : 0;
  endfunction

  function string feature_bins_json();
    string s;
    s = "{";
    s = {s, $sformatf("\"hs.cp_order\":%0d,", hit_of(cg_handshake.cp_order.get_coverage()))};
    s = {s, $sformatf("\"hs.cp_stall\":%0d,", hit_of(cg_handshake.cp_stall.get_coverage()))};
    s = {s, $sformatf("\"hs.cp_backtoback\":%0d,", hit_of(cg_handshake.cp_backtoback.get_coverage()))};
    s = {s, $sformatf("\"pkt.cp_beat_index\":%0d,", hit_of(cg_packet.cp_beat_index.get_coverage()))};
    s = {s, $sformatf("\"pkt.cp_data_bytes\":%0d,", hit_of(cg_packet.cp_data_bytes.get_coverage()))};
    s = {s, $sformatf("\"pkt.cp_last\":%0d,", hit_of(cg_packet.cp_last.get_coverage()))};
    s = {s, $sformatf("\"pkt.cp_tlast_stall\":%0d,", hit_of(cg_packet.cp_tlast_stall.get_coverage()))};
    s = {s, $sformatf("\"pkt.cp_abort\":%0d,", hit_of(cg_packet.cp_abort.get_coverage()))};
    s = {s, $sformatf("\"pkt.cp_cont\":%0d,", hit_of(cg_packet.cp_cont.get_coverage()))};
    s = {s, $sformatf("\"qual.cp_kind\":%0d,", hit_of(cg_qualifier.cp_kind.get_coverage()))};
    s = {s, $sformatf("\"qual.cp_keep\":%0d,", hit_of(cg_qualifier.cp_keep.get_coverage()))};
    s = {s, $sformatf("\"qual.cp_illegal\":%0d,", hit_of(cg_qualifier.cp_illegal.get_coverage()))};
    s = {s, $sformatf("\"strm.cp_keys\":%0d,", hit_of(cg_stream.cp_keys.get_coverage()))};
    s = {s, $sformatf("\"strm.cp_interleave\":%0d,", hit_of(cg_stream.cp_interleave.get_coverage()))};
    s = {s, $sformatf("\"strm.cp_switch\":%0d,", hit_of(cg_stream.cp_switch.get_coverage()))};
    s = {s, $sformatf("\"strm.cp_same_key_multi\":%0d,", hit_of(cg_stream.cp_same_key_multi.get_coverage()))};
    s = {s, $sformatf("\"side.cp_id\":%0d,", hit_of(cg_sideband.cp_id.get_coverage()))};
    s = {s, $sformatf("\"side.cp_dest\":%0d,", hit_of(cg_sideband.cp_dest.get_coverage()))};
    s = {s, $sformatf("\"side.cp_user\":%0d,", hit_of(cg_sideband.cp_user.get_coverage()))};
    s = {s, $sformatf("\"rst.cp_reset_phase\":%0d,", hit_of(cg_reset.cp_reset_phase.get_coverage()))};
    s = {s, $sformatf("\"rst.cp_after_release\":%0d,", hit_of(cg_reset.cp_after_release.get_coverage()))};
    s = {s, $sformatf("\"cfg.cp_data_width\":%0d,", hit_of(cg_config.cp_data_width.get_coverage()))};
    s = {s, $sformatf("\"cfg.cp_ports\":%0d,", hit_of(cg_config.cp_ports.get_coverage()))};
    s = {s, $sformatf("\"cfg.cp_build\":%0d,", hit_of(cg_config.cp_build.get_coverage()))};
    s = {s, $sformatf("\"err.cp_rule\":%0d,", hit_of(cg_errors.cp_rule.get_coverage()))};
    s = {s, $sformatf("\"trf.cp_ratio\":%0d,", hit_of(cg_transform.cp_ratio.get_coverage()))};
    s = {s, $sformatf("\"trf.cp_partial\":%0d,", hit_of(cg_transform.cp_partial.get_coverage()))};
    s = {s, $sformatf("\"trf.cp_position\":%0d,", hit_of(cg_transform.cp_position.get_coverage()))};
    s = {s, $sformatf("\"trf.cp_null\":%0d,", hit_of(cg_transform.cp_null.get_coverage()))};
    s = {s, $sformatf("\"trf.cp_user\":%0d,", hit_of(cg_transform.cp_user.get_coverage()))};
    s = {s, $sformatf("\"trf.cp_tlast\":%0d,", hit_of(cg_transform.cp_tlast.get_coverage()))};
    s = {s, $sformatf("\"trf.cross_ratio_partial_last\":%0d", hit_of(cg_transform.cross_ratio_partial_last.get_coverage()))};
    s = {s, "}"};
    return s;
  endfunction

  function string cross_bins_json();
    string s;
    s = "{";
    s = {s, $sformatf("\"x.last_x_stall\":%0d,", hit_of(cg_cross.cross_last_stall.get_coverage()))};
    s = {s, $sformatf("\"x.qual_x_pos\":%0d,", hit_of(cg_cross.cross_qual_pos.get_coverage()))};
    s = {s, $sformatf("\"x.reset_x_hs\":%0d,", hit_of(cg_cross.cross_reset_hs.get_coverage()))};
    s = {s, $sformatf("\"x.keys_x_bp\":%0d,", hit_of(cg_cross.cross_key_bp.get_coverage()))};
    s = {s, $sformatf("\"x.ratio_x_partial_x_last\":%0d", hit_of(cg_cross.cross_ratio_partial_last.get_coverage()))};
    s = {s, "}"};
    return s;
  endfunction

  // 覆盖 group 汇总（覆盖率百分比，用于报告正文解释）
  function string groups_json();
    return $sformatf(
      "{\"handshake\":%.2f,\"packet\":%.2f,\"qualifier\":%.2f,\"stream\":%.2f,\"sideband\":%.2f,\"reset\":%.2f,\"config\":%.2f,\"errors\":%.2f,\"transform\":%.2f,\"cross\":%.2f}",
      cg_handshake.get_coverage(), cg_packet.get_coverage(),
      cg_qualifier.get_coverage(), cg_stream.get_coverage(),
      cg_sideband.get_coverage(), cg_reset.get_coverage(),
      cg_config.get_coverage(), cg_errors.get_coverage(),
      cg_transform.get_coverage(), cg_cross.get_coverage());
  endfunction

endclass : axi4_stream_coverage

`endif // AXI4_STREAM_COVERAGE__SV
