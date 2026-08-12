// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 AIXSILICON
//
// vip_common_transaction.sv — 公共事务基类。
// 提供 pack/unpack、打印与 ID 关联能力；各协议事务由此扩展。
`ifndef VIP_COMMON_TRANSACTION_SV
`define VIP_COMMON_TRANSACTION_SV

package vip_common_pkg;

  class vip_common_transaction extends uvm_sequence_item;
    `uvm_object_utils(vip_common_transaction)

    rand int unsigned seq_id;       // 由 sequencer 分配的稳定 ID（用于 OOO / ID 关联比较）
    rand int unsigned delay;        // 相对随机延迟（cycle），由 driver 解释
    rand bit          error_inject; // 是否注入合法错误响应（由 agent policy 约束）

    constraint c_seq_id { seq_id inside {[0 : 2**16-1]}; }
    constraint c_delay  { delay   inside {[0 : 8]}; }

    function new(string name = "vip_common_transaction");
      super.new(name);
    endfunction

    virtual function string convert2string();
      return $sformatf("seq_id=%0d delay=%0d error=%b",
                       seq_id, delay, error_inject);
    endfunction

    // 字段级比较钩子：子类在此实现自定义比较（忽略不稳定字段、masked 等）。
    virtual function bit policy_compare(input vip_common_transaction rhs);
      return (this.seq_id == rhs.seq_id);
    endfunction
  endclass : vip_common_transaction

endpackage : vip_common_pkg

`endif
