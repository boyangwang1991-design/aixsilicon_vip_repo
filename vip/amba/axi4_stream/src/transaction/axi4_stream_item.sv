// =============================================================================
// File Name   : axi4_stream_item.sv
// Description : axi4_stream 事务与控制模型
//               beat item / packet item / ready policy item / observed event /
//               error event（REQ-TXN-001：控制请求与总线事实分离）
// 依据        : docs/requirement.md（REQ-TXN-001..007, REQ-ERR-001, REQ-COV-001）
//
// 设计说明：
//   * beat item 描述“打算发送什么”；observed beat 描述“总线实际发生了什么”。
//     两者是不同对象，monitor 绝不使用 driver item 作为总线事实（REQ-MON-001）。
//   * analysis port 发布独立快照（clone/copy），防止复用可变对象覆盖历史（REQ-TXN-007）。
//   * 四态：data/keep/strb 等字段使用四态逻辑，未知值不参与二态 equality。
// =============================================================================

`ifndef AXI4_STREAM_ITEM__SV
`define AXI4_STREAM_ITEM__SV

// ---------------------------------------------------------------------------
// stream key：同一 (TID,TDEST) 的 beat 构成一条逻辑流（REQ-PRO-009）
// ---------------------------------------------------------------------------
typedef struct {
  bit [31:0] tid;
  bit [31:0] tdest;
} stream_key_t;

function automatic bit axis_key_equal(stream_key_t a, stream_key_t b);
  return (a.tid == b.tid) && (a.tdest == b.tdest);
endfunction

function automatic int unsigned axis_key_hash(stream_key_t k);
  return (k.tid * 31) ^ (k.tdest + (k.tdest << 5));
endfunction

function automatic string axis_key_string(stream_key_t k);
  return $sformatf("(tid=%0d,dest=%0d)", k.tid, k.tdest);
endfunction

// 完成状态（REQ-TXN-004）
typedef enum {
  AXIS_ST_ACCEPTED,
  AXIS_ST_ABORTED_BY_RESET,
  AXIS_ST_CANCELED_BEFORE_VALID,
  AXIS_ST_WATCHDOG_EXPIRED,
  AXIS_ST_REJECTED_CONFIG
} axis_txn_status_e;

