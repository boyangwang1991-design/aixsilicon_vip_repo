// =============================================================================
// File Name   : axi4_configuration.sv
// Description : AXI4 VIP 配置对象（自包含实现，替代 tvip_axi_configuration，
//               不依赖 tue/tvip-common；补齐本 Suite 扩展开关）
// VLNV        : aixsilicon:vip:axi4:1.0.0
// =============================================================================

`ifndef AXI4_CONFIGURATION__SV
`define AXI4_CONFIGURATION__SV

// -----------------------------------------------------------------------------
// 延迟配置类：固定延迟 / 随机范围延迟（替代 tue_delay_configuration）
//   delay_kind: 0=FIXED（delay_value 生效）, 1=RANDOM（delay_min/delay_max 内随机）
// -----------------------------------------------------------------------------
class axi4_delay_configuration extends uvm_object;

  rand bit  enabled;
  rand int  delay_kind;
  rand int  delay_value;
  rand int  delay_min;
  rand int  delay_max;

  constraint c_valid {
    delay_kind inside {[0:1]};
    delay_value >= 0;
    delay_min   >= 0;
    delay_max   >= 0;
    if (delay_kind == 1) {
      delay_max >= delay_min;
    }
  }

  constraint c_default {
    soft enabled     == 0;
    soft delay_kind  == 0;
    soft delay_value == 0;
    soft delay_min   == 0;
    soft delay_max   == 0;
  }

  function new(string name = "axi4_delay_configuration");
    super.new(name);
  endfunction

  // 返回本拍延迟（cycles）
  function int get_delay();
    int delay;
    if (!enabled) begin
      return 0;
    end
    if (delay_kind == 0) begin
      delay = delay_value;
    end
    else begin
      if (!std::randomize(delay) with { delay inside {[delay_min:delay_max]}; }) begin
        delay = delay_min;
      end
    end
    return delay;
  endfunction

  `uvm_object_utils_begin(axi4_delay_configuration)
    `uvm_field_int(enabled,    UVM_DEFAULT | UVM_BIN)
    `uvm_field_int(delay_kind, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(delay_value,UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(delay_min,  UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(delay_max,  UVM_DEFAULT | UVM_DEC)
  `uvm_object_utils_end

endclass : axi4_delay_configuration


