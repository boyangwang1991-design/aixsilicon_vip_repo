// =============================================================================
// File Name   : axi4_fi_test.sv
// Description : AXI4 VIP Self Test Fault Injection 专项（G4/FI-013 起步）
//               FI-013: slave 发非预期响应编码（3'b100/3'b101 超出 2-bit 协议域；
//                       实测 enum cast 截断后为 EXOKAY）→ checker RUL-007 检出
//                       （非 exclusive 事务返回 EXOKAY）
//               验证结论：AXI4 标准 2-bit 响应空间（00/01/10/11）全部合法，
//               "非法响应编码"在 2-bit 界面上不可构造（RUL-010 的该子句
//               需 3-bit+ 扩展界面才可触发）；本注入以 EXOKAY→RUL-007 为检出路径。
//               判定：RUL-007 ≥2（B+R 各至少 1）
// =============================================================================
`ifndef AXI4_FI_TEST__SV
`define AXI4_FI_TEST__SV

import uvm_pkg::*;
import axi4_pkg::*;
import axi4_types_pkg::*;

class axi4_fi_seq extends axi4_master_base_seq;

  `uvm_object_utils(axi4_fi_seq)

  function new(string name = "axi4_fi_seq");
    super.new(name);
  endfunction

  virtual task body();
    axi4_data rdata;
    // FI-013a: 写（B 通道非法编码）
    `uvm_info(get_type_name(), "FI-013a: illegal BRESP injection", UVM_LOW)
    write(32'h0000_9000, 32'h9000_0001);
    #50;
    // FI-013b: 读（R 通道非法编码）
    `uvm_info(get_type_name(), "FI-013b: illegal RRESP injection", UVM_LOW)
    read(32'h0000_9000, rdata);
    #50;
  endtask

endclass : axi4_fi_seq


class axi4_fi_test extends uvm_test;

  axi4_smoke_env env;

  `uvm_component_utils(axi4_fi_test)

  function new(string name = "axi4_fi_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = axi4_smoke_env::type_id::create("env", this);
  endfunction

  task run_phase(uvm_phase phase);
    axi4_fi_seq seq;
    phase.raise_objection(this);
    if (env.slave_agent.driver != null) begin
      env.slave_agent.driver.inject_illegal_resp_b = 1;   // FI-013a
      env.slave_agent.driver.inject_illegal_resp_r = 1;   // FI-013b
    end
    seq = axi4_fi_seq::type_id::create("seq");
    seq.start(env.master_agent.sequencer);
    #200;
    if (env.slave_agent.driver != null) begin
      env.slave_agent.driver.inject_illegal_resp_b = 0;   // 恢复（合法对照）
      env.slave_agent.driver.inject_illegal_resp_r = 0;
    end
    #100;
    phase.drop_objection(this);
  endtask

  function void report_phase(uvm_phase phase);
    uvm_report_server svr = uvm_report_server::get_server();
    int rul007;
    super.report_phase(phase);
    rul007 = svr.get_id_count("AXI4-REQ-RUL-007");
    if (rul007 < 2) begin
      `uvm_error(get_type_name(), $sformatf(
        "FI test: unexpected-response (RUL-007 EXOKAY) MUST be caught >=2 (B+R), got %0d", rul007))
    end
    else begin
      `uvm_info(get_type_name(), $sformatf(
        "FI test: RUL-007=%0d — FI-013 unexpected-response mutation VALIDATED (RUL-010 not constructible in 2-bit resp space)", rul007), UVM_LOW)
    end
  endfunction

endclass : axi4_fi_test

`endif // AXI4_FI_TEST__SV