// SPDX-License-Identifier: Apache-2.0
class ahb_smoke_test extends uvm_test;
  `uvm_component_utils(ahb_smoke_test)
  ahb_agent master_agent,slave_agent;
  ahb_scoreboard scoreboard;
  ahb_config manager_cfg,slave_cfg;
  function new(string name,uvm_component parent);super.new(name,parent);endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);manager_cfg=ahb_config::type_id::create("manager_cfg");slave_cfg=ahb_config::type_id::create("slave_cfg");slave_cfg.mode=ACTIVE_SLAVE;
    void'($value$plusargs("WAIT=%d",slave_cfg.max_wait));slave_cfg.min_wait=slave_cfg.max_wait;
    uvm_config_db#(ahb_config)::set(this,"master_agent*","cfg",manager_cfg);
    uvm_config_db#(ahb_config)::set(this,"slave_agent*","cfg",slave_cfg);
    uvm_config_db#(ahb_config)::set(this,"scoreboard","cfg",manager_cfg);
    master_agent=ahb_agent#()::type_id::create("master_agent",this);slave_agent=ahb_agent#()::type_id::create("slave_agent",this);
    scoreboard=ahb_scoreboard::type_id::create("scoreboard",this);
  endfunction
  function void connect_phase(uvm_phase phase);super.connect_phase(phase);master_agent.monitor.transaction_ap.connect(scoreboard.analysis_export);endfunction
  task run_phase(uvm_phase phase);
    ahb_smoke_seq seq;phase.raise_objection(this);seq=ahb_smoke_seq::type_id::create("seq");
    #100ns;seq.start(master_agent.sequencer);#30ns;
    if(master_agent.coverage.completed!=64 || slave_agent.slave_driver.memory.writes!=32) `uvm_error("COUNTS","expected 64 beats and exactly 32 writes")
    `uvm_info("AHB_TEST_PASS","smoke completion oracle reached",UVM_NONE)
    phase.drop_objection(this);
  endtask
endclass
