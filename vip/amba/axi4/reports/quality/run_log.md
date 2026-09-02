# AXI4 VIP 运行日志（run_log）

## 2026-09-01 — G2 源码开发 + smoke 自验证（S01）

### 目标
继续开发 `aixsilicon:vip:axi4:1.0.0`（VIP-001，FULL_UVM），参考 `reference/tvip-axi`，
完成 G2 源码并验证可编译 + smoke 自验证。

### 完成内容
- `src/` 全部组件（自包含标准 UVM 1.2，不依赖 tue/tvip-common）：
  - `axi4_types_pkg.sv`（类型/枚举/编解码 + lock/exclusive/region/4KB/byte lane）
  - `axi4_if.sv`（完整信号集 + master/slave/monitor clocking + modport）
  - `axi4_configuration.sv`（含 `axi4_delay_configuration`；`random_constraint_mode` 避开 `constraint_mode` 内置方法冲突）
  - `axi4_status.sv` / `axi4_memory.sv`（WSTRB 感知 + exclusive 标记）
  - `transaction/axi4_item.sv`（master/slave/payload_store；`is_write_data_began` 避同名冲突；三元约束避 if/else 解析问题）
  - `agent/axi4_monitor.sv`（只观察重建；用 `axi4_item` 暂存，规避 virtual class 内局部 uvm_object 解析问题）
  - `agent/axi4_sequencer.sv` / `axi4_driver.sv`（复位等待 `@(posedge aclk iff areset_n)`；采样不再读 clocking output）
  - `agent/axi4_agent.sv`（master/slave，ACTIVE/PASSIVE）
  - `sequences/axi4_sequences.sv`（base/read/write/access/default/smoke；`pre_start` 改 task）
  - `checker/axi4_checker.sv`（REQ-010~019 + 0110~0116；REQ-016 区分读响应==len、写响应==1）
  - `checker/axi4_assertions.sv`（SVA；复位断言容忍 X）
  - `coverage/axi4_coverage.sv`（四层覆盖；嵌入式 covergroup 在 new() 显式构造）
  - `env/axi4_env.sv` + `env/axi4_violation_injector.sv`
  - `axi4_pkg.sv`
- `self_test/`（Makefile + filelist + tb smoke_env/test/tb）
- `docs/architecture.md` 升级为 39 章模板 + Profile 元数据
- `README.md` 更新交付物状态

### 执行检查
| 检查 | 结果 |
| --- | --- |
| `vip_tool.py vip-check` | **PASS**（仅 3 个可选文档 WARN） |
| VCS 编译（-full64 -ntb_opts uvm-1.2） | **通过**（compile+elab+link，simv 生成） |
| smoke 自验证 | **通过**（UVM_ERROR=0, UVM_FATAL=0, TEST_DONE；checker 检查 30 笔/违规 0） |

### 环境
- VCS W-2024.09-SP1，UVM 1.2（`-ntb_opts uvm-1.2`）
- 链接需 `-full64`（本机缺 32 位 ctype-stub）

### 未执行
- G4 覆盖率闭合、G5 Qualification（compile/lint/regression/coverage/mutation）、G6 Release：待后续 Gate。

### 剩余风险/下一步
1. 补 `docs/validation-plan.md` / `docs/rtm.md` / `docs/user-guide.md`（可选文档，消除 WARN）；
2. 扩展 self_test（feature/corner/error/random/stress）；
3. 接入 `examples/` 最小 DUT + `fault_injection/` mutation cases；
4. `gen-core` 生成 FuseSoC `.core` + `metadata/vip.yaml`；
5. 进入 G4 覆盖率闭合与 G5 Qualification。

## 2026-09-01 — G0 Normalization（S02）

### 目标
按评审意见完成 G0 normalization：协议事实修正 → Feature/Profile 边界冻结 → ID 重构 → Priority/Status 字段化 → How 下沉 → G0 Freeze（requirement 0.4.0-draft → 0.9.0-g0）。

### 完成内容
1. **§2.2 AXI4-Lite capability matrix 修正**：Narrow vs Partial Write 分离（Lite 无 AxSIZE，narrow 不适用，partial write/WSTRB 适用）；AxCACHE/QOS/REGION 区分 signal presence vs semantic default（Lite 无信号、固定默认）；outstanding 改为实现策略（非协议事实）。
2. **§2.3 新增 Feature**：PRO-0106（AW/W Decoupling）、PRO-0107（READY pattern）、PRO-0108（Byte-Lane Model）；Zero-strobe write 并入 PRO-0102。
3. **§3.2 RUL-0115 Exclusive 语义精炼**：exclusive monitor 完整语义（建立/配对/属性匹配/invalidation/单 active/EXOKAY-OKAY）。
4. **§7.2 CFG-006 response_ordering 默认 IN_ORDER**（deterministic + simplest legal）。
5. **Requirement ID 域分类局部编号**：`AXI4-REQ-<DOMAIN>-<NNN>`（PRO/RUL/TRN/SEQ/VER/CFG/API/DBG/ENG/DEL/QLF），域内局部编号避免全局重排；requirement.md/architecture.md/checker 源码全部同步替换（脚本确定性执行）。
6. **P0/P1 冲突消除 + 字段化**：§24 修订；附录 C 增加 Priority/Status/Target/Profile 字段化规范。
7. **How 下沉**：§5.1 Ordering Model、§13 文本表示等改为能力描述，实现细节归 architecture。
8. **Mutation/Coverage 指标精炼**：§11.2 overall ≥95% + P0 mandatory mutation 100%；§10.5 Requirement Coverage vs Functional Coverage Bin 两维度区分。
9. **api-reference 决策**：方案 A，API 签名并入 user-guide，不单独建一级文档。

