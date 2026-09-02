// =============================================================================
// File Name   : axi4_ral_adapter.sv
// Description : UVM RAL adapter（REQ-VER-014 / REQ-API-007 / architecture §23）
//               - reg2bus：uvm_reg_bus_op → axi4_master_item（frontdoor 访问）
//               - bus2reg：axi4_master_item → uvm_reg_bus_op（B/R 响应镜像）
//               - provides_responses：bus2reg 后发布 response item
// VLNV        : aixsilicon:vip:axi4:1.0.0
// =============================================================================

`ifndef AXI4_RAL_ADAPTER__SV
`define AXI4_RAL_ADAPTER__SV

import uvm_pkg::*;
`include "uvm_macros.svh"

class axi4_ral_adapter extends uvm_reg_adapter;

  `uvm_object_utils(axi4_ral_adapter)

  function new(string name = "axi4_ral_adapter");
    super.new(name);
    supports_byte_enable = 1;   // WSTRB 感知（部分访问）
    provides_responses   = 1;   // driver 返回带响应的同一 item
    parent_sequence      = null;
  endfunction

  // -------------------------------------------------------------------------
  // reg2bus：寄存器操作 → AXI4 事务
  // -------------------------------------------------------------------------
  virtual function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
    axi4_master_item item = axi4_master_item::type_id::create("ral_item");
    item.access_type  = (rw.kind == UVM_READ) ? AXI4_READ_ACCESS : AXI4_WRITE_ACCESS;
    item.address      = rw.addr;
    item.burst_length = 1;
    item.burst_size   = 4;                       // 与 data_width/8 对齐（32b 缺省）
    item.burst_type   = AXI4_INCREMENTING_BURST;
    item.data         = new[1];
    item.strobe       = new[1];
    if (rw.kind == UVM_WRITE) begin
      item.data[0]   = rw.data;
      // UVM 1.2 uvm_reg_bus_op 无 byte_enable 成员：full strobe
      // （部分寄存器访问经 uvm_reg_field 映射，adapter 侧不拆分）
      item.strobe[0] = '1;
    end
    return item;
  endfunction

  // -------------------------------------------------------------------------
  // bus2reg：AXI4 事务（含响应） → 寄存器操作
  // -------------------------------------------------------------------------
  virtual function void bus2reg(uvm_sequence_item bus_item, ref uvm_reg_bus_op rw);
    axi4_master_item item;
    if (!$cast(item, bus_item)) begin
      `uvm_fatal(get_type_name(), "bus2reg: item 不是 axi4_master_item")
      return;
    end
    rw.kind   = item.is_read() ? UVM_READ : UVM_WRITE;
    rw.addr   = item.address;
    rw.status = UVM_IS_OK;
    if (item.is_read() && (item.data.size() > 0)) begin
      rw.data = item.data[0];
    end
    else if (item.data.size() > 0) begin
      rw.data = item.data[0];
    end
    // 响应映射：非 OKAY/EXOKAY → UVM_NOT_OK
    if (item.has_response && (item.response.size() > 0)) begin
      if (!(item.response[0] inside {AXI4_OKAY, AXI4_EXOKAY})) begin
        rw.status = UVM_NOT_OK;
      end
    end
  endfunction

endclass : axi4_ral_adapter


// =============================================================================
// axi4_ral_predictor：前门预测器（订阅 monitor 事务 → 更新寄存器镜像）
// =============================================================================
class axi4_ral_predictor extends uvm_component;

  uvm_analysis_imp_axi4_monitor #(axi4_item, axi4_ral_predictor) monitor_imp;

  uvm_reg_block  reg_model;

  `uvm_component_utils(axi4_ral_predictor)

  function new(string name = "axi4_ral_predictor", uvm_component parent = null);
    super.new(name, parent);
    monitor_imp = new("monitor_imp", this);
  endfunction

  // 单拍写/读事务 → 寄存器镜像更新（uvm_reg::predict_frontdoor 简化路径）
  virtual function void write_axi4_monitor(axi4_item item);
    uvm_reg rg;
    uvm_status_e status;
    if ((reg_model == null) || (item.burst_length != 1)) begin
      return;  // 只处理单拍寄存器式访问
    end
    rg = reg_model.get_default_map().get_reg_by_offset(item.address);
    if (rg == null) begin
      return;
    end
    if (item.is_write()) begin
      if (item.data.size() > 0) begin
        void'(rg.predict(item.data[0], -1, .kind(UVM_PREDICT_WRITE), .path(UVM_FRONTDOOR)));
      end
    end
    else begin
      if (item.data.size() > 0) begin
        void'(rg.predict(item.data[0], -1, .kind(UVM_PREDICT_READ), .path(UVM_FRONTDOOR)));
      end
    end
  endfunction

endclass : axi4_ral_predictor

`endif // AXI4_RAL_ADAPTER__SV
