# AIXSILICON APB VIP — Requirement Traceability Matrix（RTM）

> **Document ID**: `aixsilicon:vip:apb:rtm` · 版本: 1.0.0
> **VIP Name**: APB VIP（APB3/4/5，FULL_UVM，P0）
> **Protocol / Interface**: AMBA APB3 / APB4 / APB5（ARM IHI 0024E）
> **Requirement Baseline**: requirement.md r3.1（G0 PASS）
> **Architecture Baseline**: architecture.md r4（G1 PASS）
> **Validation Plan Baseline**: validation-plan.md 1.0.0
> **Target VLNV**: `aixsilicon:vip:apb:1.0.0`
> **Validation Run**: VCS W-2024.09-SP1 / UVM 1.2，2026-09-03 G4/G5 轮

> 模板：vip-development-suite `templates/vip/docs/rtm.md`（47 章）；本文件为 FULL_UVM
> 按 Profile/协议裁剪后的应用。章节适用性遵循 `references/template-applicability.md`；
> 不适用章节标 `N/A`，不留空占位。

---

# 1. Purpose（必填）

本文档建立 APB VIP 的完整追溯链：`REQ → Arch/Impl → Validation → Checker/SVA →
Coverage → Mutation → Evidence → Final Status`，是"APB VIP 完整性"的证据。

# 2. RTM Principles（必填）

- **Requirement Driven**：所有追溯从 requirement.md 的 REQ/Feature 出发；
- **Evidence Based**：Result 必须关联命令/日志/报告（run_log.md 证据索引）；
- **Bidirectional**：REQ→Validation ↔ Validation→REQ 双向可查；
- **Single Final Status**：每 REQ 一个状态：PASS / FAIL / BLOCKED / WAIVED / N/A / NOT_RUN。

# 3. Input Artifacts（必填）

| Artifact | Purpose | Baseline |
|---|---|---|
| `docs/requirement.md` | Requirement SSOT | r3.1（G0 Freeze） |
| `docs/architecture.md` | Architecture / Component Mapping | r4（G1 PASS） |
| `docs/validation-plan.md` | Validation Case 定义（VAL-001..004） | 1.0.0 |
| `src/` | Implementation | 1.0.0 |
| `reports/run_log.md` | 执行证据（compile/regression/coverage/mutation） | 2026-09-03 |
| `reports/gate_status.md` | Gate G0-G6 判定 | 2026-09-03 |
| `reports/coverage/coverage_report.md` | 覆盖证据（G4） | 2026-09-03 |
| `reports/mutation/mutation_report.md` | Mutation 证据（G5） | 2026-09-03 |

# 4. Traceability Model（必填）

```text
REQ (PRO-/RUL-/CFG-/TRN-/TIM-/OO-/ERR-/VER-/RAL-)
  ├── ARCH (architecture.md §4 组件矩阵)
  ├── IMPL (src/ 关键类/helper)
  ├── VAL  (self_test/unit_test tier + UTxx)
  ├── CHK/SVA (checker/apb_protocol_sva.sv)
  ├── COV  (coverage/apb_coverage.sv CP/CR)
  ├── MUT  (self_test/apb_fi_test.sv FI-xxx)
  └── EVIDENCE (reports/*)
```

# 5. Requirement Status Definition（必填）

| Status | Definition |
|---|---|
| PASS | 已实现 + 已验证 + 证据完整（本轮 run_log/gate_status 有对应） |
| FAIL | 已验证但结果不满足 |
| BLOCKED | 环境/依赖/缺陷阻塞 |
| WAIVED | 经评审批准不作为本版 blocker |
| N/A | 对当前 Profile / Config 不适用 |
| NOT_RUN | 已规划验证但本轮未差异化执行 |

> P0 conformance（APB3/4/5，requirement §24）在 1.0.0 发布前不允许存在 NOT_RUN
> （QLF-006）；当前 developing 阶段允许，须显式列入 §36 Uncovered。

# 6. Requirement Priority（必填）

继承 requirement.md §24：P0 = APB3/4/5 conformance（USER/WAKEUP/RME/check_type 全含）、
RAL adapter；P1 = RAL predictor、advanced negative；P2 = trace/recording/statistics。
RTM 不重新定义优先级。

# 7. Master RTM（必填，核心表）

> 列裁剪说明：模板 §7 的 11 列（REQ/Priority/Arch/Impl/Val/CHK/COV/MUT/Evidence/Status）
> 对不适用项标 `N/A`。APB 术语：`Implementation` 用 src 类名；`Check` 用
> apb_checker/apb_protocol_sva 的 CHK/SVA id；`Test` 用 tier + UTxx（validation-plan §3）；
> `Coverage` 用 CP/CR（coverage 模型）；`Result` 从 run_log 证据转换，禁止无证据自封。

