// =============================================================================
// File Name   : apb_monitor.sv
// Description : APB 统一 monitor（env 级唯一 authoritative 观察流——ADR-1）
//               完全被动（C-2）；相位重建（RUL-010 载体）；
//               observed_wait_cycles 重建；ABORTED 事务发布（无 error_ap——两流语义）
// VLNV        : aixsilicon:vip:apb:1.0.0
// =============================================================================

`ifndef APB_MONITOR__SV
`define APB_MONITOR__SV

class apb_monitor extends uvm_monitor;

  `uvm_component_utils(apb_monitor)

  virtual apb_if vif;
  apb_config     cfg;

  // 观察流：事务结果流（status 一体表达 OK/ERROR/ABORTED）——REQ §8
  uvm_analysis_port #(apb_item) transaction_ap;

  // 内部相位状态
  typedef enum { M_IDLE, M_SETUP, M_ACCESS } monitor_phase_e;
  monitor_phase_e phase;

  apb_item cur_item;
  int unsigned wait_cnt;

  // 简易统计（架构 §27）
  int unsigned n_completed;
  int unsigned n_aborted;
  int unsigned n_error;
  int unsigned wait_total;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    transaction_ap = new("transaction_ap", this);
    phase = M_IDLE;
  endfunction

  function void build_phase(uvm_phase phase_);
    super.build_phase(phase_);
    if (!uvm_config_db#(virtual apb_if)::get(this, "", "vif", vif))
      `uvm_fatal(get_type_name(), "virtual interface 'vif' not set")
    if (!uvm_config_db#(apb_config)::get(this, "", "config", cfg))
      `uvm_fatal(get_type_name(), "apb_config 'config' not set")
  endfunction

  // ---------------------------------------------------------------------------
  // X/Z 检查（VER-013，配合 RUL-011 有效窗口——checker 侧双保险之一）
  // ---------------------------------------------------------------------------
  function void x_check_request(logic psel, logic penable,
                                logic [`APB_MAX_ADDR_WIDTH-1:0] addr, logic pwrite);
    if (!cfg.enable_x_check) return;
    if (psel) begin  // PSEL 有效窗口
      if (^addr === 1'bx) `uvm_error("APB_XCHK", $sformatf("PADDR X/Z at %0t", $time))
      if (pwrite === 1'bx) `uvm_error("APB_XCHK", $sformatf("PWRITE X/Z at %0t", $time))
    end
  endfunction

  // ---------------------------------------------------------------------------
  // 重建主循环（完全被动采样）
  // ---------------------------------------------------------------------------
  virtual task run_phase(uvm_phase phase_);
    super.run_phase(phase_);
    wait (vif.presetn === 1'b1);
    forever begin
      @(posedge vif.pclk);

      // 复位检测：任意相位复位 → ABORTED
      if (vif.presetn !== 1'b1) begin
        handle_abort_during_transfer();
        wait (vif.presetn === 1'b1);
        phase = M_IDLE;
        continue;
      end

      // 采样请求有效窗（PSEL）
      x_check_request(vif.psel[0], vif.penable, vif.paddr, vif.pwrite);

      case (phase)
        M_IDLE: begin
          if (vif.psel[0] && !vif.penable) begin
            phase = M_SETUP;
          end
        end

        M_SETUP: begin
          // RUL-010：SETUP 拍 PREADY 任意值合法，不判完成
          if (vif.psel[0] && vif.penable) begin
            // SETUP→ACCESS：组装请求
            cur_item = apb_item::type_id::create("mon_item");
            cur_item.cfg_addr_width = cfg.addr_width;
            cur_item.cfg_data_width = cfg.data_width;
            cur_item.direction      = vif.pwrite ? APB_WRITE : APB_READ;
            cur_item.addr           = vif.paddr;
            cur_item.wdata          = vif.pwdata;
            if (cfg.enable_strb)     cur_item.strb  = vif.pstrb_w;
            if (cfg.enable_prot)     cur_item.prot  = vif.pprot_w;
            if (cfg.user_req_width)  cur_item.auser = vif.pauser_w;
            if (cfg.user_data_width) cur_item.wuser = vif.pwuser_w;
            if (cfg.enable_wakeup)   cur_item.wakeup = vif.pwakeup_w;
            if (cfg.rme_support)     cur_item.pnse  = vif.pnse_w;   // PRO-013/CP-07
            cur_item.status    = APB_OK;
            cur_item.start_time = $time;
            wait_cnt = 0;
            // 零等待完成可落在 ACCESS 第 1 拍（RUL-010 载体：
            // completion = psel&&penable&&pready 同拍判定）
            if (vif.pready) begin
              complete_item();
              phase = M_IDLE;
            end
            else begin
              phase = M_ACCESS;
            end
          end
          else if (!vif.psel[0]) begin
            phase = M_IDLE;   // SETUP→IDLE 违规由 SVA A1 报告
          end
        end

        M_ACCESS: begin
          if (!vif.psel[0]) begin
            // ACCESS 期 PSEL 撤销：异常终止（SVA 负责；monitor 安全退出）
            handle_abort_during_transfer();
            phase = M_IDLE;
          end
          else if (!vif.penable) begin
            phase = M_SETUP;   // 完成次拍直接下一笔 SETUP（back-to-back）
          end
          else if (vif.pready) begin
            // completion 拍（RUL-010 载体：psel&&penable&&pready）
            complete_item();
            phase = M_IDLE;
          end
          else begin
            wait_cnt++;   // wait state 延长
          end
        end

        default: phase = M_IDLE;
      endcase
    end
  endtask

  // ---------------------------------------------------------------------------
  // completion：填响应字段并发布
  // ---------------------------------------------------------------------------
  function void complete_item();
    cur_item.observed_wait_cycles = wait_cnt;
    cur_item.rdata  = vif.prdata;
    cur_item.ruser  = vif.pruser_w;
    cur_item.buser  = vif.pbuser_w;
    cur_item.slverr = vif.pslverr;
    cur_item.status = vif.pslverr ? APB_ERROR : APB_OK;
    cur_item.end_time = $time;
    cur_item.update_derived();
    // CP-08 pattern 判定
    if (wait_cnt > 0)      cur_item.phase_pattern = APB_PAT_WAIT_EXTENDED;
    else if (cur_item.start_time == $time) cur_item.phase_pattern = APB_PAT_BACK_TO_BACK;
    else                   cur_item.phase_pattern = APB_PAT_IDLE_TO_TRANSFER;

    n_completed++;
    if (cur_item.status == APB_ERROR) n_error++;
    wait_total += wait_cnt;

    `uvm_info(get_type_name(), $sformatf("MON completed: %s", cur_item.convert2string()), UVM_LOW)
    transaction_ap.write(cur_item);
    cur_item = null;
  endfunction

  // ---------------------------------------------------------------------------
  // 复位中止：ABORTED 事务发布（不判违规；reset 场景由 UT08-10 驱动）
  // ---------------------------------------------------------------------------
  function void handle_abort_during_transfer();
    if (cur_item != null && (phase == M_ACCESS || phase == M_SETUP)) begin
      cur_item.observed_wait_cycles = wait_cnt;
      cur_item.status = APB_ABORTED;
      cur_item.end_time = $time;
      n_aborted++;
      `uvm_info(get_type_name(), $sformatf("MON aborted: %s", cur_item.convert2string()), UVM_MEDIUM)
      transaction_ap.write(cur_item);
      cur_item = null;
    end
  endfunction

endclass : apb_monitor

`endif // APB_MONITOR__SV
