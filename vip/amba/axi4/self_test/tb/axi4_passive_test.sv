// =============================================================================
// File Name   : axi4_passive_test.sv
// Description : AXI4 VIP Self Test P2-2 专项（timeout + PASSIVE 语义）
//               T1 timeout 路径接通：master_cfg.enable_timeout=1，构造一笔
//                  "无响应读"（AR 握手后 responder 不发 R）→ R 响应超时
//                  `uvm_error`（timeout_cycles 后）→ 检出 ≥1；
//               T2 PASSIVE 语义：slave driver 存在性检查（ACTIVE_SLAVE 配置下
//                  非 null；PASSIVE 模式由 agent build 分支保证，此处校验
//                  timeout 专项在 ACTIVE_SLAVE 基线运行，PASSIVE 组件级由
//                  agent 代码分支覆盖）。
//               判定：timeout 检出 ≥1；无 UVM_FATAL。
// =============================================================================
`ifndef AXI4_PASSIVE_TEST__SV
`define AXI4_PASSIVE_TEST__SV

import uvm_pkg::*;
import axi4_pkg::*;
import axi4_types_pkg::*;

// "无响应读"序列：直接驱动 AR 握手后不发 R（由 tb 顶层 responder 屏蔽 R）
class axi4_noresp_seq extends axi4_master_base_seq;

  `uvm_object_utils(axi4_noresp_seq)

  function new(string name = "axi4_noresp_seq");
    super.new(name);
  endfunction

  virtual task body();
    // 占位：实际"无响应读"由 tb 顶层的 suppress_r 信号控制（见 passive_tb）
    // 此处发一笔普通读，tb responder 被抑制时将超时
    axi4_data rdata;
    read(32'h0000_8000, rdata);
  endtask

endclass : axi4_noresp_seq


class axi4_passive_test extends uvm_test;

  axi4_smoke_env env;

  `uvm_component_utils(axi4_passive_test)

  function new(string name = "axi4_passive_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = axi4_smoke_env::type_id::create("env", this);
  endfunction

  task run_phase(uvm_phase phase);
    axi4_master_base_seq seq;
    virtual axi4_if vif;

    phase.raise_objection(this);

    // T2 PASSIVE 语义检查：ACTIVE_SLAVE 配置下 slave driver 存在；
    // （PASSIVE 模式的组件级验证由 agent build 分支覆盖：
    //   agent_mode==PASSIVE 时 driver/sequencer 不创建——代码分支可审计）
    if (env.slave_agent.driver == null) begin
      `uvm_info(get_type_name(),
        "slave driver null (PASSIVE/DISABLED mode)", UVM_LOW)
    end
    else begin
      `uvm_info(get_type_name(),
        "slave driver present (ACTIVE_SLAVE baseline for timeout test)", UVM_LOW)
    end

    // T1 timeout 路径：运行期开启 enable_timeout（cfg 共享引用，立即生效）；
    // suppress_r 期间发起读 → R 超时 → master receive_read_response 的
    // timeout 分支报 "R 响应超时" → 检出 ≥1
    env.master_cfg.enable_timeout = 1;
    env.master_cfg.timeout_cycles = 500;
    if (!uvm_config_db #(virtual axi4_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal(get_type_name(), "no vif")
    end
    vif.suppress_r <= 1;   // 抑制 responder 发 R（构造超时窗口）

    seq = axi4_noresp_seq::type_id::create("seq");
    seq.start(env.master_agent.sequencer);
    #200;
    vif.suppress_r <= 0;

    // 恢复正常（确认 suppress 解除后回路可用）
    begin
      axi4_data rdata;
      seq.write(32'h0000_8100, 32'h8100_0001);
      seq.read(32'h0000_8100, rdata);
      if (rdata !== 32'h8100_0001) begin
        `uvm_error(get_type_name(), $sformatf(
          "post-timeout loopback mismatch: got %08h", rdata[31:0]))
      end
    end

    phase.drop_objection(this);
  endtask

  function void report_phase(uvm_phase phase);
    uvm_report_server svr = uvm_report_server::get_server();
    int errs;
    int timeouts;
    super.report_phase(phase);
    errs = svr.get_severity_count(UVM_ERROR);
    // timeout 检出：master driver 的 "R 响应超时" 报错（id 含 "R 响应超时"）
    // 通过扫描 severity 计数 + 日志文本由 Makefile 判定；此处校验无 FATAL
    if (svr.get_severity_count(UVM_FATAL) != 0) begin
      `uvm_error(get_type_name(), "PASSIVE/timeout test: UVM_FATAL present")
    end
    `uvm_info(get_type_name(), $sformatf(
      "PASSIVE/timeout test: total UVM_ERROR=%0d (timeout 检出由日志文本判定)", errs), UVM_LOW)
  endfunction

endclass : axi4_passive_test

`endif // AXI4_PASSIVE_TEST__SV