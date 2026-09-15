# src/

VIP 源码目录（按 `docs/architecture.md` 组件矩阵与 Profile 裁剪）。

组件代码模板基于 ip-development-suite 的 UVM 骨架规范（uvm_driver/uvm_monitor/uvm_agent
继承、extern 声明、`uvm_config_db`、analysis port），按 VIP 独立产品结构适配：

| 文件 | 继承/类型 | 用途 | Profile |
| --- | --- | --- | --- |
| `axi4_stream_pkg.sv` | package | 包定义（import 全部组件） | 所有 |
| `axi4_stream_if.sv` | interface | 信号采样 / clocking / modport（引用 HWIF） | 所有 |
| `axi4_stream_config.sv` | uvm_object | 配置对象（禁止全局变量） | 所有 |
| `transaction/axi4_stream_item.sv` | uvm_sequence_item | 事务定义 + do_copy/compare | FULL_UVM 等 |
| `agent/axi4_stream_monitor.sv` | uvm_monitor | 被动采样 + transaction_ap/error_ap | FULL_UVM/LIGHTWEIGHT/PASSIVE |
| `agent/axi4_stream_driver.sv` | uvm_driver | 主动驱动 | FULL_UVM/LIGHTWEIGHT |
| `agent/axi4_stream_sequencer.sv` | uvm_sequencer | 序列器 | FULL_UVM |
| `agent/axi4_stream_agent.sv` | uvm_agent | 组件组装 | FULL_UVM |
| `sequences/axi4_stream_base_seq.sv` | uvm_sequence | 基础序列 | FULL_UVM |
| `coverage/axi4_stream_coverage.sv` | uvm_subscriber | 功能覆盖（四层） | 推荐 |
| `checker/axi4_stream_checker.sv` | uvm_subscriber | 协议检查（error_count） | 推荐 |
| `checker/axi4_stream_assertions.sv` | module(SVA) | 协议时序断言 | 推荐 |
| `scoreboard/axi4_stream_reference_model.sv` | uvm_subscriber | 参考模型（独立建模预期输出） | FULL_UVM |
| `scoreboard/axi4_stream_scoreboard.sv` | uvm_scoreboard | 计分板（比对 expected vs actual） | FULL_UVM |
| `env/axi4_stream_env.sv` | uvm_env | 自验证环境（组装 RM/scoreboard） | FULL_UVM |

> 命名规范：`axi4_stream_<component>.sv`；`checker` 是 SV 保留字，变量名用 `scb`。
> Profile 裁剪：LIGHTWEIGHT 删除 sequencer/agent 层；CHECKER_ONLY 只保留
> checker/assertions/coverage。

### 多 analysis imp（checker / scoreboard）

一个组件需要接收多个事务流（如 checker 的"事务 + 错误事件"、scoreboard 的"预期 + 实际"）
时，必须使用 `uvm_analysis_imp_decl` 宏区分写回调，**禁止**为多个 imp 直接使用同名
`uvm_analysis_imp`（无法区分 write 来源，且无法编译）：

```systemverilog
// axi4_stream_pkg 顶部（package 内、class 前）定义一次：
`uvm_analysis_imp_decl(_actual)
`uvm_analysis_imp_decl(_error)
`uvm_analysis_imp_decl(_expected)

// 组件内使用带后缀类型，回调方法为 write_<suffix>()：
uvm_analysis_imp_actual   #(axi4_stream_item, axi4_stream_checker)  actual_export;  // → write_actual()
uvm_analysis_imp_error    #(axi4_stream_item, axi4_stream_checker)  error_export;   // → write_error()
uvm_analysis_imp_expected #(axi4_stream_item, axi4_stream_scoreboard) expected_export; // → write_expected()
```

> `uvm_subscriber #(T)` 自带单一 `analysis_export`（单流场景可直接用）；
> 多流场景改用 `uvm_component` + 上述 imp 宏。
