// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 AIXSILICON
//
// apb_agent.sv — APB Agent 装配（按 mode 装配 driver/monitor/coverage/checker）。
`ifndef APB_AGENT_SV
`define APB_AGENT_SV

package apb_pkg;

  class apb_agent extends uvm_agent;
    `uvm_component_utils(apb_agent)

    apb_config         cfg;
    apb_sequencer      sqr;
    apb_master_driver  m_drv;
    apb_slave_driver   s_drv;
    apb_monitor        mon;
    apb_coverage       cov;
    apb_checker        chk;
    apb_ral_adapter    ral_adapter;

    function new(string name = "apb_agent", uvm_component parent = null);
      super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db#(apb_config)::get(this, "", "cfg", cfg))
        `uvm_fatal("NOCFG", "apb_agent 未获取 cfg")

      if (cfg.mode != vip_common_pkg::VIP_DISABLED) begin
        mon = apb_monitor::type_id::create("mon", this);
        case (cfg.mode)
          vip_common_pkg::VIP_ACTIVE_MASTER: m_drv = apb_master_driver::type_id::create("m_drv", this);
          vip_common_pkg::VIP_ACTIVE_SLAVE:  s_drv = apb_slave_driver ::type_id::create("s_drv", this);
          default: ;
        endcase
        if (cfg.mode != vip_common_pkg::VIP_PASSIVE)
          sqr = apb_sequencer::type_id::create("sqr", this);
        if (cfg.coverage_enabled)
          cov = apb_coverage::type_id::create("cov", this);
        if (cfg.check_enabled)
          chk = apb_checker::type_id::create("chk", this);
        if (cfg.mode != vip_common_pkg::VIP_PASSIVE)
          ral_adapter = apb_ral_adapter::type_id::create("ral_adapter", this);
      end
    endfunction

    virtual function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      if (m_drv != null) m_drv.seq_item_port.connect(sqr.seq_item_export);
      if (s_drv != null) s_drv.seq_item_port.connect(sqr.seq_item_export);
      if (mon != null) begin
        if (cov != null) mon.transaction_ap.connect(cov.analysis_export);
        if (chk != null) begin
          mon.transaction_ap.connect(chk.analysis_export);
          mon.error_ap.connect(chk.error_export);
        end
      end
    endfunction
  endclass : apb_agent

endpackage : apb_pkg

`endif
