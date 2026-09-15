# AHB 变异当前评审

## 当前结论：PASS

六个指定源码变异的历史检出证据保留，生产输入未变化。6/6只对应指定故障，不表示全部checker正负向覆盖完成。

## 历史证据与当前验收

历史执行运行：acceptance-clean。当前仅进行计划和证据复用评审，运行身份version-plan-check。复用依据见 [输入复核](../build/version-plan-check/evidence/reuse-review.json)，版本范围见 [版本验收说明](../docs/acceptance.md)。旧候选不代表当前出口授权。

## METADATA

<!-- VIP_METADATA_BEGIN -->
```yaml
schema_version: vip.acceptance/v1
run_id: version-plan-check
generated_at: '2026-09-15T12:12:20.436435+00:00'
producer:
  kind: ai
  agent: Codex
asset:
  vlnv: aixsilicon:vip:ahb:0.1.0
  source_fingerprint: 0bcb2824f53883dbd28c5c1efbe082cd321cc3cf65785d6207af2d1f550fa985
  config_fingerprint: 7d991848fa407a1e1119a58e08a02b82567202a28731a9cf2706c2ea46ca9f24
validated_scope:
- 对0.1.0三配置版本承诺草案与历史执行证据的评审，非新仿真运行
known_limitations:
- 版本承诺清单为draft，尚未形成有效出口结论
- 历史执行成功不等于版本必测覆盖满足
evidence_ids:
- full_s1_w0
- mutation
- observations
- rtm-inventory
- seed-log-review
- source-consistency
- reuse-review
evidence:
- id: full_s1_w0
  path: evidence/historical/full_s1_w0.yaml
  sha256: 0684702f2b314d5bbd64957e6f0fb1f22f152b6bde925b815618f7a2c5520a10
- id: mutation
  path: evidence/historical/mutation.yaml
  sha256: 37e50150af974f9723d093f83c9888f508d0a647566c27847c48af64626f2be7
- id: observations
  path: evidence/historical/observations.json
  sha256: 907b2ef518dc6c97e19c69628d8f77c63a8aa2b698d5f9dd05188ffb94f264ea
- id: rtm-inventory
  path: evidence/historical/rtm-inventory.json
  sha256: 3f255c20d577384314a5a47cc2e9d1fa3d074387c8b17c032fa34ce649ec915f
- id: seed-log-review
  path: evidence/historical/seed-log-review.json
  sha256: 6193c3b93687661747951d1ee2d2bc259986b757cc258f967b3d79146b81b474
- id: source-consistency
  path: evidence/historical/source-consistency.json
  sha256: 6366ae8a7996f0a2236818c804797e1c3cc81e5075dffa16e075fbc04a5a56c7
- id: reuse-review
  path: evidence/reuse-review.json
  sha256: d8de85e958e0bec8bdbb99bd603fa9459b0491affe3258e0d3d4b8e9b1f5a56f
report_kind: mutation
conclusion: PASS
export_allowed: true
blocking_issues: []
checks:
- id: mutation-review
  in_scope: true
  status: PASS
  evidence_ids:
  - reuse-review
  - mutation
execution_run_id: acceptance-clean
```
<!-- VIP_METADATA_END -->
