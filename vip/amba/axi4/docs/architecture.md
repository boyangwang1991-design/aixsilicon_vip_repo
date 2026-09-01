# AIXSILICON AXI4 VIP — Architecture Specification（架构与设计规格）

> 本规格回答 **How**：将 `docs/requirement.md`（What）转化为可实现的 UVM / SystemVerilog 架构；
> **API 签名**由 `user-guide.md`（API Reference）定义。

---

> **Document ID**: `aixsilicon:vip:axi4:arch`
> **VIP Name**: `axi4`
> **Protocol / Interface**: AMBA AXI4 / AXI4-Lite（ARM IHI 0022E）
> **Version**: `0.4.0-draft`
> **Status**: Draft（G1 待确认，按 requirement 0.9.0-g0 同步）
> **Owner**: `<owner>`
> **Requirement Baseline**: `docs/requirement.md`（AXI4-REQ-<CAT>-<NNN>，0.9.0-g0）
> **Profile**: FULL_UVM
> **Target VLNV**: `aixsilicon:vip:axi4:1.0.0`
> **HWIF**: `aixsilicon:hwif:axi`（`IFC-AXI-001`）—— 接口契约唯一来源
> **参考实现**: `repos/aixsilicon_vip_repo/reference/tvip-axi`

---

> **章节适用性总览**（图例：`必`=必填；`▲`=按Profile；`◆`=按协议；`○`=可选；N/A=不适用标记。
> 完整映射见 `references/template-applicability.md`；组件裁剪以 §4 组件矩阵为准）
>
> | 章 | 标记 | 章 | 标记 | 章 | 标记 |
> | --- | --- | --- | --- | --- | --- |
> | 1 Purpose | 必 | 14 Monitor | ▲ | 27 Runtime Status | ▲ |
> | 2 Goals | 必 | 15 Checker | ▲ | 28 Statistics | ○ |
> | 3 Overview | 必 | 16 Assertion | ▲ | 29 Reset | ▲ |
> | 4 Component Matrix | 必 | 17 Violation | ▲ | 30 Timeout | ◆ |
> | 5 Package | 必 | 18 Coverage | ▲ | 31 Recording | ○ |
> | 6 Interface | 必 | 19 Target | ◆ | 32 Machine-readable | 必 |
> | 7 Transaction | ▲ | 20 Behavior Policy | ◆ | 33 Build | 必 |
> | 8 Semantic Helper | ▲ | 21 Memory/Data | ◆ | 34 Dependency | 必 |
> | 9 Configuration | 必 | 22 Error Injection | ▲ | 35 REQ→Arch | 必 |
> | 10 Agent | ▲ | 23 RAL | ◆ | 36 ADR | 必 |
> | 11 Sequencer | ▲ | 24 Public API | ▲ | 37 Constraints | 必 |
> | 12 Sequence | ▲ | 25 High-Level API | ▲ | 38 Review (G1) | 必 |
> | 13 Driver | ▲ | 26 Extension | ▲ | 39 Complete | 必 |

---

# 1. Purpose（必填）

本文档定义 `axi4` VIP 的软件架构与组件设计，将 `requirement.md` 中定义的 AXI4 / AXI4-Lite
协议能力、验证能力和外部接口需求转化为可实现的 UVM / SystemVerilog 架构。

本文档主要回答：

- VIP 由哪些组件组成；
- 各组件职责是什么；
- Transaction 如何建模；
- Driver / Monitor / Checker 如何协作；
- Configuration 如何组织；
- Public API 如何暴露；
- Slave / Target 行为如何建模；
- Coverage / Assertion / Violation 如何接入；
- VIP 如何支持扩展、调试和外部集成。

本文档不定义：详细测试用例、Regression 计划、Coverage Closure 策略、Qualification Evidence、
最终用户操作说明（分别由 `docs/validation-plan.md` / `docs/rtm.md` / `docs/user-guide.md` 承担）。

---

# 2. Architecture Goals（必填）

## 2.1 Protocol Correctness

组件行为必须符合 ARM IHI 0022E（AXI4 / AXI4-Lite）与 `requirement.md`。

## 2.2 Clear Responsibility

各组件职责单一：

```text
Transaction  → 描述协议事务
Sequence     → 生成事务
Driver       → 协议驱动
Monitor      → 事务观察（passive，不判断协议正确性）
Checker      → 协议检查
Coverage     → 功能覆盖
Memory/Model  → 响应与行为模型
```

## 2.3 Reusability

VIP 不绑定特定 DUT / SoC / 测试环境 / 项目目录 / 验证场景。

## 2.4 Observability

所有重要事务、状态与违规可通过标准 analysis port / status 对象观察。

## 2.5 Qualifiability

VIP 自身能力可系统化验证（Self-Test / RTM / Coverage / Mutation）。

---

# 3. Architecture Overview（必填：三大模型总览）

