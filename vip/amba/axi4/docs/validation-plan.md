# AXI4 VIP — Validation Plan（验证方案）

> 模板：由 `vip-test` + `vip-coverage` skill 生成。本文档描述如何验证 VIP 自己（VIP Self Test）——
> 与"验证 DUT"不同，VIP 是待验证对象。

---

> **Document ID**: `AXI4_VALIDATION_PLAN_001`
> **VIP Name**: `axi4`
> **Protocol / Interface**: `AXI4 / AXI4-Lite`（IHI 0022E）
> **Version**: `1.0.0`
> **Status**: `Draft`
> **Owner**: `aixsilicon_vip_repo`
> **Requirement Baseline**: `requirement.md 1.0.0-g0-baseline`
> **Architecture Baseline**: `architecture.md 0.4.0-draft`
> **Target VLNV**: `aixsilicon:vip:axi4:1.0.0`

---

> **章节适用性总览**（图例：`必`=必填；`▲`=按Profile；`◆`=按协议；`○`=可选；N/A=不适用标记。
> 完整映射见 `references/template-applicability.md`。本 VIP 为 **FULL_UVM + AXI4/AXI4-Lite 双剖面**）
>
> | 章 | 标记 | 章 | 标记 | 章 | 标记 |
> | --- | --- | --- | --- | --- | --- |
> | 1 Purpose | 必 | 20 ErrInj | ▲ | 39 Simulator | 必 |
> | 2 Objectives | 必 | 21 Ordering | ◆ | 40 Build | 必 |
> | 3 Scope | 必 | 22 FlowCtrl | ◆ | 41 Metadata | 必 |
> | 4 Strategy | 必 | 23 Boundary | ▲ | 42 Debug | ▲ |
> | 5 SelfTest Env | ▲ | 24 Reset | ▲ | 43 Statistics | ○ |
> | 6 Ref Strategy | ▲ | 25 Timeout | ◆ | 44 Recording | ○ |
> | 7 Categories | ▲ | 26 Config | ▲ | 45 Replay | ○ |
> | 8 Smoke | ▲ | 27 Public API | ▲ | 46 Robustness | ▲ |
> | 9 Basic Tx | ▲ | 28 Obs API | ▲ | 47 Neg Config | ▲ |
> | 10 Feature | ▲ | 29 Viol API | ▲ | 48 Naming | 必 |
> | 11 Tx Model | ▲ | 30 Extension | ▲ | 49 Case Tpl | 必 |
> | 12 Driver | ▲ | 31 RAL | ◆ | 50 Matrix | 必 |
> | 13 Monitor | ▲ | 32 Cov Model | ▲ | 51 ReqCov Review | 必 |
> | 14 Initiator | ▲ | 33 Cov Closure | ▲ | 52 Exit Criteria | 必 |
> | 15 Target | ◆ | 34 Code Cov | ○ | 53 Evidence | 必 |
> | 16 Behavior | ◆ | 35 Random | ▲ | 54 Checklist | 必 |
> | 17 Checker | ▲ | 36 Stress | ▲ | 55 Complete | 必 |
> | 18 Assertion | ▲ | 37 Regr Strat | ▲ | | |
> | 19 Mutation | ▲ | 38 Regr Matrix | ▲ | | |
>
> 裁剪规则：不适用章节标 `N/A`（可合并为一行"组件裁剪决策"），不保留空占位、不删除模板。
> AXI4-Lite 剖面能力差异（无 ID/burst/exclusive/narrow）见 requirement §2.2，验证计划以 AXI4-Full 为主，
> Lite 剖面在 Regression 中按 `--profile axi4lite` 独立执行能力子集。

---

# 1. Purpose（必填）

本文档定义 `axi4` VIP 的验证计划，用于证明：

* `requirement.md`（1.0.0-g0-baseline）中定义的协议能力均已实现（REQ-PRO-001~021、REQ-RUL-001~017）；
* `architecture.md` 中定义的主要组件和数据流工作正确（agent/driver/monitor/sequencer/checker/coverage/memory/env）；
* VIP 能够正确产生合法协议行为（Master 激励 + Slave 响应）；
* VIP 能够正确观察和重建协议事务（含 Write/Read Association 运行时模型）；
* VIP 能够正确发现协议违规（Checker + SVA + Violation Bridge）；
* Coverage、Error Injection、Debug、Public API 等能力工作正确；
* VIP 自身具备足够的质量证据，可进入后续 Qualification（G4/G5）/ Release（G6）。

本文档回答：

> **VIP 应该测试什么、如何测试、覆盖什么、通过标准是什么。**

本文档不负责：

* 重新定义协议需求（见 `docs/requirement.md`）；
* 修改 VIP Architecture（见 `docs/architecture.md`）；
* 记录最终测试结果（见 `reports/` 与 `docs/rtm.md`）；
* 记录最终 Requirement Traceability（见 `docs/rtm.md`）；
* 描述最终用户使用方法（见 `docs/user-guide.md`）。

最终执行结果及证据由 `verification result`、`reports/`、`docs/rtm.md` 统一记录。

---

# 2. Validation Objectives（必填）

VIP Validation 应证明以下五类能力。

## 2.1 Stimulus Correctness

证明 VIP 能够产生：

* 合法读/写事务（single/burst）；
* 边界事务（4KB 边界、WRAP 边界、最大/最小 burst）；
* 并发事务（outstanding、多 ID、AW/W decoupling）；
* 随机事务（constrained random）；
* 协议允许的 Corner Case（narrow/unaligned/zero-strobe/exclusive）；
* 配置指定的特殊事务（handshake pattern、backpressure、响应延迟）。

## 2.2 Observation Correctness

证明 Monitor 能够：

* 正确采样接口（master/slave clocking + monitor_cb）；
* 正确重建 transaction（Write/Read Association：AW→W→B、AR→R）；
* 正确关联 request / response（含无 WID 时 W 按序归属 AW）；
* 正确识别事务起止（WLAST/RLAST、burst length）；
* 正确提取事务字段（id/addr/len/size/burst/lock/strobe/data/response）；
* 正确输出 transaction observation（`item_ap`/`response_item_ap`/`protocol_event_ap`）。

## 2.3 Checking Correctness

证明 Checker / Assertion：

* 能检测真正存在的协议违规（RUL-001~017 负向测试）；
* 不对合法事务产生误报（RUL 正向测试）；
* 能定位对应 Rule / Requirement（rule_id 关联 AXI4-REQ-RUL-xxx）；
* 能提供足够的违规上下文（axi4_violation：rule/severity/timestamp/context）。

## 2.4 Coverage Correctness

证明 Coverage Model：

* 覆盖主要协议能力（四层覆盖：Requirement/Field/Cross/Scenario+Event）；
* Coverpoint 采样条件正确（从 Monitor Transaction / protocol_event 采样）；
* Cross Coverage 正确（size×burst×width、ID×ordering 等）；
* 不产生明显虚假覆盖；
* 能支持 Coverage Closure（P0 Feature 100% exercised）。

## 2.5 Integration Correctness

证明 VIP 能够：