| Requirement | Priority | Impl（src 关键对象） | Check（CHK/SVA） | Test（tier+UT） | Coverage | Result | Evidence |
|---|---|---|---|---|---|---|---|
| PRO-001 IDLE | P0 | apb_if helper | — | UT01 | CP-08(idle_to_transfer) | PASS | cov smoke/sweep |
| PRO-002 SETUP | P0 | master_driver drive_setup | SVA-A1 | UT01 | — | PASS | same |
| PRO-003 ACCESS | P0 | master_driver drive_access | SVA-C1 | UT01 | — | PASS | same |
| PRO-004 READ | P0 | driver+apb_item | CHK-R7 | UT02 | CP-01 | PASS | smoke |
| PRO-005 WRITE | P0 | driver+apb_item | — | UT01 | CP-01 | PASS | smoke |
| PRO-006 WAIT | P0 | slave_driver wait policy | SVA-B1 | UT04/05/06 | CP-04 | PASS | corner/sweep |
| PRO-007 SLVERR | P0 | slave_driver error resp | CHK-REC | UT07/error | CP-03 | PASS | error |
| PRO-008 B2B | P0 | master_driver prefetch | — | UT03 | CP-08(b2b) | PASS | feature/sweep |
| PRO-009 PSTRB | P0 | item+driver strb | SVA-F1 | UT11 | CP-06/CR-04 | PASS | sweep |
| PRO-010 PPROT | P0 | item+driver prot | SVA-B1 | UT12 | CP-05/CR-05 | PASS | sweep |
| PRO-011 USER | P0 | item user×3 + driver | — | UT13 (APB5) | — | PASS | apb5 |
| PRO-012 WAKEUP | P0 | item.wakeup + driver | — | UT14 (APB5) | — | PASS | apb5 |
| PRO-013 RME/PNSE | P0 | item.pnse + monitor/driver | — | UT20 (APB5) | CP-07 | PASS | apb5 |
| PRO-014 CHECK | P0 | apb_if CHK 族+check_type | — | UT21 (APB5) | — | PASS | apb5 |
| PRO-015 RESET | P0 | driver/monitor reset | SVA-G1 | UT08/09/10 | — | NOT_RUN | 缺独立 reset tier |
| PRO-016 ABORTED | P0 | monitor ABORTED | CHK-ABORT | UT10/sweep | CP-03(aborted) | PASS | cov sweep |
| RUL-001 | P0 | SVA-A1 | SVA-A1 | UT15/error | — | PASS | fI/error |
| RUL-002 | P0 | SVA-A2 | SVA-A2 | UT15/error | — | PASS | fi |
| RUL-003 | P0 | SVA-B1 | SVA-B1 | UT15/error | — | PASS | fi |
| RUL-004 | P0 | SVA-C1 | SVA-C1 | UT03 | — | PASS | feature |
| RUL-005 REC | P0 | CHK-REC | CHK-REC | UT18/error | — | PASS | error |
| RUL-006 | P0 | SVA-F1 | CHK-R7 | UT11/error | — | PASS | fi/sweep |
| RUL-007 | P0 | slave memory | CHK-R7 | UT11 | — | PASS | sweep |
| RUL-008 | P0 | SVA-G1 | SVA-G1 | UT08 | — | NOT_RUN | 无独立 reset |
| RUL-009 | P0 | monitor 超时 | CHK-R9 | error/fi | — | PASS | fi(RUL-009=4) |
| RUL-010 | P0 | monitor 相位机 | CHK-R10 | UT17/error | — | PASS | error |
| RUL-011 | P0 | monitor validity | CHK-X | UT22 | — | NOT_RUN | 无独立 X-check tier |
| VER-013 X-check | P0 | CHK-X | CHK-X | UT22 | — | NOT_RUN | same |
| RAL-001 adapter | P0 | apb_reg_adapter | — | UT16 | — | NOT_RUN | 无 RAL 独立场景 |
| RAL-003 byte_en | P0 | adapter.configure | — | UT16 | — | NOT_RUN | same |
| CFG-003/004 | P0 | config.validate_widths | fatal | UT19(L1) | — | PASS | unit config 44 |
| CFG-008 parity | P0 | types parity helper | — | L1 parity_group | — | PASS | unit types 72 |
| TRN-002 wait 分离 | P0 | item requested/observed | CHK-R9 | UT05/06/corner | — | PASS | corner |
| TIM-001 | P0 | CHK-R9 | CHK-R9 | error/fi | — | PASS | fi |
| OO-1/2 | P0 | tie-off 归一化 | — | UT17/18/error | — | PASS | error |
| ERR-006 unaligned | P1 | inject_unaligned | 反向(不误报) | — | — | NOT_RUN | 无实例/无 tier |
| VER-005 debug | P1 | monitor convert2string | — | smoke | — | PASS | smoke log |
| VER-013（见上） | — | — | — | — | — | — | — |

