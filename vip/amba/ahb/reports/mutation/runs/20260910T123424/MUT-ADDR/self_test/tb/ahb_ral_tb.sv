// SPDX-License-Identifier: Apache-2.0
module ahb_ral_tb;
  timeunit 1ns;timeprecision 1ps;
  import uvm_pkg::*;import ahb_types_pkg::*;import ahb_pkg::*;
  `include "uvm_macros.svh"
  logic clk=0,rst_n=0;always #5 clk=~clk;initial begin repeat(5) @(negedge clk);rst_n=1;end
  ahb_if bus(clk,rst_n);assign bus.HREADY=bus.HREADYOUT;assign bus.HSEL=1;
  class test_reg extends uvm_reg;
    `uvm_object_utils(test_reg)
    uvm_reg_field value;
    function new(string name="test_reg");super.new(name,32,UVM_NO_COVERAGE);endfunction
    function void build();value=uvm_reg_field::type_id::create("value");value.configure(this,32,0,"RW",0,0,1,1,0);endfunction
  endclass
  class test_block extends uvm_reg_block;
    `uvm_object_utils(test_block)
    test_reg good,bad;
    function new(string name="test_block");super.new(name,UVM_NO_COVERAGE);endfunction
    function void build();
      default_map=create_map("map",0,4,UVM_LITTLE_ENDIAN,1);
      good=test_reg::type_id::create("good");good.configure(this);good.build();default_map.add_reg(good,'h100,"RW");
      bad=test_reg::type_id::create("bad");bad.configure(this);bad.build();default_map.add_reg(bad,'hff00,"RW");lock_model();
    endfunction
  endclass
  class ral_test extends uvm_test;
    `uvm_component_utils(ral_test)
    ahb_agent manager,subordinate;ahb_config mc,sc;ahb_reg_adapter adapter;ahb_reg_predictor predictor;test_block regs;
    function new(string name,uvm_component parent);super.new(name,parent);endfunction
    function void build_phase(uvm_phase phase);
      super.build_phase(phase);mc=new();sc=new();sc.mode=ACTIVE_SLAVE;sc.error_enable=1;sc.error_start='hff00;sc.error_end='hff03;
      uvm_config_db#(ahb_config)::set(this,"manager*","cfg",mc);uvm_config_db#(ahb_config)::set(this,"subordinate*","cfg",sc);
      manager=ahb_agent#()::type_id::create("manager",this);subordinate=ahb_agent#()::type_id::create("subordinate",this);
      adapter=ahb_reg_adapter::type_id::create("adapter");adapter.cfg=mc;
      predictor=ahb_reg_predictor::type_id::create("predictor",this);
      regs=test_block::type_id::create("regs");regs.build();regs.reset();
    endfunction
    function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);regs.default_map.set_sequencer(manager.sequencer,adapter);regs.default_map.set_auto_predict(0);
      predictor.map=regs.default_map;predictor.adapter=adapter;manager.monitor.transaction_ap.connect(predictor.bus_in);
    endfunction
    task run_phase(uvm_phase phase);
      uvm_status_e status;uvm_reg_data_t data;
      phase.raise_objection(this);#100;
      regs.good.write(status,'h12345678,UVM_FRONTDOOR);#1;
      if(status!=UVM_IS_OK || regs.good.get_mirrored_value()!='h12345678) `uvm_error("RAL-WRITE","status/mirror")
      regs.good.read(status,data,UVM_FRONTDOOR);if(status!=UVM_IS_OK || data!='h12345678) `uvm_error("RAL-READ","data")
      regs.bad.write(status,'hdeadbeef,UVM_FRONTDOOR);#1;
      if(status!=UVM_NOT_OK || regs.bad.get_mirrored_value()!=0) `uvm_error("RAL-ERROR","error changed mirror")
      #20;$display("AHB_RAL_PASS");phase.drop_objection(this);
    endtask
  endclass
  initial begin uvm_config_db#(virtual ahb_if)::set(null,"uvm_test_top.*","vif",bus);run_test("ral_test");end
  initial begin #100000;$fatal(1,"RAL_WATCHDOG");end
endmodule