* 正确连接 DUT / Self-Test bench；
* 正确配置（`axi4_configuration`，uvm_config_db 下发 vif/cfg）；
* 正确运行 Active / Passive 模式（master/slave agent 开关）；
* 与 Subscriber / Checker / Coverage / Violation Injector 集成；
* 在标准 Simulator / Build Flow 中使用（VCS + UVM1.2，`-full64`）。

---

# 3. Validation Scope（必填）

## 3.1 In Scope

本次 Validation 覆盖：

* Protocol Capability（PRO-001~021：read/write/burst/outstanding/ID/backpressure/timing/
  ordering/interleave/narrow/unaligned/strobe/exclusive/sideband/reset/decoupling/handshake/byte-lane）；
* Protocol Rules（RUL-001~017，Checker/SVA 正向+负向）；
* Transaction Model（axi4_item/master/slave，字段/约束/helper）；
* Initiator / Master（driver + master sequences）；
* Target / Slave（slave driver + response policy + memory model）；
* Passive Monitor（write/read monitor + data monitor，只观察不驱动）；
* Checker（axi4_checker + ordering model + violation 输出）；
* Assertions（axi4_assertions SVA + violation bridge）；
* Coverage（axi4_coverage 四层）；
* Error Injection（axi4_violation_injector）；
* Configuration（axi4_configuration 参数空间）；
* Public API（configure/connect/start/observe/query/extension）；
* Reset（EXTERNAL/VIP_CONTROLLED ownership，复位行为）；
* Build / Simulator Integration（VCS -full64 UVM1.2）。

## 3.2 Out of Scope

明确本版本不验证的能力（与 requirement §23 Limitations 一致）：

* AXI-Stream / ACE / CHI 协议（另立 VIP）；
* AXI5 / AMBA5 Atomic Transactions（AWATOP，superset 信号保留，AXI4 profile 不激活）；
* AXI3 Locked Transactions（AXI4 已移除）；
* Write Data Interleaving（AXI3 WID，AXI4 移除）；
* RAL 集成（REQ-VER-014 为 **P1 Required、V1.0 Target**，纳入 Validation：**G3 非 blocker、G6 Release blocker**；
  若 V1.0 确定不实现，则 requirement 须先行降级为 P2 Optional，本文档再随之改标 N/A）；
* Recording / Replay（REQ-REC-001，P3/Future 2.0）；
* 第三方仿真器 Xcelium / Questa（V1.0 以 VCS 为 Required，见 §39）。

任何 Out-of-Scope 项必须与 `requirement.md` 的 Limitations / future capability 一致。

---

# 4. Validation Strategy（必填：L0-L7 分层）

推荐采用分层验证：

```text
L0 Static / Structure       vip-check：结构/元数据/编码规则
        ↓
L1 Component                Transaction Model 单测、helper 验证
        ↓
L2 Feature                  feature 定向测试（PRO-001~021）
        ↓
L3 Protocol Rule            RUL-001~017 正向 + 负向
        ↓
L4 Scenario / Corner        4KB 边界、WRAP、narrow/unaligned、exclusive、reset during traffic
        ↓
L5 Random / Stress          constrained random + 高 outstanding + backpressure
        ↓
L6 Mutation / Negative      violation injection → checker 检测率
        ↓
L7 Integration / Regression smoke → feature → full 分层回归 + vip-check
```

各层目标不同，不应仅依赖 Random Test 覆盖全部问题。

---

# 5. Self-Test Environment（按Profile：FULL_UVM 完整环境）

VIP 必须拥有独立 Self-Test Environment（`self_test/`），**不依赖真实项目 DUT**。
采用配对模式（Master VIP + Memory/Response Model + Slave VIP）：

```text
                +----------------+
                | axi4_smoke_test|
                +-------+--------+
                        |
                +-------v--------+
                |  axi4_smoke_env |
                +-------+--------+
                        |
        +---------------+---------------+
        |                               |
+-------v--------+              +-------v--------+
| Master Agent   |              | Slave Agent    |
| (driver/seq/mon)|             | (driver/mon)   |
+-------+--------+              +-------+--------+
        |                               |
        +---------------+---------------+
                        |
                  axi4_if vif
              (master_cb/slave_cb/monitor_cb)
```

配套组件：`axi4_memory`（Slave 数据/响应模型）、`axi4_checker`（挂 monitor 观察）、
`axi4_coverage`（四层覆盖）、`axi4_violation_injector`（错误注入）。
Self-Test 不应依赖真实项目 DUT。

---

# 6. Reference Strategy（按Profile：FULL_UVM 采用 Loopback + Memory Model）

VIP 自验证**不能只依赖"VIP 验 VIP"**（Self-Test 仍使用 Master VIP ↔ Slave VIP + `axi4_memory` +
同一套 checker，但 Qualification Evidence **不得仅依赖两侧互相同意**——存在"同源错误同时存在于
两侧"的风险）。采用以下组件级独立参考策略：

## 6.1 Reference Model

`axi4_memory` 作为 Slave 行为模型：读返回已写数据、WSTRB 感知 partial write、
exclusive 标记与 EXOKAY/OKAY 判定。写读回环验证数据完整性。

## 6.2 Protocol Oracle

Checker 以 `axi4_*_item` 的字段级 compare 与协议规则（RUL-001~017）作为独立 oracle，
验证 Driver 驱动与 Monitor 重建的一致性。

## 6.3 Loopback / Memory Model

Master VIP + Slave VIP + Memory 构成端到端 loopback：`write → read → compare`。

## 6.4 Cross Check

参考 `reference/tvip-axi`（vendored）的语义作为交叉核对；不依赖其代码运行。

## 6.5 Component-level Independent Reference（收紧点）

每条组件的正确性必须由**独立于被测组件自身**的观察/计算来证明，而不是"另一个同类组件
复述相同实现"：

| 被测组件 | 独立参考（不得与被测组件共享实现） |
| --- | --- |
| Driver correctness | independent signal-level observer / scoreboard：不解析为 VIP transaction，直接按原始事务 + 协议规则核对信号沿（含 byte lane / WSTRB / address progression） |
| Monitor correctness | 对照 **原始生成事务** + **raw handshake trace**（非 Monitor 自身重建路径）逐事务 compare |
| Semantic helper correctness | 独立 **Python / 参考公式** 或 **directed golden vectors**：`is_legal_burst()`、`get_beat_address()`、`get_byte_lane_index()`、4KB/WRAP 推进等 |
| Checker correctness | mutation / hand-crafted illegal waveform（§19），不用"正常 loopback 恰好无报错"作为证据 |
| Memory correctness | 独立 **byte-addressable golden model**（与 `axi4_memory` 实现分离），WSTRB 感知、exclusive 标记逐步核对 |

> **优先 golden vectors**（尤其对 byte lane、wrap address、exclusive、WSTRB、AW/W association）：
> 用确定性手工构造的"输入波形 → 期望事务/期望内存状态"向量验证 Monitor/Semantic/Memory 的
> 解析与计算，避免两套实现恰好犯同样错误的系统性偏差。

---

# 7. Test Categories（按Profile：FULL_UVM 全类别）

标准 VIP Test Suite 至少包含以下类别：

