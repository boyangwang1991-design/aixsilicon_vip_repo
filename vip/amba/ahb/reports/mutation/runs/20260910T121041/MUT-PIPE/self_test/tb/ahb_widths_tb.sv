// SPDX-License-Identifier: Apache-2.0
module ahb_width_probe #(int AW=32,DW=32)(input logic clk,rst_n);
  import ahb_pkg::*;
  ahb_if#(AW,DW,0,0) bus(clk,rst_n);
  virtual ahb_if#(AW,DW,0,0) vif;
  ahb_monitor#(AW,DW,0,0) mon;
  initial begin vif=bus;if($bits(bus.HADDR)!=AW || $bits(bus.HWDATA)!=DW) $fatal(1,"WIDTH_FAIL");end
endmodule
module ahb_widths_tb;
  logic clk=0,rst_n=0;
  ahb_width_probe#(10,8) p0(clk,rst_n);
  ahb_width_probe#(17,16) p1(clk,rst_n);
  ahb_width_probe#(32,32) p2(clk,rst_n);
  ahb_width_probe#(33,64) p3(clk,rst_n);
  ahb_width_probe#(64,128) p4(clk,rst_n);
  ahb_width_probe#(10,256) p5(clk,rst_n);
  ahb_width_probe#(64,512) p6(clk,rst_n);
  ahb_width_probe#(64,1024) p7(clk,rst_n);
  initial begin #1;$display("AHB_WIDTHS_PASS");$finish;end
endmodule
