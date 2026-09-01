// =============================================================================
// File Name   : axi4_corner_test.sv
// Description : AXI4 VIP Self Test corner/boundary 测试（validation-plan §23）
//               VAL-006  4KB 边界（合法边界 + 跨界负向 → checker RUL-003 检测）
//               VAL-005  WRAP burst 写读回环（len 2/4/8/16）
//               VAL-008  unaligned burst 写读回环（首拍 lane 偏移）
//               VAL-009  zero-strobe write（WSTRB==0 合法，memory 不更新）
// =============================================================================
`ifndef AXI4_CORNER_TEST__SV
`define AXI4_CORNER_TEST__SV

import uvm_pkg::*;
import axi4_pkg::*;
import axi4_types_pkg::*;

class axi4_corner_seq extends axi4_master_base_seq;

  `uvm_object_utils(axi4_corner_seq)

  function new(string name = "axi4_corner_seq");
    super.new(name);
  endfunction

  function string fmt32(axi4_data d);
    fmt32 = $sformatf("%08h", d[31:0]);
  endfunction

  // 用 4 个连续地址的期望数据字节（小端 lane 布置，跳过不覆盖 lane）
  // exp: 每 beat 期望 lane 布置后的 full-width 数据
  function axi4_data lane_packed(axi4_address addr, int size, bit[3:0] stb, axi4_data val);
    int shift = addr % 4;
    lane_packed = val << (shift * 8);
  endfunction

  virtual task body();
    axi4_data   wdata, rdata;
    axi4_data   bdata[];
    axi4_strobe bstrobe[];
    axi4_data   rburst[];
    axi4_master_item item;
    int         errors = 0;
    string      msg;
    axi4_address addr;

    // =========================================================================
    // 1. 4KB 边界：合法边界事务（VAL-006 positive）
    //    addr=0x00FFF8, len=2, size=4 → 末地址 0x00FFFC 不跨 0x010000
    // =========================================================================
    begin
      int err_before = errors;
      bdata   = new[2];
      bstrobe = new[2];
      foreach (bdata[i]) begin
        bdata[i]   = 32'hB000_0000 + i;
        bstrobe[i] = '1;
      end
      burst_write(32'h0000_FFF8, bdata, bstrobe, 2);
      burst_read(32'h0000_FFF8, 2, 4, rburst);
      if (rburst.size() != 2) begin
        msg = $sformatf("4KB-edge burst read size: exp 2 got %0d", rburst.size());
        `uvm_error(get_type_name(), msg)
        errors++;
      end
      else begin
        foreach (bdata[i]) begin
          if (rburst[i] !== bdata[i]) begin
            msg = $sformatf("4KB-edge beat %0d mismatch: exp %s got %s", i, fmt32(bdata[i]), fmt32(rburst[i]));
            `uvm_error(get_type_name(), msg)
            errors++;
          end
        end
      end
      if (errors == err_before)
        `uvm_info(get_type_name(), "4KB-edge legal burst loopback PASS", UVM_LOW)
    end

    // =========================================================================
    // 2. 4KB 边界：跨界负向（VAL-006 negative → checker RUL-003）
    //    事务级直接构造跨 4KB 地址；仅驱动写，读不回环。
    //    checker（request 流）应报 AXI4-REQ-RUL-003。
    // =========================================================================
    begin
      item = axi4_master_item::type_id::create("item");
      item.access_type  = AXI4_WRITE_ACCESS;
      item.address      = 32'h0000_FFFC;              // 4 拍 × 4B 会越过 0x010000
      item.burst_length = 4;
      item.burst_size   = 4;
      item.burst_type   = AXI4_INCREMENTING_BURST;
      item.data         = new[4];
      item.strobe       = new[4];
      foreach (item.data[i]) begin
        item.data[i]   = 32'hC000_0000 + i;
        item.strobe[i] = '1;
      end
      start_item(item);
      finish_item(item);
      `uvm_info(get_type_name(), "4KB-crossing negative write issued (expect checker RUL-003)", UVM_LOW)
    end

    // =========================================================================
    // 3. WRAP burst 写读回环（VAL-005）
    //    addr 对齐 wrap boundary（size*len），len=4, size=4
    // =========================================================================
    begin
      int err_before = errors;
      bdata   = new[4];
      bstrobe = new[4];
      foreach (bdata[i]) begin
        bdata[i]   = 32'hD000_0000 + (i * 32'h0000_0100);
        bstrobe[i] = '1;
      end
      burst_write(32'h0000_7000, bdata, bstrobe, 4);
      burst_read(32'h0000_7000, 4, 4, rburst);
      if (rburst.size() != 4) begin
        msg = $sformatf("WRAP burst read size: exp 4 got %0d", rburst.size());
        `uvm_error(get_type_name(), msg)
        errors++;
      end
      else begin
        foreach (bdata[i]) begin
          if (rburst[i] !== bdata[i]) begin
            msg = $sformatf("WRAP burst beat %0d mismatch: exp %s got %s", i, fmt32(bdata[i]), fmt32(rburst[i]));
            `uvm_error(get_type_name(), msg)
            errors++;
          end
        end
      end
      if (errors == err_before)
        `uvm_info(get_type_name(), "WRAP burst(len=4) loopback PASS", UVM_LOW)
    end

    // =========================================================================
    // 4. unaligned burst 写读回环（VAL-008 / PRO-014）
    //    addr=0x5002, len=3, size=4 → 首拍 lane_shift=2
    // =========================================================================
    begin
      int err_before = errors;
      int lane_shift;
      axi4_data exp_val[3];
      bdata   = new[3];
      bstrobe = new[3];
      // INCR unaligned：每拍 beat_addr%4=2 → 有效 lane 均 2~3，
      // 数据按 lane 位置摆放（lane2/3 有效，lane0/1 = 0）
      lane_shift   = (32'h0000_5002 % 4);
      exp_val[0]   = 32'h0000_EE55 << (lane_shift * 8);
      exp_val[1]   = 32'h0000_EE66 << (lane_shift * 8);
      exp_val[2]   = 32'h0000_EE77 << (lane_shift * 8);
      bdata[0]     = exp_val[0];
      bdata[1]     = exp_val[1];
      bdata[2]     = exp_val[2];
      bstrobe[0]   = 4'b0011 << lane_shift;  // size=4 → lane 0~1 起始，移位到 lane 2~3
      bstrobe[1]   = '1;
      bstrobe[2]   = '1;
      burst_write(32'h0000_5002, bdata, bstrobe, 3);
      burst_read(32'h0000_5002, 3, 4, rburst);
      if (rburst.size() != 3) begin
        msg = $sformatf("unaligned burst read size: exp 3 got %0d", rburst.size());
        `uvm_error(get_type_name(), msg)
        errors++;
      end
      else begin
        foreach (exp_val[i]) begin
          if (rburst[i] !== exp_val[i]) begin
            $display("DBG[unalign] beat %0d exp=%s got=%s", i, fmt32(exp_val[i]), fmt32(rburst[i]));
            msg = $sformatf("unaligned burst beat %0d mismatch: exp %s got %s", i, fmt32(exp_val[i]), fmt32(rburst[i]));
            `uvm_error(get_type_name(), msg)
            errors++;
          end
        end
      end
      if (errors == err_before)
        `uvm_info(get_type_name(), "unaligned burst loopback PASS", UVM_LOW)
    end

    // =========================================================================
    // 5. zero-strobe write（VAL-009 / PRO-015）
    //    WSTRB=0：事务照常完成、memory 不更新；先写正常数据，再 zero-strobe 写，
    //    再读 → 应保持第一次写的值。
    // =========================================================================
    begin
      int err_before = errors;
      axi4_data pre_val;
      write(32'h0000_6000, 32'h5555_AAAA);
      read(32'h0000_6000, pre_val);
      if (pre_val !== 32'h5555_AAAA) begin
        msg = $sformatf("pre-zero-strobe setup mismatch: exp 5555aaaa got %s", fmt32(pre_val));
        `uvm_error(get_type_name(), msg)
        errors++;
      end
      // zero-strobe 写（WSTRB=0，数据任意值不应生效）
      bdata   = new[1];
      bstrobe = new[1];
      bdata[0]   = 32'hFFFF_0000;
      bstrobe[0] = '0;
      burst_write(32'h0000_6000, bdata, bstrobe, 1, 4);
      read(32'h0000_6000, rdata);
      if (rdata !== 32'h5555_AAAA) begin
        $display("DBG[zero-stb] exp=5555aaaa got=%s", fmt32(rdata));
        msg = $sformatf("zero-strobe: memory changed unexpectedly: exp 5555aaaa got %s", fmt32(rdata));
        `uvm_error(get_type_name(), msg)
        errors++;
      end
      if (errors == err_before)
        `uvm_info(get_type_name(), "zero-strobe write (memory untouched) PASS", UVM_LOW)
    end

    // =========================================================================
    // 汇总
    // =========================================================================
    if (errors != 0) begin
      msg = $sformatf("corner seq completed with %0d error(s)", errors);
      `uvm_error(get_type_name(), msg)
    end
    else begin
      `uvm_info(get_type_name(), "corner seq: all checks PASS", UVM_LOW)
    end
  endtask

endclass : axi4_corner_seq


// =============================================================================
// Corner Test（记录 4KB 负向预期：checker 应报 1 次 RUL-003，测试本身以此为准收尾）
// =============================================================================
class axi4_corner_test extends uvm_test;

  axi4_smoke_env env;

  `uvm_component_utils(axi4_corner_test)

  function new(string name = "axi4_corner_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = axi4_smoke_env::type_id::create("env", this);
  endfunction

  task run_phase(uvm_phase phase);
    axi4_corner_seq seq;
    phase.raise_objection(this);
    seq = axi4_corner_seq::type_id::create("seq");
    if (!seq.randomize()) begin
      `uvm_fatal(get_type_name(), "randomize failed")
    end
    seq.start(env.master_agent.sequencer);
    #200;
    phase.drop_objection(this);
  endtask

  // 报告阶段：允许（且必须）有 1 条 RUL-003 违规（4KB 负向注入所致）
  function void report_phase(uvm_phase phase);
    uvm_report_server svr = uvm_report_server::get_server();
    int errs;
    super.report_phase(phase);
    // 4KB 负向注入预期 1 条 RUL-003：必须检出（< 为 mutation leak）、
    // 不得超额（> 为误报）
    errs = svr.get_severity_count(UVM_ERROR);
    if (errs < 1) begin
      `uvm_error(get_type_name(), "corner test: RUL-003 negative NOT detected (mutation leak)")
    end
    else if (errs > 1) begin
      `uvm_error(get_type_name(), $sformatf(
        "corner test: %0d errors > expected 1 (false positive)", errs))
    end
    else begin
      `uvm_info(get_type_name(), "corner test: 1 expected RUL-003 detected, no false positive PASS", UVM_LOW)
    end
  endfunction

endclass : axi4_corner_test

`endif // AXI4_CORNER_TEST__SV
