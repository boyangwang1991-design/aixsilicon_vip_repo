// SPDX-License-Identifier: Apache-2.0
module ahb_negative_tb;
  import uvm_pkg::*;import ahb_types_pkg::*;import ahb_pkg::*;
  ahb_checker scb;ahb_config cfg;int checks=0,failures=0;
  function ahb_cycle sample_value(int trans=0,longint unsigned addr=0,bit wr=0,bit ready=1,int resp=0,int burst=0);
    ahb_cycle s;s=new();s.reset_n=1;s.ready=ready;s.readyout=ready;s.sel=1;s.trans=2'(trans);s.resp=2'(resp);s.exokay=0;
    s.address.addr=addr;s.address.size=2;s.address.write=wr;s.address.burst=3'(burst);s.address.prot=3;
    s.wdata=0;s.rdata=0;s.strb='1;s.wu=0;s.ru=0;s.bu=0;return s;
  endfunction
  task expect_rule(string id,int expected_count=1);
    int found;found=0;checks++;
    foreach(scb.violations[i]) if(scb.violations[i].rule_id==id) found++;
    if(found!=expected_count || scb.violations.size()!=expected_count) begin failures++;$display("FAILED: expected %s count=%0d actual=%0d total=%0d",id,expected_count,found,scb.violations.size());foreach(scb.violations[i]) $display("  %s",scb.violations[i].convert2string());end
    else $display("AHB_RULE_TEST id=%s detected=%0d cycle=%0d",id,found,scb.cycle_number);
  endtask
  task restart();ahb_cycle s;s=sample_value();s.reset_n=0;scb.sample(s);endtask
  initial begin
    ahb_cycle s;
    cfg=new();scb=new();scb.cfg=cfg;scb.instance_name="independent_negative";
    restart();s=sample_value(2,2);scb.sample(s);expect_rule("AHB-CHECK-ALIGN");
    restart();s=sample_value(2,0);s.address.size=3;scb.sample(s);expect_rule("AHB-CHECK-SIZE");
    restart();scb.sample(sample_value(3,0));expect_rule("AHB-CHECK-SEQ");
    restart();scb.sample(sample_value(2,0,0,1,0,3));scb.sample(sample_value(3,8,0,1,0,3));expect_rule("AHB-CHECK-SEQ-ADDR");
    restart();scb.sample(sample_value(2,0,0,1,0,3));s=sample_value(3,4,1,1,0,3);scb.sample(s);expect_rule("AHB-CHECK-BURST-ATTR");
    restart();scb.sample(sample_value(2,'h3fc,0,1,0,1));scb.sample(sample_value(3,'h400,0,1,0,1));expect_rule("AHB-CHECK-BOUNDARY");
    restart();scb.sample(sample_value(1,0));expect_rule("AHB-CHECK-BUSY");
    restart();scb.sample(sample_value(2,0,1));scb.sample(sample_value(2,4,0,0));scb.sample(sample_value(2,8,0,0));expect_rule("AHB-CHECK-HOLD-ADDR");
    restart();scb.sample(sample_value(2,0,1));scb.sample(sample_value(0,0,0,0));s=sample_value(0,0,0,0);s.wdata=1;scb.sample(s);expect_rule("AHB-CHECK-HOLD-WDATA");
    restart();scb.sample(sample_value(2,0));scb.sample(sample_value(0,0,0,1,1));expect_rule("AHB-CHECK-ERROR-TWO");
    restart();scb.sample(sample_value(2,0));scb.sample(sample_value(0,0,0,0,1));scb.sample(sample_value(0,0,0,0,1));expect_rule("AHB-CHECK-ERROR-TWO");
    restart();scb.sample(sample_value(0,0,0,1,1));expect_rule("AHB-CHECK-RESP-PHASE");
    restart();scb.sample(sample_value(2,0));s=sample_value();s.rdata='x;scb.sample(s);expect_rule("AHB-CHECK-DATA-X");
    restart();s=sample_value();s.trans='x;scb.sample(s);expect_rule("AHB-CHECK-CONTROL-X");
    restart();cfg.exclusive=1;scb.sample(sample_value(2,0));s=sample_value();s.exokay=1;scb.sample(s);expect_rule("AHB-CHECK-EXOKAY");
    restart();s=sample_value(2,0,0,1,0,3);s.address.exclusive=1;scb.sample(s);expect_rule("AHB-CHECK-EX-FORM");
    restart();s=sample_value(2,0);s.address.exclusive=1;scb.sample(s);s=sample_value(2,4);s.address.exclusive=1;scb.sample(s);expect_rule("AHB-CHECK-EX-OVERLAP");cfg.exclusive=0;
    restart();cfg.allow_write=0;scb.sample(sample_value(2,0,1));expect_rule("AHB-CHECK-CAPABILITY");cfg.allow_write=1;
    restart();cfg.watchdog_cycles=1;scb.sample(sample_value(2,0));scb.sample(sample_value(0,0,0,0));expect_rule("AHB-CHECK-WATCHDOG");cfg.watchdog_cycles=100000;
    restart();cfg.strobe=1;scb.sample(sample_value(2,0,1));scb.sample(sample_value(0,0,0,0));s=sample_value(0,0,0,0);s.strb=0;scb.sample(s);expect_rule("AHB-CHECK-HOLD-STRB");cfg.strobe=0;
    restart();cfg.au=8;scb.sample(sample_value(2,0));scb.sample(sample_value(2,4,0,0));s=sample_value(2,4,0,0);s.address.auser=1;scb.sample(s);expect_rule("AHB-CHECK-HOLD-AUSER");cfg.au=0;
    restart();cfg.du=8;scb.sample(sample_value(2,0,1));scb.sample(sample_value(0,0,0,0));s=sample_value(0,0,0,0);s.wu=1;scb.sample(s);expect_rule("AHB-CHECK-HOLD-WUSER");cfg.du=0;
    // Legal anti-overchecking: inactive payload X and IDLE address changes.
    restart();s=sample_value();s.wdata='x;s.rdata='x;scb.sample(s);expect_rule("none",0);
    restart();scb.sample(sample_value(2,0,1));scb.sample(sample_value(0,12,0,0));scb.sample(sample_value(0,28,0,0));expect_rule("none",0);
    scb.sample(sample_value(2,32,0,0));expect_rule("none",0);scb.sample(sample_value(2,32,0,1));expect_rule("none",0);scb.sample(sample_value());expect_rule("none",0);
    $display("NEGATIVE_SUMMARY checks=%0d failures=%0d",checks,failures);if(failures) $fatal(1,"NEGATIVE_FAIL");$display("AHB_NEGATIVE_PASS");$finish;
  end
endmodule
