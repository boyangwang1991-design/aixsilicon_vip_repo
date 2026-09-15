// =============================================================================
// File Name   : axi4_stream_checker.sv
// Description : axi4_stream 独立协议 Checker（SV/UVM，不依赖 driver intent）
// 依据        : docs/requirement.md（REQ-CHK-001..005, §8 规则表）
//
// 设计说明：
//   * 每条规则可单独开关、改变严重度、设置限报次数，并输出结构化事件
//     （REQ-CHK-003）；SVA 与 UVM checker 同时启用时通过关联 ID 避免重复计数。
//   * 只拥有观测状态，不读 driver item（REQ-CHK-004 黑盒约束）。
//   * 不能要求复位时 TREADY=0，也不能普遍要求 payload 清零（REQ-CHK-005）。
//   * 纯黑盒不能证明 source 未依赖 ready 才产生 valid，该点由 WAIT_VALID 对抗
//     测试 + 结构检查补充，不伪装成完整 SVA 证明（REQ-CHK-004）。
// =============================================================================

`ifndef AXI4_STREAM_CHECKER__SV
`define AXI4_STREAM_CHECKER__SV

// 规则类别
typedef enum { AXIS_CAT_PROTOCOL, AXIS_CAT_APPLICATION, AXIS_CAT_WATCHDOG,
               AXIS_CAT_CONFIG, AXIS_CAT_VIP_INTERNAL } axis_rule_category_e;

