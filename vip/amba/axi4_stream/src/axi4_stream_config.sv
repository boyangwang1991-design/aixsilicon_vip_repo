// =============================================================================
// File Name   : axi4_stream_config.sv
// Description : axi4_stream VIP 配置对象（结构参数镜像 + 运行期行为 + 校验）
// 依据        : docs/requirement.md（REQ-CFG-001..007, REQ-SNK-001..004,
//               REQ-SCB-001/003/004, REQ-INT-003）
//
// 设计说明：
//   * 静态端口形状（HAS_*、宽度）在 elaboration 固定；本对象只镜像并在 build
//     阶段与 virtual interface 参数核对（REQ-CFG-006）。
//   * 影响组包/比较语义的配置只能在 drain/复位后更新，并记录 configuration_epoch
//     （REQ-INT-003）。
//   * 不支持的配置在 build 阶段明确失败，输出配置名、值与原因，禁止静默截断。
// =============================================================================

`ifndef AXI4_STREAM_CONFIG__SV
`define AXI4_STREAM_CONFIG__SV

// 角色（REQ-CFG-001 ROLE）：必须显式设置
typedef enum { AXIS_ROLE_SOURCE, AXIS_ROLE_SINK, AXIS_ROLE_PASSIVE } axis_role_e;

// 组包模式（REQ-CFG-003 PACKET_MODE）
typedef enum { AXIS_PKT_TLAST, AXIS_PKT_CONTINUOUS, AXIS_PKT_FIXED_BEATS } axis_packet_mode_e;

// 比较模式（REQ-SCB-001 COMPARE_MODE）
typedef enum { AXIS_CMP_EXACT_BEAT, AXIS_CMP_LOGICAL_STREAM, AXIS_CMP_CUSTOM } axis_compare_mode_e;

// 抓取模式（REQ-PERF-004 CAPTURE_MODE）
typedef enum { AXIS_CAPTURE_FULL, AXIS_CAPTURE_STREAMING } axis_capture_mode_e;

// TUSER 跨位宽映射（REQ-SCB-003）
typedef enum {
  AXIS_USER_OPAQUE_PER_BEAT, AXIS_USER_PER_BYTE, AXIS_USER_PER_PACKET, AXIS_USER_CUSTOM
} axis_user_map_e;

// 全局保序 / 逐 key 保序（REQ-SCB-004）
typedef enum { AXIS_ORDER_GLOBAL, AXIS_ORDER_PER_KEY } axis_order_mode_e;

// DUT 复位合同（REQ-RST-005）
typedef enum { AXIS_CDC_BOTH_FLUSH, AXIS_CDC_PRESERVE, AXIS_CDC_CUSTOM } axis_cdc_reset_e;

// 预定义配置 profile（REQ-CFG / docs/architecture.md §9）
typedef enum {
  AXIS_PROFILE_DEFAULT, AXIS_PROFILE_ZERO_DELAY, AXIS_PROFILE_HEAVY_BACKPRESSURE,
  AXIS_PROFILE_STRESS, AXIS_PROFILE_PASSIVE
} axis_config_profile_e;

