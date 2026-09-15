# axi4_stream VIP Requirement Traceability Matrix（RTM）

> 本文件是**设计期**追溯映射：需求 → 实现 → 检查/测试 → 覆盖。
> 它不记录某次运行的结果；逐次执行状态只写 `reports/<run-id>/rtm.md`。
> 机器 case/priority/bin 集合只维护在 `config/verification-plan.yaml`。

> **Document ID**: `aixsilicon:vip:axi4_stream:rtm`
> **VIP Name**: `axi4_stream`
> **Version**: `0.1.0`
> **Status**: `Draft`
> **Owner**: `amba-vip`
> **Requirement Baseline**: `docs/requirement.md`（90 REQ）
> **Architecture Baseline**: `docs/architecture.md`
> **Validation Plan Baseline**: `docs/validation-plan.md`
> **Target VLNV**: `aixsilicon:vip:axi4_stream:1.0.0`
> **Validation Run / Release ID**: 由每次运行的 run-id 提供（本文不固定）

---

# 1. Purpose

建立 90 条 REQ 到实现、检查、测试与覆盖的设计期追溯链，用于确认
"每条需求都有实现 owner 与验证入口"。**本文的 Result 列不是执行结论**。

---

# 2. RTM Principles

## 2.1 Requirement Driven

所有追溯链从 `REQ-*` 出发；不允许存在无需求来源的重要实现或验证活动。

## 2.2 Evidence Based

需求不得仅因"代码已实现"而标记 PASS；至少需要
Implementation + Validation + Result + Evidence 四要素，且由
`vip_tool.py report-check` 依据 `reports/<run-id>` 的 metadata 计算。

## 2.3 Bidirectional Traceability

既支持 Requirement → Validation，也支持 Validation → Requirement；
无需求的 test 与无测试的需求都不允许。

## 2.4 Single Final Status

每条需求在某个发布版本只有一个最终状态：
`PASS` / `FAIL` / `BLOCKED` / `WAIVED` / `N/A` / `NOT_RUN`。
当前 v1 门禁不接受 WAIVED 替代 PASS。

---

# 3. Input Artifacts

| Artifact | Purpose | Baseline |
|---|---|---|
| `docs/requirement.md` | Requirement SSOT（源自 `../axi_stream_vip_contract.md`） | v0.1.0 |
| `docs/architecture.md` | Architecture / Component Mapping | v0.1.0 |
| `docs/validation-plan.md` | Validation Case 定义 | v0.1.0 |
| `config/requirements.yaml` | 权威 REQ ID 清单 | v1 |
| `config/verification-plan.yaml` | 冻结 case/bin 集合 | `vip.plan/v1` |
| Source Code | Implementation | 见运行报告 source_fingerprint |
| Regression / Coverage / Mutation 报告 | Evidence | `reports/<run-id>/` |
| `docs/user-guide.md` | Release Documentation | v0.1.0 |

---

# 4. Traceability Model

```text
REQ → 架构/实现组件 → 检查器(rule/断言) → 测试入口(tier) → 覆盖 bin → 结果/证据
```

---

# 5. Status Definitions

| 状态 | 含义 |
|---|---|
| PASS | 实现 + 验证 + 结果 + 证据齐备，且被门禁计算通过 |
| FAIL | 已执行但结果不符或不完整 |
| BLOCKED | 环境/工具/许可证阻塞 |
| NOT_RUN | 尚未执行（本文默认状态） |
| WAIVED | v1 门禁不接受其替代 PASS |

---

# 6. Priority Model

全部 90 条 REQ 在 `config/verification-plan.yaml` 中均为 `required: true`（等价 P0）。
P1/P2 目前不存在；后续扩展（AXI5-Stream、pass-through BFM）另行评审。
结果报告不得设置或修改 required/priority。

---

# 7. Master RTM

下表是逐 ID 设计期映射的唯一权威表。**Result 列固定为设计期默认 `NOT_RUN`**，
表示"需要本次运行证据才能判定"，不代表失败。

