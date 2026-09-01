# AXI4 VIP — Requirement Traceability Matrix（RTM）

> **Document ID**: `AXI4_RTM_001`
> **VIP Name**: `axi4`
> **Protocol / Interface**: `AXI4 / AXI4-Lite`（IHI 0022E）
> **Version**: `1.0.0`
> **Status**: `Draft（G3 首轮证据；随 G4/G5 迭代更新）`
> **Owner**: `aixsilicon_vip_repo`
> **Requirement Baseline**: [`requirement.md 1.0.0-g0-baseline`](requirement.md)
> **Architecture Baseline**: [`architecture.md 0.4.0-draft`](architecture.md)
> **Validation Baseline**: [`validation-plan.md（Freeze 版）`](validation-plan.md)
> **Target VLNV**: `aixsilicon:vip:axi4:1.0.0`

> 状态口径（禁止伪报通过）：`PASS` = 有回归/检查证据；`PARTIAL` = 实现存在但证据不完整；
> `NOT_RUN` = 计划内未执行；`N/A` = 不适用；`BLOCKED` / `WAIVED` 需注明原因。

---

# 1. Purpose（必填）

本文档建立 AXI4 VIP 的 Requirement Traceability Matrix，回答：

* 每个 Requirement 如何映射到 Architecture 组件、Implementation、Checker/SVA、Test、Coverage；
* 每个 Requirement 的验证状态与证据；
* 哪些 Requirement 尚未验证（Uncovered）、已失败（Failed）、已知问题（Known Issues）、
  Waiver 与 Limitation；
* Release（G6）所需的最终 qualification 状态。

本文档是"VIP 完整性的证据"，由回归/检查产物持续更新；PASS 项必须关联真实
run 证据（`reports/logs/*.log`，VCS W-2024.09-SP1，2026-09-01，seed=1）。

# 2. RTM Principles（必填）

* 单一事实源：Requirement ↔ Architecture ↔ Implementation ↔ Validation ↔ Evidence
  五向追踪，任何不一致以 requirement.md 为准并回修；
* 证据化：每条 PASS 关联 test/日志；无证据不得标 PASS；
* 组件级粒度：PRO/RUL 逐条映射；大项（TRN/VER/CFG/API）按组件映射；
* 状态机：PASS / FAIL / NOT_RUN / BLOCKED / WAIVED / N/A；
* 迭代更新：G3 首轮 → G4 覆盖闭合 → G5 Qualification → G6 Release 逐轮刷新。

# 3. Input Artifacts（必填）

