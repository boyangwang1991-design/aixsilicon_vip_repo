// SPDX-License-Identifier: Apache-2.0
class ahb_memory extends uvm_object;
  typedef struct {ahb_addr_t addr;bit[2:0] size,burst;bit[6:0] prot;bit nonsecure;longint unsigned stamp;} reservation_t;
  logic [7:0] bytes[bit[64:0]];
  bit initialized[bit[64:0]];
  reservation_t reservations[int unsigned];
  ahb_init_e init_policy=INIT_X;
  logic [7:0] constant_value=0;
  int unsigned seed=1,reservation_bytes=128,reservation_capacity=256;
  bit separate_security=0;
  longint unsigned order=0,writes=0,bytes_written=0;
  `uvm_object_utils(ahb_memory)
  function new(string name="ahb_memory");super.new(name);endfunction
  function bit[64:0] key(ahb_addr_t addr,bit ns);return {separate_security?ns:1'b0,addr};endfunction
  virtual function logic[7:0] peek(ahb_addr_t addr,bit ns=0);
    bit[64:0] k;bit[63:0] hash_value;k=key(addr,ns);
    if(initialized.exists(k) && initialized[k]) return bytes[k];
    case(init_policy)
      INIT_ZERO:return 0;
      INIT_CONSTANT:return constant_value;
      INIT_ADDRESS:return addr[7:0];
      INIT_RANDOM:begin hash_value=addr ^ (64'h9e3779b97f4a7c15*seed);hash_value=(hash_value^(hash_value>>30))*64'hbf58476d1ce4e5b9;hash_value=(hash_value^(hash_value>>27))*64'h94d049bb133111eb;return hash_value^(hash_value>>31);end
      default:return 'x;
    endcase
  endfunction
  function bit valid(ahb_addr_t addr,bit ns=0);bit[64:0] k;k=key(addr,ns);return initialized.exists(k) && initialized[k];endfunction
  function void invalidate(ahb_addr_t addr,int count=1,bit ns=0);
    int unsigned remove_ids[$];
    foreach(reservations[id]) begin
      ahb_addr_t lo,hi;lo=reservations[id].addr & ~(64'(reservation_bytes)-1);hi=lo+reservation_bytes-1;
      if((!separate_security || reservations[id].nonsecure==ns) && addr<=hi && addr+count-1>=lo) remove_ids.push_back(id);
    end
    // mutation: omit invalidation
  endfunction
  virtual function void poke(ahb_addr_t addr,logic[7:0] value,bit ns=0);
    invalidate(addr,1,ns);bytes[key(addr,ns)]=value;initialized[key(addr,ns)]=1;
  endfunction
  function void reserve(ahb_item t,int unsigned identity);
    reservation_t r;
    if(reservation_bytes==0 || (reservation_bytes&(reservation_bytes-1)) || reservation_capacity==0) `uvm_fatal("AHB-RESERVATION","invalid granule/capacity")
    if(!reservations.exists(identity) && reservations.num()>=reservation_capacity) begin
      int unsigned oldest;longint unsigned age;age='1;oldest=0;
      foreach(reservations[id]) if(reservations[id].stamp<age) begin age=reservations[id].stamp;oldest=id;end
      reservations.delete(oldest);
    end
    r.addr=t.addr;r.size=t.size;r.burst=t.burst;r.prot=t.prot;r.nonsecure=t.nonsecure;r.stamp=order++;
    reservations[identity]=r;
  endfunction
  function bit exclusive_match(ahb_item t,int unsigned identity);
    if(!reservations.exists(identity)) return 0;
    return reservations[identity].addr==t.addr && reservations[identity].size==t.size && reservations[identity].burst==t.burst && reservations[identity].prot==t.prot && reservations[identity].nonsecure==t.nonsecure;
  endfunction
  virtual function ahb_data_t read_bus(ahb_item t,int bus_bytes,ahb_endian_e endian);
    ahb_data_t data;data='x;
    for(int i=0;i<(1<<t.size);i++) data[byte_lane(t.addr+i,bus_bytes,endian)*8+:8]=peek(t.addr+i,t.nonsecure);
    return data;
  endfunction
  virtual function void commit(ahb_item t,int bus_bytes,ahb_endian_e endian,int unsigned identity=0);
    ahb_mask_t mask;
    if(t.status!=OKAY) return;
    if(t.exclusive && !t.write) begin reserve(t,identity);return;end
    if(!t.write) return;
    if(t.exclusive && !exclusive_match(t,identity)) return;
    mask=active_mask(t.addr,t.size,bus_bytes,endian)&t.strobe;
    writes++;
    for(int i=0;i<(1<<t.size);i++) begin
      int lane_index;lane_index=byte_lane(t.addr+i,bus_bytes,endian);
      if(mask[lane_index]) begin poke(t.addr+i,t.data[lane_index*8+:8],t.nonsecure);bytes_written++;end
    end
    if(t.exclusive) reservations.delete(identity);
  endfunction
  virtual function void reset(bit preserve=1);reservations.delete();if(!preserve) begin bytes.delete();initialized.delete();end endfunction
  function void load(string path,ahb_addr_t base=0,bit ns=0);
    int fd,code;logic[7:0] value;string line;
    fd=$fopen(path,"r");if(!fd) `uvm_fatal("AHB-LOAD",path)
    while($fgets(line,fd)) begin code=$sscanf(line,"%h",value);if(code==1) begin poke(base,value,ns);base++;end end
    $fclose(fd);
  endfunction
  function void dump(string path,ahb_addr_t base,int count,bit ns=0);
    int fd;fd=$fopen(path,"w");if(!fd) `uvm_fatal("AHB-DUMP",path)
    for(int i=0;i<count;i++) $fdisplay(fd,"%02h",peek(base+i,ns));$fclose(fd);
  endfunction
endclass
class ahb_response_policy extends uvm_object;
  ahb_config cfg;
  int scripted_waits[$];
  bit [1:0] scripted_responses[$];
  `uvm_object_utils(ahb_response_policy)
  function new(string name="ahb_response_policy");super.new(name);endfunction
  virtual function void select_response(ahb_item t,output int waits,output bit[1:0] response);
    waits=scripted_waits.size()?scripted_waits.pop_front():$urandom_range(cfg.max_wait,cfg.min_wait);
    response=scripted_responses.size()?scripted_responses.pop_front():((cfg.error_enable && t.addr>=cfg.error_start && t.addr<=cfg.error_end)?1:0);
    if(cfg.capability_error(t)!="") response=1;
  endfunction
endclass
