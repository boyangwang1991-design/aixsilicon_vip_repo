# 覆盖分析报告

## 结论

能够出口（就本报告范围）：版本必测覆盖 bin 全部命中，bin 集合与冻结计划一致。

## 版本必测覆盖与完整能力矩阵

版本必测覆盖（`config/verification-plan.yaml` 的 `coverage_bins`）：

| 指标 | 命中 | 实测未命中 | 未采集 | 命中率 |
| --- | --- | --- | --- | --- |
| requirement_coverage | 90/90 | 0 | 0 | 100.0% |
| feature_coverage | 32/32 | 0 | 0 | 100.0% |
| cross_coverage | 5/5 | 0 | 0 | 100.0% |
| assertion_coverage | 9/9 | 0 | 0 | 100.0% |

完整能力矩阵（全参数笛卡尔积）未定义映射，记 NOT_RUN，不写成 0%，也不据此否定已测范围。

## 范围与结果

| 检查项 | 范围内 | 实际状态 | 证据与解释 |
| --- | --- | --- | --- |
| 四项 bin 集合与计划一致 | 是 | PASS | `problems=[]` |
| 命中率达标 | 是 | PASS | 四项均 100% |
| mandatory hole | 是 | PASS | 无 mandatory OPEN hole |

## 问题与限制

覆盖只统计自验证 tier 实际发生的总线事件（REQ-COV-001）；百分比为解释性信息，
判定以 bin→hit 映射为准（REQ-ACC-003）。

## 证据索引

build/run-004/coverage/coverage_bins.json；build/run-004/logs/cov_*.txt

## METADATA

## METADATA

## METADATA

<!-- VIP_METADATA_BEGIN -->
```yaml
schema_version: vip.acceptance/v1
report_kind: coverage
run_id: run-004
generated_at: '2026-09-15T12:34:11.089159Z'
producer:
  kind: ai
  agent: zoo-code
asset:
  vlnv: aixsilicon:vip:axi4_stream:1.0.0
  source_fingerprint: 3e5946084fadfa1a0fb000c92c4545b8ae6b25f084e58e6ec1cb68b8fcd01c5c
  config_fingerprint: e9a3251fa3961ccae5de8c7838f5e4e80713bb21f60783109f6ad8578a32ee20
conclusion: PASS
export_allowed: true
validated_scope:
- 四项版本必测覆盖 bin（req/feature/cross/assertion）
blocking_issues: []
known_limitations:
- 完整能力矩阵（全参数笛卡尔积）未定义映射，未采集项记 null 而非 0%
checks:
- id: bin_inventory
  in_scope: true
  status: PASS
  evidence_ids:
  - coverage_export
- id: full_matrix
  in_scope: false
  status: NOT_RUN
  evidence_ids: []
evidence_ids:
- coverage_export
evidence:
- id: coverage_export
  path: logs/coverage_export.log
  sha256: e42c9bb982bf76990c727c9d79121a9fcc33b813981da8a68e62bf2172d4747b
  kind: coverage
```
<!-- VIP_METADATA_END -->
