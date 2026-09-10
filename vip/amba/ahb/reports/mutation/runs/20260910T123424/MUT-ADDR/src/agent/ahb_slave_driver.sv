// SPDX-License-Identifier: Apache-2.0
class ahb_slave_driver #(int AW=32,DW=32,BW=3,PW=4,MW=0,AU=0,DU=0,RU=0,PROFILE=0, bit SECURE=0,EXCLUSIVE=0,STROBE=0,PARITY=0) extends uvm_component;
  `uvm_component_param_utils(ahb_slave_driver#(AW,DW,BW,PW,MW,AU,DU,RU,PROFILE,SECURE,EXCLUSIVE,STROBE,PARITY))
  virtual ahb_if#(AW,DW,BW,PW,MW,AU,DU,RU,PROFILE,SECURE,EXCLUSIVE,STROBE,PARITY) vif;
  ahb_config cfg;
  ahb_memory memory;
  ahb_response_policy policy;
  ahb_item pending;
  int remaining;
  int split_countdown[16];
  bit[1:0] chosen_response;
  bit error_first;
  int unsigned identity_prefix=0;
  function new(string name,uvm_component parent);super.new(name,parent);endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(ahb_config)::get(this,"","cfg",cfg)) `uvm_fatal("AHB-CONFIG","cfg missing")
    if(!uvm_config_db#(virtual ahb_if#(AW,DW,BW,PW,MW,AU,DU,RU,PROFILE,SECURE,EXCLUSIVE,STROBE,PARITY))::get(this,"","vif",vif)) `uvm_fatal("AHB-VIF","vif missing")
    if(!uvm_config_db#(ahb_memory)::get(this,"","memory",memory)) memory=ahb_memory::type_id::create("memory");
    if(!uvm_config_db#(ahb_response_policy)::get(this,"","policy",policy)) policy=ahb_response_policy::type_id::create("policy");policy.cfg=cfg;
  endfunction
  task output_response(bit ready,bit[1:0] response,logic exokay,ahb_data_t data);
    vif.subordinate_cb.HREADYOUT<=ready;vif.subordinate_cb.HRESP<=response;vif.subordinate_cb.HEXOKAY<=exokay;
    vif.subordinate_cb.HRDATA<=data;vif.subordinate_cb.HRUSER<=0;vif.subordinate_cb.HBUSER<=0;
    if(PARITY) begin
      vif.subordinate_cb.HREADYOUTCHK<=~ready;vif.subordinate_cb.HRESPCHK<=~^{response[0],exokay};
      vif.subordinate_cb.HRDATACHK<=parity_bytes(data,DW);vif.subordinate_cb.HRUSERCHK<=parity_bytes(0,DU);vif.subordinate_cb.HBUSERCHK<=parity_bytes(0,RU);
    end
  endtask
  task run_phase(uvm_phase phase);
    forever begin
      bit accepted_now;bit[15:0] release_bits;
      @(vif.subordinate_cb);cfg.check_frozen();accepted_now=0;release_bits=0;
      if(PROFILE==2) begin
        for(int i=0;i<16;i++) if(split_countdown[i]>0) begin split_countdown[i]--;if(split_countdown[i]==0) release_bits[i]=1;end
        vif.subordinate_cb.HSPLIT<=release_bits;
      end
      if(vif.subordinate_cb.HRESETn!==1) begin pending=null;remaining=0;error_first=0;memory.reset(cfg.preserve_memory);foreach(split_countdown[i]) split_countdown[i]=0;if(PROFILE==2) vif.subordinate_cb.HSPLIT<=0;output_response(1,0,0,0);continue;end
      if(pending!=null && vif.subordinate_cb.HREADY===1) begin
        pending.data=vif.subordinate_cb.HWDATA;pending.strobe=STROBE?vif.subordinate_cb.HWSTRB:'1;
        pending.status=(chosen_response!=0)?ERROR:(pending.exclusive && pending.write && !memory.exclusive_match(pending,identity_prefix+pending.master))?EXCLUSIVE_FAIL:OKAY;
        if(PROFILE==2 && chosen_response==3) split_countdown[pending.master]=cfg.split_release_delay>0?cfg.split_release_delay:1;
        memory.commit(pending,DW/8,cfg.endian,identity_prefix+pending.master);pending=null;
      end
      if(vif.subordinate_cb.HREADY===1 && vif.subordinate_cb.HSEL===1 && vif.subordinate_cb.HTRANS[1]===1) begin
        pending=ahb_item::type_id::create("accepted");pending.addr=vif.subordinate_cb.HADDR;
        pending.write=vif.subordinate_cb.HWRITE;pending.size=vif.subordinate_cb.HSIZE;
        pending.burst=BW?vif.subordinate_cb.HBURST:1;pending.prot=PW?vif.subordinate_cb.HPROT:3;
        pending.lock=vif.subordinate_cb.HMASTLOCK;pending.nonsecure=SECURE?vif.subordinate_cb.HNONSEC:0;
        pending.exclusive=EXCLUSIVE?vif.subordinate_cb.HEXCL:0;pending.master=MW?vif.subordinate_cb.HMASTER:0;
        pending.auser=AU?vif.subordinate_cb.HAUSER:0;
        policy.select_response(pending,remaining,chosen_response);error_first=0;accepted_now=1;
      end
      if(pending==null) output_response(1,0,0,0);
      else begin
        if(!accepted_now && remaining>0) remaining--;
        if(remaining>0) output_response(0,0,0,0);
        else if(chosen_response!=0 && !error_first) begin output_response(0,chosen_response,0,0);error_first=1;end
        else begin
          bit ex_success;ahb_data_t data;
          ex_success=pending.exclusive && chosen_response==0 && (!pending.write || memory.exclusive_match(pending,identity_prefix+pending.master));
          data=pending.write?0:memory.read_bus(pending,DW/8,cfg.endian);
          output_response(1,chosen_response,ex_success,data);
        end
      end
    end
  endtask
endclass
