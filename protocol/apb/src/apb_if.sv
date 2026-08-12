// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 AIXSILICON
//
// apb_if.sv — APB 接口契约（Interface Layer）。
// 提供信号、clocking block、modport 与事务结构体。
`ifndef APB_IF_SV
`define APB_IF_SV

interface apb_if #(parameter int DATA_WIDTH = 32,
                   parameter int ADDR_WIDTH = 12) (input logic pclk,
                                                   input logic presetn);

  logic                        psel;
  logic                        penable;
  logic [ADDR_WIDTH-1:0]       paddr;
  logic                        pwrite;
  logic [DATA_WIDTH-1:0]       pwdata;
  logic [DATA_WIDTH-1:0]       prdata;
  logic                        pready;
  logic                        pslverr;

  // 传输方向
  typedef enum bit { READ = 1'b0, WRITE = 1'b1 } apb_dir_e;

  // 事务结构体（Transaction Layer 的轻量载体，UVM item 见 apb_item.sv）
  typedef struct {
    apb_dir_e                 dir;
    logic [ADDR_WIDTH-1:0]    addr;
    logic [DATA_WIDTH-1:0]    data;
    bit                       wait;    // 该传输是否经历 wait
    bit                       error;   // slave 返回 error
  } apb_transfer_t;

  clocking master_cb @(posedge pclk);
    output psel, penable, paddr, pwrite, pwdata;
    input  prdata, pready, pslverr;
  endclocking

  clocking slave_cb @(posedge pclk);
    input  psel, penable, paddr, pwrite, pwdata;
    output prdata, pready, pslverr;
  endclocking

  clocking monitor_cb @(posedge pclk);
    input psel, penable, paddr, pwrite, pwdata, prdata, pready, pslverr;
  endclocking

  modport master_mp (clocking master_cb, input pclk, input presetn);
  modport slave_mp  (clocking slave_cb,  input pclk, input presetn);
  modport monitor_mp(clocking monitor_cb, input pclk, input presetn);

endinterface : apb_if

`endif
