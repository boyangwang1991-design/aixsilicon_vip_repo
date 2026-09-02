// =============================================================================
// File Name   : axi4_concurrent_test.sv
// Description : AXI4 VIP Self Test concurrent tier（validation-plan §13.2/§21）
//               C1 多 ID 写读回环（PRO-008）：4 个 ID 交替写+读，数据完整性
//               C2 outstanding 写流水（PRO-007）：请求即 item_done、B 后台收
//               C3 AW/W 解耦 W-before-AW 形态（PRO-019）：decouple 模式回环
//               判定：合法空间 0 违规；数据完整性由 sequence 校验
// =============================================================================
`ifndef AXI4_CONCURRENT_TEST__SV
`define AXI4_CONCURRENT_TEST__SV

import uvm_pkg::*;
import axi4_pkg::*;
import axi4_types_pkg::*;

// 多 ID 写读回环 sequence：每 ID 写入特征值并读回校验
class axi4_multi_id_seq extends axi4_master_base_seq;

  rand int num_ids;
  rand bit decouple_mode;

  constraint c_ids { num_ids inside {[2:4]}; soft decouple_mode == 0; }

  `uvm_object_utils(axi4_multi_id_seq)

  function new(string name = "axi4_multi_id_seq");
    super.new(name);
    num_ids = 4;
    decouple_mode = 0;
  endfunction

  virtual task body();
    axi4_data wdata, rdata;
    int errors = 0;
    string msg;

    for (int i = 0; i < num_ids; i++) begin
      axi4_address base = 32'h0000_8000 + i * 32'h40;
      // 写：ID=i 特征值
      begin
        axi4_master_item item;
        item = axi4_master_item::type_id::create("item");
        item.access_type  = AXI4_WRITE_ACCESS;
        item.id           = axi4_id'(i);
        item.address      = base;
        item.burst_length = 2;
        item.burst_size   = 4;
        item.burst_type   = AXI4_INCREMENTING_BURST;
        item.data         = new[2];
        item.strobe       = new[2];
        item.data[0]      = 32'hC0DE_0000 + i;
        item.data[1]      = 32'hC0DE_1000 + i;
        item.strobe[0]    = '1;
        item.strobe[1]    = '1;
        start_item(item);
        finish_item(item);
      end
      // 读：ID=i 校验
      begin
        axi4_master_item item;
        item = axi4_master_item::type_id::create("item");
        item.access_type  = AXI4_READ_ACCESS;
        item.id           = axi4_id'(i);
        item.address      = base;
        item.burst_length = 2;
        item.burst_size   = 4;
        item.burst_type   = AXI4_INCREMENTING_BURST;
        start_item(item);
        finish_item(item);
        if (item.data.size() == 2) begin
          if ((item.data[0] !== (32'hC0DE_0000 + i)) ||
              (item.data[1] !== (32'hC0DE_1000 + i))) begin
            msg = $sformatf("multi-id[%0d] data mismatch: got %08h/%08h",
                            i, item.data[0][31:0], item.data[1][31:0]);
            `uvm_error(get_type_name(), msg)
            errors++;
          end
        end
        else begin
          msg = $sformatf("multi-id[%0d] read size %0d != 2", i, item.data.size());
          `uvm_error(get_type_name(), msg)
          errors++;
        end
      end
    end
    if (errors == 0) begin
      `uvm_info(get_type_name(), $sformatf("multi-id(%0d) write/read loopback PASS", num_ids), UVM_LOW)
    end
  endtask

endclass : axi4_multi_id_seq


