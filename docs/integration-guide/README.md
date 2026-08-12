# 集成指南

本目录面向项目验证工程师，说明如何在 IP / CBB / Subsystem / SoC 环境中装配与复用本仓库的 VIP。

## 集成步骤

1. 从 IP / SoC 接口 Metadata 识别协议与版本；
2. 查询 [`catalog/vip_index.yaml`](../../catalog/vip_index.yaml) 与
   [`catalog/compatibility_matrix.yaml`](../../catalog/compatibility_matrix.yaml)，
   选择兼容且成熟度足够的 VIP VLNV；
3. 生成 FuseSoC 依赖与环境装配代码；
4. 生成 IP 专用 Config、Virtual Sequence、Reference Model adapter 与 Scoreboard；
5. 将 Requirement ID 映射到 VIP sequence、项目 testcase 与 coverage；
6. 运行 compile / smoke / regression Gate；
7. 将日志、coverage、seed、工具版本与 hash 写入 Evidence；
8. 在 AIXSILICON 项目座舱展示 VIP 版本、质量等级与复用关系。

> 注意：项目专用 Env、Virtual Sequence 与 Testcase 应留在 IP / SoC 项目仓库，
> 不放入本 VIP Repo。

## 仓库边界提示

| 资产 | 归属 |
|---|---|
| 项目专用 Env / Virtual Sequence / Testcase | IP 或 SoC 项目仓库 |
| IP RTL / SoC Top RTL | 项目仓库（VIP 不复制） |
| CSR 定义 | 所属 IP 的 SystemRDL |
| 通用 UVM 基类 | `dv-common`（本仓库 `common/`） |
| 协议 Agent / SVA / Checker | 本仓库 |

## 交叉验证建议

- 内部 UVM Master ↔ cocotbext 或 PULP 参考 Slave；
- TVIP Master ↔ 内部 Slave；
- 内部 Master ↔ PULP AXI 模块；
- 协议 SVA ↔ 故意带 Bug 的 mutation DUT；
- 商业 VIP ↔ 内部 VIP（条件允许时）。