| 输入 | 版本/路径 |
| --- | --- |
| requirement.md | 1.0.0-g0-baseline |
| architecture.md | 0.4.0-draft（G1 运行时模型冻结） |
| validation-plan.md | Freeze（RUL mapping 校正版） |
| src/ | G2（VCS 编译通过，本轮修复 8 处缺陷） |
| self_test/ | 6 tier（smoke/feature/corner/negative/random/stress） |
| reports/logs/*.log | 本轮 6 test 日志（build/logs/，工作区忽略不入库） |
| reports/quality/run_log.md | S07 记录 |

# 4. Traceability Model（必填）

```text
Requirement(REQ-xxx) → Architecture(组件) → Implementation(src) 
  → Checker/SVA(验证资产) → Test(axi4-VAL / tier) → Coverage(bin)
  → Result(PASS/PARTIAL/...) → Evidence(log)
```

每个 Requirement 至少贯通到 Implementation；PASS 项贯通到 Test + Evidence；
Checker/SVA/Coverage 列标注实现所在组件与检查规则。

# 5. Requirement Status Definition（必填）

| 状态 | 定义 |
| --- | --- |
| PASS | 有本轮回归/检查日志证据 |
| PARTIAL | 实现存在，验证证据不完整（部分场景缺失） |
| NOT_RUN | 已计划但未执行（明确列入 G4/G5 gap） |
| N/A | V1.0 明确不适用（与 requirement Limitations 一致） |
| BLOCKED / WAIVED | 需注明原因与批准人 |

# 6. Requirement Priority（必填）

* P0：PRO-001~014/018/019/020/021、RUL-001~011、TRN-001~003、VER-001~013、CFG 核心、API-001~005/008；
* P1：PRO-015/016/017、RUL-012~017、VER-014（RAL，G6 blocker）、API 扩展；
* P2：STA-001、DBG 扩展；
* P3/Future：REC-001（V1.0 不实现 → N/A）。

# 7. Master RTM（必填）

汇总矩阵见 §11（Validation Result Matrix）；类别分表见 §8~§28。整体计数：
**PASS 59 / PARTIAL 17 / NOT_RUN 16 / N/A 4**（详见 §35）。

# 8. Requirement-to-Architecture Trace（必填）

| Requirement 类 | Architecture 组件（章节） |
| --- | --- |
| PRO-001~008 | master/slave agent + driver + monitor（§10~§13） |
| PRO-009~012 | 配置延迟/背压/排序模型（§7.3/§20） |
| PRO-013~016 | memory/WSTRB/exclusive（§9.1/§9.2） |
| PRO-017~021 | sideband 驱动、reset、AW/W 解耦、handshake、byte-lane（§12~§15/§29） |
| RUL-001~017 | checker（§17）+ assertions（§16） |
| TRN-001~003 | axi4_item + protocol_event（§6/§18） |
| VER-001~014 | 组件层（§6~§14/§22） |

# 9. Requirement-to-Implementation Trace（必填）

| Requirement 类 | Implementation |
| --- | --- |
| PRO-001/002 | `axi4_master_driver.receive_read_response` / `drive_write_data`；slave `drive_write_response`（本轮修复） |
| PRO-003~005 | `axi4_types_pkg.get_beat_address` + `pack/unpack_burst_*` |
| PRO-006/RUL-003 | `is_crossing_4kb`（本轮修正）+ checker |
| PRO-013/021 | memory `read_beat/write_beat` lane 语义 + `get_byte_lane_index` |
| PRO-014/RUL-014 | 同上（unaligned lane 推进） |
| PRO-015/RUL-013 | `write_beat` WSTRB 门控（zero-strobe 不更新） |
| PRO-016/RUL-016 | memory `exclusive_read/write/clear` + driver EXOKAY 判定 |
| PRO-017 | driver awcache/awprot/awqos/awregion 驱动 + monitor 重建 |
| PRO-018/RUL-009 | driver `reset_signals()` + `a_reset_valid` SVA |
| PRO-019/020 | driver AW→W 固定序（解耦形态未实现 → PARTIAL） |
| RUL-004 | sequence 约束（本轮修正）+ checker PRO-010 |
| RUL-005/017 | driver wlast/rlast 末拍 + SVA |
| RUL-007 | checker `check_transaction_rules` |
| RUL-010 | checker `check_response_rules` |
| TRN-001~003 | `axi4_item` 字段/helper/compare |
| VER-001~013 | src/ 各组件 |
| VER-014 | 未实现（NOT_RUN） |

# 10. Requirement-to-Validation Trace（必填）

| Requirement 类 | Validation（tier / VAL ID） |
| --- | --- |
| PRO-001/002 | axi4-VAL-001/002（smoke+feature） |
| PRO-003~005 | VAL-003/004/005（feature/corner） |
| PRO-006/RUL-003 | VAL-006（corner，1/1 negative 检出） |
| PRO-013/021 | VAL-007（feature narrow） |
| PRO-014 | VAL-008（corner unaligned） |
| PRO-015 | VAL-009（corner zero-strobe） |
| RUL-004（PRO-010 语义） | negative（2/2 检出） |
| PRO-012（WRAP 对齐） | negative（2/2 检出） |
| PRO-007/008/009~012 | random/stress 基线（路径未接通 → PARTIAL/NOT_RUN） |
| CFG/API | random/stress 配置使用 + API 全回归 |

# 11. Validation Result Matrix（必填）

| Tier | Test | UVM_ERROR(实际/预期) | Result | Evidence |
| --- | --- | --- | --- | --- |
| smoke | axi4_smoke_test | 0/0 | PASS | logs/axi4_smoke_test.log |
| feature | axi4_feature_test | 0/0 | PASS | logs/axi4_feature_test.log |
| corner | axi4_corner_test | 1/1（RUL-003 预期） | PASS | logs/axi4_corner_test.log |
| negative | axi4_negative_test | 4/4 | PASS | logs/axi4_negative_test.log |
| random | axi4_random_test | 0/0 | PASS | logs/axi4_random_test.log |
| stress | axi4_stress_test | 0/0 | PASS | logs/axi4_stress_test.log |

**全量 6/6 PASS（VCS W-2024.09-SP1 / UVM 1.2 / seed=1，2026-09-01）。**

# 12. Protocol Rule Trace（按Profile：C 最核心）

| Rule | Impl | Checker/SVA | Negative | Result |
| --- | --- | --- | --- | --- |
| RUL-001 | driver（本轮修 D4） | a_valid_hold SVA | 无专项 | PARTIAL |
| RUL-002 | monitor #1step | cover_handshake | directed semantic 未专项 | PARTIAL |
| RUL-003 | is_crossing_4kb | checker | corner 1/1 检出 | **PASS** |
| RUL-004 | sequence 约束 | checker PRO-010 | negative 2/2 | **PASS** |
| RUL-005 | driver 末拍 | a_wlast/rlast SVA | 无专项 | PARTIAL |
| RUL-006 | checker ID queue | — | 单 ID 未触发 | PARTIAL |
| RUL-007 | checker 拍数检查 | checker | 无专项 | PARTIAL |
| RUL-008 | monitor 重建 | — | 无专项 | NOT_RUN |
| RUL-009 | reset_signals | a_reset_valid SVA | reset 注入未做 | PARTIAL |
| RUL-010 | slave OKAY | checker | 非法编码未注入 | PARTIAL |
| RUL-011 | payload stability | a_payload_stability | 无专项 | PARTIAL |
| RUL-012 | memory lane | — | narrow 正向已验 | PARTIAL |
| RUL-013 | write_beat WSTRB | — | 越界未注入 | PARTIAL |
| RUL-014 | get_byte_lane | — | unaligned 正向已验 | PARTIAL |
| RUL-015 | 无 WID FIFO | — | 无专项 | PARTIAL |
| RUL-016 | memory exclusive | — | 无专项 | PARTIAL |
| RUL-017 | monitor 闭合 | SVA | 缩短未注入 | PARTIAL |

# 13. Checker Trace（按Profile：C 最核心）

| Checker 能力 | Evidence | Result |
| --- | --- | --- |
| request 流（PRO-010/PRO-012/RUL-003） | negative 4/4 + corner 1/1 | PASS |
| response 流（RUL-010/EXOKAY） | smoke 无误报 | PASS（负向未注入） |
| monitor 流（RUL-007 拍数） | 全回归无误报 | PASS（负向未注入） |
| violation 输出（rule/severity/channel/context） | negative 日志结构化输出 | PASS |
| ordering queue | 实例化 | PARTIAL |

# 14. Assertion Trace（按Profile）

| SVA | Rule | Case | Result |
| --- | --- | --- | --- |
| a_valid_hold | RUL-001 | pass（smoke） | PASS（fail case 未做） |
| a_wlast_handshake / a_rlast_handshake | RUL-005 | pass | PASS（fail 未做） |
| a_reset_valid | RUL-009 | pass/reset | PASS（fail 未做） |
| a_payload_stability | RUL-011 | pass | PASS（fail 未做） |
| cover_handshake_*（5 通道） | RUL-002 | cover 输出 | PASS |
| burst 终止（RUL-017） | 未实现 | — | NOT_RUN |

# 15. Coverage Trace（按Profile）

| Coverage 层 | 组件 | Evidence | Result |
| --- | --- | --- | --- |
| Requirement/Feature | axi4_coverage | 组件实例化 + transaction_ap 采样 | PARTIAL |
| Field | 同上 | 未系统闭合 | PARTIAL |
| Cross | 同上 | 未系统闭合 | NOT_RUN（G4 gap） |
| Temporal/Event | protocol_event_ap | 独立验证未做（§13.6） | NOT_RUN |

# 16. Feature Coverage Matrix（按Profile）

| Feature | Coverpoint 状态 |
| --- | --- |
| burst_type/len/size、ID、WSTRB 形态、4KB | covergroup 已存在，bins 未闭合（G4） |

# 17. Protocol Rule Coverage（按Profile）

RUL-001~017 的 rule_cov bins 未系统性闭合 → NOT_RUN（G4 gap）。

# 18. Mutation Trace（按Profile：C 必填）

| Mutation | Expected | Detected | Result |
| --- | --- | --- | --- |
| RUL-003 跨 4KB（corner） | 1 | 1 | PASS |
| PRO-010 WRAP len=3 | 1 | 1 | PASS |
| PRO-010 FIXED len=20 | 1 | 1 | PASS |
| PRO-012 WRAP 未对齐（len3） | 1 | 1 | PASS |
| PRO-012 WRAP 未对齐（addr） | 1 | 1 | PASS |
| 合法读对照 | 0 | 0（无误报） | PASS |

# 19. Mutation Summary（按Profile：C 必填）

**注入 5 组，检出 5/5 = 100%；合法对照 0 误报。**
剩余 12 条 RUL mutation NOT_RUN（G5 gap）。§19 指标（总体 ≥95%、P0 100%）在已注入子集达成，
全集未闭合——不得宣称达标。

# 20. Configuration Trace（按Profile）

| 配置组 | Evidence | Result |
| --- | --- | --- |
| protocol/width（CFG-001~005） | 全回归随机化 | PASS |
| suite 开关（checker/coverage/injection） | corner/negative 生效 | PASS |
| ordering/interleave/weights | 默认展开 | PARTIAL |
| 延迟/背压组（CFG-014~023） | 未消费 | NOT_RUN |

# 21. Public API Trace（按Profile）

| API | Evidence | Result |
| --- | --- | --- |
| configure/connect（uvm_config_db） | smoke tb | PASS |
| start（sequences） | 6 tier | PASS |
| observe（transaction_ap） | coverage 采样 | PASS |
| violation（violation_ap） | negative | PASS |
| extension（factory override/callback） | 未验证 | NOT_RUN |

# 22. Agent Mode Trace（按协议：仅含多模式/Agent 的 VIP）

| Mode | Evidence | Result |
| --- | --- | --- |
| ACTIVE_MASTER | 全回归 | PASS |
| ACTIVE_SLAVE | 全回归 | PASS |
| PASSIVE | 未跑专项 | NOT_RUN |

# 23. Reset Trace（按Profile）

| 场景 | Evidence | Result |
| --- | --- | --- |
| 复位期间 VALID=0（SVA） | smoke（cover_reset_seen=3） | PASS |
| 复位中 traffic / outstanding 清理 | 未做专项 | NOT_RUN |

# 24. Timeout / Deadlock Trace（按协议：仅含等待语义的协议）

timeout 为 VIP 运行时能力（Environment/Runtime violation，非 AXI 协议概念）：
默认 disable；路径在本轮 D3 修复中重写并经全回归（未启超时形态）。专项 timeout 测试
NOT_RUN。死锁：stress 300 事务无 deadlock → PASS。

# 25. Target / Behavior Model Trace（按协议：仅含 Target 的协议；M 核心）

| 组件 | Evidence | Result |
| --- | --- | --- |
| axi4_memory（WSTRB/exclusive/read/write） | feature/corner 回环 | PASS |
| response policy（延迟/排序/权重） | 未接通 | NOT_RUN |
| slave data monitor | 实例化 | PARTIAL |

# 26. RAL Trace（按协议：仅寄存器类总线；其余 N/A）

REQ-VER-014（P1 Required，V1.0 Target）：**NOT_RUN（G6 Release blocker）**；
若确定 V1.0 不实现，requirement 须先降级 P2 再标 N/A（validation-plan §31 口径）。

# 27. Debug Capability Trace（按Profile）

| 能力 | Evidence | Result |
| --- | --- | --- |
| violation rule_id 关联 REQ | negative 日志 | PASS |
| transaction convert2string | 全回归日志 | PASS |
| timeout context | 未启用形态 | PARTIAL |

# 28. Statistics Trace（可选：非 P0/P1 可省略）

STA-001（P2/Optional）：NOT_RUN。

# 29. Build / Simulator Trace（必填）

| 项 | Evidence | Result |
| --- | --- | --- |
| VCS compile（-full64 UVM1.2） | 全回归前编译 0 error | PASS |
| filelist/Makefile | self_test/6 tier | PASS |
| FuseSoC core | 未生成 | NOT_RUN（G5 gap） |

# 30. Metadata Trace（必填）

`metadata/vip.yaml` 未建 → NOT_RUN（G5 gap）；gen-core 时须保证声明与实现一致
（§41 Metadata Validation）。

# 31. Documentation Trace（必填）

| 文档 | 状态 |
| --- | --- |
| requirement.md | G0 PASS（1.0.0-g0-baseline） |
| architecture.md | G1（0.4.0-draft） |
| validation-plan.md | Freeze（本轮修正） |
| rtm.md | 本文档（G3 首轮） |
| user-guide.md | Draft 首版 |

# 32. Regression Summary（按Profile）

6 tier 全 PASS（§11）；`make -C self_test full` 一键回归。

# 33. Simulator Summary（按Profile）

VCS W-2024.09-SP1（Required）PASS；Xcelium/Questa 未验证（V1.0 Not-required/Optional）。

# 34. Coverage Summary（按Profile）

四层覆盖模型实例化但未闭合 → G4 gap；Requirement Exercise（P0）经 6 tier 有证据但
bin-level 阈值未评估。

# 35. Requirement Closure Summary（必填）

| 类别 | 总数 | PASS | PARTIAL | NOT_RUN | N/A |
| --- | ---: | ---: | ---: | ---: | ---: |
| PRO | 21 | 13 | 5 | 3 | 0 |
| RUL | 17 | 2 | 13 | 2 | 0 |
| TRN | 3 | 2 | 1 | 0 | 0 |
| VER | 14 | 12 | 0 | 1 | 1 |
| CFG | 20 | 8 | 4 | 8 | 0 |
| API | 12 | 5 | 2 | 5 | 0 |
| ENG | 4 | 4 | 0 | 0 | 0 |
| DBG | 4 | 3 | 1 | 0 | 0 |
| STA | 1 | 0 | 0 | 1 | 0 |
| REC | 1 | 0 | 0 | 0 | 1 |
| DEL/QLF | 6 | 2 | 2 | 2 | 0 |
| **合计** | 93 | 59 | 17 | 16 | 1 |

（计数以逐条映射的最新评审为准；更新时保持本表与分表一致。）

# 36. Uncovered Requirement（必填）

* 12 条 RUL 专项负向（RUL-001/002/005/006/007/008/010/011~017 mutation）；
* PRO-009/010/012（背压/延迟/交织）、PRO-019/020（AW/W 解耦、握手形态）；
* RUL-016 exclusive 定向、RUL-013 WSTRB 越界、RUL-017 burst 缩短注入；
* protocol_event 独立验证（§13.6）、coverage 闭合（G4）、RAL（VER-014）。

# 37. Failed Validation（必填）

本轮无未修复 FAIL。调试期间曾出现并已闭环的失败（D1~D8，见 run_log S07）：
feature 8 错（D2/D3）、corner 3 错（D5/D8）、random 45（D6）、stress 165（D6/D7）——
全部修复并回归 PASS。

# 38. Known Issues（必填）

* K1：PRO-019/020 driver 仅固定 AW→W 顺序（解耦/握手形态未实现）；
* K2：延迟/背压配置未接通（PRO-009/010）；
* K3：`awatop` 仅保留钳位（非 AXI4 capability，符合 requirement 边界）。

# 39. Waiver（必填）

暂无 WAIVED 项。G4/G5 gap 未走 waiver，按 NOT_RUN 如实记录。

# 40. Limitation Trace（必填）

与 requirement §23 一致：AXI-Stream/ACE/CHI、AXI5 ATOP、AXI3 locked/WID-interleave
不支持（N/A）；RAL V1.0 目标实现但未验证（G6 blocker）；第三方仿真器未验证。

# 41. Evidence Index（必填）

| Evidence | 位置 |
| --- | --- |
| 回归日志（6 test） | `self_test/build/logs/*.log`（工作区忽略，不入库；run_log 摘要为准） |
| run manifest | `reports/quality/run_log.md`（S07） |
| 环境指纹 | VCS W-2024.09-SP1_Full64 / UVM-1.2.Synopsys / seed=1 / 2026-09-01 |

# 42. Recommended Evidence Structure（必填）

```text
reports/
├── regression/     # 6 tier 结果汇总
├── logs/           # simv 运行日志
├── coverage/       # G4 产物
├── mutation/       # 注入/检测对照
├── simulator/      # 仿真器版本/设置
└── quality/run_log.md
```

# 43. Release Readiness（必填）

| Gate | 状态 | 结论 |
| --- | --- | --- |
| G0/G1/G2 | PASS | 历史冻结 + 编译通过 |
| G3 | PARTIAL→主体 PASS | 6/6 回归；专项 gap 见 §36 |
| G4 | NOT_RUN | 覆盖闭合未开始 |
| G5 | NOT_RUN | qualification 未开始 |
| G6 | NOT_RUN | RAL/doc/FuseSoC/metadata 未齐 |

**结论：尚不具备 Release（G6）条件。**

# 44. Final Qualification Statement（必填）

当前状态：**Developing（G3 主体完成）**。6 tier 回归 6/6 PASS、mutation 已注入子集
5/5=100%；G3 gap（§36）与 G4/G5 未启动。**不得声明 Qualified/Released。**

# 45. Sign-Off（必填）

| 角色 | 状态 | 说明 |
| --- | --- | --- |
| VIP owner | 未签 | 待 G4/G5 后 |
| Reviewer | 未签 | 待 RTM 评审 |

# 46. RTM Review Checklist（必填）

* [x] Requirement ↔ Impl 映射完整（§9）
* [x] 每条 PASS 关联证据（§11）
* [x] 未验证项如实 NOT_RUN（§36）
* [x] Mutation 对照（§18/19）
* [ ] G4 覆盖闭合后刷新
* [ ] G5 qualification 后刷新

# 47. Definition of RTM Complete（必填）

当以下条件满足时 RTM 完成一轮：全部 Requirement 有状态、PASS 有证据、FAIL 闭环或
WAIVED、Release Readiness 明确。本轮达成"G3 首轮"定义；G4/G5/G6 各刷新一次。