// ---------------------------------------------------------------------------
// beat item：待发送 beat（控制请求 + 错误注入计划）
// ---------------------------------------------------------------------------
class axi4_stream_beat_item extends uvm_sequence_item;

  // 四态 payload / sideband（存在性由配置给出）
  // 注意：这些字段必须有确定初值，否则未赋值即驱动会在总线上产生 X，
  // 触发 AXIS-P006/P007/P008/P009（X 检查）。缺省 0 表示“合法但未指定”。
  logic [axi4_stream_types_pkg::AXIS_MAX_BITS-1:0]  data = '0;
  logic [axi4_stream_types_pkg::AXIS_MAX_BYTES-1:0] keep = '0;
  logic [axi4_stream_types_pkg::AXIS_MAX_BYTES-1:0] strb = '0;
  logic                                             last = 1'b0;
  logic [31:0]                                      id   = 32'd0;
  logic [31:0]                                      dest = 32'd0;
  logic [axi4_stream_types_pkg::AXIS_MAX_USER_WIDTH-1:0] user = '0;

  // 时序与身份
  int  idle_cycles = 0;            // 发送前空闲周期（尚未断言 TVALID）
  int  local_txn_id = -1;
  bit  has_local_txn_id = 1'b0;

  // 错误注入计划（缺省关闭，REQ-ERR-001/003）
  bit  inject_enable = 1'b0;
  string inject_rule = "";
  int  inject_cycles = 0;

  // 完成状态（测试软件状态，不是接口响应，REQ-TXN-004 / REQ-RST-003）
  axis_txn_status_e status = AXIS_ST_ACCEPTED;

  // 实用字段：数据字节（from_bytes 生成）
  byte unsigned bytes[$];

  `uvm_object_utils(axi4_stream_beat_item)

  function new(string name = "axi4_stream_beat_item");
    super.new(name);
  endfunction

  function string convert2string();
    return $sformatf(
      "beat(data=%h keep=%h strb=%h last=%b id=%h dest=%h user=%h idle=%0d txn=%0d inject=%0b/%s)",
      data, keep, strb, last, id, dest, user, idle_cycles, local_txn_id,
      inject_enable, inject_rule);
  endfunction

endclass : axi4_stream_beat_item

// ---------------------------------------------------------------------------
// packet item：包级请求（REQ-TXN-002/003/004）
// ---------------------------------------------------------------------------
class axi4_stream_packet_item extends uvm_sequence_item;

  stream_key_t               key;
  byte unsigned              payload[$];        // from_bytes 输入
  axi4_stream_beat_item      beats[$];          // from_beats / 增量构造结果
  int unsigned               data_byte_count;
  int unsigned               position_byte_count;
  axis_end_kind_e            end_kind = AXIS_END_TLAST;
  time                       start_time;
  time                       end_time;
  axis_txn_status_e          status = AXIS_ST_ACCEPTED;

  `uvm_object_utils(axi4_stream_packet_item)

  function new(string name = "axi4_stream_packet_item");
    super.new(name);
  endfunction

  // from_bytes：默认紧密排列 DATA、最后一拍用 TKEEP 标识余数（REQ-TXN-002）
  // 无 TKEEP 时不能静默填充有效字节：无法精确表达的长度被拒绝（返回 0）。
  function bit from_bytes(
    byte unsigned in_bytes[$], stream_key_t k,
    bit has_tkeep, int bytes_per_beat,
    bit pad_enable = 1'b0, byte unsigned pad_byte = 8'h00
  );
    int nbytes, nbeats, b, idx;
    axi4_stream_beat_item item;
    logic [axi4_stream_types_pkg::AXIS_MAX_BYTES-1:0] kmask;
    nbytes = in_bytes.size();
    if (!axi4_stream_types_pkg::axis_bytes_expressible(nbytes, bytes_per_beat, has_tkeep || pad_enable)) begin
      `uvm_error("AXIS-TXN", $sformatf(
        "from_bytes 无法在 HAS_TKEEP=%0b 下精确表达 %0d 字节（需明确 padding 合同，REQ-TXN-002）",
        has_tkeep, nbytes))
      return 1'b0;
    end
    nbeats = axi4_stream_types_pkg::axis_beat_count_for_bytes(nbytes, bytes_per_beat);
    if (nbeats < 0) return 1'b0;
    key    = k;
    payload.delete();
    foreach (in_bytes[i]) payload.push_back(in_bytes[i]);
    beats.delete();
    for (b = 0; b < nbeats; b++) begin
      item = axi4_stream_beat_item::type_id::create($sformatf("byte_beat_%0d", b));
      item.data = '0;
      kmask = axi4_stream_types_pkg::axis_keep_for_beat(nbytes, bytes_per_beat, b);
      for (int lane = 0; lane < bytes_per_beat; lane++) begin
        idx = b * bytes_per_beat + lane;
        if (idx < nbytes) begin
          item.data[8*lane +: 8] = in_bytes[idx];
        end else if (pad_enable) begin
          item.data[8*lane +: 8] = pad_byte;
        end
      end
      item.keep = kmask;
      item.strb = kmask;                          // DATA bytes
      item.id   = k.tid[31:0];
      item.dest = k.tdest[31:0];
      item.last = 1'b0;
      item.bytes.delete();
      for (int lane = 0; lane < bytes_per_beat; lane++) begin
        idx = b * bytes_per_beat + lane;
        if (idx < nbytes) item.bytes.push_back(in_bytes[idx]);
      end
      beats.push_back(item);
    end
    if (beats.size() > 0) beats[beats.size()-1].last = 1'b1;
    end_kind = AXIS_END_TLAST;
    data_byte_count = nbytes;
    return 1'b1;
  endfunction

  // from_beats：直接使用给定 beat 序列
  function void from_beats(axi4_stream_beat_item in_beats[$], stream_key_t k);
    key = k;
    beats.delete();
    foreach (in_beats[i]) beats.push_back(in_beats[i]);
    end_kind = AXIS_END_TLAST;
  endfunction

  // 增量构造：追加一个 beat
  function void append_beat(axi4_stream_beat_item b);
    beats.push_back(b);
  endfunction

  function string convert2string();
    return $sformatf("packet(key=%s beats=%0d data_bytes=%0d pos_bytes=%0d end=%s status=%s)",
      axis_key_string(key), beats.size(), data_byte_count, position_byte_count,
      end_kind.name(), status.name());
  endfunction

endclass : axi4_stream_packet_item

// ---------------------------------------------------------------------------
// ready policy item：背压控制请求（REQ-SNK-001）
// ---------------------------------------------------------------------------
typedef enum {
  AXIS_READY_ALWAYS, AXIS_READY_FIXED_DELAY, AXIS_READY_RANDOM, AXIS_READY_PERIODIC,
  AXIS_READY_WAIT_VALID, AXIS_READY_BURST_ACCEPT, AXIS_READY_TARGETED,
  AXIS_READY_BUFFER_MODEL, AXIS_READY_SCRIPTED
} axis_ready_mode_e;

class axi4_stream_ready_item extends uvm_sequence_item;

  axis_ready_mode_e mode = AXIS_READY_ALWAYS;
  int               delay = 0;             // FIXED_DELAY 的 N（含 N=0 边界）
  int               prob_percent = 50;     // RANDOM 概率
  int               max_stall = 4;         // RANDOM 连续 stall 上限
  int               high_cycles = 1;       // PERIODIC ready 高 M 拍
  int               low_cycles = 1;        // PERIODIC ready 低 N 拍
  int               burst_k = 4;           // BURST_ACCEPT 接收 K 拍
  int               burst_n = 2;           // BURST_ACCEPT 暂停 N 拍
  int               target_beat = 0;       // TARGETED 第 K 拍
  int               buffer_depth = 8;      // BUFFER_MODEL 深度
  int               consume_rate = 1;      // BUFFER_MODEL 消费速率（拍/周期）
  int               repeat_count = 1;      // 持续次数
  int               seed = 0;              // 随机 seed（可重放）
  bit               enable = 1'b1;

  `uvm_object_utils(axi4_stream_ready_item)

  function new(string name = "axi4_stream_ready_item");
    super.new(name);
  endfunction

  function string convert2string();
    return $sformatf("ready(mode=%s delay=%0d prob=%0d%% stall_max=%0d %0d/%0d K=%0d N=%0d depth=%0d rate=%0d seed=%0d)",
      mode.name(), delay, prob_percent, max_stall, high_cycles, low_cycles,
      burst_k, burst_n, buffer_depth, consume_rate, seed);
  endfunction

