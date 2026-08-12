// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 AIXSILICON
//
// apb_item.sv — APB 事务（Transaction Layer）。
`ifndef APB_ITEM_SV
`define APB_ITEM_SV

package apb_pkg;

  import uvm_pkg::*;
  import vip_common_pkg::*;
  `include "uvm_macros.svh"

  // APB 传输方向
  typedef enum bit { APB_READ = 1'b0, APB_WRITE = 1'b1 } apb_dir_e;

  class apb_item extends vip_common_transaction;
    `uvm_object_utils(apb_item)

    rand apb_dir_e             dir;
    rand bit [31:0]            addr;
    rand bit [31:0]            data;
    rand bit                   wait_en;      // 请求 slave 插入 wait
    rand bit                   error_en;     // 请求 slave 返回 error
    rand int unsigned          wait_cycles;  // 期望的 wait 拍数

    constraint c_addr_align { addr[1:0] == 2'b00; }
    constraint c_wait { wait_cycles inside {[1:4]}; }

    function new(string name = "apb_item");
      super.new(name);
    endfunction

    virtual function string convert2string();
      return $sformatf("%s addr=0x%08x data=0x%08x wait=%0d err=%b",
                       dir.name(), addr, data, wait_cycles, error_en);
    endfunction
  endclass : apb_item

endpackage : apb_pkg

`endif