## 3.1 Stimulus Model（Stimulus → Driver → Interface）

```text
Sequence (axi4_base/read/write/access/default/smoke)
   │  item (axi4_item / axi4_master_item / axi4_slave_item)
   ▼
Driver (axi4_master_driver / axi4_slave_driver)
   │  clocking block (master_cb / slave_cb)
   ▼
axi4_if (AW/W/B/AR/R 通道)
```

## 3.2 Observation Model（Interface → Monitor → Transaction）

```text
axi4_if (monitor_cb)
   ▼
Monitor（axi4_write_monitor / axi4_read_monitor / axi4_slave_data_monitor）
   │  重建 axi4_item（id/addr/len/size/burst/mem/prot/qos/region/lock/data/strobe/response）
   ▼
analysis port（transaction_ap / request_item_port / response_item_port）
```

## 3.3 Qualification Model（Transaction → Checker/Coverage/Assertion）

```text
analysis port ──► axi4_checker（协议规则 REQ-RUL-001~017）
             └─► axi4_coverage（四层覆盖）
SVA ──► axi4_assertions（握手/时序/边界/复位）
```

---

# 4. Component Matrix（必填：组件×Profile 裁剪矩阵）

| Component | FULL_UVM | LIGHTWEIGHT | PASSIVE | CHECKER_ONLY | MODEL | Description |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Interface | Y | Y | Y | Y | Y | `axi4_if`（引用 HWIF） |
| Transaction | Y | Y | Y | - | Y | `axi4_item` / master / slave |
| Configuration | Y | Y | Y | - | Y | `axi4_configuration` |
| Initiator Agent | Y | Optional | N | N | N | `axi4_master_agent` |
| Target Agent | Y | Optional | N | N | N | `axi4_slave_agent` |
| Sequencer | Y | Optional | N | N | N | `axi4_master/slave_sequencer` |
| Driver | Y | Optional | N | N | N | `axi4_master/slave_driver` |
| Monitor | Y | Y | Y | N | N | `axi4_write/read_monitor` + data_monitor |
| Checker | Y | Y | Y | Y | - | `axi4_checker` |
| Assertions | Y | Optional | Y | Y | - | `axi4_assertions`（SVA） |
| Coverage | Y | Y | Y | Y | - | `axi4_coverage` |
| Behavior Model | Optional | Optional | N | N | Y | `axi4_memory`（Slave 行为） |
| RAL Adapter | Optional | Optional | N | N | N | `axi4_ral_adapter/predictor` |
| Statistics | Y | Optional | Y | - | - | status + 统计 |

> Profile：**FULL_UVM**。最终裁剪结果由 `docs/requirement.md` 决定；`vip-check` 校验 Profile 与组件表一致性。

---

# 5. Package Architecture（必填：Public Package 划分）

对外仅暴露有限 Public Package：

```text
axi4_pkg
axi4_if
```

用户典型使用：

```systemverilog
import axi4_pkg::*;
axi4_if #(.ID_WIDTH(8), .ADDRESS_WIDTH(32), .DATA_WIDTH(32)) vif(...);
axi4_configuration cfg = axi4_configuration::type_id::create("cfg");
uvm_config_db #(virtual axi4_if)::set(null, "*", "vif", vif);
```

内部组件（configuration/status/memory/item/monitor/driver/sequencer/sequence/checker/coverage/env）
均通过 `axi4_pkg` include，不单独暴露。

---

# 6. Interface Architecture（必填：引用 HWIF 为 SSOT）

| 项 | 内容 |
| --- | --- |
| HWIF 引用 | `aixsilicon:hwif:axi`（`IFC-AXI-001`） |
| 信号来源 | 5 通道（aw/w/b/ar/r）信号集合、方向、位宽、握手与语义以 HWIF 契约为**唯一基准** |
| 命名规范 | AXI 标准命名（无下划线，如 `awvalid`/`awlock`/`awregion`/`awuser`） |
| 完整信号集 | 必选 `awlock/arlock`、`awregion/arregion`；capability 保留 `awatop`/`*user` |
| Exclusive 语义 | `awlock/arlock=1` 表达 **exclusive access**；不支持 AXI3 locked transaction |
| **AWATOP 边界** | `awatop` 为 HWIF superset 信号（AXI5/AMBA5 Atomic）；**AXI4 profile 下驱动/钳位为非原子值、不激活**（非 AXI4 capability，REQ §2.4/§2.5） |
| 与 tvip-axi 差异 | tvip-axi 缺 lock/region/atop/user；`axi4_if` 以 HWIF 为准，不得照搬 |

`axi4_if` 提供三套 clocking block（`master_cb`/`slave_cb`/`monitor_cb`）与 modport。

---

# 7. Transaction Architecture（按Profile）

`axi4_item`（REQ-TRN-001/002）字段分类：

