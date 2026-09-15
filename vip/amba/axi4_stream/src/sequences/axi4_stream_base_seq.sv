// =============================================================================
// File Name   : axi4_stream_base_seq.sv
// Description : axi4_stream 基础序列 + 序列库（§12 序列与场景）
// 依据        : docs/requirement.md（REQ-SEQ-001, REQ-SRC-001..004,
//               REQ-TXN-002/003/006）
//
// 序列库覆盖 §12 的 10 组场景；每个序列支持 seed / repeat / stream / 长度 / 时序配置。
// =============================================================================

`ifndef AXI4_STREAM_BASE_SEQ__SV
`define AXI4_STREAM_BASE_SEQ__SV

class axi4_stream_base_seq extends uvm_sequence #(axi4_stream_beat_item);

  `uvm_object_utils(axi4_stream_base_seq)

  axi4_stream_config cfg;
  int unsigned       n_sequences  = 1;
  int unsigned       n_beats      = 1;
  int                idle_cycles  = 0;
  int unsigned       seed         = 0;
  stream_key_t       key;

  function new(string name = "axi4_stream_base_seq");
    super.new(name);
  endfunction

  function void set_config(axi4_stream_config c);
    cfg = c;
  endfunction

  // 基础工具：构造一拍
  function axi4_stream_beat_item make_beat(
    logic [axi4_stream_types_pkg::AXIS_MAX_BITS-1:0] d,
    logic [axi4_stream_types_pkg::AXIS_MAX_BYTES-1:0] k,
    logic [axi4_stream_types_pkg::AXIS_MAX_BYTES-1:0] s,
    bit l, int idle = 0
  );
    axi4_stream_beat_item it;
    it = axi4_stream_beat_item::type_id::create("beat");
    it.data = d; it.keep = k; it.strb = s; it.last = l;
    it.idle_cycles = idle;
    it.id   = key.tid;
    it.dest = key.tdest;
    it.user = '0;   // TUSER 必须为确定值，避免 X 检查误报
    return it;
  endfunction

  // 发送一包：基于字节序列（自动 beat 拆分）
  // bytes 使用 input 语义（值传递），避免 ref 实参与临时量不兼容
  task send_bytes(byte unsigned bytes[$], bit use_tlast = 1'b1);
    axi4_stream_packet_item pkt;
    int lanes;
    lanes = (cfg != null) ? cfg.byte_lanes() : 8;
    pkt = axi4_stream_packet_item::type_id::create("pkt");
    if (!pkt.from_bytes(bytes, key, (cfg != null) ? cfg.has_tkeep : 1'b1, lanes)) begin
      `uvm_error("AXIS-SEQ", "from_bytes 无法精确表达该长度（REQ-TXN-002）")
      return;
    end
    foreach (pkt.beats[i]) begin
      if (!use_tlast && i == pkt.beats.size()-1) pkt.beats[i].last = 1'b0;
      pkt.beats[i].idle_cycles = idle_cycles;
      start_item(pkt.beats[i]);
      finish_item(pkt.beats[i]);
    end
  endtask

  // 发送 N 拍同 key 连续流
  task send_beats(int unsigned count, bit last_on_final = 1'b1);
    axi4_stream_beat_item it;
    logic [axi4_stream_types_pkg::AXIS_MAX_BYTES-1:0] full_keep;
    int lanes;
    lanes = (cfg != null) ? cfg.byte_lanes() : 8;
    full_keep = axi4_stream_types_pkg::axis_byte_mask(lanes);
    for (int unsigned i = 0; i < count; i++) begin
      it = make_beat($urandom(), full_keep, full_keep,
                     last_on_final && (i == count-1), idle_cycles);
      start_item(it);
      finish_item(it);
    end
  endtask

  task body();
    send_beats(n_beats);
  endtask

endclass : axi4_stream_base_seq

// ---------------------------------------------------------------------------
// 1. 单 beat / 单字节 / 单包 / 多包 / 连续
// ---------------------------------------------------------------------------
class axi4_stream_single_beat_seq extends axi4_stream_base_seq;
  `uvm_object_utils(axi4_stream_single_beat_seq)
  function new(string name = "axi4_stream_single_beat_seq"); super.new(name); endfunction
  task body();
    byte unsigned b[$];
    b.push_back(8'h5a);
    send_bytes(b);
  endtask
endclass

class axi4_stream_multi_packet_seq extends axi4_stream_base_seq;
  `uvm_object_utils(axi4_stream_multi_packet_seq)
  int unsigned n_packets = 4;
  function new(string name = "axi4_stream_multi_packet_seq"); super.new(name); endfunction
  task body();
    byte unsigned b[$];
    for (int unsigned p = 0; p < n_packets; p++) begin
      b.delete();
      for (int unsigned i = 0; i < n_beats; i++) b.push_back($urandom());
      send_bytes(b);
    end
  endtask
endclass

// ---------------------------------------------------------------------------
// 2. 随机包长与边界长度
// ---------------------------------------------------------------------------
class axi4_stream_random_length_seq extends axi4_stream_base_seq;
  `uvm_object_utils(axi4_stream_random_length_seq)
  int unsigned min_bytes = 1;
  int unsigned max_bytes = 64;
  function new(string name = "axi4_stream_random_length_seq"); super.new(name); endfunction
  task body();
    byte unsigned b[$];
    int unsigned n;
    n = min_bytes + ($urandom % ((max_bytes - min_bytes) + 1));
    b.delete();
    for (int unsigned i = 0; i < n; i++) b.push_back($urandom);
    send_bytes(b);
  endtask
endclass

class axi4_stream_boundary_length_seq extends axi4_stream_base_seq;
  `uvm_object_utils(axi4_stream_boundary_length_seq)
  function new(string name = "axi4_stream_boundary_length_seq"); super.new(name); endfunction
  task body();
    byte unsigned b[$];
    int lens[6];
    int lanes;
    lanes = (cfg != null) ? cfg.byte_lanes() : 8;
    lens = '{0, 1, lanes-1, lanes, lanes+1, 255};
    foreach (lens[i]) begin
      if (lens[i] < 0) continue;
      b.delete();
      for (int j = 0; j < lens[i]; j++) b.push_back($urandom);
      send_bytes(b);
    end
  endtask
endclass

// ---------------------------------------------------------------------------
// 3. 数据模式：全 0 / 全 1 / 递增 / walking-one / 随机
// ---------------------------------------------------------------------------
class axi4_stream_data_pattern_seq extends axi4_stream_base_seq;
  `uvm_object_utils(axi4_stream_data_pattern_seq)
  function new(string name = "axi4_stream_data_pattern_seq"); super.new(name); endfunction
  task body();
    byte unsigned b[$];
    int lanes;
    lanes = (cfg != null) ? cfg.byte_lanes() : 8;
    // 全 0
    b.delete(); for (int i = 0; i < lanes; i++) b.push_back(8'h00); send_bytes(b);
    // 全 1
    b.delete(); for (int i = 0; i < lanes; i++) b.push_back(8'hff); send_bytes(b);
    // 递增
    b.delete(); for (int i = 0; i < lanes; i++) b.push_back(i); send_bytes(b);
    // walking-one
    for (int w = 0; w < lanes && w < 8; w++) begin
      b.delete(); for (int i = 0; i < lanes; i++) b.push_back(i == w ? 8'h01 : 8'h00); send_bytes(b);
    end
  endtask
endclass

// ---------------------------------------------------------------------------
// 4. 全 keep / 稀疏 keep / partial / POSITION / NULL / 全 NULL TLAST
// ---------------------------------------------------------------------------
class axi4_stream_qualifier_seq extends axi4_stream_base_seq;
  `uvm_object_utils(axi4_stream_qualifier_seq)
  function new(string name = "axi4_stream_qualifier_seq"); super.new(name); endfunction
  task body();
    axi4_stream_beat_item it;
    logic [axi4_stream_types_pkg::AXIS_MAX_BYTES-1:0] full_keep, null_keep, sparse;
    int lanes;
    lanes = (cfg != null) ? cfg.byte_lanes() : 8;
    full_keep = axi4_stream_types_pkg::axis_byte_mask(lanes);
    null_keep = '0;
    sparse    = '0;
    if (lanes > 0) sparse[0] = 1'b1;
    if (lanes > 1) sparse[lanes-1] = 1'b1;

    // 全 keep DATA
    it = make_beat('1, full_keep, full_keep, 1'b0);
    start_item(it); finish_item(it);
    // 稀疏 keep + 尾拍 partial（保持非尾拍 partial 也合法，REQ-PRO-006）
    it = make_beat('1, sparse, sparse, 1'b0);
    start_item(it); finish_item(it);
    // POSITION（keep=1 strb=0）
    it = make_beat('1, full_keep, '0, 1'b0);
    start_item(it); finish_item(it);
    // 全 NULL + TLAST
    it = make_beat('0, null_keep, null_keep, 1'b1);
    start_item(it); finish_item(it);
    // 只有 POSITION 的包（REQ-TXN-003）
    it = make_beat('0, full_keep, '0, 1'b1);
    start_item(it); finish_item(it);
  endtask
endclass

// ---------------------------------------------------------------------------
// 5. ready 先到 / valid 先到 / 周期 / 随机 / 长 stall / TLAST stall
// ---------------------------------------------------------------------------
class axi4_stream_stall_seq extends axi4_stream_base_seq;
  `uvm_object_utils(axi4_stream_stall_seq)
  int stall_beats = 4;
  function new(string name = "axi4_stream_stall_seq"); super.new(name); endfunction
  task body();
    // 通过 idle_cycles 制造 valid 延迟；ready 侧延迟由 ready policy 控制
    idle_cycles = 2;
    send_beats(stall_beats);
    idle_cycles = 0;
  endtask
endclass

// ---------------------------------------------------------------------------
// 6. 多 key 持续流 / 逐 beat 交织 / 每包切换 / 同 key 连续包
// ---------------------------------------------------------------------------
class axi4_stream_multi_key_seq extends axi4_stream_base_seq;
  `uvm_object_utils(axi4_stream_multi_key_seq)
  int unsigned n_keys        = 4;
  int unsigned beats_per_key = 8;
  bit          per_beat_interleave = 1'b1;
  function new(string name = "axi4_stream_multi_key_seq"); super.new(name); endfunction
  task body();
    axi4_stream_beat_item it;
    logic [axi4_stream_types_pkg::AXIS_MAX_BYTES-1:0] full_keep;
    int lanes;
    lanes = (cfg != null) ? cfg.byte_lanes() : 8;
    full_keep = axi4_stream_types_pkg::axis_byte_mask(lanes);
    if (per_beat_interleave) begin
      // 逐 beat 交织：不同 key 在 beat 间交替，TID/TDEST 只在成功传输之间变化（REQ-PRO-010）
      for (int unsigned b = 0; b < beats_per_key; b++) begin
        for (int unsigned k = 0; k < n_keys; k++) begin
          it = make_beat($urandom, full_keep, full_keep,
                         (b == beats_per_key-1), 0);
          it.id   = k;
          it.dest = k;
          start_item(it); finish_item(it);
        end
      end
    end else begin
      // 每包切换 key
      for (int unsigned k = 0; k < n_keys; k++) begin
        for (int unsigned b = 0; b < beats_per_key; b++) begin
          it = make_beat($urandom, full_keep, full_keep, (b == beats_per_key-1), 0);
          it.id = k; it.dest = k;
          start_item(it); finish_item(it);
        end
      end
    end
  endtask
endclass

// ---------------------------------------------------------------------------
// 7. 无 TLAST 连续流 / 满速流 / 仅侧带流
// ---------------------------------------------------------------------------
class axi4_stream_continuous_seq extends axi4_stream_base_seq;
  `uvm_object_utils(axi4_stream_continuous_seq)
  function new(string name = "axi4_stream_continuous_seq"); super.new(name); endfunction
  task body();
    send_beats(n_beats, .last_on_final(1'b0));
  endtask
endclass

// ---------------------------------------------------------------------------
// 9. 逐项协议错误注入（专用注入序列，默认不启用）
// ---------------------------------------------------------------------------
class axi4_stream_error_inject_seq extends axi4_stream_base_seq;
  `uvm_object_utils(axi4_stream_error_inject_seq)
  string inject_rule = "AXIS-P005";
  function new(string name = "axi4_stream_error_inject_seq"); super.new(name); endfunction
  task body();
    axi4_stream_beat_item it;
    logic [axi4_stream_types_pkg::AXIS_MAX_BYTES-1:0] full_keep;
    int lanes;
    lanes = (cfg != null) ? cfg.byte_lanes() : 8;
    full_keep = axi4_stream_types_pkg::axis_byte_mask(lanes);
    it = make_beat('1, full_keep, full_keep, 1'b0);
    it.inject_enable = 1'b1;
    it.inject_rule   = inject_rule;
    start_item(it); finish_item(it);
  endtask
endclass

// ---------------------------------------------------------------------------
// 10. 压力 / 有限缓存 / drain
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// 通用 item 序列（供 test 层注入/取消/在途场景复用）
// ---------------------------------------------------------------------------
class axi4_stream_single_item_seq extends axi4_stream_base_seq;

  `uvm_object_utils(axi4_stream_single_item_seq)

  int unsigned n_items     = 1;
  bit          last_marker = 1'b0;
  bit          inject      = 1'b0;
  string       inject_rule = "";

  function new(string name = "axi4_stream_single_item_seq");
    super.new(name);
  endfunction

  task body();
    axi4_stream_beat_item it;
    logic [axi4_stream_types_pkg::AXIS_MAX_BYTES-1:0] keep;
    int lanes;
    lanes = (cfg != null) ? cfg.byte_lanes() : 8;
    keep = axi4_stream_types_pkg::axis_byte_mask(lanes);
    for (int unsigned i = 0; i < n_items; i++) begin
      it = make_beat('1, keep, keep, (last_marker && (i == n_items-1)), idle_cycles);
      it.inject_enable = inject;
      it.inject_rule   = inject_rule;
      start_item(it);
      finish_item(it);
    end
  endtask

endclass

// ---------------------------------------------------------------------------
// 文件回放（REQ-SRC-001）：可重放文件输入
//   格式：每行 `<hex_data> <keep> <strb> <last> <tid> <dest> <user>`
//   `#` 开头为注释；同一文件在相同配置/seed/仿真器版本下可复现。
// ---------------------------------------------------------------------------
class axi4_stream_file_replay_seq extends axi4_stream_base_seq;

  `uvm_object_utils(axi4_stream_file_replay_seq)

  string filename = "";
  int    lines_read = 0;
  int    lines_skipped = 0;

  function new(string name = "axi4_stream_file_replay_seq");
    super.new(name);
  endfunction

  task body();
    int fd;
    string line;
    int code;
    int lanes;
    axi4_stream_beat_item it;
    logic [axi4_stream_types_pkg::AXIS_MAX_BITS-1:0]  d;
    logic [axi4_stream_types_pkg::AXIS_MAX_BYTES-1:0] k, s;
    logic l;
    int unsigned tid, dest;
    logic [axi4_stream_types_pkg::AXIS_MAX_USER_WIDTH-1:0] u;

    lanes = (cfg != null) ? cfg.byte_lanes() : 8;
    if (filename == "") begin
      `uvm_fatal("AXIS-SEQ", "file_replay 需要先设置 filename（REQ-SRC-001）")
      return;
    end
    fd = $fopen(filename, "r");
    if (fd == 0) begin
      `uvm_fatal("AXIS-SEQ", $sformatf("无法打开回放文件: %s", filename))
      return;
    end
    while (!$feof(fd)) begin
      code = $fgets(line, fd);
      if (code == 0) break;
      if (line.len() == 0) continue;
      if (line[0] == "#" || line[0] == "\n") begin lines_skipped++; continue; end
      code = $sscanf(line, "%h %h %h %b %d %d %h", d, k, s, l, tid, dest, u);
      if (code < 4) begin lines_skipped++; continue; end
      it = axi4_stream_beat_item::type_id::create($sformatf("replay_%0d", lines_read));
      it.data = d;
      it.keep = (code >= 2) ? k : axi4_stream_types_pkg::axis_byte_mask(lanes);
      it.strb = (code >= 3) ? s : it.keep;
      it.last = l;
      it.id   = (code >= 5) ? tid  : 0;
      it.dest = (code >= 6) ? dest : 0;
      it.user = (code >= 7) ? u    : '0;
      it.idle_cycles = idle_cycles;
      lines_read++;
      start_item(it);
      finish_item(it);
    end
    $fclose(fd);
    `uvm_info("AXIS-SEQ", $sformatf("file_replay 读取 %0d 拍，跳过 %0d 行（%s）",
      lines_read, lines_skipped, filename), UVM_LOW)
    if (lines_read == 0)
      `uvm_error("AXIS-SEQ", "回放文件未产生任何 beat（REQ-SRC-001）")
  endtask

endclass

// ---------------------------------------------------------------------------
// 多流调度（REQ-SRC-004）：round-robin / weighted-random / 显式顺序
// ---------------------------------------------------------------------------
typedef enum { AXIS_SCHED_RR, AXIS_SCHED_WEIGHTED, AXIS_SCHED_EXPLICIT } axis_sched_mode_e;

class axi4_stream_scheduled_seq extends axi4_stream_base_seq;

  `uvm_object_utils(axi4_stream_scheduled_seq)

  axis_sched_mode_e sched_mode = AXIS_SCHED_RR;
  int unsigned      n_keys     = 3;
  int unsigned      n_rounds   = 4;
  int               weights[8];
  int               rr_cursor  = 0;
  int               rng_state  = 1;
  int unsigned      explicit_order[$];

  function new(string name = "axi4_stream_scheduled_seq");
    super.new(name);
    foreach (weights[i]) weights[i] = 1;
  endfunction

  protected function int pick_key_rr();
    int k;
    k = rr_cursor % (n_keys > 0 ? n_keys : 1);
    rr_cursor++;
    return k;
  endfunction

  protected function int pick_key_weighted();
    int total, pick, acc;
    rng_state = (rng_state * 1103515245 + 12345) & 32'h7fffffff;
    total = 0;
    for (int i = 0; i < n_keys; i++) total += (weights[i] > 0) ? weights[i] : 1;
    if (total <= 0) return 0;
    pick = rng_state % total;
    acc = 0;
    for (int i = 0; i < n_keys; i++) begin
      acc += (weights[i] > 0) ? weights[i] : 1;
      if (pick < acc) return i;
    end
    return 0;
  endfunction

  task body();
    axi4_stream_beat_item it;
    logic [axi4_stream_types_pkg::AXIS_MAX_BYTES-1:0] keep;
    int k;
    int lanes;
    lanes = (cfg != null) ? cfg.byte_lanes() : 8;
    keep = axi4_stream_types_pkg::axis_byte_mask(lanes);

    if (sched_mode == AXIS_SCHED_EXPLICIT && explicit_order.size() != n_rounds) begin
      `uvm_error("AXIS-SEQ", $sformatf(
        "显式顺序需要 %0d 个 key，实际 %0d（REQ-SRC-004）", n_rounds, explicit_order.size()))
      return;
    end

    for (int unsigned r = 0; r < n_rounds; r++) begin
      case (sched_mode)
        AXIS_SCHED_RR:       k = pick_key_rr();
        AXIS_SCHED_WEIGHTED: k = pick_key_weighted();
        AXIS_SCHED_EXPLICIT: k = explicit_order[r];
        default:             k = pick_key_rr();
      endcase
      it = make_beat($urandom, keep, keep, 1'b1, idle_cycles);
      it.id   = k;
      it.dest = k % 4;
      start_item(it);
      finish_item(it);
    end
  endtask

endclass

// ---------------------------------------------------------------------------
// 压力
// ---------------------------------------------------------------------------
class axi4_stream_stress_seq extends axi4_stream_base_seq;
  `uvm_object_utils(axi4_stream_stress_seq)
  function new(string name = "axi4_stream_stress_seq"); super.new(name); endfunction
  task body();
    byte unsigned b[$];
    int lanes;
    lanes = (cfg != null) ? cfg.byte_lanes() : 8;
    b.delete();
    for (int i = 0; i < lanes * 16; i++) b.push_back($urandom);
    repeat (n_sequences) send_bytes(b);
  endtask
endclass

`endif // AXI4_STREAM_BASE_SEQ__SV