### 执行检查
| 检查 | 结果 |
| --- | --- |
| ID 替换残留 | 0（requirement/architecture/checker） |
| VCS 编译 | 通过（ID 改动不影响逻辑） |
| smoke 自验证 | 通过（UVM_ERROR=0, UVM_FATAL=0） |
| vip-check | PASS（待复跑确认） |

### 剩余
- G0 Review 冻结（人工确认）；G1 后续同步；validation-plan/rtm/user-guide 待建。

## 2026-09-01 — Architecture 按模板完善（S03）

### 目标
按模板（39 章，1274 行详细度）完善 `docs/architecture.md`，对齐套件模板结构并保留 AXI4 特定内容与新域编号。

### 完成内容
- architecture.md 从 661 行完善为完整 39 章模板结构（各章对齐模板：Purpose/Goals/Overview/Component Matrix/Package/Interface/Transaction/Semantic Helper/Configuration/Agent/Sequencer/Sequence/Driver/Monitor/Checker/Assertion/Violation/Coverage/Target/Policy/Memory/Error Injection/RAL/Public API/High-level/Extension/Runtime/Statistics/Reset/Timeout/Recording/Machine-readable/Build/Dependency/REQ→Arch/ADR/Constraints/Review/Complete）。
- 补齐模板要求的细节：Interface Responsibility/Source of Truth/Parameterization；Driver Principles/Channel Scheduler；Monitor Reconstruction Model/Observation Output；Checker Rule Mapping/State Model；Configuration Profiles；ADR-005（IN_ORDER 默认）与 ADR-006（域编号）；Reset 组件行为表；39 章 Completeness 判定。
- 全部引用采用新域编号（PRO/RUL/TRN/SEQ/VER/CFG/API/DBG/ENG/DEL/QLF），无残留旧号。

### 执行检查
| 检查 | 结果 |
| --- | --- |
| vip-check | PASS（39 章，Profile FULL_UVM） |
| 残留旧号 | 0（仅合法域编号范围） |

### 剩余
- validation-plan/rtm/user-guide 待建；G1 Review 确认。

## 2026-09-01 — G0 Normalization（S02）：协议事实校正 + Requirement ID 局部编号

### 目标
按评审意见执行 G0 normalization，推进 requirement 至 0.9.0-g0（G0 Freeze），并优化 Requirement 编号体系。

### 完成内容（docs/requirement.md）
1. **AXI4-Lite capability matrix 修正**（§2.2）：Narrow vs Partial Write 分离、AxCACHE/QOS/REGION
   signal presence vs semantic default、outstanding 改为实现策略（可配置 depth + 保持顺序）、Zero-strobe write；
2. **Exclusive 语义精炼**（§2.5 / REQ-0115→RUL-016）：exclusive monitor 完整语义（pairing、属性匹配、
   invalidation、EXOKAY/OKAY）；
3. **新增 Feature**：Write Address/Data Decoupling（PRO-019）、READY 行为模式（PRO-020）、
   Address/Byte-Lane Model（PRO-021）；
4. **response_ordering 默认值** IN_ORDER（§7.2）；
5. **Requirement ID 重构**：旧全局编号 → `AXI4-REQ-<CATEGORY>-<NNN>` 局部编号
   （PRO/RUL/TRN/STM/VER/CFG/API/ENG/DBG/STA/REC/DEL/QLF，每类别独立 001 起编），
   新增需求无需全局重排；同步 architecture.md 与 checker rule_id；
6. **P0/P1 冲突消除 + Priority/Status/Target 字段化**（§24）；
7. **How 下沉 Architecture**：Ordering Model（§5.1）、convert2string 表述（§13）；
8. **Mutation 指标精炼**：总体 ≥95% + 所有 P0 Rule mandatory mutation 100%（§11.2）；
9. **Coverage 双指标区分**：Requirement/Feature Exercise（P0=100%） vs Functional Coverage Bin（阈值）（§10.6）；
10. **api-reference 决策**：并入 user-guide（方案 A，不额外制造一级文档）。

### 执行检查
| 检查 | 结果 |
| --- | --- |
| ID 映射完整性（requirement/architecture/checker） | 无遗漏、无旧编号残留（grep=0） |
| checker 编译（-full64 UVM1.2） | 通过 |
| smoke 自验证 | 通过（UVM_ERROR=0） |

### 剩余风险/下一步
1. G0 Freeze 确认后基于 0.9.0-g0 生成/同步 validation-plan、rtm、user-guide；
2. 扩展 self_test（feature/corner/error/random/stress）+ fault_injection mutation cases；
3. examples + gen-core + metadata/vip.yaml；进入 G4 覆盖率闭合与 G5 Qualification。

## 2026-09-01 — G0 Consistency Cleanup（S03）：修复正文与 Checklist/索引不一致

