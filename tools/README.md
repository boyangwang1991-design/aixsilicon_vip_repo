# tools — 工具脚本

确定性任务（校验、构建、运行、报告、发布）由脚本完成；专业决策由 Skill Suite 负责。

| 工具 | 目录 | 用途 |
|---|---|---|
| Metadata 校验 | [`metadata_check/`](metadata_check/) | 校验 `metadata/vip.yaml` 等符合 Schema |
| Testplan 校验 | [`testplan_check/`](testplan_check/) | 校验 testplan / coverage / RTM ID 完整性 |
| 新 VIP 生成 | [`vip_new/`](vip_new/) | 基于 APB 模板生成新 VIP 骨架 |
| 发布打包 | [`package_release/`](package_release/) | 生成发布包、Release Manifest 与 SBOM |
| Catalog 导出 | [`catalog_export/`](catalog_export/) | 汇总各 VIP metadata 到 `catalog/` 索引 |

## 运行要求

- Python 3.6+；
- PyYAML（`pip install pyyaml`）；
- FuseSoC 2.x（可选，用于 target 解析）。

## 约定

- 脚本只做确定性任务，不做专业判断；
- 所有脚本以 `exit code` 表达结果，供 CI 使用；
- 输出结构化日志，便于记录到 Evidence。
