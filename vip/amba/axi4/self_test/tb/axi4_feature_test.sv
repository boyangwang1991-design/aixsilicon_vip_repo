// =============================================================================
// File Name   : axi4_feature_test.sv
// Description : AXI4 VIP Self Test feature 测试
//               feature tier：basic / burst / narrow 写读回环，
//               覆盖 REQ-PRO-001/002/003/004/005/013/015 等基础 feature 路径。
// =============================================================================

`ifndef AXI4_FEATURE_TEST__SV
`define AXI4_FEATURE_TEST__SV

import uvm_pkg::*;
import axi4_pkg::*;
import axi4_types_pkg::*;

// =============================================================================
// Feature Sequence：在 master sequencer 上执行一组定向 feature 场景
// =============================================================================
class axi4_feature_seq extends axi4_master_base_seq;

  `uvm_object_utils(axi4_feature_seq)

  function new(string name = "axi4_feature_seq");
    super.new(name);
  endfunction

  // 32 位诊断打印辅助（axi4_data 为 1024 位，%h 直打会触发 VCS SFRTMATR）
  function string fmt32(axi4_data d);
    fmt32 = $sformatf("%08h", d[31:0]);
  endfunction

  virtual task body();
    axi4_data   wdata, rdata;
    axi4_data   bdata[];
    axi4_strobe bstrobe[];
    axi4_data   rburst[];
    int         errors = 0;
    string      msg;

    // ---- 1. single write → read 回环（PRO-001/002）----
    wdata = 'hA5A5_A5A5;
    write(32'h0000_1000, wdata);
    read(32'h0000_1000, rdata);
    $display("DBG[single] exp=%s got=%s", fmt32(wdata), fmt32(rdata));
    if (rdata !== wdata) begin
      msg = $sformatf("single write/read mismatch: exp %s got %s", fmt32(wdata), fmt32(rdata));
      `uvm_error(get_type_name(), msg)
      errors++;
    end else begin
      `uvm_info(get_type_name(), "single write/read loopback PASS", UVM_LOW)
    end

    // ---- 2. burst write (len=4, full width) → burst read 回环（PRO-003/004/005）----
    bdata   = new[4];
    bstrobe = new[4];
    foreach (bdata[i]) begin
      bdata[i]   = (32'h1111_0000 + (i * 32'h0000_0010));
      bstrobe[i] = '1;
    end
    burst_write(32'h0000_2000, bdata, bstrobe, 4);
    burst_read(32'h0000_2000, 4, cfg.data_width / 8, rburst);
    if (rburst.size() != 4) begin
      msg = $sformatf("burst read size mismatch: exp 4 got %0d", rburst.size());
      `uvm_error(get_type_name(), msg)
      errors++;
    end else begin
      foreach (bdata[i]) begin
        if (rburst[i] !== bdata[i]) begin
          $display("DBG[burst] beat %0d exp=%s got=%s", i, fmt32(bdata[i]), fmt32(rburst[i]));
          msg = $sformatf("burst write/read beat %0d mismatch: exp %s got %s", i, fmt32(bdata[i]), fmt32(rburst[i]));
          `uvm_error(get_type_name(), msg)
          errors++;
        end
      end
      if (errors == 0) begin
        `uvm_info(get_type_name(), "burst(4) write/read loopback PASS", UVM_LOW)
      end
    end

    // ---- 3. burst write (len=8, narrow size=2) → burst read 回环（PRO-013 narrow）----
    // narrow 语义：数据按 beat_addr 的 lane 位置摆放（lane_shift = addr%4），
    // WSTRB 只置位对应 lane；读回应为相同的 full-width lane 布局。
    begin
      int err_before = errors;
      int lane_shift;
      axi4_data narrow_exp[8];
      bdata   = new[8];
      bstrobe = new[8];
      foreach (bdata[i]) begin
        lane_shift      = ((32'h0000_3000 + i * 2) % 4);
        narrow_exp[i]   = (32'hA500 + i) << (lane_shift * 8);  // 紧凑值放到合法 lane
        bdata[i]        = narrow_exp[i];
        bstrobe[i]      = 'h03 << lane_shift;                  // size=2 → 2 个 lane
      end
      burst_write(32'h0000_3000, bdata, bstrobe, 8, 2);
      burst_read(32'h0000_3000, 8, 2, rburst);
      if (rburst.size() != 8) begin
        msg = $sformatf("narrow burst read size mismatch: exp 8 got %0d", rburst.size());
        `uvm_error(get_type_name(), msg)
        errors++;
      end else begin
        foreach (bdata[i]) begin
          if (rburst[i] !== narrow_exp[i]) begin
            $display("DBG[narrow] beat %0d exp=%s got=%s", i, fmt32(narrow_exp[i]), fmt32(rburst[i]));
            msg = $sformatf("narrow burst beat %0d mismatch: exp %s got %s", i, fmt32(narrow_exp[i]), fmt32(rburst[i]));
            `uvm_error(get_type_name(), msg)
            errors++;
          end
        end
      end
      if (errors == err_before) begin
        `uvm_info(get_type_name(), "narrow burst(8,size=2) write/read loopback PASS", UVM_LOW)
      end
    end

    // ---- 4. 多笔写不同地址 → 读回（PRO-007 基础路径 + memory 独立性）----
    begin
      int err_before = errors;
      axi4_data addr_data[4];
      addr_data[0] = 'h0000_0001;
      addr_data[1] = 'h0000_0002;
      addr_data[2] = 'h0000_0003;
      addr_data[3] = 'h0000_0004;
      foreach (addr_data[i]) begin
        write((32'h0000_4000 + (i * 32'h0000_0040)), addr_data[i]);
      end
      foreach (addr_data[i]) begin
        read((32'h0000_4000 + (i * 32'h0000_0040)), rdata);
        if (rdata !== addr_data[i]) begin
          $display("DBG[multi] addr[%0d] exp=%s got=%s", i, fmt32(addr_data[i]), fmt32(rdata));
          msg = $sformatf("multi-write addr[%0d] mismatch: exp %s got %s", i, fmt32(addr_data[i]), fmt32(rdata));
          `uvm_error(get_type_name(), msg)
          errors++;
        end
      end
      if (errors == err_before) begin
        `uvm_info(get_type_name(), "multi-address write/read loopback PASS", UVM_LOW)
      end
    end

    // ---- 汇总 ----
    if (errors != 0) begin
      msg = $sformatf("feature seq completed with %0d error(s)", errors);
      `uvm_error(get_type_name(), msg)
    end else begin
      `uvm_info(get_type_name(), "feature seq: all checks PASS", UVM_LOW)
    end
  endtask

endclass : axi4_feature_seq


// =============================================================================
// Feature Test
// =============================================================================
class axi4_feature_test extends uvm_test;

  axi4_smoke_env env;

  `uvm_component_utils(axi4_feature_test)

  function new(string name = "axi4_feature_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = axi4_smoke_env::type_id::create("env", this);
  endfunction

  task run_phase(uvm_phase phase);
    axi4_feature_seq seq;
    phase.raise_objection(this);
    seq = axi4_feature_seq::type_id::create("seq");
    if (!seq.randomize()) begin
      `uvm_fatal(get_type_name(), "randomize failed")
    end
    seq.start(env.master_agent.sequencer);
    #200;
    phase.drop_objection(this);
  endtask

endclass : axi4_feature_test

`endif // AXI4_FEATURE_TEST__SV
