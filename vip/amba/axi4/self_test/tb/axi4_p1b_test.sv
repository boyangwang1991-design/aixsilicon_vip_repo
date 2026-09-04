// =============================================================================
// File Name   : axi4_p1b_test.sv
// Description : P1 回归专项——写事务 B 响应后台回填完整性。
//               场景：独立 test（无前序 seq 的 outstanding 队列污染），唯一 ID
//               写事务连续发出，断言每笔 item.has_response==1 && response.size()==1
//               && resp==OKAY（B 后台线程必须存活并正确配对回填）。
//               修复前：drive_write_data / receive_write_response / receive_read_
//               response 的无条件 disable fork 会杀掉 run_phase join_none 派生的
//               write_response_thread 后台线程 → 所有写 item 永远等不到 B。
// VLNV        : aixsilicon:vip:axi4:1.0.0
// =============================================================================
`ifndef AXI4_P1B_TEST__SV
`define AXI4_P1B_TEST__SV

import uvm_pkg::*;
import axi4_pkg::*;
import axi4_types_pkg::*;

class axi4_p1b_seq extends axi4_master_base_seq;

  `uvm_object_utils(axi4_p1b_seq)

  int num_writes = 8;

  function new(string name = "axi4_p1b_seq");
    super.new(name);
  endfunction

  virtual task body();
    axi4_master_item items[$];
    int errors = 0;
    string msg;
    // 唯一 ID 连续写（outstanding：AW+W 完成即 item_done，B 后台收取）
    for (int i = 0; i < num_writes; i++) begin
      axi4_master_item item;
      item = axi4_master_item::type_id::create($sformatf("p1b_wr_%0d", i));
      item.access_type  = AXI4_WRITE_ACCESS;
      item.id           = axi4_id'(i);
      item.address      = 32'h0000_F000 + i * 32'h20;
      item.burst_length = 1;
      item.burst_size   = 4;
      item.burst_type   = AXI4_INCREMENTING_BURST;
      item.data         = new[1];
      item.strobe       = new[1];
      item.data[0]      = 32'hBFFF_0000 + i;
      item.strobe[0]    = '1;
      start_item(item);
      finish_item(item);
      items.push_back(item);
    end
    #1000;   // 等待 B 后台线程回填
    foreach (items[i]) begin
      if (!items[i].has_response) begin
        msg = $sformatf("P1-B[%0d] no B response backfill (has_response=0 — disable fork regression)", i);
        `uvm_error(get_type_name(), msg)
        errors++;
      end
      else if (items[i].response.size() != 1) begin
        msg = $sformatf("P1-B[%0d] B response size=%0d, expected 1 (backfill regression)",
                        i, items[i].response.size());
        `uvm_error(get_type_name(), msg)
        errors++;
      end
      else if (items[i].response[0] != AXI4_OKAY) begin
        msg = $sformatf("P1-B[%0d] B resp=%s, expected OKAY", i, items[i].response[0].name());
        `uvm_error(get_type_name(), msg)
        errors++;
      end
    end
    if (errors == 0) begin
      `uvm_info(get_type_name(), $sformatf("P1-B: %0d unique-id writes all B-backfilled (OKAY)", num_writes), UVM_LOW)
    end
    else begin
      `uvm_error(get_type_name(), $sformatf("P1-B: %0d write items missing/incorrect B response", errors))
    end
  endtask

endclass : axi4_p1b_seq


class axi4_p1b_test extends uvm_test;

  axi4_smoke_env env;

  `uvm_component_utils(axi4_p1b_test)

  function new(string name = "axi4_p1b_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = axi4_smoke_env::type_id::create("env", this);
  endfunction

  task run_phase(uvm_phase phase);
    axi4_p1b_seq seq;
    phase.raise_objection(this);
    seq = axi4_p1b_seq::type_id::create("seq");
    seq.start(env.master_agent.sequencer);
    #200;
    phase.drop_objection(this);
  endtask

  function void report_phase(uvm_phase phase);
    uvm_report_server svr = uvm_report_server::get_server();
    int errs;
    super.report_phase(phase);
    errs = svr.get_severity_count(UVM_ERROR);
    if (errs != 0) begin
      `uvm_error(get_type_name(), $sformatf("P1-B: %0d UVM_ERROR (B backfill failed)", errs))
    end
    else begin
      `uvm_info(get_type_name(), "P1-B: all write B responses backfilled PASS", UVM_LOW)
    end
  endfunction

endclass : axi4_p1b_test

`endif // AXI4_P1B_TEST__SV
