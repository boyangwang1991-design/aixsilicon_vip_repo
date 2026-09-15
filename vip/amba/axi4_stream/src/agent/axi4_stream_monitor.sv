// =============================================================================
// File Name   : axi4_stream_monitor.sv
// Description : axi4_stream 独立采样 / 组包 / 事件发布
// 依据        : docs/requirement.md（REQ-MON-001..007, REQ-PRO-001/003/005/009,
//               REQ-RST-004, REQ-PERF-001/003）
//
// 设计说明：
//   * 完全依赖实际 interface，绝不使用 driver item 作为总线事实（REQ-MON-001）。
//   * Passive 模式不写任何总线或时钟复位信号。
//   * 独立 analysis port：beat_ap / packet_ap / error_ap / reset_ap / cycle_ap。
//   * 按 (interface_id, reset_epoch, TID, TDEST) 独立组包；TLAST 在完成握手后
//     结束该 key 的包，其他 key 传输不结束本 key 的包（REQ-MON-003）。
//   * 保留原始四态值；未知 key/qualifier 按明确策略隔离并报告（REQ-MON-007）。
// =============================================================================

`ifndef AXI4_STREAM_MONITOR__SV
`define AXI4_STREAM_MONITOR__SV

class axi4_stream_monitor extends uvm_component;

  `uvm_component_utils(axi4_stream_monitor)

  virtual axi4_stream_if vif;
  axi4_stream_config  cfg;
  axi4_stream_stream_model model;

  int interface_id = 0;

  uvm_analysis_port #(axi4_stream_observed_beat)    beat_ap;
  uvm_analysis_port #(axi4_stream_observed_packet)  packet_ap;
  uvm_analysis_port #(axi4_stream_error_event)      error_ap;
  uvm_analysis_port #(axi4_stream_observed_packet)  reset_ap;
  uvm_analysis_port #(axi4_stream_observed_beat)    cycle_ap;

  // ---- 组包状态（逐 key 独立）----
  protected axi4_stream_observed_packet open_packet[string];
  protected int                         open_key_count = 0;

  // ---- 采样/统计状态 ----
  protected int      reset_epoch      = 0;
  protected bit      was_in_reset     = 1'b0;
  protected bit      partial_capture  = 1'b0;
  protected longint  cycle_count      = 0;
  protected longint  accepted_beats   = 0;
  protected longint  data_bytes_total = 0;
  protected longint  position_bytes_total = 0;
  protected longint  null_bytes_total = 0;
  protected longint  completed_packets = 0;
  protected longint  aborted_packets  = 0;
  protected longint  idle_cycles     = 0;
  protected longint  valid_not_ready = 0;
  protected longint  active_cycles   = 0;
  protected longint  last_handshake_cycle = -1;
  protected longint  max_ready_wait  = 0;
  protected int      wait_in_progress = 0;
  protected bit      valid_seen_pending = 1'b0;

  // 中途启用监控标志：构造后首次采样前一拍视为 PARTIAL_CAPTURE（REQ-MON-006）
  bit start_at_reset = 1'b1;

  function new(string name = "axi4_stream_monitor", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual axi4_stream_if)::get(this, "", "vif", vif))
      `uvm_fatal("AXIS-MON", "未获取 virtual interface（REQ-INT-002）")
    if (!uvm_config_db#(axi4_stream_config)::get(this, "", "cfg", cfg))
      `uvm_fatal("AXIS-MON", "未获取 config（REQ-INT-002）")
    model = axi4_stream_stream_model::type_id::create("model");
    model.configure(cfg.byte_lanes());
    beat_ap   = new("beat_ap", this);
    packet_ap = new("packet_ap", this);
    error_ap  = new("error_ap", this);
    reset_ap  = new("reset_ap", this);
    cycle_ap  = new("cycle_ap", this);
    partial_capture = !start_at_reset;
  endfunction

  // ---------------------------------------------------------------------------
  // key 字符串（稀疏容器，不按 ID 位数展开全空间，REQ-CFG-001 MAX_OPEN_STREAMS）
  // ---------------------------------------------------------------------------
  protected function string key_string(int tid, int dest);
    return $sformatf("k_%0d_%0d", tid, dest);
  endfunction

  protected function void publish_error(
    string rule, string category, axi4_stream_types_pkg::axis_severity_e sev,
    string before_s, string after_s, string desc, stream_key_t k, int beat_idx = -1
  );
    axi4_stream_error_event ev;
    ev = axi4_stream_error_event::type_id::create("err_ev");
    ev.rule_id       = rule;
    ev.category      = category;
    ev.severity      = sev;
    ev.interface_id  = interface_id;
    ev.reset_epoch   = reset_epoch;
    ev.timestamp     = $time;
    ev.cycle         = cycle_count;
    ev.before_sample = before_s;
    ev.after_sample  = after_s;
    ev.key           = k;
    ev.packet_beat_index = beat_idx;
    ev.description   = desc;
    error_ap.write(ev);
  endfunction

  // ---------------------------------------------------------------------------
  // 主采样循环：每个 ACLK 上升沿执行一次
  // ---------------------------------------------------------------------------
  task run_phase(uvm_phase phase);
    forever begin
      sample_edge();
      @(vif.mon_cb);
    end
  endtask

  protected function void sample_edge();
    bit in_reset;
    bit has_tkeep;
    bit has_tstrb;
    bit has_tlast;
    logic [axi4_stream_types_pkg::AXIS_MAX_BYTES-1:0] keep_n, strb_n;
    bit effective_ready;
    bit hs;
    axi4_stream_observed_beat obs;
    stream_key_t key;
    string ks;
    cycle_count++;

    in_reset = (vif.aresetn === 1'b0);

    // --- 复位断言处理（REQ-RST-004 / REQ-MON-003）---
    if (in_reset) begin
      if (!was_in_reset) begin
        abort_open_packets();
        reset_epoch++;
        was_in_reset = 1'b1;
      end
      publish_reset_snapshot();
      return;
    end
    if (was_in_reset) begin
      was_in_reset = 1'b0;
      // 复位释放后的第一个采样边沿：P002 由 checker 检查，这里只更新 epoch
    end

    // --- 构建观测对象（独立快照，REQ-TXN-007）---
    obs = axi4_stream_observed_beat::type_id::create("obs");
    obs.interface_id  = interface_id;
    obs.reset_epoch   = reset_epoch;
    obs.timestamp     = $time;
    obs.cycle         = cycle_count;
    obs.in_reset      = 1'b0;
    obs.partial_capture = partial_capture;
    obs.data = vif.tdata;
    obs.keep = vif.tkeep;
    obs.strb = vif.tstrb;
    obs.last = vif.tlast;
    obs.id   = vif.tid;
    obs.dest = vif.tdest;
    obs.user = vif.tuser;

    has_tkeep = vif.exists_tkeep();
    has_tstrb = vif.exists_tstrb();
    has_tlast = vif.exists_tlast();
    keep_n = model.norm_keep(has_tkeep, vif.tkeep);
    strb_n = model.norm_strb(has_tkeep, vif.tkeep, has_tstrb, vif.tstrb);
    obs.keep_norm = keep_n;
    obs.strb_norm = strb_n;
    model.normalize_stats(has_tkeep, vif.tkeep, has_tstrb, vif.tstrb,
      obs.data_bytes, obs.position_bytes, obs.null_bytes, obs.illegal_present);

    // cycle_ap 发布每拍原始采样（可含未完成/非法采样，REQ-MON-002）
    cycle_ap.write(obs);

    // --- 握手判定（REQ-PRO-001）---
    // HAS_TREADY=0 时有效 ready 恒为 1（REQ-CFG-002）
    effective_ready = vif.exists_tready() ? (vif.tready === 1'b1) : 1'b1;
    hs = (vif.tvalid === 1'b1) && effective_ready;

    if (vif.exists_tready() && vif.tready === 1'b1 && vif.tvalid !== 1'b1)
      idle_cycles++;
    if (vif.tvalid === 1'b1 && !effective_ready) begin
      valid_not_ready++;
      wait_in_progress++;
      if (wait_in_progress > max_ready_wait) max_ready_wait = wait_in_progress;
    end

    if (!hs) return;

    // 成功传输：只有 TVALID===1 && effective_TREADY===1（REQ-PRO-001）
    obs.handshake   = 1'b1;
    obs.wait_cycles = wait_in_progress;
    wait_in_progress = 0;
    active_cycles++;
    accepted_beats++;
    if (last_handshake_cycle >= 0 && (cycle_count - last_handshake_cycle) > 1)
      idle_cycles += (cycle_count - last_handshake_cycle - 1);
    last_handshake_cycle = cycle_count;

    data_bytes_total     += obs.data_bytes;
    position_bytes_total += obs.position_bytes;
    null_bytes_total     += obs.null_bytes;

    beat_ap.write(obs.clone_beat());

    // --- 组包：按 (interface_id, reset_epoch, TID, TDEST) ---
    key.tid   = vif.exists_tid()   ? vif.tid   : 32'd0;
    key.tdest = vif.exists_tdest() ? vif.tdest : 32'd0;
    ks = key_string(key.tid, key.tdest);

    if (!open_packet.exists(ks)) begin
      axi4_stream_observed_packet pkt;
      if (open_key_count >= cfg.max_open_streams) begin
        publish_error("AXIS-I001", "VIP_INTERNAL", axi4_stream_types_pkg::AXIS_SEV_ERROR,
          "", "", $sformatf("open stream 数达到上限 %0d（REQ-CFG-001/VIP 容量）", cfg.max_open_streams), key);
        return;
      end
      pkt = axi4_stream_observed_packet::type_id::create("open_pkt");
      pkt.key          = key;
      pkt.interface_id = interface_id;
      pkt.reset_epoch  = reset_epoch;
      pkt.start_time   = $time;
      pkt.partial_capture = partial_capture;
      open_packet[ks]  = pkt;
      open_key_count++;
    end

    open_packet[ks].beats.push_back(obs.clone_beat());
    open_packet[ks].data_byte_count     += obs.data_bytes;
    open_packet[ks].position_byte_count += obs.position_bytes;
    open_packet[ks].null_byte_count     += obs.null_bytes;
    open_packet[ks].end_time = $time;

    // 包上限保护（REQ-CFG-001 MAX_PACKET_BEATS 为 VIP 资源限制）
    if (open_packet[ks].beats.size() > cfg.max_packet_beats) begin
      publish_error("AXIS-I001", "VIP_INTERNAL", axi4_stream_types_pkg::AXIS_SEV_ERROR,
        "", "", $sformatf("包 beat 数超过 MAX_PACKET_BEATS=%0d（VIP 资源上限，非协议限制）", cfg.max_packet_beats),
        key, open_packet[ks].beats.size());
      close_packet(ks, AXIS_END_SYNTHETIC, 1'b0);
      return;
    end

    // --- 包结束判定 ---
    case (cfg.packet_mode)
      AXIS_PKT_TLAST: begin
        if (has_tlast && vif.tlast === 1'b1)
          close_packet(ks, AXIS_END_TLAST, 1'b0);
      end
      AXIS_PKT_FIXED_BEATS: begin
        // FIXED_BEATS 是本地应用解释，结束必须标为 synthetic（REQ-MON-004）
        if (open_packet[ks].beats.size() >= cfg.max_packet_beats)
          close_packet(ks, AXIS_END_SYNTHETIC, 1'b0);
      end
      AXIS_PKT_CONTINUOUS: begin
        // 无限连续流：按 history_limit 增量输出，不等待包结束（REQ-MON-004）
        if (open_packet[ks].beats.size() >= cfg.history_limit) begin
          if (cfg.capture_mode == AXIS_CAPTURE_STREAMING) begin
            packet_ap.write(open_packet[ks]);
            open_packet[ks].beats.delete();
          end else begin
            // FULL capture 下只裁剪最早的 beat，保持内存有界（REQ-PERF-004）
            while (open_packet[ks].beats.size() > cfg.history_limit)
              open_packet[ks].beats.pop_front();
          end
        end
      end
      default: ;
    endcase
  endfunction

  protected function void close_packet(string ks, axis_end_kind_e end_kind, bit aborted);
    axi4_stream_observed_packet pkt;
    if (!open_packet.exists(ks)) return;
    pkt = open_packet[ks];
    pkt.end_kind = end_kind;
    pkt.aborted_by_reset = aborted;
    pkt.end_time = $time;
    if (aborted) aborted_packets++; else completed_packets++;
    packet_ap.write(pkt);
    open_packet.delete(ks);
    open_key_count--;
  endfunction

  protected function void abort_open_packets();
    axi4_stream_observed_packet pkt;
    foreach (open_packet[ks]) begin
      pkt = open_packet[ks];
      pkt.end_kind = AXIS_END_NONE;
      pkt.aborted_by_reset = 1'b1;
      reset_ap.write(pkt);
      aborted_packets++;
    end
    open_packet.delete();
    open_key_count = 0;
  endfunction

  // 复位期间的快照发布（REQ-MON-002：cycle_ap/reset_ap 可含未完成采样）
  protected function void publish_reset_snapshot();
    axi4_stream_observed_beat obs;
    obs = axi4_stream_observed_beat::type_id::create("reset_obs");
    obs.interface_id = interface_id;
    obs.reset_epoch  = reset_epoch;
    obs.timestamp    = $time;
    obs.cycle        = cycle_count;
    obs.in_reset     = 1'b1;
    obs.data = vif.tdata; obs.keep = vif.tkeep; obs.strb = vif.tstrb;
    obs.last = vif.tlast; obs.id = vif.tid; obs.dest = vif.tdest; obs.user = vif.tuser;
    cycle_ap.write(obs);
  endfunction

  // ---------------------------------------------------------------------------
  // 结束时报告未完成包、最后握手、等待状态与缓存占用（REQ-MON-005）
  // ---------------------------------------------------------------------------
  function void check_phase(uvm_phase phase);
    super.check_phase(phase);
    foreach (open_packet[ks]) begin
      axi4_stream_observed_packet pkt;
      pkt = open_packet[ks];
      `uvm_warning("AXIS-MON", $sformatf(
        "仿真结束仍有未完成包 key=%s beats=%0d data_bytes=%0d（last_handshake_cycle=%0d, wait_in_progress=%0d, open_cache=%0d）；按 test policy 判定，不静默 PASS（REQ-MON-005）",
        axis_key_string(pkt.key), pkt.beats.size(), pkt.data_byte_count,
        last_handshake_cycle, wait_in_progress, open_key_count))
    end
    if (partial_capture)
      `uvm_warning("AXIS-MON",
        "PARTIAL_CAPTURE：监控中途启用，第一个包可能缺包头，不能用于完整端到端比较（REQ-MON-006）")
  endfunction

  // ---------------------------------------------------------------------------
  // 统计快照（REQ-PERF-001/002/003）
  // ---------------------------------------------------------------------------
  function void get_stats(output longint accepted, output longint data_bytes,
                          output longint pos_bytes, output longint null_bytes,
                          output longint pkts_done, output longint pkts_abort,
                          output longint idle_cyc, output longint valid_ready_cyc,
                          output longint active_cyc, output longint max_wait);
    accepted = accepted_beats; data_bytes = data_bytes_total;
    pos_bytes = position_bytes_total; null_bytes = null_bytes_total;
    pkts_done = completed_packets; pkts_abort = aborted_packets;
    idle_cyc = idle_cycles; valid_ready_cyc = valid_not_ready;
    active_cyc = active_cycles; max_wait = max_ready_wait;
  endfunction

  function int open_packet_count();
    return open_key_count;
  endfunction

  // ---------------------------------------------------------------------------
  // 公开状态查询（供 test policy 与跨域关联使用，REQ-RST-004 / REQ-PERF-003）
  // ---------------------------------------------------------------------------
  function int current_epoch();
    return reset_epoch;
  endfunction

  // 跨时钟域必须使用统一仿真时间，不得相减两侧周期号（REQ-PERF-003）
  function time current_time();
    return $time;
  endfunction

  function longint current_cycle();
    return cycle_count;
  endfunction

  function bit in_partial_capture();
    return partial_capture;
  endfunction

endclass : axi4_stream_monitor

`endif // AXI4_STREAM_MONITOR__SV
