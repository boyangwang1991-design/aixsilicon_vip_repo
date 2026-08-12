// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 AIXSILICON
//
// apb_config.sv — APB 配置对象（配置必须通过 config object 传递）。
`ifndef APB_CONFIG_SV
`define APB_CONFIG_SV

package apb_pkg;

  import uvm_pkg::*;
  import vip_common_pkg::*;
  `include "uvm_macros.svh"

  class apb_config extends vip_common_config;
    `uvm_object_utils(apb_config)

    rand bit [31:0]            base_addr = 32'h0;
    rand int unsigned          addr_width = 12;
    rand int unsigned          data_width = 32;
    rand int unsigned          min_wait = 0;
    rand int unsigned          max_wait = 4;
    bit                        check_enabled = 1'b1;
    bit                        coverage_enabled = 1'b1;
    bit                        error_response_allowed = 1'b1;
    time                       apb_timeout = 1_000_000;

    function new(string name = "apb_config");
      super.new(name);
    endfunction

    virtual function string convert2string();
      return $sformatf("%s base=0x%08x dw=%0d aw=%0d", super.convert2string(),
                       base_addr, data_width, addr_width);
    endfunction
  endclass : apb_config

endpackage : apb_pkg

`endif
