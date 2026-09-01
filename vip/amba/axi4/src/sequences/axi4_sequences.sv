// =============================================================================
// File Name   : axi4_sequences.sv
// Description : AXI4 Sequences（REQ-0108/0109）
//               - axi4_master_base_seq：base
//               - axi4_master_write_seq / axi4_master_read_seq
//               - axi4_master_access_seq（随机访问）
//               - axi4_slave_default_seq（slave 自动响应）
//               - axi4_smoke_seq（开箱即用基础序列）
// VLNV        : aixsilicon:vip:axi4:1.0.0
// =============================================================================

`ifndef AXI4_SEQUENCES__SV
`define AXI4_SEQUENCES__SV

// =============================================================================
// Master Base Sequence
// =============================================================================
class axi4_master_base_seq extends uvm_sequence #(axi4_master_item);

  axi4_configuration cfg;

  `uvm_object_utils(axi4_master_base_seq)
  `uvm_declare_p_sequencer(axi4_master_sequencer)

  function new(string name = "axi4_master_base_seq");
    super.new(name);
  endfunction

  virtual task pre_start();
    super.pre_start();
    if (p_sequencer != null) begin
      cfg = p_sequencer.cfg;
    end
  endtask

  // 高层 API（REQ-081）：单拍写
  virtual task write(axi4_address address, axi4_data data, axi4_strobe strobe = '1);
    axi4_master_item item = axi4_master_item::type_id::create("item");
    item.access_type = AXI4_WRITE_ACCESS;
    item.address     = address;
    item.burst_length = 1;
    item.burst_size   = cfg.data_width / 8;
    item.burst_type   = AXI4_INCREMENTING_BURST;
    item.data         = new[1];
    item.strobe       = new[1];
    item.data[0]      = data;
    item.strobe[0]    = strobe;
    start_item(item);
    finish_item(item);
  endtask

  // 高层 API（REQ-081）：单拍读
  virtual task read(axi4_address address, output axi4_data data);
    axi4_master_item item = axi4_master_item::type_id::create("item");
    item.access_type = AXI4_READ_ACCESS;
    item.address     = address;
    item.burst_length = 1;
    item.burst_size   = cfg.data_width / 8;
    item.burst_type   = AXI4_INCREMENTING_BURST;
    start_item(item);
    finish_item(item);
    data = (item.data.size() > 0) ? item.data[0] : '0;
  endtask

  // 高层 API（REQ-081）：burst 写
  virtual task burst_write(axi4_address address, axi4_data data[], axi4_strobe strobe[], int burst_len, int burst_sz = 0);
    axi4_master_item item = axi4_master_item::type_id::create("item");
    int size = (burst_sz > 0) ? burst_sz : (cfg.data_width / 8);
    item.access_type   = AXI4_WRITE_ACCESS;
    item.address       = address;
    item.burst_length  = burst_len;
    item.burst_size    = size;
    item.burst_type    = AXI4_INCREMENTING_BURST;
    item.data          = data;
    item.strobe        = strobe;
    start_item(item);
    finish_item(item);
  endtask

  // 高层 API（REQ-081）：burst 读
  virtual task burst_read(axi4_address address, int burst_len, int burst_sz, output axi4_data data[]);
    axi4_master_item item = axi4_master_item::type_id::create("item");
    int size = (burst_sz > 0) ? burst_sz : (cfg.data_width / 8);
    item.access_type   = AXI4_READ_ACCESS;
    item.address       = address;
    item.burst_length  = burst_len;
    item.burst_size    = size;
    item.burst_type    = AXI4_INCREMENTING_BURST;
    start_item(item);
    finish_item(item);
    data = item.data;
  endtask

endclass : axi4_master_base_seq


// =============================================================================
// Master Write Sequence
// =============================================================================
class axi4_master_write_seq extends axi4_master_base_seq;

  rand axi4_address address;
  rand axi4_data    data[];
  rand axi4_strobe  strobe[];
  rand int          burst_length;
  rand int          burst_size;
  rand axi4_burst_type burst_type;
  rand axi4_lock_type  lock;

  constraint c_write_legal {
    burst_size inside {1, 2, 4, 8, 16, 32};
    burst_type inside {AXI4_FIXED_BURST, AXI4_INCREMENTING_BURST, AXI4_WRAPPING_BURST};
    data.size()   == burst_length;
    strobe.size() == burst_length;
    soft lock     == AXI4_NORMAL_LOCK;
    // 突发长度合法性（REQ-PRO-004 / PRO-010）：
    //   INCR 1~256（此处上限 16）、FIXED 1~16、WRAP ∈{2,4,8,16}
    if (burst_type == AXI4_FIXED_BURST) {
      burst_length inside {[1:16]};
    }
    else if (burst_type == AXI4_WRAPPING_BURST) {
      burst_length inside {2, 4, 8, 16};
    }
    else {
      burst_length inside {[1:16]};
    }
    // 不跨 4KB（首末字节同一 4KB page；原公式对 unaligned 起始不充分）
    solve address before burst_size;
    solve burst_size before burst_length;
    ((address & 32'h0000_F000) ==
     ((address + (burst_length - 1) * burst_size) & 32'h0000_F000));
    // WRAP 起始地址对齐 wrap boundary（REQ-PRO-012）
    if (burst_type == AXI4_WRAPPING_BURST) {
      (address % (burst_size * burst_length)) == 0;
    }
  }

  `uvm_object_utils(axi4_master_write_seq)

  function new(string name = "axi4_master_write_seq");
    super.new(name);
    burst_length = 1;
    burst_size   = 4;
    burst_type   = AXI4_INCREMENTING_BURST;
    lock         = AXI4_NORMAL_LOCK;
  endfunction

  virtual task body();
    axi4_master_item item = axi4_master_item::type_id::create("item");
    item.access_type   = AXI4_WRITE_ACCESS;
    item.address       = address;
    item.burst_length  = burst_length;
    item.burst_size    = burst_size;
    item.burst_type    = burst_type;
    item.lock          = lock;
    item.data          = data;
    item.strobe        = strobe;
    start_item(item);
    finish_item(item);
  endtask

endclass : axi4_master_write_seq


// =============================================================================
// Master Read Sequence
// =============================================================================
class axi4_master_read_seq extends axi4_master_base_seq;

  rand axi4_address address;
  rand int          burst_length;
  rand int          burst_size;
  rand axi4_burst_type burst_type;
  rand axi4_lock_type  lock;

  constraint c_read_legal {
    burst_size inside {1, 2, 4, 8, 16, 32};
    burst_type inside {AXI4_FIXED_BURST, AXI4_INCREMENTING_BURST, AXI4_WRAPPING_BURST};
    soft lock == AXI4_NORMAL_LOCK;
    // 突发长度合法性（同 write：INCR 1~256、FIXED 1~16、WRAP ∈{2,4,8,16}）
    if (burst_type == AXI4_FIXED_BURST) {
      burst_length inside {[1:16]};
    }
    else if (burst_type == AXI4_WRAPPING_BURST) {
      burst_length inside {2, 4, 8, 16};
    }
    else {
      burst_length inside {[1:16]};
    }
    solve address before burst_size;
    solve burst_size before burst_length;
    // 不跨 4KB（首末字节同一 4KB page）
    ((address & 32'h0000_F000) ==
     ((address + (burst_length - 1) * burst_size) & 32'h0000_F000));
    // WRAP 起始地址对齐 wrap boundary（REQ-PRO-012）
    if (burst_type == AXI4_WRAPPING_BURST) {
      (address % (burst_size * burst_length)) == 0;
    }
  }

  `uvm_object_utils(axi4_master_read_seq)

  function new(string name = "axi4_master_read_seq");
    super.new(name);
    burst_length = 1;
    burst_size   = 4;
    burst_type   = AXI4_INCREMENTING_BURST;
    lock         = AXI4_NORMAL_LOCK;
  endfunction

  virtual task body();
    axi4_master_item item = axi4_master_item::type_id::create("item");
    item.access_type   = AXI4_READ_ACCESS;
    item.address       = address;
    item.burst_length  = burst_length;
    item.burst_size    = burst_size;
    item.burst_type    = burst_type;
    item.lock          = lock;
    start_item(item);
    finish_item(item);
  endtask

endclass : axi4_master_read_seq


// =============================================================================
// Master Access Sequence（随机访问）
// =============================================================================
class axi4_master_access_seq extends axi4_master_base_seq;

  rand int num_transactions;
  rand axi4_access_type access_type;

  constraint c_access_default {
    soft num_transactions == 10;
  }

  `uvm_object_utils(axi4_master_access_seq)

  function new(string name = "axi4_master_access_seq");
    super.new(name);
    num_transactions = 10;
    access_type      = AXI4_WRITE_ACCESS;
  endfunction

  virtual task body();
    repeat (num_transactions) begin
      if (access_type == AXI4_WRITE_ACCESS) begin
        axi4_master_write_seq seq = axi4_master_write_seq::type_id::create("seq");
        void'(seq.randomize());
        seq.start(m_sequencer);
      end
      else begin
        axi4_master_read_seq seq = axi4_master_read_seq::type_id::create("seq");
        void'(seq.randomize());
        seq.start(m_sequencer);
      end
    end
  endtask

endclass : axi4_master_access_seq


// =============================================================================
// Slave Default Sequence（自动响应；REQ-024）
// =============================================================================
class axi4_slave_default_seq extends uvm_sequence #(axi4_slave_item);

  axi4_configuration cfg;

  `uvm_object_utils(axi4_slave_default_seq)
  `uvm_declare_p_sequencer(axi4_slave_sequencer)

  function new(string name = "axi4_slave_default_seq");
    super.new(name);
  endfunction

  virtual task pre_start();
    super.pre_start();
    if (p_sequencer != null) begin
      cfg = p_sequencer.cfg;
    end
  endtask

  virtual task body();
    // Slave 响应由 slave_driver 自动处理（memory 读取 + B/R 驱动），
    // 本 sequence 仅确保 sequencer 上有响应项可用（驱动完整事务流）。
    forever begin
      axi4_slave_item item = axi4_slave_item::type_id::create("item");
      item.respond = 1;
      start_item(item);
      finish_item(item);
    end
  endtask

endclass : axi4_slave_default_seq


// =============================================================================
// Smoke Sequence（开箱即用：写读回环）
// =============================================================================
class axi4_smoke_seq extends axi4_master_base_seq;

  rand int num_transactions;

  constraint c_smoke_default {
    soft num_transactions == 8;
  }

  `uvm_object_utils(axi4_smoke_seq)

  function new(string name = "axi4_smoke_seq");
    super.new(name);
    num_transactions = 8;
  endfunction

  virtual task body();
    axi4_data rdata;
    for (int i = 0; i < num_transactions; i++) begin
      axi4_address addr = i * (cfg.data_width / 8);
      axi4_data    wdata = (i * 32'hA5A5_A5A5) & ((cfg.data_width == 32) ? 'hFFFFFFFF : 'hFFFF);
      write(addr, wdata);
      read(addr, rdata);
    end
  endtask

endclass : axi4_smoke_seq

`endif // AXI4_SEQUENCES__SV