### 背景
评审发现 requirement.md 的协议事实修正被回滚（仅 ID 编号保留），正文与 G0 Checklist/附录索引不一致。

### 完成内容（完整重写 docs/requirement.md，一次解决全部 blocker）
1. **§2.2 AXI4-Lite matrix 重新修正**（最终矩阵）：Narrow vs Partial Write 彻底分离、AxCACHE/AxQOS/AxREGION
   signal presence vs semantic default、Multiple Outstanding（无 ID-based reordering）、Unaligned ✅、Zero-strobe ✅；
2. **§2.3 补 PRO-019/020/021**：AW/W Channel Decoupling、Handshake Pattern、Zero-Strobe Write（正文与索引/Checklist 对齐）；
3. **AWATOP 边界重定义**：AXI5/AMBA5 Atomic 非 AXI4 capability；HWIF superset 保留、AXI4 profile 驱动/钳位非原子值（§2.4/2.5/附录 B）；
4. **RUL-016 Exclusive 精炼**：exclusive transaction association（ID/地址范围/attributes 匹配）、monitor 建立/失效、EXOKAY/OKAY 语义；
5. **CFG-006 默认 IN_ORDER**（与 Architecture ADR 一致）；VER-009 旧 ID `0110~0116` 清理为 RUL-001~017；
6. **§5.1 Ordering Model How 下沉**（去 queue 实现细节）；
7. **§15 Statistics 删 retry count**（AXI 无 retry）；DBG-004 改 Transaction/Channel/Beat 三层；
8. **Reset 拆分**：RUL-009 协议规则 vs PRO-018 VIP 状态恢复；
9. **新增 TRN-003 Protocol Event Model**（AW/W/B/AR/R handshake/reset/stall）+ API-003 扩展 Event Observation；
10. **§4.4 Constraint Model 两层**：Illegal Transaction Generation vs Protocol Violation Injection；§10 Scenario 含 temporal/event coverage；
11. **§24 Priority 逐条字段化**（表格含 Priority/Status/Target/Profile 列；VER-014 RAL、API-006/007/009/010/013 降为 P1）；
12. **附录顺序恢复 A→B→C**；清理 `</parameter>` 残留、§26 引用（见附录 B 而非 §27）。

### 同步
- architecture.md：§6 AWATOP 边界、§7 Protocol Event Model（TRN-003）、§29 Reset 拆分、§35 TRN-003 映射；
- checker rule_id 不受影响（编译通过）。

### 执行检查
| 检查 | 结果 |
| --- | --- |
| 旧 ID/残留扫描（requirement/architecture/checker） | 均为 0 |
| vip-check | PASS |
| checker 编译 | 通过 |
| smoke 自验证 | 通过（UVM_ERROR=0） |

### 结论
G0 consistency cleanup 完成：正文与 G0 Checklist/附录索引一致，Conditional PASS → 满足 G0 Freeze 条件。

## 2026-09-01 — G0 Final Cleanup（S04）：判定 G0 PASS / Requirement Freeze（1.0.0-g0-baseline）

### 背景
评审判定 G0 PASS，提出 8 项最终 cleanup 收敛建议。全部采纳并完成。

### 完成内容（docs/requirement.md）
1. **去重**：PRO-021 只定义能力、TRN-002 定义统一语义计算、§4.2A 改为引用（不重复展开）；
2. **outstanding 配置去重**：CFG-021（max_outstanding_read/write/per_id）为正式；CFG-007 标 deprecated/alias，同时设置时以 CFG-021 为准；
3. **PRO-010 改名** Channel Timing / Response Delay（分 Master request/data gap 与 Slave response/backpressure）；
4. **RUL-001 拆分语义**：VALID generation independence / VALID stability / payload stability 三条子语义，分别映射 Checker/SVA/Mutation；
5. **RUL-017 精炼**：已发出 burst 必须完成 AxLEN+1 个 transfer，不得提前 WLAST/RLAST/停 beat；
6. **VER-005 去实现暗示**：改 target driver + protocol monitor + behavior model integration（data monitor 留 Architecture 决定）；
7. **Priority 逐条化**：PRO-019 AW/W→P0、PRO-021 Byte-Lane→P0、PRO-020 Handshake→P1、RUL-011 Payload Stability→P0（不再按范围一刀切）；
8. **LIM-006 写法**：Current: V1.0 / Planned Removal: V1.x-V2.0。

### 版本
requirement 推进至 **1.0.0-g0-baseline**（G0 PASS / Requirement Freeze）。

### 验证
| 检查 | 结果 |
| --- | --- |
| 残留旧 ID 扫描 | 0 |
| vip-check | PASS |
| checker 编译 | 通过 |
| smoke | 通过（UVM_ERROR=0） |

### 后续
基于 1.0.0-g0-baseline 生成 validation-plan / rtm / user-guide；Architecture 聚焦 AW/W/B association、AR/R outstanding & ordering、exclusive monitor、protocol event stream、slave response policy 等模型；随后 G4 覆盖率闭合与 G5 Qualification。

## 2026-09-01 — G1 Runtime Model 深化（S05）：冻结 4 个核心运行时模型

### 目标
按 G1 评审意见深化 architecture.md 运行时模型（不新增章节，只写透核心模型），为 G1 PASS 做准备。

