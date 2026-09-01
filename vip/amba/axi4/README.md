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

`Developing`：**G0 PASS / Requirement Freeze（requirement 1.0.0-g0-baseline）**：协议事实修正（AXI4-Lite capability matrix、
Exclusive 语义、AWATOP 边界）、新增 Feature（AW/W 解耦 / Handshake Pattern / Byte-Lane Model / Zero-strobe）、
**Requirement ID 局部编号**（`AXI4-REQ-<CATEGORY>-<NNN>`：PRO/RUL/TRN/STM/VER/CFG/API/ENG/DBG/STA/REC/DEL/QLF，
附录 A/C，每类别独立 001 起编）、Priority 逐条字段化、outstanding 配置去重、How 下沉 Architecture。
G1（architecture 0.4.0-draft，39 章模板完整完善）已就绪；**G2 源码已开发并 VCS 编译通过；G3 前置 smoke 自验证通过**
（checker 检查 30 笔事务，违规 0）。可选文档（validation-plan/rtm/user-guide）与 examples/fault_injection/fusesoc/qualification 待建。

## 目录

```text
vip/amba/axi4/
├── README.md               # 本文件（总览 + 交付物清单）
├── CHANGELOG.md            # 版本历史（待建）
├── docs/                   # 文档
│   ├── requirement.md      # 需求规格（AXI4-REQ-xxx，G0）
│   └── architecture.md     # 架构与设计（39 章模板，G1）
├── src/                    # VIP 源码（已开发，VCS 编译通过）
│   ├── axi4_types_pkg.sv   # 类型/枚举/编解码（含 lock/exclusive/region）
│   ├── axi4_if.sv          # interface + clocking block + modport（完整信号集对齐 HWIF）
│   ├── axi4_pkg.sv         # 包入口
│   ├── axi4_configuration.sv / axi4_status.sv / axi4_memory.sv
│   ├── transaction/        # axi4_item（master/slave/payload_store）
│   ├── agent/              # monitor / sequencer / driver / agent（master+slave）
│   ├── sequences/          # base / read / write / access / default / smoke
│   ├── coverage/           # axi4_coverage（四层覆盖）
│   ├── checker/            # axi4_checker + axi4_assertions（SVA）
│   └── env/                # axi4_env + axi4_violation_injector
├── self_test/              # VIP Self Test（Makefile + filelist + tb；smoke 通过）
├── fault_injection/        # 错误注入案例（待建）
├── examples/               # 最小集成示例 DUT（待建）
├── fusesoc/                # FuseSoC core（gen-core 生成）
├── qualification/          # Qualification 证据（RTM/report/fault/coverage/limitations）
└── reports/                # 编译/lint/回归/覆盖/变异报告
```

## 交付物清单

| 交付物 | 路径 | 状态 |
| --- | --- | --- |
| 需求规格 | `docs/requirement.md` | ✅ G0（0.9.0-g0，Normalized） |
| 架构与设计 | `docs/architecture.md` | ✅ G1（0.4.0-draft，39 章模板完整完善） |
| 源代码 | `src/` | ✅ G2（VCS 编译 + 链接通过） |
| 自验证 smoke | `self_test/` | ✅ smoke 通过（checker 30 笔/违规 0） |
| 验证方案 | `docs/validation-plan.md` | ⬜ 待建 |
| 追溯矩阵 | `docs/rtm.md` | ⬜ 待建 |
| 用户指南 | `docs/user-guide.md` | ⬜ 待建 |
| 示例 | `examples/` | ⬜ 待建 |
| 测试用例 | `self_test/tests/` | ⬜ 待建 |
| FuseSoC Core | `aixsilicon_vip_axi4_1.0.0.core` | ⬜ gen-core 生成 |
| 元数据 | `metadata/vip.yaml` | ⬜ 待建 |
| Qualification 证据 | `qualification/` | ⬜ 待建 |
| CHANGELOG | `CHANGELOG.md` | ⬜ 待建 |

## 自验证运行

```bash
# 编译（VCS，UVM 1.2；-full64 适配本机链接）
make -C self_test compile

# smoke 自验证
make -C self_test smoke
```

## 开发流程

```text
vip-requirement → vip-architecture → vip-development → vip-test → vip-coverage
→ vip-qualification → vip-release → 发布（G6）
```

## 设计要点（vs tvip-axi 参考）

- **自包含标准 UVM 1.2**，不依赖 tvip-axi 的 tue/tvip-common 外部库；
- 接口采用 **HWIF 完整信号集**（必选 `awlock/arlock`、`awregion/arregion` + capability `awatop`/`*user`）；
- **Exclusive 语义**：`AxLOCK=1` 表达 exclusive access，不支持 AXI3 locked transaction；
- Monitor **只观察重建**，协议规则由 Checker/SVA 检查（Observe → Check → Stimulus）；
- 补齐 tvip-axi 未提供的 **Checker / Coverage / Assertions**；
- Violation Injector 提供错误注入（Mutation 检测率）。
