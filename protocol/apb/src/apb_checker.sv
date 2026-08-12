// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 AIXSILICON
//
// apb_checker.sv — APB 协议检查器（Checking Layer）。
// 检查信号时序与稳定性（不等同于数据结果检查）：
//   - PENABLE 不能先于 PSEL；
//   - PADDR/PWRITE/PWATA 在 setup 阶段稳定；
//   - X/Z 检测、timeout、重复 PSEL 等。
`ifndef APB_CHECKER_SV
`define APB_CHECKER_SV

package apb_pkg;

  class apb_checker extends uvm_subscriber #(apb_item);
    `uvm_component_utils(apb_checker)

    uvm_analysis_imp #(apb_item, apb_checker) analysis_export;
    uvm_analysis_imp #(apb_item, apb_checker) error_export;

    virtual apb_if vif;
    apb_config cfg;

    function new(string name = "apb_checker", uvm_component parent = null);
      super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      analysis_export = new("analysis_export", this);
      error_export    = new("error_export", this);
      if (!uvm_config_db#(virtual apb_if)::get(this, "", "vif", vif))
        `uvm_fatal("NOVIF", "apb_checker 未获取 vif")
    endfunction

    virtual function void write(apb_item t);
      check_transfer(t);
    endfunction

    protected virtual function void check_transfer(apb_item t);
      // 示例断言占位：真实检查由 apb_checker_assert 或 SVA 完成
      if (t.dir == APB_WRITE) begin
        `uvm_info("APBCHK", $sformatf("write addr=0x%08x data=0x%08x err=%b",
                                      t.addr, t.data, t.error_en), UVM_HIGH)
      end
    endfunction
  endclass : apb_checker

endpackage : apb_pkg

`endif
