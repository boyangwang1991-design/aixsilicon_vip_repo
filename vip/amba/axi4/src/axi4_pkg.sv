// =============================================================================
// File Name   : axi4_pkg.sv
// Description : AXI4 VIP package（所有组件类定义/导入）
// VLNV        : aixsilicon:vip:axi4:1.0.0
// =============================================================================

`ifndef AXI4_PKG__SV
`define AXI4_PKG__SV

package axi4_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import axi4_types_pkg::*;

  // =============================================================================
  // 多 analysis imp 宏（checker 多输入流：request / response / monitor）
  // =============================================================================
  `uvm_analysis_imp_decl(_axi4_request)
  `uvm_analysis_imp_decl(_axi4_response)
  `uvm_analysis_imp_decl(_axi4_monitor)

  // =============================================================================
  // Protocol / Configuration
  // =============================================================================
  `include "axi4_configuration.sv"
  `include "axi4_status.sv"
  `include "axi4_memory.sv"

  // =============================================================================
  // Transaction
  // =============================================================================
  `include "transaction/axi4_item.sv"

  // =============================================================================
  // Agent 组件
  // =============================================================================
  `include "agent/axi4_monitor.sv"
  `include "agent/axi4_sequencer.sv"
  `include "agent/axi4_driver.sv"
  `include "agent/axi4_agent.sv"

  // =============================================================================
  // Sequences
  // =============================================================================
  `include "sequences/axi4_sequences.sv"

  // =============================================================================
  // Qualification Model（Checker / Coverage / Injector / Env）
  // =============================================================================
  `include "checker/axi4_checker.sv"
  `include "env/axi4_violation_injector.sv"
  `include "coverage/axi4_coverage.sv"
  `include "env/axi4_env.sv"

  // =============================================================================
  // RAL Integration（REQ-VER-014：adapter + predictor，architecture §23）
  // =============================================================================
  `include "ral/axi4_ral_adapter.sv"

endpackage : axi4_pkg

`endif // AXI4_PKG__SV