```text
Request Fields     id / address / burst / len / size / memory_type / protection / qos / region / lock / strobe / data
Response Fields    response / has_response
Observation Fields start_time / end_time / address_time / response_time
Derived Fields     effective_address / total_bytes / aligned / boundary_crossing
```

- `axi4_master_item`：Master 侧激励事务；
- `axi4_slave_item`：Slave 侧响应事务（含 `slave_response`/`respond`）；
- `axi4_payload_store`：事务负载暂存（gapped 写数据、交织重建辅助）。

字段级 compare policy（`axi4_compare`）替代裸 `uvm_object::compare()`。

**Address / Byte-Lane Model（REQ-PRO-021）**：aligned/unaligned/narrow/INCR/FIXED/WRAP lane/WSTRB legality
由 Semantic Helper 统一计算，Driver/Monitor/Checker/Coverage 复用。

**Protocol Event Model（REQ-TRN-003）**：观察并结构化表示关键 channel-level protocol event
（AW/W/B/AR/R handshake、reset、stall/backpressure），经 `protocol_event_ap` 发布，供
Checker / Scenario Coverage / Statistics / Debug 消费（对应 Requirement §4.3）。

---

# 8. Protocol Semantic Helper（按Profile）

统一语义计算层（`axi4_types_pkg` 函数 + `axi4_item` 方法），Driver/Monitor/Checker/Coverage 复用：

```text
is_aligned / get_transfer_size / get_payload_size / get_transaction_length
get_beat_address / get_byte_lane / check_boundary
pack/unpack_burst_length / pack/unpack_burst_size
encode/decode_memory_type / compare_memory_type
```

> Checker 规则判定与 Reference/Model 保持独立实现，避免"同源错误"。

---

# 9. Configuration Architecture（必填）

`axi4_configuration`（REQ-CFG-001~024）分层配置：

```text
协议与位宽    protocol / id_width / address_width / data_width / strobe_width / max_burst_length
行为特性      response_ordering(默认 IN_ORDER) / outstanding_responses / enable_response_interleaving / min/max_interleave_size / response_weight_*
时序/背压    request_start_delay / write_data_delay / response_start_delay / response_delay / default_*ready + *_ready_delay / reset_by_agent
扩展开关      enable_checker / enable_coverage / enable_error_injection / enable_timeout / timeout_cycles / agent_mode
扩展配置      max_outstanding_* / exclusive_support / drive_* / random_constraint_mode
```

- `axi4_delay_configuration`：自包含延迟配置（FIXED/RANDOM）；
- `agent_mode`：ACTIVE_MASTER / ACTIVE_SLAVE / PASSIVE / DISABLED；
- 预定义 Profile：`get_axi4_profile()` / `get_axi4lite_profile()`；
- 字段名避免 `constraint_mode`（UVM 内置方法冲突），用 `random_constraint_mode`（REQ-CFG-024）。

---

# 10. Agent Architecture（按Profile：仅 F）

- `axi4_master_agent`：组装 master sequencer/driver + write/read monitor；ACTIVE/PASSIVE；
- `axi4_slave_agent`：组装 slave sequencer/driver + write/read monitor + data monitor + memory；ACTIVE/PASSIVE。

Agent 模式 `AXI4_DISABLED` 时不创建组件。

---

# 11. Sequencer Architecture（按Profile：仅 F）

- `axi4_master_sequencer`：标准 `uvm_sequencer #(axi4_master_item)`；
- `axi4_slave_sequencer`：标准 `uvm_sequencer #(axi4_slave_item)`。

---

# 12. Sequence Architecture（按Profile：仅 F）

- `axi4_master_base_seq`：base + 高层 API（write/read/burst_write/burst_read，REQ-API-002）；
- `axi4_master_write_seq` / `axi4_master_read_seq`：定向读写（legal 约束）；
- `axi4_master_access_seq`：随机访问；
- `axi4_slave_default_seq`：slave 自动响应；
- `axi4_smoke_seq`：开箱即用写读回环。

---

# 13. Driver Architecture（按Profile：仅 F）

- `axi4_master_driver`：驱动 AW/W/AR，接收 B/R；处理 request_start_delay、write_data_delay、timeout；
- `axi4_slave_driver`：接收 AW/W/AR，驱动 B/R；处理 response_start_delay、memory 读写、exclusive 语义。

Driver 在 run_phase 等待复位释放后才驱动（REQ-RUL-009）。支持 AW/W 解耦（REQ-PRO-019）与
READY 行为模式（REQ-PRO-020）。

## 13.1 Write Runtime Model（AW/W/B Association，G1 Blocker）

AXI4 无 WID，W 数据如何归属前面的 AW 是整个 Monitor/Slave Driver 的核心。冻结如下 Write Runtime Model：

