// SPDX-License-Identifier: Apache-2.0
class ahb_coverage extends uvm_subscriber#(ahb_item);
  `uvm_component_utils(ahb_coverage)
  ahb_config cfg;
  longint unsigned bin_hits[string];
  longint unsigned completed=0,successful=0,errors=0,aborted=0,effective_bytes=0,wait_cycles=0;
  int direction,burst_value,size_value,wait_bucket,response_value;
  covergroup cg;
    option.per_instance=1;
    cp_direction:coverpoint direction {bins read={0};bins write={1};}
    cp_burst:coverpoint burst_value {bins types[]={[0:7]};}
    cp_size:coverpoint size_value {bins sizes[]={[0:7]};}
    cp_wait:coverpoint wait_bucket {bins zero={0};bins one={1};bins short_wait={2};bins long_wait={3};}
    cp_response:coverpoint response_value {bins okay={0};bins error={1};bins exfail={2};}
    rw_burst_size:cross cp_direction,cp_burst,cp_size;
    wait_response:cross cp_wait,cp_response;
  endgroup
  function new(string name,uvm_component parent);super.new(name,parent);cg=new();endfunction
  function void build_phase(uvm_phase phase);super.build_phase(phase);void'(uvm_config_db#(ahb_config)::get(this,"","cfg",cfg));endfunction
  function void write(ahb_item t);
    string path;wait_cycles+=t.waits;
    if(t.lifecycle==ABORTED) begin aborted++;bin_hits[{"abort/",t.status.name()}]++;return;end
    completed++;if(t.status==OKAY) successful++;else errors++;
    path=(t.status==OKAY)?"normal":"error";
    bin_hits[$sformatf("%s/rw%0d/burst%0d/size%0d",path,t.write,t.burst,t.size)]++;
    bin_hits[$sformatf("%s/wait%0d/response%s",path,t.waits,t.status.name())]++;
    bin_hits[$sformatf("%s/lock%0d/secure%0d/exclusive%0d",path,t.lock,!t.nonsecure,t.exclusive)]++;
    if(t.status==OKAY) for(int i=0;i<128;i++) if(t.valid_mask[i]) effective_bytes++;
    direction=t.write;burst_value=t.burst;size_value=t.size;wait_bucket=t.waits==0?0:t.waits==1?1:t.waits<16?2:3;
    response_value=t.status==OKAY?0:t.status==EXCLUSIVE_FAIL?2:1;cg.sample();
  endfunction
  function void report_phase(uvm_phase phase);
    foreach(bin_hits[id]) $display("AHB_BIN instance=%s id=%s hits=%0d",get_full_name(),id,bin_hits[id]);
    $display("AHB_STATS instance=%s completed=%0d successful=%0d errors=%0d aborted=%0d bytes=%0d waits=%0d",get_full_name(),completed,successful,errors,aborted,effective_bytes,wait_cycles);
  endfunction
endclass
