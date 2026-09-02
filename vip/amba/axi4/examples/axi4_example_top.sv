// =============================================================================
// File Name   : axi4_example_top.sv
// Description : AXI4 VIP 最小集成示例（最小 DUT：环回 slave 内存）
//               演示 VIP 作为 master agent 激励最小系统的标准接入方式：
//               axi4_if + 时钟复位 + master/slave agent + smoke 测试
//               （完整自验证环境见 self_test/tb/axi4_smoke_tb.sv）
// VLNV        : aixsilicon:vip:axi4:1.0.0
// =============================================================================

`ifndef AXI4_EXAMPLE_TOP__SV
`define AXI4_EXAMPLE_TOP__SV

module axi4_example_top;

  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import axi4_pkg::*;
  import axi4_types_pkg::*;

  // ---- 时钟 / 复位 ----
  logic aclk;
  logic areset_n;

  initial begin
    aclk = 1'b0;
    forever #5 aclk = ~aclk;   // 100MHz
  end

  initial begin
    areset_n = 1'b0;
    repeat (3) @(posedge aclk);
    areset_n = 1'b1;
  end

  // ---- 接口实例（对齐 HWIF IFC-AXI-001 信号集）----
  axi4_if #(
    .ID_WIDTH      (8),
    .ADDRESS_WIDTH (32),
    .DATA_WIDTH    (32)
  ) vif (
    .aclk     (aclk),
    .areset_n (areset_n)
  );

  // ---- UVM 启动（master ACTIVE + slave ACTIVE 环回）----
  initial begin
    axi4_configuration master_cfg;
    axi4_configuration slave_cfg;
    axi4_status        status;

    master_cfg = axi4_configuration::type_id::create("master_cfg");
    void'(master_cfg.randomize() with {
      protocol   == AXI4_PROTOCOL;
      agent_mode == AXI4_ACTIVE_MASTER;
    });
    slave_cfg = axi4_configuration::type_id::create("slave_cfg");
    void'(slave_cfg.randomize() with {
      protocol   == AXI4_PROTOCOL;
      agent_mode == AXI4_ACTIVE_SLAVE;
    });
    status = axi4_status::type_id::create("status");

    master_cfg.vif = vif;
    slave_cfg.vif  = vif;

    uvm_config_db #(virtual axi4_if)::set(null, "*", "vif", vif);
    uvm_config_db #(axi4_configuration)::set(null, "*", "master_cfg", master_cfg);
    uvm_config_db #(axi4_configuration)::set(null, "*", "slave_cfg", slave_cfg);
    uvm_config_db #(axi4_status)::set(null, "*", "status", status);
    run_test("axi4_smoke_test");
  end

  // ---- 超时保护 ----
  initial begin
    #1_000_000;
    `uvm_error("axi4_example_top", "EXAMPLE TIMEOUT")
    $finish;
  end

endmodule : axi4_example_top

`endif // AXI4_EXAMPLE_TOP__SV