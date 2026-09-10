// SPDX-License-Identifier: Apache-2.0
`uvm_analysis_imp_decl(_upstream)
`uvm_analysis_imp_decl(_downstream)
class ahb_translation_policy extends uvm_object;
  ahb_addr_t source_base=0,target_base=0;
  int source_bytes=4,target_bytes=4,error_fanout=1;
  ahb_endian_e source_endian=LITTLE_ENDIAN,target_endian=LITTLE_ENDIAN;
  bit compare_prot=1,compare_security=1,compare_user=0;
  `uvm_object_utils(ahb_translation_policy)
  function new(string name="ahb_translation_policy");super.new(name);endfunction
  virtual function ahb_addr_t map_address(ahb_addr_t addr);return addr-source_base+target_base;endfunction
  virtual function bit[6:0] map_prot(bit[6:0] prot);return prot;endfunction
  virtual function bit map_security(bit nonsecure);return nonsecure;endfunction
  virtual function logic[127:0] map_request_user(logic[127:0] user_value);return user_value;endfunction
endclass
class ahb_bridge_scoreboard extends uvm_component;
  `uvm_component_utils(ahb_bridge_scoreboard)
  typedef struct {ahb_addr_t addr;logic[7:0] data;bit write;ahb_status_e status;logic[6:0] prot;logic nonsecure;logic[127:0] auser;} byte_event_t;
  uvm_analysis_imp_upstream#(ahb_item,ahb_bridge_scoreboard) upstream;
  uvm_analysis_imp_downstream#(ahb_item,ahb_bridge_scoreboard) downstream;
  ahb_translation_policy policy;
  byte_event_t expected[$],observed[$];
  int queue_limit=4096;
  longint unsigned matches=0,mismatches=0;
  function new(string name,uvm_component parent);super.new(name,parent);upstream=new("upstream",this);downstream=new("downstream",this);endfunction
  function void build_phase(uvm_phase phase);super.build_phase(phase);if(!uvm_config_db#(ahb_translation_policy)::get(this,"","policy",policy)) policy=ahb_translation_policy::type_id::create("policy");endfunction
  function void append(ahb_item t,bit is_upstream);
    int width;ahb_endian_e endian;
    if(t.lifecycle!=COMPLETED) return;
    width=is_upstream?policy.source_bytes:policy.target_bytes;endian=is_upstream?policy.source_endian:policy.target_endian;
    if(t.status!=OKAY) begin
      byte_event_t e;e.addr=is_upstream?policy.map_address(t.addr):t.addr;e.status=t.status;e.write=t.write;
      repeat(is_upstream?policy.error_fanout:1) if(is_upstream) expected.push_back(e);else observed.push_back(e);
    end else begin
      for(int i=0;i<(1<<t.size);i++) begin
        int lane_index;byte_event_t e;lane_index=byte_lane(t.addr+i,width,endian);
        if(!t.valid_mask[lane_index]) continue;
        e.addr=is_upstream?policy.map_address(t.addr+i):t.addr+i;e.data=t.data[lane_index*8+:8];e.write=t.write;e.status=t.status;
        e.prot=is_upstream?policy.map_prot(t.prot):t.prot;e.nonsecure=is_upstream?policy.map_security(t.nonsecure):t.nonsecure;
        e.auser=is_upstream?policy.map_request_user(t.auser):t.auser;
        if(is_upstream) expected.push_back(e);else observed.push_back(e);
      end
    end
    while(expected.size() && observed.size()) begin
      byte_event_t a,b;bit equal;a=expected.pop_front();b=observed.pop_front();
      equal=a.addr===b.addr && a.write===b.write && a.status==b.status;
      if(a.status==OKAY && b.status==OKAY) equal &= !$isunknown({a.data,b.data}) && a.data===b.data && (!policy.compare_prot || a.prot===b.prot) && (!policy.compare_security || a.nonsecure===b.nonsecure) && (!policy.compare_user || a.auser===b.auser);
      if(equal) matches++;else begin mismatches++;`uvm_error("AHB-BRIDGE-MISMATCH",$sformatf("expected addr=%h data=%h status=%s observed addr=%h data=%h status=%s",a.addr,a.data,a.status.name(),b.addr,b.data,b.status.name())) end
    end
    if(expected.size()>queue_limit || observed.size()>queue_limit) `uvm_fatal("AHB-BRIDGE-WATCHDOG","unmatched observation queue limit")
  endfunction
  function void write_upstream(ahb_item t);append(t,1);endfunction
  function void write_downstream(ahb_item t);append(t,0);endfunction
  function void check_phase(uvm_phase phase);super.check_phase(phase);if(expected.size() || observed.size()) `uvm_error("AHB-BRIDGE-INCOMPLETE",$sformatf("lost/duplicated bytes: expected=%0d observed=%0d",expected.size(),observed.size())) endfunction
endclass
