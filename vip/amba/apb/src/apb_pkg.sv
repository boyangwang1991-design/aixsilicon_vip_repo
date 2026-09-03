// =============================================================================
// File Name   : apb_pkg.sv
// Description : APB VIP UVM package（include 顺序：config → violation/checker →
//               item → monitor → sequencer → driver → agent → sequences →
//               coverage → ral → env；架构 §5）
// VLNV        : aixsilicon:vip:apb:1.0.0
// =============================================================================

`ifndef APB_PKG__SV
`define APB_PKG__SV

package apb_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import apb_types_pkg::*;

  // ---------------------------------------------------------------------------
  // Configuration（runtime policy）
  // ---------------------------------------------------------------------------
  `include "apb_config.sv"

  // ---------------------------------------------------------------------------
  // Transaction（先于 checker：checker 引用 apb_item）
  // ---------------------------------------------------------------------------
  `include "transaction/apb_item.sv"

  // ---------------------------------------------------------------------------
  // Violation model + transaction checker
  // ---------------------------------------------------------------------------
  `include "checker/apb_violation.sv"

  // ---------------------------------------------------------------------------
  // Agent 组件（monitor / sequencer / driver / agent）
  // ---------------------------------------------------------------------------
  `include "agent/apb_monitor.sv"
  `include "agent/apb_sequencer.sv"
  `include "agent/apb_master_driver.sv"
  `include "agent/apb_slave_driver.sv"
  `include "agent/apb_agent.sv"

  // ---------------------------------------------------------------------------
  // Sequences
  // ---------------------------------------------------------------------------
  `include "sequences/apb_sequences.sv"

  // ---------------------------------------------------------------------------
  // Qualification Model（coverage / RAL）
  // ---------------------------------------------------------------------------
  `include "coverage/apb_coverage.sv"
  `include "ral/apb_ral.sv"

  // ---------------------------------------------------------------------------
  // Env
  // ---------------------------------------------------------------------------
  `include "env/apb_env.sv"

endpackage : apb_pkg

`endif // APB_PKG__SV
