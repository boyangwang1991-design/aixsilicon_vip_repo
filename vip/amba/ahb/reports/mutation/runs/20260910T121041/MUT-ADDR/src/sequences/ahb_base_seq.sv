// SPDX-License-Identifier: Apache-2.0
class ahb_base_seq extends uvm_sequence#(ahb_item);
  `uvm_object_utils(ahb_base_seq)
  function new(string name="ahb_base_seq");super.new(name);set_response_queue_depth(-1);endfunction
  task submit(ahb_item t);start_item(t);finish_item(t);endtask
  task transfer(ahb_item t,output ahb_item response);submit(t);get_response(response);endtask
  task write(ahb_addr_t addr,ahb_data_t data,int size=2);
    ahb_item t,r;t=ahb_item::type_id::create("write");t.addr=addr;t.data=data;t.write=1;t.size=3'(size);transfer(t,r);
    if(r.status!=OKAY) `uvm_error("AHB-WRITE",r.convert2string())
  endtask
  task read(ahb_addr_t addr,output ahb_data_t data,input int size=2);
    ahb_item t,r;t=ahb_item::type_id::create("read");t.addr=addr;t.size=3'(size);transfer(t,r);data=r.data;
    if(r.status!=OKAY) `uvm_error("AHB-READ",r.convert2string())
  endtask
  task burst_transfer(ahb_item first,int length,ref ahb_item responses[$]);
    ahb_item t,r;ahb_addr_t addr;addr=first.addr;responses.delete();
    if(burst_length(first.burst)!=0 && length!=burst_length(first.burst)) `uvm_fatal("AHB-BURST","length mismatch")
    for(int i=0;i<length;i++) begin
      t=first.duplicate();t.addr=addr;t.beat_index=i;t.trans=(i==0)?2:3;
      if(i && addr[63:10]!=first.addr[63:10]) begin if(first.burst==1) t.trans=2;else `uvm_fatal("AHB-BURST","fixed burst crosses 1KB") end
      submit(t);addr=next_address(addr,first.size,first.burst);
    end
    repeat(length) begin get_response(r);responses.push_back(r);end
  endtask
  task exclusive_pair(ahb_item request,output ahb_item read_response,output ahb_item write_response);
    ahb_item t;t=request.duplicate();t.exclusive=1;t.write=0;t.burst=0;t.trans=2;transfer(t,read_response);
    t=request.duplicate();t.exclusive=1;t.write=1;t.burst=0;t.trans=2;transfer(t,write_response);
  endtask
endclass