```text
smoke       最小正向事务（编译/连接/基本路径）
basic       single read / single write / burst
feature     每个 P0/P1 Feature 定向测试
protocol    RUL 正向/负向、握手形态
corner      4KB 边界、WRAP、narrow/unaligned、max/min burst
negative    illegal burst、错误响应、违规注入
reset       复位前/中/后行为、ownership
random      constrained random（固定种子可复现）
stress      high outstanding、持续 backpressure、大量事务
integration 环境组装、passive 监控、API 验证
```

---

# 8. Smoke Validation（按Profile：FULL_UVM）

目标：

> 证明 VIP 最基本的编译、连接和事务路径可以工作。

至少验证：package compile、interface compile、agent build、configuration、
sequencer-driver 连接、monitor 输出、basic write/read transaction、checker 无误报。

示例 Test：`axi4_smoke_test`（`axi4_smoke_seq`：写读回环）。

通过标准：

* Compile PASS（VCS `-full64 -ntb_opts uvm-1.2`，0 errors）；
* Simulation PASS（UVM_ERROR=0, UVM_FATAL=0, TEST_DONE）；
* 至少完成一笔合法 write + read transaction；
* Checker 无 unexpected error、无 violation 误报。

---

# 9. Basic Transaction Validation（按Profile：FULL_UVM）

验证协议最基本的操作。每种基本事务至少验证：Driver signal、Monitor reconstruction、
Transaction fields、Checker、Coverage sampling。

| VAL ID | 场景 | 覆盖 Feature | 验证点 |
| --- | --- | --- | --- |
| axi4-VAL-001 | single read | PRO-001 | AR→R 重建、字段提取、checker 无误报 |
| axi4-VAL-002 | single write | PRO-002 | AW→W→B 关联、WSTRB、memory 更新 |
| axi4-VAL-003 | INCR burst | PRO-003/004/005 | burst 地址推进、WLAST/RLAST |
| axi4-VAL-004 | FIXED burst | PRO-003/004 | 固定地址、多 beat |
| axi4-VAL-005 | WRAP burst | PRO-003/004/005 | wrap boundary、len∈{2,4,8,16} |

---

# 10. Protocol Feature Validation（按Profile：FULL_UVM）

每个 P0 / P1 Feature 至少应有验证场景。

| Feature ID | Feature | Test Strategy | Expected |
| --- | --- | --- | --- |
| PRO-001 | Read | directed read tests | PASS |
| PRO-002 | Write | directed write tests | PASS |
| PRO-003 | Burst Type | FIXED/INCR/WRAP 三型 | PASS |
| PRO-004 | Burst Length | 边界长度 + illegal length negative | PASS |
| PRO-005 | Burst Address Generation | INCR/WRAP/narrow/unaligned 地址 | PASS |
| PRO-006 | Burst Legality | 4KB/WRAP/SIZE 合法 + 违规 | PASS |
| PRO-007 | Outstanding | 多笔 outstanding + 延迟响应 | PASS |
| PRO-008 | ID 管理 | 多 ID、in/out-of-order | PASS |
| PRO-009 | Backpressure | 各通道 VALID/READY 延迟 | PASS |
| PRO-010 | Channel Timing / Response Delay | request/data gap、response delay | PASS |
| PRO-011 | Response Ordering | 同 ID in-order、异 ID ooo | PASS |
| PRO-012 | Read Interleave | 多 ID 交织返回 | PASS |
| PRO-013 | Narrow Transfer | SIZE<bus width、byte lane | PASS |
| PRO-014 | Unaligned Transfer | unaligned read/write/burst | PASS |
| PRO-015 | Write Strobe / Partial | full/partial/sparse/zero-strobe | PASS |
| PRO-016 | Exclusive Access | EXOKAY/OKAY、monitor 语义 | PASS |
| PRO-017 | Sideband | CACHE/PROT/QOS/REGION/USER 字段，按字段属性拆四类（见 §10.1） | PASS |
| PRO-018 | Reset 中 VIP 行为 | 复位 VALID=0、状态清空 | PASS |
| PRO-019 | AW/W Decoupling | AW before W / W before AW / same-cycle | PASS |
| PRO-020 | Handshake Pattern | READY-before/VALID-before/same-cycle | PASS |
| PRO-021 | Address / Byte-Lane Model | aligned/unaligned/narrow/lane legality | PASS |

## 10.1 Sideband Field-wise Validation（PRO-017）

Sideband 字段的**能力属性不同，验证方法必须按属性拆分**，不能笼统"驱动 CACHE/PROT/QOS/REGION/USER
即算通过"：

| 能力属性（requirement §2.4） | 验证内容 | 方法 |
| --- | --- | --- |
| PRESENT / DRIVE | 各字段能按 transaction 正确驱动到信号（AxCACHE/AxPROT/AxQOS/AxREGION/`*user`），含默认值 | Driver Signal Mapping（§12.1）+ directed drive test |
| MONITOR reconstruction | Monitor 能从信号重建各 sideband 字段并写入 observed item | §13 Reconstruction + golden vector compare |
| CHECK | 仅对**存在语义约束**的字段做检查：CACHE 的 bufferable/modifiable 组合合法性；REGION 范围（0~15）；**QOS/PROT/USER 大多无"非法编码"**，只做 drive/monitor/coverage，不做负向协议检查 | Checker positive；无非法编码的字段不注入负向 |
| COVERAGE | 各字段值域与典型组合纳入 coverpoint（field/cross），作为 coverage 证据 | §32 Coverage Model |

> 原则：**无"非法编码"定义的字段不制造 Protocol Violation**；只验证 drive/monitor/coverage。
> 带语义约束的字段（CACHE 组合、REGION 范围）才进 Checker 负向。

---

# 11. Transaction Model Validation（按Profile：FULL_UVM）

必须独立验证 Transaction Model。

## 11.1 Field Validation

验证 `axi4_item`/`axi4_master_item`/`axi4_slave_item`：randomization、field range、
enum legality（burst type/size/response）、array size、default value、request/response field。

## 11.2 Constraint Validation

验证：

```text
legal random          合法事务可随机化
corner random         边界事务随机化（max burst、max size）
constraint override   用户 override 生效
illegal generation    非法字段生成（供负向测试）
```

## 11.3 Helper Function Validation

验证 Semantic Helper（REQ-TRN-002/021）：`is_legal_burst()`、`is_aligned()`、`get_length()`、
`get_size()`、`get_address()`、`get_4kb_boundary_mask()`、`is_crossing_4kb()`、
`get_beat_address()`、`get_byte_lane_index()`，确保 Driver / Monitor / Checker 共用的
协议语义模型自身正确。

---

# 12. Driver Validation（按Profile：FULL_UVM）

Driver Validation 应证明：Transaction → Signal 映射正确、handshake 正确、timing 正确、
configurable delay 正确、flow control 正确、reset behavior 正确、concurrency 正确。

## 12.1 Signal Mapping

逐字段验证：`Transaction Field → Protocol Signal`，包括 address、command（AW/AR）、ID、
payload（W/R）、attribute（burst/len/size/lock/cache/prot/qos/region）、
response-related control（BRESP/RRESP/WLAST/RLAST）。

## 12.2 Timing

验证：zero delay、fixed delay、random delay、backpressure（READY 延迟）、
wait state、maximum configured delay、AW/W decoupling 时序形态（PRO-019/020）。

---

