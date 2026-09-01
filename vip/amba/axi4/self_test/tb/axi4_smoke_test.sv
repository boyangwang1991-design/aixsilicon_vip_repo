// =============================================================================
// File Name   : axi4_smoke_test.sv
// Description : AXI4 VIP Self Test smoke 测试（最小正向事务：写读回环）
// =============================================================================

`ifndef AXI4_SMOKE_TEST__SV
`define AXI4_SMOKE_TEST__SV

import uvm_pkg::*;
import axi4_pkg::*;
import axi4_types_pkg::*;

class axi4_smoke_test extends uvm_test;

  axi4_smoke_env env;

  `uvm_component_utils(axi4_smoke_test)

  function new(string name = "axi4_smoke_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = axi4_smoke_env::type_id::create("env", this);
  endfunction

  task run_phase(uvm_phase phase);
    axi4_smoke_seq seq;
    phase.raise_objection(this);
    seq = axi4_smoke_seq::type_id::create("seq");
    if (!seq.randomize()) begin
      `uvm_fatal(get_type_name(), "randomize failed")
    end
    seq.start(env.master_agent.sequencer);
    #100;
    phase.drop_objection(this);
  endtask

endclass : axi4_smoke_test

`endif // AXI4_SMOKE_TEST__SV
