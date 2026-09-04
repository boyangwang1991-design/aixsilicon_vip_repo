// =============================================================================
// File Name   : apb_sequences.sv
// Description : Primitive sequences（REQ §6 STM-001..006）：
//               base / write / read / random / incrementing / error
// VLNV        : aixsilicon:vip:apb:1.0.0
// =============================================================================

`ifndef APB_SEQUENCES__SV
`define APB_SEQUENCES__SV

// ---------------------------------------------------------------------------
// STM-001 基类
// ---------------------------------------------------------------------------
class apb_base_sequence extends uvm_sequence #(apb_item);

  `uvm_object_utils(apb_base_sequence)

  apb_config cfg;   // 经 start_item 前由 env/agent 侧注入（或 set）

  function new(string name = "apb_base_sequence");
    super.new(name);
  endfunction

  // helper：单笔写
  task do_write(bit [`APB_MAX_ADDR_WIDTH-1:0] addr,
                bit [`APB_MAX_DATA_WIDTH-1:0] data,
                bit [`APB_MAX_DATA_WIDTH/8-1:0] strb = '1);
    apb_item it = apb_item::type_id::create("w_item");
    start_item(it);
    it.direction = APB_WRITE;
    it.addr      = addr;
    it.wdata     = data;
    it.strb      = strb;
    finish_item(it);
  endtask

  // helper：单笔读
  task do_read(bit [`APB_MAX_ADDR_WIDTH-1:0] addr,
               output bit [`APB_MAX_DATA_WIDTH-1:0] data,
               output bit slverr);
    apb_item it = apb_item::type_id::create("r_item");
    start_item(it);
    it.direction = APB_READ;
    it.addr      = addr;
    it.strb      = '0;   // RUL-006
    finish_item(it);
    data   = it.rdata;
    slverr = it.slverr;
  endtask

endclass

// ---------------------------------------------------------------------------
// STM-002 N 笔写
// ---------------------------------------------------------------------------
class apb_write_sequence extends apb_base_sequence;
  `uvm_object_utils(apb_write_sequence)

  int unsigned num_writes = 8;
  bit [`APB_MAX_ADDR_WIDTH-1:0] base_addr = 'h1000;

  function new(string name = "apb_write_sequence");
    super.new(name);
  endfunction

  virtual task body();
    for (int i = 0; i < num_writes; i++)
      do_write(base_addr + i*4, $urandom);
  endtask
endclass

// ---------------------------------------------------------------------------
// STM-003 N 笔读
// ---------------------------------------------------------------------------
class apb_read_sequence extends apb_base_sequence;
  `uvm_object_utils(apb_read_sequence)

  int unsigned num_reads = 8;
  bit [`APB_MAX_ADDR_WIDTH-1:0] base_addr = 'h1000;
  // 最近一笔读回值（P4 回归：ZERO_WAIT 读数据完整性校验用）
  bit [`APB_MAX_DATA_WIDTH-1:0] last_data = '0;

  function new(string name = "apb_read_sequence");
    super.new(name);
  endfunction

  virtual task body();
    bit [`APB_MAX_DATA_WIDTH-1:0] d;
    bit err;
    for (int i = 0; i < num_reads; i++) begin
      do_read(base_addr + i*4, d, err);
      last_data = d;
    end
  endtask
endclass