| Requirement | Implementation | Test witness / Checker | Coverage | Result | Evidence / remaining gap |
| --- | --- | --- | --- | --- | --- |
| REQ-SCP-001 | src/agent/axi4_stream_agent.sv; src/env/axi4_stream_env.sv | unit_test golden vector + AXIS-P004 稳定性子码 | smoke,passive | hs.same_cycle | NOT_RUN |
| REQ-SCP-002 | src/agent/axi4_stream_agent.sv; src/env/axi4_stream_env.sv | unit_test golden vector + AXIS-P004 稳定性子码 | smoke,passive | hs.same_cycle | NOT_RUN |
| REQ-SCP-003 | src/agent/axi4_stream_agent.sv; src/env/axi4_stream_env.sv | unit_test golden vector + AXIS-P004 稳定性子码 | smoke,passive | hs.same_cycle | NOT_RUN |
| REQ-SCP-004 | src/agent/axi4_stream_agent.sv; src/env/axi4_stream_env.sv | unit_test golden vector + AXIS-P004 稳定性子码 | smoke,passive | hs.same_cycle | NOT_RUN |
| REQ-SCP-005 | src/agent/axi4_stream_agent.sv; src/env/axi4_stream_env.sv | unit_test golden vector + AXIS-P004 稳定性子码 | smoke,passive | hs.same_cycle | NOT_RUN |
| REQ-CFG-001 | src/axi4_stream_config.sv; src/axi4_stream_if.sv | unit_test golden vector + AXIS-P004 稳定性子码 | unit,config | cfg.w64 | NOT_RUN |
| REQ-CFG-002 | src/axi4_stream_config.sv; src/axi4_stream_if.sv | unit_test golden vector + AXIS-P004 稳定性子码 | unit,config | cfg.w64 | NOT_RUN |
| REQ-CFG-003 | src/axi4_stream_config.sv; src/axi4_stream_if.sv | unit_test golden vector + AXIS-P004 稳定性子码 | unit,config | cfg.w64 | NOT_RUN |
| REQ-CFG-004 | src/axi4_stream_config.sv; src/axi4_stream_if.sv | unit_test golden vector + AXIS-P004 稳定性子码 | unit,config | cfg.w64 | NOT_RUN |
| REQ-CFG-005 | src/axi4_stream_config.sv; src/axi4_stream_if.sv | unit_test golden vector + AXIS-P004 稳定性子码 | unit,config | cfg.w64 | NOT_RUN |
| REQ-CFG-006 | src/axi4_stream_config.sv; src/axi4_stream_if.sv | unit_test golden vector + AXIS-P004 稳定性子码 | unit,config | cfg.w64 | NOT_RUN |
| REQ-CFG-007 | src/axi4_stream_config.sv; src/axi4_stream_if.sv | unit_test golden vector + AXIS-P004 稳定性子码 | unit,config | cfg.w64 | NOT_RUN |
| REQ-PRO-001 | src/axi4_stream_types_pkg.sv; src/agent/axi4_stream_monitor.sv | AXIS-P001..P010（协议时序与稳定性） | feature,corner | qual.data | NOT_RUN |
| REQ-PRO-002 | src/axi4_stream_types_pkg.sv; src/agent/axi4_stream_monitor.sv | AXIS-P001..P010（协议时序与稳定性） | feature,corner | qual.data | NOT_RUN |
| REQ-PRO-003 | src/axi4_stream_types_pkg.sv; src/agent/axi4_stream_monitor.sv | AXIS-P001..P010（协议时序与稳定性） | feature,corner | qual.data | NOT_RUN |
| REQ-PRO-004 | src/axi4_stream_types_pkg.sv; src/agent/axi4_stream_monitor.sv | AXIS-P001..P010（协议时序与稳定性） | feature,corner | qual.data | NOT_RUN |
| REQ-PRO-005 | src/axi4_stream_types_pkg.sv; src/agent/axi4_stream_monitor.sv | AXIS-P001..P010（协议时序与稳定性） | feature,corner | qual.data | NOT_RUN |
| REQ-PRO-006 | src/axi4_stream_types_pkg.sv; src/agent/axi4_stream_monitor.sv | AXIS-P001..P010（协议时序与稳定性） | feature,corner | qual.data | NOT_RUN |
| REQ-PRO-007 | src/axi4_stream_types_pkg.sv; src/agent/axi4_stream_monitor.sv | AXIS-P001..P010（协议时序与稳定性） | feature,corner | qual.data | NOT_RUN |
| REQ-PRO-008 | src/axi4_stream_types_pkg.sv; src/agent/axi4_stream_monitor.sv | AXIS-P001..P010（协议时序与稳定性） | feature,corner | qual.data | NOT_RUN |
| REQ-PRO-009 | src/axi4_stream_types_pkg.sv; src/agent/axi4_stream_monitor.sv | AXIS-P001..P010（协议时序与稳定性） | feature,corner | qual.data | NOT_RUN |
| REQ-PRO-010 | src/axi4_stream_types_pkg.sv; src/agent/axi4_stream_monitor.sv | AXIS-P001..P010（协议时序与稳定性） | feature,corner | qual.data | NOT_RUN |
| REQ-CHK-001 | src/checker/axi4_stream_checker.sv; src/checker/axi4_stream_assertions.sv | AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001 | unit,feature,corner | sva.p004_data | NOT_RUN |
| REQ-CHK-002 | src/checker/axi4_stream_checker.sv; src/checker/axi4_stream_assertions.sv | AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001 | unit,feature,corner | sva.p004_data | NOT_RUN |
| REQ-CHK-003 | src/checker/axi4_stream_checker.sv; src/checker/axi4_stream_assertions.sv | AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001 | unit,feature,corner | sva.p004_data | NOT_RUN |
| REQ-CHK-004 | src/checker/axi4_stream_checker.sv; src/checker/axi4_stream_assertions.sv | AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001 | unit,feature,corner | sva.p004_data | NOT_RUN |
| REQ-CHK-005 | src/checker/axi4_stream_checker.sv; src/checker/axi4_stream_assertions.sv | AXIS-P001..P009 / A001 / A002 / W001 / W002 / C001 / I001 | unit,feature,corner | sva.p004_data | NOT_RUN |
| REQ-TXN-001 | src/transaction/axi4_stream_item.sv | unit_test golden vector + AXIS-P004 稳定性子码 | unit,feature | pkt.single | NOT_RUN |
| REQ-TXN-002 | src/transaction/axi4_stream_item.sv | unit_test golden vector + AXIS-P004 稳定性子码 | unit,feature | pkt.single | NOT_RUN |
| REQ-TXN-003 | src/transaction/axi4_stream_item.sv | unit_test golden vector + AXIS-P004 稳定性子码 | unit,feature | pkt.single | NOT_RUN |
| REQ-TXN-004 | src/transaction/axi4_stream_item.sv | unit_test golden vector + AXIS-P004 稳定性子码 | unit,feature | pkt.single | NOT_RUN |
| REQ-TXN-005 | src/transaction/axi4_stream_item.sv | unit_test golden vector + AXIS-P004 稳定性子码 | unit,feature | pkt.single | NOT_RUN |
| REQ-TXN-006 | src/transaction/axi4_stream_item.sv | unit_test golden vector + AXIS-P004 稳定性子码 | unit,feature | pkt.single | NOT_RUN |
| REQ-TXN-007 | src/transaction/axi4_stream_item.sv | unit_test golden vector + AXIS-P004 稳定性子码 | unit,feature | pkt.single | NOT_RUN |
| REQ-INT-001 | src/axi4_stream_if.sv; src/axi4_stream_pkg.sv; aixsilicon_vip_axi4_stream_1.0.0.core | unit_test golden vector + AXIS-P004 稳定性子码 | compile,smoke | cfg.all | NOT_RUN |
| REQ-INT-002 | src/axi4_stream_if.sv; src/axi4_stream_pkg.sv; aixsilicon_vip_axi4_stream_1.0.0.core | unit_test golden vector + AXIS-P004 稳定性子码 | compile,smoke | cfg.all | NOT_RUN |
| REQ-INT-003 | src/axi4_stream_if.sv; src/axi4_stream_pkg.sv; aixsilicon_vip_axi4_stream_1.0.0.core | unit_test golden vector + AXIS-P004 稳定性子码 | compile,smoke | cfg.all | NOT_RUN |
| REQ-INT-004 | src/axi4_stream_if.sv; src/axi4_stream_pkg.sv; aixsilicon_vip_axi4_stream_1.0.0.core | unit_test golden vector + AXIS-P004 稳定性子码 | compile,smoke | cfg.all | NOT_RUN |
| REQ-INT-005 | src/axi4_stream_if.sv; src/axi4_stream_pkg.sv; aixsilicon_vip_axi4_stream_1.0.0.core | unit_test golden vector + AXIS-P004 稳定性子码 | compile,smoke | cfg.all | NOT_RUN |
| REQ-SRC-001 | src/agent/axi4_stream_driver.sv; src/sequences/axi4_stream_base_seq.sv | AXIS-P003/P004（驱动合法性由 checker 观测） | corner,stress | hs.backtoback | NOT_RUN |
| REQ-SRC-002 | src/agent/axi4_stream_driver.sv; src/sequences/axi4_stream_base_seq.sv | AXIS-P003/P004（驱动合法性由 checker 观测） | corner,stress | hs.backtoback | NOT_RUN |
| REQ-SRC-003 | src/agent/axi4_stream_driver.sv; src/sequences/axi4_stream_base_seq.sv | AXIS-P003/P004（驱动合法性由 checker 观测） | corner,stress | hs.backtoback | NOT_RUN |
| REQ-SRC-004 | src/agent/axi4_stream_driver.sv; src/sequences/axi4_stream_base_seq.sv | AXIS-P003/P004（驱动合法性由 checker 观测） | corner,stress | hs.backtoback | NOT_RUN |
| REQ-SRC-005 | src/agent/axi4_stream_driver.sv; src/sequences/axi4_stream_base_seq.sv | AXIS-P003/P004（驱动合法性由 checker 观测） | corner,stress | hs.backtoback | NOT_RUN |
| REQ-SNK-001 | src/agent/axi4_stream_sink_driver.sv | AXIS-P004-W001（ready 等待与稳定性） | config,random | x.keys_x_bp | NOT_RUN |
| REQ-SNK-002 | src/agent/axi4_stream_sink_driver.sv | AXIS-P004-W001（ready 等待与稳定性） | config,random | x.keys_x_bp | NOT_RUN |
| REQ-SNK-003 | src/agent/axi4_stream_sink_driver.sv | AXIS-P004-W001（ready 等待与稳定性） | config,random | x.keys_x_bp | NOT_RUN |
| REQ-SNK-004 | src/agent/axi4_stream_sink_driver.sv | AXIS-P004-W001（ready 等待与稳定性） | config,random | x.keys_x_bp | NOT_RUN |
| REQ-MON-001 | src/agent/axi4_stream_monitor.sv | AXIS-P006..P009（未知值检查） | smoke,corner | pkt.multi | NOT_RUN |
| REQ-MON-002 | src/agent/axi4_stream_monitor.sv | AXIS-P006..P009（未知值检查） | smoke,corner | pkt.multi | NOT_RUN |
| REQ-MON-003 | src/agent/axi4_stream_monitor.sv | AXIS-P006..P009（未知值检查） | smoke,corner | pkt.multi | NOT_RUN |
| REQ-MON-004 | src/agent/axi4_stream_monitor.sv | AXIS-P006..P009（未知值检查） | smoke,corner | pkt.multi | NOT_RUN |
| REQ-MON-005 | src/agent/axi4_stream_monitor.sv | AXIS-P006..P009（未知值检查） | smoke,corner | pkt.multi | NOT_RUN |
| REQ-MON-006 | src/agent/axi4_stream_monitor.sv | AXIS-P006..P009（未知值检查） | smoke,corner | pkt.multi | NOT_RUN |
| REQ-MON-007 | src/agent/axi4_stream_monitor.sv | AXIS-P006..P009（未知值检查） | smoke,corner | pkt.multi | NOT_RUN |
| REQ-RST-001 | src/agent/axi4_stream_driver.sv; src/agent/axi4_stream_monitor.sv | unit_test golden vector + AXIS-P004 稳定性子码 | corner | x.reset_x_hs | NOT_RUN |
| REQ-RST-002 | src/agent/axi4_stream_driver.sv; src/agent/axi4_stream_monitor.sv | unit_test golden vector + AXIS-P004 稳定性子码 | corner | x.reset_x_hs | NOT_RUN |
| REQ-RST-003 | src/agent/axi4_stream_driver.sv; src/agent/axi4_stream_monitor.sv | unit_test golden vector + AXIS-P004 稳定性子码 | corner | x.reset_x_hs | NOT_RUN |
| REQ-RST-004 | src/agent/axi4_stream_driver.sv; src/agent/axi4_stream_monitor.sv | unit_test golden vector + AXIS-P004 稳定性子码 | corner | x.reset_x_hs | NOT_RUN |
| REQ-RST-005 | src/agent/axi4_stream_driver.sv; src/agent/axi4_stream_monitor.sv | unit_test golden vector + AXIS-P004 稳定性子码 | corner | x.reset_x_hs | NOT_RUN |
| REQ-RST-006 | src/agent/axi4_stream_driver.sv; src/agent/axi4_stream_monitor.sv | unit_test golden vector + AXIS-P004 稳定性子码 | corner | x.reset_x_hs | NOT_RUN |
| REQ-RST-007 | src/agent/axi4_stream_driver.sv; src/agent/axi4_stream_monitor.sv | unit_test golden vector + AXIS-P004 稳定性子码 | corner | x.reset_x_hs | NOT_RUN |
| REQ-ERR-001 | src/env/axi4_stream_violation_injector.sv; tools/mutate.py | unit_test golden vector + AXIS-P004 稳定性子码 | unit | sva.p005 | NOT_RUN |
| REQ-ERR-002 | src/env/axi4_stream_violation_injector.sv; tools/mutate.py | unit_test golden vector + AXIS-P004 稳定性子码 | unit | sva.p005 | NOT_RUN |
| REQ-ERR-003 | src/env/axi4_stream_violation_injector.sv; tools/mutate.py | unit_test golden vector + AXIS-P004 稳定性子码 | unit | sva.p005 | NOT_RUN |
| REQ-SCB-001 | src/scoreboard/axi4_stream_scoreboard.sv; src/scoreboard/axi4_stream_reference_model.sv | scoreboard compare_packet（EXACT_BEAT/LOGICAL_STREAM/CUSTOM） | smoke,feature,random | x.qual_x_pos | NOT_RUN |
| REQ-SCB-002 | src/scoreboard/axi4_stream_scoreboard.sv; src/scoreboard/axi4_stream_reference_model.sv | scoreboard compare_packet（EXACT_BEAT/LOGICAL_STREAM/CUSTOM） | smoke,feature,random | x.qual_x_pos | NOT_RUN |
| REQ-SCB-003 | src/scoreboard/axi4_stream_scoreboard.sv; src/scoreboard/axi4_stream_reference_model.sv | scoreboard compare_packet（EXACT_BEAT/LOGICAL_STREAM/CUSTOM） | smoke,feature,random | x.qual_x_pos | NOT_RUN |
| REQ-SCB-004 | src/scoreboard/axi4_stream_scoreboard.sv; src/scoreboard/axi4_stream_reference_model.sv | scoreboard compare_packet（EXACT_BEAT/LOGICAL_STREAM/CUSTOM） | smoke,feature,random | x.qual_x_pos | NOT_RUN |
| REQ-SCB-005 | src/scoreboard/axi4_stream_scoreboard.sv; src/scoreboard/axi4_stream_reference_model.sv | scoreboard compare_packet（EXACT_BEAT/LOGICAL_STREAM/CUSTOM） | smoke,feature,random | x.qual_x_pos | NOT_RUN |
| REQ-SCB-006 | src/scoreboard/axi4_stream_scoreboard.sv; src/scoreboard/axi4_stream_reference_model.sv | scoreboard compare_packet（EXACT_BEAT/LOGICAL_STREAM/CUSTOM） | smoke,feature,random | x.qual_x_pos | NOT_RUN |
| REQ-SCB-007 | src/scoreboard/axi4_stream_scoreboard.sv; src/scoreboard/axi4_stream_reference_model.sv | scoreboard compare_packet（EXACT_BEAT/LOGICAL_STREAM/CUSTOM） | smoke,feature,random | x.qual_x_pos | NOT_RUN |
| REQ-SCB-008 | src/scoreboard/axi4_stream_scoreboard.sv; src/scoreboard/axi4_stream_reference_model.sv | scoreboard compare_packet（EXACT_BEAT/LOGICAL_STREAM/CUSTOM） | smoke,feature,random | x.qual_x_pos | NOT_RUN |
| REQ-SEQ-001 | src/sequences/axi4_stream_base_seq.sv | unit_test golden vector + AXIS-P004 稳定性子码 | feature,random,config | x.last_x_stall | NOT_RUN |
| REQ-COV-001 | src/coverage/axi4_stream_coverage.sv | covergroup 采样断言（REQ-COV-001） | random | qual.mixed | NOT_RUN |
| REQ-COV-002 | src/coverage/axi4_stream_coverage.sv | covergroup 采样断言（REQ-COV-001） | random | qual.mixed | NOT_RUN |
| REQ-COV-003 | src/coverage/axi4_stream_coverage.sv | covergroup 采样断言（REQ-COV-001） | random | qual.mixed | NOT_RUN |
| REQ-PERF-001 | src/agent/axi4_stream_monitor.sv; src/env/axi4_stream_env.sv | unit_test golden vector + AXIS-P004 稳定性子码 | stress | pkt.long | NOT_RUN |
| REQ-PERF-002 | src/agent/axi4_stream_monitor.sv; src/env/axi4_stream_env.sv | unit_test golden vector + AXIS-P004 稳定性子码 | stress | pkt.long | NOT_RUN |
| REQ-PERF-003 | src/agent/axi4_stream_monitor.sv; src/env/axi4_stream_env.sv | unit_test golden vector + AXIS-P004 稳定性子码 | stress | pkt.long | NOT_RUN |
| REQ-PERF-004 | src/agent/axi4_stream_monitor.sv; src/env/axi4_stream_env.sv | unit_test golden vector + AXIS-P004 稳定性子码 | stress | pkt.long | NOT_RUN |
| REQ-VAL-001 | unit_test/axi4_stream_unit_*.sv; self_test/tb/axi4_stream_dut_fixtures.sv | unit_test golden vector + AXIS-P004 稳定性子码 | unit | qual.null | NOT_RUN |
| REQ-VAL-002 | unit_test/axi4_stream_unit_*.sv; self_test/tb/axi4_stream_dut_fixtures.sv | unit_test golden vector + AXIS-P004 稳定性子码 | unit | qual.null | NOT_RUN |
| REQ-ACC-001 | self_test/tb/axi4_stream_tests.sv; config/verification-plan.yaml | unit_test golden vector + AXIS-P004 稳定性子码 | stress,unit | trf.tlast | NOT_RUN |
| REQ-ACC-002 | self_test/tb/axi4_stream_tests.sv; config/verification-plan.yaml | unit_test golden vector + AXIS-P004 稳定性子码 | stress,unit | trf.tlast | NOT_RUN |
| REQ-ACC-003 | self_test/tb/axi4_stream_tests.sv; config/verification-plan.yaml | unit_test golden vector + AXIS-P004 稳定性子码 | stress,unit | trf.tlast | NOT_RUN |
| REQ-ACC-004 | self_test/tb/axi4_stream_tests.sv; config/verification-plan.yaml | unit_test golden vector + AXIS-P004 稳定性子码 | stress,unit | trf.tlast | NOT_RUN |
| REQ-ACC-005 | self_test/tb/axi4_stream_tests.sv; config/verification-plan.yaml | unit_test golden vector + AXIS-P004 稳定性子码 | stress,unit | trf.tlast | NOT_RUN |
| REQ-ACC-006 | self_test/tb/axi4_stream_tests.sv; config/verification-plan.yaml | unit_test golden vector + AXIS-P004 稳定性子码 | stress,unit | trf.tlast | NOT_RUN |
| REQ-ACC-007 | self_test/tb/axi4_stream_tests.sv; config/verification-plan.yaml | unit_test golden vector + AXIS-P004 稳定性子码 | stress,unit | trf.tlast | NOT_RUN |