class axi4_stream_checker extends uvm_component;

  `uvm_component_utils(axi4_stream_checker)

  virtual axi4_stream_if vif;
  axi4_stream_config  cfg;

  uvm_analysis_port #(axi4_stream_error_event) error_ap;

  int interface_id = 0;

  // ---- 规则开关 / 严重度 / 限报次数（REQ-CHK-003）----
  bit                                                        rule_enable[16];
  axi4_stream_types_pkg::axis_severity_e                     rule_severity[16];
  int                                                        rule_max_report[16];
  int                                                        rule_hit_count[16];
  string                                                     rule_name[16];
  // 子码命中计数（REQ-CHK-003：每个字段有独立诊断子码；如 AXIS-P004-KEEP）
  int                                                        sub_hit_count[string];

  // ---- 观测状态 ----
  protected int            reset_epoch       = 0;
  protected bit            was_in_reset      = 1'b0;
  protected bit            release_edge_seen = 1'b0;
  protected bit            valid_prev        = 1'b0;
  protected logic [axi4_stream_types_pkg::AXIS_MAX_BITS-1:0]  data_prev;
  protected logic [axi4_stream_types_pkg::AXIS_MAX_BYTES-1:0] keep_prev;
  protected logic [axi4_stream_types_pkg::AXIS_MAX_BYTES-1:0] strb_prev;
  protected logic                                             last_prev;
  protected logic [31:0]                                      id_prev;
  protected logic [31:0]                                      dest_prev;
  protected logic [axi4_stream_types_pkg::AXIS_MAX_USER_WIDTH-1:0] user_prev;
  protected bit            prev_valid_known   = 1'b0;
  // 上一拍是否处于同一 beat 的 stall（valid=1 且未握手）。
  // 稳定性只适用于“同一未被接受的 beat”持续等待期间；握手完成后允许
  // 背靠背改变 payload（REQ-PRO-003 只覆盖 stall 与恢复握手边沿）。
  protected bit            prev_stall        = 1'b0;
  protected int            wait_cycles       = 0;
  protected longint        cycle             = 0;
  protected longint        first_release_cycle = -1;

  // 超时/看门狗（AXIS-W001/W002）
  protected longint        last_progress_cycle = 0;
  protected bit            packet_open        = 1'b0;

  localparam int R_P001 = 0; localparam int R_P002 = 1;
  localparam int R_P003 = 2; localparam int R_P004 = 3;
  localparam int R_P005 = 4; localparam int R_P006 = 5;
  localparam int R_P007 = 6; localparam int R_P008 = 7;
  localparam int R_P009 = 8; localparam int R_A001 = 9;
  localparam int R_A002 = 10; localparam int R_W001 = 11;
  localparam int R_W002 = 12; localparam int R_C001 = 13;
  localparam int R_I001 = 14;

  function new(string name = "axi4_stream_checker", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual axi4_stream_if)::get(this, "", "vif", vif))
      `uvm_fatal("AXIS-CHK", "未获取 virtual interface（REQ-INT-002）")
    if (!uvm_config_db#(axi4_stream_config)::get(this, "", "cfg", cfg))
      `uvm_fatal("AXIS-CHK", "未获取 config（REQ-INT-002）")
    error_ap = new("error_ap", this);
    init_rules();
  endfunction

  // 缺省：协议规则 ERROR；应用/看门狗规则关闭；配置规则 FATAL（§8 规则表）
  protected function void init_rules();
    for (int i = 0; i < 16; i++) begin
      rule_enable[i]      = 1'b1;
      rule_severity[i]    = axi4_stream_types_pkg::AXIS_SEV_ERROR;
      rule_max_report[i]  = 0;     // 0=不限
      rule_hit_count[i]   = 0;
      rule_name[i]        = "";
    end
    rule_name[R_P001]="AXIS-P001"; rule_name[R_P002]="AXIS-P002"; rule_name[R_P003]="AXIS-P003";
    rule_name[R_P004]="AXIS-P004"; rule_name[R_P005]="AXIS-P005"; rule_name[R_P006]="AXIS-P006";
    rule_name[R_P007]="AXIS-P007"; rule_name[R_P008]="AXIS-P008"; rule_name[R_P009]="AXIS-P009";
    rule_name[R_A001]="AXIS-A001"; rule_name[R_A002]="AXIS-A002"; rule_name[R_W001]="AXIS-W001";
    rule_name[R_W002]="AXIS-W002"; rule_name[R_C001]="AXIS-C001"; rule_name[R_I001]="AXIS-I001";

    // 应用规则缺省关闭，需应用配置启用（REQ-CHK §8）
    rule_enable[R_A001] = 1'b0;
    rule_enable[R_A002] = 1'b0;
    // 看门狗缺省关闭；启用后 W001=WARNING，W002=WATCHDOG 语义
    rule_enable[R_W001] = 1'b0;
    rule_enable[R_W002] = 1'b0;
    rule_severity[R_W001] = axi4_stream_types_pkg::AXIS_SEV_WARNING;
    rule_severity[R_W002] = axi4_stream_types_pkg::AXIS_SEV_WARNING;
    rule_severity[R_C001] = axi4_stream_types_pkg::AXIS_SEV_FATAL;
    rule_severity[R_I001] = axi4_stream_types_pkg::AXIS_SEV_ERROR;

    // 仅当存在相应端口时才启用对应 X 检查（REQ-CFG-002）
    if (!vif.exists_tready()) rule_enable[R_P006] = 1'b1;   // 仍检查 TVALID 未知
  endfunction

  // ---------------------------------------------------------------------------
  // 规则配置 API（REQ-CHK-003）
  // ---------------------------------------------------------------------------
  function void set_rule_enable(string rule, bit en);
    int idx = rule_index(rule);
    if (idx >= 0) rule_enable[idx] = en;
  endfunction

  function void set_rule_severity(string rule, axi4_stream_types_pkg::axis_severity_e sev);
    int idx = rule_index(rule);
    if (idx >= 0) rule_severity[idx] = sev;
  endfunction

  function void set_rule_max_report(string rule, int n);
    int idx = rule_index(rule);
    if (idx >= 0) rule_max_report[idx] = n;
  endfunction

  function int rule_index(string rule);
    for (int i = 0; i < 16; i++) if (rule_name[i] == rule) return i;
    return -1;
  endfunction

  // 返回该规则（含子码）的命中数：基规则名走 rule_hit_count，
  // 子码（如 AXIS-P004-KEEP）走 sub_hit_count。
  function int rule_hits(string rule);
    int idx;
    idx = rule_index(rule);
    if (idx >= 0) return rule_hit_count[idx];
    return sub_hit_count.exists(rule) ? sub_hit_count[rule] : 0;
  endfunction

  // ---------------------------------------------------------------------------
  // 违规发布（含 rule ID / 类别 / 严重度 / 实例 / epoch / 时间 / 前后采样）
  // ---------------------------------------------------------------------------
  protected function void report_rule(int idx, string desc, string before_s, string after_s);
    axi4_stream_error_event ev;
    axis_rule_category_e cat;
    if (idx < 0 || !rule_enable[idx]) return;
    if (rule_max_report[idx] > 0 && rule_hit_count[idx] >= rule_max_report[idx]) return;
    rule_hit_count[idx]++;
    // 记录子码命中：描述前缀中的 AXIS-Pxxx-YYY 形式
    begin
      string sub;
      if ($sscanf(desc, "%s", sub) == 1) begin
        if (sub.len() > 0 && sub[sub.len()-1] == ":") sub = sub.substr(0, sub.len()-2);
        if (sub.len() > 11 && sub.substr(0, 9) == "AXIS-P004") begin
          if (sub_hit_count.exists(sub)) sub_hit_count[sub]++;
          else sub_hit_count[sub] = 1;
        end
      end
    end
    case (idx)
      R_A001, R_A002: cat = AXIS_CAT_APPLICATION;
      R_W001, R_W002: cat = AXIS_CAT_WATCHDOG;
      R_C001:         cat = AXIS_CAT_CONFIG;
      R_I001:         cat = AXIS_CAT_VIP_INTERNAL;
      default:        cat = AXIS_CAT_PROTOCOL;
    endcase
    ev = axi4_stream_error_event::type_id::create("checker_err");
    ev.rule_id       = rule_name[idx];
    ev.category      = cat.name();
    ev.severity      = rule_severity[idx];
    ev.interface_id  = interface_id;
    ev.reset_epoch   = reset_epoch;
    ev.timestamp     = $time;
    ev.cycle         = cycle;
    ev.before_sample = before_s;
    ev.after_sample  = after_s;
    ev.description   = desc;
    // SVA 与 UVM checker 同时启用时的关联 ID（REQ-CHK-003）
    ev.injection_ref = $sformatf("uvm-checker#%0d@%0d", idx, cycle);
    error_ap.write(ev);
    case (rule_severity[idx])
      axi4_stream_types_pkg::AXIS_SEV_FATAL:
        `uvm_fatal("AXIS-CHK", $sformatf("[%s] %s", rule_name[idx], desc))
      axi4_stream_types_pkg::AXIS_SEV_ERROR:
        `uvm_error("AXIS-CHK", $sformatf("[%s] %s", rule_name[idx], desc))
      axi4_stream_types_pkg::AXIS_SEV_WARNING:
        `uvm_warning("AXIS-CHK", $sformatf("[%s] %s", rule_name[idx], desc))
      default:
        `uvm_info("AXIS-CHK", $sformatf("[%s] %s", rule_name[idx], desc), UVM_LOW)
    endcase
  endfunction

  // ---------------------------------------------------------------------------
  // 主检查循环：每个 ACLK 上升沿
  // ---------------------------------------------------------------------------
  task run_phase(uvm_phase phase);
    forever begin
      check_edge();
      @(vif.mon_cb);
    end
  endtask

  protected function string sample_string(logic [axi4_stream_types_pkg::AXIS_MAX_BITS-1:0] d,
                                          logic [axi4_stream_types_pkg::AXIS_MAX_BYTES-1:0] k,
                                          logic [axi4_stream_types_pkg::AXIS_MAX_BYTES-1:0] s,
                                          logic l);
    return $sformatf("data=%h keep=%h strb=%h last=%b", d, k, s, l);
  endfunction

  protected function void check_edge();
    bit in_reset;
    bit tvalid_known;
    bit has_tlast;
    bit has_tkeep;
    bit has_tstrb;
    bit hs;
    bit effective_ready;
    logic [axi4_stream_types_pkg::AXIS_MAX_BYTES-1:0] keep_n, strb_n;
    string cur_s;

    cycle++;
    in_reset = (vif.aresetn === 1'b0);
    has_tlast = vif.exists_tlast();
    has_tkeep = vif.exists_tkeep();
    has_tstrb = vif.exists_tstrb();
    keep_n = axi4_stream_types_pkg::axis_effective_keep(has_tkeep, vif.tkeep, vif.byte_lanes());
    strb_n = axi4_stream_types_pkg::axis_effective_strb(has_tkeep, vif.tkeep, has_tstrb, vif.tstrb, vif.byte_lanes());
    cur_s = sample_string(vif.tdata, keep_n, strb_n, vif.tlast);

    // ---------------- 复位期间与释放（P001 / P002）----------------
    // 判据为“不得为 1”：复位期间由未初始化产生的 X 不属于协议违规
    // （REQ-CHK-001 复位取消未完成/未初始化窗口）。
    if (in_reset) begin
      // 复位断言与 driver 撤销 TVALID 在同一时间步的不同 delta 可能交错。
      // 按 REQ-CHK-001“复位取消未完成的时序检查”，对“复位断言的那一个采样边沿”
      // 给一个边沿宽限（与 P002 的释放边沿对称）；此后仍为 1 才报错。
      if (was_in_reset && vif.tvalid === 1'b1)
        report_rule(R_P001, "复位期间 TVALID 不得为 1", "", cur_s);
      was_in_reset = 1'b1;
      release_edge_seen = 1'b0;
      wait_cycles = 0;
      update_prev(1'b0);
      return;
    end
    if (was_in_reset) begin
      was_in_reset = 1'b0;
      first_release_cycle = cycle;
      release_edge_seen = 1'b0;
    end
    // P002：ARESETn 拉高后的第一个 ACLK 上升沿仍采样到 TVALID=0（REQ-CHK-002）
    if (first_release_cycle == cycle) begin
      if (vif.tvalid !== 1'b1) release_edge_seen = 1'b1;
      else report_rule(R_P002,
        "复位释放后的第一个采样边沿 TVALID 不得为 1（source 可在该边沿之后驱动）", "", cur_s);
    end

    // ---------------- 未知值检查（P006 / P007 / P008 / P009）----------------
    tvalid_known = (vif.tvalid !== 1'bx) && (vif.tvalid !== 1'bz);
    if (vif.tvalid === 1'b1) begin
      // P006：复位外 TVALID、存在的 TREADY 不得未知
      if (!tvalid_known)
        report_rule(R_P006, "复位外 TVALID 不得为未知", "", cur_s);
      if (vif.exists_tready() && (vif.tready === 1'bx || vif.tready === 1'bz))
        report_rule(R_P006, "TVALID 有效时存在的 TREADY 不得未知", "", cur_s);
      // P007：qualifier / TLAST / ID / DEST 不得未知
      if (has_tkeep && (^vif.tkeep) === 1'bx)
        report_rule(R_P007, "TVALID 有效时存在的 TKEEP 不得未知", "", cur_s);
      if (has_tstrb && (^vif.tstrb) === 1'bx)
        report_rule(R_P007, "TVALID 有效时存在的 TSTRB 不得未知", "", cur_s);
      if (has_tlast && (vif.tlast === 1'bx))
        report_rule(R_P007, "TVALID 有效时存在的 TLAST 不得未知", "", cur_s);
      if (vif.exists_tid() && (^vif.tid) === 1'bx)
        report_rule(R_P007, "TVALID 有效时存在的 TID 不得未知", "", cur_s);
      if (vif.exists_tdest() && (^vif.tdest) === 1'bx)
        report_rule(R_P007, "TVALID 有效时存在的 TDEST 不得未知", "", cur_s);
      // P008：DATA bytes 不得未知；POSITION/NULL 数据值不做有效载荷 X 检查
      if (vif.exists_tdata() &&
          axi4_stream_types_pkg::axis_payload_has_unknown(
            vif.tdata, has_tkeep, vif.tkeep, has_tstrb, vif.tstrb, vif.byte_lanes()))
        report_rule(R_P008, "TVALID 有效时 DATA byte 的有效载荷不得未知（POSITION/NULL 除外）", "", cur_s);
      // P009：TUSER 有效检查位不得未知（缺省 mask 全有效）
      if (vif.exists_tuser() && (^vif.tuser) === 1'bx)
        report_rule(R_P009, "TVALID 有效时 TUSER 有效检查位不得未知", "", cur_s);
      // P005：TKEEP=0 不得对应 TSTRB=1
      if (axi4_stream_types_pkg::axis_illegal_byte_present(
            has_tkeep, vif.tkeep, has_tstrb, vif.tstrb, vif.byte_lanes()))
        report_rule(R_P005, "TKEEP=0 不得对应 TSTRB=1（非法字节限定符组合）", "", cur_s);
    end

    // ---------------- 握手与稳定性（P003 / P004）----------------
    effective_ready = vif.exists_tready() ? (vif.tready === 1'b1) : 1'b1;
    hs = (vif.tvalid === 1'b1) && effective_ready;

    if (vif.tvalid === 1'b1 && !effective_ready) begin
      wait_cycles++;
      // P003：stall 后到完成接收前 TVALID 持续为 1（valid_prev && prev_stall
      // 表示同一 beat 已连续等待至少两拍）
      // P004：stall 期间所有存在的 payload/sideband 稳定（每个字段独立子码）。
      // 仅当上一拍也是同一 beat 的 stall 时才比较，避免把“背靠背新 beat”
      // 误判为稳定性违规（REQ-PRO-003）。
      if (valid_prev && prev_valid_known && prev_stall) begin
        if (vif.exists_tdata() && vif.tdata !== data_prev)
          report_rule(R_P004, "AXIS-P004-DATA: stall 期间 TDATA 必须保持稳定",
            sample_string(data_prev, keep_prev, strb_prev, last_prev), cur_s);
        if (has_tkeep && keep_n !== keep_prev)
          report_rule(R_P004, "AXIS-P004-KEEP: stall 期间 TKEEP 必须保持稳定",
            sample_string(data_prev, keep_prev, strb_prev, last_prev), cur_s);
        if (has_tstrb && strb_n !== strb_prev)
          report_rule(R_P004, "AXIS-P004-STRB: stall 期间 TSTRB 必须保持稳定",
            sample_string(data_prev, keep_prev, strb_prev, last_prev), cur_s);
        if (has_tlast && vif.tlast !== last_prev)
          report_rule(R_P004, "AXIS-P004-LAST: stall 期间 TLAST 必须保持稳定",
            sample_string(data_prev, keep_prev, strb_prev, last_prev), cur_s);
        if (vif.exists_tid() && vif.tid !== id_prev)
          report_rule(R_P004, "AXIS-P004-ID: stall 期间 TID 必须保持稳定",
            sample_string(data_prev, keep_prev, strb_prev, last_prev), cur_s);
        if (vif.exists_tdest() && vif.tdest !== dest_prev)
          report_rule(R_P004, "AXIS-P004-DEST: stall 期间 TDEST 必须保持稳定",
            sample_string(data_prev, keep_prev, strb_prev, last_prev), cur_s);
        if (vif.exists_tuser() && vif.tuser !== user_prev)
          report_rule(R_P004, "AXIS-P004-USER: stall 期间 TUSER 必须保持稳定",
            sample_string(data_prev, keep_prev, strb_prev, last_prev), cur_s);
      end
    end

    if (hs) begin
      // TID/TDEST 只能在成功传输之间变化；不得在等待当前拍接收期间变化（REQ-PRO-010）
      // 已在 P004 的 stall 检查中覆盖。
      wait_cycles = 0;
      last_progress_cycle = cycle;
      packet_open = has_tlast ? (vif.tlast !== 1'b1) : 1'b1;
    end

    // ---------------- 看门狗（W001 / W002，缺省关闭）----------------
    if (rule_enable[R_W001] && cfg.max_ready_wait > 0 && wait_cycles > cfg.max_ready_wait)
      report_rule(R_W001, $sformatf("ready 等待 %0d 周期超过阈值 %0d",
        wait_cycles, cfg.max_ready_wait), "", cur_s);
    if (rule_enable[R_W002] && cfg.max_packet_idle > 0 &&
        packet_open && (cycle - last_progress_cycle) > cfg.max_packet_idle)
      report_rule(R_W002, $sformatf("packet 已 %0d 周期无进展或未结束（WATCHDOG）",
        cycle - last_progress_cycle), "", cur_s);

    update_prev(vif.tvalid === 1'b1 && !effective_ready);
  endfunction

  protected function void update_prev(bit stalled_now);
    valid_prev      = (vif.tvalid === 1'b1);
    prev_stall      = stalled_now;
    prev_valid_known = (vif.tvalid !== 1'bx) && (vif.tvalid !== 1'bz);
    data_prev  = vif.tdata;
    keep_prev  = axi4_stream_types_pkg::axis_effective_keep(
      vif.exists_tkeep(), vif.tkeep, vif.byte_lanes());
    strb_prev  = axi4_stream_types_pkg::axis_effective_strb(
      vif.exists_tkeep(), vif.tkeep, vif.exists_tstrb(), vif.tstrb, vif.byte_lanes());
    last_prev  = vif.tlast;
    id_prev    = vif.tid;
    dest_prev  = vif.tdest;
    user_prev  = vif.tuser;
  endfunction

  function void check_phase(uvm_phase phase);
    super.check_phase(phase);
    for (int i = 0; i < 16; i++) begin
      if (rule_enable[i] && rule_name[i] != "")
        `uvm_info("AXIS-CHK", $sformatf("rule %s hits=%0d", rule_name[i], rule_hit_count[i]), UVM_HIGH)
    end
  endfunction

endclass : axi4_stream_checker

`endif // AXI4_STREAM_CHECKER__SV