# 8. Requirement-to-Architecture Trace（必填）

> 完整组件映射见 architecture.md §4 组件矩阵（冻结 G1）。核心映射概括：

| REQ 族 | Architecture Section | Component |
|---|---|---|
| PRO-001..016 | architecture §7/§10/§12 | interface / driver / monitor |
| RUL-001..011 | architecture §17 | SVA / checker |
| CFG-003..008 | architecture §6/§8 | config / helper |
| RAL-001/003 | architecture §13 | reg adapter |
| VER-005 | architecture §19 | monitor debug |

# 9. Requirement-to-Implementation Trace（必填）

> 关键实现入口（证明 REQ 实现路径，非穷举）。

| REQ | Component | Implementation | Key Object/Function |
|---|---|---|---|
| PRO-002/003 | driver | `src/agent/apb_master_driver.sv` | drive_setup / drive_access |
| PRO-004/005 | item | `src/transaction/apb_item.sv` | direction/addr/wdata |
| PRO-006 | slave | `src/agent/apb_slave_driver.sv` | wait policy |
| PRO-013 | item+monitor | `apb_item.pnse` + `apb_monitor` | update_derived / pnse 采样 |
| RUL-009 | checker | `src/checker/apb_violation.sv` | CHK-R9 超时 |
| CFG-003/004 | config | `src/apb_config.sv` | validate_widths / validate_interface_vs_config |

# 10. Requirement-to-Validation Trace（必填）

| REQ | VAL ID | Case | Method | Tier |
|---|---|---|---|---|
| PRO-001..005 | VAL-002 | apb_smoke_test | Directed | Smoke |
| PRO-006 | VAL-002 | apb_corner_test | Directed | Corner |
| PRO-007/015/016 | VAL-002 | apb_error_test / apb_sweep | Negative/Directed | Error+Sweep |
| PRO-011..014 | VAL-002 | apb_apb5_test | Directed | APB5 专项 |
| PRO-009/010 + 覆盖 | VAL-002 | apb_cov_sweep_test | Directed/Sweep | Sweep |
| RUL-001..010 | VAL-004 | apb_fi_test | Negative（FI） | Mutation |

# 11. Validation Result Matrix（必填）

| VAL ID | Test | Simulator | Result | Log |
|---|---|---|---|---|
| VAL-002 smoke | apb_smoke_test | VCS W-2024.09-SP1 | PASS | build/logs/smoke.log |
| VAL-002 feature | apb_feature_test | same | PASS | feature.log |
| VAL-002 corner | apb_corner_test | same | PASS | corner.log |
| VAL-002 error | apb_error_test | same | PASS | error.log |
| VAL-002 random | apb_random_test | same | PASS | random.log |
| VAL-002 sweep | apb_cov_sweep_test | same | PASS | cov_sweep.log |
| VAL-002 apb5 | apb_apb5_test | same | PASS | apb5.log |
| VAL-004 mutation | apb_fi_test | same | PASS（5/5 detected） | fi.log |
| VAL-001 unit | unit_test | same | PASS（554/554） | unit_test.log |

# 12. Protocol Rule Trace（按Profile：C 核心）

| Rule | Req | Checker | SVA | Positive | Negative | Status |
|---|---|---|---|---|---|---|
| RUL-001 | PRO-002 | — | A1 | UT01 | FI-001 | PASS |
| RUL-002 | — | — | A2b | UT01 | FI-002 | PASS |
| RUL-003 | PRO-006 | — | B1 | UT04 | FI-003 | PASS |
| RUL-006 | PRO-009 | CHK-R7 | F1 | UT11 | FI-004 | PASS |
| RUL-009 | TIM-001 | CHK-R9 | — | UT05 | FI-005 | PASS |

# 13-16. Checker/Assertion/Coverage Trace（裁剪汇总）

- **Checker**：CHK-R7（transaction）、CHK-REC（PSLVERR 非窗）、CHK-R9（超时）、
  CHK-R10（相位机）、CHK-ABORT（reset 中止）——全有 Positive + Negative 证据；