# 13. Monitor Validation（按Profile：FULL_UVM 重点）

Monitor 是 VIP Validation 的重点。必须验证 `Signal → Monitor → Transaction` 与原始 stimulus 一致。

## 13.1 Transaction Reconstruction

比较 `Driven Transaction` vs `Observed Transaction`，检查：transaction type、address、
length、ID、payload、response、attributes（Write/Read Association Model 正确性，见 §13.4/13.5）。

## 13.2 Concurrent Reconstruction

验证：outstanding、multiple IDs、reordered response、interleaving、overlapping transactions
（无 WID 时 W 按序归属 AW 的 FIFO association）。

## 13.3 Passive Behavior

证明 Passive Monitor **不驱动任何 DUT / Interface signal**（monitor_cb 只采样）。

## 13.4 Write Association Validation（一等验证对象）

AW→W→B 关联是 AXI VIP 最核心、最易错的运行时模型，**单独作为 Validation Category**
（对应 architecture §18 / §21 runtime model），不埋在 Transaction Reconstruction 内。覆盖：

| 场景 | 验证点 |
| --- | --- |
| AW before W | 标准顺序：先 AW 后 W，Monitor 正确归属 |
| W before AW | W 先到、AW 后到，Monitor 缓冲后正确归属 |
| same-cycle | AW 与第一拍 W 同拍握手 |
| multiple AW pending | 多笔 AW 未完成，W 按序归属到正确 AW（FIFO association） |
| gapped W beats | W 拍间插入 READY/背压间隔，关联不丢 |
| B delayed | B 响应延迟，仍归属正确写事务 |
| different BID | BID 与 AWID 不一致时按规范判定（同 ID 才正确） |
| reset with partially assembled write | 未组装完成的写上下文在复位后正确清理（§24） |

## 13.5 Read Association Validation（一等验证对象）

AR→R 关联同样单独验证。覆盖：

| 场景 | 验证点 |
| --- | --- |
| multiple AR same ID | 同 ID 多笔读，R 严格 in-order 返回并正确归属 |
| multiple AR different ID | 异 ID 多笔读，可 out-of-order / interleave |
| R interleave | 跨 ID R 数据交织，Monitor 重建不串 ID |
| same-ID ordering | 同 ID R 顺序保持（RUL-006/008） |
| different-ID ordering | 异 ID 乱序合法，不误报 |
| RLAST close | RLAST 与 burst 长度一致，事务闭合（RUL-005/008） |
| reset mid-read | 读事务中途复位，上下文清理与 RID 关联释放（§24） |

## 13.6 Protocol Event Model Validation（独立正确性）

`protocol_event_ap`（architecture §18）已是正式能力，但 Validation Plan 不能只把它当
Coverage source —— **Event stream 本身必须独立验证正确**（Transaction reconstruction 测对了
不代表 Event stream 对；后者支撑 Temporal Coverage / Statistics / Debug / AI analysis）：

| 检查项 | 期望 |
| --- | --- |
| AW handshake → exactly 1 AW event | 每次 AW 握手恰好 1 个对应事件，无重复 |
| W handshake → exactly 1 W event | 每次 W 握手恰好 1 个对应事件 |
| stall begin/end → event pair | backpressure 起止正确生成 begin/end 事件对 |
| reset assert/release → correct events | 复位断言/释放产生正确事件（含清理语义） |
| ordering of events matches waveform | 事件顺序与原始波形顺序一致 |
| no duplicate event / no missing event | 逐握手核对：不重、不漏（用独立 golden 计数比对，§6.5） |

---

# 14. Initiator Validation（按Profile：FULL_UVM）

验证 Master 能力：basic transaction、random transaction、concurrency（outstanding）、
timing、backpressure handling、response handling、reset recovery、timeout behavior。

---

# 15. Target / Responder Validation（按协议：AXI4 Slave）

验证 Slave 能力：request acceptance、normal response、delayed response（response_delay）、
random response、error response（BRESP/RRESP 类型）、ordering、backpressure、behavior model、
memory / data model（WSTRB-aware 更新）。

---

# 16. Behavior Model Validation（按协议：Memory / Response Model）

验证 `axi4_memory`：read、write、partial update（WSTRB）、initialize、peek/poke、exclusive 标记。
特别验证：**Model behavior 与 Protocol Timing 解耦**（Monitor 永不修改 memory，memory 由
Slave Driver→Behavior Subscriber 或 Passive Memory Predictor 更新，architecture §14）。

Response Policy Model（architecture §20）：`axi4_response_policy` 行为决策层
（BRESP/RRESP 选择、延迟、排序、背压、exclusive EXOKAY/OKAY）作为独立组件验证。

---

# 17. Protocol Checker Validation（按Profile：FULL_UVM 核心，正/负测试）

每条高优先级 Protocol Rule（RUL-001~017）必须进行 **Positive Test + Negative Test**。

## 17.1 Positive Checking

合法事务 `Legal Behavior → Checker → NO ERROR`，用于防止 Checker 误报。

## 17.2 Negative Checking

故意制造协议违规 `Violation → Checker → Expected Error`，必须检查：Rule ID、Severity、
Transaction Context、Error Count、Detection Timing。

> **Rule → Negative Case 一一对应**（与 requirement §3 RUL-001~017 定义严格对齐；
> 本表是 §19 Mutation 与 RTM 的权威映射，Freeze 前必须无错位）：

| Rule | 负向场景（与 requirement 定义一致） | Expected Detector |
| --- | --- | --- |
| RUL-001 | VALID generation 错误等待 READY 才断言 / VALID 提前撤销（两种语义拆分见下） | CHK/SVA |
| RUL-002 | handshake accounting 错误（传输采样/计数不正确） | CHK（directed semantic，见下） |
| RUL-003 | burst 跨 4KB 地址边界（INCR/WRAP） | CHK（SVA 可选，见下） |
| RUL-004 | illegal AxLEN / AxSIZE（len 越界、size>DATA_W/8） | CHK/SVA |
| RUL-005 | WLAST/RLAST 提前 / 缺失 / 与 burst 长度不一致 | CHK/SVA |
| RUL-006 | 同 ID 响应/数据乱序（in-order 违反） | CHK |
| RUL-007 | response 在对应请求未完成（B 先于 W 数据 / R 无 AR）时出现 | CHK |
| RUL-008 | 单笔读 R 数据顺序打乱 / 交织越界 | CHK |
| RUL-009 | 复位断言期间 VALID≠0 | SVA |
| RUL-010 | illegal BRESP/RRESP / invalid EXOKAY 用法 | CHK/SVA |
| RUL-011 | stalled 期间（VALID=1&&READY=0）payload 变化 | SVA |
| RUL-012 | narrow byte lane 越过合法 lane（由 AxADDR/AxSIZE 决定且随 burst 移动） | CHK/SVA |
| RUL-013 | WSTRB 置位超出当前 transfer 覆盖 lane（WSTRB==0 为合法场景） | CHK |
| RUL-014 | unaligned 首拍 lane/WSTRB/地址推进不合法 | CHK |
| RUL-015 | W 数据归属到错误 AW（写数据乱序 / AXI3 式 interleave） | CHK |
| RUL-016 | exclusive monitor / pairing / invalidation 违规（ID、地址范围、属性不匹配；EXOKAY/OKAY 语义） | CHK |
| RUL-017 | burst 被缩短 / 提前终止（提前 WLAST/RLAST 或停拍） | SVA |

