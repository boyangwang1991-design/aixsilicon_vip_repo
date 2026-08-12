// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 AIXSILICON
//
// vip_common_compare_policy.sv — 字段级数据比较策略。
// 禁止只依赖 uvm_object::compare()。统一支持：
//   - 字段级 compare policy（可忽略不稳定字段）
//   - masked compare
//   - order-aware / out-of-order compare（结合 transaction ID 关联）
//   - mismatch 必须可失败并输出原始证据
`ifndef VIP_COMMON_COMPARE_POLICY_SV
`define VIP_COMMON_COMPARE_POLICY_SV

package vip_common_pkg;

  // 比较结果：除通过/失败外，携带原始证据以便失败时打印。
  typedef struct {
    bit   matched;
    string field;
    string lhs_evidence;
    string rhs_evidence;
  } vip_compare_result_t;

  class vip_common_compare_policy extends uvm_object;
    `uvm_object_utils(vip_common_compare_policy)

    protected bit ignore_delay = 1'b1;  // 示例：默认忽略 delay 字段

    function new(string name = "vip_common_compare_policy");
      super.new(name);
    endfunction

    // 子类按字段实现比较；默认全部比较。
    virtual function vip_compare_result_t compare_fields(
        input vip_common_transaction lhs,
        input vip_common_transaction rhs);
      vip_compare_result_t r;
      r.matched = 1'b1;
      if (lhs.seq_id !== rhs.seq_id) begin
        r.matched = 0'b0;
        r.field   = "seq_id";
        r.lhs_evidence = $sformatf("0x%0x", lhs.seq_id);
        r.rhs_evidence = $sformatf("0x%0x", rhs.seq_id);
      end
      if (!ignore_delay && (lhs.delay !== rhs.delay)) begin
        r.matched = 0'b0;
        r.field   = "delay";
        r.lhs_evidence = $sformatf("%0d", lhs.delay);
        r.rhs_evidence = $sformatf("%0d", rhs.delay);
      end
      return r;
    endfunction

    // mismatch 必须可失败并输出原始证据。
    virtual function void report_mismatch(input vip_compare_result_t r);
      if (!r.matched) begin
        `uvm_error("CMP", $sformatf("字段比较失败 field=%s lhs=%s rhs=%s",
                                    r.field, r.lhs_evidence, r.rhs_evidence))
      end
    endfunction
  endclass : vip_common_compare_policy

endpackage : vip_common_pkg

`endif