// -----------------------------------------------------------------------------
// AXI4 配置对象（AXI4-REQ-040~059 + 0510~0513）
// -----------------------------------------------------------------------------
class axi4_configuration extends uvm_object;

  virtual axi4_if vif;

  // ---- 协议与位宽（§7.1）----
  rand axi4_protocol       protocol;
  rand int                 id_width;
  rand int                 address_width;
  rand int                 data_width;
  rand int                 strobe_width;
  rand int                 max_burst_length;

  // ---- 行为特性（§7.2）----
  rand axi4_ordering_mode  response_ordering;
  rand int                 outstanding_responses;
  rand bit                 enable_response_interleaving;
  rand int                 min_interleave_size;
  rand int                 max_interleave_size;
  rand int                 response_weight_okay;
  rand int                 response_weight_exokay;
  rand int                 response_weight_slave_error;
  rand int                 response_weight_decode_error;

  // ---- 时序/背压（§7.3）----
  rand axi4_delay_configuration request_start_delay;
  rand axi4_delay_configuration write_data_delay;
  rand axi4_delay_configuration response_start_delay;
  rand axi4_delay_configuration response_delay;
  rand bit                      default_awready;
  rand axi4_delay_configuration awready_delay;
  rand bit                      default_wready;
  rand axi4_delay_configuration wready_delay;
  rand bit                      default_bready;
  rand axi4_delay_configuration bready_delay;
  rand bit                      default_arready;
  rand axi4_delay_configuration arready_delay;
  rand bit                      default_rready;
  rand axi4_delay_configuration rready_delay;
  rand bit                      reset_by_agent;

  // ---- 本 Suite 扩展（§7.4）----
  rand bit                 enable_checker;
  rand bit                 enable_coverage;
  rand bit                 enable_error_injection;
  rand bit                 enable_timeout;
  rand int                 timeout_cycles;
  rand axi4_agent_mode     agent_mode;
  rand int                 transaction_log_verbosity;

  // ---- 扩展配置（§7.5）----
  rand int                 max_outstanding_read;
  rand int                 max_outstanding_write;
  rand int                 max_outstanding_per_id;
  rand bit                 exclusive_support;
  rand bit                 drive_awcache;
  rand bit                 drive_awprot;
  rand bit                 drive_awqos;
  rand bit                 drive_awregion;
  rand bit                 drive_aruser;
  rand axi4_constraint_mode random_constraint_mode;   // 注意：不能命名 constraint_mode（uvm_object 内置方法）

  // ---------------------------------------------------------------------------
  // 约束
  // ---------------------------------------------------------------------------
  constraint c_default_protocol {
    soft protocol == AXI4_PROTOCOL;
  }

  constraint c_valid_id_width {
    id_width inside {[0:`AXI4_MAX_ID_WIDTH]};
  }

  constraint c_default_id_width {
    solve protocol before id_width;
    if (protocol == AXI4LITE_PROTOCOL) {
      id_width == 0;
    }
    else {
      soft id_width == 8;
    }
  }

  constraint c_valid_address_width {
    address_width inside {[1:`AXI4_MAX_ADDRESS_WIDTH]};
  }

  constraint c_default_address_width {
    soft address_width == 32;
  }

  constraint c_valid_data_width {
    data_width inside {8, 16, 32, 64, 128, 256, 512, 1024};
    if (protocol == AXI4LITE_PROTOCOL) {
      data_width inside {32, 64};
    }
  }

  constraint c_default_data_width {
    soft data_width == 32;
  }

  constraint c_valid_strobe_width {
    solve data_width before strobe_width;
    strobe_width == (data_width / 8);
  }

  constraint c_valid_max_burst_length {
    solve protocol before max_burst_length;
    max_burst_length inside {[1:256]};
    if (protocol == AXI4LITE_PROTOCOL) {
      max_burst_length == 1;
    }
  }

  constraint c_default_max_burst_length {
    soft max_burst_length == 256;
  }

  constraint c_valid_response_ordering {
    solve protocol before response_ordering;
    if (protocol == AXI4LITE_PROTOCOL) {
      response_ordering == AXI4_IN_ORDER;
    }
  }

  constraint c_default_response_ordering {
    soft response_ordering == AXI4_OUT_OF_ORDER;
  }

  constraint c_valid_outstanding_responses {
    outstanding_responses >= 0;
  }

  constraint c_default_outstanding_responses {
    soft outstanding_responses == 0;
  }

  constraint c_default_enable_response_interleaving {
    soft enable_response_interleaving == 0;
  }

  constraint c_valid_interleave_size {
    min_interleave_size >= 0;
    max_interleave_size >= 0;
    max_interleave_size >= min_interleave_size;
    if (enable_response_interleaving == 0) {
      min_interleave_size == 0;
      max_interleave_size == 0;
    }
  }

  constraint c_valid_response_weight {
    response_weight_okay         >= -1;
    response_weight_exokay       >= -1;
    response_weight_slave_error  >= -1;
    response_weight_decode_error >= -1;
  }

  constraint c_default_response_weight {
    soft response_weight_okay         == -1;
    soft response_weight_exokay       == -1;
    soft response_weight_slave_error  == -1;
    soft response_weight_decode_error == -1;
  }

  constraint c_default_ready {
    soft default_awready == 1;
    soft default_wready  == 1;
    soft default_bready  == 1;
    soft default_arready == 1;
    soft default_rready  == 1;
  }

  constraint c_default_reset_by_agent {
    soft reset_by_agent == 0;
  }

  constraint c_default_suite_switches {
    soft enable_checker          == 1;
    soft enable_coverage         == 1;
    soft enable_error_injection  == 0;
    soft enable_timeout          == 0;
    soft timeout_cycles          == 10000;
    soft transaction_log_verbosity == UVM_MEDIUM;
    soft agent_mode              == AXI4_ACTIVE_MASTER;
  }

  constraint c_default_extended {
    soft max_outstanding_read   == 0;
    soft max_outstanding_write  == 0;
    soft max_outstanding_per_id == 0;
    soft exclusive_support      == 1;
    soft drive_awcache          == 1;
    soft drive_awprot           == 1;
    soft drive_awqos            == 1;
    soft drive_awregion         == 1;
    soft drive_aruser           == 0;
    soft random_constraint_mode == AXI4_LEGAL_ONLY;
  }

  // ---------------------------------------------------------------------------
  // 方法
  // ---------------------------------------------------------------------------
  function new(string name = "axi4_configuration");
    super.new(name);
    request_start_delay   = axi4_delay_configuration::type_id::create("request_start_delay");
    write_data_delay      = axi4_delay_configuration::type_id::create("write_data_delay");
    response_start_delay  = axi4_delay_configuration::type_id::create("response_start_delay");
    response_delay        = axi4_delay_configuration::type_id::create("response_delay");
    awready_delay         = axi4_delay_configuration::type_id::create("awready_delay");
    wready_delay          = axi4_delay_configuration::type_id::create("wready_delay");
    bready_delay          = axi4_delay_configuration::type_id::create("bready_delay");
    arready_delay         = axi4_delay_configuration::type_id::create("arready_delay");
    rready_delay          = axi4_delay_configuration::type_id::create("rready_delay");
    // P2 修复：默认握手位在 new() 直接赋 1（与 c_default_ready soft 约束一致）。
    // soft 约束仅在 randomize() 时生效；手工 new + 赋值（不 randomize）的接入方
    // （如 x2p）若不显式置位会得到 0 → B/R 通道 ready 恒低、永远握不上。
    default_awready = 1'b1;
    default_wready  = 1'b1;
    default_bready  = 1'b1;
    default_arready = 1'b1;
    default_rready  = 1'b1;
  endfunction

  function void post_randomize();
    super.post_randomize();
    response_weight_okay         = (response_weight_okay         >= 0) ? response_weight_okay         : 1;
    response_weight_exokay       = (response_weight_exokay       >= 0) ? response_weight_exokay       : 0;
    response_weight_slave_error  = (response_weight_slave_error  >= 0) ? response_weight_slave_error  : 0;
    response_weight_decode_error = (response_weight_decode_error >= 0) ? response_weight_decode_error : 0;
  endfunction

  // 预定义 Profile 帮助函数（REQ-083）
  static function axi4_configuration get_axi4_profile();
    axi4_configuration cfg = new("cfg");
    void'(cfg.randomize() with {
      protocol == AXI4_PROTOCOL;
    });
    return cfg;
  endfunction

  static function axi4_configuration get_axi4lite_profile();
    axi4_configuration cfg = new("cfg");
    void'(cfg.randomize() with {
      protocol == AXI4LITE_PROTOCOL;
    });
    return cfg;
  endfunction

  `uvm_object_utils_begin(axi4_configuration)
    `uvm_field_enum(axi4_protocol, protocol, UVM_DEFAULT)
    `uvm_field_int(id_width, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(address_width, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(data_width, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(strobe_width, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(max_burst_length, UVM_DEFAULT | UVM_DEC)
    `uvm_field_enum(axi4_ordering_mode, response_ordering, UVM_DEFAULT)
    `uvm_field_int(outstanding_responses, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(enable_response_interleaving, UVM_DEFAULT | UVM_BIN)
    `uvm_field_int(min_interleave_size, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(max_interleave_size, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(response_weight_okay, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(response_weight_exokay, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(response_weight_slave_error, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(response_weight_decode_error, UVM_DEFAULT | UVM_DEC)
    `uvm_field_object(request_start_delay, UVM_DEFAULT)
    `uvm_field_object(write_data_delay, UVM_DEFAULT)
    `uvm_field_object(response_start_delay, UVM_DEFAULT)
    `uvm_field_object(response_delay, UVM_DEFAULT)
    `uvm_field_int(default_awready, UVM_DEFAULT | UVM_BIN)
    `uvm_field_object(awready_delay, UVM_DEFAULT)
    `uvm_field_int(default_wready, UVM_DEFAULT | UVM_BIN)
    `uvm_field_object(wready_delay, UVM_DEFAULT)
    `uvm_field_int(default_bready, UVM_DEFAULT | UVM_BIN)
    `uvm_field_object(bready_delay, UVM_DEFAULT)
    `uvm_field_int(default_arready, UVM_DEFAULT | UVM_BIN)
    `uvm_field_object(arready_delay, UVM_DEFAULT)
    `uvm_field_int(default_rready, UVM_DEFAULT | UVM_BIN)
    `uvm_field_object(rready_delay, UVM_DEFAULT)
    `uvm_field_int(reset_by_agent, UVM_DEFAULT | UVM_BIN)
    `uvm_field_int(enable_checker, UVM_DEFAULT | UVM_BIN)
    `uvm_field_int(enable_coverage, UVM_DEFAULT | UVM_BIN)
    `uvm_field_int(enable_error_injection, UVM_DEFAULT | UVM_BIN)
    `uvm_field_int(enable_timeout, UVM_DEFAULT | UVM_BIN)
    `uvm_field_int(timeout_cycles, UVM_DEFAULT | UVM_DEC)
    `uvm_field_enum(axi4_agent_mode, agent_mode, UVM_DEFAULT)
    `uvm_field_int(transaction_log_verbosity, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(max_outstanding_read, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(max_outstanding_write, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(max_outstanding_per_id, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(exclusive_support, UVM_DEFAULT | UVM_BIN)
    `uvm_field_int(drive_awcache, UVM_DEFAULT | UVM_BIN)
    `uvm_field_int(drive_awprot, UVM_DEFAULT | UVM_BIN)
    `uvm_field_int(drive_awqos, UVM_DEFAULT | UVM_BIN)
    `uvm_field_int(drive_awregion, UVM_DEFAULT | UVM_BIN)
    `uvm_field_int(drive_aruser, UVM_DEFAULT | UVM_BIN)
    `uvm_field_enum(axi4_constraint_mode, random_constraint_mode, UVM_DEFAULT)
  `uvm_object_utils_end

endclass : axi4_configuration

`endif // AXI4_CONFIGURATION__SV
