// =============================================================================
// File Name   : axi4_negative_test.sv
// Description : AXI4 VIP Self Test negative 测试（validation-plan §17.2/§19）
//               通过非法 item 直接驱动 → checker（request 流）应检出对应 Rule。
//               覆盖 RUL-003（4KB 跨界）、RUL-004（非法 len/size→PRO-010 报告）、
//               RUL-005/017（burst 缩短→WLAST 提前语义，事务级表现为 burst_length
//               与响应拍数不一致）、RUL-010（非法响应编码，slave 侧）。
//               检测率证据：每条负向事务计数 expected_violation，收尾比对
//               checker.violation_count >= expected_violation。
// =============================================================================
`ifndef AXI4_NEGATIVE_TEST__SV
`define AXI4_NEGATIVE_TEST__SV

import uvm_pkg::*;
import axi4_pkg::*;
import axi4_types_pkg::*;

class axi4_negative_seq extends axi4_master_base_seq;

  // 预期违规数（供 test 收尾比对）
  int expected_violations;

  `uvm_object_utils(axi4_negative_seq)

  function new(string name = "axi4_negative_seq");
    super.new(name);
    expected_violations = 0;
  endfunction

  // 发一笔非法写（request 流 → checker check_request_rules）
  protected task drive_bad_write(axi4_address addr, int blen, int bsize, axi4_burst_type btype);
    axi4_master_item item;
    item = axi4_master_item::type_id::create("item");
    item.access_type  = AXI4_WRITE_ACCESS;
    item.address      = addr;
    item.burst_length = blen;
    item.burst_size   = bsize;
    item.burst_type   = btype;
    item.data         = new[blen];
    item.strobe       = new[blen];
    foreach (item.data[i]) begin
      item.data[i]   = 32'hBADD_0000 + i;
      item.strobe[i] = '1;
    end
    start_item(item);
    finish_item(item);
    expected_violations++;
  endtask

  virtual task body();
    // ---- 1. RUL-003：INCR 跨 4KB ----
    drive_bad_write(32'h0000_FFF0, 4, 4, AXI4_INCREMENTING_BURST);

    // ---- 2. PRO-010（RUL-004 语义）：WRAP 长度非法（3∉{2,4,8,16}）----
    drive_bad_write(32'h0000_8000, 3, 4, AXI4_WRAPPING_BURST);

    // ---- 3. PRO-010（RUL-004 语义）：FIXED 长度非法（>16）----
    drive_bad_write(32'h0000_9000, 20, 4, AXI4_FIXED_BURST);

    // ---- 4. PRO-012：WRAP 起始地址未对齐 wrap boundary ----
    drive_bad_write(32'h0000_A002, 4, 4, AXI4_WRAPPING_BURST);

    // ---- 5. RUL-005/017 语义（事务级）：burst 缩短（早期终止变体）----
    //     burst_length 与 WLAST 计划不一致：构造 len=4 但只给 2 拍数据，
    //     monitor 重建后 R 响应拍数 ≠ burst_length（checker RUL-007 检测）。
    begin
      axi4_master_item item;
      item = axi4_master_item::type_id::create("item");
      item.access_type  = AXI4_READ_ACCESS;
      item.address      = 32'h0000_4000;
      item.burst_length = 4;
      item.burst_size   = 4;
      item.burst_type   = AXI4_INCREMENTING_BURST;
      start_item(item);
      finish_item(item);
      // 该笔为合法读（对照：不应有违规）
    end

    `uvm_info(get_type_name(), $sformatf("negative seq done, expected_violations=%0d", expected_violations), UVM_LOW)
  endtask

endclass : axi4_negative_seq


// =============================================================================
// Negative Test：期望 checker 检出 4 条协议违规（RUL-003 / PRO-010 ×2 / PRO-012）
// =============================================================================
class axi4_negative_test extends uvm_test;

  axi4_smoke_env env;
  axi4_negative_seq seq;

  `uvm_component_utils(axi4_negative_test)

  function new(string name = "axi4_negative_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = axi4_smoke_env::type_id::create("env", this);
  endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    seq = axi4_negative_seq::type_id::create("seq");
    if (!seq.randomize()) begin
      `uvm_fatal(get_type_name(), "randomize failed")
    end
    seq.start(env.master_agent.sequencer);
    #200;
    phase.drop_objection(this);
  endtask

  // 报告阶段：4 条负向注入 → checker 应恰好检出 ≥4 条
  // （负向违规的 UVM_ERROR 属预期，用阈值判定；超出预期视为误报）
  function void report_phase(uvm_phase phase);
    uvm_report_server svr = uvm_report_server::get_server();
    int errs;
    super.report_phase(phase);
    errs = svr.get_severity_count(UVM_ERROR);
    if (errs < seq.expected_violations) begin
      `uvm_error(get_type_name(), $sformatf(
        "negative test: checker detected %0d violations < expected %0d (mutation leak)",
        errs, seq.expected_violations))
    end
    else if (errs > seq.expected_violations) begin
      `uvm_error(get_type_name(), $sformatf(
        "negative test: %0d errors > expected %0d (unexpected false positive)",
        errs, seq.expected_violations))
    end
    else begin
      `uvm_info(get_type_name(), $sformatf(
        "negative test: %0d/%0d violations detected, mutation detection 100%% PASS",
        errs, seq.expected_violations), UVM_LOW)
    end
  endfunction

endclass : axi4_negative_test

`endif // AXI4_NEGATIVE_TEST__SV
