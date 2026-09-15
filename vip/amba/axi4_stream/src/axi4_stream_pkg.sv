// =============================================================================
// File Name   : axi4_stream_pkg.sv
// Description : axi4_stream VIP package（组件类定义与导入顺序）
// 依据        : docs/requirement.md（REQ-INT-002/004, REQ-CFG-006）
//
// 编译顺序：axi4_stream_types_pkg（纯语义，无 UVM）→ axi4_stream_if →
//           axi4_stream_assertions（独立 module）→ 本 package。
// 本 package 内 include 顺序按类依赖排列；每个类只编译一次（REQ-INT-002）。
// =============================================================================

`ifndef AXI4_STREAM_PKG__SV
`define AXI4_STREAM_PKG__SV

package axi4_stream_pkg;

  import uvm_pkg::*;
  import axi4_stream_types_pkg::*;
  `include "uvm_macros.svh"

  // ---------------------------------------------------------------------------
  // Transaction / Control 模型
  // ---------------------------------------------------------------------------
  `include "transaction/axi4_stream_item.sv"

  // ---------------------------------------------------------------------------
  // Configuration
  // ---------------------------------------------------------------------------
  `include "axi4_stream_config.sv"

  // ---------------------------------------------------------------------------
  // 单一协议语义模型（lane/byte/token 规范化）
  // ---------------------------------------------------------------------------
  `include "model/axi4_stream_stream_model.sv"

  // ---------------------------------------------------------------------------
  // Sequences（激励模型）
  // ---------------------------------------------------------------------------
  `include "sequences/axi4_stream_base_seq.sv"
  `include "sequences/axi4_stream_smoke_seq.sv"

  // ---------------------------------------------------------------------------
  // Qualification 模型：Checker / Coverage / Scoreboard / Reference model
  // ---------------------------------------------------------------------------
  `include "checker/axi4_stream_checker.sv"
  `include "coverage/axi4_stream_coverage.sv"
  `include "scoreboard/axi4_stream_reference_model.sv"
  `include "scoreboard/axi4_stream_scoreboard.sv"

  // ---------------------------------------------------------------------------
  // 观测模型：Monitor
  // ---------------------------------------------------------------------------
  `include "agent/axi4_stream_monitor.sv"

  // ---------------------------------------------------------------------------
  // 激励模型：Driver / Sink driver / Sequencer / Agent
  // ---------------------------------------------------------------------------
  `include "agent/axi4_stream_driver.sv"
  `include "agent/axi4_stream_sink_driver.sv"
  `include "agent/axi4_stream_sequencer.sv"
  `include "agent/axi4_stream_agent.sv"

  // ---------------------------------------------------------------------------
  // 错误注入控制器（负向验证）
  // ---------------------------------------------------------------------------
  `include "env/axi4_stream_violation_injector.sv"

  // ---------------------------------------------------------------------------
  // Env（FULL_UVM 集成）
  // ---------------------------------------------------------------------------
  `include "env/axi4_stream_env.sv"

endpackage : axi4_stream_pkg

`endif // AXI4_STREAM_PKG__SV
