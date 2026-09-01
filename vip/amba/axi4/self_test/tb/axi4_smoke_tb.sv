// =============================================================================
// File Name   : axi4_smoke_tb.sv
// Description : AXI4 VIP Self Test 顶层（smoke）
//               实例化 axi4_if、提供时钟/复位、配置 vif/cfg、启动 UVM
// =============================================================================

`ifndef AXI4_SMOKE_TB__SV
`define AXI4_SMOKE_TB__SV

module axi4_smoke_tb;

  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import axi4_pkg::*;
  import axi4_types_pkg::*;

  // 时钟 / 复位
  logic aclk;
  logic areset_n;

  initial begin
    aclk = 1'b0;
    forever #5 aclk = ~aclk;   // 100MHz
  end

  // 接口实例
  axi4_if #(
    .ID_WIDTH(8),
    .ADDRESS_WIDTH(32),
    .DATA_WIDTH(32)
  ) vif (
    .aclk     (aclk),
    .areset_n (areset_n)
  );

  // 复位序列
  initial begin
    areset_n = 1'b0;
    repeat (3) @(posedge aclk);
    areset_n = 1'b1;
  end

  // UVM 配置与启动
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
    run_test();
  end

  // 超时保护
  initial begin
    #1_000_000;
    `uvm_error("axi4_smoke_tb", "SMOKE TIMEOUT")
    $finish;
  end

  // 断言绑定（SVA 协议断言）
  axi4_assertions #(
    .DATA_WIDTH(32)
  ) u_assertions (
    .aclk     (aclk),
    .areset_n (areset_n),
    .awvalid  (vif.awvalid),
    .awready  (vif.awready),
    .awlen    (vif.awlen),
    .wvalid   (vif.wvalid),
    .wready   (vif.wready),
    .wlast    (vif.wlast),
    .bvalid   (vif.bvalid),
    .bready   (vif.bready),
    .arvalid  (vif.arvalid),
    .arready  (vif.arready),
    .arlen    (vif.arlen),
    .rvalid   (vif.rvalid),
    .rready   (vif.rready),
    .rlast    (vif.rlast)
  );

endmodule : axi4_smoke_tb

`endif // AXI4_SMOKE_TB__SV
