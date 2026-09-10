// SPDX-License-Identifier: Apache-2.0
class ahb_reg_adapter extends uvm_reg_adapter;
  `uvm_object_utils(ahb_reg_adapter)
  ahb_config cfg;
  function new(string name="ahb_reg_adapter");super.new(name);provides_responses=1;supports_byte_enable=1;endfunction
  function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
    ahb_item t;int count;t=ahb_item::type_id::create("ral");
    if(cfg==null) `uvm_fatal("AHB-RAL","cfg missing")
    count=(rw.n_bits+7)/8;
    if(count==0 || (count&(count-1)) || count>cfg.dw/8) `uvm_fatal("AHB-RAL","unsupported transfer width")
    t.addr=rw.addr;t.size=3'($clog2(count));t.write=rw.kind==UVM_WRITE;t.strobe=0;t.data=0;
    for(int i=0;i<count;i++) begin int lane_index;lane_index=byte_lane(t.addr+i,cfg.dw/8,cfg.endian);t.data[lane_index*8+:8]=rw.data[i*8+:8];t.strobe[lane_index]=rw.byte_en[i];end
    if(cfg.request_error(t)!="") `uvm_fatal("AHB-RAL",cfg.request_error(t))
    return t;
  endfunction
  function void bus2reg(uvm_sequence_item bus_item,ref uvm_reg_bus_op rw);
    ahb_item t;if(!$cast(t,bus_item)) `uvm_fatal("AHB-RAL","wrong item")
    rw.addr=t.addr;rw.kind=t.write?UVM_WRITE:UVM_READ;rw.n_bits=(1<<t.size)*8;rw.data=0;rw.byte_en=0;
    for(int i=0;i<(1<<t.size) && i<$bits(rw.data)/8;i++) begin int lane_index;lane_index=byte_lane(t.addr+i,cfg.dw/8,cfg.endian);rw.data[i*8+:8]=t.data[lane_index*8+:8];rw.byte_en[i]=t.valid_mask[lane_index];end
    rw.status=(t.status==OKAY && t.lifecycle==COMPLETED)?UVM_IS_OK:UVM_NOT_OK;
  endfunction
endclass
class ahb_reg_predictor extends uvm_reg_predictor#(ahb_item);
  `uvm_component_utils(ahb_reg_predictor)
  function new(string name,uvm_component parent);super.new(name,parent);endfunction
  virtual function void write(ahb_item tr);if(tr.status==OKAY && tr.lifecycle==COMPLETED) super.write(tr);endfunction
endclass
