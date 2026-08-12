// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 AIXSILICON
//
// apb_smoke_env.sv — 最小 APB smoke 环境：Master Agent + Slave Agent + Scoreboard。
`ifndef APB_SMOKE_ENV_SV
`define APB_SMOKE_ENV_SV

package apb_smoke_pkg;

  import uvm_pkg::*;
  import apb_pkg::*;
  import vip_common_pkg::*;
  `include "uvm_macros.svh"

  class apb_smoke_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(apb_smoke_scoreboard)
    uvm_analysis_imp #(apb_item, apb_smoke_scoreboard) ap_import;

    function new(string name = "apb_smoke_scoreboard", uvm_component parent = null);
      super.new(name, parent);
    endfunction
    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      ap_import = new("ap_import", this);
    endfunction
    virtual function void write(apb_item t);
      `uvm_info("SB", $sformatf("saw: %s", t.convert2string()), UVM_MEDIUM)
    endfunction
  endclass : apb_smoke_scoreboard

  class apb_smoke_env extends uvm_env;
    `uvm_component_utils(apb_smoke_env)

    apb_agent           apb_master;
    apb_agent           apb_slave;
    apb_smoke_scoreboard sb;

    function new(string name = "apb_smoke_env", uvm_component parent = null);
      super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      apb_master = apb_agent::type_id::create("apb_master", this);
      apb_slave  = apb_agent::type_id::create("apb_slave", this);
      sb         = apb_smoke_scoreboard::type_id::create("sb", this);

      // 配置
      apb_config mcfg = apb_config::type_id::create("mcfg");
      mcfg.mode = VIP_ACTIVE_MASTER;
      uvm_config_db#(apb_config)::set(this, "apb_master", "cfg", mcfg);

      apb_config scfg = apb_config::type_id::create("scfg");
      scfg.mode = VIP_ACTIVE_SLAVE;
      uvm_config_db#(apb_config)::set(this, "apb_slave", "cfg", scfg);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      apb_master.mon.transaction_ap.connect(sb.ap_import);
    endfunction
  endclass : apb_smoke_env

endpackage : apb_smoke_pkg

`endif