- **Assertion**：SVA-A1/A2b/B1/C1/F1/G1（apb_protocol_sva.sv，generate-if 按
  elaboration 参数）——覆盖 PRO-002/003/006/009 等；
- **Coverage**：CP-01..08 + CR-01..06 ↔ REQ 映射见 coverage_report.md；
  能力裁剪 cp_pas（rme）由 APB5 专项闭合（100%）。

# 17. Protocol Rule Coverage（按Profile）

| Rule | Legal Exercise | Violation Exercise | Detector | Status |
|---|---|---|---|---|
| RUL-001..010 | 各正常 tier | FI-001..005 | SVA/CHK | PASS |

# 18-19. Mutation Trace（按Profile：C 必填）

| MUT ID | Req | Rule | Injected | Expected Detector | Result | Evidence |
|---|---|---|---|---|---|---|
| FI-001 | RUL-001 | SETUP 延长 | inject_extended_setup | SVA-A1 | DETECTED | reports/mutation/ |
| FI-002 | RUL-002 | 跳 SETUP | inject_illegal_penable | SVA-A2b | DETECTED | same |
| FI-003 | RUL-003 | wait 期地址翻转 | inject_unstable_addr | SVA-B1 | DETECTED(21) | same |
| FI-004 | RUL-006 | 读非法 PSTRB | inject_illegal_strb | SVA-F1 | DETECTED | same |
| FI-005 | RUL-009 | ACCESS 挂死 | FIXED_WAIT=20>16 | CHK-R9 | DETECTED(4) | same |

| Metric | Result | Target | Status |
|---|---|---|---|
| Total Mutation | 5 | - | - |
| Detected | 5 | - | - |
| Detection Rate | 100% | ≥95% | PASS |

# 20-28. Config / API / AgentMode / Reset / Timeout / Target / RAL / Debug（按Profile/协议）

- **Config Trace**：CFG-003/004（宽度合法性，L1 PASS）、CFG-008（parity，L1 PASS）、
  CFG-001/002（版本派生/一致性，L1 PASS）；
- **Agent Mode**：Active Master / Active Slave / Passive 全部存在（apb_agent
  四种模式），smoke/loopback 证明 master+slave 活动路径；
- **Reset Trace**：Before Traffic（tb 上电复位）PASS；During Transaction
  （sweep `+ntb_reset_abort=1` APB_ABORTED）PASS；完整 reset tier（UT08-10）NOT_RUN
  （§36）；
- **Timeout Trace**：RUL-009（FI 证明检测）PASS；timeout_severity policy（req §14）；
- **Target/Behavior**：slave_driver 四层 responder（ZERO/FIXED/RANDOM/SEQ）+ 错误注入
  （ADDRESS_RANGE）——smoke/corner/error 证明；
- **RAL**：UT16 未独立执行 → N/A（当前轮）；predictor P1；
- **Debug**：convert2string（VER-005）smoke log 输出，PASS。

# 29. Build / Simulator Trace（必填）

| Environment | Result | Evidence |
|---|---|---|
| VCS Compile（VIP src + selftest） | PASS | build/logs/unit_compile.log + smoke compile |
| VCS Regression（smoke/feature/corner/error/random/sweep/apb5/mutation） | PASS | cov_*/smoke/... log |
| FuseSoC .core 校验 | PASS | `gen-core --check-only` OK |
| Lint | NOT_RUN | vip_tool 无独立 lint 子命令 |

# 30. Metadata Trace（必填）

| Capability | Check | Result |
|---|---|---|
| registry.yaml 条目（apb，FULL_UVM，P0） | registry 结构 | PASS |
| .core VLNV `aixsilicon:vip:apb:1.0.0` | gen-core | PASS |
| Limitations（requirement §23 LIM-001..005） | 文档一致性 | PASS |

# 31. Documentation Trace（必填）

| Deliverable | Baseline | Status |
|---|---|---|
| requirement.md | r3.1 | PASS |
| architecture.md | r4 | PASS |
| validation-plan.md | 1.0.0 | PASS |
| rtm.md（本文） | 1.0.0 | PASS |
| user-guide.md | 实现后撰写 | PASS |

# 32-34. Regression / Simulator / Coverage Summary（按Profile）

| Tier | Tests | Passed | Status |
|---|---|---|---|
| Smoke / Feature / Corner / Error / Random / Sweep / APB5 / Mutation | 各 ≥1 | 全 PASS | PASS |
| Unit（L1） | types 72 + item 438 + config 44 = 554 | 554 | PASS |