```text
1. AW handshake 建立 write context（awid/awaddr/awlen/awsize/awburst/...）
2. W beats 按 AW 事务顺序归属（FIFO：先到先服务；无 WID 故依序匹配）
3. WLAST 关闭 data phase（该事务 W 数据收齐）
4. B response 按 BID 关联到对应 write context
5. completed write transaction 在 B 握手后发布（transaction_ap / response_item_port）
```

要点：

- **AW request queue**：未完成 AW 上下文队列（供 W 归属）；
- **W beat ownership**：W 数据按到达顺序匹配最早未收齐 W 的 AW context（AXI4 禁止 write-data interleaving，REQ-RUL-015）；
- **write completion condition**：AW + 全部 W beats + B 均完成后事务才算完成；
- **B ↔ completed write association**：BID 关联 write context（B 每事务 1 拍）。

对应实现：`axi4_write_monitor`（Observe）、`axi4_slave_driver`（Target）。

## 13.2 Read Runtime Model（AR/R Association，G1 Blocker）

对称冻结 Read Runtime Model：

```text
AR handshake
  ↓
read context[ID]（arid/araddr/arlen/...）
  ↓
R beat collection（按 ID 归属）
  ↓
RLAST
  ↓
completed read transaction
```

要点：

- **read context[ID]**：同 ID 多笔 outstanding 通过 FIFO 区分（按 AR 顺序）；
- **R beat 归属**：R beat 归属**最早未完成**的同 ID read context（in-order per-ID）；不同 ID 可 interleave（REQ-RUL-008/012）；
- **RLAST 结束**：RLAST 关闭对应 read context，事务完成；
- 读响应在 AR 后 R 数据返回（响应跟随请求，REQ-RUL-007）。

对应实现：`axi4_read_monitor`（Observe）、`axi4_slave_driver`（Target）。

---

# 14. Monitor Architecture（按Profile：F/L/P 需要）

Monitor **只负责 Observe + Reconstruct**，不判断协议正确性（交给 Checker/SVA）**、不修改任何 DUT/模型状态**：

- `axi4_write_monitor`：AW/W/B 重建写事务（按 §13.1 Write Runtime Model）；
- `axi4_read_monitor`：AR/R 重建读事务（按 §13.2 Read Runtime Model）；
- `axi4_slave_data_monitor`：W 数据专项观察（**只发布，不更新 memory**）。

每个 Monitor 提供 `transaction_ap`、`request_item_port`、`response_item_port`、`error_ap`（可选 `protocol_event_ap`）。

**Monitor 与 Memory 完全解耦（G1 Blocker）**：Monitor **永远不修改 `axi4_memory`**，避免 Passive 模式意外改变状态。
memory 更新由以下任一路径承担（互斥选择，见 ADR）：

```text
路径 A（Active Slave）：Slave Driver 接受写 → Behavior Subscriber → axi4_memory
路径 B（Passive/Predictor）：Memory Predictor / Behavior Subscriber 订阅 monitor 的 transaction/event → axi4_memory
```

---

# 15. Checker Architecture（按Profile：C 最核心）

`axi4_checker`（uvm_scoreboard）实现协议规则检查（REQ-RUL-001~017）：

```text
check_request_rules    请求侧（burst/4KB/响应编码）
check_response_rules   响应侧（编码/EXOKAY 语义）
check_transaction_rules 完整事务（响应 beat 数：读==len、写==1）
Ordering Model          §5.1（按 ID 的请求/响应队列，same-ID / cross-ID / interleaving）
```

结构化违规输出（REQ-API-008）：`axi4_violation` 含 rule_id/severity/channel/time/item。

---

# 16. Assertion Architecture（按Profile：C 核心）

`axi4_assertions`（SVA module）覆盖：

```text
REQ-RUL-001 VALID 不依赖 READY    REQ-RUL-005 WLAST/RLAST
REQ-RUL-002 握手机制（cover）      REQ-RUL-009 复位行为
REQ-RUL-011 payload stability     REQ-RUL-017 禁止提前终止
```

通过 `bind axi4_if` 或顶层实例化接入。

**Assertion Reporting Integration（G1 Blocker）**：SVA 处于 module/interface 世界，不能天然 `new` UVM object 再发 analysis port。冻结统一通道方案：

```text
SVA failure
   ↓
Assertion Event / Report Bridge
   ↓
axi4_violation
   ↓
violation_ap
```

- **Assertion Bridge**（`axi4_assertion_bridge`）：在含 `axi4_if` 实例的作用域实例化，将 SVA `assert` 失败（`$error`/fail 计数）转换为 `axi4_violation` 并写入 `violation_ap`；
- 也可退化为：**Checker → violation_ap** + **SVA → native assertion report**（两套独立报告），但**必须二选一**并在实现时固化（见 ADR-006），避免实现阶段发明跨 module/class 的临时机制。

---

# 17. Violation Model（按Profile：C 必填）

