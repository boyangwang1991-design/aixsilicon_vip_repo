// APB VIP L1 Unit Test filelist（L1）
// 顺序：types_pkg(无 UVM) → apb_if(接口；pkg 内 agent/env 引用) → apb_pkg(UVM 组件)
//       → suites → tb
// 同步规则：每个 suite 与 src/ 特性批次同步登记（vip-development §6.1）
../src/apb_types_pkg.sv
../src/apb_if.sv
../src/apb_pkg.sv
apb_unit_types.sv
apb_unit_item.sv
apb_unit_config.sv
apb_unit_tb.sv
