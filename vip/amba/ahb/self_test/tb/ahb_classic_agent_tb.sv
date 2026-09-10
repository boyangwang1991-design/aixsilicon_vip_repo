// SPDX-License-Identifier: Apache-2.0
module ahb_classic_agent_tb;
  timeunit 1ns;timeprecision 1ps;
  import uvm_pkg::*;import ahb_types_pkg::*;import ahb_pkg::*;
  `include "uvm_macros.svh"
  logic clk=0,rst_n=0;always #5 clk=~clk;initial begin repeat(5) @(negedge clk);rst_n=1;end
  ahb_if#(32,32,3,4,4,0,0,0,2) bus(clk,rst_n);
  logic[3:0] grant,data_owner,split_mask;
  assign bus.HREADY=bus.HREADYOUT;assign bus.HSEL=bus.HMASTER!=0;
  assign bus.HGRANT={12'b0,grant};
  ahb_arbiter arb(clk,rst_n,bus.HREADY,bus.HRESP,bus.HBUSREQ[3:0],{2'b0,bus.HLOCK,1'b0},bus.HSPLIT[3:0],bus.HTRANS,grant,bus.HMASTER,data_owner,bus.HMASTLOCK,split_mask);
  class classic_seq extends ahb_base_seq;
    `uvm_object_utils(classic_seq)
    function new(string name="classic_seq");super.new(name);endfunction
    task body();ahb_item t,r;t=new();t.addr='h100;t.write=1;t.data='h12345678;transfer(t,r);
      if(r.status!=OKAY || r.attempt!=2) `uvm_error("CLASSIC-REPLAY",r.convert2string())
      t=new();t.addr='h100;transfer(t,r);if(r.status!=OKAY || r.data[31:0]!=='h12345678) `uvm_error("CLASSIC-DATA",r.convert2string())
    endtask
  endclass
  class classic_test extends uvm_test;
    `uvm_component_utils(classic_test)
    ahb_agent#(32,32,3,4,4,0,0,0,2) manager,subordinate;
    ahb_config mc,sc;ahb_response_policy policy;
    function new(string name,uvm_component parent);super.new(name,parent);endfunction
    function void build_phase(uvm_phase phase);
      super.build_phase(phase);mc=new();sc=new();mc.profile=AHB_CLASSIC;sc.profile=AHB_CLASSIC;mc.issue="A";sc.issue="A";mc.mw=4;sc.mw=4;sc.mode=ACTIVE_SLAVE;
      policy=new();policy.scripted_responses.push_back(2);policy.scripted_responses.push_back(3);policy.scripted_responses.push_back(0);
      uvm_config_db#(ahb_config)::set(this,"manager*","cfg",mc);uvm_config_db#(ahb_config)::set(this,"subordinate*","cfg",sc);
      uvm_config_db#(ahb_response_policy)::set(this,"subordinate.slave_driver","policy",policy);
      manager=ahb_agent#(32,32,3,4,4,0,0,0,2)::type_id::create("manager",this);subordinate=ahb_agent#(32,32,3,4,4,0,0,0,2)::type_id::create("subordinate",this);
    endfunction
    task run_phase(uvm_phase phase);classic_seq seq;phase.raise_objection(this);seq=new();#100;seq.start(manager.sequencer);#30;
      if(subordinate.slave_driver.memory.writes!=1) `uvm_error("CLASSIC-COMMIT","rejected attempts committed")
      $display("AHB_CLASSIC_AGENT_PASS");phase.drop_objection(this);
    endtask
  endclass
  initial begin uvm_config_db#(virtual ahb_if#(32,32,3,4,4,0,0,0,2))::set(null,"uvm_test_top.*","vif",bus);run_test("classic_test");end
  initial begin #1000000;$fatal(1,"CLASSIC_AGENT_WATCHDOG");end
endmodule
