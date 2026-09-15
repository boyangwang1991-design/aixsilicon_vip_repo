# 回归报告

## 结论

能够出口（就本报告范围）：L1 golden vector、15 个仿真 tier、CHECKER_ONLY、结构检查与多 seed 矩阵全部通过。

## 范围与结果

| 检查项 | 范围内 | 实际状态 | 证据与解释 |
| --- | --- | --- | --- |
| compile / unit | 是 | PASS | VCS 编译成功；UNIT_TEST_PASS（226 断言 0 失败） |
| smoke/feature/corner/random/config/passive | 是 | PASS | AXIS_*_PASS，scoreboard mismatched=0/unexpected=0 |
| stress | 是 | PASS | accepted=20000 与 driver 计数守恒、aborts=0 |
| reset | 是 | PASS | epoch 递增、观测到 ABORTED_BY_RESET、复位后可继续传输 |
| perf | 是 | PASS | position 不计入吞吐；STREAMING+history_limit 有界 |
| cancel | 是 | PASS | 在途拍不被撤销；watchdog 报告后 drain 正常 |
| sched | 是 | PASS | 文件回放两次拍数一致；三种调度与 BUFFER_MODEL 无死锁 |
| cdc | 是 | PASS | 异步 FIFO 双时钟双复位下目标侧握手正常 |
| inject | 是 | PASS | 6 条规则逐项注入命中；无未解释额外告警 |
| checker_only | 是 | PASS | AXIS_CHECKER_ONLY_PASS，不 import uvm_pkg |
| structural | 是 | PASS | S1–S5 结构化证据（REQ-CHK-004） |
| seed_matrix | 是 | PASS | 3 tier × 20 seed = 60/60 |

## 问题与限制

压力规模 20000 accepted beat（未运行 1000000 beat 目标）；仅单仿真器已验证。

## 证据索引

build/run-004/logs/

## METADATA

## METADATA

