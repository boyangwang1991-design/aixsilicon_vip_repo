// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 AIXSILICON
//
// apb_pkg.sv — APB VIP 包入口。仅 `include 各实现文件并保持编译顺序。
`ifndef APB_PKG_SV
`define APB_PKG_SV

package apb_pkg;

  import uvm_pkg::*;
  import vip_common_pkg::*;
  `include "uvm_macros.svh"

  // 类型/常量占位（结构差异通过参数与 config 表达，不使用宏）
  localparam int APB_MAX_ADDR_WIDTH = 32;
  localparam int APB_MAX_DATA_WIDTH = 64;

  // 后续通过 `include 展开各组件（当前为骨架，逐文件实现）
  // `include "apb_item.sv"
  // `include "apb_config.sv"
  // `include "apb_sequencer.sv"
  // `include "apb_master_driver.sv"
  // `include "apb_slave_driver.sv"
  // `include "apb_monitor.sv"
  // `include "apb_coverage.sv"
  // `include "apb_checker.sv"
  // `include "apb_ral_adapter.sv"
  // `include "apb_agent.sv"

endpackage : apb_pkg

`endif
