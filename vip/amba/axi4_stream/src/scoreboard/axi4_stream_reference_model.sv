// =============================================================================
// File Name   : axi4_stream_reference_model.sv
// Description : axi4_stream 参考模型接口（CUSTOM 比较模式的用户扩展点）
// 依据        : docs/requirement.md（REQ-SCB-001 CUSTOM, REQ-SCB-005 路由合同,
//               REQ-SCB-007 不得用同一 driver 缓存充当 oracle）
//
// 设计说明：
//   * 本类只定义 CUSTOM 模式契约：由用户提供 expected packet 序列，通用匹配
//     组件消费。默认实现是恒等（transparent），必须被显式配置为非透明转换使用。
//   * 参考模型不使用被测 VIP 的同一规范化函数生成 oracle（REQ-VAL-002），
//     用户提供的 expected 由手工/独立实现产生。
// =============================================================================

`ifndef AXI4_STREAM_REFERENCE_MODEL__SV
`define AXI4_STREAM_REFERENCE_MODEL__SV

class axi4_stream_reference_model extends uvm_object;

  `uvm_object_utils(axi4_stream_reference_model)

  // 源端口 -> stream key 映射（REQ-SCB-005）
  protected bit                        port_remap_enable = 1'b0;
  protected int                        source_port_of_key[int];
  protected bit                        rewrite_tid = 1'b0;
  protected bit                        rewrite_tdest = 1'b0;

  function new(string name = "axi4_stream_reference_model");
    super.new(name);
  endfunction

  // ---------------------------------------------------------------------------
  // CUSTOM 扩展点：把输入包映射为 expected 输出包
  // 默认恒等（transparent）。非透明 DUT 必须覆盖本函数或显式配置 drop/replicate
  // 与 mapping 合同（REQ-SCB-005/006）。
  // ---------------------------------------------------------------------------
  virtual function void predict(
    axi4_stream_observed_packet input_pkt,
    ref axi4_stream_observed_packet expected[$]
  );
    axi4_stream_observed_packet pkt;
    pkt = axi4_stream_observed_packet::type_id::create("predicted");
    pkt.key          = input_pkt.key;
    pkt.interface_id = input_pkt.interface_id;
    pkt.reset_epoch  = input_pkt.reset_epoch;
    foreach (input_pkt.beats[i]) pkt.beats.push_back(input_pkt.beats[i]);
    pkt.data_byte_count     = input_pkt.data_byte_count;
    pkt.position_byte_count = input_pkt.position_byte_count;
    pkt.null_byte_count     = input_pkt.null_byte_count;
    pkt.end_kind            = input_pkt.end_kind;
    // 若配置了显式路由重写，则按合同映射 key（不进行任意 payload 搜索）
    if (rewrite_tid || rewrite_tdest) pkt.key = remap_key(input_pkt.key);
    expected.push_back(pkt);
  endfunction

  // 显式路由合同（REQ-SCB-005）：禁止“任意搜索一个匹配 payload”
  function void set_route_remap(int source_port, int key_tid, bit rw_tid, bit rw_dest);
    port_remap_enable = 1'b1;
    source_port_of_key[key_tid] = source_port;
    rewrite_tid  = rw_tid;
    rewrite_tdest = rw_dest;
  endfunction

  function stream_key_t remap_key(stream_key_t k);
    stream_key_t out;
    out = k;
    if (rewrite_tid && port_remap_enable && source_port_of_key.exists(k.tid))
      out.tid = source_port_of_key[k.tid];
    return out;
  endfunction

  // 校验路由合同是否足以消歧（REQ-SCB-005）
  function bit route_contract_complete(int key_count, int port_count);
    if (key_count <= 1 || !rewrite_tid) return 1'b1;
    // 不同输入使用相同 key 且输出无法区分时，必须由仲裁/重写合同消歧
    return port_remap_enable && (port_count > 1);
  endfunction

endclass : axi4_stream_reference_model

`endif // AXI4_STREAM_REFERENCE_MODEL__SV
