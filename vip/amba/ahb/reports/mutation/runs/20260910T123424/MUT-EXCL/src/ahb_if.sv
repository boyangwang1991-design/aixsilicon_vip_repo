// SPDX-License-Identifier: Apache-2.0
interface ahb_if #(int AW=32, DW=32, BW=3, PW=4, MW=0, AU=0, DU=0, RU=0,
                   int PROFILE=0, bit SECURE=0, EXCLUSIVE=0, STROBE=0, PARITY=0)
                  (input logic HCLK, HRESETn);
  timeunit 1ns; timeprecision 1ps;
  localparam int RW=(PROFILE==2)?2:1;
  wire logic [AW-1:0] HADDR;
  wire logic [1:0] HTRANS;
  wire logic HWRITE,HMASTLOCK,HSEL,HREADY,HREADYOUT;
  wire logic [2:0] HSIZE;
  wire logic [(BW>0?BW:1)-1:0] HBURST;
  wire logic [(PW>0?PW:1)-1:0] HPROT;
  wire logic [DW-1:0] HWDATA,HRDATA;
  wire logic [RW-1:0] HRESP;
  wire logic HNONSEC,HEXCL,HEXOKAY;
  wire logic [(MW>0?MW:1)-1:0] HMASTER;
  wire logic [DW/8-1:0] HWSTRB;
  wire logic [(AU>0?AU:1)-1:0] HAUSER;
  wire logic [(DU>0?DU:1)-1:0] HWUSER,HRUSER;
  wire logic [(RU>0?RU:1)-1:0] HBUSER;
  wire logic [15:0] HBUSREQ,HGRANT,HSPLIT;
  wire logic HLOCK;
  wire logic HTRANSCHK,HCTRLCHK1,HCTRLCHK2,HPROTCHK,HREADYCHK,HREADYOUTCHK,HRESPCHK,HSELCHK;
  wire logic [(AW+7)/8-1:0] HADDRCHK;
  wire logic [DW/8-1:0] HWDATACHK,HRDATACHK;
  wire logic [(DW+63)/64-1:0] HWSTRBCHK;
  wire logic [(AU>0?(AU+7)/8:1)-1:0] HAUSERCHK;
  wire logic [(DU>0?(DU+7)/8:1)-1:0] HWUSERCHK,HRUSERCHK;
  wire logic [(RU>0?(RU+7)/8:1)-1:0] HBUSERCHK;
  clocking sample_cb @(posedge HCLK);
    default input #1step;
    input HRESETn,HADDR,HTRANS,HWRITE,HSIZE,HBURST,HPROT,HMASTLOCK,HSEL;
    input HWDATA,HRDATA,HREADY,HREADYOUT,HRESP,HNONSEC,HEXCL,HEXOKAY,HMASTER;
    input HWSTRB,HAUSER,HWUSER,HRUSER,HBUSER,HBUSREQ,HGRANT,HSPLIT,HLOCK;
    input HTRANSCHK,HADDRCHK,HCTRLCHK1,HCTRLCHK2,HPROTCHK,HWSTRBCHK,HWDATACHK,HRDATACHK;
    input HREADYCHK,HREADYOUTCHK,HRESPCHK,HSELCHK,HAUSERCHK,HWUSERCHK,HRUSERCHK,HBUSERCHK;
  endclocking
  clocking manager_cb @(posedge HCLK);
    default input #1step output #0;
    input HRESETn,HREADY,HRESP,HRDATA,HEXOKAY,HRUSER,HBUSER,HGRANT,HSPLIT;
    output HADDR,HTRANS,HWRITE,HSIZE,HBURST,HPROT,HMASTLOCK,HWDATA;
    output HNONSEC,HEXCL,HMASTER,HWSTRB,HAUSER,HWUSER,HBUSREQ,HLOCK;
    output HTRANSCHK,HADDRCHK,HCTRLCHK1,HCTRLCHK2,HPROTCHK,HWSTRBCHK,HWDATACHK,HAUSERCHK,HWUSERCHK;
  endclocking
  clocking subordinate_cb @(posedge HCLK);
    default input #1step output #0;
    input HRESETn,HREADY,HADDR,HTRANS,HWRITE,HSIZE,HBURST,HPROT,HMASTLOCK,HSEL;
    input HWDATA,HNONSEC,HEXCL,HMASTER,HWSTRB,HAUSER,HWUSER;
    output HREADYOUT,HRESP,HRDATA,HEXOKAY,HRUSER,HBUSER,HSPLIT;
    output HRDATACHK,HREADYOUTCHK,HRESPCHK,HRUSERCHK,HBUSERCHK;
  endclocking
  modport manager(clocking manager_cb,input HCLK,HRESETn);
  modport subordinate(clocking subordinate_cb,input HCLK,HRESETn);
  modport passive(clocking sample_cb,input HCLK,HRESETn);
  initial begin
    if(AW<10 || AW>64 || !(DW inside {8,16,32,64,128,256,512,1024})) $fatal(1,"AHB structural width");
    if(!(BW inside {0,3}) || !(PW inside {0,4,7}) || MW<0 || MW>8 || AU<0 || AU>128 || DU<0 || DU>DW/2 || RU<0 || RU>16) $fatal(1,"AHB optional width");
    if(PROFILE!=1 && (SECURE || EXCLUSIVE || STROBE || PARITY || PW==7)) $fatal(1,"AHB profile/feature dependency");
  end
endinterface
