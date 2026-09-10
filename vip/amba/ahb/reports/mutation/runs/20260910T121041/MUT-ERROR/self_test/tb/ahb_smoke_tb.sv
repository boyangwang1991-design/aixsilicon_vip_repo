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
  initial begin #1000000;$fatal(1,"WALLCLOCK_WATCHDOG");end
endmodule
