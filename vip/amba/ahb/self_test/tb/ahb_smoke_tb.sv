// SPDX-License-Identifier: Apache-2.0
module ahb_smoke_tb;
  timeunit 1ns;timeprecision 1ps;
  import uvm_pkg::*;import ahb_types_pkg::*;import ahb_pkg::*;
  `include "uvm_macros.svh"
  `include "ahb_smoke_env.sv"
  logic clk=0,rst_n=0;
  always #5 clk=~clk;
  initial begin repeat(5) @(negedge clk);rst_n=1;end
  ahb_if bus(clk,rst_n);
  assign bus.HREADY=bus.HREADYOUT;
  assign bus.HSEL=1;
  initial begin uvm_config_db#(virtual ahb_if)::set(null,"uvm_test_top.*","vif",bus);run_test("ahb_smoke_test");end
  // 512 transfers, ten ns clock, plus startup and a bounded 2x margin.
  initial begin
    longint unsigned watchdog_ns;
    int wait_setting;
    wait_setting=0;
    void'($value$plusargs("WAIT=%d",wait_setting));
    if(wait_setting<0) $fatal(1,"INVALID_WAIT");
    watchdog_ns=10000+64'd512*(64'(wait_setting)+2)*10*2;
    $display("AHB_WATCHDOG_BUDGET_NS=%0d WAIT=%0d",watchdog_ns,wait_setting);
    #(watchdog_ns*1ns);
    $fatal(1,"WALLCLOCK_WATCHDOG");
  end
endmodule
