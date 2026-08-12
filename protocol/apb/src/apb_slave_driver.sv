// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 AIXSILICON
//
// apb_slave_driver.sv — APB Slave 响应（ACTIVE_SLAVE / responder）。
// 响应读写，可插入 wait（PREADY=0）并返回 error（PSLVERR）。
`ifndef APB_SLAVE_DRIVER_SV
`define APB_SLAVE_DRIVER_SV

package apb_pkg;

  class apb_slave_driver extends uvm_driver #(apb_item);
    `uvm_component_utils(apb_slave_driver)

    virtual apb_if vif;
    apb_config cfg;

    function new(string name = "apb_slave_driver", uvm_component parent = null);
      super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db#(virtual apb_if)::get(this, "", "vif", vif))
        `uvm_fatal("NOVIF", "apb_slave_driver 未获取 vif")
      if (!uvm_config_db#(apb_config)::get(this, "", "cfg", cfg))
        `uvm_fatal("NOCFG", "apb_slave_driver 未获取 cfg")
    endfunction

    virtual task run_phase(uvm_phase phase);
      vif.slave_cb.pready  <= 1'b1;
      vif.slave_cb.pslverr <= 1'b0;
      vif.slave_cb.prdata  <= '0;
      forever begin
        // 等待 PSEL && PENABLE，进入 ACCESS
        do begin
          @(vif.slave_cb);
        end while (!(vif.slave_cb.psel === 1'b1 && vif.slave_cb.penable === 1'b1));

        // 从 seq_item_port 获取响应策略（wait / error），若未配置则默认立即响应
        if (seq_item_port.has_do_available()) begin
          seq_item_port.get_next_item(req);
          drive_response(req);
          seq_item_port.item_done();
        end else begin
          drive_default_response();
        end
      end
    endtask

    protected virtual task drive_response(apb_item item);
      repeat (item.wait_cycles) begin
        vif.slave_cb.pready <= 1'b0;
        @(vif.slave_cb);
      end
      vif.slave_cb.pready  <= 1'b1;
      vif.slave_cb.pslverr <= item.error_en;
      if (item.dir == APB_READ)
        vif.slave_cb.prdata <= item.data;
      @(vif.slave_cb);
      vif.slave_cb.pslverr <= 1'b0;
    endtask

    protected virtual task drive_default_response();
      vif.slave_cb.pready  <= 1'b1;
      vif.slave_cb.pslverr <= 1'b0;
      vif.slave_cb.prdata  <= '0;
      @(vif.slave_cb);
    endtask
  endclass : apb_slave_driver

endpackage : apb_pkg

`endif
