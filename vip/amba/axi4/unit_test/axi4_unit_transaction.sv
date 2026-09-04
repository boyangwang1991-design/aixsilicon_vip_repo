// =============================================================================
// File Name   : axi4_unit_transaction.sv
// Description : L1 Unit Test — axi4_item（字段默认值 / constraint / compare /
//               semantic helper 一致性）+ axi4_configuration（profile 展开/
//               legality）+ violation injector 纯判定
// =============================================================================
`ifndef AXI4_UNIT_TRANSACTION__SV
`define AXI4_UNIT_TRANSACTION__SV

import axi4_unit_test_pkg::*;
import axi4_types_pkg::*;

module axi4_unit_transaction;

  import axi4_pkg::*;

  initial begin
    axi4_master_item    it1, it2;
    axi4_configuration  cfg;

    // ------------------------------------------------------------------
    // 1. item 字段默认值（REQ-TRN-001）
    // ------------------------------------------------------------------
    it1 = axi4_master_item::type_id::create("it1");
    check_int("item_default_len",   it1.burst_length, 1);
    check_int("item_default_size",  it1.burst_size, 4);
    check_bit("item_default_burst", bit'(it1.burst_type == AXI4_INCREMENTING_BURST), 1'b1);
    check_bit("item_default_lock",  bit'(it1.lock == AXI4_NORMAL_LOCK), 1'b1);
    check_bit("item_default_has_resp", it1.has_response, 1'b1);

    // 2. constraint：legal randomize + data/strobe 长度一致
    if (!it1.randomize() with { burst_length == 5; burst_size == 4; }) begin
      $display("FAILED: item_randomize_legal");
      FAIL_CNT++;
    end
    else begin
      check_int("item_cons_data_size",  it1.data.size(), 5);
      check_int("item_cons_strobe_size",it1.strobe.size(), 5);
    end

    // 3. derive_fields + semantic helper 一致性（is_aligned/boundary/beat）
    it2 = axi4_master_item::type_id::create("it2");
    void'(it2.randomize() with {
      access_type == AXI4_WRITE_ACCESS;
      address == 32'h00FFFC;
      burst_length == 4;
      burst_size == 4;
      burst_type == AXI4_INCREMENTING_BURST;
    });
    it2.derive_fields(4);
    check_bit("item_boundary_cross", it2.boundary_crossing, 1'b1);
    check_bit("item_aligned_flag", it2.aligned, 1'b1);  // 0xFFFC % 4 == 0 → aligned
    check_addr("item_beat_addr1", it2.get_beat_address(1), 32'h010000);
    check_int("item_payload", it2.get_payload_size(), 16);

    // 4. axi4_compare：字段级比较（REQ-TRN-001；copy 后改字段判定差异）
    it1 = axi4_master_item::type_id::create("it1");
    void'(it1.randomize() with { address == 32'h1000; burst_length == 2; burst_size == 4; });
    it2 = axi4_master_item::type_id::create("it2");
    it2.copy(it1);
    check_bit("item_compare_equal", it2.axi4_compare(it1), 1'b1);
    it2.address = 32'h1004;
    check_bit("item_compare_diff_addr", it2.axi4_compare(it1), 1'b0);

    // ------------------------------------------------------------------
    // 5. axi4_configuration：profile 展开 + legality（REQ-VER-003）
    // ------------------------------------------------------------------
    cfg = axi4_configuration::get_axi4_profile();
    check_bit("cfg_axi4_protocol", bit'(cfg.protocol == AXI4_PROTOCOL), 1'b1);
    check_int("cfg_axi4_maxlen", cfg.max_burst_length, 256);
    cfg = axi4_configuration::get_axi4lite_profile();
    check_bit("cfg_lite_protocol", bit'(cfg.protocol == AXI4LITE_PROTOCOL), 1'b1);
    check_int("cfg_lite_id_width", cfg.id_width, 0);
    check_int("cfg_lite_maxlen", cfg.max_burst_length, 1);
    check_int("cfg_lite_dataw", cfg.data_width, 32);

    // P2 回归：手工 new + 赋值（不 randomize）时 default_*ready 必须为 1。
    // 修复前 soft 约束仅 randomize 生效，new() 不赋初值 → 0 → B/R 通道
    // ready 恒低、永远握不上（x2p 集成读响应挂死根因）。
    begin
      axi4_configuration c;
      c = axi4_configuration::type_id::create("c_new_no_randomize");
      check_bit("cfg_new_default_awready", c.default_awready, 1'b1);
      check_bit("cfg_new_default_wready",  c.default_wready,  1'b1);
      check_bit("cfg_new_default_bready",  c.default_bready,  1'b1);
      check_bit("cfg_new_default_arready", c.default_arready, 1'b1);
      check_bit("cfg_new_default_rready",  c.default_rready,  1'b1);
    end

    // ------------------------------------------------------------------
    // 6. violation injector 纯判定（should_inject 概率边界 + inject 修改）
    // ------------------------------------------------------------------
    begin
      // injector 是 uvm_component：unit 上下文用 new 直接构造（无 UVM 树）
      axi4_violation_injector inj;
      axi4_master_item it;
      inj = new("inj", null);
      inj.cfg = axi4_configuration::type_id::create("inj_cfg");
      void'(inj.cfg.randomize());
      inj.injection_enabled = 0;
      check_bit("inj_disabled", inj.should_inject(), 1'b0);
      inj.injection_enabled = 1;
      inj.injection_probability = 0;
      check_bit("inj_prob0", inj.should_inject(), 1'b0);
      inj.injection_probability = 100;
      check_bit("inj_prob100", inj.should_inject(), 1'b1);
      // count 耗尽判定需先成功注入一次（type 必须设置，NONE 不计数）
      inj.injection_count = 1;
      inj.injection_type = AXI4_INJ_ILLEGAL_WSTRB;
      it = axi4_master_item::type_id::create("it_pre");
      void'(it.randomize() with { burst_length == 2; burst_size == 4; });
      check_bit("inj_first_applied", inj.inject(it), 1'b1);
      check_bit("inj_count_exhausted", inj.should_inject(), 1'b0);
      // CROSS_4KB 注入确实把地址推过 4KB（对合法 item 注入后 checker 可检出）
      it = axi4_master_item::type_id::create("it");
      void'(it.randomize() with {
        address == 32'h2000; burst_length == 4; burst_size == 4;
        burst_type == AXI4_INCREMENTING_BURST; lock == AXI4_NORMAL_LOCK;
      });
      inj = new("inj2", null);
      inj.cfg = axi4_configuration::type_id::create("inj2_cfg");
      void'(inj.cfg.randomize());
      inj.injection_enabled = 1;
      inj.injection_probability = 100;
      inj.injection_type = AXI4_INJ_CROSS_4KB;
      check_bit("inj_cross4kb_applied", inj.inject(it), 1'b1);
      check_bit("inj_cross4kb_result", axi4_types_pkg::is_crossing_4kb(it.address, it.burst_length, it.burst_size), 1'b1);
    end

    $display("transaction/config/policy: PASS=%0d FAIL=%0d", PASS_CNT, FAIL_CNT);
  end

endmodule : axi4_unit_transaction

`endif // AXI4_UNIT_TRANSACTION__SV
