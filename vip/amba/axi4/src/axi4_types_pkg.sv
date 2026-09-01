// =============================================================================
// File Name   : axi4_types_pkg.sv
// Description : AXI4 VIP 类型/枚举/编解码（AXI4 / AXI4-Lite）
//               参考 tvip_axi_types_pkg（Apache-2.0），补齐 lock/exclusive/region。
// VLNV        : aixsilicon:vip:axi4:1.0.0
// HWIF        : aixsilicon:hwif:axi（IFC-AXI-001）—— 接口契约唯一来源
// =============================================================================

`ifndef AXI4_TYPES_PKG__SV
`define AXI4_TYPES_PKG__SV

// 最大位宽（与 tvip-axi 对齐；实例化位宽由 axi4_if 参数控制）
`define AXI4_MAX_ID_WIDTH      32
`define AXI4_MAX_ADDRESS_WIDTH 64
`define AXI4_MAX_DATA_WIDTH    1024

package axi4_types_pkg;

  typedef logic [`AXI4_MAX_ID_WIDTH-1:0]      axi4_id;
  typedef logic [`AXI4_MAX_ADDRESS_WIDTH-1:0] axi4_address;
  typedef logic [7:0]                         axi4_burst_length;  // AxLEN（0 = 1 beat）
  typedef logic [3:0]                         axi4_cache;
  typedef logic [3:0]                         axi4_qos;
  typedef logic [3:0]                         axi4_region;
  typedef logic [5:0]                         axi4_atop;
  typedef logic [`AXI4_MAX_DATA_WIDTH-1:0]    axi4_data;
  typedef logic [`AXI4_MAX_DATA_WIDTH/8-1:0]  axi4_strobe;

  // ---------------------------------------------------------------------------
  // 枚举
  // ---------------------------------------------------------------------------
  typedef enum logic [2:0] {
    AXI4_BURST_SIZE_1_BYTE    = 'b000,
    AXI4_BURST_SIZE_2_BYTES   = 'b001,
    AXI4_BURST_SIZE_4_BYTES   = 'b010,
    AXI4_BURST_SIZE_8_BYTES   = 'b011,
    AXI4_BURST_SIZE_16_BYTES  = 'b100,
    AXI4_BURST_SIZE_32_BYTES  = 'b101,
    AXI4_BURST_SIZE_64_BYTES  = 'b110,
    AXI4_BURST_SIZE_128_BYTES = 'b111
  } axi4_burst_size;

  typedef enum logic [1:0] {
    AXI4_FIXED_BURST        = 'b00,
    AXI4_INCREMENTING_BURST = 'b01,
    AXI4_WRAPPING_BURST     = 'b10
  } axi4_burst_type;

  // AxLOCK：AXI4 中仅表达 exclusive access（0=NORMAL, 1=EXCLUSIVE）
  typedef enum logic {
    AXI4_NORMAL_LOCK    = 'b0,
    AXI4_EXCLUSIVE_LOCK = 'b1
  } axi4_lock_type;

  typedef enum {
    AXI4_DEVICE_NON_BUFFERABLE,
    AXI4_DEVICE_BUFFERABLE,
    AXI4_NORMAL_NON_CACHEABLE_NON_BUFFERABLE,
    AXI4_NORMAL_NON_CACHEABLE_BUFFERABLE,
    AXI4_WRITE_THROUGH_NO_ALLOCATE,
    AXI4_WRITE_THROUGH_READ_ALLOCATE,
    AXI4_WRITE_THROUGH_WRITE_ALLOCATE,
    AXI4_WRITE_THROUGH_READ_WRITE_ALLOCATE,
    AXI4_WRITE_BACK_NO_ALLOCATE,
    AXI4_WRITE_BACK_READ_ALLOCATE,
    AXI4_WRITE_BACK_WRITE_ALLOCATE,
    AXI4_WRITE_BACK_READ_WRITE_ALLOCATE
  } axi4_memory_type;

  typedef struct packed {
    logic allocate;
    logic other_allocate;
    logic modifiable;
    logic bufferable;
  } axi4_write_cache;

  typedef struct packed {
    logic other_allocate;
    logic allocate;
    logic modifiable;
    logic bufferable;
  } axi4_read_cache;

  typedef struct packed {
    logic instruction_access;
    logic non_secure_access;
    logic privileged_access;
  } axi4_protection;

  typedef enum logic [1:0] {
    AXI4_OKAY         = 'b00,
    AXI4_EXOKAY       = 'b01,
    AXI4_SLAVE_ERROR  = 'b10,
    AXI4_DECODE_ERROR = 'b11
  } axi4_response;

  typedef enum {
    AXI4_PROTOCOL,
    AXI4LITE_PROTOCOL
  } axi4_protocol;

  typedef enum {
    AXI4_IN_ORDER,
    AXI4_OUT_OF_ORDER
  } axi4_ordering_mode;

  typedef enum {
    AXI4_WRITE_ACCESS,
    AXI4_READ_ACCESS
  } axi4_access_type;

  // Agent 模式（master = initiator，slave = target 为同义别名）
  typedef enum {
    AXI4_ACTIVE_MASTER,
    AXI4_ACTIVE_SLAVE,
    AXI4_PASSIVE,
    AXI4_DISABLED
  } axi4_agent_mode;

  // 约束模式（配合 Violation Injector / Mutation）
  typedef enum {
    AXI4_LEGAL_ONLY,
    AXI4_DIRECTED,
    AXI4_ILLEGAL
  } axi4_constraint_mode;

  // ---------------------------------------------------------------------------
  // 编解码函数（统一 Protocol Semantic Helper，Driver/Monitor/Checker 复用）
  // ---------------------------------------------------------------------------

  // AxLEN：0-255（0 = 1 beat），AXI4-Lite 固定 0
  function automatic axi4_burst_length pack_burst_length(int burst_length);
    if (burst_length inside {[1:256]}) begin
      return axi4_burst_length'(burst_length - 1);
    end
    else begin
      return '0;
    end
  endfunction

  function automatic int unpack_burst_length(axi4_burst_length burst_length);
    return int'(burst_length) + 1;
  endfunction

  function automatic axi4_burst_size pack_burst_size(int burst_size);
    case (burst_size)
      1:    return AXI4_BURST_SIZE_1_BYTE;
      2:    return AXI4_BURST_SIZE_2_BYTES;
      4:    return AXI4_BURST_SIZE_4_BYTES;
      8:    return AXI4_BURST_SIZE_8_BYTES;
      16:   return AXI4_BURST_SIZE_16_BYTES;
      32:   return AXI4_BURST_SIZE_32_BYTES;
      64:   return AXI4_BURST_SIZE_64_BYTES;
      128:  return AXI4_BURST_SIZE_128_BYTES;
      default: return AXI4_BURST_SIZE_1_BYTE;
    endcase
  endfunction

  function automatic int unpack_burst_size(axi4_burst_size burst_size);
    case (burst_size)
      AXI4_BURST_SIZE_1_BYTE:    return 1;
      AXI4_BURST_SIZE_2_BYTES:   return 2;
      AXI4_BURST_SIZE_4_BYTES:   return 4;
      AXI4_BURST_SIZE_8_BYTES:   return 8;
      AXI4_BURST_SIZE_16_BYTES:  return 16;
      AXI4_BURST_SIZE_32_BYTES:  return 32;
      AXI4_BURST_SIZE_64_BYTES:  return 64;
      AXI4_BURST_SIZE_128_BYTES: return 128;
      default:                   return 1;
    endcase
  endfunction

  function automatic axi4_cache encode_memory_type(axi4_memory_type memory_type, bit read_access);
    case (memory_type)
      AXI4_DEVICE_NON_BUFFERABLE:               return 4'b0000;
      AXI4_DEVICE_BUFFERABLE:                   return 4'b0001;
      AXI4_NORMAL_NON_CACHEABLE_NON_BUFFERABLE: return 4'b0010;
      AXI4_NORMAL_NON_CACHEABLE_BUFFERABLE:     return 4'b0011;
      AXI4_WRITE_THROUGH_NO_ALLOCATE:           return (read_access) ? 4'b1010 : 4'b0110;
      AXI4_WRITE_THROUGH_READ_ALLOCATE:         return (read_access) ? 4'b1110 : 4'b0110;
      AXI4_WRITE_THROUGH_WRITE_ALLOCATE:        return (read_access) ? 4'b1010 : 4'b1110;
      AXI4_WRITE_THROUGH_READ_WRITE_ALLOCATE:   return 4'b1110;
      AXI4_WRITE_BACK_NO_ALLOCATE:              return (read_access) ? 4'b1011 : 4'b0111;
      AXI4_WRITE_BACK_READ_ALLOCATE:            return (read_access) ? 4'b1111 : 4'b0111;
      AXI4_WRITE_BACK_WRITE_ALLOCATE:           return (read_access) ? 4'b1011 : 4'b1111;
      AXI4_WRITE_BACK_READ_WRITE_ALLOCATE:      return 4'b1111;
      default:                                  return 4'b0011;
    endcase
  endfunction

  function automatic axi4_memory_type decode_memory_type(axi4_cache cache, bit read_access);
    case ({read_access, cache})
      5'b0_0010, 5'b1_0010: return AXI4_NORMAL_NON_CACHEABLE_NON_BUFFERABLE;
      5'b0_0011, 5'b1_0011: return AXI4_NORMAL_NON_CACHEABLE_BUFFERABLE;
      5'b0_0000, 5'b1_0000: return AXI4_DEVICE_NON_BUFFERABLE;
      5'b0_0001, 5'b1_0001: return AXI4_DEVICE_BUFFERABLE;
      5'b0_0110:            return AXI4_WRITE_THROUGH_NO_ALLOCATE;
      5'b0_1110:            return AXI4_WRITE_THROUGH_WRITE_ALLOCATE;
      5'b1_1010:            return AXI4_WRITE_THROUGH_READ_ALLOCATE;
      5'b0_0111:            return AXI4_WRITE_BACK_NO_ALLOCATE;
      5'b0_1111:            return AXI4_WRITE_BACK_WRITE_ALLOCATE;
      5'b1_1011:            return AXI4_WRITE_BACK_READ_ALLOCATE;
      5'b1_1111:            return AXI4_WRITE_BACK_READ_WRITE_ALLOCATE;
      default:              return AXI4_NORMAL_NON_CACHEABLE_BUFFERABLE;
    endcase
  endfunction

  function automatic bit compare_memory_type(axi4_memory_type lhs, axi4_memory_type rhs, bit read_access);
    return encode_memory_type(lhs, read_access) == encode_memory_type(rhs, read_access);
  endfunction

  // ---------------------------------------------------------------------------
  // Byte Lane / Boundary 计算（REQ-003B/003C/0100/0101）
  // ---------------------------------------------------------------------------

  // 4KB 边界掩码：低 [log2(4096)-1:0] 位置 0，用于检测跨 4KB
  function automatic axi4_address get_4kb_boundary_mask(int burst_size);
    axi4_address mask;
    mask = '1;
    // 保留低 log2(4096) 位为 0
    mask = mask << 12;
    return mask;
  endfunction

  // 判断一笔 burst（起始地址+长度+size）是否跨越 4KB 边界
  function automatic bit is_crossing_4kb(axi4_address address, int burst_length, int burst_size);
    axi4_address start_align;
    axi4_address end_addr;
    start_align = address & get_4kb_boundary_mask(burst_size);
    end_addr    = address + (burst_length - 1) * burst_size;
    return (end_addr & ~get_4kb_boundary_mask(burst_size)) != (start_align & get_4kb_boundary_mask(burst_size));
  endfunction

  // 计算第 index 个 beat 的实际字节地址（考虑 WRAP/INCR/FIXED 与 narrow/unaligned）
  function automatic axi4_address get_beat_address(
    axi4_address   address,
    int            index,
    axi4_burst_type burst_type,
    int            burst_length,
    int            burst_size
  );
    axi4_address beat_addr;
    axi4_address low_bits;
    int          lower_wrap_boundary;
    int          upper_wrap_boundary;
    int          addr_incr;
    case (burst_type)
      AXI4_FIXED_BURST: begin
        beat_addr = address;
      end
      AXI4_INCREMENTING_BURST: begin
        beat_addr = address + (index * burst_size);
      end
      AXI4_WRAPPING_BURST: begin
        addr_incr = burst_size * burst_length;
        lower_wrap_boundary = ((address / addr_incr) * addr_incr);
        upper_wrap_boundary = lower_wrap_boundary + addr_incr;
        beat_addr = address + (index * burst_size);
        if (beat_addr >= upper_wrap_boundary) begin
          beat_addr = beat_addr - addr_incr;
        end
      end
      default: begin
        beat_addr = address + (index * burst_size);
      end
    endcase
    return beat_addr;
  endfunction

  // 计算第 index 个 beat 的起始 byte lane（相对总数据总线）
  function automatic int get_byte_lane_index(axi4_address beat_addr, int data_bytes);
    return int'(beat_addr % data_bytes);
  endfunction

endpackage : axi4_types_pkg

`endif // AXI4_TYPES_PKG__SV