### RUL-001 的两种 Validation Semantics

RUL-001 "VALID 不得依赖 READY" 是**行为依赖关系**，不是单周期 illegal value；
仅构造 `READY=0, VALID=0` 无法证明依赖。拆分两种语义分别验证：

1. **Generation Independence**（VALID 生成独立性）：有一笔待发送 transaction、READY 保持 0 →
   Driver / DUT-side source 仍须在合理时机 assert VALID（VALID 拉高不等待 READY）。
2. **Hold-until-Handshake**（保持到握手完成）：VALID 已拉高、READY 保持 0 → VALID 不得撤销
   （保持稳定直到 VALID&&READY 握手）。后者更易由 SVA 精确验证（见 §18）。

### RUL-002 说明

RUL-002 是**传输发生的定义**（仅 VALID&&READY 同时为高时发生一次 transfer）；
**VALID 或 READY 单独为高完全合法**，因此它不是"协议违规"，而是 **Monitor/Checker 的
sampling correctness**：

```text
VALID=1 READY=0 → 不计数 transfer
VALID=0 READY=1 → 不计数 transfer
VALID=1 READY=1 → 恰好计 1 次 transfer
```

因此 RUL-002 走 **directed semantic test**（验证采样/计数正确），**不适合 mutation 注入**，
不进入 §19 Mutation 表。

### RUL-003 说明

4KB 边界是 transaction-level 地址计算规则，用 **Checker（CHK）更自然**；SVA 可实现但非必须。
不为了"每条 Rule 都有 SVA"而引入不必要的 assertion 复杂度。

---

# 18. Assertion Validation（按Profile：FULL_UVM 核心）

每条关键 Assertion 应至少包含：Pass Case、Fail Case、Reset Case。Assert Failure 必须
能够映射到对应 Protocol Rule（Assertion/Violation Bridge：SVA→`axi4_violation`→`violation_ap`）。

关键 SVA（与 §17.2 的 Expected Detector 对齐）：

* VALID stability / hold-until-handshake（RUL-001，对应第 2 种语义）；
* WLAST/RLAST（RUL-005）、复位 VALID=0（RUL-009）、payload stability（RUL-011）、
  burst 终止（RUL-017）。

> **不做 SVA 的规则**：4KB 边界（RUL-003）用 transaction-level Checker（CHK）验证；
> RUL-002 是 sampling correctness，走 directed semantic test（SVA 可做但非必须）。
> 不为"每条 Rule 都有 SVA"而增加复杂度。

---

# 19. Violation / Mutation Validation（按Profile：C 必填）

Mutation Test 用来证明 **VIP Checker 真的能够发现错误**。

```text
Protocol Rule
      ↓
Violation Type
      ↓
Injection
      ↓
Expected Checker
```

| Rule | Mutation | Expected Detector | Result |
| --- | --- | --- | --- |
| RUL-001a | 注入 VALID generation 依赖 READY（有事务、READY=0 仍不 assert VALID） | Checker/SVA | TBD |
| RUL-001b | 注入 VALID 在握手前提前撤销（hold-until-handshake 违反） | SVA | TBD |
| RUL-003 | 注入 4KB 跨界 burst | Checker | TBD |
| RUL-004 | 注入 illegal AxLEN / AxSIZE | Checker/SVA | TBD |
| RUL-005 | 注入 WLAST 提前 / 缺失 | Checker/SVA | TBD |
| RUL-006 | 注入同 ID 乱序响应 | Checker | TBD |
| RUL-007 | 注入 response 在请求未完成时出现 | Checker | TBD |
| RUL-008 | 注入单笔读 R 数据乱序 / 交织越界 | Checker | TBD |
| RUL-009 | 注入复位期间 VALID≠0 | SVA | TBD |
| RUL-010 | 注入 illegal BRESP/RRESP / invalid EXOKAY | Checker/SVA | TBD |
| RUL-011 | 注入 stalled payload 翻转 | SVA | TBD |
| RUL-012 | 注入 narrow byte lane 越界 | Checker/SVA | TBD |
| RUL-013 | 注入 WSTRB 越界 lane | Checker | TBD |
| RUL-014 | 注入 unaligned lane/地址推进非法 | Checker | TBD |
| RUL-015 | 注入 W 数据归属错误 AW / interleave | Checker | TBD |
| RUL-016 | 注入 exclusive monitor/pairing/invalidation 违规 | Checker | TBD |
| RUL-017 | 注入 burst 提前终止 | SVA | TBD |

Mutation 指标（requirement §11.2）：总体 ≥95%；所有 **P0 Rule**（RUL-001~011）mandatory mutation **100%**。

> **RUL-002 不进入 Mutation**：它是 sampling correctness（directed semantic test，§17.2），
> 不制造"协议违规"，故不注入 mutation。此表与 §17.2 Negative Matrix 保持严格一一对应。

---

# 20. Error Injection Validation（按Profile：C 必填）

验证 `axi4_violation_injector`：指定 violation、随机 violation、probability、count、
transaction filter、channel filter、enable / disable。
必须证明：**关闭 Error Injection 后不会影响合法事务行为**（正/负对照）。

---

# 21. Ordering Validation（按协议：AXI4 并发）

对于支持并发的协议必须重点验证：same ID / different ID、in-order、out-of-order（异 ID）、
interleave（读交织）、request-response association（BID/RID）、illegal reorder（RUL-006/008）。

---

# 22. Flow-Control Validation（按协议：AXI4 握手流控）

根据协议验证：backpressure（各通道 READY 延迟）、wait state、ready / valid interaction。
重点场景：minimum delay、maximum delay、random delay、continuous backpressure、
intermittent backpressure（PRO-009/010/020）。

---

# 23. Boundary / Corner Validation（按Profile：FULL_UVM）

所有协议边界都应显式测试：min/max address、min/max burst（INCR 1~256、WRAP 2/4/8/16）、
boundary crossing（4KB）、minimum/maximum width、first/last ID、zero/full WSTRB mask、
aligned/unaligned、reset during transaction、zero-strobe write。

---

# 24. Reset Validation（按Profile：FULL_UVM）

至少覆盖：reset before traffic、reset during request、reset during data、reset during
response、reset with outstanding、reset recovery、multiple reset。
检查：signal state（VALID=0）、Driver/Monitor/Checker state、outstanding、pending
transaction、memory behavior、post-reset traffic（PRO-018/RUL-009）。
Reset Ownership（architecture §29）：EXTERNAL / VIP_CONTROLLED 分别验证。

---

# 25. Timeout Validation（按协议：AXI4 等待语义）

AXI4 无协议级 retry/timeout 机制；VIP 提供事务级 timeout 监控（DBG 相关）。
验证：`Timeout occurs → Expected Violation → Simulation remains controllable`。
若配置未启用 timeout，则该项 `N/A`（AXI4 无 retry，requirement §15 已删除 retry count）。

