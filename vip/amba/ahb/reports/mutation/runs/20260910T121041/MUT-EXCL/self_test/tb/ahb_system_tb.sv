// SPDX-License-Identifier: Apache-2.0
// Four manager ports, four shared target models, independent data-phase mux per port.
module ahb_system_tb;
  timeunit 1ns;timeprecision 1ps;
  import uvm_pkg::*;import ahb_types_pkg::*;import ahb_pkg::*;
  `include "uvm_macros.svh"
  logic clk=0,rst_n=0;always #5 clk=~clk;initial begin repeat(5) @(negedge clk);rst_n=1;end
  for(genvar m=0;m<4;m++) begin:ports
    ahb_if manager_bus(clk,rst_n);
    ahb_if target_bus[4](clk,rst_n);
    logic[31:0] rdata[4];logic ready[4],response[4];int data_target=-1;
    assign manager_bus.HSEL=1;
    assign manager_bus.HREADY=data_target<0?1:ready[data_target];
    assign manager_bus.HREADYOUT=manager_bus.HREADY;
    assign manager_bus.HRDATA=data_target<0?0:rdata[data_target];
    assign manager_bus.HRESP=data_target<0?0:response[data_target];
    assign manager_bus.HEXOKAY=0;assign manager_bus.HRUSER=0;assign manager_bus.HBUSER=0;
    always @(posedge clk or negedge rst_n) if(!rst_n) data_target<=-1;else if(manager_bus.HREADY) data_target<=manager_bus.HTRANS[1]?int'(manager_bus.HADDR[13:12]):-1;
    for(genvar t=0;t<4;t++) begin:targets
      assign target_bus[t].HADDR=manager_bus.HADDR;
      assign target_bus[t].HTRANS=manager_bus.HTRANS;
      assign target_bus[t].HWRITE=manager_bus.HWRITE;
      assign target_bus[t].HSIZE=manager_bus.HSIZE;
      assign target_bus[t].HBURST=manager_bus.HBURST;
      assign target_bus[t].HPROT=manager_bus.HPROT;
      assign target_bus[t].HMASTLOCK=manager_bus.HMASTLOCK;
      assign target_bus[t].HWDATA=manager_bus.HWDATA;
      assign target_bus[t].HREADY=manager_bus.HREADY;
      assign target_bus[t].HNONSEC=manager_bus.HNONSEC;
      assign target_bus[t].HEXCL=manager_bus.HEXCL;
      assign target_bus[t].HMASTER=manager_bus.HMASTER;
      assign target_bus[t].HWSTRB=manager_bus.HWSTRB;
      assign target_bus[t].HAUSER=manager_bus.HAUSER;
      assign target_bus[t].HWUSER=manager_bus.HWUSER;
      assign target_bus[t].HSEL=manager_bus.HADDR[13:12]==t;
      assign rdata[t]=target_bus[t].HRDATA;assign ready[t]=target_bus[t].HREADYOUT;assign response[t]=target_bus[t].HRESP;
      initial uvm_config_db#(virtual ahb_if)::set(null,$sformatf("uvm_test_top.s_%0d_%0d*",m,t),"vif",target_bus[t]);
    end
    initial uvm_config_db#(virtual ahb_if)::set(null,$sformatf("uvm_test_top.m_%0d*",m),"vif",manager_bus);
  end
  class system_seq extends ahb_base_seq;
    `uvm_object_utils(system_seq)
    int manager_id;
    function new(string name="system_seq");super.new(name);endfunction
    task body();
      ahb_item t,r;ahb_item requests[$];
      for(int i=0;i<32;i++) begin
        t=new();t.addr=((i%4)<<12)+(manager_id<<8)+(i/4)*4;t.write=1;t.data=(manager_id<<16)+i;
        requests.push_back(t.duplicate());submit(t);
      end
      repeat(32) begin get_response(r);if(r.status!=OKAY) `uvm_error("SYSTEM-WRITE",r.convert2string()) end
      foreach(requests[i]) begin t=requests[i].duplicate();t.write=0;submit(t);end
      foreach(requests[i]) begin get_response(r);if(r.status!=OKAY || r.data[31:0]!==requests[i].data[31:0]) `uvm_error("SYSTEM-READ",r.convert2string()) end
    endtask
  endclass
  class system_test extends uvm_test;
    `uvm_component_utils(system_test)
    ahb_agent managers[4],targets[4][4];ahb_memory memories[4];
    function new(string name,uvm_component parent);super.new(name,parent);endfunction
    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      foreach(memories[t]) memories[t]=ahb_memory::type_id::create($sformatf("memory%0d",t));
      for(int m=0;m<4;m++) begin
        ahb_config cfg;cfg=new();uvm_config_db#(ahb_config)::set(this,$sformatf("m_%0d*",m),"cfg",cfg);
        managers[m]=ahb_agent#()::type_id::create($sformatf("m_%0d",m),this);
        for(int t=0;t<4;t++) begin
          ahb_config sc;sc=new();sc.mode=ACTIVE_SLAVE;sc.max_wait=t;sc.min_wait=t;
          uvm_config_db#(ahb_config)::set(this,$sformatf("s_%0d_%0d*",m,t),"cfg",sc);
          uvm_config_db#(ahb_memory)::set(this,$sformatf("s_%0d_%0d.slave_driver",m,t),"memory",memories[t]);
          targets[m][t]=ahb_agent#()::type_id::create($sformatf("s_%0d_%0d",m,t),this);
        end
      end
    endfunction
    task run_phase(uvm_phase phase);
      phase.raise_objection(this);#100;
      for(int m=0;m<4;m++) begin
        automatic int id=m;
        fork begin system_seq seq;seq=new();seq.manager_id=id;seq.start(managers[id].sequencer);end join_none
      end
      wait fork;#30;
      foreach(memories[t]) if(memories[t].writes!=32) `uvm_error("SYSTEM-COUNT","shared target commit count")
      $display("AHB_SYSTEM_PASS");phase.drop_objection(this);
    endtask
  endclass
  initial run_test("system_test");
  initial begin #1000000;$fatal(1,"SYSTEM_WATCHDOG");end
endmodule
