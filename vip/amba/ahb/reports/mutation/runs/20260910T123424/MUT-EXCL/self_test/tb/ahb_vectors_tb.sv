// SPDX-License-Identifier: Apache-2.0
// Independent bus vectors: no VIP driver or subordinate instantiated.
module ahb_vectors_tb;
  timeunit 1ns;timeprecision 1ps;
  import uvm_pkg::*;import ahb_types_pkg::*;import ahb_pkg::*;
  `include "uvm_macros.svh"
  logic clk=0,rst_n=0;always #5 clk=~clk;
  ahb_if bus(clk,rst_n);
  // Independent procedural stimulus drives interface nets through continuous connections.
  logic [$bits(bus.HADDR)-1:0] drive_HADDR;
  assign bus.HADDR=drive_HADDR;
  logic [$bits(bus.HAUSER)-1:0] drive_HAUSER;
  assign bus.HAUSER=drive_HAUSER;
  logic [$bits(bus.HBURST)-1:0] drive_HBURST;
  assign bus.HBURST=drive_HBURST;
  logic [$bits(bus.HBUSER)-1:0] drive_HBUSER;
  assign bus.HBUSER=drive_HBUSER;
  logic [$bits(bus.HEXCL)-1:0] drive_HEXCL;
  assign bus.HEXCL=drive_HEXCL;
  logic [$bits(bus.HEXOKAY)-1:0] drive_HEXOKAY;
  assign bus.HEXOKAY=drive_HEXOKAY;
  logic [$bits(bus.HMASTER)-1:0] drive_HMASTER;
  assign bus.HMASTER=drive_HMASTER;
  logic [$bits(bus.HMASTLOCK)-1:0] drive_HMASTLOCK;
  assign bus.HMASTLOCK=drive_HMASTLOCK;
  logic [$bits(bus.HNONSEC)-1:0] drive_HNONSEC;
  assign bus.HNONSEC=drive_HNONSEC;
  logic [$bits(bus.HPROT)-1:0] drive_HPROT;
  assign bus.HPROT=drive_HPROT;
  logic [$bits(bus.HRDATA)-1:0] drive_HRDATA;
  assign bus.HRDATA=drive_HRDATA;
  logic [$bits(bus.HREADY)-1:0] drive_HREADY;
  assign bus.HREADY=drive_HREADY;
  logic [$bits(bus.HREADYOUT)-1:0] drive_HREADYOUT;
  assign bus.HREADYOUT=drive_HREADYOUT;
  logic [$bits(bus.HRESP)-1:0] drive_HRESP;
  assign bus.HRESP=drive_HRESP;
  logic [$bits(bus.HRUSER)-1:0] drive_HRUSER;
  assign bus.HRUSER=drive_HRUSER;
  logic [$bits(bus.HSEL)-1:0] drive_HSEL;
  assign bus.HSEL=drive_HSEL;
  logic [$bits(bus.HSIZE)-1:0] drive_HSIZE;
  assign bus.HSIZE=drive_HSIZE;
  logic [$bits(bus.HTRANS)-1:0] drive_HTRANS;
  assign bus.HTRANS=drive_HTRANS;
  logic [$bits(bus.HWDATA)-1:0] drive_HWDATA;
  assign bus.HWDATA=drive_HWDATA;
  logic [$bits(bus.HWRITE)-1:0] drive_HWRITE;
  assign bus.HWRITE=drive_HWRITE;
  logic [$bits(bus.HWSTRB)-1:0] drive_HWSTRB;
  assign bus.HWSTRB=drive_HWSTRB;
  logic [$bits(bus.HWUSER)-1:0] drive_HWUSER;
  assign bus.HWUSER=drive_HWUSER;
  class sink extends uvm_subscriber#(ahb_item);
    `uvm_component_utils(sink)
    ahb_item seen[$];
    function new(string name,uvm_component parent);super.new(name,parent);endfunction
    function void write(ahb_item t);seen.push_back(t.duplicate());t.addr=0;t.status=ERROR;t.data=0;endfunction
  endclass
  class cycle_mutator extends uvm_subscriber#(ahb_cycle);
    `uvm_component_utils(cycle_mutator)
    function new(string name,uvm_component parent);super.new(name,parent);endfunction
    function void write(ahb_cycle t);t.reset_n=0;t.address.addr=0;t.wdata=0;endfunction
  endclass
  class burst_sink extends uvm_subscriber#(ahb_burst);
    `uvm_component_utils(burst_sink)
    ahb_item beats[$];
    function new(string name,uvm_component parent);super.new(name,parent);endfunction
    function void write(ahb_burst t);foreach(t.beats[i]) beats.push_back(t.beats[i].duplicate());endfunction
  endclass
  class vector_test extends uvm_test;
    `uvm_component_utils(vector_test)
    ahb_monitor mon;sink observed;cycle_mutator mutator;burst_sink bursts;ahb_config cfg;
    function new(string name,uvm_component parent);super.new(name,parent);endfunction
    function void build_phase(uvm_phase phase);
      super.build_phase(phase);cfg=new();cfg.mode=PASSIVE;
      uvm_config_db#(ahb_config)::set(this,"mon","cfg",cfg);
      mon=ahb_monitor#()::type_id::create("mon",this);observed=sink::type_id::create("observed",this);mutator=cycle_mutator::type_id::create("mutator",this);bursts=burst_sink::type_id::create("bursts",this);
    endfunction
    function void connect_phase(uvm_phase phase);mon.transaction_ap.connect(observed.analysis_export);mon.cycle_ap.connect(mutator.analysis_export);mon.burst_ap.connect(bursts.analysis_export);endfunction
    task run_phase(uvm_phase phase);phase.raise_objection(this);wait(done);#20;phase.drop_objection(this);endtask
  endclass
  bit done=0;int failures=0,checks=0;
  vector_test test_handle;
  task tick(bit[1:0] tr,bit[31:0] addr,bit wr,bit ready,bit resp,logic[31:0] wd,logic[31:0] rd,bit[2:0] burst=0);
    @(negedge clk);drive_HTRANS=tr;drive_HADDR=addr;drive_HWRITE=wr;drive_HREADY=ready;drive_HREADYOUT=ready;drive_HRESP=resp;drive_HWDATA=wd;drive_HRDATA=rd;drive_HBURST=burst;
    @(posedge clk);#1;
  endtask
  task check(string id,bit ok);checks++;if(!ok) begin failures++;$display("FAILED: %s",id);end endtask
  initial begin
    drive_HADDR=0;drive_HTRANS=0;drive_HWRITE=0;drive_HSIZE=2;drive_HBURST=0;drive_HPROT=3;drive_HMASTLOCK=0;drive_HSEL=1;drive_HREADY=1;drive_HREADYOUT=1;drive_HRESP=0;drive_HWDATA=0;drive_HRDATA=0;drive_HNONSEC=0;drive_HEXCL=0;drive_HEXOKAY=0;drive_HMASTER=0;drive_HAUSER=0;drive_HWUSER=0;drive_HRUSER=0;drive_HBUSER=0;drive_HWSTRB='1;
    repeat(3) @(negedge clk);rst_n=1;
    tick(2,'h100,1,1,0,0,0);
    tick(2,'h204,1,1,0,'h11223344,0);
    tick(0,0,0,1,0,'h55667788,0);
    check("V00_subscriber_isolation",test_handle.bursts.beats.size()==2 && test_handle.bursts.beats[0].addr=='h100 && test_handle.bursts.beats[0].status==OKAY);
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
    @(negedge clk);drive_HREADY=1;drive_HRESP=0;rst_n=1;
    tick(0,0,0,1,0,0,0);
    check("V11_no_ghost",test_handle.observed.seen.size()==16);
    $display("VECTOR_SUMMARY checks=%0d failures=%0d",checks,failures);
    if(failures) $fatal(1,"VECTOR_FAIL");$display("AHB_VECTOR_PASS");done=1;
  end
  initial begin uvm_config_db#(virtual ahb_if)::set(null,"uvm_test_top.mon","vif",bus);test_handle=vector_test::type_id::create("uvm_test_top",null);run_test();end
  initial begin #100000;$fatal(1,"VECTOR_WATCHDOG");end
endmodule