`axi4_violation`（uvm_sequence_item）：

```text
rule_id / rule_name / severity / channel / time_stamp / item
```

经 `violation_ap` 广播，供外部组件（scoreboard/统计）订阅。

**统一 Violation 来源**：

```text
Checker  → 违规上报 → axi4_violation → violation_ap
SVA      → Assertion Bridge → axi4_violation → violation_ap（或 native report，二选一，见 §16）
```

---

# 18. Coverage Architecture（按Profile）

`axi4_coverage`（uvm_subscriber）四层覆盖：

```text
Feature/Field   access_type / burst_type / burst_length / burst_size / strobe_shape / lock
Cross           SIZE×BUS_WIDTH×BURST_TYPE、TYPE×RESPONSE、LENGTH×SIZE
Scenario        boundary / basic-burst / narrow / unaligned
Assertion       SVA cover（由 axi4_assertions 提供）
```

**Temporal / Event Coverage（G1 Blocker）**：显式消费 `protocol_event_ap`（REQ-TRN-003），覆盖：

```text
AW before W
W before AW
same-cycle AW/W
READY before VALID
VALID before READY
stall length
max outstanding depth
read interleave switch
```

由 `axi4_event_coverage`（订阅 `protocol_event_ap`）或并入 `axi4_coverage` 的 temporal covergroup 实现。

闭合指标遵循 REQ-QLF-004 + requirement §10.6（Requirement/Feature Exercise 与 Functional Coverage Bin 分开）。

---

# 19. Target / Responder Architecture（按协议）

`axi4_slave_agent` + `axi4_slave_driver` + `axi4_response_policy` + `axi4_memory` 提供 AXI4 Target 行为：

- 接收 AW/W/AR，按 memory 内容返回 B/R；
- exclusive read/write 语义（REQ-PRO-016 / REQ-RUL-016）；
- 响应延迟/排序/交织由 `axi4_response_policy` 决策。

Target 数据流：

```text
Request
   ↓
Slave Driver
   ↓
Response Policy（选择 BRESP/RRESP、延迟、排序、背压、地址相关行为）
   ↓
Memory / Behavior Model
   ↓
Response（B/R）
```

---

# 20. Behavior Policy Architecture（按协议/按Profile）

Slave 行为可定制（REQ-API-005）而不修改 VIP 源码。

**Response Policy Model（G1 Blocker）**：正式引入 `axi4_response_policy`（行为决策层），职责：

```text
choose BRESP/RRESP
choose response delay
choose ordering（in/out-of-order）
choose backpressure behavior
address-dependent behavior
exclusive EXOKAY/OKAY decision
```

- Config 只配置**默认 policy**；用户**替换 policy 而非 override driver**；
- `axi4_memory` 提供数据；policy 决定"如何响应"；两者解耦；
- Passive 模式可用独立 `axi4_response_predictor`（订阅 monitor 事务 → memory/统计）实现相同决策逻辑，供 SoC 监控。

自定义入口：memory content（initialize/load/poke）、response status、延迟/背压（config）。

---

# 21. Memory / Data Model Architecture（按协议）

`axi4_memory`（REQ-VER-012）：

- read/write/peek/poke/initialize/clear/load；
- narrow/unaligned 仅更新 WSTRB=1 的 byte（REQ-PRO-015，含 Zero-strobe：`WSTRB='0` 不更新 memory、事务照常完成）；
- exclusive 独占标记与冲突检测（REQ-RUL-016）。

---

# 22. Error Injection Architecture（按Profile）

`axi4_violation_injector`（REQ-CFG-018）：

```text
violation type：illegal_wrap_length / illegal_wstrb / cross_4kb / early_wlast /
                missing_wlast / unstable_awaddr / invalid_burst / invalid_id / invalid_response
```

与 `axi4_checker` 联动（Mutation 检测率：总体 ≥95% + P0 mandatory 100%，REQ-QLF-005）。

---

# 23. RAL Integration Architecture（按协议）

AXI 属寄存器类总线，提供（规划）：

```text
axi4_ral_adapter   reg2bus / bus2reg（REQ-VER-014 / REQ-API-007）
axi4_ral_predictor 前门预测
```

V1.0 可作为可选组件（Release 前验证）。

---

# 24. Public API Architecture（按Profile）

对外稳定 Public API：

- Configuration：`axi4_configuration`（REQ-API-004）；
- Stimulus：Sequence + high-level API（REQ-API-002）；
- Observation：`transaction_ap` / `response_item_port`（REQ-API-003）；
- Violation：`violation_ap`（REQ-API-008）；
- Runtime Status：`axi4_status`（REQ-API-009）。

---

# 25. High-Level Operation API（按Profile）

`axi4_master_base_seq` 提供高层调用（REQ-API-002）：