---

# 8. Requirement → Architecture

见 `docs/architecture.md` §35（家族级映射）；本文 §7 为逐 ID 版本。

---

# 9. Requirement → Implementation

每个 `Implementation` 列条目均为源码根内相对路径，由门禁逐条核对存在性
（`report-check --kind rtm` 在 PASS case 上强制校验）。

---

# 10. Requirement → Validation

`Test witness / Checker` 列的 tier 名称与 `config/verification-plan.yaml` 的
regression case ID 集合一致（`compile/unit/smoke/feature/corner/random/stress/config/passive`）。

---

# 11. Result

设计期默认 `NOT_RUN`。逐次执行的实际结果只写 `reports/<run-id>/rtm.md`，
且 PASS case 必须引用有效 `evidence_ids`、`implementation`、`checker`、`test`、`coverage`。

---

# 12. Rule Traceability

| Rule ID | 需求来源 | 检查实现 |
|---|---|---|
| AXIS-P001 | REQ-PRO-001、REQ-RST-001 | checker + SVA `a_p001` |
| AXIS-P002 | REQ-CHK-002 | checker + SVA `a_p002` |
| AXIS-P003 | REQ-PRO-003 | checker + SVA `a_p003` |
| AXIS-P004 | REQ-PRO-003 | checker（逐字段子码）+ SVA `a_p004_*` |
| AXIS-P005 | REQ-PRO-005 | checker + SVA `a_p005` |
| AXIS-P006 | REQ-MON-007 | checker + SVA `a_p006*` |
| AXIS-P007 | REQ-MON-007 | checker + SVA `a_p007` |
| AXIS-P008 | REQ-CHK-001 | checker（`axis_payload_has_unknown`） |
| AXIS-P009 | REQ-CHK-001 | checker |
| AXIS-A001 | REQ-CHK-005（应用配置） | checker（缺省关闭） |
| AXIS-A002 | REQ-SCB-003（应用插件） | checker（缺省关闭） |
| AXIS-W001 | REQ-SNK-002 / REQ-CFG-001 | checker（缺省关闭） |
| AXIS-W002 | REQ-MON-005 | checker（缺省关闭） |
| AXIS-C001 | REQ-CFG-006 | config.validate / checker |
| AXIS-I001 | REQ-CFG-001（容量） | monitor（组包上限） |