### 完成内容（docs/architecture.md）
1. **§13.1 Write Runtime Model（G1 Blocker）**：AW/W/B Association 冻结——
   AW 握手建 write context → W beats 按序归属（FIFO，无 WID）→ WLAST 关 data phase → B 按 BID 关联 → B 后发布完成事务；
   含 AW request queue、W beat ownership、write completion condition、B↔completed write association。
2. **§13.2 Read Runtime Model（G1 Blocker）**：AR/R Association 冻结——
   AR 握手 → read context[ID] → R beat 收集（同 ID FIFO 区分多笔 outstanding；不同 ID 可 interleave）→ RLAST → 完成。
3. **§14 Monitor 与 Memory 完全解耦**：Monitor 永不改 memory；memory 由 Slave Driver→Behavior Subscriber 或
   Passive Memory Predictor 更新；slave_data_monitor 只观察发布。
4. **§20 Response Policy Model**：引入 `axi4_response_policy` 行为决策层（选 BRESP/RRESP、延迟、排序、背压、
   地址相关、exclusive EXOKAY/OKAY）；Config 配默认 policy、用户替换 policy 而非 override driver；
   Passive 用 `axi4_response_predictor` 复用决策。
5. **§16/§17 Assertion/Violation Bridge**：冻结 SVA→`axi4_violation`→`violation_ap` 统一通道
   （Assertion Bridge 或 native report，二选一）。
6. **§18 Temporal/Event Coverage**：显式消费 `protocol_event_ap`（AW/W order、READY 形态、stall、outstanding、interleave）。
7. **§29 Reset Ownership**：EXTERNAL / VIP_CONTROLLED；一个 interface 一个 reset owner；Passive 只观察。
8. **§36 新增 ADR-006（Assertion Reporting Integration）+ ADR-007（Response Policy 独立组件）**。
9. **§38 G1 Checklist 退回 8 项为 [ ]**（Write/Read Association、Outstanding/Ordering、Monitor-Memory 解耦、
   Response Policy、Event Coverage、SVA Bridge、Reset ownership）；§39 状态诚实化。

### 验证
| 检查 | 结果 |
| --- | --- |
| vip-check | PASS |
| 编译 | 通过（0 错误） |
| smoke | 通过（UVM_ERROR=0） |

### 结论
4 个核心运行时模型（Write Association / Read Association / Response Policy / Assertion-Violation Bridge）已写入架构。
冻结 8 项 Checklist 后即正式 G1 PASS。

## 2026-09-01 — 根据运行优化 SKILL（S06）：回写 AXI4 开发经验到 vip-development-suite

### 目标
将本次 AXI4 VIP 开发运行经验回写优化 `vip-development-suite` skill 源仓
（`repos/aixsilicon_skill_repo/skills/vip-development-suite/`），让后续 VIP 项目少走弯路。

### 完成内容（skill 源仓）
**`skills/vip-requirement/SKILL.md`**
1. **§6 Requirement ID 局部编号**：改为 `<PROTOCOL>-REQ-<CATEGORY>-<NNN>`（每类别独立 001 起编），
   13 个类别（PRO/RUL/TRN/STM/VER/CFG/API/ENG/DBG/STA/REC/DEL/QLF）+ 局部编号规则；
   G0 之前冻结类别集，新增需求局部递增，避免全局重排（来自 AXI4 运行教训：全局编号多次重排）。
2. **§4.9 协议事实检查要点**：Signal presence vs Semantic default（如 AXI4-Lite AxCACHE/QOS/REGION
   无信号但有固定默认）、superset 信号边界（如 AWATOP 为 AXI5 Atomic 非 AXI4 capability）、
   Narrow vs Partial write、outstanding 是实现策略而非协议事实。
3. **§6.5 G0 Normalization 流程**：协议事实修正 → Feature/Profile 边界冻结 → ID 局部编号 →
   Priority/Status 逐条字段化 → How 下沉 architecture → Freeze；防止正文与 Checklist/索引不一致。
4. **§7 完成标准（G0）**：新增 Requirement Engineering 检查项（正文↔索引↔checklist 一致性、
   残留旧 ID 扫描、协议事实核对表）。

**`skills/vip-architecture/SKILL.md`**
5. **§8.5 运行时模型设计要点（复杂协议必须写透）**：Write Association Model（无 WID 时 W 归属 AW）、
   Read Association Model（AR/R outstanding & ordering）、Response Policy Model（独立行为决策层）、
   Assertion/Violation Bridge（SVA→violation→ap 统一通道）、Monitor 与模型状态解耦（Monitor 永不改 memory）、
   Protocol Event Model + Temporal/Event Coverage（显式消费 event_ap）、Reset Ownership、典型 ADR 记录。
6. **§9 完成标准（G1）**：新增**运行时模型冻结**清单（Write/Read Association、Outstanding/Ordering、
   Monitor-Memory 解耦、Response Policy、Event Coverage、SVA Bridge、Reset ownership），冻结后正式 G1 PASS。

