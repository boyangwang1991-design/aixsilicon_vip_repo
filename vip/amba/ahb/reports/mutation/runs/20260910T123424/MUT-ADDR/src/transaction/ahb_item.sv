// SPDX-License-Identifier: Apache-2.0
class ahb_item extends uvm_sequence_item;
  rand ahb_addr_t addr;
  rand ahb_data_t data;
  rand ahb_mask_t strobe;
  rand logic write;
  rand logic [2:0] size,burst;
  rand logic [6:0] prot;
  rand logic lock,nonsecure,exclusive;
  rand logic [7:0] master;
  rand logic [127:0] auser;
  rand logic [511:0] wuser;
  logic [511:0] ruser;
  logic [15:0] buser;
  logic [1:0] response;
  logic exokay;
  ahb_mask_t valid_mask;
  ahb_status_e status=OKAY;
  ahb_lifecycle_e lifecycle=REQUESTED;
  int unsigned waits,beat_index,attempt;
  longint unsigned accepted_cycle,completed_cycle;
  string tag,termination;
  bit raw=0;
  bit [1:0] trans=2;
  constraint basic_c { size<=7; (addr & ((64'd1<<size)-1))==0; }
  `uvm_object_utils_begin(ahb_item)
    `uvm_field_int(addr,UVM_DEFAULT)
    `uvm_field_int(data,UVM_DEFAULT)
    `uvm_field_int(strobe,UVM_DEFAULT)
    `uvm_field_int(write,UVM_DEFAULT)
    `uvm_field_int(size,UVM_DEFAULT)
    `uvm_field_int(burst,UVM_DEFAULT)
    `uvm_field_int(prot,UVM_DEFAULT)
    `uvm_field_int(lock,UVM_DEFAULT)
    `uvm_field_int(nonsecure,UVM_DEFAULT)
    `uvm_field_int(exclusive,UVM_DEFAULT)
    `uvm_field_int(master,UVM_DEFAULT)
    `uvm_field_int(auser,UVM_DEFAULT)
    `uvm_field_int(wuser,UVM_DEFAULT)
    `uvm_field_int(ruser,UVM_DEFAULT)
    `uvm_field_int(buser,UVM_DEFAULT)
    `uvm_field_int(response,UVM_DEFAULT)
    `uvm_field_int(exokay,UVM_DEFAULT)
    `uvm_field_int(valid_mask,UVM_DEFAULT)
    `uvm_field_enum(ahb_status_e,status,UVM_DEFAULT)
    `uvm_field_enum(ahb_lifecycle_e,lifecycle,UVM_DEFAULT)
    `uvm_field_int(waits,UVM_DEFAULT)
    `uvm_field_int(beat_index,UVM_DEFAULT)
    `uvm_field_int(attempt,UVM_DEFAULT)
    `uvm_field_int(accepted_cycle,UVM_DEFAULT)
    `uvm_field_int(completed_cycle,UVM_DEFAULT)
    `uvm_field_string(tag,UVM_DEFAULT)
    `uvm_field_string(termination,UVM_DEFAULT)
    `uvm_field_int(raw,UVM_DEFAULT)
    `uvm_field_int(trans,UVM_DEFAULT)
  `uvm_object_utils_end
  function new(string name="ahb_item"); super.new(name); strobe='1; prot=3; size=2; burst=0; addr=0; data='x; write=0; lock=0; nonsecure=0; exclusive=0; master=0; auser=0; wuser=0; ruser=0; buser=0; endfunction
  function ahb_item duplicate(); ahb_item t; $cast(t,clone()); t.set_id_info(this); return t; endfunction
  virtual function string convert2string(); return $sformatf("tag=%s addr=%h write=%b size=%0d burst=%0d data=%h mask=%h resp=%b exokay=%b status=%s cycle=%0d..%0d waits=%0d",tag,addr,write,size,burst,data,valid_mask,response,exokay,status.name(),accepted_cycle,completed_cycle,waits); endfunction
endclass
class ahb_burst extends uvm_object;
  ahb_item beats[$];
  string termination;
  `uvm_object_utils(ahb_burst)
  function new(string name="ahb_burst"); super.new(name); endfunction
  virtual function void do_copy(uvm_object rhs);
    ahb_burst other; super.do_copy(rhs); if(!$cast(other,rhs)) `uvm_fatal("COPY","burst type")
    beats.delete(); foreach(other.beats[i]) beats.push_back(other.beats[i].duplicate()); termination=other.termination;
  endfunction
endclass
