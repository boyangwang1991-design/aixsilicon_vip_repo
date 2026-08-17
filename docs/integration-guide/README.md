# 集成指南

本目录面向项目验证工程师，说明如何在 IP / CBB / Subsystem / SoC 环境中装配与复用本仓库的 VIP。

> **详细装配步骤与仓库边界已收编到私有 skill
> [`vip-repo-maintainer`](../../../aixsilicon_skill_repo/skills/vip-repo-maintainer/references/repository-integration.md)**
> （`references/repository-integration.md` §4 下游装配流程）。此处保留仓库边界速览。

## 快速装配

1. 查询 [`catalog/vip_index.yaml`](../../catalog/vip_index.yaml) 与
   [`catalog/compatibility_matrix.yaml`](../../catalog/compatibility_matrix.yaml) 选择兼容 VIP VLNV；
2. 生成 FuseSoC 依赖与环境装配代码；
3. 运行 compile / smoke / regression Gate；证据写入项目 Evidence。

> 注意：项目专用 Env、Virtual Sequence 与 Testcase 应留在 IP / SoC 项目仓库，不放入本 VIP Repo。

## 仓库边界

| 资产 | 归属 |
|---|---|
| 项目专用 Env / Virtual Sequence / Testcase | IP 或 SoC 项目仓库 |
| IP RTL / SoC Top RTL | 项目仓库（VIP 不复制） |
| CSR 定义 | 所属 IP 的 SystemRDL |
| 通用 UVM 基类 | `dv-common`（本仓库 `common/`） |
| 协议 Agent / SVA / Checker | 本仓库 |
