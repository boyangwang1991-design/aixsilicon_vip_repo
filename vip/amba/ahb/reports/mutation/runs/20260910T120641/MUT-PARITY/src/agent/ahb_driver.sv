// SPDX-License-Identifier: Apache-2.0
class ahb_driver #(int AW=32,DW=32,BW=3,PW=4,MW=0,AU=0,DU=0,RU=0,PROFILE=0, bit SECURE=0,EXCLUSIVE=0,STROBE=0,PARITY=0) extends uvm_driver#(ahb_item);
  `uvm_component_param_utils(ahb_driver#(AW,DW,BW,PW,MW,AU,DU,RU,PROFILE,SECURE,EXCLUSIVE,STROBE,PARITY))
  virtual ahb_if#(AW,DW,BW,PW,MW,AU,DU,RU,PROFILE,SECURE,EXCLUSIVE,STROBE,PARITY) vif;
  ahb_config cfg;
  ahb_item queued[$],offered,pending;
  longint unsigned cycle_count=0;
  bit owns_bus=0,split_blocked=0;
  function new(string name,uvm_component parent);super.new(name,parent);endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(ahb_config)::get(this,"","cfg",cfg)) `uvm_fatal("AHB-CONFIG","cfg missing")
    if(!uvm_config_db#(virtual ahb_if#(AW,DW,BW,PW,MW,AU,DU,RU,PROFILE,SECURE,EXCLUSIVE,STROBE,PARITY))::get(this,"","vif",vif)) `uvm_fatal("AHB-VIF","vif missing")
  endfunction
  function void respond(ahb_item t,ahb_status_e status);
    t.status=status;t.completed_cycle=cycle_count;
    t.lifecycle=(status inside {RESET_ABORT,CANCEL_BEFORE_ACCEPT,WATCHDOG})?ABORTED:COMPLETED;
    seq_item_port.put_response(t);
  endfunction
  task collect();
    forever begin
      ahb_item req,t;
      wait(queued.size()<cfg.queue_depth);
      seq_item_port.get_next_item(req);t=req.duplicate();seq_item_port.item_done();
      if(cfg.request_error(t)!="") begin `uvm_error("AHB-REQUEST",cfg.request_error(t)) respond(t,CANCEL_BEFORE_ACCEPT);end
      else queued.push_back(t);
    end
  endtask
  task drive_address(ahb_item t);
    bit[1:0] tr;ahb_addr_t ad;bit[2:0] bu,sz;bit[6:0] pr;bit wr,lk,ns,ex;bit[7:0] ma;bit[127:0] auv;
    tr=(t==null)?0:t.trans;ad=(t==null)?0:t.addr;bu=(t==null)?0:t.burst;
    sz=(t==null)?0:t.size;pr=(t==null)?3:t.prot;wr=(t==null)?0:t.write;
    lk=(t==null)?0:t.lock;ns=SECURE && t!=null?t.nonsecure:0;
    ex=EXCLUSIVE && t!=null?t.exclusive:0;ma=MW && t!=null?t.master:0;auv=AU && t!=null?t.auser:0;
    vif.manager_cb.HTRANS<=tr;vif.manager_cb.HADDR<=ad;vif.manager_cb.HBURST<=BW?bu:0;
    vif.manager_cb.HSIZE<=sz;vif.manager_cb.HPROT<=PW?pr:0;vif.manager_cb.HWRITE<=wr;
    if(PROFILE!=2) vif.manager_cb.HMASTLOCK<=lk;vif.manager_cb.HNONSEC<=ns;vif.manager_cb.HEXCL<=ex;
    if(PROFILE!=2) vif.manager_cb.HMASTER<=ma;vif.manager_cb.HAUSER<=auv;
    if(PARITY) begin
      vif.manager_cb.HTRANSCHK<=~^tr;vif.manager_cb.HADDRCHK<=parity_bytes(ad,AW);
      vif.manager_cb.HCTRLCHK1<=~^{(BW?bu:3'b0),lk,wr,sz,ns};
      vif.manager_cb.HCTRLCHK2<=~^{ex,ma};vif.manager_cb.HPROTCHK<=~^(PW?pr:7'b0);
      vif.manager_cb.HAUSERCHK<=parity_bytes(auv,AU);
    end
  endtask
  task drive_data(ahb_item t);
    ahb_data_t d;ahb_mask_t st;logic[511:0] user_value;
    d=(t!=null && t.write)?t.data:0;st=(STROBE && t!=null)?t.strobe:'1;user_value=(DU && t!=null)?t.wuser:0;
    vif.manager_cb.HWDATA<=d;vif.manager_cb.HWSTRB<=st;vif.manager_cb.HWUSER<=user_value;
    if(PARITY) begin vif.manager_cb.HWDATACHK<=parity_bytes(d,DW);vif.manager_cb.HWSTRBCHK<=parity_bytes(st,DW/8);vif.manager_cb.HWUSERCHK<=parity_bytes(user_value,DU);end
  endtask
  task schedule();
    forever begin
      @(vif.manager_cb);cycle_count++;
      if(PROFILE==2 && vif.manager_cb.HSPLIT[cfg.classic_master_id]) split_blocked=0;
      if(vif.manager_cb.HRESETn!==1) begin
        if(pending!=null) respond(pending,RESET_ABORT);
        if(offered!=null) respond(offered,RESET_ABORT);
        pending=null;offered=null;owns_bus=0;split_blocked=0;
        if(PROFILE==2) begin vif.manager_cb.HBUSREQ<=0;vif.manager_cb.HLOCK<=0;end
        while(queued.size()) begin ahb_item t;t=queued.pop_front();respond(t,RESET_ABORT);end
        drive_address(null);drive_data(null);continue;
      end
      if(vif.manager_cb.HREADY===1) begin
        if(pending!=null) begin
          pending.response=vif.manager_cb.HRESP;pending.exokay=EXCLUSIVE?vif.manager_cb.HEXOKAY:0;
          if(!pending.write) pending.data=vif.manager_cb.HRDATA;
          pending.valid_mask=active_mask(pending.addr,pending.size,DW/8,cfg.endian);
          if(pending.write && STROBE) pending.valid_mask &= pending.strobe;
          pending.ruser=DU?vif.manager_cb.HRUSER:0;pending.buser=RU?vif.manager_cb.HBUSER:0;
          if(PROFILE==2 && pending.response inside {2,3} && pending.attempt<cfg.max_attempts) begin
            if(pending.response==3) split_blocked=1;
            pending.attempt++;pending.trans=2;pending.waits=0;pending.lifecycle=REQUESTED;
            queued.push_front(pending);
          end else respond(pending,(pending.response==1)?ERROR:(pending.response==2)?RETRY:(pending.response==3)?SPLIT:(pending.exclusive && !pending.exokay)?EXCLUSIVE_FAIL:OKAY);
          pending=null;
        end
        if(offered!=null) begin
          if(offered.trans[1]) begin pending=offered;pending.lifecycle=ACCEPTED;pending.accepted_cycle=cycle_count;end
          else respond(offered,OKAY);
          offered=null;
        end
        drive_data(pending);
        if(PROFILE==2) owns_bus=vif.manager_cb.HGRANT[cfg.classic_master_id];
        if((PROFILE!=2 || owns_bus && !split_blocked) && queued.size() && !(queued[0].exclusive && pending!=null && pending.exclusive && queued[0].master==pending.master)) begin offered=queued.pop_front();offered.lifecycle=OFFERED;end
        drive_address(offered);
      end else begin
        if(pending!=null) begin
          pending.waits++;
          if(cfg.watchdog_cycles && pending.waits>=cfg.watchdog_cycles) `uvm_fatal("AHB-WATCHDOG","environment wait limit; reset DUT before reuse")
        end
        if(vif.manager_cb.HRESP!=0 && (cfg.stop_on_error || PROFILE==2 && vif.manager_cb.HRESP inside {2,3})) begin
          if(PROFILE==2 && vif.manager_cb.HRESP inside {2,3}) begin
            if(offered!=null) begin offered.trans=2;offered.lifecycle=REQUESTED;queued.push_front(offered);end
          end else begin
            if(offered!=null) respond(offered,CANCEL_BEFORE_ACCEPT);
            while(queued.size()) begin ahb_item t;t=queued.pop_front();respond(t,CANCEL_BEFORE_ACCEPT);end
          end
          offered=null;drive_address(null);
        end
      end
      if(PROFILE==2) begin
        vif.manager_cb.HBUSREQ<=(!split_blocked && (queued.size()!=0 || offered!=null))?(16'b1<<cfg.classic_master_id):0;
        vif.manager_cb.HLOCK<=(offered!=null)?offered.lock:queued.size()?queued[0].lock:0;
      end
    end
  endtask
  task run_phase(uvm_phase phase);fork collect();schedule();join endtask
endclass
