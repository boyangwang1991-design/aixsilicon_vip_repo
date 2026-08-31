# Changelog

All notable changes to the AIXSILICON VIP Repository are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- 按 `plan.md` 重建仓库定位：VIP REPO 从"开发 + 存放"调整为 **认证 VIP 资产库（产品货架）**。
  - 开发职责移交 `vip-development-suite`（VIP 工厂）；本仓库只负责
    `Plan → Accept → Qualify → Catalog → Version → Distribute`。
- 目录结构重构为 `vip/{amba,peripheral,memory,chip,debug,io,storage,safety,common}` 分类组织。
- VLNV 统一升级为 `aixsilicon:vip:<name>:<version>`（存量 `aix:vip:*` 不再使用）。
- 新增 `registry.yaml` 作为 VIP 状态唯一 SSOT（参考 cbb repo 治理模式），
  `vip_catalog.md` 与 README 状态总览由脚本派生。
- 新增 `tools/` 确定性脚本（gen_catalog / check_vip / regression）。
- 删除存量未 Qualified 的 VIP 资产（protocol/peripheral/system/safety/common 等），
  待 VIP Development Suite 产出并通过质量门禁后重新准入。

### Added
- FuseSoC Library 注册（`fusesoc.conf`）。
- `vip_catalog.md` 自动生成索引。

### Removed
- 存量 `aix:vip:*` 资产（APB/AXI/HAC-IF 等 V0_PROTOTYPE 工程包）。
- 旧分类目录 `protocol/`、`peripheral/`、`system/`、`safety/`、`common/`、`adapters/`、`formal/`。
- 旧仓库级目录 `catalog/`、`docs/`（旧版）、`examples/`、`schema/`、`vendor/`。
- 仓库级规范文档（`docs/`）与模板（`templates/`）——统一由 `vip-repo-maintainer` skill 约束。

## [0.1.0] - 2026-08

### Added
- 初始仓库骨架（原始版本）。
