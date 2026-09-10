// SPDX-License-Identifier: Apache-2.0
class ahb_config extends uvm_object;
  ahb_profile_e profile=AHB_LITE;
  ahb_mode_e mode=ACTIVE_MASTER;
  ahb_endian_e endian=LITTLE_ENDIAN;
  string issue="C";
  int aw=32,dw=32,bw=3,pw=4,mw=0,au=0,du=0,ru=0;
  bit secure,exclusive,strobe,parity;
  bit enable_checker=1,enable_coverage=1,subordinate_view=1,trace=0;
  int unsigned classic_master_id=1,max_attempts=16,split_release_delay=4;
  bit preserve_memory=1,stop_on_error=1;
  int unsigned watchdog_cycles=100000,queue_depth=16,history_limit=32;
  int unsigned min_wait=0,max_wait=0;
  bit error_enable=0;
  ahb_addr_t error_start='1,error_end='1;
  bit allow_read=1,allow_write=1,single_only=0;
  bit [7:0] allowed_sizes='1;
  bit rule_enable[string];
  uvm_severity rule_severity[string];
  string waiver_reason[string];
  longint unsigned waiver_expiry[string];
  local bit frozen=0;
  local bit [511:0] frozen_shape;
  local string frozen_issue;
  `uvm_object_utils(ahb_config)
  function new(string name="ahb_config");super.new(name);endfunction
  function bit [511:0] structural_shape();
    return {profile,mode,endian,aw,dw,bw,pw,mw,au,du,ru,secure,exclusive,strobe,parity,queue_depth};
  endfunction
  function void freeze();
    if(!frozen) begin frozen_shape=structural_shape();frozen_issue=issue;frozen=1;end
  endfunction
  function bit structural_unchanged();
    return !frozen || (structural_shape()==frozen_shape && issue==frozen_issue);
  endfunction
  function void check_frozen();
    if(!structural_unchanged()) `uvm_fatal("AHB-CONFIG-FROZEN","structural configuration changed after build; create a new typed instance")
  endfunction
  function string validate();
    if(!structural_unchanged()) return "structural configuration is frozen";
    if(!(profile inside {AHB_LITE,AHB5,AHB_CLASSIC})) return "profile";
    if(!(issue inside {"C","B.b","A"})) return "issue";
    if(aw<10 || aw>64 || !(dw inside {8,16,32,64,128,256,512,1024})) return "aw/dw";
    if(!(bw inside {0,3}) || !(pw inside {0,4,7}) || mw<0 || mw>8 || au<0 || au>128 || du<0 || du>dw/2 || ru<0 || ru>16) return "optional widths";
    if(profile!=AHB5 && (secure || exclusive || strobe || parity || pw==7)) return "profile/features";
    if(issue!="C" && (aw!=32 || bw!=3 || strobe || parity || ru!=0)) return "legacy issue widths/features";
    if(profile==AHB_CLASSIC && issue!="A") return "classic requires Issue A";
    if(profile!=AHB_CLASSIC && issue=="A") return "Issue A binding is classic only in this candidate";
    if(classic_master_id>15 || max_attempts==0) return "classic policy";
    if(queue_depth<1 || queue_depth>1024 || min_wait>max_wait) return "policy limits";
    if(endian==WORD_BIG_ENDIAN && (issue=="C" || dw<32)) return "word-invariant endian compatibility";
    return "";
  endfunction
  function string capability_error(ahb_item t);
    if(t.write && !allow_write || !t.write && !allow_read) return "direction";
    if(single_only && t.burst!=0 || !allowed_sizes[t.size]) return "burst/size";
    return "";
  endfunction
  function string request_error(ahb_item t);
    if(t.raw) return "";
    if((1<<t.size)>dw/8 || (t.addr & ((64'd1<<t.size)-1))!=0) return "size/alignment";
    if(aw<64 && (t.addr>>aw)!=0) return "address width";
    if(!secure && t.nonsecure || !exclusive && t.exclusive) return "disabled extension";
    if(!strobe && ((t.strobe & active_mask(t.addr,t.size,dw/8,endian))!=active_mask(t.addr,t.size,dw/8,endian))) return "sparse write without strobe";
    if(t.exclusive && (!(t.burst inside {0,1}) || t.trans!=2)) return "exclusive form";
    if(au<128 && (t.auser>>au)!=0 || du<512 && (t.wuser>>du)!=0) return "USER width";
    return "";
  endfunction
endclass
