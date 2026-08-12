# coverage_utils — 覆盖率辅助

功能覆盖率收集的公共辅助组件。

## 能力

- 覆盖点 / cross / transition 的统一登记与命名；
- 覆盖率合并与门限报告（关联 `schema/coverage.schema.yaml` 的 COV ID）；
- 覆盖率导出为可被 Catalog 消费的结构化数据；
- 与 CI 的 Coverage Merge 与质量 Dashboard 对接。

## 规划文件

- [`src/vip_coverage_utils.sv`](src/vip_coverage_utils.sv) — 覆盖率工具（规划中）