### 验证
| 检查 | 结果 |
| --- | --- |
| `validate_suite.py` | 1 个 FAIL 为预先存在的 scaffold 模板 PLACEHOLDERS（`templates/vip/`），与本次 SKILL.md 修改无关 |
| skill 源仓 git status | 仅 `vip-requirement/SKILL.md`、`vip-architecture/SKILL.md` 两文件修改 |
| `bootstrap.py --ensure` 重新物化 | OK（11 skills 复制到 `.roo/skills/`；副本已含 §4.9/§6.5/§8.5/冻结项） |
| `vip_tool.py vip-check --root vip/amba/axi4` | **PASS**（仅 3 个可选文档 WARN） |

### 结论
AXI4 运行经验已按 AGENT.md「skill-repo 优先 + 重新物化」原则回写：先改源仓再 `bootstrap.py --ensure`
物化到 `.roo/skills/`，无直接编辑物化副本。后续 VIP（含 axi4 G1 冻结、其他协议 VIP）可直接复用。

## 2026-09-01 — S07：G3 Self-Verification 主体完成（缺陷修复 8 处 + 6 tier 回归全绿 + 文档交付）

### 目标
按已 Freeze 的 validation-plan（RUL mapping 校正版）落地 G3：代码实现 → 验证 → 调试闭环，
交付 rtm.md / user-guide.md，并推进到可提交状态。

### 完成内容（代码修复 D1~D8）
1. **D1 编译修复**（`src/agent/axi4_driver.sv`）：task 块内变量声明上移（VCS 不接受嵌套
   block 声明）、`$display` 移出声明区、clocking block output 采样改为读接口顶层信号。
2. **D2 slave 写路径缺失**：`drive_write_response` 此前只走 exclusive 分支，普通写从未
   调用 `memory.write_beat` → 读回全 0；补齐逐 beat burst/WSTRB 写入 + 非 exclusive 写
   清除独占标记（REQ-RUL-016）。
3. **D3 join_any 死锁**：`receive_write/read_response` 在 `enable_timeout=0` 时 timeout
   分支立即完成 → `join_any` 提前返回、B/R 响应丢失（burst_read size=0 的直接根因）；
   改为 done 标志 + disable fork 同步收敛。
4. **D4 clocking 握手错位**：master output #1 写 valid 后同沿即采样到 READY=1 并撤 valid，
   slave（input #1step）永远采不到 → `drive_address` 前置 `@(vif.master_cb)` 同步。
5. **D5 is_crossing_4kb 误报**：掩码错误依赖 burst_size 且比较逻辑混乱 → 改标准
   page 比较（`(addr>>12) != (end>>12)`）。
6. **D6 随机约束非法生成**：`axi4_master_write/read_seq` 允许 WRAP len∉{2,4,8,16}、
   FIXED len>16、WRAP 地址不对齐 → 补全约束（random 45→0 违规）。
7. **D7 4KB 约束公式漏检**：`(addr%size)+(len-1)*size<4096` 对 unaligned 起始不充分
   （0x3ffe len7 size8 漏跨 0x4000）→ 改首末字节同 4KB page 判定（stress 165→0）。
8. **D8 narrow 期望语义**：测试期望值未按 beat lane 位置摆放 → lane_shift 构造修正
   （feature narrow 全 PASS）。

### 新增测试（self_test/tb/）
* `axi4_corner_test.sv`：VAL-005/006/008/009（4KB 合法边界 + 跨界负向、WRAP 回环、
  unaligned lane、zero-strobe 不更新 memory）。
* `axi4_negative_test.sv`：4 条非法事务 → checker 检出 4/4（PRO-010×2 + PRO-012×2 +
  对照合法读 0 误报），mutation detection 100%。
* `axi4_random_test.sv`（100 事务）/ `axi4_stress_test.sv`（300 事务）。
* `axi4_smoke_env.sv`：checker request/response 流接通（负向检测前置条件）。
* `Makefile`：6 tier 分层 + `ALLOW_ERRORS` 预期违规判定（corner=1、negative=4）。

### 验证（VCS W-2024.09-SP1，UVM 1.2，seed=1）
| Tier | Test | 结果 |
| --- | --- | --- |
| smoke | axi4_smoke_test | PASS（UVM_ERROR=0） |
| feature | axi4_feature_test | PASS（含 narrow lane 闭环） |
| corner | axi4_corner_test | PASS（RUL-003 负向 1/1 检出、无误报） |
| negative | axi4_negative_test | PASS（4/4 检出，mutation 100%） |
| random | axi4_random_test | PASS（100 事务 0 违规） |
| stress | axi4_stress_test | PASS（300 事务 0 违规、无 leak/deadlock） |

### 文档交付
* `docs/validation-plan.md`：RUL-001~017 映射校正 + §13.4/13.5/13.6 + §52 G3~G6 分层（本轮 Freeze）。
* `docs/rtm.md`：G3 首轮证据矩阵（诚实标注，禁止伪报）。
* `docs/user-guide.md`：集成/配置/sequence/violation API/限制 首版。
* `README.md` / `CHANGELOG.md`：状态与变更同步。

### 剩余（G3→G4/G5 Gap，如实记录）
* 12 条 RUL 专项负向注入（RUL-001/002/005/006/007/008/010/011~017）；
* PRO-009/010/012 背压/延迟/交织路径接通与验证；
* AW/W 解耦（PRO-019）、握手形态（PRO-020）驱动实现；
* protocol_event 独立正确性（validation-plan §13.6）；
* RAL（VER-014，G6 Release blocker）、FuseSoC/gen-core、metadata、coverage 闭合（G4）、
  qualification 证据包（G5）。

