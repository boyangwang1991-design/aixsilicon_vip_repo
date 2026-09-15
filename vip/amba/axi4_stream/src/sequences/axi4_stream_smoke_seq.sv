// =============================================================================
// File Name   : axi4_stream_smoke_seq.sv
// Description : axi4_stream 最小正向序列（开箱即用的最小可运行事务）
// 依据        : docs/requirement.md（REQ-SEQ-001 第 1 组：单 beat/单字节/单包）
//
// 说明：真正的场景序列库在 axi4_stream_base_seq.sv；本文件保留模板路径名，
// 提供一个最小可用序列，便于用户直接 start() 验证环境是否打通。
// =============================================================================

`ifndef AXI4_STREAM_SMOKE_SEQ__SV
`define AXI4_STREAM_SMOKE_SEQ__SV

class axi4_stream_smoke_seq extends axi4_stream_base_seq;

  `uvm_object_utils(axi4_stream_smoke_seq)

  function new(string name = "axi4_stream_smoke_seq");
    super.new(name);
  endfunction

  task body();
    byte unsigned b[$];
    b.push_back(8'h5a);
    `uvm_info(get_type_name(), "smoke: 发送单字节单 beat 包", UVM_LOW)
    send_bytes(b);
  endtask

endclass : axi4_stream_smoke_seq

`endif // AXI4_STREAM_SMOKE_SEQ__SV
