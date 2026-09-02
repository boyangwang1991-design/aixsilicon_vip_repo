// =============================================================================
// File Name   : axi4_cov_sweep_test.sv
// Description : AXI4 VIP G4 覆盖闭合专项激励（确定性 sweep）
//               S1 strobe 形态：partial/sparse WSTRB 全 shape 遍历（cg_strobe）
//               S2 exclusive 对：exclusive read → exclusive write（EXOKAY）
//                  （cg_exclusive / type_resp EXOKAY bin）
//               S3 len×size 矩阵：len{1,2,4,8,16} × size{1,2,4} INCR 遍历
//                  （cg_length_size / cg_size_bus_burst）
//               S4 read/write 均衡：读 sweep（cg_access_type 双 bin）
//               S5 4KB 边界跨越：cross_4kb bin（预期 checker RUL-003 检出 ×1）
//               判定：ALLOW_ERRORS=1（仅 S5 预期违规）；回归无其它违规
// =============================================================================
`ifndef AXI4_COV_SWEEP_TEST__SV
`define AXI4_COV_SWEEP_TEST__SV

import uvm_pkg::*;
import axi4_pkg::*;
import axi4_types_pkg::*;

class axi4_cov_sweep_seq extends axi4_master_base_seq;

  `uvm_object_utils(axi4_cov_sweep_seq)

  function new(string name = "axi4_cov_sweep_seq");
    super.new(name);
  endfunction

  // 构造一笔写 item 的辅助
  task do_write_item(axi4_address addr, int len, int size, axi4_burst_type btype,
                     axi4_lock_type lock, axi4_strobe shapes[]);
    axi4_master_item item;
    item = axi4_master_item::type_id::create("sweep_item");
    item.access_type  = AXI4_WRITE_ACCESS;
    item.id           = 0;
    item.address      = addr;
    item.burst_length = len;
    item.burst_size   = size;
    item.burst_type   = btype;
    item.lock         = lock;
    item.data         = new[len];
    item.strobe       = new[len];
    foreach (item.data[i]) begin
      item.data[i]   = 32'hC0FE_0000 + i;
      item.strobe[i] = (shapes.size() > 0) ? shapes[i % shapes.size()] : 4'b1111;
    end
    start_item(item);
    finish_item(item);
  endtask

  // 构造一笔读 item 的辅助
  task do_read_item(axi4_address addr, int len, int size, axi4_burst_type btype,
                    axi4_lock_type lock);
    axi4_master_item item;
    item = axi4_master_item::type_id::create("sweep_ritem");
    item.access_type  = AXI4_READ_ACCESS;
    item.id           = 0;
    item.address      = addr;
    item.burst_length = len;
    item.burst_size   = size;
    item.burst_type   = btype;
    item.lock         = lock;
    start_item(item);
    finish_item(item);
  endtask

  virtual task body();
    axi4_strobe shapes[];
    int base;

    // ==== S1: strobe 形态遍历（partial/sparse/full）====
    shapes = new[10];
    shapes[0] = 4'b0001; shapes[1] = 4'b0011; shapes[2] = 4'b0111;
    shapes[3] = 4'b1000; shapes[4] = 4'b1100; shapes[5] = 4'b1110;
    shapes[6] = 4'b0101; shapes[7] = 4'b1010; shapes[8] = 4'b1001;
    shapes[9] = 4'b0110;
    `uvm_info(get_type_name(), "S1: strobe shape sweep (10 shapes)", UVM_LOW)
    for (int i = 0; i < 10; i++) begin
      axi4_strobe one_shape[];
      one_shape = new[1];
      one_shape[0] = shapes[i];
      do_write_item(32'h0001_0000 + i * 32'h40, 1, 4, AXI4_INCREMENTING_BURST,
                    AXI4_NORMAL_LOCK, one_shape);
    end
    #100;

    // ==== S2: exclusive 对（read 建立标记 → write EXOKAY）====
    `uvm_info(get_type_name(), "S2: exclusive read/write pair (EXOKAY)", UVM_LOW)
    do_read_item(32'h0001_1000, 1, 4, AXI4_INCREMENTING_BURST, AXI4_EXCLUSIVE_LOCK);
    begin
      axi4_strobe full_stb[];
      full_stb = new[1];
      full_stb[0] = 4'b1111;
      do_write_item(32'h0001_1000, 1, 4, AXI4_INCREMENTING_BURST, AXI4_EXCLUSIVE_LOCK,
                    full_stb);
    end
    #100;

    // ==== S3: len×size 矩阵遍历（INCR 对齐；len{1,2,4,8,16}×size{1,2,4}）====
    `uvm_info(get_type_name(), "S3: len x size matrix sweep", UVM_LOW)
    base = 0;
    for (int li = 0; li < 5; li++) begin
      int len_arr[5] = '{1, 2, 4, 8, 16};
      for (int si = 0; si < 3; si++) begin
        int size_arr[3] = '{1, 2, 4};
        int len  = len_arr[li];
        int size = size_arr[si];
        // 写 + 读各一遍（access 双 bin + cross 双通道）
        begin
          axi4_strobe full_stb[];
          full_stb = new[len];
          foreach (full_stb[i]) full_stb[i] = 4'b1111;
          do_write_item(32'h0002_0000 + base, len, size, AXI4_INCREMENTING_BURST,
                        AXI4_NORMAL_LOCK, full_stb);
        end
        do_read_item(32'h0002_0000 + base, len, size, AXI4_INCREMENTING_BURST,
                     AXI4_NORMAL_LOCK);
        base += (len * size + 32'h40);
      end
    end
    #200;

    // ==== S4: read 均衡补充（单拍读 sweep）====
    `uvm_info(get_type_name(), "S4: read balance sweep", UVM_LOW)
    for (int i = 0; i < 4; i++) begin
      do_read_item(32'h0002_0000 + i * 32'h40, 1, 4, AXI4_INCREMENTING_BURST,
                   AXI4_NORMAL_LOCK);
    end
    #100;

    // ==== S5: 4KB 边界跨越（预期 checker RUL-003 检出 ×1）====
    `uvm_info(get_type_name(), "S5: 4KB boundary cross (expect RUL-003 detect)", UVM_LOW)
    begin
      axi4_strobe full_stb[];
      full_stb = new[4];
      foreach (full_stb[i]) full_stb[i] = 4'b1111;
      do_write_item(32'h0000_0FFC, 4, 4, AXI4_INCREMENTING_BURST, AXI4_NORMAL_LOCK,
                    full_stb);
    end
    #100;
  endtask

endclass : axi4_cov_sweep_seq


class axi4_cov_sweep_test extends uvm_test;

  axi4_smoke_env env;

  `uvm_component_utils(axi4_cov_sweep_test)

  function new(string name = "axi4_cov_sweep_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = axi4_smoke_env::type_id::create("env", this);
  endfunction

  task run_phase(uvm_phase phase);
    axi4_cov_sweep_seq seq;
    phase.raise_objection(this);
    seq = axi4_cov_sweep_seq::type_id::create("seq");
    seq.start(env.master_agent.sequencer);
    #300;
    phase.drop_objection(this);
  endtask

  function void report_phase(uvm_phase phase);
    uvm_report_server svr = uvm_report_server::get_server();
    int errs;
    int rul003;
    super.report_phase(phase);
    errs   = svr.get_severity_count(UVM_ERROR);
    rul003 = svr.get_id_count("AXI4-REQ-RUL-003");
    // S5 的 4KB 跨越应被 RUL-003 检出（≥1）；其它违规不允许
    if (rul003 < 1) begin
      `uvm_error(get_type_name(),
        "cov sweep: S5 4KB cross (RUL-003) MUST be caught >=1")
    end
    `uvm_info(get_type_name(), $sformatf(
      "cov sweep: RUL-003=%0d total=%0d (expected: 4KB cross 检出 + 0 其它违规)",
      rul003, errs), UVM_LOW)
  endfunction

endclass : axi4_cov_sweep_test

`endif // AXI4_COV_SWEEP_TEST__SV