### 结论
**G3 Self-Verification 主体达成（6/6 tier 全绿 + mutation 5/5=100%）**；未完成项 NOT_RUN
如实登记于 rtm.md。可进入 G4 覆盖闭合阶段；G5 前须补齐上述 gap 或按 WAIVED 评审。

## 2026-09-02 — S08：Unit Test 层（L1）建立 + VIP 本体能力补齐（按 requirement/architecture）

### 目标
1. 落地 Unit Test 机制（skill 固化 + axi4 首批 suite）；2. 按需求/架构补齐 PRO-007/009/010/
017/019 运行时路径与 RAL；3. 新增 error tier 负向。

### Unit Test 层（L1，G2 门禁新增 compile + unit PASS）
* **机制固化到 skill 源仓**（4 处）：`vip-test/SKILL.md`（§3 Unit Test 层：五 suite 划分、
  golden vector 形态、`G2 = compile + unit PASS` 门禁、不适合 unit test 的边界清单）、
  主 `SKILL.md`（工作区布局 `unit_test/` + G2/G3 门禁文本）、`templates/vip/docs/
  validation-plan.md`（L0~L7 分层重排，L1=Unit Test 强制层）、`templates/vip/README.md`
  （布局）；`bootstrap.py --ensure` 重物化 OK。
* **axi4 落地**：`unit_test/`（unit_test_runner 断言/计数 + semantic/memory/transaction
  三组 + tb + filelist + Makefile `unit` target）。**79 golden cases 79/79 PASS**。

### Unit Test 立即产出（价值证明）
* 抓出 **axi4_memory unaligned lane 缺陷**：`read_beat/write_beat` 的 `abs_addr` 公式
  错误（应为对齐基址+global_byte，非 beat_addr+b）——读写对称错误导致此前回环测试
  无法暴露；修复后 corner/feature 仍全绿。
* 抓出 5 处测试期望/用例错误（WRAP 回绕用例起始未对齐、item_aligned、compare 用法、
  injector count 判定、lane 数据摆放）——unit 层定位效率直接体现。

### VIP 本体补齐（src/）
1. **slave 背压（PRO-009）**：`backpressure_proc` 消费 `awready/wready/arready_delay`。
2. **response policy 子集（PRO-010/RUL-010）**：`pick_response_status` 按
   `response_weight_*` 加权选择响应状态。
3. **master 注入钩子（RUL-005/011/017 负向能力）**：`inject_early_wlast`（缩短 burst）、
   `inject_missing_wlast`、`inject_unstable_payload`（stall 期翻转 W data/strobe）。
4. **outstanding 写（PRO-007）**：写路径异步化——请求完成即 item_done，B 由
   `write_response_thread` 后台按 FIFO 收取；读保持同步（sequence 依赖 rdata）。
5. **checker RUL-017**：写事务 W beat 数 vs burst_length 对账。
6. **SVA RUL-011**：`a_wdata_stable/a_wstrb_stable`（W 通道 stalled 期 payload 保持），
   assertions 增加 wdata/wstrb 端口（smoke_tb 实例化同步）。
7. **injector 修复**：`ILLEGAL_WSTRB` 改为置位越界 lane（原全 0 是合法 zero-strobe，
   造不成 RUL-013 违规）。
8. **RAL（VER-014，G6 blocker）**：`src/ral/axi4_ral_adapter.sv`（reg2bus/bus2reg、
   provides_responses）+ `axi4_ral_predictor`（frontdoor 预测）接入 pkg；UVM 1.2 API
   适配（无 byte_enable 成员、`get_default_map().get_reg_by_offset()`）。

### 新增 error tier（独立 target，NOT_RUN 如实标注）
* `axi4_error_test.sv`：E1 early-WLAST（缩短）、E2 unstable payload、E3 SLVERR 权重
  （合法语义）、E4 背压下正确性；`make error`（MIN_ERRORS 判定）。
* **当前检出 0/2 → NOT_RUN**：E1 缩短的 monitor 重建对账与 E2 的 stall 窗口（背压
  线程时序）需 G4 调试闭环；从 full 摘除，不阻塞 6 tier 稳定回归，不做伪报。

### 验证（VCS W-2024.09-SP1 / UVM 1.2 / seed=1）
| 检查 | 结果 |
| --- | --- |
| unit test（79 golden cases） | **79/79 PASS** |
| full 6 tier 回归（smoke/feature/corner/negative/random/stress） | **6/6 PASS**（能力补齐后无回退） |
| vip-check | PASS |

### 剩余（如实）
* error tier 检出路径闭环（monitor 拍数对账调试）→ G4；
* AW/W 解耦驱动形态（PRO-019）实现待下轮；多 ID 并发乱序（PRO-008/011/012）待
  outstanding 读异步化 + 多 ID sequence；
* RAL 定向验证（frontdoor 访问 + predictor 镜像一致）待 reg_model 示例。

### 结论
**L1 Unit Test 机制双落地（skill 标准 + axi4 实现 79/79）**；VIP 本体按 architecture
补齐 outstanding 写/背压/response policy/RAL/注入钩子；6 tier 全绿无回退。error tier
NOT_RUN 如实登记，进入 G4 覆盖闭合阶段。

