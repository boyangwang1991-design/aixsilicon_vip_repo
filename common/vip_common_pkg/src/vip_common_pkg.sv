// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 AIXSILICON
//
// vip_common_pkg.sv — AIXSILICON VIP 公共包。
// 提供所有 VIP 共同依赖的基类、枚举与策略。
// 结构差异一律通过参数 / config / policy 表达，不使用编译宏（除 UVM 注册与工具兼容）。
`ifndef VIP_COMMON_PKG_SV
`define VIP_COMMON_PKG_SV

package vip_common_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // -------------------------------------------------------------------------
  // Agent 模式（所有协议 Agent 统一支持）
  // -------------------------------------------------------------------------
  typedef enum bit [1:0] {
    VIP_ACTIVE_MASTER,  // 驱动事务（master 角色）
    VIP_ACTIVE_SLAVE,   // 驱动事务（slave 角色 / responder）
    VIP_PASSIVE,        // 仅采样与检查
    VIP_DISABLED        // 组件禁用
  } vip_agent_mode_e;

  // -------------------------------------------------------------------------
  // 端口/能力开关（可只启用 Monitor / Checker / Coverage）
  // -------------------------------------------------------------------------
  typedef struct {
    bit has_monitor   = 1'b1;
    bit has_checker   = 1'b1;
    bit has_coverage  = 1'b1;
    bit has_sequencer = 1'b1;
  } vip_agent_components_cfg_t;

  // -------------------------------------------------------------------------
  // 错误严重等级（S0 最高，S1/S2 依次降低）
  // -------------------------------------------------------------------------
  typedef enum bit [1:0] {
    VIP_SEV_S0 = 2'b00,
    VIP_SEV_S1 = 2'b01,
    VIP_SEV_S2 = 2'b10
  } vip_severity_e;

  // -------------------------------------------------------------------------
  // 公共配置基类：所有协议 config object 的父类
  // -------------------------------------------------------------------------
  class vip_common_config extends uvm_object;
    `uvm_object_utils(vip_common_config)

    vip_agent_mode_e      mode          = VIP_PASSIVE;
    string                vif_name      = "";
    int                   max_outstanding = 0;   // 0 = 不限制
    vip_severity_e        err_severity  = VIP_SEV_S0;
    time                  timeout       = 1_000_000;
    bit                   enable_xcheck = 1'b1;
    bit                   random_seed_reproducible = 1'b1;

    function new(string name = "vip_common_config");
      super.new(name);
    endfunction

    virtual function string convert2string();
      return $sformatf("mode=%s vif=%s timeout=%0t",
                       mode.name(), vif_name, timeout);
    endfunction
  endclass : vip_common_config

endpackage : vip_common_pkg

`endif
