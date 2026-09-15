// =============================================================================
// File Name   : axi4_stream_sink_driver.sv
// Description : axi4_stream Sink driver（背压策略与接收容量模型）
// 依据        : docs/requirement.md（REQ-SNK-001..004, REQ-CFG-002, REQ-W001/W002）
//
// 设计说明：
//   * Sink 只驱动 TREADY；所有接收数据来自 monitor，不修改 DUT 驱动的信号
//     （REQ-SNK-001）。
//   * HAS_TREADY=0 时关闭所有背压驱动，接收吞吐匹配每周期一拍（REQ-SNK-004）。
//   * ready 决策使用周期计数与已承诺接收周期，不依赖 monitor 队列长度，避免
//     软件环路死锁（REQ-SNK-003）。
// =============================================================================

`ifndef AXI4_STREAM_SINK_DRIVER__SV
`define AXI4_STREAM_SINK_DRIVER__SV

class axi4_stream_sink_driver extends uvm_component;

  `uvm_component_utils(axi4_stream_sink_driver)

  virtual axi4_stream_if  vif;
  axi4_stream_config      cfg;
  axi4_stream_ready_item  policy;

  protected int unsigned   cycle              = 0;
  protected int            stall_remaining    = 0;
  protected int            burst_accept_left  = 0;
  protected int            burst_pause_left   = 0;
  protected int            committed_inflight = 0;
  protected longint        accepted_cycles    = 0;
  protected longint        stall_cycles       = 0;
  protected bit            in_reset           = 1'b0;
  protected bit            ready_value        = 1'b1;
  protected bit            valid_pending      = 1'b0;
  protected int            rng_state          = 1;

  function new(string name = "axi4_stream_sink_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual axi4_stream_if)::get(this, "", "vif", vif))
      `uvm_fatal("AXIS-SNK", "未获取 virtual interface（REQ-INT-002）")
    if (!uvm_config_db#(axi4_stream_config)::get(this, "", "cfg", cfg))
      `uvm_fatal("AXIS-SNK", "未获取 config（REQ-INT-002）")
    policy = axi4_stream_ready_item::type_id::create("policy");
    if (!uvm_config_db#(axi4_stream_ready_item)::get(this, "", "ready_policy", policy)) begin
      // 缺省 ALWAYS_READY（合法默认，由用户显式覆盖）
      policy.mode = AXIS_READY_ALWAYS;
    end
    rng_state = (policy.seed == 0) ? 32'h1 : policy.seed;
    drive_pins();
  endfunction

  protected function void drive_pins();
    if (!vif.exists_tready()) return;   // HAS_TREADY=0：不驱动 ready（REQ-SNK-004）
    vif.ready_cb.tready <= 1'b1;
  endfunction

  // 32-bit LCG，保证 seed 可重放（REQ-SNK-001 RANDOM）
  protected function int next_rand(int bound);
    rng_state = (rng_state * 1103515245 + 12345) & 32'h7fffffff;
    if (bound <= 1) return 0;
    return rng_state % bound;
  endfunction

  // ---------------------------------------------------------------------------
  // 运行期更新 ready policy：仅影响背压语义，不改变组包/比较语义
  // （REQ-INT-003：影响组包/比较语义的配置需 drain/复位）
  // ---------------------------------------------------------------------------
  function void set_ready_policy(axi4_stream_ready_item p);
    if (p == null) return;
    policy = p;
    rng_state = (policy.seed == 0) ? 32'h1 : policy.seed;
    committed_inflight = 0;
    stall_remaining    = 0;
    `uvm_info("AXIS-SNK", $sformatf("更新 ready policy（背压语义，非比较语义）: %s",
      policy.convert2string()), UVM_MEDIUM)
  endfunction

  task run_phase(uvm_phase phase);
    if (!vif.exists_tready()) begin
      `uvm_info("AXIS-SNK", "HAS_TREADY=0：关闭背压驱动，接收吞吐为每周期一拍（REQ-SNK-004）", UVM_LOW)
      return;
    end
    forever begin
      @(vif.ready_cb);
      cycle++;
      if (vif.aresetn === 1'b0) begin
        in_reset = 1'b1;
        ready_value = 1'b0;
        vif.ready_cb.tready <= 1'b0;
        stall_remaining = 0;
        burst_accept_left = 0;
        burst_pause_left = 0;
        committed_inflight = 0;
        continue;
      end
      if (in_reset) begin
        in_reset = 1'b0;
        cycle = 0;
      end
      ready_value = compute_ready();
      vif.ready_cb.tready <= ready_value;
      if (ready_value && vif.tvalid === 1'b1) accepted_cycles++;
      else if (!ready_value) stall_cycles++;
    end
  endtask

  // ---------------------------------------------------------------------------
  // ready 决策：覆盖全部 9 种模式（REQ-SNK-001）
  // ---------------------------------------------------------------------------
  protected function bit compute_ready();
    bit observed_valid;
    int d;
    observed_valid = (vif.tvalid === 1'b1);
    if (observed_valid) valid_pending = 1'b1;
    case (policy.mode)
      AXIS_READY_ALWAYS:        return 1'b1;

      AXIS_READY_FIXED_DELAY: begin
        // 观察到有效请求后延迟 N 拍接收；定义 N=0 边界
        if (policy.delay <= 0) return 1'b1;
        if (!observed_valid) return 1'b1;
        if (stall_remaining == 0) begin
          stall_remaining = policy.delay - 1;
          return (policy.delay == 0);
        end
        stall_remaining--;
        return (stall_remaining == 0);
      end

      AXIS_READY_RANDOM: begin
        if (stall_remaining > 0) begin stall_remaining--; return 1'b0; end
        if (next_rand(100) < policy.prob_percent) return 1'b1;
        stall_remaining = next_rand(policy.max_stall > 0 ? policy.max_stall : 1);
        return 1'b0;
      end

      AXIS_READY_PERIODIC: begin
        int hi = (policy.high_cycles > 0) ? policy.high_cycles : 1;
        int lo = (policy.low_cycles > 0) ? policy.low_cycles : 1;
        return ((cycle % (hi + lo)) < hi);
      end

      AXIS_READY_WAIT_VALID: begin
        // 先等待 TVALID 再产生 ready（用于发现 source 依赖 ready 的问题，REQ-SNK-002）
        return observed_valid && valid_pending;
      end

      AXIS_READY_BURST_ACCEPT: begin
        if (burst_pause_left > 0) begin burst_pause_left--; return 1'b0; end
        if (burst_accept_left > 0) begin
          burst_accept_left--;
          if (burst_accept_left == 0) burst_pause_left = policy.burst_n;
          return 1'b1;
        end
        burst_accept_left = (policy.burst_k > 0) ? policy.burst_k : 1;
        burst_accept_left--;
        if (burst_accept_left == 0) burst_pause_left = policy.burst_n;
        return 1'b1;
      end

      AXIS_READY_TARGETED: begin
        // 包首/包中/包尾或第 K 拍施加背压：按已接收拍序号判定
        return (policy.target_beat == 0) ? 1'b1 : ((accepted_cycles % policy.target_beat) != 0);
      end

      AXIS_READY_BUFFER_MODEL: begin
        // 达到容量前必须考虑已承诺的接收周期（REQ-SNK-003）
        d = (policy.buffer_depth > 0) ? policy.buffer_depth : 1;
        if (committed_inflight < d) begin
          committed_inflight++;
          return 1'b1;
        end
        // 消费速率：每 consume_rate 拍释放一个容量
        if (policy.consume_rate > 0 && (cycle % policy.consume_rate) == 0 && committed_inflight > 0)
          committed_inflight--;
        return (committed_inflight < d);
      end

      AXIS_READY_SCRIPTED: begin
        // 周期脚本：由 enable 与 repeat_count 控制；用户可通过回调覆盖
        return policy.enable;
      end

      default: return 1'b1;
    endcase
  endfunction

  function void get_stats(output longint acc_cycles, output longint stall_cyc);
    acc_cycles = accepted_cycles;
    stall_cyc  = stall_cycles;
  endfunction

endclass : axi4_stream_sink_driver

`endif // AXI4_STREAM_SINK_DRIVER__SV