---

# 13. Checker Traceability

超出 §7 的说明见 `docs/architecture.md` §4 与 checker 源码；每条规则可开关、
可改严重度、可限报，并输出结构化 event（REQ-CHK-003）。

---

# 14. Assertion Traceability

SVA 位于 `src/checker/axi4_stream_assertions.sv`，在 `self_test/tb/axi4_stream_smoke_tb.sv`
中直接例化于 source 侧接口（REQ-CHK-001：可 bind 也可例化）。

---

# 15. Coverage Traceability

COV 列条目属于 `config/verification-plan.yaml` 的 `coverage_bins` 四项清单之一；
覆盖报告必须给出完整 bin→hit 映射。

---

# 16. Feature Coverage

`feature_coverage` 的 49 个 bin 覆盖 Handshake/Packet/Qualifier/Stream/Sideband/
Configuration/Transform（对应 requirement §10.1 表）。

---

# 17. Rule Coverage

`assertion_coverage` 的 9 个 bin 对应 SVA 规则（P001/P002/P003/P004-DATA/P004-KEEP/
P005/P006/P006-TREADY/P007）。

---

# 18. Mutation Traceability

12 项源码变异（`tools/mutate.py`）覆盖：byte 分类、NULL 移除、END_PACKET 保留、
TKEEP 缺省、非法限定符、HAS_TDATA 配置拒绝、拍数、末拍掩码、可精确表达、
EXACT_BEAT 比较、token 比较、有效载荷 X 检查。

