// SPDX-License-Identifier: Apache-2.0
module ahb_extensions_tb;
  timeunit 1ns;timeprecision 1ps;
  import uvm_pkg::*;import ahb_types_pkg::*;import ahb_pkg::*;
  `include "uvm_macros.svh"
  logic clk=0,rst_n=0;always #5 clk=~clk;
  initial begin repeat(5) @(negedge clk);rst_n=1;end
  ahb_if lite(clk,rst_n);
  ahb_if#(17,128,3,7,4,9,16,3,1,1,1,1,1) wide(clk,rst_n);
  assign lite.HREADY=lite.HREADYOUT;assign lite.HSEL=1;
  assign wide.HREADY=wide.HREADYOUT;assign wide.HSEL=1;
  assign wide.HREADYCHK=~wide.HREADY;assign wide.HSELCHK=~wide.HSEL;
  class extension_seq extends ahb_base_seq;
    `uvm_object_utils(extension_seq)
    function new(string name="extension_seq");super.new(name);endfunction
    task body();
      ahb_item t,r,rr,wr;ahb_item responses[$];
      // AHB5 zero/sparse strobes, USER, secure and exclusive status.
      t=new();t.addr='h100;t.write=1;t.data='h11223344;t.strobe=15;t.auser='h101;t.wuser='h55aa;transfer(t,r);
      t=new();t.addr='h100;t.write=1;t.data='hffffffff;t.strobe=0;transfer(t,r);
      t=new();t.addr='h100;transfer(t,r);if(r.data[31:0]!=='h11223344) `uvm_error("ZERO-STROBE",r.convert2string())
      t=new();t.addr='h100;t.write=1;t.data='haabbccdd;t.strobe=5;transfer(t,r);
      t=new();t.addr='h100;transfer(t,r);if(r.data[31:0]!=='h11bb33dd) `uvm_error("SPARSE-STROBE",r.convert2string())
      t=new();t.addr='h100;t.write=1;t.exclusive=1;t.master=3;t.data='h87654321;transfer(t,r);
      if(r.status!=EXCLUSIVE_FAIL) `uvm_error("EX-FAIL",r.convert2string())
      t=new();t.addr='h100;t.master=3;t.data='h87654321;exclusive_pair(t,rr,wr);
      if(rr.status!=OKAY || wr.status!=OKAY || !wr.exokay) `uvm_error("EX-PAIR",wr.convert2string())
      t=new();t.addr='h100;transfer(t,r);if(r.data[31:0]!=='h87654321) `uvm_error("EX-DATA",r.convert2string())
      t=new();t.addr='h120;t.write=1;t.size=4;t.data=128'h00112233445566778899aabbccddeeff;t.nonsecure=1;transfer(t,r);
      t=new();t.addr='h120;t.size=4;t.nonsecure=1;transfer(t,r);if(r.data[127:0]!==128'h00112233445566778899aabbccddeeff) `uvm_error("WIDE",r.convert2string())
    endtask
  endclass
  class extension_test extends uvm_test;
    `uvm_component_utils(extension_test)
    ahb_agent lm,ls;
    ahb_agent#(17,128,3,7,4,9,16,3,1,1,1,1,1) wm,ws;
    ahb_config lc,lt,wc,wt;
    function new(string name,uvm_component parent);super.new(name,parent);endfunction
    function void build_phase(uvm_phase phase);
      super.build_phase(phase);lc=new();lt=new();lt.mode=ACTIVE_SLAVE;
      wc=new();wc.aw=17;wc.dw=128;wc.pw=7;wc.mw=4;wc.au=9;wc.du=16;wc.ru=3;wc.profile=AHB5;wc.secure=1;wc.exclusive=1;wc.strobe=1;wc.parity=1;
      wt=new();wt.aw=17;wt.dw=128;wt.pw=7;wt.mw=4;wt.au=9;wt.du=16;wt.ru=3;wt.profile=AHB5;wt.secure=1;wt.exclusive=1;wt.strobe=1;wt.parity=1;wt.mode=ACTIVE_SLAVE;wt.max_wait=2;wt.min_wait=2;
      uvm_config_db#(ahb_config)::set(this,"lm*","cfg",lc);uvm_config_db#(ahb_config)::set(this,"ls*","cfg",lt);
      uvm_config_db#(ahb_config)::set(this,"wm*","cfg",wc);uvm_config_db#(ahb_config)::set(this,"ws*","cfg",wt);
      lm=ahb_agent#()::type_id::create("lm",this);ls=ahb_agent#()::type_id::create("ls",this);
      wm=ahb_agent#(17,128,3,7,4,9,16,3,1,1,1,1,1)::type_id::create("wm",this);ws=ahb_agent#(17,128,3,7,4,9,16,3,1,1,1,1,1)::type_id::create("ws",this);
    endfunction
    task run_phase(uvm_phase phase);
      extension_seq seq;ahb_smoke_seq basic;phase.raise_objection(this);seq=new();basic=new();#100;
      fork seq.start(wm.sequencer);basic.start(lm.sequencer);join
      #30;$display("AHB_EXTENSIONS_PASS");phase.drop_objection(this);
    endtask
  endclass
  initial begin
    uvm_config_db#(virtual ahb_if)::set(null,"uvm_test_top.l*","vif",lite);
    uvm_config_db#(virtual ahb_if#(17,128,3,7,4,9,16,3,1,1,1,1,1))::set(null,"uvm_test_top.w*","vif",wide);
    run_test("extension_test");
  end
  initial begin #1000000;$fatal(1,"EXTENSIONS_WATCHDOG");end
endmodule
