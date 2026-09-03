// =============================================================================
// File Name   : apb_ral.sv
// Description : UVM RAL 集成（REQ §12）：
//               - apb_reg_adapter（RAL-001..003：provides_responses=0——ADR-12
//                 req item 自携带响应；supports_byte_enable=APB4+ && enable_strb）
//               - apb_reg_predictor（RAL-004，P1：订阅 monitor.transaction_ap）
// VLNV        : aixsilicon:vip:apb:1.0.0
// =============================================================================

`ifndef APB_RAL__SV
`define APB_RAL__SV

// ---------------------------------------------------------------------------
// RAL adapter（P0）
// ---------------------------------------------------------------------------
class apb_reg_adapter extends uvm_reg_adapter;

  `uvm_object_utils(apb_reg_adapter)

  apb_config cfg;

  function new(string name = "apb_reg_adapter");
    super.new(name);
    // ADR-12：request item 自携带响应（driver item_done(req)），
    //         不 put_response 独立 rsp → provides_responses=0
    provides_responses = 0;
    // RAL-003 在 configure() 中按 config 赋值
  endfunction

  // env 侧调用：按 config 冻结 byte-enable 能力
  function void configure(apb_config c);
    cfg = c;
    supports_byte_enable = (c.protocol_version >= APB4) && c.enable_strb;
  endfunction

  // ---------------------------------------------------------------------------
  // reg2bus：uvm_reg_bus_op → apb_item
  // ---------------------------------------------------------------------------
  virtual function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
    apb_item it = apb_item::type_id::create("ral_item");
    it.direction = (rw.kind == UVM_WRITE) ? APB_WRITE : APB_READ;
    it.addr      = rw.addr;
    it.wdata     = rw.data;
    if (supports_byte_enable && rw.kind == UVM_WRITE)
      it.strb = rw.byte_en;   // UVM 1.2: uvm_reg_bus_op.byte_en
    else
      it.strb = '0;   // RUL-006
    return it;
  endfunction

  // ---------------------------------------------------------------------------
  // bus2reg：apb_item → uvm_reg_bus_op（req item 自携带响应——同一 item 回填）
  // ---------------------------------------------------------------------------
  virtual function void bus2reg(uvm_sequence_item bus_item, ref uvm_reg_bus_op rw);
    apb_item it;
    if (!$cast(it, bus_item)) begin
      `uvm_fatal(get_type_name(), "bus2reg: item is not an apb_item")
      return;
    end
    rw.kind   = (it.direction == APB_WRITE) ? UVM_WRITE : UVM_READ;
    rw.addr   = it.addr;
    rw.data   = (it.direction == APB_WRITE) ? it.wdata : it.rdata;
    rw.status = (it.status == APB_ABORTED) ? UVM_NOT_OK :
                (it.slverr ? UVM_NOT_OK : UVM_IS_OK);
  endfunction

endclass

// ---------------------------------------------------------------------------
// RAL predictor（P1，RAL-004）
// ---------------------------------------------------------------------------
class apb_reg_predictor extends uvm_component;

  `uvm_component_utils(apb_reg_predictor)

  uvm_reg_predictor #(apb_item) reg_predictor;
  apb_reg_adapter               adapter;
  uvm_analysis_export #(apb_item) analysis_export;
  apb_config                     cfg;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    reg_predictor = new("uvm_reg_predictor_child", this);
    adapter       = apb_reg_adapter::type_id::create("predictor_adapter");
    analysis_export = new("analysis_export", this);
  endfunction

  function void build_phase(uvm_phase phase_);
    super.build_phase(phase_);
    if (!uvm_config_db#(apb_config)::get(this, "", "config", cfg))
      `uvm_fatal(get_type_name(), "apb_config 'config' not set")
    adapter.configure(cfg);
    reg_predictor.adapter = adapter;
  endfunction

  function void connect_phase(uvm_phase phase_);
    super.connect_phase(phase_);
    analysis_export.connect(reg_predictor.bus_in);
  endfunction

  // 用户连接 reg model：
  //   predictor.reg_predictor.map = regmodel.default_map;

endclass

`endif // APB_RAL__SV
