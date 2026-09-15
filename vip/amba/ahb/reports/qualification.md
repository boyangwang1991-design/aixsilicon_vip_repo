# AHB 当前出口资格

## 结论：BLOCKED，当前不授权出口

此前“G0–G6全部通过”的笼统资格结论已撤回。历史运行结果没有作废，但尚不足以证明新版本承诺全部满足。没有将真实执行结果改成FAIL。

## 有限清单与闭合路径

| 承诺项 | 可复用证据 | 尚需完成 |
| --- | --- | --- |
| BUILD-UNIT | 编译、单元和FuseSoC通过 | 按最终承诺确认配置集合 |
| LITE-TRANSFER | 20/48读写×Burst×尺寸命中 | 补28个组合及正确性检查 |
| LITE-RECOVERY | 五档等待、ERROR、复位与向量通过 | 将具体必测点绑定到对应证据 |
| AHB5-EXT | 现有扩展定向通过 | 明确扩展承诺边界，补齐必测点及负向映射 |
| CLASSIC-REPLAY | 既有重放与读回通过 | 将RETRY/SPLIT等功能采集映射完整 |
| CHECKER-NEG | 六变异、21条负向规则见证 | 选择并核对正式承诺涉及的关键规则正负向 |
| INTEGRATION | 原core与候选构造成功 | 最终资格通过后生成新绑定候选 |

这是一份7项有限版本清单，不要求本版本完成全部169条合同或全部204交叉点。清单仍是draft；保留三配置方向，没有擅自采纳AHB-Lite-only方案。范围确定后冻结，只补缺项与受影响测试。

## 证据复用

本次未修改SV和实际仿真输入，未重新执行EDA仿真。原始运行acceptance-clean的13/13基线、5/5等待、300/300种子、百万beat和6个变异结果保留。当前输入复核及变更说明见 [复用审查](../build/version-plan-check/evidence/reuse-review.json)。文档和计划变化使旧资格失效，不意味着这些原始日志无效。

新资格由AI直接填写，公共脚本只核对计划绑定、字段与证据一致性。旧package作为历史构建产物留在build，不再代表当前出口授权。

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
report_kind: qualification
conclusion: BLOCKED
export_allowed: false
blocking_issues:
- 版本范围及有限清单尚未冻结
- 版本必测覆盖存在未完成项
acceptance_plan:
  path: config/release-plan.yaml
  sha256: e1c0cd311f83ae3ac2f777f6bd7d2500d8c9332407b62bbe5bbcdf5f6fff4192
release_scope:
  supported:
  - 拟承诺Lite32：VCS/UVM1.2，读写、合法Burst与size0/1/2、等待/ERROR/复位
  - 拟保留AHB5_128：现有SINGLE size2/4扩展定向能力
  - 拟保留Classic32：现有SINGLE size2与RETRY/SPLIT重放定向能力
  experimental: []
  unsupported:
  - 未承诺的完整1.0.0协议组合、公共HWIF认证、第二工具和IEEE1800.2
checks:
- id: BUILD-UNIT
  in_scope: true
  status: BLOCKED
  evidence_ids:
  - reuse-review
  - observations
- id: LITE-TRANSFER
  in_scope: true
  status: BLOCKED
  evidence_ids:
  - reuse-review
  - observations
- id: LITE-RECOVERY
  in_scope: true
  status: BLOCKED
  evidence_ids:
  - reuse-review
  - observations
- id: AHB5-EXT
  in_scope: true
  status: BLOCKED
  evidence_ids:
  - reuse-review
  - observations
- id: CLASSIC-REPLAY
  in_scope: true
  status: BLOCKED
  evidence_ids:
  - reuse-review
  - observations
- id: CHECKER-NEG
  in_scope: true
  status: BLOCKED
  evidence_ids:
  - reuse-review
  - observations
- id: INTEGRATION
  in_scope: true
  status: BLOCKED
  evidence_ids:
  - reuse-review
  - observations
```
<!-- VIP_METADATA_END -->