> **Timeout 归类**：属于 **Environment / Runtime Violation**（VIP 自身的等待/监控能力），
> **不是 AXI Protocol Violation**——AXI 协议并未定义 timeout 语义。因此 timeout 相关
> violation 不得进入 §17.2 / §19 的 RUL-001~017 Protocol Rule 映射，避免用户误以为
> "AXI 协议定义了 timeout"。Timeout 验证走 §25 独立小节，Evidence 单独记录。

---

# 26. Configuration Validation（按Profile：FULL_UVM）

所有 P0 Configuration（CFG-001~020）应至少验证：default、minimum、maximum、typical、invalid、override。

## 26.1 Configuration Profile

验证 `DEFAULT` / `ZERO_DELAY` / `RANDOM_DELAY` / `BACKPRESSURE` / `STRESS` / `PASSIVE`
是否正确展开为目标配置（CFG-006 response_ordering 默认 IN_ORDER）。

## 26.2 Invalid Configuration

非法配置应：build-time reject、start-of-simulation error、explicit warning；不得静默
产生不可预测行为（如 `burst_len` 非法、`data_width` 非法）。

---

# 27. Public API Validation（按Profile：FULL_UVM）

验证用户无需访问内部实现即可完成标准操作。至少覆盖：configure（`axi4_configuration`）、
connect（uvm_config_db 下发 vif/cfg）、start transaction（sequences）、high-level operation、
transaction observe（item_ap）、runtime query（status）、extension。

---

# 28. Observation API Validation（按Profile：FULL_UVM）

连接 `Monitor → Subscriber`，验证：transaction 数量、transaction 内容、顺序、duplicate、
missing、subscriber disconnect（master/slave item_ap + protocol_event_ap）。

---

# 29. Violation API Validation（按Profile：FULL_UVM 核心）

验证 Violation 输出（`axi4_violation`）至少包含：Rule ID、Severity、Timestamp、Context、
Description；并验证 `Checker → External Subscriber` 可正常工作（violation_ap）。

---

# 30. Extension Mechanism Validation（按Profile：FULL_UVM）

验证 Architecture 定义的 Factory Override / Callback / Policy 扩展
（Response Policy 替换、Sequence 扩展、Transaction Extension）。目标：**用户可以扩展
VIP 而不修改原始源码**（architecture §26/§20）。

---

# 31. RAL Validation（按协议：AXI4 非寄存器类总线，P1 Required）

AXI4 为通用总线协议，非寄存器类总线，但 REQ-VER-014（`axi4_ral_adapter/predictor`，UVM RAL
frontdoor access 与 prediction）在 requirement 中为 **P1 Required、Target 1.0**，因此：

* **G3（Functional Validation）：不作为 blocker** —— RAL 属集成能力，不阻塞 Self-Verification 主线；
* **G6（Release）：作为 blocker** —— V1.0 Release 前必须完成验证并关闭；
* 验证内容：`axi4_ral_adapter` / `axi4_ral_predictor` 的 frontdoor read/write 访问、
  `uvm_reg` map 直连、predictor 对写响应（BRESP）的镜像更新一致性、exclusive 路径在 RAL 下的行为；
* 若经评审确定 V1.0 **不实现** RAL，则 requirement 必须先行将 REQ-VER-014 降级为 P2 Optional，
  本文档相应改为 `N/A`，不得在 Required 前提下于 Validation Plan 内自降为可选。

---

# 32. Coverage Model Validation（按Profile：FULL_UVM 四层）

Coverage Validation 不等于 Coverage Closure。首先证明 Coverage Model 本身正确。

## 32.1 Coverpoint Validation

每个关键 Coverpoint 应：有可到达 bin、能被目标 stimulus 命中、illegal bin 正确识别、
ignore bin 正确。

## 32.2 Cross Validation

关键 Cross 应至少通过 directed test 命中典型组合：
`size × burst_type × data_width`、`burst_len × burst_type`、`ID × ordering`、`WSTRB 形态`。

## 32.3 Coverage Source Validation

Coverage 应从 Monitor Transaction 或 `protocol_event_ap`（architecture §18）采样，
避免 Coverage 自己重复解析 DUT signals。

---

# 33. Functional Coverage Closure（按Profile：FULL_UVM 至少 Rule Coverage）

对 P0/P1 Requirement 应建立 Coverage Closure 目标：

| Coverage | Target |
| --- | ---: |
| P0 Feature | 100% exercised |
| Protocol Rule（RUL-001~017） | 100% exercised |
| Required Scenario（4KB/outstanding/interleave/exclusive） | 100% |
| Field Coverage | ≥95% |
| Cross Coverage | ≥90% |
| Required Temporal Scenarios（protocol_event_ap） | 100% exercised |
| Temporal Covergroup Bin Coverage | ≥ threshold（见下） |

> 区分两类指标（requirement §10.6）：**A. Requirement/Feature Exercise（P0=100%，必须）**
> vs **B. Functional Coverage Bin（阈值，非强制 100%）**。

**Temporal / Event Coverage 的"100%"定义**（避免歧义）：

* **Required Temporal Scenarios = 100% exercised**：指每个 required event scenario
  （AW/W 握手事件、stall begin/end 事件对、reset 事件、事件顺序/无重无漏，§13.6）至少
  命中一次 —— 属于 A 类（Exercise，必须 100%）；
* **Temporal Covergroup Bin Coverage ≥ threshold**：指事件覆盖组的 bin 命中率，
  属 B 类（Bin Coverage，设阈值如 ≥90%，非强制 100%）。

> 与 requirement §10.6 的"Requirement/Feature Exercise vs Functional Coverage Bin"
> 口径保持一致：不把"每个 bin 100%"当 requirement exercise 指标。

---

# 34. Code Coverage（可选：辅助指标）

如要求 Code Coverage，可统计 line、branch、toggle、FSM、assertion。注意：**Code Coverage
是辅助指标，不替代 Functional Coverage**。UVM library 与仿真器生成代码应合理 exclude。

---

# 35. Random Validation（按Profile：FULL_UVM）

Constrained Random 应覆盖：transaction（read/write/burst）、timing（各通道延迟）、
ID/tag（多 ID）、payload、response、ordering、backpressure。定义 seed count（≥10）、
transaction count（≥100）、termination condition、timeout。

> **门槛语义**：`seed_count=10` / `transaction_count=100` 是 **minimum baseline（最低门槛）**，
> **不是 qualification sufficiency 的保证**——满足门槛只能说明随机路径被走过，不代表
> Coverage Closure（§33）或 Mutation 达标。Coverage 收敛不足时须提高：
> `seed_count`、`transaction_count`、`duration`，并记录实际用量作为 evidence。
> Stress tier（§36）应在 baseline 之上进一步加大这些参数。

---

# 36. Stress Validation（按Profile：FULL_UVM）

Stress Test 重点验证：长时间运行、大量 transaction、最大 outstanding、高 backpressure、
maximum payload、repeated reset、error recovery。
目的不是只追 Coverage，而是发现 queue leak、deadlock、race condition、performance
degradation、state corruption（Write/Read Association FIFO 最终清空）。

---

# 37. Regression Strategy（按Profile：FULL_UVM）

建议标准 Tier：

```text
smoke
feature
full
stress
```

## 37.1 Smoke

特点：Fast、Basic、Every Commit。`axi4_smoke_test`。

## 37.2 Feature

