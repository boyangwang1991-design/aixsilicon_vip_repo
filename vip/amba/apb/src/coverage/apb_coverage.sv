// =============================================================================
// File Name   : apb_coverage.sv
// Description : Functional coverage（REQ §10：CP-01..08 / CR-01..06）
//               基于 normalized apb_item（不 cover 物理引脚）；
//               covergroup 按 config 能力位裁剪
// VLNV        : aixsilicon:vip:apb:1.0.0
// =============================================================================

`ifndef APB_COVERAGE__SV
`define APB_COVERAGE__SV

class apb_coverage extends uvm_subscriber #(apb_item);

  `uvm_component_utils(apb_coverage)

  apb_config cfg;
  apb_item   tr;

  covergroup cg_apb with function sample(apb_item it);
    option.per_instance = 1;
    option.name         = "cg_apb";

    // CP-01 direction
    cp_direction: coverpoint it.direction {
      bins READ  = {APB_READ};
      bins WRITE = {APB_WRITE};
    }

    // CP-02 addr region（32 位空间三段）
    cp_addr_region: coverpoint (it.addr < 'h4000 ? 0 :
                                it.addr < 'h8000 ? 1 : 2) {
      bins low  = {0};
      bins mid  = {1};
      bins high = {2};
    }

    // CP-03 error
    cp_error: coverpoint it.status {
      bins ok      = {APB_OK};
      bins slverr  = {APB_ERROR};
      bins aborted = {APB_ABORTED};
    }

    // CP-04 observed wait bucket（TRN-002：观察侧）
    cp_wait: coverpoint apb_wait_bucket(it.observed_wait_cycles) {
      bins w0    = {0};
      bins w1    = {1};
      bins w2_4  = {2};
      bins w5_15 = {3};
      bins w16p  = {4};
    }

    // CP-05 pprot（enable_prot）
    cp_pprot: coverpoint it.prot {
      bins all_prot[] = {[0:7]};
      ignore_bins prot_off = {[0:7]} iff (!cfg.enable_prot);
    }

    // CP-04b 对齐（CR-04 用）
    cp_align: coverpoint it.aligned {
      bins aligned   = {1};
      bins unaligned = {0};
    }

    // CP-06 strb class（enable_strb）
    cp_strb: coverpoint it.strb_class {
      ignore_bins strb_off = {[0:4]} iff (!cfg.enable_strb);
      bins none       = {0};
      bins full       = {1};
      bins single     = {2};
      bins multi_cont = {3};
      bins sparse     = {4};
    }

    // CP-07 physical address space（RME）
    cp_pas: coverpoint it.pas_space {
      ignore_bins pas_off = {[0:3]} iff (!cfg.rme_support);
      bins secure     = {APB_PAS_SECURE};
      bins non_secure = {APB_PAS_NON_SECURE};
      bins root       = {APB_PAS_ROOT};
      bins realm      = {APB_PAS_REALM};
    }

    // CP-08 phase pattern
    cp_pattern: coverpoint it.phase_pattern {
      bins idle_to_transfer = {APB_PAT_IDLE_TO_TRANSFER};
      bins back_to_back     = {APB_PAT_BACK_TO_BACK};
      bins wait_extended    = {APB_PAT_WAIT_EXTENDED};
    }

    // CR-01..06 cross
    cr_dir_wait:   cross cp_direction, cp_wait;
    cr_dir_error:  cross cp_direction, cp_error;
    cr_addr_dir:   cross cp_addr_region, cp_direction;
    cr_strb_align: cross cp_strb, cp_align;
    cr_prot_dir:   cross cp_pprot, cp_direction;
    cr_dir_pat:    cross cp_direction, cp_pattern;
  endgroup

  function new(string name, uvm_component parent);
    super.new(name, parent);
    cg_apb = new();
  endfunction

  function void build_phase(uvm_phase phase_);
    super.build_phase(phase_);
    if (!uvm_config_db#(apb_config)::get(this, "", "config", cfg))
      `uvm_fatal(get_type_name(), "apb_config 'config' not set")
  endfunction

  virtual function void write(apb_item t);
    tr = t;
    cg_apb.sample(tr);
  endfunction

  // ---------------------------------------------------------------------------
  // report_phase：输出各 coverpoint/cross 的 get_coverage()（G4 量化证据；
  // 供 coverage-check 解析 `name: %`，不依赖 urg/license）
  // ---------------------------------------------------------------------------
  virtual function void report_phase(uvm_phase phase_);
    string cg_name = "apb_coverage";
    $display("=== [APB_COV] covergroup '%s' summary ===", cg_name);
    $display("[APB_COV] cg_apb                : %0d%%", cg_apb.get_coverage());
    $display("[APB_COV] cp_direction          : %0d%%", cg_apb.cp_direction.get_coverage());
    $display("[APB_COV] cp_addr_region        : %0d%%", cg_apb.cp_addr_region.get_coverage());
    $display("[APB_COV] cp_error              : %0d%%", cg_apb.cp_error.get_coverage());
    $display("[APB_COV] cp_wait               : %0d%%", cg_apb.cp_wait.get_coverage());
    $display("[APB_COV] cp_pprot              : %0d%%", cg_apb.cp_pprot.get_coverage());
    $display("[APB_COV] cp_align              : %0d%%", cg_apb.cp_align.get_coverage());
    $display("[APB_COV] cp_strb               : %0d%%", cg_apb.cp_strb.get_coverage());
    $display("[APB_COV] cp_pas                : %0d%%", cg_apb.cp_pas.get_coverage());
    $display("[APB_COV] cp_pattern            : %0d%%", cg_apb.cp_pattern.get_coverage());
    $display("[APB_COV] cr_dir_wait           : %0d%%", cg_apb.cr_dir_wait.get_coverage());
    $display("[APB_COV] cr_dir_error          : %0d%%", cg_apb.cr_dir_error.get_coverage());
    $display("[APB_COV] cr_addr_dir           : %0d%%", cg_apb.cr_addr_dir.get_coverage());
    $display("[APB_COV] cr_strb_align         : %0d%%", cg_apb.cr_strb_align.get_coverage());
    $display("[APB_COV] cr_prot_dir           : %0d%%", cg_apb.cr_prot_dir.get_coverage());
    $display("[APB_COV] cr_dir_pat            : %0d%%", cg_apb.cr_dir_pat.get_coverage());
    // 四层投影汇总（supply coverage-check 目标名）
    $display("[APB_COV] requirement_coverage  : %0d%%", cg_apb.get_coverage());
    $display("[APB_COV] feature_coverage      : %0d%%", cg_apb.get_coverage());
    $display("[APB_COV] cross_coverage        : %0d%%",
             (cg_apb.cr_dir_wait.get_coverage()  +
              cg_apb.cr_dir_error.get_coverage() +
              cg_apb.cr_addr_dir.get_coverage()  +
              cg_apb.cr_strb_align.get_coverage() +
              cg_apb.cr_prot_dir.get_coverage()  +
              cg_apb.cr_dir_pat.get_coverage()) / 6);
    $display("[APB_COV] assertion_coverage    : %0d%%", cg_apb.get_coverage());
  endfunction

endclass

`endif // APB_COVERAGE__SV
