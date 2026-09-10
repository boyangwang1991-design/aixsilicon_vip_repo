// SPDX-License-Identifier: Apache-2.0
class ahb_throughput_probe extends uvm_subscriber#(ahb_item);
  `uvm_component_utils(ahb_throughput_probe)
  longint unsigned last_write_cycle=0;
  int writes=0,bubbles=0;
  function new(string name,uvm_component parent);super.new(name,parent);endfunction
  function void write(ahb_item t);
    if(t.write && t.status==OKAY) begin
      if(writes && t.completed_cycle!=last_write_cycle+1) bubbles++;
      writes++;last_write_cycle=t.completed_cycle;
    end
  endfunction
endclass
class ahb_smoke_test extends uvm_test;
  `uvm_component_utils(ahb_smoke_test)
  ahb_agent master_agent,slave_agent;
  ahb_scoreboard scoreboard;
  ahb_throughput_probe throughput;
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
    throughput=ahb_throughput_probe::type_id::create("throughput",this);
  endfunction
  function void connect_phase(uvm_phase phase);super.connect_phase(phase);master_agent.monitor.transaction_ap.connect(scoreboard.analysis_export);master_agent.monitor.transaction_ap.connect(throughput.analysis_export);endfunction
  task run_phase(uvm_phase phase);
    ahb_smoke_seq seq;phase.raise_objection(this);seq=ahb_smoke_seq::type_id::create("seq");
    seq.count=256;#100ns;seq.start(master_agent.sequencer);#30ns;
    if(master_agent.coverage.completed!=512 || slave_agent.slave_driver.memory.writes!=256) `uvm_error("COUNTS","expected 512 beats and exactly 256 writes")
    if(slave_cfg.max_wait==0 && (throughput.writes!=256 || throughput.bubbles!=0)) `uvm_error("THROUGHPUT","256 writes must complete on consecutive clocks")
    `uvm_info("AHB_TEST_PASS","smoke completion oracle reached",UVM_NONE)
    phase.drop_objection(this);
  endtask
endclass
