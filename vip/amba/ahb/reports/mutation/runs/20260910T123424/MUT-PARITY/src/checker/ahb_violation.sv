// SPDX-License-Identifier: Apache-2.0
class ahb_violation extends uvm_object;
  string rule_id,instance_name,phase_name,detail;
  ahb_category_e category=PROTOCOL;
  longint unsigned cycle;
  ahb_addr_t addr;
  ahb_item context_item;
  `uvm_object_utils_begin(ahb_violation)
    `uvm_field_string(rule_id,UVM_DEFAULT)
    `uvm_field_string(instance_name,UVM_DEFAULT)
    `uvm_field_string(phase_name,UVM_DEFAULT)
    `uvm_field_string(detail,UVM_DEFAULT)
    `uvm_field_enum(ahb_category_e,category,UVM_DEFAULT)
    `uvm_field_int(cycle,UVM_DEFAULT)
    `uvm_field_int(addr,UVM_DEFAULT)
    `uvm_field_object(context_item,UVM_DEFAULT)
  `uvm_object_utils_end
  function ahb_violation duplicate();ahb_violation t;$cast(t,clone());return t;endfunction
  function new(string name="ahb_violation");super.new(name);endfunction
  virtual function string convert2string(); return $sformatf("%s %s cycle=%0d phase=%s addr=%h category=%s %s",rule_id,instance_name,cycle,phase_name,addr,category.name(),detail);endfunction
endclass
