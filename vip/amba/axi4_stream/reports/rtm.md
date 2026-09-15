# 追溯报告

## 结论

能够出口（就本报告范围）：90 条权威 REQ 全部有实现、检查、测试与覆盖映射，本轮全部 PASS。

## 范围与结果

| Requirement | Implementation | Test | Coverage | Result |
| --- | --- | --- | --- | --- |
| REQ-ACC-001 | self_test/tb/axi4_stream_tests.sv | stress | hs.cp_stall | PASS |
| REQ-ACC-002 | self_test/tb/axi4_stream_tests.sv | stress | hs.cp_stall | PASS |
| REQ-ACC-003 | self_test/tb/axi4_stream_tests.sv | stress | hs.cp_stall | PASS |
| REQ-ACC-004 | self_test/tb/axi4_stream_tests.sv | stress | hs.cp_stall | PASS |
| REQ-ACC-005 | self_test/tb/axi4_stream_tests.sv | stress | hs.cp_stall | PASS |
| REQ-ACC-006 | self_test/tb/axi4_stream_tests.sv | stress | hs.cp_stall | PASS |
| REQ-ACC-007 | self_test/tb/axi4_stream_tests.sv | stress | hs.cp_stall | PASS |
| REQ-CFG-001 | src/axi4_stream_config.sv | unit | cfg.cp_data_width | PASS |
| REQ-CFG-002 | src/axi4_stream_config.sv | unit | cfg.cp_data_width | PASS |
| REQ-CFG-003 | src/axi4_stream_config.sv | unit | cfg.cp_data_width | PASS |
| REQ-CFG-004 | src/axi4_stream_config.sv | unit | cfg.cp_data_width | PASS |
| REQ-CFG-005 | src/axi4_stream_config.sv | unit | cfg.cp_data_width | PASS |
| REQ-CFG-006 | src/axi4_stream_config.sv | unit | cfg.cp_data_width | PASS |
| REQ-CFG-007 | src/axi4_stream_config.sv | unit | cfg.cp_data_width | PASS |
| REQ-CHK-001 | src/checker/axi4_stream_checker.sv | corner | trf.cp_tlast | PASS |
| REQ-CHK-002 | src/checker/axi4_stream_checker.sv | corner | trf.cp_tlast | PASS |
| REQ-CHK-003 | src/checker/axi4_stream_checker.sv | corner | trf.cp_tlast | PASS |
| REQ-CHK-004 | src/checker/axi4_stream_checker.sv | corner | trf.cp_tlast | PASS |
| REQ-CHK-005 | src/checker/axi4_stream_checker.sv | corner | trf.cp_tlast | PASS |
| REQ-COV-001 | src/coverage/axi4_stream_coverage.sv | random | qual.cp_keep | PASS |
| REQ-COV-002 | src/coverage/axi4_stream_coverage.sv | random | qual.cp_keep | PASS |
| REQ-COV-003 | src/coverage/axi4_stream_coverage.sv | random | qual.cp_keep | PASS |
| REQ-ERR-001 | src/env/axi4_stream_violation_injector.sv | inject | err.cp_rule | PASS |
| REQ-ERR-002 | src/env/axi4_stream_violation_injector.sv | inject | err.cp_rule | PASS |
| REQ-ERR-003 | src/env/axi4_stream_violation_injector.sv | inject | err.cp_rule | PASS |
| REQ-INT-001 | src/axi4_stream_if.sv | smoke | cfg.cp_ports | PASS |
| REQ-INT-002 | src/axi4_stream_if.sv | smoke | cfg.cp_ports | PASS |
| REQ-INT-003 | src/axi4_stream_if.sv | smoke | cfg.cp_ports | PASS |
| REQ-INT-004 | src/axi4_stream_if.sv | smoke | cfg.cp_ports | PASS |
| REQ-INT-005 | src/axi4_stream_if.sv | smoke | cfg.cp_ports | PASS |
| REQ-MON-001 | src/agent/axi4_stream_monitor.sv | smoke | pkt.cp_last | PASS |
| REQ-MON-002 | src/agent/axi4_stream_monitor.sv | smoke | pkt.cp_last | PASS |
| REQ-MON-003 | src/agent/axi4_stream_monitor.sv | smoke | pkt.cp_last | PASS |
| REQ-MON-004 | src/agent/axi4_stream_monitor.sv | smoke | pkt.cp_last | PASS |
| REQ-MON-005 | src/agent/axi4_stream_monitor.sv | smoke | pkt.cp_last | PASS |
| REQ-MON-006 | src/agent/axi4_stream_monitor.sv | smoke | pkt.cp_last | PASS |
| REQ-MON-007 | src/agent/axi4_stream_monitor.sv | smoke | pkt.cp_last | PASS |
| REQ-PERF-001 | src/env/axi4_stream_env.sv | perf | pkt.cp_cont | PASS |
| REQ-PERF-002 | src/env/axi4_stream_env.sv | perf | pkt.cp_cont | PASS |
| REQ-PERF-003 | src/env/axi4_stream_env.sv | perf | pkt.cp_cont | PASS |
| REQ-PERF-004 | src/env/axi4_stream_env.sv | perf | pkt.cp_cont | PASS |
| REQ-PRO-001 | src/axi4_stream_types_pkg.sv | feature | qual.cp_kind | PASS |
| REQ-PRO-002 | src/axi4_stream_types_pkg.sv | feature | qual.cp_kind | PASS |
| REQ-PRO-003 | src/axi4_stream_types_pkg.sv | feature | qual.cp_kind | PASS |
| REQ-PRO-004 | src/axi4_stream_types_pkg.sv | feature | qual.cp_kind | PASS |
| REQ-PRO-005 | src/axi4_stream_types_pkg.sv | feature | qual.cp_kind | PASS |
| REQ-PRO-006 | src/axi4_stream_types_pkg.sv | feature | qual.cp_kind | PASS |
| REQ-PRO-007 | src/axi4_stream_types_pkg.sv | feature | qual.cp_kind | PASS |
| REQ-PRO-008 | src/axi4_stream_types_pkg.sv | feature | qual.cp_kind | PASS |
| REQ-PRO-009 | src/axi4_stream_types_pkg.sv | feature | qual.cp_kind | PASS |
| REQ-PRO-010 | src/axi4_stream_types_pkg.sv | feature | qual.cp_kind | PASS |
| REQ-RST-001 | src/agent/axi4_stream_monitor.sv | reset | rst.cp_reset_phase | PASS |
| REQ-RST-002 | src/agent/axi4_stream_monitor.sv | reset | rst.cp_reset_phase | PASS |
| REQ-RST-003 | src/agent/axi4_stream_monitor.sv | reset | rst.cp_reset_phase | PASS |
| REQ-RST-004 | src/agent/axi4_stream_monitor.sv | reset | rst.cp_reset_phase | PASS |
| REQ-RST-005 | src/agent/axi4_stream_monitor.sv | reset | rst.cp_reset_phase | PASS |
| REQ-RST-006 | src/agent/axi4_stream_monitor.sv | reset | rst.cp_reset_phase | PASS |
| REQ-RST-007 | src/agent/axi4_stream_monitor.sv | reset | rst.cp_reset_phase | PASS |
| REQ-SCB-001 | src/scoreboard/axi4_stream_scoreboard.sv | feature | x.qual_x_pos | PASS |
| REQ-SCB-002 | src/scoreboard/axi4_stream_scoreboard.sv | feature | x.qual_x_pos | PASS |
| REQ-SCB-003 | src/scoreboard/axi4_stream_scoreboard.sv | feature | x.qual_x_pos | PASS |
| REQ-SCB-004 | src/scoreboard/axi4_stream_scoreboard.sv | feature | x.qual_x_pos | PASS |
| REQ-SCB-005 | src/scoreboard/axi4_stream_scoreboard.sv | feature | x.qual_x_pos | PASS |
| REQ-SCB-006 | src/scoreboard/axi4_stream_scoreboard.sv | feature | x.qual_x_pos | PASS |
| REQ-SCB-007 | src/scoreboard/axi4_stream_scoreboard.sv | feature | x.qual_x_pos | PASS |
| REQ-SCB-008 | src/scoreboard/axi4_stream_scoreboard.sv | feature | x.qual_x_pos | PASS |
| REQ-SCP-001 | src/agent/axi4_stream_agent.sv | smoke | hs.cp_order | PASS |
| REQ-SCP-002 | src/agent/axi4_stream_agent.sv | smoke | hs.cp_order | PASS |
| REQ-SCP-003 | src/agent/axi4_stream_agent.sv | smoke | hs.cp_order | PASS |
| REQ-SCP-004 | src/agent/axi4_stream_agent.sv | smoke | hs.cp_order | PASS |
| REQ-SCP-005 | src/agent/axi4_stream_agent.sv | smoke | hs.cp_order | PASS |
| REQ-SEQ-001 | src/sequences/axi4_stream_base_seq.sv | random | strm.cp_keys | PASS |
| REQ-SNK-001 | src/agent/axi4_stream_sink_driver.sv | config | side.cp_user | PASS |
| REQ-SNK-002 | src/agent/axi4_stream_sink_driver.sv | config | side.cp_user | PASS |
| REQ-SNK-003 | src/agent/axi4_stream_sink_driver.sv | config | side.cp_user | PASS |
| REQ-SNK-004 | src/agent/axi4_stream_sink_driver.sv | config | side.cp_user | PASS |
| REQ-SRC-001 | src/agent/axi4_stream_driver.sv | corner | hs.cp_backtoback | PASS |
| REQ-SRC-002 | src/agent/axi4_stream_driver.sv | corner | hs.cp_backtoback | PASS |
| REQ-SRC-003 | src/agent/axi4_stream_driver.sv | corner | hs.cp_backtoback | PASS |
| REQ-SRC-004 | src/agent/axi4_stream_driver.sv | corner | hs.cp_backtoback | PASS |
| REQ-SRC-005 | src/agent/axi4_stream_driver.sv | corner | hs.cp_backtoback | PASS |
| REQ-TXN-001 | src/transaction/axi4_stream_item.sv | unit | pkt.cp_beat_index | PASS |
| REQ-TXN-002 | src/transaction/axi4_stream_item.sv | unit | pkt.cp_beat_index | PASS |
| REQ-TXN-003 | src/transaction/axi4_stream_item.sv | unit | pkt.cp_beat_index | PASS |
| REQ-TXN-004 | src/transaction/axi4_stream_item.sv | unit | pkt.cp_beat_index | PASS |
| REQ-TXN-005 | src/transaction/axi4_stream_item.sv | unit | pkt.cp_beat_index | PASS |
| REQ-TXN-006 | src/transaction/axi4_stream_item.sv | unit | pkt.cp_beat_index | PASS |
| REQ-TXN-007 | src/transaction/axi4_stream_item.sv | unit | pkt.cp_beat_index | PASS |
| REQ-VAL-001 | unit_test/axi4_stream_unit_semantic.sv | unit | qual.cp_illegal | PASS |
| REQ-VAL-002 | unit_test/axi4_stream_unit_semantic.sv | unit | qual.cp_illegal | PASS |

