# AXI4 VIP — Gate Status（G0-G6 判定与证据索引）

> **VLNV**: `aixsilicon:vip:axi4:1.0.0`（VIP-001，FULL_UVM）· 更新: 2026-09-03
> 本文件是 Gate 判定唯一 SSOT（原 qualification/README + qualification_report 合并）；
> 过程流水见 [run_log.md](run_log.md)；Limitations 唯一来源 [requirement §23](../docs/requirement.md)
> （验证性限制 E2/C3 等已并入该章 LIM-007..008）。

## 环境基线

| 项 | 值 |
|---|---|
| 仿真器 | VCS W-2024.09-SP1（`-full64 -ntb_opts uvm-1.2`） |
| UVM | 1.2 |
| seed | 1（`+ntb_random_seed=1`） |
| 套件 | vip-development-suite（`vip_tool.py`） |

## Gate 判定

| Gate | 判定 | 证据索引 |
|---|---|---|
| G0 Requirement | **PASS**（1.0.0-g0-baseline） | [requirement.md](../docs/requirement.md) |
| G1 Architecture | **PASS**（0.4.0-draft 运行时模型冻结） | [architecture.md](../docs/architecture.md) |
| G2 Code + Unit | **PASS** | run_log：VCS 编译 0 错误 + L1 unit 79/79（`make -C self_test unit`） |
| G3 Self-Verification | **PASS** | run_log：**9/9 tier 全绿**（smoke/feature/corner/negative/random/stress/concurrent/error/ral） |
| G4 Coverage | NOT_RUN | 功能覆盖骨架就绪，闭合待多 tier 合并（[coverage/](coverage/coverage_report.md)）；E2/C3 NOT_RUN（requirement §23 LIM-007/008） |
| G5 Qualification | **PARTIAL** | struct/compile/regression/doc/FuseSoC/RAL ✅ + mutation 100%（[mutation/](mutation/mutation_report.md)）；G4 未闭合→不可发 Qualified 结论 |
| G6 Release | NOT_RUN | `aixsilicon_vip_axi4_1.0.0.core` 已生成（gen-core + vip-check），发布待 G4/G5 全绿 |

## G5 检查项明细

| 项 | 命令/证据 | 结果 |
|---|---|---|
| 结构（Structure） | `vip_tool.py vip-check --root ...` | PASS |
| 编译（Compile） | `make -C self_test compile` | PASS（0 错误） |
| L1 Unit Test | `make -C self_test unit` | 79/79 PASS |
| 自验证（Self-Test） | `make -C self_test full`（9 tier） | **9/9 PASS** |
| 语义负向（Mutation） | negative 4/4 + error E1 2/2 | 100%（已闭环注入；E2 NOT_RUN 如实登记） |
| 文档（Documentation） | requirement/architecture/validation-plan/rtm/user-guide | PASS |
| FuseSoC Core | `aixsilicon_vip_axi4_1.0.0.core`（gen-core + vip-check） | PASS |
| RAL 定向验证 | `make -C self_test ral` | PASS |

## 指标对照（Qualification Score）

| 指标 | 目标 | 当前 |
|---|---|---|
| Requirement Traceability | 100% | rtm 骨架（G4 收尾） |
| Mandatory Feature Coverage | 100% | G4 |
| Functional Coverage | ≥95% | G4 |
| Cross Coverage | ≥90% | G4 |
| Checker Mutation Detection | ≥95% | 已闭环注入 100% |
| Assertion Coverage | ≥95% | smoke 内 100% |
| Regression Pass | 100% | 9/9 |
| Known Critical Issues | 0 | 0（限制均非 critical） |

## 运行方法（确定性）

```bash
vip_tool.py vip-check --root vip/amba/axi4          # 结构/元数据检查
make -C vip/amba/axi4/self_test full                # 9 tier 自验证
make -C vip/amba/axi4/self_test cov                 # 功能覆盖（smoke 基线）
vip_tool.py coverage-check --root vip/amba/axi4     # 覆盖率分析
vip_tool.py gen-core --root vip/amba/axi4 --vip axi4 --version 1.0.0 --check-only
```
