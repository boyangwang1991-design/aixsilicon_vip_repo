// =============================================================================
// File Name   : axi4_status.sv
// Description : AXI4 VIP 运行时状态对象（REQ-032 / REQ-088）
//               保存 memory 句柄、outstanding 计数（read/write/per-id）与
//               统计信息（transaction count / violation count）。
// VLNV        : aixsilicon:vip:axi4:1.0.0
// =============================================================================

`ifndef AXI4_STATUS__SV
`define AXI4_STATUS__SV

// 前向声明（axi4_memory 在 axi4_memory.sv 中定义，先于 axi4_status 编译）
typedef class axi4_memory;

class axi4_status extends uvm_object;

  // 存储镜像句柄（由 slave_agent / data_monitor 设置）
  axi4_memory  memory;

  // ---- 运行时统计（REQ-088）----
  int outstanding_read_count;
  int outstanding_write_count;
  int pending_response_count;
  int transaction_count;
  int read_transaction_count;
  int write_transaction_count;
  int violation_count;
  int timeout_count;

  // 按 ID 的 outstanding 计数（数组关联，key = axi4_id）
  protected int outstanding_per_id[axi4_id];

  function new(string name = "axi4_status");
    super.new(name);
    outstanding_read_count   = 0;
    outstanding_write_count  = 0;
    pending_response_count   = 0;
    transaction_count        = 0;
    read_transaction_count   = 0;
    write_transaction_count  = 0;
    violation_count          = 0;
    timeout_count            = 0;
  endfunction

  // 记录一笔事务开始（address 阶段）
  function void start_transaction(axi4_access_type access_type, axi4_id id);
    transaction_count++;
    if (access_type == AXI4_READ_ACCESS) begin
      outstanding_read_count++;
      read_transaction_count++;
    end
    else begin
      outstanding_write_count++;
      write_transaction_count++;
    end
    if (outstanding_per_id.exists(id)) begin
      outstanding_per_id[id]++;
    end
    else begin
      outstanding_per_id[id] = 1;
    end
  endfunction

  // 记录一笔事务完成（response 阶段）
  function void end_transaction(axi4_access_type access_type, axi4_id id);
    if (access_type == AXI4_READ_ACCESS) begin
      if (outstanding_read_count > 0) begin
        outstanding_read_count--;
      end
      pending_response_count--;
    end
    else begin
      if (outstanding_write_count > 0) begin
        outstanding_write_count--;
      end
      pending_response_count--;
    end
    if (outstanding_per_id.exists(id)) begin
      if (outstanding_per_id[id] > 0) begin
        outstanding_per_id[id]--;
      end
    end
  endfunction

  function int get_outstanding_per_id(axi4_id id);
    if (outstanding_per_id.exists(id)) begin
      return outstanding_per_id[id];
    end
    return 0;
  endfunction

  function int get_total_outstanding();
    return outstanding_read_count + outstanding_write_count;
  endfunction

  function void incr_violation();
    violation_count++;
  endfunction

  function void incr_timeout();
    timeout_count++;
  endfunction

  `uvm_object_utils_begin(axi4_status)
    `uvm_field_object(memory, UVM_DEFAULT)
    `uvm_field_int(outstanding_read_count, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(outstanding_write_count, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(pending_response_count, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(transaction_count, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(read_transaction_count, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(write_transaction_count, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(violation_count, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(timeout_count, UVM_DEFAULT | UVM_DEC)
  `uvm_object_utils_end

endclass : axi4_status

`endif // AXI4_STATUS__SV
