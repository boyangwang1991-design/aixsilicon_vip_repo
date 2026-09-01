// =============================================================================
// File Name   : axi4_violation_injector.sv
// Description : AXI4 协议违规注入器（REQ-057 / §11）
//               - 在合法 item 基础上生成 illegal 变体
//               - 支持 violation type：illegal_wrap_length / illegal_wstrb /
//                 cross_4kb / early_wlast / missing_wlast / unstable_awaddr /
//                 invalid_burst / invalid_id / invalid_response
//               - 与 axi4_checker 联动（Mutation 检测率，REQ-075）
// VLNV        : aixsilicon:vip:axi4:1.0.0
// =============================================================================

`ifndef AXI4_VIOLATION_INJECTOR__SV
`define AXI4_VIOLATION_INJECTOR__SV

typedef enum {
  AXI4_INJ_NONE,
  AXI4_INJ_ILLEGAL_WRAP_LENGTH,
  AXI4_INJ_ILLEGAL_WSTRB,
  AXI4_INJ_CROSS_4KB,
  AXI4_INJ_EARLY_WLAST,
  AXI4_INJ_MISSING_WLAST,
  AXI4_INJ_UNSTABLE_AWADDR,
  AXI4_INJ_INVALID_BURST,
  AXI4_INJ_INVALID_ID,
  AXI4_INJ_INVALID_RESPONSE
} axi4_violation_type;

class axi4_violation_injector extends uvm_component;

  axi4_configuration cfg;

  // 注入配置
  axi4_violation_type injection_type;
  bit                 injection_enabled;
  int                 injection_probability;   // 0-100
  int                 injection_count;         // 0 = 不限

  protected int injected_count;

  `uvm_component_utils(axi4_violation_injector)

  function new(string name = "axi4_violation_injector", uvm_component parent = null);
    super.new(name, parent);
    injection_type      = AXI4_INJ_NONE;
    injection_enabled   = 0;
    injection_probability = 0;
    injection_count     = 0;
    injected_count      = 0;
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(axi4_configuration)::get(this, "", "cfg", cfg)) begin
      `uvm_fatal(get_type_name(), "未找到 axi4_configuration cfg")
    end
  endfunction

  // 判断是否注入（概率 + 计数）
  function bit should_inject();
    if (!injection_enabled) begin
      return 0;
    end
    if ((injection_count > 0) && (injected_count >= injection_count)) begin
      return 0;
    end
    if (injection_probability >= 100) begin
      return 1;
    end
    if (injection_probability <= 0) begin
      return 0;
    end
    return (($urandom_range(0, 99)) < injection_probability);
  endfunction

  // 对合法 item 注入违规：返回是否修改了 item
  function bit inject(axi4_item item);
    if (!should_inject()) begin
      return 0;
    end
    case (injection_type)
      AXI4_INJ_ILLEGAL_WRAP_LENGTH: begin
        // WRAP 长度非法（如 3）
        item.burst_type   = AXI4_WRAPPING_BURST;
        item.burst_length = 3;
      end
      AXI4_INJ_ILLEGAL_WSTRB: begin
        // WSTRB 越界（全 0 且 burst_size>1）
        foreach (item.strobe[i]) begin
          item.strobe[i] = '0;
        end
      end
      AXI4_INJ_CROSS_4KB: begin
        // 构造跨 4KB 边界地址
        item.address = (item.address & 'hFFFFF000) + 4096 - item.burst_size;
      end
      AXI4_INJ_EARLY_WLAST: begin
        // early wlast：burst_length 缩短（由 checker/SVA 检测）
        item.burst_length = (item.burst_length > 1) ? item.burst_length - 1 : 1;
      end
      AXI4_INJ_MISSING_WLAST: begin
        // 缺失 wlast：burst_length 加长（WLAST 提前已驱动）
        item.burst_length = item.burst_length + 1;
      end
      AXI4_INJ_UNSTABLE_AWADDR: begin
        // 地址不稳定（握手前变化）——由 SVA 检测，事务级标记
        item.address = item.address + burst_size_of(item);
      end
      AXI4_INJ_INVALID_BURST: begin
        // 非法 burst 类型编码（保留位）
        item.burst_type = AXI4_WRAPPING_BURST;
        item.burst_length = 5;
      end
      AXI4_INJ_INVALID_ID: begin
        // 非法 ID（超出配置位宽）
        if (cfg.id_width < `AXI4_MAX_ID_WIDTH) begin
          item.id = axi4_id'('1 << cfg.id_width);
        end
      end
      AXI4_INJ_INVALID_RESPONSE: begin
        // 非法响应编码（超出 2bit 合法编码空间，置 X 触发检查）
        if (item.response.size() == 0) begin
          item.response = new[1];
        end
        item.response[0] = axi4_response'(2'b1x);
      end
      default: return 0;
    endcase
    injected_count++;
    return 1;
  endfunction

  protected function int burst_size_of(axi4_item item);
    return item.burst_size;
  endfunction

  function int get_injected_count();
    return injected_count;
  endfunction

endclass : axi4_violation_injector

`endif // AXI4_VIOLATION_INJECTOR__SV
