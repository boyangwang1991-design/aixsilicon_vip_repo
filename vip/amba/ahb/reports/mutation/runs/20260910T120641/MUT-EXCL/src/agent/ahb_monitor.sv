// SPDX-License-Identifier: Apache-2.0
class ahb_monitor #(int AW=32,DW=32,BW=3,PW=4,MW=0,AU=0,DU=0,RU=0,PROFILE=0, bit SECURE=0,EXCLUSIVE=0,STROBE=0,PARITY=0) extends uvm_monitor;
  `uvm_component_param_utils(ahb_monitor#(AW,DW,BW,PW,MW,AU,DU,RU,PROFILE,SECURE,EXCLUSIVE,STROBE,PARITY))
  virtual ahb_if#(AW,DW,BW,PW,MW,AU,DU,RU,PROFILE,SECURE,EXCLUSIVE,STROBE,PARITY) vif;
  ahb_config cfg;
  ahb_checker scb;
  ahb_item pending;
  ahb_burst aggregate;
  uvm_analysis_port#(ahb_item) transaction_ap,request_ap;
  uvm_analysis_port#(ahb_violation) error_ap;
  uvm_analysis_port#(ahb_cycle) cycle_ap;
  uvm_analysis_port#(ahb_burst) burst_ap;
  longint unsigned cycle_count=0;
  function new(string name,uvm_component parent);
    super.new(name,parent);
    transaction_ap=new("transaction_ap",this);request_ap=new("request_ap",this);
    error_ap=new("error_ap",this);cycle_ap=new("cycle_ap",this);burst_ap=new("burst_ap",this);
  endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(ahb_config)::get(this,"","cfg",cfg)) `uvm_fatal("AHB-CONFIG","cfg missing")
    if(!uvm_config_db#(virtual ahb_if#(AW,DW,BW,PW,MW,AU,DU,RU,PROFILE,SECURE,EXCLUSIVE,STROBE,PARITY))::get(this,"","vif",vif)) `uvm_fatal("AHB-VIF","vif missing")
    scb=ahb_checker::type_id::create("scb");scb.cfg=cfg;scb.instance_name=get_full_name();
  endfunction
  function ahb_cycle snapshot();
    ahb_cycle s; s=ahb_cycle::type_id::create("cycle");
    s.reset_n=vif.sample_cb.HRESETn;
    s.ready=vif.sample_cb.HREADY;
    s.readyout=vif.sample_cb.HREADYOUT;
    s.sel=vif.sample_cb.HSEL;
    s.trans=vif.sample_cb.HTRANS;
    s.resp=vif.sample_cb.HRESP;
    s.exokay=vif.sample_cb.HEXOKAY;
    s.wdata=vif.sample_cb.HWDATA;
    s.rdata=vif.sample_cb.HRDATA;
    s.strb=vif.sample_cb.HWSTRB;
    s.wu=vif.sample_cb.HWUSER;
    s.ru=vif.sample_cb.HRUSER;
    s.bu=vif.sample_cb.HBUSER;
    s.addrchk=vif.sample_cb.HADDRCHK;
    s.wdchk=vif.sample_cb.HWDATACHK;
    s.rdchk=vif.sample_cb.HRDATACHK;
    s.strbchk=vif.sample_cb.HWSTRBCHK;
    s.auchk=vif.sample_cb.HAUSERCHK;
    s.wuchk=vif.sample_cb.HWUSERCHK;
    s.ruchk=vif.sample_cb.HRUSERCHK;
    s.buchk=vif.sample_cb.HBUSERCHK;
    s.transchk=vif.sample_cb.HTRANSCHK;
    s.ctrl1=vif.sample_cb.HCTRLCHK1;
    s.ctrl2=vif.sample_cb.HCTRLCHK2;
    s.protchk=vif.sample_cb.HPROTCHK;
    s.readychk=vif.sample_cb.HREADYCHK;
    s.readyoutchk=vif.sample_cb.HREADYOUTCHK;
    s.respchk=vif.sample_cb.HRESPCHK;
    s.selchk=vif.sample_cb.HSELCHK;
    s.address.addr=vif.sample_cb.HADDR;
    s.address.write=vif.sample_cb.HWRITE;
    s.address.size=vif.sample_cb.HSIZE;
    s.address.lock=vif.sample_cb.HMASTLOCK;
    s.address.nonsecure=vif.sample_cb.HNONSEC;
    s.address.exclusive=vif.sample_cb.HEXCL;
    s.address.master=vif.sample_cb.HMASTER;
    s.address.auser=vif.sample_cb.HAUSER;
    s.address.burst=BW?vif.sample_cb.HBURST:3'b001;
    s.address.prot=PW?vif.sample_cb.HPROT:7'h03;
    s.address.trans=s.trans;
    if(!SECURE) s.address.nonsecure=0;
    if(!EXCLUSIVE) begin s.address.exclusive=0;s.exokay=0;end
    if(!MW) s.address.master=0;
    if(!AU) s.address.auser=0;
    if(!DU) begin s.wu=0;s.ru=0;end
    if(!RU) s.bu=0;
    if(!STROBE) s.strb='1;
    return s;
  endfunction
  function void flush_burst(string reason);
    if(aggregate!=null && aggregate.beats.size()) begin aggregate.termination=reason;burst_ap.write(aggregate);end
    aggregate=null;
  endfunction
  task run_phase(uvm_phase phase);
    forever begin
      ahb_cycle s;
      @(vif.sample_cb);cycle_count++;s=snapshot();cycle_ap.write(s);
      if(cfg.enable_checker) begin
        scb.sample(s);
        foreach(scb.violations[i]) begin
          ahb_violation v;v=scb.violations[i];error_ap.write(v);
          if(cfg.waiver_reason.exists(v.rule_id) && cfg.waiver_reason[v.rule_id]!="" && cfg.waiver_expiry.exists(v.rule_id) && cycle_count<=cfg.waiver_expiry[v.rule_id])
            `uvm_info("AHB-WAIVER",v.convert2string(),UVM_LOW)
          else if(cfg.rule_severity.exists(v.rule_id)) uvm_report(cfg.rule_severity[v.rule_id],v.rule_id,v.convert2string());
          else `uvm_error(v.rule_id,v.convert2string())
        end
      end
      if(s.reset_n!==1) begin
        if(pending!=null) begin pending.lifecycle=ABORTED;pending.status=RESET_ABORT;pending.completed_cycle=cycle_count;transaction_ap.write(pending);pending=null;end
        flush_burst("reset");continue;
      end
      if(pending!=null) begin
        if(s.ready===1) begin
          pending.data=pending.write?s.wdata:s.rdata;pending.strobe=s.strb;
          pending.wuser=s.wu;pending.ruser=s.ru;pending.buser=s.bu;
          pending.response=s.resp;pending.exokay=s.exokay;pending.completed_cycle=cycle_count;
          pending.status=(s.resp==1)?ERROR:(s.resp==2)?RETRY:(s.resp==3)?SPLIT:(pending.exclusive && !s.exokay)?EXCLUSIVE_FAIL:OKAY;
          pending.lifecycle=COMPLETED;
          pending.valid_mask=active_mask(pending.addr,pending.size,DW/8,cfg.endian);
          if(pending.write && STROBE) pending.valid_mask &= s.strb;
          transaction_ap.write(pending);
          if(aggregate==null) aggregate=ahb_burst::type_id::create("burst");
          aggregate.beats.push_back(pending.duplicate());
          if(pending.status!=OKAY || burst_length(pending.burst)>0 && aggregate.beats.size()==burst_length(pending.burst)) flush_burst(pending.status.name());
          else if(aggregate.beats.size()>=cfg.history_limit && cfg.history_limit>0) flush_burst("bounded_chunk");
          pending=null;
        end else pending.waits++;
      end
      if(s.ready===1 && (s.sel===1 || !cfg.subordinate_view)) begin
        if(s.trans[1]===1) begin
          if(s.trans==2) flush_burst("nonseq");
          pending=s.address.duplicate();pending.lifecycle=ACCEPTED;pending.accepted_cycle=cycle_count;
          request_ap.write(pending.duplicate());
        end else if(s.trans==0) flush_burst("idle");
      end
    end
  endtask
endclass
