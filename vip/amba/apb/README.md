# AIXSILICON APB VIP

`aixsilicon:vip:apb:1.0.0` · **FULL_UVM** · APB3/APB4/APB5（ARM IHI 0024E）· 依赖 `aixsilicon:hwif:apb`

## 定位

轻量级标准入门 VIP：**简单协议 + 完整 VIP 工程能力**。VIP-REPO 第二个标杆资产
（AXI4 验证复杂协议方法论，APB 验证"轻量 VIP 开发效率/质量/复用平衡"）。
服务 UART/GPIO/Timer/CRG/EFUSE/Watchdog/CSR 等 APB 外设验证，及 RAL 标准后端。

## 能力总览

| 能力 | 说明 |
|---|---|
| Agent | Requester（master）/ Completer（slave）/ Passive / Disabled |
| 协议版本 | APB3 / APB4 / APB5（配置选择；1.0.0 三版本 conformance 均 P0） |
| APB4+ | PSTRB / PPROT |
| APB5+（正交叠加） | USER 三宽度 / PWAKEUP / RME-PNSE / *CHK 奇校验 |
| Checker | SVA-first（generate 只依赖 interface 参数）+ UVM 语义 checker + X-check |
| anti-overcheck | PREADY 常高合法（UT17）/ PSLVERR 窗外不误报（UT18）/ UNPREDICTABLE 分层 |
| Coverage | CP-01..08 / CR-01..06（normalized transaction，非物理引脚） |
| RAL | adapter（P0）+ predictor（P1）；response ownership：req item 自携带响应 |
| Completer | generic memory-backed responder（四层：sequence/memory/error/wait policy） |

## 核心架构原则（ADR-0）

> **Physical interface capability（interface 参数，elaboration-time）与
> runtime verification policy（apb_config）严格分离。**

## 目录

```text
docs/          requirement / architecture / validation-plan / rtm / user-guide
src/           types / if / pkg / transaction / agent / sequences / checker / coverage / ral / env
unit_test/     L1 golden vectors（无 UVM）
self_test/     smoke / feature / corner / error / random / mutation（Makefile）
reports/       run_log / gate_status / mutation / coverage（唯一报告出口）
```

## 快速开始

```bash
make -C self_test unit        # L1 unit test
make -C self_test regression  # 5 tier 回归
```

集成与配置详见 [docs/user-guide.md](docs/user-guide.md)。

## 状态

| Gate | 状态 |
|---|---|
| G0 Requirement | PASS（r3.1 Freeze） |
| G1 Architecture | PASS（r4 Freeze） |
| G2 Code | **PASS**（编译 + L1 unit 72/72，VCS W-2024.09-SP1） |
| G3 Self-Verification | **PASS**（5 tier 全绿 UVM_ERROR=0 + anti-overcheck） |
| G5 Qualification | **PARTIAL**（mutation 5/5 检出率 100%） |
| G4/G6 | NOT_RUN（覆盖闭合/发布待执行） |

证据：[reports/run_log.md](reports/run_log.md) · [reports/gate_status.md](reports/gate_status.md) · [reports/mutation/](reports/mutation/mutation_report.md)

交付物：FuseSoC core `aixsilicon_vip_apb_1.0.0.core`、开源全量源码、五份文档。
