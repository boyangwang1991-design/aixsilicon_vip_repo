// SPDX-License-Identifier: Apache-2.0
module ahb_assertions #(int AW=32,DW=32)(input logic HCLK,HRESETn,HREADY,HSEL,HRESP,
  input logic[1:0] HTRANS,input logic[AW-1:0] HADDR,input logic[2:0] HSIZE);
  logic data_valid;
  always @(posedge HCLK or negedge HRESETn) if(!HRESETn) data_valid<=0;else if(HREADY) data_valid<=HSEL && HTRANS[1];
  ap_size:assert property(@(posedge HCLK) disable iff(!HRESETn) HREADY && HSEL && HTRANS[1] |-> (1<<HSIZE)<=DW/8) else $error("AHB-SVA-SIZE");
  ap_align:assert property(@(posedge HCLK) disable iff(!HRESETn) HREADY && HSEL && HTRANS[1] |-> (HADDR & ((64'd1<<HSIZE)-1))==0) else $error("AHB-SVA-ALIGN");
  ap_error_complete:assert property(@(posedge HCLK) disable iff(!HRESETn) data_valid && HRESP && !HREADY |=> HRESP && HREADY) else $error("AHB-SVA-ERROR-TWO");
endmodule
