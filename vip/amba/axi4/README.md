# AXI4 VIP

> AIXSILICON AMBA AXI4 / AXI4-Lite 协议验证 IP（VIP-001，developing 阶段）。
> 工程包驻留在 `aixsilicon_vip_repo/vip/amba/axi4/`，按 `vip-development-suite` 流程开发，
> Qualified（G5）并通过发布门禁（G6）后方可发布为正式资产。

- **VLNV**: `aixsilicon:vip:axi4:1.0.0`（目标发布版本）
- **Profile**: `FULL_UVM`
- **Category**: `amba`
- **ID**: `VIP-001`（[`registry.yaml`](../../registry.yaml)）
- **HWIF**: `aixsilicon:hwif:axi`（`IFC-AXI-001`）—— 接口契约唯一来源，VIP 不重复定义

## 状态

Gate 判定唯一来源：[reports/gate_status.md](reports/gate_status.md)。
当前：**G0/G1/G2/G3 PASS；G5 PARTIAL（mutation 100% 闭环，G4 覆盖闭合未完成）；G4/G6 NOT_RUN**。

- **self_test 9 tier 全 PASS**：smoke/feature/corner/negative/random/stress/concurrent/error/ral；
- **mutation 闭环**：negative 4/4 + error E1 2/2 = 100%（E2 RUL-011 SVA 诚实 NOT_RUN）；
- **RAL 定向验证 PASS**（adapter + predictor + 物理 memory 读回一致）；
- **L1 Unit Test 79/79 PASS**；
- **剩余（G4）**：四层覆盖闭合、E2（stall 时序）、C3（decouple clocking 沿）、outstanding 读异步化
  （限制登记于 [requirement §23 LIM-007/008](docs/requirement.md)）。

## 目录

```text
vip/amba/axi4/
├── README.md               # 本文件
├── docs/                   # requirement / architecture / validation-plan / rtm / user-guide
├── src/                    # VIP 源码（types/if/config/status/memory/pkg/transaction/agent/
│                           #  sequences/coverage/checker/env，VCS 编译通过）
├── self_test/              # 9 tier 回归（Makefile + filelist + tb）
├── examples/               # 最小集成示例 DUT
└── reports/                # 唯一报告出口：run_log / gate_status / mutation/ / coverage/
```

> 开发期不维护 CHANGELOG.md（版本语义记于 reports/run_log.md 版本小节；
> CHANGELOG 由 release 阶段一次性汇出）；不设 qualification/、fault_injection/、metadata/
> 独立目录（Gate 判定在 reports/gate_status.md，FI case 在 validation-plan，Limitations 在 requirement §23）。

## 交付物清单

| 交付物 | 路径 | 状态 |
| --- | --- | --- |
| 需求规格 | `docs/requirement.md` | G0 PASS（1.0.0-g0-baseline） |
| 架构与设计 | `docs/architecture.md` | G1 PASS（0.4.0-draft，运行时模型冻结） |
| 验证方案 | `docs/validation-plan.md` | Freeze（RUL mapping 校正 + G3~G6 分层） |
| 追溯矩阵 | `docs/rtm.md` | Draft（诚实标注 NOT_RUN/PARTIAL，G4 收尾） |
| 用户指南 | `docs/user-guide.md` | Draft |
| 源代码 | `src/` | G2 PASS（VCS 编译 + 9/9 全回归） |
| 自验证 | `self_test/` | 9 tier（smoke/feature/corner/negative/random/stress/concurrent/error/ral） |
| Gate 判定 | `reports/gate_status.md` | 持续更新 |
| 执行日志 | `reports/run_log.md` | 唯一运行日志 |
| Mutation 报告 | `reports/mutation/mutation_report.md` | 已闭环注入 100%（E2 NOT_RUN 如实） |
| 覆盖率报告 | `reports/coverage/coverage_report.md` | 骨架（G4） |
| 示例 | `examples/` | 待建 |
| FuseSoC Core | `aixsilicon_vip_axi4_1.0.0.core` | 已生成（gen-core + vip-check） |

## 自验证运行

```bash
# 编译（VCS，UVM 1.2；-full64 适配本机链接）
make -C self_test compile

# 全回归（9 tier）
make -C self_test full

# 功能覆盖（smoke 基线）
make -C self_test cov
```

## 设计要点（vs tvip-axi 参考）

- **自包含标准 UVM 1.2**，不依赖 tvip-axi 的 tue/tvip-common 外部库；
- 接口采用 **HWIF 完整信号集**（必选 `awlock/arlock`、`awregion/arregion` + capability `awatop`/`*user`）；
- **Exclusive 语义**：`AxLOCK=1` 表达 exclusive access，不支持 AXI3 locked transaction；
- Monitor **只观察重建**，协议规则由 Checker/SVA 检查（Observe → Check → Stimulus）；
- 补齐 tvip-axi 未提供的 **Checker / Coverage / Assertions**；
- Violation Injector 提供错误注入（Mutation 检测率）。
