// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 AIXSILICON
//
// apb_example_top.sv — APB VIP 最小集成示例（占位）。
// 展示接口连接与 config_db 装配方式，作为用户接入的蓝本。
`ifndef APB_EXAMPLE_TOP_SV
`define APB_EXAMPLE_TOP_SV

`timescale 1ns/1ps

module apb_example_top;

  import uvm_pkg::*;
  import apb_pkg::*;
  import vip_common_pkg::*;
  `include "uvm_macros.svh"

  logic pclk, presetn;
  apb_if u_apb_if (.pclk(pclk), .presetn(presetn));

  initial begin
    // 用户在真实环境中按以下方式装配 agent 与 config
    apb_config cfg = apb_config::type_id::create("cfg");
    cfg.mode  = VIP_ACTIVE_MASTER;
    cfg.base_addr = 32'h4000_0000;
    uvm_config_db#(apb_config)::set(null, "uvm_test_top.env.apb_agent", "cfg", cfg);
    uvm_config_db#(virtual apb_if)::set(null, "uvm_test_top.env.apb_agent.*", "vif", u_apb_if);
  end

endmodule : apb_example_top

`endif