覆盖：all P0/P1 features（§10 表）、major protocol rules、configuration。

## 37.3 Full

包含：feature、corner、negative、random、reset、integration、coverage。

## 37.4 Stress

用于：long random、maximum load、large seed set。可不作为每次提交必跑。

由 `vip_tool.py regression --vip axi4 --tier <smoke|feature|full>` 编排；
`--profile axi4 / axi4lite` 双剖面独立回归。

---

# 38. Regression Matrix（按Profile）

| Test | Smoke | Feature | Full | Stress |
| --- | ---: | ---: | ---: | ---: |
| Basic（VAL-001~005） | Y | Y | Y | Y |
| Feature（PRO-001~021） | | Y | Y | Y |
| Negative（RUL 负向） | | Y | Y | Y |
| Corner / Boundary | | | Y | Y |
| Random | | | Y | Y |
| Stress | | | | Y |
| Reset | | Y | Y | Y |

---

# 39. Simulator Validation（必填）

对 Requirement 中 Required Simulator 分别验证：compile、elaboration、simulation、
UVM behavior、assertion、coverage。

| Simulator | Compile | Smoke | Full |
| --- | --- | --- | --- |
| VCS（W-2024.09-SP1，-full64 UVM1.2） | Required | Required | Required |
| Xcelium | Not in V1.0 | - | - |
| Questa | Optional | - | - |

> `Required` 必须由实际回归验证，禁止"从未运行却标记支持"。

---

# 40. Build / Packaging Validation（必填）

验证：source list、filelist、include path、package dependency、FuseSoC Core
（gen-core 后）、parameter passing（ID_WIDTH/ADDRESS_WIDTH/DATA_WIDTH）、standalone build
（`make -C self_test compile`）。如支持 FuseSoC：`fusesoc run ...` 至少进行 build / compile validation。

---

# 41. Metadata Validation（必填）

Machine-readable 检查（`reports/gate_status.md` 与 gen-core 生成物）应检查：schema、name、version、
protocol、profile（FULL_UVM）、capabilities、configuration、sequences、checker rules
（RUL-001~017）、limitations（§23）、dependencies（UVM1.2），并保证 **Metadata 声明与实际实现一致**。

---

# 42. Debug Validation（按Profile：FULL_UVM）

验证：transaction log、error log、verbosity、requirement ID（rule_id 关联）、runtime status
（axi4_status）、timeout context、configuration dump。
目标：**发生失败时，仅凭日志可以定位到协议事务和相关 Rule**（DBG-001~004）。

---

# 43. Statistics Validation（可选：P2）

`axi4_status` 统计（REQ-STA-001，P2/Optional）：对比独立计数结果（transaction count、
latency、bandwidth、outstanding、backpressure、error count）。确保统计能力不会影响 DUT / VIP 行为。

---

# 44. Transaction Recording Validation（可选）

REQ-REC-001 为 P3/Future 2.0，V1.0 **不实现** → 标 `Future / N/A`。

---

# 45. Replay Validation（可选）

本版本不支持 Replay（REQ-REC-001 Future）→ 标 `Future / N/A`。

---

# 46. Performance / Robustness Validation（按Profile）

VIP 自身还应避免明显工程问题：simulation performance、memory growth、queue growth、
long-run stability。特别检查：outstanding database eventually clears、no unbounded queue、
no orphan transaction（Write/Read Association 上下文最终释放）。

---

# 47. Negative Configuration Validation（按Profile）

对非法用户使用进行验证：invalid width、unsupported profile、illegal feature combination、
null interface、missing configuration、invalid timeout。
应产生明确错误（`uvm_fatal`/`uvm_error`），而不是 simulation hang、random fatal、
silent wrong behavior。

---

# 48. Validation Test Naming（必填）

建议统一 Test ID：`axi4-VAL-001`、`axi4-VAL-002` ...
测试名称：`axi4_<feature>_<scenario>_test`，例如：

```text
axi4_read_basic_test
axi4_write_basic_test
axi4_burst_incr_test
axi4_burst_wrap_test
axi4_4kb_boundary_test
axi4_narrow_test
axi4_unaligned_test
axi4_zero_strobe_test
axi4_exclusive_test
axi4_outstanding_test
axi4_interleave_test
axi4_backpressure_test
axi4_reset_outstanding_test
axi4_illegal_burst_test
```

---

# 49. Validation Case Template（必填）

每个 Validation Case 最少包含：

## `axi4-VAL-xxx — <Test Name>`

**Objective**

`<验证目标>`

**Requirement**

```text
<REQ-ID>（如 AXI4-REQ-PRO-013）
```

**Architecture**

```text
<Component / Section>（如 §13 Monitor / §20 Response Policy）
```

**Configuration**

```text
<configuration>（如 burst_len=8, data_width=64, response_ordering=IN_ORDER）
```

**Stimulus**

```text
<stimulus>（如 master burst write 8 beats narrow size=2）
```

**Expected Result**

```text
<expected result>（如 checker 无 violation、memory 更新 WSTRB=1 的 byte）
```

**Coverage**

```text
<coverpoint / rule / scenario>
```

**Tier**

```text
Smoke | Feature | Full | Stress
```

---

# 50. Validation Matrix（必填）

在开发启动前至少形成初步矩阵（节选 P0；完整矩阵随 G3 展开并同步 RTM）：

| VAL ID | Requirement | Feature | Method | Checker/Coverage | Tier |
| --- | --- | --- | --- | --- | --- |
| axi4-VAL-001 | PRO-001 | single read | Directed | RUL-002/007；r_cov | Smoke |
| axi4-VAL-002 | PRO-002 | single write | Directed | RUL-002/007；w_cov | Smoke |
| axi4-VAL-003 | PRO-003/004/005 | INCR burst | Directed | RUL-003/005；burst_cov | Feature |
| axi4-VAL-004 | PRO-003/004 | FIXED burst | Directed | RUL-003/005；burst_cov | Feature |
| axi4-VAL-005 | PRO-003/004/005 | WRAP burst | Directed | RUL-003/005；wrap_cov | Feature |
| axi4-VAL-006 | PRO-006/RUL-003 | 4KB boundary | Directed+Negative | RUL-003；boundary_cov | Feature |
| axi4-VAL-007 | PRO-013 | narrow transfer | Directed | byte_lane_cov | Feature |
| axi4-VAL-008 | PRO-014 | unaligned | Directed | byte_lane_cov | Feature |
| axi4-VAL-009 | PRO-015 | zero-strobe write | Directed | strobe_cov | Feature |
| axi4-VAL-010 | PRO-016/RUL-016 | exclusive | Directed | exclusive_cov | Full |
| axi4-VAL-011 | PRO-007/011 | outstanding+ordering | Random | ordering_cov | Full |
| axi4-VAL-012 | PRO-012 | read interleave | Directed | interleave_cov | Full |
| axi4-VAL-013 | PRO-019 | AW/W decoupling | Directed | assoc_cov | Feature |
| axi4-VAL-014 | PRO-020 | handshake pattern | Directed | handshake_cov | Feature |
| axi4-VAL-015 | RUL-001~017 | negative rules | Negative | rule_cov | Full |
| axi4-VAL-016 | PRO-009/010 | backpressure/timing | Random | delay_cov | Stress |
| axi4-VAL-017 | PRO-018/RUL-009 | reset | Directed | reset_cov | Full |
| axi4-VAL-018 | CFG-001~024 | config space | Directed+Invalid | cfg_cov | Feature |

