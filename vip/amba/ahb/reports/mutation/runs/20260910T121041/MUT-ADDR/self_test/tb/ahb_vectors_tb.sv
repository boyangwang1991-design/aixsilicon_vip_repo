// SPDX-License-Identifier: Apache-2.0
// Independent bus vectors: no VIP driver or subordinate instantiated.
module ahb_vectors_tb;
  timeunit 1ns;timeprecision 1ps;
  import uvm_pkg::*;import ahb_types_pkg::*;import ahb_pkg::*;
  `include "uvm_macros.svh"
  logic clk=0,rst_n=0;always #5 clk=~clk;
  ahb_if bus(clk,rst_n);
  class sink extends uvm_subscriber#(ahb_item);
    `uvm_component_utils(sink)
    ahb_item seen[$];
    function new(string name,uvm_component parent);super.new(name,parent);endfunction
    function void write(ahb_item t);seen.push_back(t.duplicate());endfunction
  endclass
  class vector_test extends uvm_test;
    `uvm_component_utils(vector_test)
    ahb_monitor mon;sink observed;ahb_config cfg;
    function new(string name,uvm_component parent);super.new(name,parent);endfunction
    function void build_phase(uvm_phase phase);
      super.build_phase(phase);cfg=new();cfg.mode=PASSIVE;
      uvm_config_db#(ahb_config)::set(this,"mon","cfg",cfg);
      mon=ahb_monitor#()::type_id::create("mon",this);observed=sink::type_id::create("observed",this);
    endfunction
    function void connect_phase(uvm_phase phase);mon.transaction_ap.connect(observed.analysis_export);endfunction
    task run_phase(uvm_phase phase);phase.raise_objection(this);wait(done);#20;phase.drop_objection(this);endtask
  endclass
  bit done=0;int failures=0,checks=0;
  vector_test test_handle;
  task tick(bit[1:0] tr,bit[31:0] addr,bit wr,bit ready,bit resp,logic[31:0] wd,logic[31:0] rd,bit[2:0] burst=0);
    @(negedge clk);bus.HTRANS=tr;bus.HADDR=addr;bus.HWRITE=wr;bus.HREADY=ready;bus.HREADYOUT=ready;bus.HRESP=resp;bus.HWDATA=wd;bus.HRDATA=rd;bus.HBURST=burst;
    @(posedge clk);#1;
  endtask
  task check(string id,bit ok);checks++;if(!ok) begin failures++;$display("FAILED: %s",id);end endtask
  initial begin
    bus.HADDR=0;bus.HTRANS=0;bus.HWRITE=0;bus.HSIZE=2;bus.HBURST=0;bus.HPROT=3;bus.HMASTLOCK=0;bus.HSEL=1;bus.HREADY=1;bus.HREADYOUT=1;bus.HRESP=0;bus.HWDATA=0;bus.HRDATA=0;bus.HNONSEC=0;bus.HEXCL=0;bus.HEXOKAY=0;bus.HMASTER=0;bus.HAUSER=0;bus.HWUSER=0;bus.HRUSER=0;bus.HBUSER=0;bus.HWSTRB='1;
    repeat(3) @(negedge clk);rst_n=1;
    tick(2,'h100,1,1,0,0,0);
    tick(2,'h204,1,1,0,'h11223344,0);
    tick(0,0,0,1,0,'h55667788,0);
    check("V01_b2b_count",test_handle.observed.seen.size()==2);
    check("V01_data_association",test_handle.observed.seen[0].addr=='h100 && test_handle.observed.seen[0].data[31:0]=='h11223344 && test_handle.observed.seen[1].addr=='h204 && test_handle.observed.seen[1].data[31:0]=='h55667788);
    tick(2,'h300,1,1,0,0,0);
    tick(2,'h400,0,0,0,'hdeadbeef,'x);
    tick(2,'h400,0,0,0,'hdeadbeef,'x);
    tick(2,'h400,0,0,0,'hdeadbeef,'x);
    tick(2,'h400,0,1,0,'hdeadbeef,'x);
    tick(0,0,0,1,0,0,'hfacecafe);
    check("V02_no_duplicate",test_handle.observed.seen.size()==4 && test_handle.observed.seen[2].waits==3 && test_handle.observed.seen[3].data[31:0]=='hfacecafe);
    tick(2,'h100,1,1,0,0,0,3);
    tick(1,'h104,1,0,0,1,0,3);
    tick(3,'h104,1,0,0,1,0,3);
    tick(3,'h104,1,1,0,1,0,3);
    tick(3,'h108,1,1,0,2,0,3);
    tick(3,'h10c,1,1,0,3,0,3);
    tick(0,0,0,1,0,4,0);
    tick(2,'h600,1,1,0,0,0,1);
    tick(1,'h604,1,0,0,1,0,1);
    tick(2,'h700,1,0,0,1,0,0);
    tick(2,'h700,1,1,0,1,0,0);
    tick(0,0,0,1,0,2,0);
    tick(2,'h800,1,1,0,0,0);
    tick(2,'h804,1,0,1,'x,0);
    tick(0,0,0,1,1,'x,0);
    tick(0,0,0,1,0,0,0);
    check("V05_cancel_no_ghost",test_handle.observed.seen.size()==11 && test_handle.observed.seen[10].status==ERROR);
    tick(2,'h80c,1,1,0,0,0,2);
    tick(3,'h800,1,1,0,10,0,2);
    tick(3,'h804,1,1,0,11,0,2);
    tick(3,'h808,1,1,0,12,0,2);
    tick(0,0,0,1,0,13,0);
    check("V06_wrap",test_handle.observed.seen[12].addr=='h800 && test_handle.observed.seen.size()==15);
    tick(2,'h900,1,1,0,0,0);
    tick(0,0,0,0,0,42,0);
    @(negedge clk);rst_n=0;@(posedge clk);#1;
    check("V11_reset_abort",test_handle.observed.seen.size()==16 && test_handle.observed.seen[15].status==RESET_ABORT);
    @(negedge clk);bus.HREADY=1;bus.HRESP=0;rst_n=1;
    tick(0,0,0,1,0,0,0);
    check("V11_no_ghost",test_handle.observed.seen.size()==16);
    $display("VECTOR_SUMMARY checks=%0d failures=%0d",checks,failures);
    if(failures) $fatal(1,"VECTOR_FAIL");$display("AHB_VECTOR_PASS");done=1;
  end
  initial begin uvm_config_db#(virtual ahb_if)::set(null,"uvm_test_top.mon","vif",bus);test_handle=vector_test::type_id::create("uvm_test_top",null);run_test();end
  initial begin #100000;$fatal(1,"VECTOR_WATCHDOG");end
endmodule