<!-- VIP_METADATA_BEGIN -->
```yaml
schema_version: vip.acceptance/v1
report_kind: regression
run_id: run-004
generated_at: '2026-09-15T12:28:13.263207Z'
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
- FULL_UVM active 双侧 + PASSIVE；UVM 1.2 + VCS W-2024.09-SP1
- 18 个必需 case（compile/unit/15 tier/checker_only/structural/seed_matrix）
blocking_issues: []
known_limitations:
- 压力规模 20000 accepted beat，未执行 1000000 beat 目标
- 仅 VCS 单仿真器已验证
checks:
- id: compile
  in_scope: true
  status: PASS
  evidence_ids:
  - compile
- id: unit
  in_scope: true
  status: PASS
  evidence_ids:
  - unit_test
- id: smoke
  in_scope: true
  status: PASS
  evidence_ids:
  - axi4_stream_smoke_test
- id: feature
  in_scope: true
  status: PASS
  evidence_ids:
  - axi4_stream_feature_test
- id: corner
  in_scope: true
  status: PASS
  evidence_ids:
  - axi4_stream_corner_test
- id: random
  in_scope: true
  status: PASS
  evidence_ids:
  - axi4_stream_random_test
- id: stress
  in_scope: true
  status: PASS
  evidence_ids:
  - axi4_stream_stress_test
- id: config
  in_scope: true
  status: PASS
  evidence_ids:
  - axi4_stream_config_test
- id: passive
  in_scope: true
  status: PASS
  evidence_ids:
  - axi4_stream_passive_test
- id: reset
  in_scope: true
  status: PASS
  evidence_ids:
  - axi4_stream_reset_test
- id: perf
  in_scope: true
  status: PASS
  evidence_ids:
  - axi4_stream_perf_test
- id: cancel
  in_scope: true
  status: PASS
  evidence_ids:
  - axi4_stream_cancel_test
- id: sched
  in_scope: true
  status: PASS
  evidence_ids:
  - axi4_stream_sched_test
- id: cdc
  in_scope: true
  status: PASS
  evidence_ids:
  - axi4_stream_cdc_test
- id: inject
  in_scope: true
  status: PASS
  evidence_ids:
  - axi4_stream_inject_test
- id: checker_only
  in_scope: true
  status: PASS
  evidence_ids:
  - checker_only
- id: structural
  in_scope: true
  status: PASS
  evidence_ids:
  - structural_check
- id: seed_matrix
  in_scope: true
  status: PASS
  evidence_ids:
  - seed_matrix
evidence_ids:
- compile
- unit_test
- axi4_stream_smoke_test
- axi4_stream_feature_test
- axi4_stream_corner_test
- axi4_stream_random_test
- axi4_stream_stress_test
- axi4_stream_config_test
- axi4_stream_passive_test
- axi4_stream_reset_test
- axi4_stream_perf_test
- axi4_stream_cancel_test
- axi4_stream_sched_test
- axi4_stream_cdc_test
- axi4_stream_inject_test
- checker_only
- structural_check
- seed_matrix
evidence:
- id: compile
  path: logs/compile.log
  sha256: ca17f95763c2526f2e46b8d610462056128f9423c26e2979a817176b4d49734a
  kind: log
- id: unit_test
  path: logs/unit_test.log
  sha256: a24ba38b48ddca9acfe47a05520ed3f0873ee11c0362ca2ac51c01fd2cdc4fad
  kind: log
- id: axi4_stream_smoke_test
  path: logs/axi4_stream_smoke_test.log
  sha256: 9d6e6ad61630fc5d2b7027eee1bd641eb588dd9b8697ee9eead1264fac6cd1c4
  kind: log
- id: axi4_stream_feature_test
  path: logs/axi4_stream_feature_test.log
  sha256: 834d860a9c8e386f93cfd74bde7a75422b878b7c14aae645826da151b5b5641c
  kind: log
- id: axi4_stream_corner_test
  path: logs/axi4_stream_corner_test.log
  sha256: 1e3a102b980455aae12642dc20b4dd58a19a646abf50b8c53952f9c7ddda3df4
  kind: log
- id: axi4_stream_random_test
  path: logs/axi4_stream_random_test.log
  sha256: 5deeeff44d7d74ea11ba7e60641ea4a5c5af2e78935ea9124a96f17813638064
  kind: log
- id: axi4_stream_stress_test
  path: logs/axi4_stream_stress_test.log
  sha256: 58315ec90fa70869e011bcb904190b1c572505e26a62a8257dec3ae91cb97d18
  kind: log
- id: axi4_stream_config_test
  path: logs/axi4_stream_config_test.log
  sha256: 276a20c58bdaa4d7537fec5cc5c6eb0ae5212573743053f05f2547581b14effd
  kind: log
- id: axi4_stream_passive_test
  path: logs/axi4_stream_passive_test.log
  sha256: 41a690139a192ae5d3095028badaaf2ab43bbdfb4636edadd95a072d29c74b8d
  kind: log
- id: axi4_stream_reset_test
  path: logs/axi4_stream_reset_test.log
  sha256: bcac069ec961893076530ae8f7a4d91d611594d59b182a7e30f4cf2c716b4871
  kind: log
- id: axi4_stream_perf_test
  path: logs/axi4_stream_perf_test.log
  sha256: ae4831484fa603e4f85d20fcdb3aaa2e1a8e893a865b7fcf924fc90eb7fedd61
  kind: log
- id: axi4_stream_cancel_test
  path: logs/axi4_stream_cancel_test.log
  sha256: f2458806eb095392d3ceaafa29f69deff6d835f9ce21b8c95989eaba5266f4d3
  kind: log
- id: axi4_stream_sched_test
  path: logs/axi4_stream_sched_test.log
  sha256: 9423205b166d3b5b6eaf3b5c5e7d6441939e9e896ce0e429afed50b17d4b4b6e
  kind: log
- id: axi4_stream_cdc_test
  path: logs/axi4_stream_cdc_test.log
  sha256: b8ae1555377006f48f6f1bd76dffcb273d8bcb84998f3cf96ebcd33aa0ce37cf
  kind: log
- id: axi4_stream_inject_test
  path: logs/axi4_stream_inject_test.log
  sha256: aa1bd24ad1933657a7f98229d4506312a20b009afdf12b69cc4675d9c88b4b6a
  kind: log
- id: checker_only
  path: logs/checker_only.log
  sha256: 29136bee9e905d6a13be4741dff9abd8e00df35ce50c923996d8ffbd573ed93a
  kind: log
- id: structural_check
  path: logs/structural_check.log
  sha256: 4b5a6c9fe4d1c8b7433c0e34482171c46dde41fd2323accf1f36b5c57de388ad
  kind: log
- id: seed_matrix
  path: logs/seed_matrix.log
  sha256: da93f1db65487f6787d39f0e90fc909ae74e3a28c3ecfbda0dc59a9002fbcef8
  kind: log
```
<!-- VIP_METADATA_END -->
