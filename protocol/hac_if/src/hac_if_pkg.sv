// Copyright (c) 2026 AIXSILICON
// SPDX-License-Identifier: Apache-2.0
//
// hac_if_pkg: HAC-IF VIP 包入口（骨架）。
// 依赖：HWIF aix_common_pkg / aix_hac_if_pkg / aix_hac_ctrl_pkg / aix_hac_mem_pkg 等。
// 规划：hac_ctrl_agent / hac_stream_agent / hac_mem_agent / hac_lmem_agent /
//       hac_event_agent / hac_protocol_checker / hac_scoreboard / hac_reference_memory /
//       hac_error_injector / hac_coverage_model / hac_virtual_sequence。

package hac_if_pkg;

  import aix_common_pkg::*;
  import aix_hac_if_pkg::*;

  // ---------------------------------------------------------------------
  // Profile 枚举（与 HWIF Profile 对齐）
  // ---------------------------------------------------------------------
  typedef enum int {
    HAC_P0 = 0,
    HAC_P1 = 1,
    HAC_P2 = 2,
    HAC_P3 = 3,
    HAC_P4 = 4
  } hac_profile_e;

  // ---------------------------------------------------------------------
  // 模式
  // ---------------------------------------------------------------------
  typedef enum {
    ACTIVE_CORE,
    ACTIVE_SHELL,
    PASSIVE
  } hac_mode_e;

  // ---------------------------------------------------------------------
  // VIP 配置对象（规划；由各 agent 展开）
  // ---------------------------------------------------------------------
  typedef struct packed {
    hac_profile_e profile;
    logic has_ctrl;
    logic has_stream;
    logic has_mem;
    logic has_lmem;
    logic has_event;
    logic has_mgmt;
    int  max_inflight_jobs;
    int  mem_outstanding;
  } hac_if_cfg_t;

endpackage : hac_if_pkg