Validation Plan 阶段允许一条 Test 覆盖多个 Requirement，也允许一个 Requirement 由多个 Test 共同证明。

---

# 51. Requirement Coverage Review（必填）

进入代码实现前至少检查：P0 / P1 100% 有 Validation Strategy；P2 根据 Release Scope 决定。
禁止出现：Requirement 已要求，但 Validation Plan 无对应验证方法。

P0 检查：PRO-001~019、PRO-021、RUL-001~011、TRN-001~003、STM-001~002、VER-001~013、
CFG-001~020、API-001~005/008/011/012、ENG/DEL/QLF —— 全部具备验证方法。

---

# 52. Exit Criteria（必填）

退出标准按生命周期 Gate 分层，避免"统一 Exit Criteria"把不同阶段的验收混在一起：

## 52.1 G3 — Functional Validation Complete

* [ ] P0 已实现且验证通过（smoke / basic / feature）
* [ ] Feature Regression PASS（§37.2）
* [ ] 核心 Checker 正向（§17.1）与负向（§17.2）通过
* [ ] 所有关键 Assertion 有 Pass / Fail / Reset Case（§18）
* [ ] Write/Read Association（§13.4/13.5）与 Protocol Event Model（§13.6）验证通过
* [ ] Required Public API / Observation / Violation API 验证通过（§27/28/29）

## 52.2 G4 — Coverage Closure

* [ ] Required Feature Exercise 100%（P0，§33 A 类）
* [ ] Coverage Bin 阈值达标（Field ≥95%、Cross ≥90%、Temporal ≥threshold，§33 B 类）
* [ ] Coverage Model 本身正确（§32）

## 52.3 G5 — Mutation / Qualification

* [ ] Mutation 达标：总体 ≥95%；所有 P0 Rule（RUL-001~011）mandatory mutation 100%（§19）
* [ ] RTM 完整性（requirement→impl→checker→test→coverage→result）可追溯
* [ ] Build / FuseSoC / Metadata / Lint / Simulator matrix 检查通过（§39/40/41）

## 52.4 G6 — Release Qualification

* [ ] P1 Required Requirement 全部关闭（含 RAL，若 V1.0 Required，§31）
* [ ] 文档齐备（requirement / architecture / validation-plan / rtm / user-guide）
* [ ] 无 Blocker / Critical Known Issue
* [ ] Evidence 可进入 `rtm.md`（§53）
* [ ] 发布门禁（vip-release）通过，进入 `aixsilicon:vip:axi4` 发布流程

> 分层原则：G3 证明"功能正确"，G4 证明"覆盖闭合"，G5 证明"质量达标（可发现错误）"，
> G6 证明"可发布"。各 Gate 状态只取 PASS / FAIL / NOT_RUN / BLOCKED / WAIVED，禁止伪报通过。

---

# 53. Validation Evidence（必填）

每次正式 Validation 应产生可追踪 Evidence：

```text
reports/
├── regression/
├── coverage/
├── mutation/
├── logs/
├── simulator/
└── summary/
```

Evidence 应能够被后续 `rtm.md` 引用，并记录于 `reports/run_log.md`。

---

# 54. Validation Review Checklist（必填）

进入正式代码验证前检查：

## Requirement

* [ ] 所有 P0/P1 Requirement 有验证方法
* [ ] Unsupported Feature 未误纳入验证目标（ATOP/Locked/WID-interleave）

## Architecture

* [ ] Transaction 验证已规划（§11）
* [ ] Driver 验证已规划（§12）
* [ ] Monitor 验证已规划（§13）
* [ ] Checker 验证已规划（§17）
* [ ] Coverage 验证已规划（§32）
* [ ] Public API 验证已规划（§27）

## Protocol

* [ ] Basic Transaction 完整（§9）
* [ ] Feature 场景完整（§10）
* [ ] Boundary 场景完整（§23）
* [ ] Ordering / Concurrency 完整（§21）
* [ ] Reset 完整（§24）
* [ ] Negative 场景完整（§17.2）

## Quality

* [ ] Checker 有正向和负向验证
* [ ] SVA 有 pass / fail case
* [ ] Coverage Model 本身有验证
* [ ] Error Injection 有验证（§20）
* [ ] Timeout 有验证（§25）
* [ ] Random / Stress 有规划（§35/36）

## Engineering

* [ ] Simulator Matrix 明确（§39）
* [ ] Regression Tier 明确（§37）
* [ ] Build / Package Validation 明确（§40）
* [ ] Metadata Validation 明确（§41）

---

# 55. Definition of Validation Plan Complete（必填）

当以下问题全部可以回答时，`validation-plan.md` 才认为完成。

### 1. 每个 Requirement 如何被证明？

```text
Requirement（REQ-PRO/RUL/TRN/...）
    ↓
Validation Case（§50 Matrix）
```

### 2. Driver 如何证明自己驱动正确？

```text
Transaction → Signal（§12 Signal Mapping）
```

### 3. Monitor 如何证明自己观察正确？

```text
Signal → Transaction（§13 Reconstruction，含 AW/W/B、AR/R 关联）
```

### 4. Checker 如何证明自己真的能发现错误？

```text
Legal Case（§17.1）
+
Violation Case（§17.2 / §19 Mutation）
```

### 5. Coverage 如何证明自己采样正确？

```text
Directed Stimulus → Expected Bin（§32）
```

### 6. VIP 如何证明在极端情况下仍稳定？

```text
Corner（§23）
Random（§35）
Stress（§36）
Reset（§24）
Timeout（§25）
```

### 7. 用户接口如何证明可用？

```text
Configure（§26/27）
Connect（§27）
Stimulate（§27）
Observe（§28）
Extend（§30）
```

### 8. 最终证据如何进入 RTM？

```text
Requirement
    ↓
Architecture
    ↓
Validation Plan
    ↓
Test Result
    ↓
Evidence（§53）
    ↓
rtm.md
```

满足上述条件后，可进入正式代码实现与验证阶段（G3）。

---

## 附加：假设与待确认项

| # | 假设/疑问 | 影响 | 待确认人 |
| --- | --- | --- | --- |
| 1 | V1.0 以 VCS 为唯一 Required 仿真器 | §39 Simulator Matrix | vip owner |
| 2 | RAL 集成（VER-014, P1 Required）：**G3 非 blocker、G6 Release blocker**；若 V1.0 不实现需 requirement 降级 P2 Optional | §3.2/§31 | vip owner |
| 3 | Recording/Replay（REC-001）V1.0 不实现 | §44/45 | vip owner |
| 4 | Full/Stress tier 用例在 G3 分阶段落地 | §37/38 | vip owner |
| 5 | RUL-001~017 Negative Matrix 与 requirement 定义严格对齐（§17.2 为权威映射） | §17.2/§19/RTM | vip owner |
| 6 | RUL-002 走 directed semantic test，不进入 Mutation；4KB（RUL-003）以 Checker 为主、SVA 可选 | §17.2/§19 | vip owner |
