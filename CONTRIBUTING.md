# 贡献指南

欢迎向 AIXSILICON VIP Repository 贡献代码、文档与参考资产。请先阅读
[`plan.md`](plan.md) 与 [`README.md`](README.md)，理解仓库边界与建设目标。

## 目录

1. [工作流程](#工作流程)
2. [第三方资产准入流程](#第三方资产准入流程)
3. [代码规范](#代码规范)
4. [文档要求](#文档要求)
5. [提交与 PR 检查](#提交与-pr-检查)
6. [行为准则](#行为准则)

## 工作流程

1. 从 `main` 拉取最新代码，新建功能分支：`feature/<vip>/<description>` 或 `fix/<vip>/<description>`；
2. 遵守本仓库的 Schema、Metadata 与 FuseSoC 结构约定；
3. 提交前运行结构检查与相关单元测试；
4. 发起 Pull Request，PR 需满足 [PR 检查清单](#提交与-pr-检查)；
5. 由 CODEOWNERS 中对应模块负责人评审合并。

## 第三方资产准入流程

任何开源资产进入正式仓库前必须经过以下 Gate（详见 [`docs/qualification/third_party_admission.md`](docs/qualification/third_party_admission.md)）：

- **G0 来源与许可证**：记录 URL、commit hash、tag、作者、许可证、NOTICE，生成 SBOM；
- **G1 代码结构审计**：确认为可复用 VIP 而非单一 DUT 的 Testbench；
- **G2 协议符合性审计**：建立协议条款 — Requirement ID — Test ID — Coverage ID 映射；
- **G3 隔离 PoC**：最小 Master—Slave loopback、双 DUT、双仿真器、固定种子可复现；
- **G4 交叉验证**：至少两种独立实现交叉检查；
- **G5 内部重构与发布**：适配统一 interface / config / analysis port API，形成 FuseSoC Core。

> 默认拒绝：GPL/AGPL、未知许可证、仅限非商业使用的资产。Apache / Solderpad / MIT 等
> 也需经公司法务或开源办公室确认。

## 代码规范

1. **禁止依赖全局变量**，配置必须通过 config object 传递；
2. 统一支持 `ACTIVE_MASTER` / `ACTIVE_SLAVE` / `PASSIVE` / `DISABLED` 四种模式；
3. 每个 Monitor 至少提供 `transaction_ap`、`error_ap`；按需提供 `request_ap` / `response_ap` / `performance_ap`；
4. 协议结构性差异使用参数、config object、policy class 或独立 VLNV，**不使用编译宏**；
5. 数据比较禁止只依赖 `uvm_object::compare()`，应使用字段级 compare policy（可忽略字段、masked、order-aware 等）；
6. 每个正式 VIP 必须提供自检测试与最小示例；
7. 支持多实例、固定随机种子可复现、仿真器兼容矩阵。

## 文档要求

每个 VIP 至少包含：

- `README.md`
- `docs/requirements.md`（含 Requirement ID）
- `docs/architecture.md`
- `docs/user_guide.md`
- `docs/testplan.md`（Test ID 关联 Requirement ID）
- `docs/coverage_plan.md`（Coverage ID 关联 Requirement / Test ID）
- `metadata/vip.yaml`、`metadata/compatibility.yaml`、`metadata/release_manifest.yaml`

文档均采用中文（简体）编写，术语可保留英文原文。

## 提交与 PR 检查

Pull Request 流水线包含：

1. YAML / Schema / 格式检查；
2. 许可证与 SBOM 检查；
3. FuseSoC Core 解析、依赖闭包与 VLNV 重复检查；
4. Lint 与编译；
5. 受影响 VIP 的 unit / smoke / negative 测试；
6. RTM、Testplan 与 Coverage ID 完整性检查；
7. 文档构建；
8. 影响分析报告。

## 行为准则

- 尊重第三方版权与许可证，不隐去原始版权信息，不将内部重构声称为完全自研；
- 评审以事实、数据与 Gate 为准，不追求代码生成数量；
- 遇到协议规范争议时，以受控环境中记录的协议版本与标准正文为准。
