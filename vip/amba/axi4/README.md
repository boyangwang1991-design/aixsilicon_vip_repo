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

`Developing`（当前仅 `docs/` 就绪：需求 G0（0.3.0-draft，含 AXI4 能力模型 + External Interface 需求）/ 架构 G1 输入；`src/` 源码与 Self Test 待开发）

## 目录

```text
vip/amba/axi4/
├── README.md               # 本文件（总览 + 交付物清单）
├── CHANGELOG.md            # 版本历史（待建）
├── docs/                   # 文档
│   ├── requirement.md      # 需求规格（AXI4-REQ-xxx，G0）
│   └── architecture.md     # 架构与设计（Profile/组件/接口/时序，G1）
├── src/                    # VIP 源码（待开发：pkg/if/transaction/agent/sequences/coverage/checker/env）
├── self_test/              # VIP Self Test Environment（待建）
├── fault_injection/        # 错误注入案例（待建）
├── examples/               # 最小集成示例 DUT（待建）
├── fusesoc/                # FuseSoC core（gen-core 生成）
├── qualification/          # Qualification 证据（RTM/report/fault/coverage/limitations）
└── reports/                # 编译/lint/回归/覆盖/变异报告
```

## 交付物清单

| 交付物 | 路径 | 状态 |
| --- | --- | --- |
| 需求规格 | `docs/requirement.md` | ✅ G0（0.3.0-draft） |
| 架构与设计 | `docs/architecture.md` | ✅ G1 输入 |
| 验证方案 | `docs/validation-plan.md` | ⬜ 待建 |
| 追溯矩阵 | `docs/rtm.md` | ⬜ 待建 |
| 用户指南 | `docs/user-guide.md` | ⬜ 待建 |
| 示例 | `examples/` | ⬜ 待建 |
| 测试用例 | `self_test/tests/` | ⬜ 待建 |
| 源代码 | `src/` | ⬜ 待建 |
| FuseSoC Core | `aixsilicon_vip_axi4_1.0.0.core` | ⬜ gen-core 生成 |
| 元数据 | `metadata/vip.yaml` | ⬜ 待建 |
| Qualification 证据 | `qualification/` | ⬜ 待建 |
| CHANGELOG | `CHANGELOG.md` | ⬜ 待建 |

## 开发流程

```text
vip-requirement → vip-architecture → vip-development → vip-test → vip-coverage
→ vip-qualification → vip-release → 发布（G6）
```
