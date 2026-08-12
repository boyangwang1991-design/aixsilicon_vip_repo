// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 AIXSILICON
//
// apb_monitor.sv — APB 采样 Monitor（PASSIVE）。
// 采样总线并广播到统一 analysis port：transaction_ap / error_ap / performance_ap。
// 独立于 driver 实现解析逻辑，避免与 driver 共享同一错误假设。
`ifndef APB_MONITOR_SV
`define APB_MONITOR_SV

package apb_pkg;

  class apb_monitor extends vip_common_monitor #(apb_item);
    `uvm_component_utils(apb_monitor)

    virtual apb_if vif;
    apb_config cfg;

    function new(string name = "apb_monitor", uvm_component parent = null);
      super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db#(virtual apb_if)::get(this, "", "vif", vif))
        `uvm_fatal("NOVIF", "apb_monitor 未获取 vif")
      if (!uvm_config_db#(apb_config)::get(this, "", "cfg", cfg))
        `uvm_fatal("NOCFG", "apb_monitor 未获取 cfg")
    endfunction

    virtual protected task sample_protocol();
      apb_item t;
      bit in_access;
      forever begin
        @(vif.monitor_cb);
        // 检测 PSEL && PENABLE（ACCESS 阶段）
        if (vif.monitor_cb.psel === 1'b1 && vif.monitor_cb.penable === 1'b1) begin
          in_access = 1'b1;
          t = apb_item::type_id::create("t");
          t.dir  = (vif.monitor_cb.pwrite) ? APB_WRITE : APB_READ;
          t.addr = vif.monitor_cb.paddr;
          t.data = (t.dir == APB_WRITE) ? vif.monitor_cb.pwdata : vif.monitor_cb.prdata;
          t.wait_cycles = 0;
          t.error_en    = vif.monitor_cb.pslverr;
        end else if (in_access) begin
          // ACCESS 结束
          transaction_ap.write(t);
          if (t.error_en)
            error_ap.write(t);
          in_access = 1'b0;
        end
      end
    endtask
  endclass : apb_monitor

endpackage : apb_pkg

`endif
