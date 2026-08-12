// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 AIXSILICON
//
// vip_common_monitor.sv — 公共 Monitor 基类。
// 提供统一 analysis port（transaction_ap / error_ap / performance_ap）与收集逻辑。
`ifndef VIP_COMMON_MONITOR_SV
`define VIP_COMMON_MONITOR_SV

package vip_common_pkg;

  class vip_common_monitor #(type TR = vip_common_transaction) extends uvm_monitor;

    // 统一端口
    uvm_analysis_port #(TR)  transaction_ap;
    uvm_analysis_port #(TR)  error_ap;
    uvm_analysis_port #(TR)  request_ap;
    uvm_analysis_port #(TR)  response_ap;
    uvm_analysis_port #(TR)  performance_ap;

    vip_common_config cfg;

    `uvm_component_utils_begin(vip_common_monitor#(TR))
      `uvm_field_object(cfg, UVM_ALL_ON)
    `uvm_component_utils_end

    function new(string name = "vip_common_monitor", uvm_component parent = null);
      super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      transaction_ap = new("transaction_ap", this);
      error_ap       = new("error_ap", this);
      request_ap     = new("request_ap", this);
      response_ap    = new("response_ap", this);
      performance_ap = new("performance_ap", this);
      if (!uvm_config_db#(vip_common_config)::get(this, "", "cfg", cfg))
        `uvm_fatal("NOCFG", "vip_common_config 未通过 config_db 配置")
    endfunction

    // 子类实现协议采样与错误检测。
    virtual protected task sample_protocol();
    endtask

    task run_phase(uvm_phase phase);
      fork
        sample_protocol();
      join_none
    endtask
  endclass : vip_common_monitor

endpackage : vip_common_pkg

`endif
