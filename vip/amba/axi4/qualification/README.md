# AXI4 VIP Qualification 证据包

> 本目录为 `aixsilicon:vip:axi4:1.0.0`（VIP-001）的 Qualification 证据（G5 前置）。
> 所有结论关联命令/环境/日志/资产版本；状态只能取 `PASS/FAIL/NOT_RUN/BLOCKED/WAIVED`。

## 环境

| 项 | 值 |
| --- | --- |
| 仿真器 | VCS W-2024.09-SP1（`-full64 -ntb_opts uvm-1.2`） |
| UVM | 1.2（`-ntb_opts uvm-1.2`） |
| seed | 1（`+ntb_random_seed=1`） |
| 套件 | vip-development-suite（`vip_tool.py`） |

## 证据索引

| 证据 | 文件 | 状态 |
| --- | --- | --- |
| 需求→实现→测试追溯 | [`requirement_traceability.md`](requirement_traceability.md) | ✅ |
| 覆盖率报告 | [`coverage_report.md`](coverage_report.md) | ✅（功能覆盖入口） |
| 失败注入 / Mutation | [`fault_injection.md`](fault_injection.md) | ✅（负向检出证据） |
| 已知限制 | [`known_limitations.md`](known_limitations.md) | ✅ |
| 总 Qualification 报告 | [`qualification_report.md`](qualification_report.md) | ✅ |

## 门禁映射

| Gate | 判定 | 证据 |
| --- | --- | --- |
| G0 Requirement | PASS（1.0.0-g0-baseline） | docs/requirement.md |
| G1 Architecture | PASS（0.4.0-draft 运行时模型冻结） | docs/architecture.md |
| G2 Code + Unit Test | PASS（VCS 编译 + unit 79/79） | run_log |
| G3 Self-Verification | PASS（9 tier 全绿） | run_log + 本目录 |
| G4 Coverage | NOT_RUN（功能覆盖骨架就绪，闭合待 G4） | coverage_report.md |
| G5 Qualification | 见 qualification_report.md | 本目录 |
| G6 Release | NOT_RUN（FuseSoC .core 已生成，发布待 G6） | aixsilicon_vip_axi4_1.0.0.core |

## 运行方法（确定性）

```bash
# 结构/元数据检查
vip_tool.py vip-check --root vip/amba/axi4

# 自验证分层回归（9 tier）
make -C vip/amba/axi4/self_test full

# 功能覆盖（smoke 基线）
make -C vip/amba/axi4/self_test cov

# 覆盖率分析
vip_tool.py coverage-check --root vip/amba/axi4

# FuseSoC core 校验
vip_tool.py gen-core --root vip/amba/axi4 --vip axi4 --version 1.0.0 --check-only