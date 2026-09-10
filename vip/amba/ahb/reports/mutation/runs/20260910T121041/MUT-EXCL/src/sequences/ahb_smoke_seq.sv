// SPDX-License-Identifier: Apache-2.0
class ahb_smoke_seq extends ahb_base_seq;
  `uvm_object_utils(ahb_smoke_seq)
  int count=32;
  function new(string name="ahb_smoke_seq");super.new(name);endfunction
  task body();
    ahb_item t,r;
    for(int i=0;i<count;i++) begin t=ahb_item::type_id::create("write");t.write=1;t.addr=i*4;t.data=32'h12340000+i;submit(t);end
    repeat(count) begin get_response(r);if(r.status!=OKAY) `uvm_error("WRITE",r.convert2string()) end
    for(int i=0;i<count;i++) begin t=ahb_item::type_id::create("read");t.addr=i*4;submit(t);end
    for(int i=0;i<count;i++) begin get_response(r);if(r.status!=OKAY || r.data[31:0] !== (32'h12340000+i)) `uvm_error("READ",r.convert2string()) end
  endtask
endclass