```text
write(addr, data, strobe)
read(addr, output data)
burst_write(addr, data[], strobe[], len, size)
burst_read(addr, len, size, output data[])
```

---

# 26. Extension Architecture（按Profile）

非侵入式扩展（REQ-API-006）：

- Factory override（自定义 item/config/checker）；
- 派生 sequence 复用 base；
- 订阅 analysis port 扩展 scoreboard/统计。

---

# 27. Runtime Status Architecture（按Profile）

`axi4_status`（REQ-VER-013 / REQ-API-009）：

```text
outstanding_read/write_count、pending_response_count、transaction_count、
violation_count、timeout_count、per-ID outstanding
```

---

# 28. Statistics Architecture（可选）

基于 status + monitor 统计（REQ-STA-001）：transaction count / latency / outstanding depth / backpressure cycles。
V1.0 提供基础统计；详细性能统计后续增强。

---

# 29. Reset Architecture（按Profile）

**协议规则（REQ-RUL-009）**：复位断言期间 VALID 输出满足协议 reset requirements（VALID=0，SVA 校验）。

**VIP 行为（REQ-PRO-018）**：所有 stateful 组件对 reset 定义确定性恢复行为——

- `axi4_if` 提供 `areset_n`；
- driver 在 run_phase 等待复位释放（`@(posedge aclk iff areset_n)`）；
- 复位后不残留 pre-reset outstanding transaction（outstanding/pending 丢弃策略）；
- checker 状态在复位后清空。

**Reset Ownership（G1 Blocker）**：明确 reset 归属，避免多 agent 同时驱动 reset——

```text
reset_mode =
  EXTERNAL        复位由 TB/外部提供（默认）
  VIP_CONTROLLED  由 VIP 指定组件（如 master_agent）驱动
```

- **一个 interface 只有一个 reset owner**；
- Passive 模式**只能观察 reset**，永不驱动；
- `reset_by_agent` 配置仅在 `VIP_CONTROLLED` 时生效。

---

# 30. Timeout Architecture（按协议）

AXI 含等待/同步语义，支持可配置 timeout（REQ-API-010）：

- master driver 的 B/R 响应超时检测（`enable_timeout`/`timeout_cycles`）；
- 超时上报 `axi4_status.timeout_count` + UVM error。

---

# 31. Transaction Recording Architecture（可选）

V1.0 规划中（N/A），V2.0 支持（REQ-REC-001）。

---

# 32. Machine-Readable Capability（必填）

`metadata/vip.yaml` 描述（REQ-API-012）：

```yaml
vip:
  name: axi4
  protocol: AMBA AXI4 / AXI4-Lite
  version: 1.0.0

profiles: [axi4_full, axi4_lite]

roles: [master, slave, passive]

capabilities: [read, write, burst, outstanding, id, exclusive, narrow, unaligned, wstrb]

operations: [write, read, burst_write, burst_read]

configuration: [protocol, id_width, address_width, data_width, max_burst_length,
                response_ordering, outstanding_responses, exclusive_support, agent_mode]

sequences: [base, read, write, access, default, smoke]

checker_rules: [AXI4-REQ-RUL-001, AXI4-REQ-RUL-002, AXI4-REQ-RUL-003, AXI4-REQ-RUL-004,
                AXI4-REQ-RUL-005, AXI4-REQ-RUL-006, AXI4-REQ-RUL-007, AXI4-REQ-RUL-008,
                AXI4-REQ-RUL-009, AXI4-REQ-RUL-010, AXI4-REQ-RUL-011, AXI4-REQ-RUL-012,
                AXI4-REQ-RUL-013, AXI4-REQ-RUL-014, AXI4-REQ-RUL-015, AXI4-REQ-RUL-016,
                AXI4-REQ-RUL-017]

limitations: [atop-not-driven-v1, user-optional-drive-v1, recording-replay-v2, axi3-not-supported]
```

---

# 33. Build / Integration Architecture（必填）

```text
axi4/
├── src/           # axi4_types_pkg.sv / axi4_if.sv / axi4_pkg.sv / configuration / status / memory / item / agent / sequences / coverage / checker / env
├── self_test/     # Makefile + filelist + tb（smoke_env/test/tb）
├── examples/      # 最小集成示例 DUT（规划）
├── docs/          # requirement / architecture / validation-plan / rtm / user-guide
├── fusesoc/       # .core（gen-core 生成）
└── qualification/ # RTM / reports / evidence
```

Build Interface：`filelist.f` + `Makefile`（vcs 已验证，`-full64 -ntb_opts uvm-1.2`）+ FuseSoC Core。

---

# 34. Dependency Architecture（必填）

```text
axi4 VIP
├── UVM 1.2
├── HWIF Contract  aixsilicon:hwif:axi（IFC-AXI-001）
└── axi4_types_pkg（自包含，不依赖 tue/tvip-common）
```

