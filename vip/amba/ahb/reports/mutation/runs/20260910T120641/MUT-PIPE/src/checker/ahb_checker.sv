// SPDX-License-Identifier: Apache-2.0
class ahb_cycle extends uvm_object;
  ahb_item address;
  logic reset_n,ready,readyout,sel;
  logic [1:0] trans,resp;
  logic exokay;
  ahb_data_t wdata,rdata;
  ahb_mask_t strb;
  logic [511:0] wu,ru;
  logic [15:0] bu;
  ahb_mask_t addrchk,wdchk,rdchk,strbchk,auchk,wuchk,ruchk,buchk;
  logic transchk,ctrl1,ctrl2,protchk,readychk,readyoutchk,respchk,selchk;
  `uvm_object_utils(ahb_cycle)
  function new(string name="ahb_cycle");super.new(name);address=ahb_item::type_id::create("address");endfunction
endclass
class ahb_checker extends uvm_object;
  ahb_config cfg;
  ahb_cycle previous;
  ahb_item pending,last_addr;
  ahb_violation violations[$];
  longint unsigned cycle_number=0;
  int burst_count=0;
  bit burst_open=0;
  string instance_name;
  int unsigned hits[string];
  `uvm_object_utils(ahb_checker)
  function new(string name="ahb_checker");super.new(name);endfunction
  function void flag(string id,string detail,ahb_item t=null,ahb_category_e category=PROTOCOL);
    ahb_violation v;
    if(cfg.rule_enable.exists(id) && !cfg.rule_enable[id]) return;
    v=ahb_violation::type_id::create("violation"); v.rule_id=id; v.detail=detail;
    v.instance_name=instance_name;v.cycle=cycle_number;v.category=category;
    v.phase_name=(t==pending)?"data":"address";
    if(t!=null) begin v.addr=t.addr;v.context_item=t.duplicate();end
    violations.push_back(v);hits[id]++;
  endfunction
  function void check_parity(ahb_cycle s);
    ahb_mask_t expected_bits;
    if(!cfg.parity) return;
    if(s.transchk !== (~^s.trans)) flag("AHB-CHECK-PAR-TRANS","HTRANSCHK",s.address);
    expected_bits=parity_bytes(s.address.addr,cfg.aw);
    if(s.addrchk !== expected_bits) flag("AHB-CHECK-PAR-ADDR","HADDRCHK",s.address);
    if(s.readychk !== ~s.ready) flag("AHB-CHECK-PAR-READY","HREADYCHK");
    if(cfg.subordinate_view && s.readyoutchk !== ~s.readyout) flag("AHB-CHECK-PAR-READYOUT","HREADYOUTCHK");
    if(cfg.subordinate_view && s.selchk !== ~s.sel) flag("AHB-CHECK-PAR-SEL","HSELCHK");
    if(s.trans!=0) begin
      if(s.ctrl1 !== (~^{(cfg.bw? s.address.burst:3'b0),s.address.lock,s.address.write,s.address.size,(cfg.secure?s.address.nonsecure:1'b0)})) flag("AHB-CHECK-PAR-CTRL1","HCTRLCHK1",s.address);
      if(cfg.exclusive && s.ctrl2 !== (~^{s.address.exclusive,s.address.master})) flag("AHB-CHECK-PAR-CTRL2","HCTRLCHK2",s.address);
      if(cfg.pw && s.protchk !== (~^s.address.prot)) flag("AHB-CHECK-PAR-PROT","HPROTCHK",s.address);
      if(cfg.au && s.auchk !== parity_bytes(s.address.auser,cfg.au)) flag("AHB-CHECK-PAR-AUSER","HAUSERCHK",s.address);
    end
    if(pending!=null) begin
      if(s.respchk !== (~^{s.resp[0],(cfg.exclusive?s.exokay:1'b0)})) flag("AHB-CHECK-PAR-RESP","HRESPCHK",pending);
      if(pending.write) begin
        if(s.wdchk !== parity_bytes(s.wdata,cfg.dw)) flag("AHB-CHECK-PAR-WDATA","HWDATACHK",pending);
        if(cfg.strobe && s.strbchk !== parity_bytes(s.strb,cfg.dw/8)) flag("AHB-CHECK-PAR-STRB","HWSTRBCHK",pending);
        if(cfg.du && s.wuchk !== parity_bytes(s.wu,cfg.du)) flag("AHB-CHECK-PAR-WUSER","HWUSERCHK",pending);
      end else if(s.ready) begin
        if(s.rdchk !== parity_bytes(s.rdata,cfg.dw)) flag("AHB-CHECK-PAR-RDATA","HRDATACHK",pending);
        if(cfg.du && s.ruchk !== parity_bytes(s.ru,cfg.du)) flag("AHB-CHECK-PAR-RUSER","HRUSERCHK",pending);
      end
      if(s.ready && cfg.ru && s.buchk !== parity_bytes(s.bu,cfg.ru)) flag("AHB-CHECK-PAR-BUSER","HBUSERCHK",pending);
    end
  endfunction
  function void sample(ahb_cycle s);
    bit prev_wait;
    cycle_number++;
    violations.delete();
    if(s.reset_n!==1) begin pending=null;last_addr=null;previous=null;burst_open=0;burst_count=0;return;end
    check_parity(s);
    if($isunknown({s.ready,s.trans,s.sel})) flag("AHB-CHECK-CONTROL-X","unknown valid control",s.address);
    prev_wait=(previous!=null && previous.ready===0 && previous.resp==0 && s.resp==0);
    if(prev_wait) begin
      if(previous.trans[1] && ({s.trans,s.address.addr,s.address.write,s.address.size,s.address.burst,s.address.prot,s.address.lock,s.address.nonsecure,s.address.exclusive,s.address.master} !== {previous.trans,previous.address.addr,previous.address.write,previous.address.size,previous.address.burst,previous.address.prot,previous.address.lock,previous.address.nonsecure,previous.address.exclusive,previous.address.master})) flag("AHB-CHECK-HOLD-ADDR","active waited address changed",s.address);
      if(previous.trans==1 && previous.address.burst!=1 && (s.trans!=1 && s.trans!=3)) flag("AHB-CHECK-BUSY","fixed burst BUSY changed to illegal type",s.address);
      if(previous.trans==1 && previous.address.burst!=1 && s.address.addr!==previous.address.addr) flag("AHB-CHECK-HOLD-ADDR","fixed BUSY address changed",s.address);
      if(cfg.au && previous.trans!=0 && s.address.auser!==previous.address.auser) flag("AHB-CHECK-HOLD-AUSER","HAUSER changed during wait",s.address);
      if(pending!=null && pending.write) begin
        ahb_mask_t mask;mask=active_mask(pending.addr,pending.size,cfg.dw/8,cfg.endian);
        for(int i=0;i<cfg.dw/8;i++) if(mask[i] && s.wdata[i*8+:8]!==previous.wdata[i*8+:8]) begin flag("AHB-CHECK-HOLD-WDATA","active write lane changed",pending);break;end
        if(cfg.strobe && (s.strb & mask)!==(previous.strb & mask)) flag("AHB-CHECK-HOLD-STRB","active strobe changed",pending);
        if(cfg.du && s.wu!==previous.wu) flag("AHB-CHECK-HOLD-WUSER","HWUSER changed",pending);
      end
    end
    if(cfg.profile!=AHB_CLASSIC && s.resp[1]) flag("AHB-CHECK-RESP-CODE","classic response on Lite/AHB5",pending);
    if(pending!=null) begin
      if($isunknown(s.resp)) flag("AHB-CHECK-RESP-X","unknown response",pending);
      if(previous!=null && previous.resp!=0 && previous.ready===0 && (s.ready!==1 || s.resp!==previous.resp)) flag("AHB-CHECK-ERROR-TWO","non-OKAY first cycle not followed by completion",pending);
      if(s.resp!=0 && s.ready===1 && !(previous!=null && previous.ready===0 && previous.resp===s.resp)) flag("AHB-CHECK-ERROR-TWO","missing first non-OKAY cycle",pending);
      if(cfg.exclusive && s.exokay===1 && (!s.ready || s.resp!=0 || !pending.exclusive)) flag("AHB-CHECK-EXOKAY","invalid HEXOKAY window",pending);
      if(s.ready && s.resp==0) begin
        ahb_mask_t mask; mask=active_mask(pending.addr,pending.size,cfg.dw/8,cfg.endian);
        if(pending.write && cfg.strobe) mask &= s.strb;
        for(int i=0;i<cfg.dw/8;i++) if(mask[i] && $isunknown(pending.write?s.wdata[i*8+:8]:s.rdata[i*8+:8])) begin flag("AHB-CHECK-DATA-X","unknown active data",pending);break;end
      end
      if(!s.ready && cfg.watchdog_cycles && cycle_number-pending.accepted_cycle>=cfg.watchdog_cycles) flag("AHB-CHECK-WATCHDOG","environment cycle watchdog",pending,ENV_POLICY);
    end else if(s.resp!=0) flag("AHB-CHECK-RESP-PHASE","response without data phase");
    if(cfg.exclusive && s.address.exclusive && s.trans==2 && pending!=null && pending.exclusive && pending.master==s.address.master) flag("AHB-CHECK-EX-OVERLAP","same identity exclusive phases overlap",s.address);
    if(s.ready===1) begin
      if(pending!=null && s.resp!=0 && s.trans!=3) burst_open=0;
      pending=null;
      if(s.sel===1 || !cfg.subordinate_view) begin
        if(s.trans[1]===1) begin
          if($isunknown({s.address.addr,s.address.size,s.address.write,s.address.burst,s.address.prot,s.address.lock,s.address.nonsecure,s.address.exclusive,s.address.master})) flag("AHB-CHECK-ADDR-X","unknown accepted address/control",s.address);
          if((1<<s.address.size)>cfg.dw/8) flag("AHB-CHECK-SIZE","size exceeds bus",s.address);
          if((s.address.addr & ((64'd1<<s.address.size)-1))!=0) flag("AHB-CHECK-ALIGN","unaligned address",s.address);
          if(cfg.capability_error(s.address)!="") flag("AHB-CHECK-CAPABILITY",cfg.capability_error(s.address),s.address,CAPABILITY);
          if(s.address.exclusive && (s.trans!=2 || !(s.address.burst inside {0,1}))) flag("AHB-CHECK-EX-FORM","exclusive must be single beat",s.address);
          if(s.trans==3) begin
            if(!burst_open || last_addr==null || last_addr.burst==0) flag("AHB-CHECK-SEQ","SEQ without open burst",s.address);
            else begin
              if(s.address.addr!==next_address(last_addr.addr,last_addr.size,last_addr.burst)) flag("AHB-CHECK-SEQ-ADDR","wrong SEQ address",s.address);
              if({s.address.size,s.address.burst,s.address.write,s.address.prot,s.address.nonsecure,s.address.lock}!=={last_addr.size,last_addr.burst,last_addr.write,last_addr.prot,last_addr.nonsecure,last_addr.lock}) flag("AHB-CHECK-BURST-ATTR","burst attributes changed",s.address);
              if(s.address.addr[63:10]!=last_addr.addr[63:10]) flag("AHB-CHECK-BOUNDARY","burst crosses 1KB",s.address);
            end
            burst_count++;
          end else begin burst_open=1;burst_count=1;end
          last_addr=s.address.duplicate();
          if(burst_length(s.address.burst)>0 && burst_count>=burst_length(s.address.burst)) burst_open=0;
          pending=s.address.duplicate();pending.accepted_cycle=cycle_number;
        end else if(s.trans==0) burst_open=0;
        else if(s.trans==1 && !burst_open) flag("AHB-CHECK-BUSY","BUSY outside burst",s.address);
      end
    end
    previous=s;
  endfunction
endclass
