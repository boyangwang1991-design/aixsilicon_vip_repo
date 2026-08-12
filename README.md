# AIXSILICON VIP Repository

> 一套可版本化、可组合、可验证、可发布、可被 RTL Coding / UVM Verification Skill Suite 消费的验证资产平台。

本仓库依据 [`plan.md`](plan.md)（V1.0，2026-08-12）建设，采用 **一个 VIP Monorepo + 每个 VIP 独立 FuseSoC Core + 统一公共基类 + 统一 Release Catalog 索引** 的结构。

- 工程底座：SystemVerilog / UVM、FuseSoC、YAML SSOT、SystemRDL / PeakRDL、统一 Catalog、DVSim / EDA 适配层
- 覆盖范围：IP 级、CBB 级、Subsystem 级、SoC 集成验证

## 仓库边界

| 资产 | 所属仓库 | 说明 |
|---|---|---|
| 通用 UVM 基类、通用 Scoreboard 框架 | `dv-common` | 所有 VIP 和项目环境共同依赖 |
| AXI / APB / UART 等协议 Agent | 本仓库（`protocol/`、`peripheral/`） | 核心内容 |
| SV interface、typedef、modport、接口语义 | `hw-interfaces` | 设计与验证共享的接口契约 |
| 项目专用 Env、Virtual Sequence、Testcase | IP 或 SoC 项目仓库 | 与被测对象版本绑定 |
| 通用协议 SVA、Protocol Checker | 本仓库 | 与对应 VIP 共同发布 |
| CSR 定义 | 所属 IP 的 SystemRDL | 不在 VIP 重复定义 |
| UVM RAL 生成工具 | `eda-flow` 或工具仓 | VIP 提供 adapter / predictor |
| SoC 地址、中断、时钟复位配置 | `soc-integration` | VIP 只提供对应激励/监测组件 |
| 商业 VIP 适配器 | 受控内部仓库 | 与开源 VIP 隔离，遵守许可证 |

> 本项目不存放：项目专用 Testbench / Scoreboard / Testcase、IP RTL 或 SoC Top RTL、第三方商业 VIP 源码、未 Qualify 的教学示例。

## 目录结构

```text
├── README.md
├── LICENSES/
├── CONTRIBUTING.md
├── CODEOWNERS
├── CHANGELOG.md
├── docs/            # 架构 / 开发 / 集成 / Qualification 文档
├── schema/          # VIP Metadata / Testplan / Coverage / Release Manifest Schema
├── common/          # VIP Common（公共配置、transaction policy、日志、结果）
├── protocol/        # apb / axi_lite / axi / axi_stream / ahb_lite / ready_valid
├── peripheral/      # uart / spi / i2c / gpio / jtag_dmi
├── system/          # clock_reset / interrupt / generic_memory / csr_access / ...
├── safety/          # bus_fault / ecc_parity_fault / interrupt_fault / ... / fault_campaign
├── adapters/        # ral / scoreboard / commercial_vip / cocotb_crosscheck
├── formal/          # protocol_properties / harness
├── examples/
├── tests/           # unit / compatibility / negative / stress / mutation
├── vendor/          # 第三方来源 Manifest / patches（只记录，不复制源码）
├── tools/           # metadata_check / testplan_check / package_release / catalog_export
└── catalog/         # vip_index.yaml / compatibility_matrix.yaml
```

## 单 VIP 标准结构（示例：`protocol/apb/`）

每个正式 VIP 按 [`protocol/apb/README.md`](protocol/apb/README.md) 的模板组织，包含
`docs/`、`metadata/`、`src/`、`sva/`、`seq/`、`tb/`、`tests/`、`examples/`、
FuseSoC Core（`.core`）与 `CHANGELOG.md`。

## 推荐 VLNV 命名

```text
aix:vip:common:1.0.0
aix:vip:apb:1.0.0
aix:vip:axi_lite:1.0.0
aix:vip:axi:1.0.0
aix:vip:uart:1.0.0
aix:vip:clock_reset:1.0.0
```

## 快速开始

```bash
# 1. 查看 Catalog 中已登记的 VIP 与兼容矩阵
cat catalog/vip_index.yaml

# 2. 基于 APB 模板生成一个新 VIP 骨架（示例）
python3 tools/vip_new/templates  # 或参考 protocol/apb/ 手动拷贝

# 3. 使用 FuseSoC 解析某个 VIP Core 的依赖与 target
fusesoc core show aix:vip:apb:1.0.0 --cores-root=.

# 4. 结构 / Metadata 校验
python3 tools/metadata_check/check_metadata.py protocol/apb/metadata/vip.yaml
```

## 建设状态

| 阶段 | 目标 | 状态 |
|---|---|---|
| P0 | VIP Common / Clock-Reset / Ready-Valid / APB / Generic Memory / Interrupt | 框架就绪，代码开发中 |
| P1 | AXI4-Lite / AXI-Stream / 外设 VIP | 规划中 |
| P2 | 完整 AXI4 / 功能安全故障注入 | 规划中 |

详细路线图见 [`docs/architecture/roadmap.md`](docs/architecture/roadmap.md) 与 [`plan.md`](plan.md)。

## 参考开源项目

本仓库所有开源参考项目的下载、来源锁定与许可证记录见
[`reference/REFERENCE_MANIFEST.md`](reference/REFERENCE_MANIFEST.md)。
第三方代码一律不直接复制进本仓库源码目录，仅通过 FuseSoC 依赖外部已发布 Core，
或在 `vendor/` 中记录来源 Manifest、锁定 commit、许可证与补丁。

## License

本仓库代码默认采用 Apache-2.0，详见 [`LICENSES/`](LICENSES/)。
各第三方参考项目版权归其各自作者所有。
