# 出口资格判定报告

## 结论

**可以出口（版本必测范围）**；出口范围见 `config/release-plan.yaml`（frozen）。
16 项验收承诺全部满足；未验证能力记入限制，不以已测用例反向定义范围。

## 版本承诺

| 承诺项 | 结果 | 依据 |
| --- | --- | --- |
| l1_semantic_golden | PASS | unit_test.log（226 断言 0 失败） |
| protocol_rules | PASS | corner + inject（逐规则注入命中） |
| end_to_end_compare | PASS | feature（mismatched=0/unexpected=0） |
| backpressure_matrix | PASS | config（9 种 ready 策略） |
| reset_contract | PASS | reset（epoch/abort/无虚构响应） |
| cdc_integrity | PASS | cdc（异步 FIFO 双时钟双复位） |
| error_injection | PASS | inject（6 条规则命中） |
| passive_observe | PASS | passive（只观测不驱动） |
| perf_statistics | PASS | perf（口径与内存有界） |
| cancel_watchdog | PASS | cancel（不破坏协议） |
| sched_replay | PASS | sched（回放可复现、三种调度） |
| checker_only | PASS | checker_only（不依赖 UVM） |
| structural_evidence | PASS | structural（S1–S5） |
| mutation_detection | PASS | mutation（12/12，P0 全命中） |
| seed_reproducibility | PASS | seed_matrix（60/60） |
| coverage_closure | PASS | coverage（四项 bin 100%） |

## 范围与结果

G0–G5：需求/架构/回归/覆盖/变异/追溯六类阶段报告均为有效 PASS；
G6（本地候选完整性）由 `release` 单独校验，本报告不预填。

## 问题与限制

见 METADATA 的 `known_limitations`：范围外未验证能力（Arm 章节映射、第二仿真器、
1000000 beat 规模、完整能力矩阵）不影响已验证出口范围，但不支持泛化的
"协议认证""所有仿真器"表述。

## 证据索引

build/run-004/logs/（含逐变异日志与覆盖率导出）。

## METADATA

## METADATA

