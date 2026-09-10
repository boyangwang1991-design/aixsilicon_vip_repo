// SPDX-License-Identifier: Apache-2.0
package ahb_types_pkg;
  typedef enum int {AHB_LITE, AHB5, AHB_CLASSIC} ahb_profile_e;
  typedef enum int {ACTIVE_MASTER, ACTIVE_SLAVE, PASSIVE, DISABLED} ahb_mode_e;
  typedef enum int {LITTLE_ENDIAN, BYTE_BIG_ENDIAN, WORD_BIG_ENDIAN} ahb_endian_e;
  typedef enum int {REQUESTED, OFFERED, ACCEPTED, COMPLETED, ABORTED} ahb_lifecycle_e;
  typedef enum int {OKAY, ERROR, EXCLUSIVE_FAIL, RESET_ABORT, WATCHDOG,
                    CANCEL_BEFORE_ACCEPT, RETRY, SPLIT} ahb_status_e;
  typedef enum int {INIT_X, INIT_ZERO, INIT_CONSTANT, INIT_ADDRESS, INIT_RANDOM} ahb_init_e;
  typedef enum int {PROTOCOL, CAPABILITY, ENV_POLICY, DATA_MISMATCH, EXPECTED_INJECTION} ahb_category_e;
  typedef logic [63:0] ahb_addr_t;
  typedef logic [1023:0] ahb_data_t;
  typedef logic [127:0] ahb_mask_t;
  function automatic int burst_length(logic [2:0] burst);
    case(burst) 0:return 1; 1:return 0; 2,3:return 4; 4,5:return 8; 6,7:return 16; endcase
    return 0;
  endfunction
  function automatic ahb_addr_t next_address(ahb_addr_t addr, int size, logic [2:0] burst);
    ahb_addr_t step_bytes, window_bytes, base;
    step_bytes=64'd1 << size;
    if (burst inside {2,4,6}) begin
      window_bytes=step_bytes*burst_length(burst); base=addr & ~(window_bytes-1);
      return base | ((addr+step_bytes)&(window_bytes-1));
    end
    return addr+step_bytes;
  endfunction
  function automatic int byte_lane(ahb_addr_t addr, int bus_bytes, ahb_endian_e endian);
    int lane_index; lane_index=int'(addr % bus_bytes);
    if(endian==BYTE_BIG_ENDIAN) return bus_bytes-1-lane_index;
    if(endian==WORD_BIG_ENDIAN) return (lane_index & ~3) | (3-(lane_index & 3));
    return lane_index;
  endfunction
  function automatic ahb_mask_t active_mask(ahb_addr_t addr,int size,int bus_bytes,ahb_endian_e endian);
    ahb_mask_t mask; mask='0;
    if(size<0 || size>7 || (1<<size)>bus_bytes) return mask;
    for(int i=0;i<(1<<size);i++) mask[byte_lane(addr+i,bus_bytes,endian)]=1;
    return mask;
  endfunction
  function automatic ahb_mask_t parity_bytes(ahb_data_t data,int width);
    ahb_mask_t result; result='0;
    for(int i=0;i<(width+7)/8;i++) begin
      result[i]=0;
      for(int j=0;j<8 && i*8+j<width;j++) result[i]^=data[i*8+j];
    end
    return result;
  endfunction
endpackage
