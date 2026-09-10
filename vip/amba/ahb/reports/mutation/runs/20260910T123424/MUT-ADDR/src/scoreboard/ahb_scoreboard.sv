// SPDX-License-Identifier: Apache-2.0
class ahb_scoreboard extends uvm_subscriber#(ahb_item);
  `uvm_component_utils(ahb_scoreboard)
  ahb_memory reference_memory;
  ahb_config cfg;
  function new(string name,uvm_component parent);super.new(name,parent);endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);reference_memory=ahb_memory::type_id::create("reference_memory");
    if(!uvm_config_db#(ahb_config)::get(this,"","cfg",cfg)) `uvm_fatal("AHB-CONFIG","scoreboard cfg")
  endfunction
  function void write(ahb_item t);
    if(t.status!=OKAY || t.lifecycle!=COMPLETED) return;
    if(t.write) begin
      for(int i=0;i<(1<<t.size);i++) begin int lane_index;lane_index=byte_lane(t.addr+i,cfg.dw/8,cfg.endian);if(t.valid_mask[lane_index]) reference_memory.poke(t.addr+i,t.data[lane_index*8+:8],t.nonsecure);end
    end else begin
      for(int i=0;i<(1<<t.size);i++) begin
        int lane_index;lane_index=byte_lane(t.addr+i,cfg.dw/8,cfg.endian);
        if(reference_memory.valid(t.addr+i,t.nonsecure) && t.data[lane_index*8+:8] !== reference_memory.peek(t.addr+i,t.nonsecure)) `uvm_error("AHB-DATA-MISMATCH",t.convert2string())
      end
    end
  endfunction
endclass
