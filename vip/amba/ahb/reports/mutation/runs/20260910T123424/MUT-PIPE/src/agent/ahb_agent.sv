// SPDX-License-Identifier: Apache-2.0
class ahb_agent #(int AW=32,DW=32,BW=3,PW=4,MW=0,AU=0,DU=0,RU=0,PROFILE=0, bit SECURE=0,EXCLUSIVE=0,STROBE=0,PARITY=0) extends uvm_agent;
  `uvm_component_param_utils(ahb_agent#(AW,DW,BW,PW,MW,AU,DU,RU,PROFILE,SECURE,EXCLUSIVE,STROBE,PARITY))
  ahb_config cfg;
  ahb_monitor#(AW,DW,BW,PW,MW,AU,DU,RU,PROFILE,SECURE,EXCLUSIVE,STROBE,PARITY) monitor;
  ahb_driver#(AW,DW,BW,PW,MW,AU,DU,RU,PROFILE,SECURE,EXCLUSIVE,STROBE,PARITY) driver;
  ahb_slave_driver#(AW,DW,BW,PW,MW,AU,DU,RU,PROFILE,SECURE,EXCLUSIVE,STROBE,PARITY) slave_driver;
  ahb_sequencer sequencer;
  ahb_coverage coverage;
  function new(string name,uvm_component parent);super.new(name,parent);endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(ahb_config)::get(this,"","cfg",cfg)) `uvm_fatal("AHB-CONFIG","cfg missing")
    if(cfg.validate()!="") `uvm_fatal("AHB-CONFIG",cfg.validate())
    if(cfg.aw!=AW || cfg.dw!=DW || cfg.bw!=BW || cfg.pw!=PW || cfg.mw!=MW || cfg.au!=AU || cfg.du!=DU || cfg.ru!=RU || int'(cfg.profile)!=PROFILE || cfg.secure!=SECURE || cfg.exclusive!=EXCLUSIVE || cfg.strobe!=STROBE || cfg.parity!=PARITY) `uvm_fatal("AHB-CONFIG","structural config/vif mismatch")
    cfg.freeze();
    uvm_config_db#(ahb_config)::set(this,"*","cfg",cfg);
    if(cfg.mode==DISABLED) return;
    monitor=ahb_monitor#(AW,DW,BW,PW,MW,AU,DU,RU,PROFILE,SECURE,EXCLUSIVE,STROBE,PARITY)::type_id::create("monitor",this);
    if(cfg.enable_coverage) coverage=ahb_coverage::type_id::create("coverage",this);
    if(cfg.mode==ACTIVE_MASTER) begin
      driver=ahb_driver#(AW,DW,BW,PW,MW,AU,DU,RU,PROFILE,SECURE,EXCLUSIVE,STROBE,PARITY)::type_id::create("driver",this);sequencer=ahb_sequencer::type_id::create("sequencer",this);
    end
    if(cfg.mode==ACTIVE_SLAVE) slave_driver=ahb_slave_driver#(AW,DW,BW,PW,MW,AU,DU,RU,PROFILE,SECURE,EXCLUSIVE,STROBE,PARITY)::type_id::create("slave_driver",this);
  endfunction
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if(driver!=null) driver.seq_item_port.connect(sequencer.seq_item_export);
    if(coverage!=null) monitor.transaction_ap.connect(coverage.analysis_export);
  endfunction
endclass
