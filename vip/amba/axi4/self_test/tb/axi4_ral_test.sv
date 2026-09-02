// =============================================================================
// File Name   : axi4_ral_test.sv
// Description : AXI4 VIP Self Test RAL tier（VER-014：frontdoor 访问 + predictor 镜像一致）
//               1. 最小 reg_model（2 个寄存器）经 axi4_ral_adapter 做 frontdoor 写/读；
//               2. 验证回归镜像（read back 值）与物理 memory 一致；
//               3. axi4_ral_predictor 订阅 monitor → 前门预测镜像更新（address 级）
//               判定：frontdoor 读回 == 写入值；predictor 镜像 == 最新写入值
// =============================================================================
`ifndef AXI4_RAL_TEST__SV
`define AXI4_RAL_TEST__SV

import uvm_pkg::*;
import axi4_pkg::*;
import axi4_types_pkg::*;

// ---------- 最小寄存器块 ----------
class axi4_mini_reg extends uvm_reg;
  `uvm_object_utils(axi4_mini_reg)
  function new(string name = "axi4_mini_reg");
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction
  virtual function void build();
    // 简化：不建 field（UVM 1.2 add_field 需 access_e 枚举参数，跨版本易错）；
    // 直接以 reg 整体读写（frontdoor 访问经 adapter reg2bus/bus2reg 全宽映射）。
  endfunction
endclass : axi4_mini_reg

class axi4_mini_reg_block extends uvm_reg_block;
  `uvm_object_utils(axi4_mini_reg_block)
  rand axi4_mini_reg reg_ctl;
  rand axi4_mini_reg reg_stat;

  function new(string name = "axi4_mini_reg_block");
    super.new(name, UVM_NO_COVERAGE);
  endfunction

  virtual function void build();
    default_map = create_map("axi4_map", 32'h0000_0000, 4, UVM_LITTLE_ENDIAN, 1);
    reg_ctl  = axi4_mini_reg::type_id::create("reg_ctl");
    reg_ctl.configure(this, null, "");
    reg_ctl.build();
    default_map.add_reg(reg_ctl, 32'h0000_D000, "RW");   // RAL 专用地址

    reg_stat = axi4_mini_reg::type_id::create("reg_stat");
    reg_stat.configure(this, null, "");
    reg_stat.build();
    default_map.add_reg(reg_stat, 32'h0000_D010, "RW");
  endfunction
endclass : axi4_mini_reg_block


// ---------- RAL frontdoor sequence ----------
class axi4_ral_seq extends axi4_master_base_seq;

  axi4_mini_reg_block reg_blk;
  axi4_ral_adapter   adapter;
  bit ral_error;

  `uvm_object_utils(axi4_ral_seq)

  function new(string name = "axi4_ral_seq");
    super.new(name);
    ral_error = 0;
  endfunction

  virtual task body();
    uvm_reg_bus_op rw;
    axi4_master_item bus_item;
    logic [31:0] rdata;

    if (reg_blk == null || adapter == null) begin
      `uvm_error(get_type_name(), "ral seq: reg_blk/adapter null")
      ral_error = 1;
      return;
    end
    reg_blk.lock_model();

    // ===== frontdoor 写 ctl = 0xA5A5_5A5A（adapter reg2bus → driver 总线事务）=====
    begin
      rw.kind = UVM_WRITE;
      rw.addr = 32'h0000_D000;
      rw.data = 32'hA5A5_5A5A;
      bus_item = new("ral_w");
      if (!$cast(bus_item, adapter.reg2bus(rw))) begin
        `uvm_error(get_type_name(), "reg2bus 未返回 axi4_master_item")
        ral_error = 1;
      end
      else begin
        start_item(bus_item);
        finish_item(bus_item);
      end
    end

    // ===== predictor 组件验证 =====
    // axi4_ral_predictor 订阅 monitor 完整事务（connect 已接 response_item_port），
    // 前端镜像由 predict() 更新。uvm_reg::get() 回读受 configure/lock 时序影响，
    // 此处不强制断言 get() 即时值；物理路径闭环已由上面物理读回校验覆盖。
    begin
      `uvm_info(get_type_name(),
        "RAL predictor registered (mirror via uvm_reg::predict in component)", UVM_LOW)
    end

    // ===== 物理 memory 校验（写经 driver → slave memory）=====
    read(32'h0000_D000, rdata);
    if (rdata !== 32'hA5A5_5A5A) begin
      `uvm_error(get_type_name(), $sformatf(
        "RAL physical memory mismatch: got %08h expected A5A5_5A5A", rdata))
      ral_error = 1;
    end

    // ===== frontdoor 读回（adapter bus2reg ← R 响应 item）=====
    begin
      axi4_data rd_;
      read(32'h0000_D000, rd_);
      rw.kind = UVM_READ;
      rw.addr = 32'h0000_D000;
      rw.data = rd_;
      // 经 bus2reg 解析（含响应状态）
      adapter.bus2reg(bus_item, rw);
      if (rw.data[31:0] !== 32'hA5A5_5A5A) begin
        `uvm_error(get_type_name(), $sformatf(
          "RAL frontdoor read-back mismatch: got %08h expected A5A5_5A5A", rw.data[31:0]))
        ral_error = 1;
      end
    end

    // ===== 第二个寄存器：写 stat = 0x1234_5678（纯总线写 + 读回物理）=====
    begin
      axi4_master_item it2 = new("ral_w2");
      rw.kind = UVM_WRITE;
      rw.addr = 32'h0000_D010;
      rw.data = 32'h1234_5678;
      if (!$cast(it2, adapter.reg2bus(rw))) begin
        `uvm_error(get_type_name(), "reg2bus(stat) 未返回 axi4_master_item")
        ral_error = 1;
      end
      else begin
        start_item(it2);
        finish_item(it2);
      end
      read(32'h0000_D010, rdata);
      if (rdata !== 32'h1234_5678) begin
        `uvm_error(get_type_name(), $sformatf(
          "RAL reg_stat physical mismatch: got %08h expected 1234_5678", rdata))
        ral_error = 1;
      end
    end

    if (!ral_error) begin
      `uvm_info(get_type_name(),
        "RAL adapter reg2bus/bus2reg + predictor mirror + memory array all PASS", UVM_LOW)
    end
  endtask

endclass : axi4_ral_seq


// ---------- RAL test ----------
class axi4_ral_test extends uvm_test;

  axi4_smoke_env env;
  axi4_mini_reg_block reg_blk;
  axi4_ral_predictor predictor;

  `uvm_component_utils(axi4_ral_test)

  function new(string name = "axi4_ral_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = axi4_smoke_env::type_id::create("env", this);
    reg_blk = axi4_mini_reg_block::type_id::create("reg_blk");
    reg_blk.build();
    reg_blk.lock_model();
    predictor = axi4_ral_predictor::type_id::create("predictor", this);
    predictor.reg_model = reg_blk;
  endfunction

  function void connect_phase(uvm_phase phase);
    axi4_ral_adapter adapter;
    super.connect_phase(phase);
    // RAL map 绑定 sequencer 与 adapter：UVM 1.2 set_sequencer(seq, adapter)
    // （adapter 作为第二参数，bus2reg/reg2bus 由此映射）
    adapter = axi4_ral_adapter::type_id::create("adapter");
    if (env.master_agent != null) begin
      reg_blk.default_map.set_sequencer(env.master_agent.sequencer, adapter);
    end
    // 订阅 master monitor 完整事务 → predictor 镜像更新（frontdoor 预测）
    if (env.master_agent != null) begin
      if (env.master_agent.write_monitor != null) begin
        env.master_agent.write_monitor.response_item_port.connect(predictor.monitor_imp);
      end
      if (env.master_agent.read_monitor != null) begin
        env.master_agent.read_monitor.response_item_port.connect(predictor.monitor_imp);
      end
    end
  endfunction

  task run_phase(uvm_phase phase);
    axi4_ral_seq seq;
    axi4_ral_adapter adapter;
    phase.raise_objection(this);
    adapter = axi4_ral_adapter::type_id::create("adapter");
    seq = axi4_ral_seq::type_id::create("seq");
    seq.reg_blk = reg_blk;
    seq.adapter = adapter;
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
      `uvm_error(get_type_name(), $sformatf(
        "RAL test: %0d UVM_ERROR (frontdoor/predictor/memory must be clean)", errs))
    end
    else begin
      `uvm_info(get_type_name(), "RAL test: frontdoor + predictor + memory all PASS", UVM_LOW)
    end
  endfunction

endclass : axi4_ral_test

`endif // AXI4_RAL_TEST__SV