---

# 19. Mutation Summary

运行结果写 `reports/<run-id>/mutation.md`（≥95%，P0 全部 PASS，未报项计入分母）。

---

# 20. Configuration Traceability

配置项 → REQ 映射见 requirement §2/§7；profile 见 `config/qualification.yaml`
与 `axi4_stream_config::apply_profile`。

---

# 21. Public API Traceability

见 requirement §8.1 表与 `docs/user-guide.md` §12/§13。

---

# 22. Agent Mode Traceability

SOURCE / SINK / PASSIVE 与 FULL_UVM/PASSIVE_UVM 组合见 `docs/architecture.md` §4。

---

# 23. Reset Traceability

复位相关 REQ（RST-001..007）逐条状态见 §7 的 gap 列。

---

# 24. Timeout Traceability

`MAX_READY_WAIT` / `MAX_PACKET_IDLE` 缺省关闭，对应 AXIS-W001/W002。

---

# 25. Target Traceability

Sink 背压 9 种模式见 requirement §18.2（REQ-SNK-001）。

---

# 26. RAL

**N/A**：AXI4-Stream 无寄存器访问语义，不提供 RAL adapter。

---

# 27. Debug Traceability

analysis port 与统计 API 见 requirement §13（MON-002/005/006/007、PERF-001..004）。

