// =============================================================================
// File Name   : apb_unit_types.sv
// Description : L1 Unit Test——types_pkg golden vectors（无 UVM 依赖）
//               覆盖：wait bucket / strb class / 对齐 / 位宽合法性 /
//               PAS space / parity grouping（CFG-003..005/CT-4）
// VLNV        : aixsilicon:vip:apb:1.0.0
// =============================================================================

`ifndef APB_UNIT_TYPES__SV
`define APB_UNIT_TYPES__SV

package apb_unit_types;

  import apb_types_pkg::*;

  int PASS_CNT = 0;
  int FAIL_CNT = 0;

  function void check_int(string case_id, int actual, int expected);
    if (actual !== expected) begin
      $display("FAILED: %s expected=%0d actual=%0d", case_id, expected, actual);
      FAIL_CNT++;
    end else PASS_CNT++;
  endfunction

  function void check_bit(string case_id, bit actual, bit expected);
    if (actual !== expected) begin
      $display("FAILED: %s expected=%0b actual=%0b", case_id, expected, actual);
      FAIL_CNT++;
    end else PASS_CNT++;
  endfunction

  // ---------------------------------------------------------------------------
  // wait bucket（CP-04）
  // ---------------------------------------------------------------------------
  task t_wait_bucket();
    check_int("wait_bucket_0",  apb_wait_bucket(0),  0);
    check_int("wait_bucket_1",  apb_wait_bucket(1),  1);
    check_int("wait_bucket_2",  apb_wait_bucket(2),  2);
    check_int("wait_bucket_4",  apb_wait_bucket(4),  2);
    check_int("wait_bucket_5",  apb_wait_bucket(5),  3);
    check_int("wait_bucket_15", apb_wait_bucket(15), 3);
    check_int("wait_bucket_16", apb_wait_bucket(16), 4);
    check_int("wait_bucket_100",apb_wait_bucket(100),4);
  endtask

  // ---------------------------------------------------------------------------
  // strb class（CP-06）
  // ---------------------------------------------------------------------------
  task t_strb_class();
    check_int("strb_none",   apb_strb_class(4'b0000, 32), 0);
    check_int("strb_full",   apb_strb_class(4'b1111, 32), 1);
    check_int("strb_single", apb_strb_class(4'b0010, 32), 2);
    check_int("strb_contig", apb_strb_class(4'b0110, 32), 3);
    check_int("strb_sparse", apb_strb_class(4'b0101, 32), 4);
    check_int("strb_sparse2",apb_strb_class(4'b1001, 32), 4);
  endtask

  // ---------------------------------------------------------------------------
  // 对齐（TRN-004）
  // ---------------------------------------------------------------------------
  task t_aligned();
    check_bit("align32_4",  apb_is_aligned('h1004, 32), 1'b1);
    check_bit("align32_2",  apb_is_aligned('h1002, 32), 1'b0);
    check_bit("align16_2",  apb_is_aligned('h1002, 16), 1'b1);
    check_bit("align8_any", apb_is_aligned('h1003, 8),  1'b1);
  endtask

  // ---------------------------------------------------------------------------
  // 位宽合法性（CFG-003/004）
  // ---------------------------------------------------------------------------
  task t_width_legal();
    check_bit("dw8",  apb_data_width_legal(8),  1'b1);
    check_bit("dw16", apb_data_width_legal(16), 1'b1);
    check_bit("dw32", apb_data_width_legal(32), 1'b1);
    check_bit("dw12", apb_data_width_legal(12), 1'b0);
    check_bit("dw64", apb_data_width_legal(64), 1'b0);
    check_bit("aw1",  apb_addr_width_legal(1),  1'b1);
    check_bit("aw32", apb_addr_width_legal(32), 1'b1);
    check_bit("aw33", apb_addr_width_legal(33), 1'b0);
    check_bit("aw0",  apb_addr_width_legal(0),  1'b0);
  endtask

  // ---------------------------------------------------------------------------
  // PAS space（CP-07 RME）
  // ---------------------------------------------------------------------------
  task t_pas_space();
    check_int("pas_secure",     apb_pas_space(1'b0, 1'b0), APB_PAS_SECURE);
    check_int("pas_non_secure", apb_pas_space(1'b0, 1'b1), APB_PAS_NON_SECURE);
    check_int("pas_root",       apb_pas_space(1'b1, 1'b0), APB_PAS_ROOT);
    check_int("pas_realm",      apb_pas_space(1'b1, 1'b1), APB_PAS_REALM);
  endtask

  // ---------------------------------------------------------------------------
  // parity grouping（CT-4/CFG-008）
  // ---------------------------------------------------------------------------
  task t_parity_group();
    // addr=32'h0000_00FF, width=32：group0=0xFF（8 位全 1）
    // 奇校验：组内 1 计数为 8（偶）→ check=1
    check_bit("pg_g0_ff", apb_parity_group(32'h0000_00FF, 0, 32), 1'b1);
    // group1=0x00（0 个 1，偶）→ check=1
    check_bit("pg_g1_00", apb_parity_group(32'h0000_00FF, 1, 32), 1'b1);
    // group2=0x01（1 个 1，奇）→ check=0
    check_bit("pg_g2_01", apb_parity_group(32'h0001_0000, 2, 32), 1'b0);
    // addr_width=12：group1 仅覆盖 addr[11:8]（4 位，末组）
    // addr=0x0F0 → group1=0xF（4 个 1，偶）→ check=1
    check_bit("pg_end_g1", apb_parity_group(12'h0F0, 1, 12), 1'b1);
    // addr_width=12：group0=addr[7:0]=0xF0（4 个 1，偶）→ check=1
    check_bit("pg_end_g0", apb_parity_group(12'h0F0, 0, 12), 1'b1);
  endtask

endpackage

// ---------------------------------------------------------------------------
// 独立执行入口（unit_tb 调用或单独 module 包装）
// ---------------------------------------------------------------------------
module apb_unit_types_exec;
  import apb_unit_types::*;
  initial begin
    t_wait_bucket();
    t_strb_class();
    t_aligned();
    t_width_legal();
    t_pas_space();
    t_parity_group();
  end
endmodule

`endif // APB_UNIT_TYPES__SV