- 参考实现 `tvip-axi`（Apache-2.0）仅作设计参考，**不引入其 tue/tvip-common 运行时依赖**；
- 禁止产生未经声明的隐式依赖。

---

# 35. Requirement-to-Architecture Mapping（必填：REQ→组件映射）

| Requirement | Architecture Component |
| --- | --- |
| AXI4-REQ-VER-001（接口） | `axi4_if` |
| AXI4-REQ-TRN-001/002（事务） | `axi4_item` / `axi4_master_item` / `axi4_slave_item` |
| AXI4-REQ-TRN-003（Protocol Event） | `protocol_event_ap`（monitor/event 发布） |
| AXI4-REQ-CFG-001~024（配置） | `axi4_configuration` |
| AXI4-REQ-VER-004（Master Agent） | `axi4_master_agent` |
| AXI4-REQ-VER-005（Slave Agent） | `axi4_slave_agent` |
| AXI4-REQ-VER-006（Sequencer） | `axi4_master/slave_sequencer` |
| AXI4-REQ-VER-007（Driver） | `axi4_master/slave_driver` |
| AXI4-REQ-VER-008（Monitor） | `axi4_write/read_monitor` + `axi4_slave_data_monitor` |
| AXI4-REQ-VER-009 + REQ-RUL-001~017（Checker） | `axi4_checker` |
| AXI4-REQ-VER-010（Assertion） | `axi4_assertions` |
| AXI4-REQ-VER-011（Coverage） | `axi4_coverage` |
| AXI4-REQ-VER-012（Memory） | `axi4_memory` |
| REQ-API-005（Slave 行为定制） | `axi4_response_policy`（行为决策层） |
| AXI4-REQ-VER-013 / API-009（Status） | `axi4_status` |
| AXI4-REQ-VER-014 / API-007（RAL） | `axi4_ral_adapter/predictor`（规划） |
| AXI4-REQ-CFG-018 / QLF-005（Error Injection） | `axi4_violation_injector` |

> 完整链 `Requirement → Design → Validation → Result → Evidence` 最终由 `docs/rtm.md` 管理。

---

# 36. Key Architecture Decisions（必填：ADR 取舍记录）

## ADR-001：自包含实现，不依赖 tue/tvip-common

**Problem**：tvip-axi 参考实现依赖外部库 tue/tvip-common，直接引入会带来运行时依赖与子模块管理负担。

**Decision**：VIP 采用**自包含标准 UVM 1.2 实现**，参考 tvip-axi 行为模型，但不引入其外部依赖。

**Reason**：VIP 应作为独立可发布的 FuseSoC 资产，减少第三方依赖。

**Alternatives**：直接 vendor tue/tvip-common（增加复杂度）。

**Impact**：需自行实现 delay 配置/时序逻辑（`axi4_delay_configuration`）。

## ADR-002：Monitor 只观察不判断

**Problem**：协议正确性判断若放在 Monitor 会与 Checker 职责重叠。

**Decision**：Monitor 仅做 passive 采样与事务重建；协议规则全部由 `axi4_checker` 与 `axi4_assertions` 承担。

**Reason**：职责单一，Checkable/Qualifiable 边界清晰。

**Impact**：Monitor 只发布 transaction，无协议判断逻辑。

## ADR-003：接口以 HWIF 为准，补齐 lock/region/user

**Problem**：tvip-axi 参考接口缺 `awlock/arlock`、`awregion/arregion`、`awatop`/`*user`。

**Decision**：`axi4_if` 采用 HWIF 完整信号集（必选 lock/region + capability atop/user）。

**Reason**：HWIF 为接口契约唯一 SSOT（REQ-VER-001）。

**Impact**：接口信号多于 tvip-axi；capability 信号 V1.0 保留可置常量。

## ADR-004：Exclusive 与 AXI3 Locked 语义分离

**Problem**：AXI4 已移除 locked transactions，`AxLOCK` 仅表达 exclusive access。

**Decision**：`awlock/arlock=1` 仅表达 exclusive；不支持 AXI3 locked transaction。

**Reason**：遵循 ARM IHI 0022E 与 requirement REQ-PRO-016 / REQ-RUL-016。

**Impact**：`axi4_memory` 维护 exclusive monitor（pairing/属性匹配/invalidation）；checker 校验 EXOKAY 语义。

## ADR-005：Requirement ID 局部编号

**Problem**：旧全局编号（REQ-010/0100/0101…）工具化排序混乱，新增需求需全局重排。

**Decision**：采用 `AXI4-REQ-<CATEGORY>-<NNN>` 局部编号（每类别独立 001 起编），新增需求只影响所属类别。

**Reason**：局部编号可扩展、无需全局重排，机器可解析。

**Impact**：requirement/architecture/checker 编号已同步（附录 A/C）。

## ADR-006：Assertion Reporting Integration