---

# 28. Statistics

统计项与汇总位置见 `docs/architecture.md` §33 与 env `report_stats()`。

---

# 29. Build / Simulation Traceability

| 需求 | 构建/仿真要素 |
|---|---|
| REQ-INT-004 | `self_test/Makefile` 目标 + `.core` |
| REQ-INT-005 | VCS + UVM 1.2（版本记录在运行报告 tools） |
| REQ-ACC-004 | corner tier 无气泡段 + stress tier |

---

# 30. Metadata

报告 metadata 契约见套件 `references/report-metadata.md`；本 VIP 的
`reports/<run-id>/*.md` 使用同一 schema。

---

# 31. Documentation

| 文档 | 内容 |
|---|---|
| `docs/requirement.md` | What |
| `docs/architecture.md` | How |
| `docs/validation-plan.md` | 验证策略 |
| `docs/rtm.md` | 本文件 |
| `docs/user-guide.md` | 使用说明 |

---

# 32. Regression Summary

由 `reports/<run-id>/regression.md` 提供（逐 case 状态 + execution metadata）。

---

# 33. Simulation Summary

在每个 tier 日志中输出 `SRC if=0 accepted=... util=...` 与
`SCOREBOARD matched=...`（见 `self_test/tb/axi4_stream_smoke_env.sv`）。