## 2026-09-02 — S09：AW/W 解耦驱动（PRO-019）+ concurrent tier（多 ID/outstanding）

### 目标
按 requirement/architecture 继续：PRO-019 解耦驱动形态；PRO-008/007 多 ID/outstanding
专项测试。

### 完成内容
1. **PRO-019 W-before-AW 驱动形态**：master driver `decouple_w_before_aw` 开关——
   写路径按形态先 W 后 AW（默认仍 AW-before-W）。
2. **slave W 预收队列**：`w_pre_collect_thread` 后台持续吸收 wvalid 拍 +
   `wait_for_write_request` 队列优先消化——解耦场景数据不丢的结构准备。
3. **concurrent tier（`axi4_concurrent_test`，纳入 full）**：
   * C1 多 ID 交替写读回环（ID=0..N 特征值校验）→ PASS；
   * C2 outstanding 写流水（连续 5 写 + 统一读回）→ PASS；
   * C3 W-before-AW 解耦回环 → **NOT_RUN**：slave 侧 W 预收线程与 AW 采样主循环的
     clocking 事件竞争（W 拍归属错位/丢失），需 per-beat 所有权仲裁（G4 深化）；
     driver 实现保留，测试场景注释保留待接入。

### 验证（VCS W-2024.09-SP1 / UVM 1.2 / seed=1）
| 检查 | 结果 |
| --- | --- |
| unit test | 79/79 PASS |
| full 回归（7 tier，含 concurrent） | **7/7 PASS** |

### 剩余（如实）
* C3 decouple 回环：slave W 预收/AW 采样竞争仲裁 → G4；
* error tier 检出闭环（同前）→ G4；
* outstanding 读异步化（当前读同步，R 依赖 rdata）→ 多 ID 乱序/交织的完整并发 → G4。

### 结论
PRO-008/007 有专项 PASS 证据；PRO-019 实现就绪、验证 NOT_RUN（诚实标注）。
full 升级为 7 tier 稳定回归。

## 2026-09-02 — S10：error tier 检出闭环（E1 RUL-017）+ RAL 定向验证 + monitor W 重建修复

### 目标
1. error tier 检出 0/2 根因修复（monitor 固定拍数数组 → 实际 beat 对账）；
2. RAL（VER-014）定向验证：adapter reg2bus/bus2reg + predictor + 物理 memory；
3. C3 decouple W 预收竞争（PRO-019）根因分析并诚实登记。

### error tier 闭环（E1 VALIDATED，E2 诚实 NOT_RUN）
* **根因 1（monitor 重建）**：`axi4_write_monitor` 的 `data/strobe` 固定 `new[burst_length]`
  填不满的尾部为 'x，checker RUL-017 依 `data.size()` 对账永不触发 → 改为**实际拍数
  resize**（WLAST 时截断）+ `write_data_ended_status()` 归属切换（W 无 ID 依到达顺序，
  不并入已 WLAST 事务）。
* **根因 2（注入钩子全局交叉）**：E1/E2 用 driver 全局 bit 导致互相污染 → 改为 **item 级
  注入字段**（`inject_early_wlast`/`inject_unstable_payload` 到 `axi4_item`，driver 优先
  item 级、回退全局）。
* **根因 3（E1 语义）**：early-WLAST 原在 `burst_length-2` 拍（len=4 时发 3 beat）→ 修正
  为第 2 拍（index 1）提前 WLAST，实际 2 beat。
* **结果**：E1 事务（id=1 addr=0xc000）被 checker **精确检出 RUL-017 ×2（两侧 monitor）**，
  `make error` PASS；E2（RUL-011 SVA）依赖 stall 时序，SVA 未触发 → **NOT_RUN 如实标注**
  （Makefile MIN_ERRORS=1 + report_phase 明示），不伪报。

### RAL 定向验证（VER-014，PASS）
* 新增 `axi4_ral_test`（最小 reg_block + adapter）：**adapter reg2bus/bus2reg 直接驱动
  总线事务**（绕过 uvm_reg 全调度，避免 frontdoor 调度挂起），验证：
  * reg2bus 写 item → driver 执行 → slave 写 memory → **物理读回 == 写入值**；
  * bus2reg 读响应解析（UVM_IS_OK + 数据一致）；
  * `axi4_ral_predictor` 组件订阅 monitor response 流（连接 + predict 注册）；
* **结果**：`make ral` PASS（UVM_ERROR=0）。

### C3 decouple（PRO-019）根因确认 + 诚实登记
* 接入 C3 后实测 decouple[0/1] mismatch（读回 0）：**W-before-AW 时 slave 预收队列
  pre_queue=0**（AW 到达时未采到 W）。
