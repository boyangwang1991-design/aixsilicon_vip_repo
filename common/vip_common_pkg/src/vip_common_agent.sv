// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 AIXSILICON
//
// vip_common_agent.sv — 公共 Agent 基类。
// 按 mode（ACTIVE_MASTER / ACTIVE_SLAVE / PASSIVE / DISABLED）统一装配组件。
`ifndef VIP_COMMON_AGENT_SV
`define VIP_COMMON_AGENT_SV

package vip_common_pkg;

  class vip_common_agent #(type TR = vip_common_transaction) extends uvm_agent;

    vip_common_config cfg;
    vip_common_monitor #(TR)     mon;
    uvm_sequencer #(TR)          sqr;
    uvm_driver #(TR)             drv;

    `uvm_component_utils_begin(vip_common_agent#(TR))
      `uvm_field_object(cfg, UVM_ALL_ON)
    `uvm_component_utils_end

    function new(string name = "vip_common_agent", uvm_component parent = null);
      super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db#(vip_common_config)::get(this, "", "cfg", cfg))
        `uvm_fatal("NOCFG", "vip_common_config 未通过 config_db 配置")

      if (cfg.mode != VIP_DISABLED) begin
        mon = vip_common_monitor#(TR)::type_id::create("mon", this);
        if (cfg.mode != VIP_PASSIVE) begin
          sqr = uvm_sequencer#(TR)::type_id::create("sqr", this);
          drv = uvm_driver#(TR)::type_id::create("drv", this);
        end
      end
    endfunction

    virtual function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      if (cfg.mode != VIP_PASSIVE && drv != null)
        drv.seq_item_port.connect(sqr.seq_item_export);
    endfunction
  endclass : vip_common_agent

endpackage : vip_common_pkg

`endif