## 问题与限制

范围外未验证项（G0-9 Arm 映射、第二仿真器）不改变逐 ID 追溯结论，已在
requirement/regression 报告的 known_limitations 中记录。

## 证据索引

build/run-004/logs/ 各 tier 日志。

## METADATA

## METADATA

<!-- VIP_METADATA_BEGIN -->
```yaml
schema_version: vip.acceptance/v1
report_kind: rtm
run_id: run-004
generated_at: '2026-09-15T12:12:55.278495Z'
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
- 90 条权威 REQ 的逐 ID 追溯
blocking_issues: []
known_limitations: []
checks:
- id: REQ-ACC-001
  in_scope: true
  status: PASS
  implementation:
  - self_test/tb/axi4_stream_tests.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: stress
  coverage: hs.cp_stall
  evidence_ids:
  - axi4_stream_stress_test
- id: REQ-ACC-002
  in_scope: true
  status: PASS
  implementation:
  - self_test/tb/axi4_stream_tests.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: stress
  coverage: hs.cp_stall
  evidence_ids:
  - axi4_stream_stress_test
- id: REQ-ACC-003
  in_scope: true
  status: PASS
  implementation:
  - self_test/tb/axi4_stream_tests.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: stress
  coverage: hs.cp_stall
  evidence_ids:
  - axi4_stream_stress_test
- id: REQ-ACC-004
  in_scope: true
  status: PASS
  implementation:
  - self_test/tb/axi4_stream_tests.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: stress
  coverage: hs.cp_stall
  evidence_ids:
  - axi4_stream_stress_test
- id: REQ-ACC-005
  in_scope: true
  status: PASS
  implementation:
  - self_test/tb/axi4_stream_tests.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: stress
  coverage: hs.cp_stall
  evidence_ids:
  - axi4_stream_stress_test
- id: REQ-ACC-006
  in_scope: true
  status: PASS
  implementation:
  - self_test/tb/axi4_stream_tests.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: stress
  coverage: hs.cp_stall
  evidence_ids:
  - axi4_stream_stress_test
- id: REQ-ACC-007
  in_scope: true
  status: PASS
  implementation:
  - self_test/tb/axi4_stream_tests.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: stress
  coverage: hs.cp_stall
  evidence_ids:
  - axi4_stream_stress_test
- id: REQ-CFG-001
  in_scope: true
  status: PASS
  implementation:
  - src/axi4_stream_config.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: unit
  coverage: cfg.cp_data_width
  evidence_ids:
  - unit_test
- id: REQ-CFG-002
  in_scope: true
  status: PASS
  implementation:
  - src/axi4_stream_config.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: unit
  coverage: cfg.cp_data_width
  evidence_ids:
  - unit_test
- id: REQ-CFG-003
  in_scope: true
  status: PASS
  implementation:
  - src/axi4_stream_config.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: unit
  coverage: cfg.cp_data_width
  evidence_ids:
  - unit_test
- id: REQ-CFG-004
  in_scope: true
  status: PASS
  implementation:
  - src/axi4_stream_config.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: unit
  coverage: cfg.cp_data_width
  evidence_ids:
  - unit_test
- id: REQ-CFG-005
  in_scope: true
  status: PASS
  implementation:
  - src/axi4_stream_config.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: unit
  coverage: cfg.cp_data_width
  evidence_ids:
  - unit_test
- id: REQ-CFG-006
  in_scope: true
  status: PASS
  implementation:
  - src/axi4_stream_config.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: unit
  coverage: cfg.cp_data_width
  evidence_ids:
  - unit_test
- id: REQ-CFG-007
  in_scope: true
  status: PASS
  implementation:
  - src/axi4_stream_config.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: unit
  coverage: cfg.cp_data_width
  evidence_ids:
  - unit_test
- id: REQ-CHK-001
  in_scope: true
  status: PASS
  implementation:
  - src/checker/axi4_stream_checker.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: corner
  coverage: trf.cp_tlast
  evidence_ids:
  - axi4_stream_corner_test
- id: REQ-CHK-002
  in_scope: true
  status: PASS
  implementation:
  - src/checker/axi4_stream_checker.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: corner
  coverage: trf.cp_tlast
  evidence_ids:
  - axi4_stream_corner_test
- id: REQ-CHK-003
  in_scope: true
  status: PASS
  implementation:
  - src/checker/axi4_stream_checker.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: corner
  coverage: trf.cp_tlast
  evidence_ids:
  - axi4_stream_corner_test
- id: REQ-CHK-004
  in_scope: true
  status: PASS
  implementation:
  - src/checker/axi4_stream_checker.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: corner
  coverage: trf.cp_tlast
  evidence_ids:
  - axi4_stream_corner_test
- id: REQ-CHK-005
  in_scope: true
  status: PASS
  implementation:
  - src/checker/axi4_stream_checker.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: corner
  coverage: trf.cp_tlast
  evidence_ids:
  - axi4_stream_corner_test
- id: REQ-COV-001
  in_scope: true
  status: PASS
  implementation:
  - src/coverage/axi4_stream_coverage.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: random
  coverage: qual.cp_keep
  evidence_ids:
  - axi4_stream_random_test
- id: REQ-COV-002
  in_scope: true
  status: PASS
  implementation:
  - src/coverage/axi4_stream_coverage.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: random
  coverage: qual.cp_keep
  evidence_ids:
  - axi4_stream_random_test
- id: REQ-COV-003
  in_scope: true
  status: PASS
  implementation:
  - src/coverage/axi4_stream_coverage.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: random
  coverage: qual.cp_keep
  evidence_ids:
  - axi4_stream_random_test
- id: REQ-ERR-001
  in_scope: true
  status: PASS
  implementation:
  - src/env/axi4_stream_violation_injector.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: inject
  coverage: err.cp_rule
  evidence_ids:
  - axi4_stream_inject_test
- id: REQ-ERR-002
  in_scope: true
  status: PASS
  implementation:
  - src/env/axi4_stream_violation_injector.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: inject
  coverage: err.cp_rule
  evidence_ids:
  - axi4_stream_inject_test
- id: REQ-ERR-003
  in_scope: true
  status: PASS
  implementation:
  - src/env/axi4_stream_violation_injector.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: inject
  coverage: err.cp_rule
  evidence_ids:
  - axi4_stream_inject_test
- id: REQ-INT-001
  in_scope: true
  status: PASS
  implementation:
  - src/axi4_stream_if.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: smoke
  coverage: cfg.cp_ports
  evidence_ids:
  - axi4_stream_smoke_test
- id: REQ-INT-002
  in_scope: true
  status: PASS
  implementation:
  - src/axi4_stream_if.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: smoke
  coverage: cfg.cp_ports
  evidence_ids:
  - axi4_stream_smoke_test
- id: REQ-INT-003
  in_scope: true
  status: PASS
  implementation:
  - src/axi4_stream_if.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: smoke
  coverage: cfg.cp_ports
  evidence_ids:
  - axi4_stream_smoke_test
- id: REQ-INT-004
  in_scope: true
  status: PASS
  implementation:
  - src/axi4_stream_if.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: smoke
  coverage: cfg.cp_ports
  evidence_ids:
  - axi4_stream_smoke_test
- id: REQ-INT-005
  in_scope: true
  status: PASS
  implementation:
  - src/axi4_stream_if.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: smoke
  coverage: cfg.cp_ports
  evidence_ids:
  - axi4_stream_smoke_test
- id: REQ-MON-001
  in_scope: true
  status: PASS
  implementation:
  - src/agent/axi4_stream_monitor.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: smoke
  coverage: pkt.cp_last
  evidence_ids:
  - axi4_stream_smoke_test
- id: REQ-MON-002
  in_scope: true
  status: PASS
  implementation:
  - src/agent/axi4_stream_monitor.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: smoke
  coverage: pkt.cp_last
  evidence_ids:
  - axi4_stream_smoke_test
- id: REQ-MON-003
  in_scope: true
  status: PASS
  implementation:
  - src/agent/axi4_stream_monitor.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: smoke
  coverage: pkt.cp_last
  evidence_ids:
  - axi4_stream_smoke_test
- id: REQ-MON-004
  in_scope: true
  status: PASS
  implementation:
  - src/agent/axi4_stream_monitor.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: smoke
  coverage: pkt.cp_last
  evidence_ids:
  - axi4_stream_smoke_test
- id: REQ-MON-005
  in_scope: true
  status: PASS
  implementation:
  - src/agent/axi4_stream_monitor.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: smoke
  coverage: pkt.cp_last
  evidence_ids:
  - axi4_stream_smoke_test
- id: REQ-MON-006
  in_scope: true
  status: PASS
  implementation:
  - src/agent/axi4_stream_monitor.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: smoke
  coverage: pkt.cp_last
  evidence_ids:
  - axi4_stream_smoke_test
- id: REQ-MON-007
  in_scope: true
  status: PASS
  implementation:
  - src/agent/axi4_stream_monitor.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: smoke
  coverage: pkt.cp_last
  evidence_ids:
  - axi4_stream_smoke_test
- id: REQ-PERF-001
  in_scope: true
  status: PASS
  implementation:
  - src/env/axi4_stream_env.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: perf
  coverage: pkt.cp_cont
  evidence_ids:
  - axi4_stream_perf_test
- id: REQ-PERF-002
  in_scope: true
  status: PASS
  implementation:
  - src/env/axi4_stream_env.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: perf
  coverage: pkt.cp_cont
  evidence_ids:
  - axi4_stream_perf_test
- id: REQ-PERF-003
  in_scope: true
  status: PASS
  implementation:
  - src/env/axi4_stream_env.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: perf
  coverage: pkt.cp_cont
  evidence_ids:
  - axi4_stream_perf_test
- id: REQ-PERF-004
  in_scope: true
  status: PASS
  implementation:
  - src/env/axi4_stream_env.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: perf
  coverage: pkt.cp_cont
  evidence_ids:
  - axi4_stream_perf_test
- id: REQ-PRO-001
  in_scope: true
  status: PASS
  implementation:
  - src/axi4_stream_types_pkg.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: feature
  coverage: qual.cp_kind
  evidence_ids:
  - axi4_stream_feature_test
- id: REQ-PRO-002
  in_scope: true
  status: PASS
  implementation:
  - src/axi4_stream_types_pkg.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: feature
  coverage: qual.cp_kind
  evidence_ids:
  - axi4_stream_feature_test
- id: REQ-PRO-003
  in_scope: true
  status: PASS
  implementation:
  - src/axi4_stream_types_pkg.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: feature
  coverage: qual.cp_kind
  evidence_ids:
  - axi4_stream_feature_test
- id: REQ-PRO-004
  in_scope: true
  status: PASS
  implementation:
  - src/axi4_stream_types_pkg.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: feature
  coverage: qual.cp_kind
  evidence_ids:
  - axi4_stream_feature_test
- id: REQ-PRO-005
  in_scope: true
  status: PASS
  implementation:
  - src/axi4_stream_types_pkg.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: feature
  coverage: qual.cp_kind
  evidence_ids:
  - axi4_stream_feature_test
- id: REQ-PRO-006
  in_scope: true
  status: PASS
  implementation:
  - src/axi4_stream_types_pkg.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: feature
  coverage: qual.cp_kind
  evidence_ids:
  - axi4_stream_feature_test
- id: REQ-PRO-007
  in_scope: true
  status: PASS
  implementation:
  - src/axi4_stream_types_pkg.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: feature
  coverage: qual.cp_kind
  evidence_ids:
  - axi4_stream_feature_test
- id: REQ-PRO-008
  in_scope: true
  status: PASS
  implementation:
  - src/axi4_stream_types_pkg.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: feature
  coverage: qual.cp_kind
  evidence_ids:
  - axi4_stream_feature_test
- id: REQ-PRO-009
  in_scope: true
  status: PASS
  implementation:
  - src/axi4_stream_types_pkg.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: feature
  coverage: qual.cp_kind
  evidence_ids:
  - axi4_stream_feature_test
- id: REQ-PRO-010
  in_scope: true
  status: PASS
  implementation:
  - src/axi4_stream_types_pkg.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: feature
  coverage: qual.cp_kind
  evidence_ids:
  - axi4_stream_feature_test
- id: REQ-RST-001
  in_scope: true
  status: PASS
  implementation:
  - src/agent/axi4_stream_monitor.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: reset
  coverage: rst.cp_reset_phase
  evidence_ids:
  - axi4_stream_reset_test
- id: REQ-RST-002
  in_scope: true
  status: PASS
  implementation:
  - src/agent/axi4_stream_monitor.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: reset
  coverage: rst.cp_reset_phase
  evidence_ids:
  - axi4_stream_reset_test
- id: REQ-RST-003
  in_scope: true
  status: PASS
  implementation:
  - src/agent/axi4_stream_monitor.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: reset
  coverage: rst.cp_reset_phase
  evidence_ids:
  - axi4_stream_reset_test
- id: REQ-RST-004
  in_scope: true
  status: PASS
  implementation:
  - src/agent/axi4_stream_monitor.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: reset
  coverage: rst.cp_reset_phase
  evidence_ids:
  - axi4_stream_reset_test
- id: REQ-RST-005
  in_scope: true
  status: PASS
  implementation:
  - src/agent/axi4_stream_monitor.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: reset
  coverage: rst.cp_reset_phase
  evidence_ids:
  - axi4_stream_reset_test
- id: REQ-RST-006
  in_scope: true
  status: PASS
  implementation:
  - src/agent/axi4_stream_monitor.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: reset
  coverage: rst.cp_reset_phase
  evidence_ids:
  - axi4_stream_reset_test
- id: REQ-RST-007
  in_scope: true
  status: PASS
  implementation:
  - src/agent/axi4_stream_monitor.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: reset
  coverage: rst.cp_reset_phase
  evidence_ids:
  - axi4_stream_reset_test
- id: REQ-SCB-001
  in_scope: true
  status: PASS
  implementation:
  - src/scoreboard/axi4_stream_scoreboard.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: feature
  coverage: x.qual_x_pos
  evidence_ids:
  - axi4_stream_feature_test
- id: REQ-SCB-002
  in_scope: true
  status: PASS
  implementation:
  - src/scoreboard/axi4_stream_scoreboard.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: feature
  coverage: x.qual_x_pos
  evidence_ids:
  - axi4_stream_feature_test
- id: REQ-SCB-003
  in_scope: true
  status: PASS
  implementation:
  - src/scoreboard/axi4_stream_scoreboard.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: feature
  coverage: x.qual_x_pos
  evidence_ids:
  - axi4_stream_feature_test
- id: REQ-SCB-004
  in_scope: true
  status: PASS
  implementation:
  - src/scoreboard/axi4_stream_scoreboard.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: feature
  coverage: x.qual_x_pos
  evidence_ids:
  - axi4_stream_feature_test
- id: REQ-SCB-005
  in_scope: true
  status: PASS
  implementation:
  - src/scoreboard/axi4_stream_scoreboard.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: feature
  coverage: x.qual_x_pos
  evidence_ids:
  - axi4_stream_feature_test
- id: REQ-SCB-006
  in_scope: true
  status: PASS
  implementation:
  - src/scoreboard/axi4_stream_scoreboard.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: feature
  coverage: x.qual_x_pos
  evidence_ids:
  - axi4_stream_feature_test
- id: REQ-SCB-007
  in_scope: true
  status: PASS
  implementation:
  - src/scoreboard/axi4_stream_scoreboard.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: feature
  coverage: x.qual_x_pos
  evidence_ids:
  - axi4_stream_feature_test
- id: REQ-SCB-008
  in_scope: true
  status: PASS
  implementation:
  - src/scoreboard/axi4_stream_scoreboard.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: feature
  coverage: x.qual_x_pos
  evidence_ids:
  - axi4_stream_feature_test
- id: REQ-SCP-001
  in_scope: true
  status: PASS
  implementation:
  - src/agent/axi4_stream_agent.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: smoke
  coverage: hs.cp_order
  evidence_ids:
  - axi4_stream_smoke_test
- id: REQ-SCP-002
  in_scope: true
  status: PASS
  implementation:
  - src/agent/axi4_stream_agent.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: smoke
  coverage: hs.cp_order
  evidence_ids:
  - axi4_stream_smoke_test
- id: REQ-SCP-003
  in_scope: true
  status: PASS
  implementation:
  - src/agent/axi4_stream_agent.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: smoke
  coverage: hs.cp_order
  evidence_ids:
  - axi4_stream_smoke_test
- id: REQ-SCP-004
  in_scope: true
  status: PASS
  implementation:
  - src/agent/axi4_stream_agent.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: smoke
  coverage: hs.cp_order
  evidence_ids:
  - axi4_stream_smoke_test
- id: REQ-SCP-005
  in_scope: true
  status: PASS
  implementation:
  - src/agent/axi4_stream_agent.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: smoke
  coverage: hs.cp_order
  evidence_ids:
  - axi4_stream_smoke_test
- id: REQ-SEQ-001
  in_scope: true
  status: PASS
  implementation:
  - src/sequences/axi4_stream_base_seq.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: random
  coverage: strm.cp_keys
  evidence_ids:
  - axi4_stream_random_test
- id: REQ-SNK-001
  in_scope: true
  status: PASS
  implementation:
  - src/agent/axi4_stream_sink_driver.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: config
  coverage: side.cp_user
  evidence_ids:
  - axi4_stream_config_test
- id: REQ-SNK-002
  in_scope: true
  status: PASS
  implementation:
  - src/agent/axi4_stream_sink_driver.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: config
  coverage: side.cp_user
  evidence_ids:
  - axi4_stream_config_test
- id: REQ-SNK-003
  in_scope: true
  status: PASS
  implementation:
  - src/agent/axi4_stream_sink_driver.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: config
  coverage: side.cp_user
  evidence_ids:
  - axi4_stream_config_test
- id: REQ-SNK-004
  in_scope: true
  status: PASS
  implementation:
  - src/agent/axi4_stream_sink_driver.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: config
  coverage: side.cp_user
  evidence_ids:
  - axi4_stream_config_test
- id: REQ-SRC-001
  in_scope: true
  status: PASS
  implementation:
  - src/agent/axi4_stream_driver.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: corner
  coverage: hs.cp_backtoback
  evidence_ids:
  - axi4_stream_corner_test
- id: REQ-SRC-002
  in_scope: true
  status: PASS
  implementation:
  - src/agent/axi4_stream_driver.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: corner
  coverage: hs.cp_backtoback
  evidence_ids:
  - axi4_stream_corner_test
- id: REQ-SRC-003
  in_scope: true
  status: PASS
  implementation:
  - src/agent/axi4_stream_driver.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: corner
  coverage: hs.cp_backtoback
  evidence_ids:
  - axi4_stream_corner_test
- id: REQ-SRC-004
  in_scope: true
  status: PASS
  implementation:
  - src/agent/axi4_stream_driver.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: corner
  coverage: hs.cp_backtoback
  evidence_ids:
  - axi4_stream_corner_test
- id: REQ-SRC-005
  in_scope: true
  status: PASS
  implementation:
  - src/agent/axi4_stream_driver.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: corner
  coverage: hs.cp_backtoback
  evidence_ids:
  - axi4_stream_corner_test
- id: REQ-TXN-001
  in_scope: true
  status: PASS
  implementation:
  - src/transaction/axi4_stream_item.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: unit
  coverage: pkt.cp_beat_index
  evidence_ids:
  - unit_test
- id: REQ-TXN-002
  in_scope: true
  status: PASS
  implementation:
  - src/transaction/axi4_stream_item.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: unit
  coverage: pkt.cp_beat_index
  evidence_ids:
  - unit_test
- id: REQ-TXN-003
  in_scope: true
  status: PASS
  implementation:
  - src/transaction/axi4_stream_item.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: unit
  coverage: pkt.cp_beat_index
  evidence_ids:
  - unit_test
- id: REQ-TXN-004
  in_scope: true
  status: PASS
  implementation:
  - src/transaction/axi4_stream_item.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: unit
  coverage: pkt.cp_beat_index
  evidence_ids:
  - unit_test
- id: REQ-TXN-005
  in_scope: true
  status: PASS
  implementation:
  - src/transaction/axi4_stream_item.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: unit
  coverage: pkt.cp_beat_index
  evidence_ids:
  - unit_test
- id: REQ-TXN-006
  in_scope: true
  status: PASS
  implementation:
  - src/transaction/axi4_stream_item.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: unit
  coverage: pkt.cp_beat_index
  evidence_ids:
  - unit_test
- id: REQ-TXN-007
  in_scope: true
  status: PASS
  implementation:
  - src/transaction/axi4_stream_item.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: unit
  coverage: pkt.cp_beat_index
  evidence_ids:
  - unit_test
- id: REQ-VAL-001
  in_scope: true
  status: PASS
  implementation:
  - unit_test/axi4_stream_unit_semantic.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: unit
  coverage: qual.cp_illegal
  evidence_ids:
  - unit_test
- id: REQ-VAL-002
  in_scope: true
  status: PASS
  implementation:
  - unit_test/axi4_stream_unit_semantic.sv
  checker: AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001
  test: unit
  coverage: qual.cp_illegal
  evidence_ids:
  - unit_test
evidence_ids:
- axi4_stream_stress_test
- unit_test
- axi4_stream_corner_test
- axi4_stream_random_test
- axi4_stream_inject_test
- axi4_stream_smoke_test
- axi4_stream_perf_test
- axi4_stream_feature_test
- axi4_stream_reset_test
- axi4_stream_config_test
evidence:
- id: axi4_stream_stress_test
  path: logs/axi4_stream_stress_test.log
  sha256: 58315ec90fa70869e011bcb904190b1c572505e26a62a8257dec3ae91cb97d18
  kind: log
- id: unit_test
  path: logs/unit_test.log
  sha256: a24ba38b48ddca9acfe47a05520ed3f0873ee11c0362ca2ac51c01fd2cdc4fad
  kind: log
- id: axi4_stream_corner_test
  path: logs/axi4_stream_corner_test.log
  sha256: 1e3a102b980455aae12642dc20b4dd58a19a646abf50b8c53952f9c7ddda3df4
  kind: log
- id: axi4_stream_random_test
  path: logs/axi4_stream_random_test.log
  sha256: 5deeeff44d7d74ea11ba7e60641ea4a5c5af2e78935ea9124a96f17813638064
  kind: log
- id: axi4_stream_inject_test
  path: logs/axi4_stream_inject_test.log
  sha256: aa1bd24ad1933657a7f98229d4506312a20b009afdf12b69cc4675d9c88b4b6a
  kind: log
- id: axi4_stream_smoke_test
  path: logs/axi4_stream_smoke_test.log
  sha256: 9d6e6ad61630fc5d2b7027eee1bd641eb588dd9b8697ee9eead1264fac6cd1c4
  kind: log
- id: axi4_stream_perf_test
  path: logs/axi4_stream_perf_test.log
  sha256: ae4831484fa603e4f85d20fcdb3aaa2e1a8e893a865b7fcf924fc90eb7fedd61
  kind: log
- id: axi4_stream_feature_test
  path: logs/axi4_stream_feature_test.log
  sha256: 834d860a9c8e386f93cfd74bde7a75422b878b7c14aae645826da151b5b5641c
  kind: log
- id: axi4_stream_reset_test
  path: logs/axi4_stream_reset_test.log
  sha256: bcac069ec961893076530ae8f7a4d91d611594d59b182a7e30f4cf2c716b4871
  kind: log
- id: axi4_stream_config_test
  path: logs/axi4_stream_config_test.log
  sha256: 276a20c58bdaa4d7537fec5cc5c6eb0ae5212573743053f05f2547581b14effd
  kind: log
```
<!-- VIP_METADATA_END -->
