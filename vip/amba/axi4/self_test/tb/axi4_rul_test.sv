// =============================================================================
// File Name   : axi4_rul_test.sv
// Description : AXI4 VIP Self Test RUL 专项负向注入（P2-1）
//               M1 RUL-001：ARVALID 提前撤销（inject_valid_drop）→ SVA a_arvalid_stable
//               M2 RUL-005：末拍缺失 WLAST（inject_missing_wlast）→ checker
//                            "数据收满但无 WLAST" 检测器
//               判定：RUL-001 ≥1 且 RUL-005 ≥1（双 VALIDATED）；其余无违规
// =============================================================================
`ifndef AXI4_RUL_TEST__SV
`define AXI4_RUL_TEST__SV

import uvm_pkg::*;
import axi4_pkg::*;
import axi4_types_pkg::*;

class axi4_rul_seq extends axi4_master_base_seq;

  `uvm_object_utils(axi4_rul_seq)

  function new(string name = "axi4_rul_seq");
    super.new(name);
  endfunction

  virtual task body();
    axi4_data bdata[];
    axi4_strobe bstrobe[];
    axi4_data rdata;
    logic [31:0] rdata32;

    bdata   = new[4];
    bstrobe = new[4];
    foreach (bdata[i]) begin
      bdata[i]   = 32'hF100_0000 + i;
      bstrobe[i] = '1;
    end

    // ---- M1: ARVALID 提前撤销（RUL-001；stall 由 arready_delay 供窗口）----
    begin
      axi4_master_item item;
      item = axi4_master_item::type_id::create("item_m1");
      item.access_type  = AXI4_READ_ACCESS;
      item.id           = 1;
      item.address      = 32'h0000_F000;
      item.burst_length = 1;
      item.burst_size   = 4;
      item.burst_type   = AXI4_INCREMENTING_BURST;
      item.inject_valid_drop = 1;
      `uvm_info(get_type_name(), "M1: VALID drop injection (expect SVA RUL-001 detect)", UVM_LOW)
      start_item(item);
      finish_item(item);
    end
    #50;

    // ---- M2: 末拍缺失 WLAST（RUL-005；checker missing-WLAST 检测器）----
    begin
      axi4_master_item item;
      item = axi4_master_item::type_id::create("item_m2");
      item.access_type  = AXI4_WRITE_ACCESS;
      item.id           = 2;
      item.address      = 32'h0000_F100;
      item.burst_length = 4;
      item.burst_size   = 4;
      item.burst_type   = AXI4_INCREMENTING_BURST;
      item.data         = bdata;
      item.strobe       = bstrobe;
      item.inject_missing_wlast = 1;
      `uvm_info(get_type_name(), "M2: missing-WLAST injection (expect checker RUL-005 detect)", UVM_LOW)
      start_item(item);
      finish_item(item);
    end
    #50;

    // ---- 合法对照（无违规）----
    write(32'h0000_F200, 32'hF200_0001);
    read(32'h0000_F200, rdata);
    if (rdata !== 32'hF200_0001) begin
      `uvm_error(get_type_name(), $sformatf(
        "RUL legal control mismatch: got %08h", rdata[31:0]))
    end
  endtask

endclass : axi4_rul_seq


class axi4_rul_test extends uvm_test;

  axi4_smoke_env env;

  `uvm_component_utils(axi4_rul_test)

  function new(string name = "axi4_rul_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = axi4_smoke_env::type_id::create("env", this);
  endfunction

  task run_phase(uvm_phase phase);
    axi4_rul_seq seq;

    // M1 的 VALID drop 需 stall 窗口（AR 在 stall 拍撤销才构成 RUL-001）：
    // arready 确定性 2 拍拉低（与 E2 的 wready 同款跨沿语义）
    if (env.slave_cfg != null) begin
      env.slave_cfg.arready_delay.enabled    = 1;
      env.slave_cfg.arready_delay.delay_kind = 0;
      env.slave_cfg.arready_delay.delay_value = 2;
      env.slave_cfg.arready_delay.delay_min   = 2;
      env.slave_cfg.arready_delay.delay_max   = 2;
    end

    phase.raise_objection(this);
    seq = axi4_rul_seq::type_id::create("seq");
    seq.start(env.master_agent.sequencer);
    #300;
    phase.drop_objection(this);
  endtask

  function void report_phase(uvm_phase phase);
    uvm_report_server svr = uvm_report_server::get_server();
    int rul001;
    int rul005;
    super.report_phase(phase);
    rul001 = svr.get_id_count("AXI4-REQ-RUL-001");
    rul005 = svr.get_id_count("AXI4-REQ-RUL-005");
    // M1/M2 双检出判定
    if (rul001 < 1) begin
      `uvm_error(get_type_name(),
        "RUL test: M1 valid-drop (RUL-001 SVA) MUST be caught >=1")
    end
    if (rul005 < 1) begin
      `uvm_error(get_type_name(),
        "RUL test: M2 missing-WLAST (RUL-005 checker) MUST be caught >=1")
    end
    `uvm_info(get_type_name(), $sformatf(
      "RUL test: RUL-001=%0d RUL-005=%0d — M1+M2 mutation %s",
      rul001, rul005, ((rul001 >= 1) && (rul005 >= 1)) ? "VALIDATED" : "LEAK"), UVM_LOW)
  endfunction

endclass : axi4_rul_test

`endif // AXI4_RUL_TEST__SV