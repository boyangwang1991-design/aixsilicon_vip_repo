// SPDX-License-Identifier: Apache-2.0
module ahb_classic_tb;
  timeunit 1ns;timeprecision 1ps;
  logic clk=0,rst_n=0,ready=1;always #5 clk=~clk;
  logic[1:0] resp=0,trans=0;
  logic[3:0] req=0,lock_req=0,releases=0,grant,addr_owner,data_owner,masked;
  logic locked;int failures=0,checks=0;
  ahb_arbiter arb(clk,rst_n,ready,resp,req,lock_req,releases,trans,grant,addr_owner,data_owner,locked,masked);
  task tick();@(posedge clk);#1;endtask
  task check(string id,bit ok);checks++;if(!ok) begin failures++;$display("FAILED: %s",id);end endtask
  initial begin
    repeat(2) tick();@(negedge clk);rst_n=1;tick();check("default_idle_master",addr_owner==0 && grant==1);
    @(negedge clk);req=4'b0010;tick();check("grant_ownership",addr_owner==1);
    @(negedge clk);trans=2;req=4'b0100;tick();check("separate_data_owner",addr_owner==2 && data_owner==1);
    @(negedge clk);ready=0;req=4'b1000;tick();check("wait_owner_hold",addr_owner==2 && data_owner==1);
    @(negedge clk);resp=3;tick();check("split_mask_data_owner",masked[1]);
    @(negedge clk);ready=1;tick();check("split_handoff",addr_owner==3);
    @(negedge clk);resp=0;req=2;tick();check("split_not_regranted",addr_owner!=1);
    @(negedge clk);releases=2;tick();check("split_release",!masked[1] && addr_owner==1);
    @(negedge clk);releases=0;lock_req=2;tick();
    @(negedge clk);req=4;tick();check("locked_owner",addr_owner==1 && locked);
    @(negedge clk);rst_n=0;tick();check("reset_masks",masked==0 && addr_owner==0);
    $display("CLASSIC_SUMMARY checks=%0d failures=%0d",checks,failures);
    if(failures) $fatal(1,"CLASSIC_FAIL");$display("AHB_CLASSIC_PASS");$finish;
  end
endmodule