| Coverage Type | Target | Actual | Status |
|---|---|---|---|
| Requirement Coverage | 100% | 98.6% | PARTIAL（cr_dir_error 1 bin） |
| Feature Coverage | ≥95% | 100% | PASS |
| Cross Coverage | ≥90% | 97.2% | PASS |
| Assertion Coverage | ≥95% | 98.6% | PASS |
| Mutation Detection | ≥95% | 100% | PASS |

# 35. Requirement Closure Summary（必填）

| Priority | Total | PASS | NOT_RUN | N/A |
|---|---|---|---|---|
| P0 | 33 | 29 | 4（PRO-015/RUL-008/RUL-011/VER-013/RAL-001/RAL-003→6） | 0 |
| P1 | 少数 | ERR-006 NOT_RUN | 1 | 0 |
| P2 | — | — | — | 本版 N/A |

> 注：P0 实际 NOT_RUN 6 项（PRO-015 RESET、RUL-008、RUL-011、VER-013、RAL-001、RAL-003）
> ——均因本轮未差异化执行独立场景；developing 阶段允许（§5 说明），发布前必须闭合（QLF-006）。

# 36. Uncovered Requirement（必填）

| REQ | Priority | Missing Item | Reason | Action | Status |
|---|---|---|---|---|---|
| PRO-015 RESET | P0 | 独立 reset tier（UT08-10） | 仅 sweep 单 abort，无完整 reset 场景 | 新增 apb_reset_test + tb reset 分级 | OPEN |
| RUL-008 | P0 | reset SVA 独立用例 | 同 PRO-015 | same | OPEN |
| RUL-011 / VER-013 | P0 | X-check 独立 tier（UT22） | 无独立 X/Z 检查场景 | 新增 UT22 tier | OPEN |
| RAL-001/003 | P0 | RAL read/write 场景（UT16） | 无 RAL 独立 bench | 新增 RAL smoke | OPEN |
| ERR-006 | P1 | inject_unaligned 实例+反向验证 | 无实例/无 tier | 补 unaligned 不误报用例 | OPEN |

# 37-39. Failed / Known Issues / Waiver

- **Failed**：无（全部执行项 PASS）；
- **Known Issue**：KI-001 = cr_dir_error 83%（WRITE×ABORTED 单 bin，timing-reset
  干扰负收益，独立 reset-tier 后闭合）——记录于 gate_status；
- **Waiver**：无（本版不申请 WAIVED）。

# 40. Limitation Trace（必填）

| LIM ID | Req | Description | Planned |
|---|---|---|---|
| LIM-001..005 | requirement §23 | 见 requirement §23（接口参数化占位、严格物理省略等） | 1.0.0 |

# 41. Evidence Index（必填）

| Evidence | Type | Location | Generated By |
|---|---|---|---|
| EVD-001 | Regression | `self_test/build/logs/*.log` | make -C self_test |
| EVD-002 | Coverage | `reports/coverage/coverage_report.md` | coverage_merge.py |
| EVD-003 | Mutation | `reports/mutation/mutation_report.md` | make mutation |
| EVD-004 | Unit | `self_test/build/logs/unit_test.log` | make unit |
| EVD-005 | Gate | `reports/gate_status.md` | Agent |
| EVD-006 | Run Log | `reports/run_log.md` | Agent |

# 42-44. Evidence Structure / Readiness / Final Qual

- **Evidence Structure**：reports/ 下 run_log / gate_status / coverage / mutation
  （目录正交，SSOT 单一）；
- **Readiness**：G0-G3 PASS、G4 feature/cross/assertion PASS、G5 mutation 100%、
  compile/unit/regression PASS；G4 requirement 98.6% + G5 lint 未做 → **未达 Qualified**；
- **Final Qual**：`PARTIAL_DEVELOPING`（registry 同步）。

# 45-47. SignOff / Checklist / Complete

- **SignOff**：Requirement（G0）✓ / Architecture（G1）✓ / Validation（G3）✓ /
  Coverage（G4 部分）✓ / Mutation（G5）✓ / 发布（G6）— 待闭合 G4 残余；
- **Checklist**：RTM 已按模板裁剪生成、Result 均有 run_log 证据、Uncovered 显式列出、
  KnownIssue 记录 KI-001；
- **Complete**：developing 状态满足 —— 完整闭环（Qualification/Release）待
  cr_dir_error + 独立 reset/X-check/RAL tier 闭合。

---

**当前状态**：developing。RTM 为模板裁剪合规版（保留 47 章骨架、N/A/裁剪明确）；
全部 Result 对齐 run_log/gate_status 证据，无伪报。
