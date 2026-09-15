// =============================================================================
// File Name   : axi4_stream_stream_model.sv
// Description : lane/byte/token 规范化模型（唯一语义实现入口）
// 依据        : docs/requirement.md（REQ-PRO-005..007, REQ-SCB-002/003,
//               REQ-MON-004, REQ-TXN-002）
//
// 设计说明：
//   * driver/monitor/checker/coverage/scoreboard 全部调用本模型，禁止各自实现
//     byte 分类、缺省归一化或 token 化（docs/architecture.md §8 单一语义模型）。
//   * 本模型是无状态对象，不持有总线事实，也不是 DUT 参考模型。
// =============================================================================

`ifndef AXI4_STREAM_STREAM_MODEL__SV
`define AXI4_STREAM_STREAM_MODEL__SV

class axi4_stream_stream_model extends uvm_object;

  `uvm_object_utils(axi4_stream_stream_model)

  int byte_lanes = 8;

  function new(string name = "axi4_stream_stream_model");
    super.new(name);
  endfunction

  function void configure(int in_byte_lanes);
    byte_lanes = in_byte_lanes;
  endfunction

  // byte 分类（代理到 types_pkg，保持唯一实现）
  function axi4_stream_types_pkg::axis_byte_class_e classify(bit keep, bit strb);
    return axi4_stream_types_pkg::axis_classify_byte(keep, strb);
  endfunction

  // 缺省归一化
  function logic [axi4_stream_types_pkg::AXIS_MAX_BYTES-1:0] norm_keep(
    bit has_tkeep, logic [axi4_stream_types_pkg::AXIS_MAX_BYTES-1:0] keep
  );
    return axi4_stream_types_pkg::axis_effective_keep(has_tkeep, keep, byte_lanes);
  endfunction

  function logic [axi4_stream_types_pkg::AXIS_MAX_BYTES-1:0] norm_strb(
    bit has_tkeep, logic [axi4_stream_types_pkg::AXIS_MAX_BYTES-1:0] keep,
    bit has_tstrb, logic [axi4_stream_types_pkg::AXIS_MAX_BYTES-1:0] strb
  );
    return axi4_stream_types_pkg::axis_effective_strb(
      has_tkeep, keep, has_tstrb, strb, byte_lanes);
  endfunction

  // 规范化统计
  function void normalize_stats(
    bit has_tkeep, logic [axi4_stream_types_pkg::AXIS_MAX_BYTES-1:0] keep,
    bit has_tstrb, logic [axi4_stream_types_pkg::AXIS_MAX_BYTES-1:0] strb,
    output int data_bytes, output int position_bytes, output int null_bytes,
    output bit illegal_present
  );
    data_bytes     = axi4_stream_types_pkg::axis_data_byte_count(has_tkeep, keep, has_tstrb, strb, byte_lanes);
    position_bytes = axi4_stream_types_pkg::axis_position_byte_count(has_tkeep, keep, has_tstrb, strb, byte_lanes);
    null_bytes     = axi4_stream_types_pkg::axis_null_byte_count(has_tkeep, keep, has_tstrb, strb, byte_lanes);
    illegal_present = axi4_stream_types_pkg::axis_illegal_byte_present(has_tkeep, keep, has_tstrb, strb, byte_lanes);
  endfunction

  // 有效载荷未知值（仅 DATA byte 检查，REQ-CHK-001 / AXIS-P008）
  function bit payload_unknown(
    logic [axi4_stream_types_pkg::AXIS_MAX_BITS-1:0] data,
    bit has_tkeep, logic [axi4_stream_types_pkg::AXIS_MAX_BYTES-1:0] keep,
    bit has_tstrb, logic [axi4_stream_types_pkg::AXIS_MAX_BYTES-1:0] strb
  );
    return axi4_stream_types_pkg::axis_payload_has_unknown(
      data, has_tkeep, keep, has_tstrb, strb, byte_lanes);
  endfunction

  // beat -> 逻辑流 token（NULL 移除、POSITION 保留、END_PACKET 保留）
  function void tokenize(
    logic [axi4_stream_types_pkg::AXIS_MAX_BITS-1:0] data,
    bit has_tkeep, logic [axi4_stream_types_pkg::AXIS_MAX_BYTES-1:0] keep,
    bit has_tstrb, logic [axi4_stream_types_pkg::AXIS_MAX_BYTES-1:0] strb,
    bit has_tlast, bit tlast,
    output axi4_stream_types_pkg::axis_token_t tokens[$]
  );
    axi4_stream_types_pkg::axis_token_t tmp[];
    int count;
    tokens.delete();
    axi4_stream_types_pkg::axis_tokenize_beat(
      data, has_tkeep, keep, has_tstrb, strb, has_tlast, tlast, byte_lanes, tmp, count);
    for (int i = 0; i < count; i++) tokens.push_back(tmp[i]);
  endfunction

  // TUSER 映射（REQ-SCB-003）：非透明转换必须有映射合同，否则不做隐式比较
  function logic [axi4_stream_types_pkg::AXIS_MAX_USER_WIDTH-1:0] map_user(
    axis_user_map_e mode, logic [axi4_stream_types_pkg::AXIS_MAX_USER_WIDTH-1:0] user,
    int src_lanes, int dst_lanes
  );
    logic [axi4_stream_types_pkg::AXIS_MAX_USER_WIDTH-1:0] mapped;
    mapped = '0;
    case (mode)
      AXIS_USER_OPAQUE_PER_BEAT:  mapped = user;
      AXIS_USER_PER_PACKET:       mapped = user;
      AXIS_USER_PER_BYTE: begin
        if (src_lanes == dst_lanes) mapped = user;
        // 位宽变化时不做隐式重排：由 CUSTOM 映射或显式关闭该维度处理
      end
      AXIS_USER_CUSTOM:           mapped = user;   // 由用户回调覆盖
      default:                    mapped = user;
    endcase
    return mapped;
  endfunction

  // 包 API：byte 长度 -> beat 数 / keep 掩码（转发到 types_pkg）
  function int beat_count_for_bytes(int nbytes);
    return axi4_stream_types_pkg::axis_beat_count_for_bytes(nbytes, byte_lanes);
  endfunction

  function logic [axi4_stream_types_pkg::AXIS_MAX_BYTES-1:0] keep_for_beat(int nbytes, int beat_index);
    return axi4_stream_types_pkg::axis_keep_for_beat(nbytes, byte_lanes, beat_index);
  endfunction

endclass : axi4_stream_stream_model

`endif // AXI4_STREAM_STREAM_MODEL__SV