<!-- VIP_METADATA_BEGIN -->
```yaml
schema_version: vip.acceptance/v1
report_kind: qualification
run_id: run-004
generated_at: '2026-09-15T12:19:51.900269Z'
producer:
  kind: ai
  agent: zoo-code
asset:
  vlnv: aixsilicon:vip:axi4_stream:1.0.0
  source_fingerprint: 3e5946084fadfa1a0fb000c92c4545b8ae6b25f084e58e6ec1cb68b8fcd01c5c
  config_fingerprint: e9a3251fa3961ccae5de8c7838f5e4e80713bb21f60783109f6ad8578a32ee20
acceptance_plan:
  path: config/release-plan.yaml
  sha256: db534a315a4c6a65c7e4d8323c9505369f1b93703b0b4cb769a9952bfb3750a7
release_scope:
  supported:
  - AMBA AXI4-Stream（IHI 0051A 基线）单向接口
  - FULL_UVM 与 PASSIVE 角色；CHECKER_ONLY 独立构建路径
  - UVM 1.2 + VCS W-2024.09-SP1（四态与 SVA）
  - 全部 15 条协议规则与 9 种背压策略
  - CDC 数据完整性与复位合同（不宣称亚稳态安全）
  experimental: []
  unsupported:
  - AXI memory-mapped（AW/W/B/AR/R）与 RAL
  - AXI5-Stream / TWAKEUP / 接口奇偶校验扩展
  - Pass-through BFM
  - 第二商业仿真器（未执行兼容矩阵）
  - CDC 亚稳态安全证明（仅验证合同与数据完整性）
  - 公共 HWIF 兼容声明（本仓无该契约，interface 为 development binding）
conclusion: PASS
export_allowed: true
validated_scope:
- AMBA AXI4-Stream（IHI 0051A 基线）单向接口，FULL_UVM 与 PASSIVE
- UVM 1.2 + VCS W-2024.09-SP1（四态与 SVA）
- 15 条协议规则、9 种背压策略、复位/取消/watchdog 合同
- CDC 数据完整性与复位合同（异步 FIFO fixture）
- CHECKER_ONLY 独立构建路径；60 次固定 seed 复现
- 四项版本必测覆盖 bin 全部命中
blocking_issues: []
known_limitations:
- G0-9：Arm 固定版本逐规则章节映射未完成，不构成协议认证
- G1-9：CHECKER_ONLY/PASSIVE 未按完整源码规则逐条评审
- 压力规模 20000 accepted beat，未执行需求中 1000000 beat 目标
- 第二商业仿真器兼容矩阵（REQ-ACC-007）未执行 —— 无第二套环境，申请执行不在本轮范围
- CDC 仅验证数据完整性与复位合同，不证明亚稳态安全
- 本仓无 AXI4-Stream 公共 HWIF 契约，interface 为 development binding
- 完整能力矩阵（全参数笛卡尔积）未定义映射；未采集项记 null
checks:
- id: l1_semantic_golden
  in_scope: true
  status: PASS
  evidence_ids:
  - unit_test
- id: protocol_rules
  in_scope: true
  status: PASS
  evidence_ids:
  - axi4_stream_corner_test
- id: end_to_end_compare
  in_scope: true
  status: PASS
  evidence_ids:
  - axi4_stream_feature_test
- id: backpressure_matrix
  in_scope: true
  status: PASS
  evidence_ids:
  - axi4_stream_config_test
- id: reset_contract
  in_scope: true
  status: PASS
  evidence_ids:
  - axi4_stream_reset_test
- id: cdc_integrity
  in_scope: true
  status: PASS
  evidence_ids:
  - axi4_stream_cdc_test
- id: error_injection
  in_scope: true
  status: PASS
  evidence_ids:
  - axi4_stream_inject_test
- id: passive_observe
  in_scope: true
  status: PASS
  evidence_ids:
  - axi4_stream_passive_test
- id: perf_statistics
  in_scope: true
  status: PASS
  evidence_ids:
  - axi4_stream_perf_test
- id: cancel_watchdog
  in_scope: true
  status: PASS
  evidence_ids:
  - axi4_stream_cancel_test
- id: sched_replay
  in_scope: true
  status: PASS
  evidence_ids:
  - axi4_stream_sched_test
- id: checker_only
  in_scope: true
  status: PASS
  evidence_ids:
  - checker_only
- id: structural_evidence
  in_scope: true
  status: PASS
  evidence_ids:
  - structural_check
- id: mutation_detection
  in_scope: true
  status: PASS
  evidence_ids:
  - mutation
- id: seed_reproducibility
  in_scope: true
  status: PASS
  evidence_ids:
  - seed_matrix
- id: coverage_closure
  in_scope: true
  status: PASS
  evidence_ids:
  - coverage_export
evidence_ids:
- unit_test
- axi4_stream_corner_test
- axi4_stream_feature_test
- axi4_stream_config_test
- axi4_stream_reset_test
- axi4_stream_cdc_test
- axi4_stream_inject_test
- axi4_stream_passive_test
- axi4_stream_perf_test
- axi4_stream_cancel_test
- axi4_stream_sched_test
- checker_only
- structural_check
- mutation
- seed_matrix
- coverage_export
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
- id: unit_test
  path: logs/unit_test.log
  sha256: a24ba38b48ddca9acfe47a05520ed3f0873ee11c0362ca2ac51c01fd2cdc4fad
  kind: log
- id: axi4_stream_corner_test
  path: logs/axi4_stream_corner_test.log
  sha256: 1e3a102b980455aae12642dc20b4dd58a19a646abf50b8c53952f9c7ddda3df4
  kind: log
- id: axi4_stream_feature_test
  path: logs/axi4_stream_feature_test.log
  sha256: 834d860a9c8e386f93cfd74bde7a75422b878b7c14aae645826da151b5b5641c
  kind: log
- id: axi4_stream_config_test
  path: logs/axi4_stream_config_test.log
  sha256: 276a20c58bdaa4d7537fec5cc5c6eb0ae5212573743053f05f2547581b14effd
  kind: log
- id: axi4_stream_reset_test
  path: logs/axi4_stream_reset_test.log
  sha256: bcac069ec961893076530ae8f7a4d91d611594d59b182a7e30f4cf2c716b4871
  kind: log
- id: axi4_stream_cdc_test
  path: logs/axi4_stream_cdc_test.log
  sha256: b8ae1555377006f48f6f1bd76dffcb273d8bcb84998f3cf96ebcd33aa0ce37cf
  kind: log
- id: axi4_stream_inject_test
  path: logs/axi4_stream_inject_test.log
  sha256: aa1bd24ad1933657a7f98229d4506312a20b009afdf12b69cc4675d9c88b4b6a
  kind: log
- id: axi4_stream_passive_test
  path: logs/axi4_stream_passive_test.log
  sha256: 41a690139a192ae5d3095028badaaf2ab43bbdfb4636edadd95a072d29c74b8d
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
- id: checker_only
  path: logs/checker_only.log
  sha256: 29136bee9e905d6a13be4741dff9abd8e00df35ce50c923996d8ffbd573ed93a
  kind: log
- id: structural_check
  path: logs/structural_check.log
  sha256: 4b5a6c9fe4d1c8b7433c0e34482171c46dde41fd2323accf1f36b5c57de388ad
  kind: log
- id: mutation
  path: logs/mutation.log
  sha256: c0ab776dab922f8444c6c0b62ac171abe4c7955dc5c513c6b5a12fa430cf6e62
  kind: log
- id: seed_matrix
  path: logs/seed_matrix.log
  sha256: da93f1db65487f6787d39f0e90fc909ae74e3a28c3ecfbda0dc59a9002fbcef8
  kind: log
- id: coverage_export
  path: logs/coverage_export.log
  sha256: e42c9bb982bf76990c727c9d79121a9fcc33b813981da8a68e62bf2172d4747b
  kind: coverage
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