**Problem**：SVA 处于 module/interface 世界，不能天然 `new` UVM object 再发 analysis port；若不固化方案，实现阶段容易发明跨 module/class 的临时机制。

**Decision**：采用 **Assertion Bridge 方案**：`axi4_assertion_bridge` 将 SVA 失败转换为 `axi4_violation` 并写入 `violation_ap`，与 Checker 违规统一通道（备选：SVA 用 native report，二选一并在实现时固化）。

**Reason**：Violation 接口（REQ-API-008）要求机器可读、外部订阅统一；Bridge 使 SVA/Checker 共享 `violation_ap`。

**Alternatives**：SVA 仅用 `$error`/native report（保持简单，但与 UVM 统计/RTM 脱节）。

**Impact**：需要 `axi4_assertion_bridge`（module + UVM 桥接），在含 `axi4_if` 实例的作用域实例化。

## ADR-007：Response Policy 独立组件

**Problem**：Slave 行为（响应状态/延迟/排序/背压）若散落在 driver/config，用户定制需 override driver，复用性差。

**Decision**：引入 `axi4_response_policy` 独立行为决策层；Config 只配置默认 policy；用户**替换 policy 而非 override driver**。

**Reason**：职责分离、可复用；Passive 模式可用 `axi4_response_predictor` 复用相同决策逻辑。

**Impact**：Slave 数据流为 Request → Slave Driver → Response Policy → Memory → Response；需新增 policy 类。

---

# 37. Architecture Constraints（必填）

* SystemVerilog / UVM 1.2；
* 禁止修改第三方 UVM；
* Public Object 使用 Factory 创建；
* Monitor 必须 passive（不驱动 DUT、不判断协议）；
* Config 不使用全局变量；
* Transaction 不直接依赖 Driver；
* Checker 不驱动 DUT；
* Coverage 不影响协议行为；
* 协议结构差异使用 config/enum/policy，不使用编译宏；
* 数据比较使用字段级 compare policy（不依赖裸 `uvm_object::compare()`）；
* 遵守 HWIF 契约唯一 SSOT。

---

# 38. Architecture Review Checklist（G1）（必填）

- [x] Profile 判断合理（FULL_UVM，理由充分）
- [x] 组件裁剪与 Profile 一致（对照 §4 组件矩阵）
- [x] 三大核心模型明确（Stimulus / Observation / Qualification）
- [x] 与 HWIF 契约一致（引用 `aixsilicon:hwif:axi`）
- [x] Monitor/Checker 职责分离（Observe vs Check）
- [x] 与 `docs/requirement.md` 能力覆盖一致（REQ-PRO/RUL/TRN/STM/VER/CFG/API/ENG/DBG/STA/REC/DEL/QLF）
- [x] 自包含依赖（不引入 tue/tvip-common）
- [x] 实现遵循架构 ADR 与 Constraints（无违反项）

### G1 运行时模型冻结（冻结后正式 G1 PASS）

- [ ] **Write AW/W/B Association Model 冻结**（§13.1：AW 建上下文 → W 按序归属 → WLAST → B 关联 → 发布）
- [ ] **Read AR/R Association Model 冻结**（§13.2：AR 建上下文 → R beat 归属 → RLAST → 完成）
- [ ] **Outstanding / Ordering Runtime Model 冻结**（§5.1 + §13：同 ID FIFO、跨 ID interleave、B/R 关联）
- [ ] **Monitor 与 Memory 完全解耦**（§14：Monitor 永不改 memory；memory 由 Behavior Subscriber / Slave Driver 更新）
- [ ] **Response Policy 机制冻结**（§20：`axi4_response_policy` 决策层 + 替换 policy）
- [ ] **Protocol Event Coverage 接入明确**（§18：temporal/event coverage 消费 `protocol_event_ap`）
- [ ] **SVA Violation Reporting 方案冻结**（§16/§17：Assertion Bridge → violation_ap 或 native report，二选一）
- [ ] **Reset ownership 明确**（§29：EXTERNAL / VIP_CONTROLLED，单一 owner，Passive 只观察）

---

# 39. Definition of Architecture Complete（必填）

架构完成判定：

| 项 | 状态 |
| --- | --- |
| Profile 与组件矩阵确定 | ✅ FULL_UVM |
| 三大模型定义 | ✅ |
| 接口契约（HWIF）确定 | ✅ |
| 组件职责与协作确定 | ✅ |
| Public API 确定 | ✅（REQ-API-001~013） |
| 依赖确定 | ✅（UVM + HWIF + 自包含） |
| REQ→组件映射 | ✅ |
| ADR 记录关键取舍 | ✅ |
| 约束明确 | ✅ |
| G1 Checklist 通过 | ⏳ 8 项运行时模型待冻结（§38）—— 冻结后正式 G1 PASS |

> 架构变更需更新本文件 + CHANGELOG，并同步 requirement/validation-plan。