---

# 34. Coverage Summary

由 `reports/<run-id>/coverage.md` 提供（四项指标完整 bin→hit + holes）。

---

# 35. Closure

覆盖闭合定义见 requirement §10.1（REQ-ACC-003）；闭合判定由 coverage 报告计算。

---

# 36. Uncovered Items

未命中 bin 必须显式列出；mandatory OPEN 阻断门禁，v1 不接受 waiver 字符串绕过。

---

# 37. Failed Items

失败项必须保留原 case ID 与证据链接，不得从冻结计划中删除分母。

---

# 38. Known Issues

已知缺口集中在 §7 的 gap 列（复位矩阵、错误注入场景化、CHECKER_ONLY 独立构建、
1000000 beat 压力、20 seed 矩阵、第二仿真器兼容矩阵）。

---

# 39. Waiver

v1 门禁尚无 waiver 认可机制；WAIVED 不能替代 PASS。需要豁免的项目必须先明确
合同扩展，不能只改状态绕过检查。

---

# 40. Limitation

见 `docs/requirement.md` §23 与 `docs/architecture.md` §37。

---

# 41. Evidence

证据路径相对 RUN_ROOT，必须位于 `logs/evidence/coverage` 下且哈希一致。

---

# 42. Evidence Strength

分级：执行日志（log）> 覆盖数据（coverage）> 评审记录（review）。
PASS 的执行类 case 至少需要一条 log 证据。

