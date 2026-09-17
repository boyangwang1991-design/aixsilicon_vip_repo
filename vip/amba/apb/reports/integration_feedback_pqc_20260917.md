# APB VIP 集成反馈（来自 IP：pqc）

> 来源：`aixsilicon_ip_repo/ips/security/crypto/pqc`（PQC 加速器）UVM 集成
> 日期：2026-09-17 · VIP 版本：`aixsilicon:vip:apb:1.0.0` · 仿真器：VCS W-2024.09-SP1 / UVM 1.2
>
> 本文件由 PQC 集成方记录，供 `vip-development-suite` 修改并回归。
> 以下各项均为**在真实集成中使用**时遇到的阻塞或非预期行为，不是风格建议。
> 未经 VIP owner 修改前，PQC 侧采用消费方只读引用绕过，不改动 VIP 源码。

## F-APB-01（阻塞级）发布 core 无法独立 elaborate

**现象**：用发布 core 直接编译失败：

```
Error-[SFCOR] Source file cannot be opened
  Source file "uvm_macros.svh" cannot be opened ...
Error-[SFCOR] Source file "apb_config.sv" cannot be opened ...
  Source info: `include "apb_config.sv"   (apb_pkg.sv, 21)
```

**根因（两处，均已实测确认）**：
1. `aixsilicon_vip_apb_1.0.0.core` 未声明 `+incdir+`，而 `apb_pkg.sv` 以
   `#include "apb_config.sv"`、`#include "agent/apb_monitor.sv"` 等**相对于 src 根**的
   路径包含自身源码，因此缺少 `src/` 及其各子目录的 include 路径；
2. `src/apb_config.sv` **存在于 VIP 仓，但未列在 core 的 `rtl` fileset 中**，
   所以无论是否 `depend` 引用，FuseSoC 都不会把它导出到构建树：

```
VIP 仓存在： vip/amba/apb/src/apb_config.sv        -> 存在
core 中声明： grep -c "apb_config.sv" ...core       -> 0
depend 导出后： build/.../src/aixsilicon_vip_apb_1.0.0/src/  -> 无 apb_config.sv
```

**影响**：消费方无法按 `reuse-plan` 的首选方式（FuseSoC `depend`）接入；集成被阻塞。

**建议**：
- core 的 `rtl` fileset 补齐 `src/apb_config.sv`（或改为由 `apb_pkg.sv` 之外单独编译）；
- 为 fileset 增加 include 路径（FuseSoC 支持在文件项上标 `is_include_file: true`
  以自动产生 `+incdir+`，或由 core 显式声明）；
- 增加一个"消费者 plug-in"自检：`fusesoc run --target=lint` 至少能 elaborate。

## F-APB-02（阻塞级）`apb_env` 默认连接 predictor，但 `map` 未绑定时直接空指针崩溃

**现象**：把 VIP `apb_env` 原样例化并只设置 `apb_config` + `vif` 后，仿真在第一个
事务就崩溃：

```
Error-[NOA] Null object access
  #0 uvm_reg_predictor#(apb_pkg::apb_item)::write  (uvm_reg_predictor.svh:151)
  #1 apb_monitor::complete_item (apb_monitor.sv:168)
```

**根因**：`apb_env.connect_phase` 无条件执行
`monitor.transaction_ap.connect(predictor.analysis_export)`，而
`apb_reg_predictor.reg_predictor.map` 只有在使用 RAL 时才被绑定
（user-guide §5）。因此**不使用 RAL 的消费者**（寄存器契约验证之外的任何场景）
也会崩在 VIP 内部。

同时 `apb_reg_predictor` 内部包了一层 `uvm_reg_predictor`，但对外没有暴露
`map` / `adapter` 的转发接口：文档写 `env.predictor.reg_predictor.map = ...`，
而组件名是 `reg_predictor`，外部只能靠内部字段名访问（脆弱）。

**建议**：
- RAL 未启用时不连接 predictor（例如由 `cfg` 的开关或
  `if (reg_predictor.map != null) connect(...)` 保护）；
- 或在 `apb_reg_predictor` 上提供 `set_map(uvm_reg_map)` / `set_adapter()` 公开方法，
  避免消费者依赖内部字段名。

## F-APB-03（体验级）`apb_config` 未在 AGENT 层注入时致命退出，但错误信息未提示正确 scope

**现象**：集成方按"精确 scope"注入 `config` 时：

```
UVM_FATAL apb_violation.sv(61) [apb_protocol_checker] apb_config 'config' not set
```

**根因**：UVM `config_db` 精确 scope 不向更深层组件级联（user-guide §9 已提及），
但 `apb_checker` / `apb_reg_predictor` / `apb_coverage` 都在 `build_phase` 用
`get(this, "", "config", cfg)` 取配置。集成方必须使用通配 scope
`set(null, "*", "config", cfg)`。

**建议**：FATAL 信息里直接给出修复建议，例如
`"set config with a wildcard scope: uvm_config_db#(apb_config)::set(null, \"*\", \"config\", cfg)"`。
（仅体验改进；PQC 侧已改用通配 scope 解决。）

## 已确认工作正常的部分（供回归参考）

- 包结构（`apb_types_pkg` → `apb_if` → `apb_pkg`）与 `apb_if` 参数化（ADDR/DATA/
  PSTRB/PPROT）在 `ADDR_WIDTH=32, DATA_WIDTH=32, HAS_PSTRB=1, HAS_PPROT=1` 下正常；
- `apb_master_agent` / `apb_master_sequencer` + `apb_base_sequence.do_write/do_read`
  是清晰可用的激励入口，定向测试单笔访问只需继承 base 并 `start()`；
- `apb_monitor` 的 `transaction_ap` 与分析流对下游 adapter 友好；
- SVA bind（`apb_protocol_sva`）在 APB4 参数下未产生误报。

## 复现入口（PQC 侧）

```bash
cd repos/aixsilicon_ip_repo/ips/security/crypto/pqc
VIP_ROOT=<workflow>/repos/aixsilicon_vip_repo \
uv run --locked --no-sync python verification/sim/run_uvm.py \
  --tests "tc_cmd_smoke tc_reg_reset_attr tc_apb_protection" --seeds 1 \
  --compile-timeout 300 --run-timeout 90
```

当前状态：编译 `rc=0`；三个 smoke 用例 `UVM_ERROR=0` 全部通过。