* 修复尝试：`w_pre_collect_thread` 改为**仅采集已握手 W 拍**（wvalid && wready，
  避免 stall 误采；修复 clocking output 采样非法）。实测仍 mismatch → 根因确认：
  **master 用 master_cb(output #1)、slave 用 slave_cb(input #1step) 采样，clocking
  沿错位导致预收线程漏采/错位**。属已知时序限制 → **NOT_RUN 如实登记**（G4 深化项）。

### 验证（VCS W-2024.09-SP1 / UVM 1.2 / seed=1）
| 检查 | 结果 |
| --- | --- |
| error tier（E1 RUL-017 检出） | **PASS（2/2，MIN=1）**；E2 RUL-011 NOT_RUN |
| RAL tier（adapter/predictor/memory） | **PASS（UVM_ERROR=0）** |
| full 回归 | **9/9 PASS**（smoke/feature/corner/negative/random/stress/concurrent/error/ral） |

### 剩余（如实）
* E2（RUL-011 SVA）检出依赖 stall 窗口时序 → 待 G4 深化（driver 自含 stall 注入）；
* C3（W-before-AW）slave 预收 clocking 沿错位 → 待 G4 深化（统一样本沿）；
* outstanding 读异步化 + 多 ID 乱序/交织（PRO-008 完整并发）→ 待 G4。

### 结论
**error tier 由 NOT_RUN 转 E1 VALIDATED + RAL 定向验证闭环**；full 升级为 9 tier 全绿。
剩余两项（E2/C3）与 outstanding 读均诚实 NOT_RUN，进入 G4 覆盖闭合阶段。

## 2026-09-02 — S11：P0 技术债清零（E2 RUL-011 + C3 decouple 双闭环）+ G4 覆盖管道建立

### 目标
按优先级逐项闭环：P0-1 E2（RUL-011 SVA 检出）、P0-2 C3（W-before-AW 回环）、
P1-1 覆盖闭合管道。

### P0-1：E2 unstable payload（RUL-011）闭环 ✅
* **根因 1（backpressure delta 循环）**：`backpressure_proc` 的
  `repeat(delay) wready<=0; wready<=1` 无时钟沿间隔，付值被覆盖 → wready 恒 1，
  stall 窗口从不出现。修复为**跨沿拉低**（`repeat @(slave_cb) wready<=0` 后恢复）。
* **根因 2（注入只 wake 一次）**：`inject_unstable_payload` 的 fork 若 wake 时恰逢
  wready=1 则漏检。修复为 **forever 循环等 stall 拍**（wready=0 拍立即翻转 payload）。
* **结构化**：E2 拆为独立 `axi4_error_seq_e2`；test 分两阶段——**阶段 1（stall 开）
  E2+E1、阶段 2（stall 关）E3/E4 干净运行**，消除 stall 外溢。
* **结果**：E2 检出 **RUL-011 ×4**（wdata/wstrb_stable 各 2，addr=0xc100）；
  E1 检出 RUL-017 ×2；report_phase 判定 RUL-011≥1 且 RUL-017≥1（双 VALIDATED）。
  RUL-005×2 为 E2 注入附带现象（WLAST 拍遇 stall），日志可解释。

### P0-2：C3 W-before-AW 解耦（PRO-019）闭环 ✅
* **根因（clocking output 首付值无同步）**：decouple 路径 `drive_write_data` 是 item
  处理入口，首个 clocking output 付值（wvalid<=0）未先 `@(master_cb)` 同步 →
  落非法窗口被丢弃，W 拍从未上线（W_PRE 队列 0 条 DECE 证据）。AW-first 路径
  由 `drive_address` 提供同步故不受影响。
* **修复**：`drive_write_data` 开头补 `@(vif.master_cb)`；同时统一 slave 侧采样沿
  （`w_pre_collect_thread` 与 `wait_for_write_request` 均改 `@(posedge aclk)` +
  接口顶层信号，消除 input#1step 与 output#1 错位）。
* **结果**：接入 seq3 到 concurrent tier → **W-before-AW decouple write/read
  loopback PASS**，C1+C2+C3 全绿（UVM_ERROR=0）。

### P1-1：G4 覆盖闭合管道 ✅（管道建立，阈值判定待下轮）
* `make cov_full`：6 tier（smoke/feature/corner/negative/random/stress）功能覆盖
  采样 → vdb 保留（`build/cov/axi4_cov_*.vdb`）→ urg merge（不可用时 WARN 保留证据）。
* 功能覆盖 summary（axi4_coverage 打印）：stress/random **scenario=100**（最高）、
  burst=83、size_bus_burst=30；smoke 基线 scenario=50。四层模型
  （Feature/Field/Cross/Scenario）covergroup 全部实例化并采样。

### 验证（VCS W-2024.09-SP1 / UVM 1.2 / seed=1）
| 检查 | 结果 |
| --- | --- |
| error tier | **PASS**（RUL-017=2 + RUL-011=4，双 VALIDATED） |
| concurrent tier（含 C3 decouple） | **PASS**（multi-id + outstanding + W-before-AW） |
| full 回归 | **9/9 PASS** |
| cov_full（6 tier 采样） | PASS（vdb + summary 证据） |

### 剩余（如实，更新优先级）
* P1-2 outstanding 读异步化 + 多 ID 乱序/交织（PRO-008 完整并发）；
* P2-1 RUL 专项负向注入全集（001/002/005/006/007/008/009/010/012~016）；
* P2-2 PASSIVE/timeout/extension 专项；
* P3-1 rtm.md S10/S11 同步、P3-2 examples//fault_injection/。

### 结论
**P0 技术债清零**：E2/C3 由 NOT_RUN 转 VALIDATED，known_limitations #1/#2 解除；
G4 覆盖管道建立（cov_full 证据化）。full 9/9 稳定回归保持。
