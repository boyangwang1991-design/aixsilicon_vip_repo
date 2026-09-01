// =============================================================================
// File Name   : axi4_coverage.sv
// Description : AXI4 功能覆盖模型（uvm_subscriber；REQ-030 / §10）
//               四层覆盖：Feature / Field / Cross / Scenario
//               - SIZE × BUS_WIDTH × BURST_TYPE
//               - TYPE × RESPONSE
//               - WSTRB 形态（full/partial/edge/sparse）
//               - exclusive 交叉
// VLNV        : aixsilicon:vip:axi4:1.0.0
// =============================================================================

`ifndef AXI4_COVERAGE__SV
`define AXI4_COVERAGE__SV

class axi4_coverage extends uvm_subscriber #(axi4_item);

  axi4_configuration cfg;

  // 采样辅助
  axi4_item sampled_item;
  int  bus_bytes;

  `uvm_component_utils(axi4_coverage)

  function new(string name = "axi4_coverage", uvm_component parent = null);
    super.new(name, parent);
    sampled_item = null;
    bus_bytes = 4;
    cg_access_type    = new();
    cg_burst          = new();
    cg_strobe         = new();
    cg_exclusive      = new();
    cg_type_response  = new();
    cg_size_bus_burst = new();
    cg_length_size    = new();
    cg_boundary       = new();
    cg_scenario       = new();
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(axi4_configuration)::get(this, "", "cfg", cfg)) begin
      `uvm_fatal(get_type_name(), "未找到 axi4_configuration cfg")
    end
    bus_bytes = cfg.data_width / 8;
  endfunction

  function void write(axi4_item t);
    sampled_item = t;
    cg_access_type.sample();
    cg_burst.sample();
    cg_strobe.sample();
    cg_exclusive.sample();
    cg_type_response.sample();
    cg_size_bus_burst.sample();
    cg_length_size.sample();
    cg_boundary.sample();
    cg_scenario.sample();
  endfunction

  // ---------------------------------------------------------------------------
  // Feature / Field Coverage
  // ---------------------------------------------------------------------------

  // 访问类型
  covergroup cg_access_type;
    cp_access: coverpoint sampled_item.access_type {
      bins read  = {AXI4_READ_ACCESS};
      bins write = {AXI4_WRITE_ACCESS};
    }
  endgroup

  // 突发类型（REQ-003）
  covergroup cg_burst;
    cp_burst_type: coverpoint sampled_item.burst_type {
      bins fixed = {AXI4_FIXED_BURST};
      bins incr  = {AXI4_INCREMENTING_BURST};
      bins wrap  = {AXI4_WRAPPING_BURST};
    }
    cp_burst_length: coverpoint sampled_item.burst_length {
      bins len1   = {1};
      bins len2   = {2};
      bins len4   = {4};
      bins len8   = {8};
      bins len16  = {16};
      bins len256 = {256};
      bins other  = default;
    }
    cp_burst_size: coverpoint sampled_item.burst_size {
      bins size1  = {1};
      bins size2  = {2};
      bins size4  = {4};
      bins size8  = {8};
      bins size16 = {16};
      bins size64 = {64};
      bins other  = default;
    }
  endgroup

  // WSTRB 形态（REQ-0102）
  covergroup cg_strobe;
    cp_strobe_shape: coverpoint sampled_item.strobe[0] {
      bins full    = {4'b1111};
      bins partial = {4'b0001, 4'b0011, 4'b0111, 4'b1000, 4'b1100, 4'b1110};
      bins sparse  = {4'b0101, 4'b1010, 4'b1001, 4'b0110};
    }
  endgroup

  // Exclusive（REQ-0103）
  covergroup cg_exclusive;
    cp_lock: coverpoint sampled_item.lock {
      bins normal    = {AXI4_NORMAL_LOCK};
      bins exclusive = {AXI4_EXCLUSIVE_LOCK};
    }
  endgroup

  // ---------------------------------------------------------------------------
  // Cross Coverage
  // ---------------------------------------------------------------------------

  // TYPE × RESPONSE（REQ-019）
  covergroup cg_type_response;
    cp_access: coverpoint sampled_item.access_type;
    cp_response: coverpoint sampled_item.response[0] {
      bins okay  = {AXI4_OKAY};
      bins exok  = {AXI4_EXOKAY};
      bins slverr = {AXI4_SLAVE_ERROR};
      bins decerr = {AXI4_DECODE_ERROR};
    }
    cross cp_access, cp_response;
  endgroup

  // SIZE × BUS_WIDTH × BURST_TYPE（REQ-0100）
  covergroup cg_size_bus_burst;
    cp_size: coverpoint sampled_item.burst_size;
    cp_bus_bytes: coverpoint bus_bytes {
      bins b1   = {1};
      bins b2   = {2};
      bins b4   = {4};
      bins b8   = {8};
      bins b16  = {16};
      bins b32  = {32};
      bins other = default;
    }
    cp_burst: coverpoint sampled_item.burst_type;
    cross cp_size, cp_bus_bytes, cp_burst;
  endgroup

  // LENGTH × SIZE
  covergroup cg_length_size;
    cp_length: coverpoint sampled_item.burst_length;
    cp_size:   coverpoint sampled_item.burst_size;
    cross cp_length, cp_size;
  endgroup

  // ---------------------------------------------------------------------------
  // Scenario Coverage（§10.4）
  // ---------------------------------------------------------------------------

  covergroup cg_boundary;
    cp_boundary: coverpoint sampled_item.check_boundary() {
      bins no_cross = {0};
      bins cross_4kb = {1};
    }
  endgroup

  covergroup cg_scenario;
    cp_basic: coverpoint (sampled_item.burst_length == 1) {
      bins basic = {1};
      bins burst = {0};
    }
    cp_narrow: coverpoint (sampled_item.burst_size < bus_bytes) {
      bins full_width = {0};
      bins narrow     = {1};
    }
    cp_unaligned: coverpoint (sampled_item.is_aligned()) {
      bins aligned   = {1};
      bins unaligned = {0};
    }
  endgroup

  // ===========================================================================
  // 覆盖报告
  // ===========================================================================
  function void report_phase(uvm_phase phase);
    string cov_str;
    super.report_phase(phase);
    cov_str = $sformatf("access=%0.0f burst=%0.0f strobe=%0.0f exclusive=%0.0f type_resp=%0.0f size_bus_burst=%0.0f len_size=%0.0f boundary=%0.0f scenario=%0.0f",
      cg_access_type.get_coverage(), cg_burst.get_coverage(), cg_strobe.get_coverage(),
      cg_exclusive.get_coverage(), cg_type_response.get_coverage(), cg_size_bus_burst.get_coverage(),
      cg_length_size.get_coverage(), cg_boundary.get_coverage(), cg_scenario.get_coverage());
    `uvm_info(get_type_name(), cov_str, UVM_LOW)
  endfunction

endclass : axi4_coverage

`endif // AXI4_COVERAGE__SV