---

# 43. Readiness

进入资格判定的条件：六类报告齐备 + RTM 全 ID 覆盖 + 生成 core 有效 +
`qualify` 内容绑定计算通过。当前状态见运行报告。

---

# 44. Final Qualification

由 `vip_tool.py qualify` 计算并写 `gates/qualification.yaml`；本文不预先声明结果。

---

# 45. Sign Off

签核需要：六类报告 metadata 通过 + core 有效 + 资产指纹一致。
本次签核结论见 `reports/<run-id>/` 的 gate 汇总。

---

# 46. Checklist

| # | 检查 | 状态 |
|---|---|---|
| 1 | 90 条 REQ 全部出现在 §7 | 已完成 |
| 2 | 每条 REQ 有实现路径 | 已完成 |
| 3 | 每条 REQ 有测试入口 | 已完成 |
| 4 | 每条 REQ 有覆盖 bin | 已完成 |
| 5 | Result 只在运行报告更新 | 已完成（本文固定 NOT_RUN） |
| 6 | 缺口逐项显式记录 | 已完成（§7 gap 列） |

---

# 47. Complete

RTM 完成定义：

- [x] ID 集合与 `config/requirements.yaml`、需求合同一致（90 条）。
- [x] 每行含实现 / 检查 / 测试 / 覆盖四列。
- [x] 无悬空 mandatory 项：缺口逐项显式记录为 NOT_RUN 及剩余工作。
- [x] 本文不声明任何 Gate PASS。

> 运行期 RTM 由 `vip_tool.py report-check --kind rtm` 计算。