endclass : axi4_stream_ready_item

// ---------------------------------------------------------------------------
// observed beat：monitor 采样事实（REQ-TXN-001）
// ---------------------------------------------------------------------------
class axi4_stream_observed_beat extends uvm_object;

  logic [axi4_stream_types_pkg::AXIS_MAX_BITS-1:0]  data;    // 原始采样值
  logic [axi4_stream_types_pkg::AXIS_MAX_BYTES-1:0] keep;
  logic [axi4_stream_types_pkg::AXIS_MAX_BYTES-1:0] strb;
  logic                                             last;
  logic [31:0]                                      id;
  logic [31:0]                                      dest;
  logic [axi4_stream_types_pkg::AXIS_MAX_USER_WIDTH-1:0] user;

  // 归一化语义
  logic [axi4_stream_types_pkg::AXIS_MAX_BYTES-1:0] keep_norm;
  logic [axi4_stream_types_pkg::AXIS_MAX_BYTES-1:0] strb_norm;
  int  data_bytes;
  int  position_bytes;
  int  null_bytes;
  bit  illegal_present;

  int         interface_id;
  int         reset_epoch;
  time        timestamp;
  longint     cycle;
  bit         handshake;           // 成功握手：TVALID && effective_TREADY && !reset
  int         wait_cycles;         // valid 到握手等待周期
  bit         in_reset;
  bit         partial_capture;     // 中途启用监控（REQ-MON-006）

  `uvm_object_utils(axi4_stream_observed_beat)

  function new(string name = "axi4_stream_observed_beat");
    super.new(name);
  endfunction

  function axi4_stream_observed_beat clone_beat();
    axi4_stream_observed_beat c;
    c = axi4_stream_observed_beat::type_id::create("obs_clone");
    c.copy(this);
    return c;
  endfunction

  function void copy(axi4_stream_observed_beat other);
    data=other.data; keep=other.keep; strb=other.strb; last=other.last;
    id=other.id; dest=other.dest; user=other.user;
    keep_norm=other.keep_norm; strb_norm=other.strb_norm;
    data_bytes=other.data_bytes; position_bytes=other.position_bytes; null_bytes=other.null_bytes;
    illegal_present=other.illegal_present;
    interface_id=other.interface_id; reset_epoch=other.reset_epoch;
    timestamp=other.timestamp; cycle=other.cycle; handshake=other.handshake;
    wait_cycles=other.wait_cycles; in_reset=other.in_reset;
    partial_capture=other.partial_capture;
  endfunction

  function string convert2string();
    return $sformatf(
      "obs(if=%0d epoch=%0d cyc=%0d hs=%0b wait=%0d data=%h keep=%h strb=%h last=%b id=%h dest=%h user=%h)",
      interface_id, reset_epoch, cycle, handshake, wait_cycles,
      data, keep, strb, last, id, dest, user);
  endfunction

endclass : axi4_stream_observed_beat

// ---------------------------------------------------------------------------
// observed packet：monitor 组包结果（REQ-MON-003/004）
// ---------------------------------------------------------------------------
class axi4_stream_observed_packet extends uvm_object;

  stream_key_t                  key;
  axi4_stream_observed_beat     beats[$];
  int unsigned                  data_byte_count;
  int unsigned                  position_byte_count;
  int unsigned                  null_byte_count;
  axis_end_kind_e               end_kind = AXIS_END_NONE;
  time                          start_time;
  time                          end_time;
  int                           interface_id;
  int                           reset_epoch;
  bit                           aborted_by_reset = 1'b0;
  bit                           partial_capture  = 1'b0;

  `uvm_object_utils(axi4_stream_observed_packet)

  function new(string name = "axi4_stream_observed_packet");
    super.new(name);
  endfunction

  // 逻辑流 token（LOGICAL_STREAM 比较用，REQ-SCB-002）
  function void to_tokens(output axi4_stream_types_pkg::axis_token_t tokens[$]);
    axi4_stream_types_pkg::axis_token_t tmp[];
    int count;
    tokens.delete();
    foreach (beats[i]) begin
      axi4_stream_types_pkg::axis_tokenize_beat(
        beats[i].data, 1'b1, beats[i].keep_norm, 1'b1, beats[i].strb_norm,
        1'b1, beats[i].last, byte_lanes_of(), tmp, count);
      for (int t = 0; t < count; t++) tokens.push_back(tmp[t]);
    end
  endfunction

  function int byte_lanes_of();
    // 由第一个 beat 中非零 keep 的宽度推断；仅用于 token 化的 lane 扫描范围
    return axi4_stream_types_pkg::AXIS_MAX_BYTES;
  endfunction

  function string convert2string();
    return $sformatf("obs_packet(key=%s beats=%0d data=%0d pos=%0d null=%0d end=%s abort=%0b)",
      axis_key_string(key), beats.size(), data_byte_count, position_byte_count,
      null_byte_count, end_kind.name(), aborted_by_reset);
  endfunction

endclass : axi4_stream_observed_packet

// ---------------------------------------------------------------------------
// error event：结构化违规事件（REQ-TXN-001 / REQ-CHK-003）
// ---------------------------------------------------------------------------
class axi4_stream_error_event extends uvm_object;

  string                            rule_id;
  string                            category;    // PROTOCOL/APPLICATION/WATCHDOG/CONFIG/VIP_INTERNAL
  axi4_stream_types_pkg::axis_severity_e severity;
  int                               interface_id;
  int                               reset_epoch;
  time                              timestamp;
  longint                           cycle;
  string                            before_sample;   // 前后采样
  string                            after_sample;
  stream_key_t                      key;
  int                               packet_beat_index = -1;
  string                            injection_ref = "";   // 注入关联
  string                            description;

  `uvm_object_utils(axi4_stream_error_event)

  function new(string name = "axi4_stream_error_event");
    super.new(name);
  endfunction

  function string convert2string();
    return $sformatf("[%s] %s sev=%s if=%0d epoch=%0d cyc=%0d key=%s beat=%0d %s",
      category, rule_id, severity.name(), interface_id, reset_epoch, cycle,
      axis_key_string(key), packet_beat_index, description);
  endfunction

endclass : axi4_stream_error_event

`endif // AXI4_STREAM_ITEM__SV