class axi4_stream_config extends uvm_object;

  `uvm_object_utils(axi4_stream_config)

  // ---- 结构参数镜像（与 interface 参数必须一致）----
  int  data_width   = 64;
  int  id_width     = 0;
  int  dest_width   = 0;
  int  user_width   = 0;
  bit  has_tdata    = 1'b1;
  bit  has_tready   = 1'b1;
  bit  has_tkeep    = 1'b1;
  bit  has_tstrb    = 1'b0;
  bit  has_tlast    = 1'b1;

  // ---- 角色与行为 ----
  axis_role_e         role          = AXIS_ROLE_SOURCE;   // 必须显式设置
  bit                 role_configured = 1'b0;
  axis_packet_mode_e  packet_mode   = AXIS_PKT_TLAST;
  bit                 packet_mode_configured = 1'b0;      // REQ-CFG-003 不得隐式推断
  axis_config_profile_e profile     = AXIS_PROFILE_DEFAULT;

  // ---- 容量与资源上限（VIP 资源限制，非协议限制）----
  int max_open_streams  = 256;      // REQ-CFG-001 MAX_OPEN_STREAMS（稀疏容器）
  int max_packet_beats  = 65536;    // REQ-CFG-001 MAX_PACKET_BEATS（本地限制）
  int max_ready_wait    = 0;        // 0=关闭；启用后为环境 watchdog
  int max_packet_idle   = 0;        // 0=关闭
  int max_queue_depth   = 64;       // 非阻塞提交的有界队列（REQ-TXN-006）

  // ---- 检查 / 覆盖 / 抓取 ----
  bit                  check_enable      = 1'b1;
  bit                  coverage_enable   = 1'b1;
  axis_capture_mode_e  capture_mode      = AXIS_CAPTURE_FULL;
  int                  history_limit     = 4096;   // STREAMING 模式的有限历史缓存

  // ---- 比较 / 顺序 / 复位合同 ----
  axis_compare_mode_e  compare_mode      = AXIS_CMP_EXACT_BEAT;   // 默认 EXACT_BEAT
  axis_user_map_e      user_map          = AXIS_USER_OPAQUE_PER_BEAT;
  bit                  user_compare_enable = 1'b1;   // 无映射合同的非透明转换须显式关闭
  axis_order_mode_e    order_mode        = AXIS_ORDER_GLOBAL;
  axis_cdc_reset_e     cdc_reset         = AXIS_CDC_BOTH_FLUSH;
  bit                  cdc_reset_configured = 1'b0;
  int                  width_ratio       = 1;        // DUT 扩宽/缩宽比（1=透明）

  // ---- 覆盖率相关旋钮（REQ-COV-003）----
  bit                  cov_handshake_enable = 1'b1;
  bit                  cov_packet_enable    = 1'b1;
  bit                  cov_qualifier_enable = 1'b1;
  bit                  cov_stream_enable    = 1'b1;
  bit                  cov_sideband_enable  = 1'b1;
  bit                  cov_reset_enable     = 1'b1;
  bit                  cov_errors_enable    = 1'b1;
  bit                  cov_transform_enable = 1'b1;

  // ---- 配置 epoch（REQ-INT-003：语义配置只能在 drain/复位后更新）----
  int                  configuration_epoch = 0;

  // ---- 复位后排队 item 处理（REQ-RST-002）----
  bit                  reset_retain_queued = 1'b0;   // 默认 FLUSH

  function new(string name = "axi4_stream_config");
    super.new(name);
  endfunction

  // ---------------------------------------------------------------------------
  // 非 2 的幂宽度也支持（REQ-CFG-001），byte lane 数按 DATA_WIDTH/8
  // ---------------------------------------------------------------------------
  function int byte_lanes();
    return data_width / 8;
  endfunction

  // ---------------------------------------------------------------------------
  // 应用预定义 profile（REQ-CFG §7.5）
  // ---------------------------------------------------------------------------
  function void apply_profile(axis_config_profile_e p);
    profile = p;
    case (p)
      AXIS_PROFILE_DEFAULT: ;
      AXIS_PROFILE_ZERO_DELAY: begin
        // 无额外背压：由 sink driver 的 ALWAYS_READY 策略实现
      end
      AXIS_PROFILE_HEAVY_BACKPRESSURE: begin
        max_queue_depth = 256;
      end
      AXIS_PROFILE_STRESS: begin
        max_packet_beats = 1000000;
        capture_mode     = AXIS_CAPTURE_STREAMING;
        history_limit    = 8192;
      end
      AXIS_PROFILE_PASSIVE: begin
        role = AXIS_ROLE_PASSIVE;
        role_configured = 1'b1;
      end
      default: ;
    endcase
  endfunction

  // ---------------------------------------------------------------------------
  // 结构合法性校验：返回 0 表示非法，非法时 uvm_fatal 并给出配置名/值/原因
  // 调用时机：agent build_phase（elaboration 后立即失败，REQ-CFG-006）
  // ---------------------------------------------------------------------------
  function bit validate(string context = "cfg");
    string reason;
    bit ok;
    if (!role_configured) begin
      `uvm_fatal("AXIS-CFG", $sformatf("[%s] ROLE 未显式设置（REQ-CFG-001）", context))
      return 1'b0;
    end
    if (!packet_mode_configured && !has_tlast) begin
      `uvm_fatal("AXIS-CFG", $sformatf(
        "[%s] HAS_TLAST=0 时必须显式选择连续流或应用边界策略（REQ-CFG-003）", context))
      return 1'b0;
    end
    ok = axi4_stream_types_pkg::axis_config_check(
      has_tdata, data_width, has_tkeep, has_tstrb, has_tlast,
      id_width, dest_width, user_width,
      (user_map == AXIS_USER_PER_BYTE) ? byte_lanes() : 0, reason);
    if (!ok) begin
      `uvm_fatal("AXIS-CFG", $sformatf(
        "[%s] 非法配置 data_width=%0d has_tdata=%0b has_tkeep=%0b has_tstrb=%0b id=%0d dest=%0d user=%0d: %s",
        context, data_width, has_tdata, has_tkeep, has_tstrb,
        id_width, dest_width, user_width, reason))
      return 1'b0;
    end
    if (max_open_streams <= 0 || max_packet_beats <= 0 || max_queue_depth <= 0) begin
      `uvm_fatal("AXIS-CFG", $sformatf(
        "[%s] 容量上限必须为正: max_open_streams=%0d max_packet_beats=%0d max_queue_depth=%0d",
        context, max_open_streams, max_packet_beats, max_queue_depth))
      return 1'b0;
    end
    if (compare_mode != AXIS_CMP_CUSTOM && width_ratio != 1 && !user_compare_enable) begin
      // 非透明转换且无映射合同：明确标识"不检查该维度"，不得宣称完整 PASS（REQ-SCB-003）
      `uvm_warning("AXIS-CFG", $sformatf(
        "[%s] width_ratio=%0d 且 user_compare_enable=0：TUSER 维度不参与比较（REQ-SCB-003）",
        context, width_ratio))
    end
    return 1'b1;
  endfunction

  // ---------------------------------------------------------------------------
  // 与 virtual interface 参数一致性（REQ-CFG-006：不一致必须失败）
  // ---------------------------------------------------------------------------
  function bit check_vif(
    bit vif_has_tready, int vif_data_width, bit vif_has_tdata,
    bit vif_has_tkeep, bit vif_has_tstrb, bit vif_has_tlast,
    int vif_id_width, int vif_dest_width, int vif_user_width
  );
    if (vif_data_width != data_width || vif_has_tdata != has_tdata ||
        vif_has_tkeep  != has_tkeep  || vif_has_tstrb  != has_tstrb ||
        vif_has_tlast  != has_tlast  || vif_id_width   != id_width ||
        vif_dest_width != dest_width || vif_user_width != user_width) begin
      `uvm_fatal("AXIS-CFG", $sformatf(
        "virtual interface 与 config 参数不一致: vif(data=%0d data=%0b keep=%0b strb=%0b last=%0b id=%0d dest=%0d user=%0d) cfg(data=%0d data=%0b keep=%0b strb=%0b last=%0b id=%0d dest=%0d user=%0d)",
        vif_data_width, vif_has_tdata, vif_has_tkeep, vif_has_tstrb, vif_has_tlast,
        vif_id_width, vif_dest_width, vif_user_width,
        data_width, has_tdata, has_tkeep, has_tstrb, has_tlast,
        id_width, dest_width, user_width))
      return 1'b0;
    end
    if (vif_has_tready != has_tready) begin
      `uvm_fatal("AXIS-CFG", $sformatf(
        "virtual interface HAS_TREADY=%0b 与 config HAS_TREADY=%0b 不一致", vif_has_tready, has_tready))
      return 1'b0;
    end
    return 1'b1;
  endfunction

  // ---------------------------------------------------------------------------
  // 语义配置更新：必须经 drain/复位，epoch 递增（REQ-INT-003）
  // ---------------------------------------------------------------------------
  function void begin_semantic_update(bit drained);
    if (!drained) begin
      `uvm_fatal("AXIS-CFG",
        "影响组包/比较语义的配置只能在 drain 或复位后更新（REQ-INT-003）")
      return;
    end
    configuration_epoch++;
  endfunction

  function string convert2string();
    return $sformatf(
      "axi4_stream_config(data=%0d id=%0d dest=%0d user=%0d data=%0b ready=%0b keep=%0b strb=%0b last=%0b role=%s pkt=%s cmp=%s epoch=%0d)",
      data_width, id_width, dest_width, user_width,
      has_tdata, has_tready, has_tkeep, has_tstrb, has_tlast,
      role.name(), packet_mode.name(), compare_mode.name(), configuration_epoch);
  endfunction

endclass : axi4_stream_config

`endif // AXI4_STREAM_CONFIG__SV
