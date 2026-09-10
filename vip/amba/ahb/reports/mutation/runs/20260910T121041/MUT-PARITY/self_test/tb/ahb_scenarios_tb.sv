// SPDX-License-Identifier: Apache-2.0
module ahb_scenarios_tb;
  timeunit 1ns;timeprecision 1ps;
  import uvm_pkg::*;import ahb_types_pkg::*;import ahb_pkg::*;
  `include "uvm_macros.svh"
  logic clk=0,rst_n=0;always #5 clk=~clk;
  ahb_if bus(clk,rst_n);
  assign bus.HREADY=bus.HREADYOUT;assign bus.HSEL=1;
  ahb_assertions assertions(clk,rst_n,bus.HREADY,bus.HSEL,bus.HRESP,bus.HTRANS,bus.HADDR,bus.HSIZE);
  string scenario="burst";bit request_reset=0,reset_done=0;
  initial begin
    void'($value$plusargs("CASE=%s",scenario));repeat(5) @(negedge clk);rst_n=1;
    wait(request_reset);repeat(3) @(negedge clk);rst_n=0;repeat(3) @(negedge clk);rst_n=1;reset_done=1;
  end
  class scenario_seq extends ahb_base_seq;
    `uvm_object_utils(scenario_seq)
    int completed=0,aborts=0,count=1000;
    function new(string name="scenario_seq");super.new(name);endfunction
    task body();
      ahb_item t,r,first;ahb_item results[$];ahb_data_t value;
      if(scenario=="burst") begin
        for(int b=0;b<8;b++) begin
          int length;length=(b==0)?1:(b==1)?17:(b<=3)?4:(b<=5)?8:16;
          first=new();first.addr='h100+(b*'h100)+((b inside {2,4,6})?12:0);first.write=1;first.burst=3'(b);first.data='h12345678;
          burst_transfer(first,length,results);foreach(results[i]) if(results[i].status!=OKAY) `uvm_error("BURST-WRITE",results[i].convert2string())
          first.write=0;burst_transfer(first,length,results);foreach(results[i]) if(results[i].status!=OKAY || results[i].data[31:0]!=='h12345678) `uvm_error("BURST-READ",results[i].convert2string())
        end
        for(int sz=0;sz<=2;sz++) for(int offset=0;offset<4;offset+=(1<<sz)) begin
          t=new();t.addr='h1000+offset;t.write=1;t.size=3'(sz);t.data='h44332211;transfer(t,r);
          t=new();t.addr='h1000+offset;t.size=3'(sz);transfer(t,r);
          for(int i=offset;i<offset+(1<<sz);i++) if(r.data[i*8+:8]!==8'('h44332211>>(i*8))) `uvm_error("NARROW",r.convert2string())
        end
      end else if(scenario=="error") begin
        for(int i=0;i<4;i++) begin t=new();t.addr='hff00+i*4;t.write=1;t.data=i;transfer(t,r);if(r.status!=ERROR) `uvm_error("ERROR-STATUS",r.convert2string()) end
        write('h100,32'h11223344);read('h100,value);if(value[31:0]!=='h11223344) `uvm_error("ERROR-RECOVERY","data")
      end else if(scenario=="reset") begin
        request_reset=1;
        for(int i=0;i<16;i++) begin t=new();t.addr=i*4;t.write=1;t.data=i;submit(t);end
        repeat(16) begin get_response(r);if(r.status==RESET_ABORT) aborts++;else if(r.status!=OKAY) `uvm_error("RESET-STATUS",r.convert2string()) end
        wait(reset_done);if(aborts==0) `uvm_error("RESET-ABORT","no aborted queued/data requests")
        write('h100,32'h11223344);read('h100,value);if(value[31:0]!=='h11223344) `uvm_error("RESET-RECOVERY","data")
      end else if(scenario=="stress") begin
        void'($value$plusargs("COUNT=%d",count));
        for(int i=0;i<count;i++) begin
          t=new();t.addr=(i%256)*4;t.write=1;t.data=$urandom();transfer(t,r);if(r.status!=OKAY) `uvm_error("STRESS-WRITE",r.convert2string())
          value=t.data;t=new();t.addr=(i%256)*4;transfer(t,r);if(r.data[31:0]!==value[31:0] || r.status!=OKAY) `uvm_error("STRESS-READ",r.convert2string())
          completed+=2;
        end
        $display("STRESS_COMPLETIONS %0d",completed);
      end
    endtask
  endclass
  class scenario_test extends uvm_test;
    `uvm_component_utils(scenario_test)
    ahb_agent manager,subordinate;ahb_config mc,sc;
    function new(string name,uvm_component parent);super.new(name,parent);endfunction
    function void build_phase(uvm_phase phase);
      super.build_phase(phase);mc=new();sc=new();sc.mode=ACTIVE_SLAVE;
      if(scenario=="error") begin sc.error_enable=1;sc.error_start='hff00;sc.error_end='hff0f;sc.max_wait=3;sc.min_wait=3;end
      if(scenario=="reset") begin sc.max_wait=15;sc.min_wait=15;end
      uvm_config_db#(ahb_config)::set(this,"manager*","cfg",mc);uvm_config_db#(ahb_config)::set(this,"subordinate*","cfg",sc);
      manager=ahb_agent#()::type_id::create("manager",this);subordinate=ahb_agent#()::type_id::create("subordinate",this);
    endfunction
    task run_phase(uvm_phase phase);
      scenario_seq seq;phase.raise_objection(this);seq=new();#100;seq.start(manager.sequencer);#30;
      if(scenario=="error" && subordinate.slave_driver.memory.valid('hff00)) `uvm_error("ERROR-COMMIT","error modified memory")
      $display("AHB_SCENARIO_PASS case=%s",scenario);phase.drop_objection(this);
    endtask
  endclass
  initial begin uvm_config_db#(virtual ahb_if)::set(null,"uvm_test_top.*","vif",bus);run_test("scenario_test");end
  initial begin #1000000000;$fatal(1,"SCENARIO_WATCHDOG");end
endmodule
