// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 AIXSILICON
//
// apb_master_driver.sv — APB Master 驱动（ACTIVE_MASTER）。
// 实现 APB 写/读时序：IDLE -> SETUP(PSEL) -> ACCESS(PENABLE)，等待 PREADY。
`ifndef APB_MASTER_DRIVER_SV
`define APB_MASTER_DRIVER_SV

package apb_pkg;

  class apb_master_driver extends uvm_driver #(apb_item);
    `uvm_component_utils(apb_master_driver)

    virtual apb_if vif;
    apb_config cfg;

    function new(string name = "apb_master_driver", uvm_component parent = null);
      super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db#(virtual apb_if)::get(this, "", "vif", vif))
        `uvm_fatal("NOVIF", "apb_master_driver 未获取 vif")
      if (!uvm_config_db#(apb_config)::get(this, "", "cfg", cfg))
        `uvm_fatal("NOCFG", "apb_master_driver 未获取 cfg")
    endfunction

    virtual task run_phase(uvm_phase phase);
      vif.master_cb.psel    <= 1'b0;
      vif.master_cb.penable <= 1'b0;
      @(vif.master_cb);
      forever begin
        seq_item_port.get_next_item(req);
        drive_apb(req);
        seq_item_port.item_done();
      end
    endtask

    protected virtual task drive_apb(apb_item item);
      // IDLE -> SETUP
      @(vif.master_cb);
      vif.master_cb.paddr  <= item.addr;
      vif.master_cb.pwrite <= (item.dir == APB_WRITE);
      vif.master_cb.pwdata <= item.data;
      vif.master_cb.psel   <= 1'b1;
      vif.master_cb.penable<= 1'b0;

      // SETUP -> ACCESS
      @(vif.master_cb);
      vif.master_cb.penable <= 1'b1;

      // 等待 PREADY（支持随机 wait/backpressure）
      do begin
        @(vif.master_cb);
      end while (vif.master_cb.pready !== 1'b1);

      // 采样读数据
      if (item.dir == APB_READ) begin
        rsp = apb_item::type_id::create("rsp");
        rsp.copy(item);
        rsp.data = vif.master_cb.prdata;
        rsp.error = vif.master_cb.pslverr;
        seq_item_port.put_response(rsp);
      end

      // ACCESS -> IDLE
      vif.master_cb.penable <= 1'b0;
      vif.master_cb.psel    <= 1'b0;
    endtask
  endclass : apb_master_driver

endpackage : apb_pkg

`endif
