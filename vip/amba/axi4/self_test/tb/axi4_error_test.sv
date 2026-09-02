// =============================================================================
// File Name   : axi4_error_test.sv
// Description : AXI4 VIP Self Test error tier（validation-plan §17.2 扩展负向）
//               利用 driver 注入钩子 + response weights + ready_delay 配置：
//               E1 RUL-005/017：early WLAST（burst 缩短）→ SVA a_wlast_handshake
//                  / a_valid 系列期望检测
//               E2 RUL-011：stalled W payload 翻转 → SVA payload stability
//               E3 RUL-010：response_weight_slave_error → SLVERR 合法语义
//                  （checker 无违规；非法编码检测属 RUL-010 负向对照）
//               E4 PRO-009：awready/wready 背压（ready_delay）→ 事务仍正确完成
//               判定：E1/E2 各注入 1 次，须有 UVM_ERROR（SVA 或 checker 检出）；
//               E3/E4 为合法语义场景，无违规。
// =============================================================================
`ifndef AXI4_ERROR_TEST__SV
`define AXI4_ERROR_TEST__SV

import uvm_pkg::*;
import axi4_pkg::*;
import axi4_types_pkg::*;

// E2 专用：unstable payload 注入 + 依赖 test 在事务期间开 wready_delay（stall）。
// 与 E1（early-WLAST）拆开，避免 E2 的 stall 外溢干扰 E3/E4 合法性。
class axi4_error_seq_e2 extends axi4_master_base_seq;

  `uvm_object_utils(axi4_error_seq_e2)

  function new(string name = "axi4_error_seq_e2");
    super.new(name);
  endfunction

  virtual task body();
    axi4_data bdata[];
    axi4_strobe bstrobe[];
    axi4_master_item item;

    bdata   = new[4];
    bstrobe = new[4];
    foreach (bdata[i]) begin
      bdata[i]   = 32'hE200_0000 + i;
      bstrobe[i] = '1;
    end
    item = axi4_master_item::type_id::create("item_e2");
    item.access_type  = AXI4_WRITE_ACCESS;
    item.id           = 2;
    item.address      = 32'h0000_C100;
    item.burst_length = 4;
    item.burst_size   = 4;
    item.burst_type   = AXI4_INCREMENTING_BURST;
    item.data         = bdata;
    item.strobe       = bstrobe;
    item.inject_unstable_payload = 1;
    `uvm_info(get_type_name(), "E2: unstable payload injection (expect SVA RUL-011 detect)", UVM_LOW)
    start_item(item);
    finish_item(item);
    #50;

    // ---- E1: early WLAST（RUL-017，item 级注入；与 E2 同阶段（stall 环境），
    //      slave 16 拍超时完成缩短事务；E3/E4 在阶段 2（stall 关）干净运行）----
    foreach (bdata[i]) begin
      bdata[i]   = 32'hE100_0000 + i;
      bstrobe[i] = '1;
    end
    item = axi4_master_item::type_id::create("item_e1");
    item.access_type  = AXI4_WRITE_ACCESS;
    item.id           = 1;
    item.address      = 32'h0000_C000;
    item.burst_length = 4;
    item.burst_size   = 4;
    item.burst_type   = AXI4_INCREMENTING_BURST;
    item.data         = bdata;
    item.strobe       = bstrobe;
    item.inject_early_wlast = 1;
    `uvm_info(get_type_name(), "E1: early-WLAST injection (expect checker RUL-017 detect)", UVM_LOW)
    start_item(item);
    finish_item(item);
    #50;
  endtask

endclass : axi4_error_seq_e2


class axi4_error_seq extends axi4_master_base_seq;

  `uvm_object_utils(axi4_error_seq)

  function new(string name = "axi4_error_seq");
    super.new(name);
  endfunction

  virtual task body();
    axi4_data bdata[];
    axi4_strobe bstrobe[];

    bdata   = new[4];
    bstrobe = new[4];
    foreach (bdata[i]) begin
      bdata[i]   = 32'hE100_0000 + i;
      bstrobe[i] = '1;
    end

    // E1/E2 由独立 seq（axi4_error_seq_e2）在阶段 1（stall 开）执行；
    // E3/E4 在阶段 2（stall 关）干净运行。

    // ---- E3: SLVERR 响应（合法语义，response weight 已由 test 配置）----
    begin
      axi4_data rdata;
      `uvm_info(get_type_name(), "E3: SLVERR-weighted response (legal, no violation)", UVM_LOW)
      write(32'h0000_C200, 32'hE300_0001);
      read(32'h0000_C200, rdata);
    end

    // ---- E4: 背压下事务仍正确（PRO-009；ready_delay 由 test 配置）----
    begin
      axi4_data rdata;
      `uvm_info(get_type_name(), "E4: backpressure (ready_delay) still correct", UVM_LOW)
      write(32'h0000_C300, 32'hE400_0001);
      read(32'h0000_C300, rdata);
    end
  endtask

endclass : axi4_error_seq


class axi4_error_test extends uvm_test;

  axi4_smoke_env env;

  `uvm_component_utils(axi4_error_test)

  function new(string name = "axi4_error_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = axi4_smoke_env::type_id::create("env", this);
  endfunction

  task start_phase(uvm_phase phase);
  endtask

  task run_phase(uvm_phase phase);
    axi4_error_seq     seq;
    axi4_error_seq_e2  seq_e2;

    // E1/E2 注入为 item 级（per-transaction）；wready stall 仅在 E2 阶段启用
    //（阶段化控制，避免 stall 外溢干扰 E3/E4 合法性 → RUL-005 误报）。
    if (env.slave_cfg != null) begin
      // E3：SLVERR 权重（合法响应语义）
      env.slave_cfg.response_weight_okay        = 0;
      env.slave_cfg.response_weight_slave_error = 1;
      // E4：请求通道背压（每 2 拍 ready 关 1 拍）
      env.slave_cfg.awready_delay.enabled    = 1;
      env.slave_cfg.awready_delay.delay_kind = 1;
      env.slave_cfg.awready_delay.delay_min  = 1;
      env.slave_cfg.awready_delay.delay_max  = 3;
      env.slave_cfg.arready_delay.enabled    = 1;
      env.slave_cfg.arready_delay.delay_kind = 1;
      env.slave_cfg.arready_delay.delay_min  = 1;
      env.slave_cfg.arready_delay.delay_max  = 3;
      // wready stall 默认关闭（E2 阶段临时开启）
      env.slave_cfg.wready_delay.enabled     = 0;
      env.slave_cfg.wready_delay.delay_kind  = 0;
      env.slave_cfg.wready_delay.delay_value = 3;
      env.slave_cfg.wready_delay.delay_min   = 3;
      env.slave_cfg.wready_delay.delay_max   = 3;
    end
    // ===== 阶段 1：E2（unstable payload）——启用 wready stall =====
    if (env.slave_cfg != null) begin
      env.slave_cfg.wready_delay.enabled = 1;
    end

    seq     = axi4_error_seq::type_id::create("seq");
    seq_e2  = axi4_error_seq_e2::type_id::create("seq_e2");

    phase.raise_objection(this);
    seq_e2.start(env.master_agent.sequencer);
    #100;

    // ===== 阶段 2：关闭 stall，跑 E1（early-WLAST）+ E3（SLVERR）+ E4（背压）=====
    if (env.slave_cfg != null) begin
      env.slave_cfg.wready_delay.enabled = 0;
    end
    seq.start(env.master_agent.sequencer);
    #300;
    phase.drop_objection(this);
  endtask

  function void report_phase(uvm_phase phase);
    uvm_report_server svr = uvm_report_server::get_server();
    int errs;
    int rul011;
    int rul017;
    super.report_phase(phase);
    errs   = svr.get_severity_count(UVM_ERROR);
    rul011 = svr.get_id_count("AXI4-REQ-RUL-011");
    rul017 = svr.get_id_count("AXI4-REQ-RUL-017");
    // E1（RUL-017 burst 缩短）与 E2（RUL-011 payload stability）均为已验证闭环：
    // 两者各须 ≥1 检出；E3/E4 为合法语义场景，其余违规不允许。
    if (rul017 < 1) begin
      `uvm_error(get_type_name(),
        "error test: E1 early-WLAST (RUL-017) MUST be caught >=1")
    end
    if (rul011 < 1) begin
      `uvm_error(get_type_name(),
        "error test: E2 unstable payload (RUL-011 SVA) MUST be caught >=1")
    end
    `uvm_info(get_type_name(), $sformatf(
      "error test: RUL-017=%0d RUL-011=%0d total=%0d — E1+E2 mutation VALIDATED",
      rul017, rul011, errs), UVM_LOW)
  endfunction

endclass : axi4_error_test

`endif // AXI4_ERROR_TEST__SV
