// =============================================================================
// File Name   : axi4_stream_types_pkg.sv
// Description : axi4_stream VIP 纯逻辑类型与语义函数（无 UVM 依赖）
//               提供 byte 分类、缺省端口归一化、token 化与配置校验的单一实现。
//               该 package 是 src/ 内唯一的协议语义实现，driver/monitor/checker/
//               coverage/scoreboard/unit_test 均调用此处函数，避免多处重复实现。
// 依据        : docs/requirement.md（REQ-PRO-005/006/007, REQ-CFG-002..006,
//               REQ-TXN-002/003, REQ-SCB-002）
// =============================================================================

`ifndef AXI4_STREAM_TYPES_PKG__SV
`define AXI4_STREAM_TYPES_PKG__SV

package axi4_stream_types_pkg;

  // ---------------------------------------------------------------------------
  // 编译期上限（REQ-CFG-001：静态端口形状由 elaboration 参数决定）
  // 仅为内部容器上限，不改变对用户声明的位宽支持范围（8~4096bit）。
  // ---------------------------------------------------------------------------
  localparam int AXIS_MAX_DATA_WIDTH = 4096;
  localparam int AXIS_MAX_BITS       = AXIS_MAX_DATA_WIDTH;
  localparam int AXIS_MAX_BYTES      = AXIS_MAX_DATA_WIDTH / 8;   // 512
  localparam int AXIS_MAX_USER_WIDTH = 4096;

  // byte 分类（REQ-PRO-005 表）
  typedef enum logic [1:0] {
    AXIS_BYTE_DATA     = 2'd0,   // TKEEP=1, TSTRB=1：保留位置与数据值
    AXIS_BYTE_POSITION = 2'd1,   // TKEEP=1, TSTRB=0：保留位置，数据值无效
    AXIS_BYTE_NULL     = 2'd2,   // TKEEP=0, TSTRB=0：逻辑流可移除
    AXIS_BYTE_ILLEGAL  = 2'd3    // TKEEP=0, TSTRB=1：协议错误
  } axis_byte_class_e;

  // 逻辑流 token（REQ-SCB-002）
  typedef enum logic [1:0] {
    AXIS_TOKEN_DATA       = 2'd0,
    AXIS_TOKEN_POSITION   = 2'd1,
    AXIS_TOKEN_END_PACKET = 2'd2
  } axis_token_kind_e;

  typedef struct {
    axis_token_kind_e kind;
    logic [7:0]       value;
  } axis_token_t;

  // 包结束类型（REQ-MON-004 / REQ-TXN-001）
  typedef enum logic [1:0] {
    AXIS_END_NONE       = 2'd0,
    AXIS_END_TLAST      = 2'd1,
    AXIS_END_SYNTHETIC  = 2'd2   // FIXED_BEATS/CONTINUOUS 的本地解释，不冒充协议 TLAST
  } axis_end_kind_e;

  // 错误严重度（REQ-CHK-003 / REQ-TXN-001）
  typedef enum logic [1:0] {
    AXIS_SEV_INFO    = 2'd0,
    AXIS_SEV_WARNING = 2'd1,
    AXIS_SEV_ERROR   = 2'd2,
    AXIS_SEV_FATAL   = 2'd3
  } axis_severity_e;

  // ---------------------------------------------------------------------------
  // 宽度掩码与缺省端口归一化（REQ-CFG-002）
  // 未存在的物理信号不得参加 X/stability 检查：归一化函数返回的是语义值，
  // 调用方必须用 exists_* 判定是否参与检查。
  // ---------------------------------------------------------------------------

  // nbytes 位全 1 掩码（声明在所有归一化函数之前，供其调用）
  function automatic logic [AXIS_MAX_BYTES-1:0] axis_byte_mask(int nbytes);
    logic [AXIS_MAX_BYTES-1:0] mask;
    mask = '0;
    for (int i = 0; i < nbytes && i < AXIS_MAX_BYTES; i++) mask[i] = 1'b1;
    return mask;
  endfunction

  // 缺省 TREADY 恒为 1
  function automatic logic axis_effective_ready(bit has_tready, logic tready);
    return has_tready ? tready : 1'b1;
  endfunction

  // 缺省 TKEEP 为全 1
  function automatic logic [AXIS_MAX_BYTES-1:0] axis_effective_keep(
    bit has_tkeep, logic [AXIS_MAX_BYTES-1:0] keep, int nbytes
  );
    logic [AXIS_MAX_BYTES-1:0] mask;
    mask = axis_byte_mask(nbytes);
    return has_tkeep ? (keep & mask) : mask;
  endfunction

  // 缺省 TSTRB 按有效 TKEEP 归一化；两者均缺省为全 1
  function automatic logic [AXIS_MAX_BYTES-1:0] axis_effective_strb(
    bit has_tkeep, logic [AXIS_MAX_BYTES-1:0] keep,
    bit has_tstrb, logic [AXIS_MAX_BYTES-1:0] strb, int nbytes
  );
    logic [AXIS_MAX_BYTES-1:0] keep_n;
    keep_n = axis_effective_keep(has_tkeep, keep, nbytes);
    if (has_tstrb) return strb & axis_byte_mask(nbytes);
    if (has_tkeep) return keep_n;          // 缺省：与有效 TKEEP 相同
    return axis_byte_mask(nbytes);         // 两者均缺省：全 1
  endfunction

  // ---------------------------------------------------------------------------
  // byte 分类与计数（REQ-PRO-005 / REQ-PRO-006 / REQ-COV-001）
  // ---------------------------------------------------------------------------
  function automatic axis_byte_class_e axis_classify_byte(bit keep, bit strb);
    if (keep && strb)  return AXIS_BYTE_DATA;
    if (keep && !strb) return AXIS_BYTE_POSITION;
    if (!keep && !strb) return AXIS_BYTE_NULL;
    return AXIS_BYTE_ILLEGAL;            // keep=0, strb=1
  endfunction

  // DATA 字节数（keep=1 && strb=1）
  function automatic int axis_data_byte_count(
    bit has_tkeep, logic [AXIS_MAX_BYTES-1:0] keep,
    bit has_tstrb, logic [AXIS_MAX_BYTES-1:0] strb, int nbytes
  );
    logic [AXIS_MAX_BYTES-1:0] k, s;
    int count;
    k = axis_effective_keep(has_tkeep, keep, nbytes);
    s = axis_effective_strb(has_tkeep, keep, has_tstrb, strb, nbytes);
    count = 0;
    for (int i = 0; i < nbytes; i++) if (k[i] && s[i]) count++;
    return count;
  endfunction

  // POSITION 字节数（keep=1 && strb=0）
  function automatic int axis_position_byte_count(
    bit has_tkeep, logic [AXIS_MAX_BYTES-1:0] keep,
    bit has_tstrb, logic [AXIS_MAX_BYTES-1:0] strb, int nbytes
  );
    logic [AXIS_MAX_BYTES-1:0] k, s;
    int count;
    k = axis_effective_keep(has_tkeep, keep, nbytes);
    s = axis_effective_strb(has_tkeep, keep, has_tstrb, strb, nbytes);
    count = 0;
    for (int i = 0; i < nbytes; i++) if (k[i] && !s[i]) count++;
    return count;
  endfunction

  // NULL 字节数（keep=0 && strb=0）
  function automatic int axis_null_byte_count(
    bit has_tkeep, logic [AXIS_MAX_BYTES-1:0] keep,
    bit has_tstrb, logic [AXIS_MAX_BYTES-1:0] strb, int nbytes
  );
    logic [AXIS_MAX_BYTES-1:0] k, s;
    int count;
    k = axis_effective_keep(has_tkeep, keep, nbytes);
    s = axis_effective_strb(has_tkeep, keep, has_tstrb, strb, nbytes);
    count = 0;
    for (int i = 0; i < nbytes; i++) if (!k[i] && !s[i]) count++;
    return count;
  endfunction

  // 非法组合是否存在（keep=0 && strb=1），对应 AXIS-P005
  function automatic bit axis_illegal_byte_present(
    bit has_tkeep, logic [AXIS_MAX_BYTES-1:0] keep,
    bit has_tstrb, logic [AXIS_MAX_BYTES-1:0] strb, int nbytes
  );
    logic [AXIS_MAX_BYTES-1:0] k, s;
    if (!has_tstrb) return 1'b0;
    k = axis_effective_keep(has_tkeep, keep, nbytes);
    s = axis_effective_strb(has_tkeep, keep, has_tstrb, strb, nbytes);
    for (int i = 0; i < nbytes; i++) if (!k[i] && s[i]) return 1'b1;
    return 1'b0;
  endfunction

  // data byte 有效载荷中是否存在未知值（POSITION/NULL 不做有效载荷 X 检查，
  // REQ-CHK-001 / AXIS-P008）
  function automatic bit axis_payload_has_unknown(
    logic [AXIS_MAX_BITS-1:0] data,
    bit has_tkeep, logic [AXIS_MAX_BYTES-1:0] keep,
    bit has_tstrb, logic [AXIS_MAX_BYTES-1:0] strb, int nbytes
  );
    logic [AXIS_MAX_BYTES-1:0] k, s;
    k = axis_effective_keep(has_tkeep, keep, nbytes);
    s = axis_effective_strb(has_tkeep, keep, has_tstrb, strb, nbytes);
    for (int i = 0; i < nbytes; i++) begin
      if (k[i] && s[i]) begin
        if ((^data[8*i +: 8]) === 1'bx) return 1'b1;
      end
    end
    return 1'b0;
  endfunction

  // ---------------------------------------------------------------------------
  // 逻辑流 token 化（REQ-SCB-002 / REQ-PRO-007）
  // NULL 移除；POSITION 保留位置；END_PACKET 不得移除，也不得跨包合并。
  // ---------------------------------------------------------------------------
  function automatic void axis_tokenize_beat(
    logic [AXIS_MAX_BITS-1:0] data,
    bit has_tkeep, logic [AXIS_MAX_BYTES-1:0] keep,
    bit has_tstrb, logic [AXIS_MAX_BYTES-1:0] strb,
    bit has_tlast, bit tlast,
    int nbytes,
    output axis_token_t tokens[],
    output int count
  );
    logic [AXIS_MAX_BYTES-1:0] k, s;
    axis_byte_class_e cls;
    count = 0;
    if (tokens.size() < nbytes + 1) tokens = new [nbytes + 1];
    k = axis_effective_keep(has_tkeep, keep, nbytes);
    s = axis_effective_strb(has_tkeep, keep, has_tstrb, strb, nbytes);
    for (int i = 0; i < nbytes; i++) begin
      cls = axis_classify_byte(k[i], s[i]);
      case (cls)
        AXIS_BYTE_DATA: begin
          tokens[count].kind  = AXIS_TOKEN_DATA;
          tokens[count].value = data[8*i +: 8];
          count++;
        end
        AXIS_BYTE_POSITION: begin
          tokens[count].kind  = AXIS_TOKEN_POSITION;
          tokens[count].value = 8'h00;   // POSITION 不比较数据值
          count++;
        end
        AXIS_BYTE_NULL: ;               // NULL 从逻辑流移除
        default: ;                      // 非法组合由 checker 报错，token 化跳过
      endcase
    end
    // 全 NULL beat 仍必须保留包结束事件（REQ-PRO-007）
    if (has_tlast && tlast) begin
      tokens[count].kind  = AXIS_TOKEN_END_PACKET;
      tokens[count].value = 8'h00;
      count++;
    end
  endfunction

  // ---------------------------------------------------------------------------
  // 包 API 支持（REQ-TXN-002 / REQ-TXN-003）
  // from_bytes 默认紧密排列 DATA、最后一拍用 TKEEP 标识余数。
  // ---------------------------------------------------------------------------
  // 需要的 beat 数（nbytes=0 时仍需要 1 拍以表达边界）
  function automatic int axis_beat_count_for_bytes(int nbytes, int bytes_per_beat);
    int beats;
    if (bytes_per_beat <= 0) return -1;
    if (nbytes < 0) return -1;
    beats = (nbytes + bytes_per_beat - 1) / bytes_per_beat;
    if (beats == 0) beats = 1;
    return beats;
  endfunction

  // 指定 beat 的 TKEEP 掩码：紧密排列 + 末拍余数
  function automatic logic [AXIS_MAX_BYTES-1:0] axis_keep_for_beat(
    int nbytes, int bytes_per_beat, int beat_index
  );
    logic [AXIS_MAX_BYTES-1:0] mask;
    int remain;
    mask  = '0;
    if (bytes_per_beat <= 0) return mask;
    remain = nbytes - beat_index * bytes_per_beat;
    if (remain >= bytes_per_beat) return axis_byte_mask(bytes_per_beat);
    if (remain <= 0) return mask;
    return axis_byte_mask(remain);
  endfunction

  // 无 TKEEP 时无法精确表达余数：拒绝无法精确表示的长度（REQ-TXN-002）
  function automatic bit axis_bytes_expressible(int nbytes, int bytes_per_beat, bit has_tkeep);
    if (bytes_per_beat <= 0 || nbytes < 0) return 1'b0;
    if (has_tkeep) return 1'b1;
    return (nbytes % bytes_per_beat) == 0;
  endfunction

  // ---------------------------------------------------------------------------
  // 配置合法性（REQ-CFG-005 / REQ-CFG-006 / REQ-CFG-004）
  // 返回 0 表示非法，reason 给出配置名、值与原因（elaboration/build 阶段失败）
  // ---------------------------------------------------------------------------
  function automatic bit axis_config_check(
    bit         has_tdata,
    int         data_width,
    bit         has_tkeep,
    bit         has_tstrb,
    bit         has_tlast,
    int         id_width,
    int         dest_width,
    int         user_width,
    int         per_byte_user_ratio,
    output string reason
  );
    reason = "";
    if (data_width < 8 || data_width > AXIS_MAX_DATA_WIDTH || (data_width % 8) != 0) begin
      reason = $sformatf("DATA_WIDTH=%0d 非法：需为 8 的正整数倍且 8~%0d", data_width, AXIS_MAX_DATA_WIDTH);
      return 1'b0;
    end
    if (has_tdata && !has_tlast && has_tkeep) begin
      // TLAST 缺省时仍可用 TKEEP 表达边界，但不得隐式推断 tlast（REQ-CFG-003）
      // 因此这里是合法组合，只要求用户在 packet_mode 显式选择。
    end
    if (!has_tdata && (has_tkeep || has_tstrb)) begin
      reason = "HAS_TDATA=0 时禁止开启 TKEEP/TSTRB（REQ-CFG-005）";
      return 1'b0;
    end
    if (id_width < 0 || id_width > 32) begin
      reason = $sformatf("ID_WIDTH=%0d 非法：允许 0~32", id_width);
      return 1'b0;
    end
    if (dest_width < 0 || dest_width > 32) begin
      reason = $sformatf("DEST_WIDTH=%0d 非法：允许 0~32", dest_width);
      return 1'b0;
    end
    if (user_width < 0 || user_width > AXIS_MAX_USER_WIDTH) begin
      reason = $sformatf("USER_WIDTH=%0d 非法：允许 0~%0d", user_width, AXIS_MAX_USER_WIDTH);
      return 1'b0;
    end
    // USER 不要求为 lane 数的整数倍，只有选择 PER_BYTE 映射时才检查整除（REQ-CFG-004）
    if (per_byte_user_ratio > 0) begin
      if (user_width == 0 || (user_width % per_byte_user_ratio) != 0) begin
        reason = $sformatf(
          "PER_BYTE USER 映射要求 USER_WIDTH=%0d 为 lane 数 %0d 的整数倍（REQ-CFG-004）",
          user_width, per_byte_user_ratio
        );
        return 1'b0;
      end
    end
    return 1'b1;
  endfunction

  // virtual interface 参数与 agent 参数一致性（REQ-CFG-006：不一致必须失败）
  function automatic bit axis_vif_matches(
    bit         vif_has_tready,
    int         vif_data_width,
    bit         cfg_has_tready,
    int         cfg_data_width
  );
    return (vif_has_tready == cfg_has_tready) && (vif_data_width == cfg_data_width);
  endfunction

  // ---------------------------------------------------------------------------
  // 比较语义（REQ-SCB-002 / REQ-SCB-003）
  // ---------------------------------------------------------------------------
  // EXACT_BEAT：beat 个数、qualifier、边界、ID/DEST/USER 与有效 lane 值
  function automatic bit axis_exact_beat_equal(
    logic [AXIS_MAX_BITS-1:0] a_data, logic [AXIS_MAX_BYTES-1:0] a_keep, logic [AXIS_MAX_BYTES-1:0] a_strb,
    logic [AXIS_MAX_BITS-1:0] b_data, logic [AXIS_MAX_BYTES-1:0] b_keep, logic [AXIS_MAX_BYTES-1:0] b_strb,
    int nbytes
  );
    logic [AXIS_MAX_BYTES-1:0] k;
    if (a_keep !== b_keep) return 1'b0;
    if (a_strb !== b_strb) return 1'b0;
    for (int i = 0; i < nbytes; i++) begin
      k = axis_effective_keep(1'b1, a_keep, nbytes);
      if (k[i] && a_strb[i]) begin
        if (a_data[8*i +: 8] !== b_data[8*i +: 8]) return 1'b0;
      end
    end
    return 1'b1;
  endfunction

  // 逻辑流 token 序列比较：NULL 已移除，POSITION 保留位置，END_PACKET 保留
  function automatic bit axis_token_stream_equal(axis_token_t a[], axis_token_t b[]);
    if (a.size() != b.size()) return 1'b0;
    for (int i = 0; i < a.size(); i++) begin
      if (a[i].kind !== b[i].kind) return 1'b0;
      if (a[i].kind == AXIS_TOKEN_DATA && a[i].value !== b[i].value) return 1'b0;
    end
    return 1'b1;
  endfunction

endpackage : axi4_stream_types_pkg

`endif // AXI4_STREAM_TYPES_PKG__SV