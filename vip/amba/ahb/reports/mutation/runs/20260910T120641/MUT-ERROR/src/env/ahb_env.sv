// SPDX-License-Identifier: Apache-2.0
class ahb_env extends uvm_env;
  `uvm_component_utils(ahb_env)
  ahb_agent manager,subordinate;
  ahb_scoreboard scoreboard;
  function new(string name,uvm_component parent);super.new(name,parent);endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    manager=ahb_agent#()::type_id::create("manager",this);
    subordinate=ahb_agent#()::type_id::create("subordinate",this);
    scoreboard=ahb_scoreboard::type_id::create("scoreboard",this);
  endfunction
  function void connect_phase(uvm_phase phase);super.connect_phase(phase);manager.monitor.transaction_ap.connect(scoreboard.analysis_export);endfunction
endclass