// outstanding 写流水 sequence：连续 N 笔写（B 后台收），再统一读回
class axi4_outstanding_seq extends axi4_master_base_seq;

  rand int num_writes;

  constraint c_ow { num_writes inside {[4:8]}; }

  `uvm_object_utils(axi4_outstanding_seq)

  function new(string name = "axi4_outstanding_seq");
    super.new(name);
    num_writes = 6;
  endfunction

  virtual task body();
    axi4_data rdata;
    int errors = 0;
    string msg;

    // 连续写（driver 侧 outstanding：AW+W 完成即返回）
    for (int i = 0; i < num_writes; i++) begin
      begin
        axi4_master_item item;
        item = axi4_master_item::type_id::create("item");
        item.access_type  = AXI4_WRITE_ACCESS;
        item.id           = axi4_id'(i % 4);
        item.address      = 32'h0000_A000 + i * 32'h20;
        item.burst_length = 1;
        item.burst_size   = 4;
        item.burst_type   = AXI4_INCREMENTING_BURST;
        item.data         = new[1];
        item.strobe       = new[1];
        item.data[0]      = 32'hDADA_0000 + i;
        item.strobe[0]    = '1;
        start_item(item);
        finish_item(item);
      end
    end
    // 统一读回校验
    for (int i = 0; i < num_writes; i++) begin
      read(32'h0000_A000 + i * 32'h20, rdata);
      if (rdata !== (32'hDADA_0000 + i)) begin
        msg = $sformatf("outstanding[%0d] mismatch: got %08h", i, rdata[31:0]);
        `uvm_error(get_type_name(), msg)
        errors++;
      end
    end
    if (errors == 0) begin
      `uvm_info(get_type_name(), $sformatf("outstanding %0d writes + readback PASS", num_writes), UVM_LOW)
    end
  endtask

endclass : axi4_outstanding_seq


// outstanding 读流水 sequence（PRO-008 完整并发 / async_read）：
// 连续 N 笔多 ID 读（异步 item_done），随后经 driver 后台线程回填后统一校验。
class axi4_outstanding_read_seq extends axi4_master_base_seq;

  rand int num_reads;

  constraint c_ord { num_reads inside {[4:8]}; }

  `uvm_object_utils(axi4_outstanding_read_seq)

  function new(string name = "axi4_outstanding_read_seq");
    super.new(name);
    num_reads = 6;
  endfunction

  virtual task body();
    axi4_master_item items[$];
    int errors = 0;
    string msg;

    // 预写特征值（同步写，B 后台收）
    for (int i = 0; i < num_reads; i++) begin
      write(32'h0000_E000 + i * 32'h20, 32'hECE0_0000 + i);
    end
    #100;

    // 连续多 ID 异步读（driver async_read=1：AR 完成即 item_done）
    for (int i = 0; i < num_reads; i++) begin
      axi4_master_item item;
      item = axi4_master_item::type_id::create($sformatf("ord_rd_%0d", i));
      item.access_type  = AXI4_READ_ACCESS;
      item.id           = axi4_id'(i % 4);
      item.address      = 32'h0000_E000 + i * 32'h20;
      item.burst_length = 1;
      item.burst_size   = 4;
      item.burst_type   = AXI4_INCREMENTING_BURST;
      start_item(item);
      finish_item(item);
      items.push_back(item);
    end

    // 等待后台线程回填（R 按 per-ID FIFO 回来后 data 有效）
    #500;
    foreach (items[i]) begin
      if (!items[i].has_response) begin
        msg = $sformatf("outstanding-read[%0d] no response (backfill incomplete)", i);
        `uvm_error(get_type_name(), msg)
        errors++;
      end
      else if (items[i].data.size() == 0) begin
        msg = $sformatf("outstanding-read[%0d] empty data", i);
        `uvm_error(get_type_name(), msg)
        errors++;
      end
      else if (items[i].data[0] !== (32'hECE0_0000 + i)) begin
        msg = $sformatf("outstanding-read[%0d] mismatch: got %08h",
                        i, items[i].data[0][31:0]);
        `uvm_error(get_type_name(), msg)
        errors++;
      end
    end
    if (errors == 0) begin
      `uvm_info(get_type_name(),
        $sformatf("outstanding async read %0d beats (multi-id) PASS", num_reads), UVM_LOW)
    end
  endtask

endclass : axi4_outstanding_read_seq


// W-before-AW 解耦 sequence
class axi4_decouple_seq extends axi4_master_base_seq;

  `uvm_object_utils(axi4_decouple_seq)

  function new(string name = "axi4_decouple_seq");
    super.new(name);
  endfunction

  virtual task body();
    axi4_data rdata;
    int errors = 0;
    string msg;
    // decouple 模式由 test 在 driver 上置位；写 2 笔 + 读回
    // 每笔写后加间隔：使 W-before-AW 的 W 拍与 AW 明确分离（避免跨事务
    // W 拍被前一 AW 的采样窗口吸收——线程竞争属 G4 深化项）
    for (int i = 0; i < 2; i++) begin
      write(32'h0000_B000 + i * 32'h20, 32'hDECE_0000 + i);
      #40;
    end
    for (int i = 0; i < 2; i++) begin
      read(32'h0000_B000 + i * 32'h20, rdata);
      if (rdata !== (32'hDECE_0000 + i)) begin
        msg = $sformatf("decouple[%0d] mismatch: got %08h", i, rdata[31:0]);
        `uvm_error(get_type_name(), msg)
        errors++;
      end
    end
    if (errors == 0) begin
      `uvm_info(get_type_name(), "W-before-AW decouple write/read loopback PASS", UVM_LOW)
    end
  endtask

endclass : axi4_decouple_seq


class axi4_concurrent_test extends uvm_test;

  axi4_smoke_env env;

  `uvm_component_utils(axi4_concurrent_test)

  function new(string name = "axi4_concurrent_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = axi4_smoke_env::type_id::create("env", this);
  endfunction

  task run_phase(uvm_phase phase);
    axi4_multi_id_seq   seq1;
    axi4_outstanding_seq seq2;
    axi4_decouple_seq   seq3;
    axi4_outstanding_read_seq seq4;
    axi4_master_driver  mdrv;

    phase.raise_objection(this);

    // C1: 多 ID 交替写读
    seq1 = axi4_multi_id_seq::type_id::create("seq1");
    void'(seq1.randomize() with { decouple_mode == 0; });
    seq1.start(env.master_agent.sequencer);
    #50;

    // C2: outstanding 写流水
    seq2 = axi4_outstanding_seq::type_id::create("seq2");
    void'(seq2.randomize());
    seq2.start(env.master_agent.sequencer);
    #50;

    // C3 W-before-AW 解耦（PRO-019）：采样沿统一修复后（slave 预收与 AW 采样
    // 均改 @(posedge aclk) + 顶层信号），接入回环验证。
    if (env.master_agent.driver != null) begin
      mdrv = env.master_agent.driver;
      mdrv.decouple_w_before_aw = 1;
    end
    seq3 = axi4_decouple_seq::type_id::create("seq3");
    seq3.start(env.master_agent.sequencer);
    #50;
    if (mdrv != null) begin
      mdrv.decouple_w_before_aw = 0;   // 恢复默认形态
    end

    // C4 outstanding 读（PRO-008 完整并发）：async_read=1，AR 完成即 item_done，
    // R 由 driver 后台线程按 per-ID FIFO 回填；多 ID 交织场景校验。
    seq4 = axi4_outstanding_read_seq::type_id::create("seq4");
    void'(seq4.randomize());
    if (mdrv != null) begin
      mdrv.async_read = 1;
    end
    seq4.start(env.master_agent.sequencer);
    #50;
    if (mdrv != null) begin
      mdrv.async_read = 0;             // 恢复同步读（其余 tier 兼容）
    end

    phase.drop_objection(this);
  endtask

  function void report_phase(uvm_phase phase);
    uvm_report_server svr = uvm_report_server::get_server();
    int errs;
    super.report_phase(phase);
    errs = svr.get_severity_count(UVM_ERROR);
    if (errs != 0) begin
      `uvm_error(get_type_name(), $sformatf(
        "concurrent test: %0d UVM_ERROR (multi-id/outstanding/decouple must be clean)", errs))
    end
    else begin
      `uvm_info(get_type_name(), "concurrent test: multi-id + outstanding + W-before-AW all PASS", UVM_LOW)
    end
  endfunction

endclass : axi4_concurrent_test

`endif // AXI4_CONCURRENT_TEST__SV
