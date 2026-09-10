// SPDX-License-Identifier: Apache-2.0
class ahb_violation extends uvm_object;
  string rule_id,instance_name,phase_name,detail;
  ahb_category_e category=PROTOCOL;
  longint unsigned cycle;
  ahb_addr_t addr;
  ahb_item context_item;
  `uvm_object_utils(ahb_violation)
  function new(string name="ahb_violation");super.new(name);endfunction
  virtual function string convert2string(); return $sformatf("%s %s cycle=%0d phase=%s addr=%h category=%s %s",rule_id,instance_name,cycle,phase_name,addr,category.name(),detail);endfunction
endclass
