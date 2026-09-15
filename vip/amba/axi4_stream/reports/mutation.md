# 变异验证报告

## 结论

能够出口（就本报告范围）：12/12 语义变异被检出，满足 ≥95% 且 P0 全命中。

## 范围与结果

| 检查项 | 范围内 | 实际状态 | 证据与解释 |
| --- | --- | --- | --- |
| 12 项语义变异检出 | 是 | PASS | 隔离副本内逐项编译+运行，均命中预期证据串 |
| 变异不修改生产源码 | 是 | PASS | 全部在 build/run-004/mutant/<id> 内执行 |

## 问题与限制

变异集中在 axi4_stream_types_pkg（单一语义实现点）；时序类语义的装配级检出由
regression 的 scoreboard 计数与 checker 规则命中覆盖（ADR8）。

## 证据索引

build/run-004/logs/MUT-*.log

## METADATA

## METADATA

<!-- VIP_METADATA_BEGIN -->
```yaml
schema_version: vip.acceptance/v1
report_kind: mutation
run_id: run-004
generated_at: '2026-09-15T12:19:51.900269Z'
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
- axi4_stream_types_pkg 的 12 项协议语义变异
blocking_issues: []
known_limitations: []
checks:
- id: MUT-BYTE-CLASS
  in_scope: true
  status: PASS
  evidence_ids:
  - MUT-BYTE-CLASS
- id: MUT-NULL-REMOVE
  in_scope: true
  status: PASS
  evidence_ids:
  - MUT-NULL-REMOVE
- id: MUT-END-PACKET
  in_scope: true
  status: PASS
  evidence_ids:
  - MUT-END-PACKET
- id: MUT-KEEP-DEFAULT
  in_scope: true
  status: PASS
  evidence_ids:
  - MUT-KEEP-DEFAULT
- id: MUT-ILLEGAL-COMB
  in_scope: true
  status: PASS
  evidence_ids:
  - MUT-ILLEGAL-COMB
- id: MUT-CFG-NODATA
  in_scope: true
  status: PASS
  evidence_ids:
  - MUT-CFG-NODATA
- id: MUT-BEAT-COUNT
  in_scope: true
  status: PASS
  evidence_ids:
  - MUT-BEAT-COUNT
- id: MUT-KEEP-BEAT
  in_scope: true
  status: PASS
  evidence_ids:
  - MUT-KEEP-BEAT
- id: MUT-EXPRESSIBLE
  in_scope: true
  status: PASS
  evidence_ids:
  - MUT-EXPRESSIBLE
- id: MUT-EXACT-COMPARE
  in_scope: true
  status: PASS
  evidence_ids:
  - MUT-EXACT-COMPARE
- id: MUT-TOKEN-EQ
  in_scope: true
  status: PASS
  evidence_ids:
  - MUT-TOKEN-EQ
- id: MUT-PAYLOAD-X
  in_scope: true
  status: PASS
  evidence_ids:
  - MUT-PAYLOAD-X
evidence_ids:
- MUT-BYTE-CLASS
- MUT-NULL-REMOVE
- MUT-END-PACKET
- MUT-KEEP-DEFAULT
- MUT-ILLEGAL-COMB
- MUT-CFG-NODATA
- MUT-BEAT-COUNT
- MUT-KEEP-BEAT
- MUT-EXPRESSIBLE
- MUT-EXACT-COMPARE
- MUT-TOKEN-EQ
- MUT-PAYLOAD-X
evidence:
- id: MUT-BYTE-CLASS
  path: logs/MUT-BYTE-CLASS.log
  sha256: 60c012b5bbddf305b04cb73d725d9e4582e836ee64bf4113ae873abb77e3e165
  kind: log
- id: MUT-NULL-REMOVE
  path: logs/MUT-NULL-REMOVE.log
  sha256: 32c0542eb00b95f3717fba6eae94cd99972e445e35ff0d007da6112c51918fe7
  kind: log
- id: MUT-END-PACKET
  path: logs/MUT-END-PACKET.log
  sha256: e8e86785d4cb5f7c7f0f79c50f8e2f15aa5f578082a388c5700832f109782afe
  kind: log
- id: MUT-KEEP-DEFAULT
  path: logs/MUT-KEEP-DEFAULT.log
  sha256: 5462980f6db7340d03183e500590b00add3fe987f6d7e223bab32ba7adea41b2
  kind: log
- id: MUT-ILLEGAL-COMB
  path: logs/MUT-ILLEGAL-COMB.log
  sha256: 881768c7e5ae419169d48147295dcfec5334cd0798ab2017708a9acc492f6cf3
  kind: log
- id: MUT-CFG-NODATA
  path: logs/MUT-CFG-NODATA.log
  sha256: a580869be2fc784a6fdc9e6688f5145434675fc0b923cfc5b275407022380ddb
  kind: log
- id: MUT-BEAT-COUNT
  path: logs/MUT-BEAT-COUNT.log
  sha256: 70e0d3e02e68c2d55e528827475af285bf161cabef6482b277ae93dc0cfff186
  kind: log
- id: MUT-KEEP-BEAT
  path: logs/MUT-KEEP-BEAT.log
  sha256: a680d6f56219931e6c29d001fcef273dbaac750689cf12c92428def4959f2266
  kind: log
- id: MUT-EXPRESSIBLE
  path: logs/MUT-EXPRESSIBLE.log
  sha256: 0d861e3cda8702dab90f8e9c2971828bde3926dc6c6c3678599a090eddca4e6a
  kind: log
- id: MUT-EXACT-COMPARE
  path: logs/MUT-EXACT-COMPARE.log
  sha256: d29934f10a46b9e2257aa22dd7ecf586e0347a2b50c43271ac72a017eddb0265
  kind: log
- id: MUT-TOKEN-EQ
  path: logs/MUT-TOKEN-EQ.log
  sha256: 3a83d353d1f0c992231b47df6cf970a6cb90b51d42dbadacfcbc4f1a13046771
  kind: log
- id: MUT-PAYLOAD-X
  path: logs/MUT-PAYLOAD-X.log
  sha256: 17d1ea54224fe10df19ee7a4f2478c490560fcf0cb83669ce5c5e93633c2227d
  kind: log
```
<!-- VIP_METADATA_END -->
