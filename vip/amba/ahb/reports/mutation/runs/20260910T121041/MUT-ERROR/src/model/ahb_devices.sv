// SPDX-License-Identifier: Apache-2.0
class ahb_region extends uvm_object;
  ahb_addr_t first=0,last='1;
  int priority_value=0;
  bit read_allowed=1,write_allowed=1,secure_allowed=1,nonsecure_allowed=1,privileged_only=0;
  `uvm_object_utils(ahb_region)
  function new(string name="ahb_region");super.new(name);endfunction
  function bit contains(ahb_item t);return t.addr>=first && t.addr<=last && ((64'd1<<t.size)-1)<=last-t.addr;endfunction
  function bit permitted(ahb_item t);return (t.write?write_allowed:read_allowed) && (t.nonsecure?nonsecure_allowed:secure_allowed) && (!privileged_only || t.prot[1]);endfunction
endclass
class ahb_region_policy extends ahb_response_policy;
  ahb_region regions[$];
  bit error_unmapped=1;
  `uvm_object_utils(ahb_region_policy)
  function new(string name="ahb_region_policy");super.new(name);endfunction
  function string validate_regions();
    foreach(regions[i]) begin
      if(regions[i].first>regions[i].last) return "reversed region";
      foreach(regions[j]) if(i<j && regions[i].first<=regions[j].last && regions[j].first<=regions[i].last && regions[i].priority_value==regions[j].priority_value) return "overlapping regions need distinct priorities";
    end
    return "";
  endfunction
  virtual function void select_response(ahb_item t,output int waits,output bit[1:0] response);
    ahb_region selected;selected=null;
    super.select_response(t,waits,response);
    if(validate_regions()!="") `uvm_fatal("AHB-REGION",validate_regions())
    foreach(regions[i]) if(regions[i].contains(t) && (selected==null || regions[i].priority_value>selected.priority_value)) selected=regions[i];
    if(selected==null) begin if(error_unmapped) response=1;end
    else if(!selected.permitted(t)) response=1;
  endfunction
endclass
class ahb_register_memory extends ahb_memory;
  ahb_addr_t first=0,last='1;
  bit read_only=0,write_only=0,read_clear=0,write_one_clear=0;
  `uvm_object_utils(ahb_register_memory)
  function new(string name="ahb_register_memory");super.new(name);endfunction
  virtual function ahb_data_t read_bus(ahb_item t,int bus_bytes,ahb_endian_e endian);
    if(write_only && t.addr>=first && t.addr<=last) return 0;
    return super.read_bus(t,bus_bytes,endian);
  endfunction
  virtual function void commit(ahb_item t,int bus_bytes,ahb_endian_e endian,int unsigned identity=0);
    ahb_item adjusted;
    if(t.status!=OKAY) return;
    if(t.addr<first || t.addr>last) begin super.commit(t,bus_bytes,endian,identity);return;end
    if(t.write && read_only) return;
    if(!t.write && read_clear) begin
      for(int i=0;i<(1<<t.size);i++) poke(t.addr+i,0,t.nonsecure);
      return;
    end
    adjusted=t.duplicate();
    if(t.write && write_one_clear) for(int i=0;i<(1<<t.size);i++) begin int lane_index;lane_index=byte_lane(t.addr+i,bus_bytes,endian);adjusted.data[lane_index*8+:8]=peek(t.addr+i,t.nonsecure)&~t.data[lane_index*8+:8];end
    super.commit(adjusted,bus_bytes,endian,identity);
  endfunction
endclass
class ahb_fifo_memory extends ahb_memory;
  ahb_addr_t window_addr=0;
  ahb_data_t fifo[$];
  int capacity=16;
  `uvm_object_utils(ahb_fifo_memory)
  function new(string name="ahb_fifo_memory");super.new(name);endfunction
  virtual function ahb_data_t read_bus(ahb_item t,int bus_bytes,ahb_endian_e endian);
    if(t.addr!=window_addr) return super.read_bus(t,bus_bytes,endian);
    return fifo.size()?fifo[0]:'x;
  endfunction
  virtual function void commit(ahb_item t,int bus_bytes,ahb_endian_e endian,int unsigned identity=0);
    if(t.addr!=window_addr) begin super.commit(t,bus_bytes,endian,identity);return;end
    if(t.status!=OKAY) return;
    if(t.exclusive) `uvm_fatal("AHB-FIFO","exclusive FIFO policy is undefined; use region rejection")
    if(t.write) begin if(fifo.size()>=capacity) `uvm_fatal("AHB-FIFO","overflow") else fifo.push_back(t.data);end
    else if(fifo.size()) begin ahb_data_t ignored;ignored=fifo.pop_front();end
  endfunction
  virtual function void reset(bit preserve=1);super.reset(preserve);if(!preserve) fifo.delete();endfunction
endclass