// ---------------------------------------------------------------------------
// STM-004 随机（addr/rw/data/strb/prot）
// ---------------------------------------------------------------------------
class apb_random_sequence extends apb_base_sequence;
  `uvm_object_utils(apb_random_sequence)

  int unsigned num_items = 16;
  bit [`APB_MAX_ADDR_WIDTH-1:0] addr_min = 'h1000;
  bit [`APB_MAX_ADDR_WIDTH-1:0] addr_max = 'h10FF;

  function new(string name = "apb_random_sequence");
    super.new(name);
  endfunction

  virtual task body();
    apb_item it;
    repeat (num_items) begin
      it = apb_item::type_id::create("rnd_item");
      start_item(it);
      if (!it.randomize() with {
        direction inside {APB_READ, APB_WRITE};
        addr inside {[addr_min:addr_max]};
      })
        `uvm_error(get_type_name(), "randomize failed")
      finish_item(it);
    end
  endtask
endclass

// ---------------------------------------------------------------------------
// STM-005 递增地址（burst-like pattern）
// ---------------------------------------------------------------------------
class apb_incrementing_sequence extends apb_base_sequence;
  `uvm_object_utils(apb_incrementing_sequence)

  int unsigned num_items = 8;
  bit [`APB_MAX_ADDR_WIDTH-1:0] start_addr = 'h1000;
  int unsigned step = 4;

  function new(string name = "apb_incrementing_sequence");
    super.new(name);
  endfunction

  virtual task body();
    bit [`APB_MAX_DATA_WIDTH-1:0] d;
    bit err;
    for (int i = 0; i < num_items; i++) begin
      if (i % 2 == 0) do_write(start_addr + i*step, $urandom);
      else            do_read(start_addr + (i-1)*step, d, err);
    end
  endtask
endclass

// ---------------------------------------------------------------------------
// STM-005b G4 coverage sweep（定向打遍 CP/CR bins）
//   - strb：10 种 PSTRB shape（CP-06/CR-04）——写事务 strb 类型
//   - prot：PPROT 8 值 × 读写（CP-05/CR-05）
//   - addr：low/mid/high 三区（CP-02）+ aligned/unaligned（CP-04b）
//   - direction：read/write（CP-01 CR-01/02/03/06）
//   - wait：随机 wait（env mode_cov_sweep 已 RANDOM_WAIT max=32 覆盖五桶 CP-04）
//   - slverr 区域：0x7000-0x7FFF（CP-03 APB_ERROR）
// ---------------------------------------------------------------------------
class apb_cov_sweep_sequence extends apb_base_sequence;
  `uvm_object_utils(apb_cov_sweep_sequence)

  int unsigned num_strb_shapes = 10;
  int unsigned num_prots       = 8;
  int unsigned num_addr_pairs  = 6;

  function new(string name = "apb_cov_sweep_sequence");
    super.new(name);
  endfunction

  virtual task body();
    bit [`APB_MAX_DATA_WIDTH-1:0] d;
    bit err;

    // ---------- PSTRB shapes（写）----------
    // 0x0 none / 0xF full / 0x1,0x2,0x4,0x8 single / 0x3,0x6,0xC contig / 0x5,0x9 sparse
    begin
      bit [3:0] shapes[10];
      shapes = '{4'h0, 4'hF, 4'h1, 4'h2, 4'h4, 4'h8, 4'h3, 4'h6, 4'hC, 4'h5};
      for (int i = 0; i < num_strb_shapes; i++)
        do_write('h1000 + i*4, $urandom, shapes[i]);
    end

    // ---------- PPROT（写 + 读各 8 值）----------
    for (int p = 0; p < num_prots; p++) begin
      apb_item it = apb_item::type_id::create("prot_item");
      start_item(it);
      it.direction = APB_WRITE;
      it.addr      = 'h2000 + p*4;
      it.wdata     = p;
      it.strb      = 'hF;
      it.prot      = apb_protection'(p);
      finish_item(it);
      // 读侧带相同 prot（CR-05 prot×dir 双侧覆盖）
      begin
        apb_item rit = apb_item::type_id::create("prot_ritem");
        start_item(rit);
        rit.direction = APB_READ;
        rit.addr      = 'h2000 + p*4;
        rit.strb      = '0;
        rit.prot      = apb_protection'(p);
        finish_item(rit);
      end
    end

    // ---------- 地址区域 low/mid/high + 对齐 ----------
    // low:0x0-, mid:0x4xxx, high:0x8xxx；aligned/unaligned 各半
    begin
      bit [`APB_MAX_ADDR_WIDTH-1:0] addrs[6];
      addrs = '{'h0100, 'h0101, 'h4000, 'h4002, 'h8000, 'h8001};
      for (int i = 0; i < num_addr_pairs; i++) begin
        do_write(addrs[i], $urandom, 'hF);
        do_read(addrs[i], d, err);
      end
    end

    // ---------- slverr 区域（0x7000-0x7FFF）：read + write（CR-02 dir×error）----------
    for (int i = 0; i < 4; i++)
      do_read('h7000 + i*4, d, err);
    for (int i = 0; i < 4; i++)
      do_write('h7000 + i*4, $urandom, 'hF);   // write→slverr（CR-02 write×error）

    // ---------- read-heavy wait 组合（CR-01 dir×wait）----------
    // 随机 wait 模式下连续多读，使 read×{w0,w1,w2_4,w5_15,w16+} 均命中
    for (int i = 0; i < 20; i++) begin
      apb_item it = apb_item::type_id::create("wait_read");
      start_item(it);
      it.direction = APB_READ;
      it.addr      = 'h2000 + (i*4);
      it.strb      = '0;
      finish_item(it);
    end

    // ---------- back-to-back 写读交替（CR-06 dir×pattern：READ×B2B/WRITE×B2B）
    // 无 start_delay（seq_item_delay_max=0）→ 连续 access 无 idle → B2B pattern
    for (int i = 0; i < 8; i++) begin
      do_write('h3000 + i*4, $urandom, 'hF);
      do_read('h3000 + i*4, d, err);
    end
  endtask
endclass

// ---------------------------------------------------------------------------
// STM-005c APB5 专项（UT13/14/20/21）：PAS bins / USER 三宽度 / WAKEUP / CHK
// ---------------------------------------------------------------------------
class apb_apb5_sequence extends apb_base_sequence;
  `uvm_object_utils(apb_apb5_sequence)

  function new(string name = "apb_apb5_sequence");
    super.new(name);
  endfunction

  virtual task body();
    bit [`APB_MAX_DATA_WIDTH-1:0] d;
    bit err;

    // UT20 RME-PNSE：PNSE×PPROT[1] → 4 PAS bins
    for (int pnse = 0; pnse <= 1; pnse++) begin
      for (int prot1 = 0; prot1 <= 1; prot1++) begin
        apb_item it = apb_item::type_id::create("pas_item");
        start_item(it);
        it.direction = APB_WRITE;
        it.addr      = 'h1000;
        it.wdata     = $urandom;
        it.strb      = 'hF;
        it.pnse      = pnse;
        it.prot.non_secure_access = prot1;
        finish_item(it);
        do_read('h1000, d, err);
      end
    end

    // UT13 USER 三宽度（PAUSER/WUSER/RUSER/BUSER）
    for (int i = 0; i < 8; i++) begin
      apb_item it = apb_item::type_id::create("user_item");
      start_item(it);
      it.direction = APB_WRITE;
      it.addr      = 'h2000 + i*4;
      it.wdata     = i;
      it.strb      = 'hF;
      it.auser     = i*8'h11;
      it.wuser     = i*8'h10;
      finish_item(it);
      do_read('h2000 + i*4, d, err);
    end

    // UT14 WAKEUP：交替 wakeup 0/1
    for (int i = 0; i < 4; i++) begin
      apb_item it = apb_item::type_id::create("wake_item");
      start_item(it);
      it.direction = APB_READ;
      it.addr      = 'h1000;
      it.wakeup    = i[0];
      finish_item(it);
    end

    // UT21 CHK 族（check_enable=1 下正常事务通过）
    for (int i = 0; i < 4; i++)
      do_read('h1004 + i*4, d, err);
  endtask
endclass

// ---------------------------------------------------------------------------
// STM-006 错误场景（配合 Completer ADDRESS_RANGE）
// ---------------------------------------------------------------------------
class apb_error_sequence extends apb_base_sequence;
  `uvm_object_utils(apb_error_sequence)

  bit [`APB_MAX_ADDR_WIDTH-1:0] err_base = 'h3000;
  bit [`APB_MAX_ADDR_WIDTH-1:0] err_limit = 'h3FFF;
  int unsigned num_items = 4;

  function new(string name = "apb_error_sequence");
    super.new(name);
  endfunction

  virtual task body();
    bit [`APB_MAX_DATA_WIDTH-1:0] d;
    bit err;
    for (int i = 0; i < num_items; i++) begin
      do_read(err_base + i*4, d, err);
      // 配置 slave_error_mode=ADDRESS_RANGE 且 region.slverr=1 时 err==1
    end
  endtask
endclass

`endif // APB_SEQUENCES__SV
