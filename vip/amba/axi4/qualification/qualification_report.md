# AXI4 VIP Qualification 报告（G5）

> `aixsilicon:vip:axi4:1.0.0`（VIP-001，FULL_UVM，amba）
> 环境：VCS W-2024.09-SP1 / UVM 1.2 / seed=1
> 结论：**G5 Qualification 主体达成（struct/compile/regression/doc 通过）；G4 覆盖闭合与
> E2/C3 两项 NOT_RUN 待 G4 深化。** 状态如实，禁止伪报。

## 检查项

| 项 | 命令/证据 | 结果 |
| --- | --- | --- |
| 结构（Structure） | `vip_tool.py vip-check --root ...` | ✅ PASS |
| 编译（Compile） | `make -C self_test compile` | ✅ PASS（0 错误） |
| L1 Unit Test | `make -C self_test unit` | ✅ 79/79 PASS |
| 自验证（Self-Test） | `make -C self_test full`（9 tier） | ✅ **9/9 PASS** |
| 语义负向（Mutation detected） | negative 4/4 + error E1 2/2 | ✅ 100%（已闭环注入） |
| 文档（Documentation） | requirement/architecture/validation-plan/rtm/user-guide/README/CHANGELOG | ✅ |
| FuseSoC Core | `aixsilicon_vip_axi4_1.0.0.core`（gen-core 生成 + vip-check 校验） | ✅ |
| RAL 定向验证 | `make -C self_test ral` | ✅ PASS |
| 覆盖率（Coverage） | `make cov` + coverage-report | ⚠️ 骨架（G4） |
| E2（RUL-011）/ C3（decouple） | — | ⚠️ NOT_RUN（known_limitations #1/#2） |

## 指标对照

| 指标 | 目标 | 当前 |
| --- | --- | --- |
| Requirement Traceability | 100% | ⚠️ rtm 骨架（G4 收尾） |
| Mandatory Feature Coverage | 100% | ⚠️ G4 |
| Functional Coverage | ≥95% | ⚠️ G4 |
| Cross Coverage | ≥90% | ⚠️ G4 |
| Checker Mutation Detection | ≥95% | ✅ 已闭环注入 100% |
| Assertion Coverage | ≥95% | ✅ smoke 内 100% |
| Regression Pass | 100% | ✅ 9/9 |
| Known Critical Issues | 0 | ✅ 0（限制均非 critical） |

## 结论

- **G5 主体条件满足**：结构/编译/回归/文档/FuseSoC/RAL 全通过，已闭环 mutation 100%；
- **G4 未闭合**：四层覆盖闭合、E2/C3 两项 NOT_RUN → 不可发「Qualified」结论；
- 满足**进入 G4 覆盖闭合阶段**的全部前置（稳定 9/9 回归 + 负向检出 + 文档 + FuseSoC 包）。