# AIXSILICON AXI4 VIP — Requirement Specification（需求规格）

> **Document ID**: `aixsilicon:vip:axi4:req` · 版本: 0.4.0-draft
> **VIP Name**: `axi4`
> **Category**: `amba`
> **Protocol / Interface**: AMBA AXI4 / AXI4-Lite（ARM IHI 0022E）
> **Target Version**: `1.0.0`
> **Profile**: `FULL_UVM`
> **Status**: `Draft`（G0 修订中）
> **Owner**: `<owner>`
> **Reference Specification**: ARM AMBA AXI4 协议（IHI 0022E），AXI4-Lite（IHI 0022E 附录）
> **HWIF Contract**: `aixsilicon:hwif:axi`（`IFC-AXI-001`，[`axi.interface.yaml`](../../../../../aixsilicon_hwif_repo/bus/axi/contract/axi.interface.yaml)）
> **Target VLNV**: `aixsilicon:vip:axi4:1.0.0`

> 参考实现: `repos/aixsilicon_vip_repo/reference/tvip-axi`（Apache-2.0，Taichi Ishitani）
> VIP Plan 条目: `repos/aixsilicon_vip_repo/registry.yaml` `VIP-001`（axi4，FULL_UVM，P0）

---

# 1. Overview

## 1.1 Purpose

本 VIP 用于验证 **AMBA AXI4 / AXI4-Lite** 协议，提供标准化、可复用的：

* 主动激励（Master / Slave）；
* 被动监控（PASSIVE）；
* 协议检查（Checker / SVA）；
* 功能覆盖（Coverage）；
* 错误注入（Violation Injector / Mutation）；
* 调试与统计（Debug / Statistics）；
* 与 UVM / SoC / IP 验证环境集成能力。

VIP 应能够作为独立验证资产被不同项目复用，不依赖具体 DUT 实现，供 `ip-development-suite` / `soc-integration-suite` 复用。

- **Profile**: `FULL_UVM`（AXI4 属复杂协议：5 通道握手、burst/outstanding/ID 排序/交织，需完整 agent/driver/monitor/sequencer/sequence 与 UVM RAL 集成）
- **VLNV**: `aixsilicon:vip:axi4:1.0.0`（目标发布版本）
- **依赖 HWIF**: `aixsilicon:hwif:axi`（`IFC-AXI-001`）—— 信号/宽度/方向/时序以 HWIF 契约为准，VIP 不重复定义接口契约
- **双 Protocol Profile**: 区分 `AXI4_FULL` 与 `AXI4_LITE` 两种能力剖面，以 `protocol` 配置选择（见 §2.2 与 §7）。

## 1.2 Scope

### In Scope

* AXI4（完整信号集）与 AXI4-Lite（能力剖面）；
* Master（initiator）激励 / Slave（target）响应 / Passive 监控；
* 主要协议能力：read/write/burst/outstanding/ID/backpressure/ordering/interleaving/exclusive；
* 数据传输结构：narrow / unaligned / WSTRB（partial & sparse）；
* 主要使用场景：IP 级协议验证、SoC 集成监控（PASSIVE）、寄存器访问（RAL）。

### Out of Scope

* AXI-Stream / ACE / ACE-Lite / CHI（另立 VIP-003/VIP-101/VIP-201）；
* **AXI3 兼容**：locked transaction、write-data interleaving（AXI4 已移除，不支持）；
* ATOP 原子操作驱动（V1.0 仅保留信号，V2.0 激活）；
* USER 边带信号随机驱动（V1.0 optional）。

## 1.3 Design Principles

1. **Protocol Correctness** —— 行为符合 ARM IHI 0022E 与 `requirement.md`。
2. **Reusable** —— 不绑定具体 DUT、项目或 Testbench。
3. **Configurable** —— 通过配置控制协议能力（profile/位宽/特性开关）与运行行为（延迟/背压/检查/覆盖）。
4. **Observable** —— 所有重要事务和状态可观察（observation stream / runtime status）。
5. **Checkable** —— 协议违规能够自动识别（Checker/SVA，结构化 Violation）。
6. **Extensible** —— 用户无需修改 VIP 源码即可定制行为（policy/callback/factory）。
7. **Debuggable** —— 提供足够的事务、错误和状态信息。
8. **Qualifiable** —— VIP 自身能力可系统化验证（Self-Test/RTM/Coverage/Mutation）。

## 1.4 文档分层原则

本规格是 **Requirement Specification**，只回答 **What**：

> VIP 必须提供什么能力、用户能够做什么、系统必须满足什么约束。

**How**（组件拆分、继承、内部队列、policy/callback 选型）属于 `architecture.md`；
**API 签名**（类/方法/参数/analysis port）属于 `api-reference.md`。
本规格中的组件名/配置字段名仅作**建议目标架构的指引**，不锁死实现。

## 1.5 需求分类模型（5 类）

| 类别 | 回答 | 本章 |
| --- | --- | --- |
| 1. Protocol Requirements | 协议能力（支持什么协议/事务/信号） | §2 |
| 2. Verification Capability Requirements | 激励 / Monitor / Checker / Coverage / Error Injection / 参考模型 | §3、§5 |
| 3. External Interface Requirements | 用户如何使用与集成 VIP（API/Observation/Config/Slave 定制/扩展/RAL/元数据） | §8（配置 §7） |
| 4. Engineering Requirements | Simulator / FuseSoC / Debug / Logging / Timeout / Statistics / Recording | §7、§13-18 |
| 5. Qualification Requirements | Self-test / Coverage / Mutation / Regression / Evidence | §22 |

---

# 2. Protocol Capability Requirements（Feature List，REQ-001 ~ REQ-009 + 扩展）

AXI4 能力以 **Feature Model** 组织：Feature → Requirement → Sequence → Monitor → Checker/SVA → Coverage → Self-Test → Mutation。

## 2.1 核心 Feature

| ID | Feature | 说明 | 参考实现 | 对应能力 |
| --- | --- | --- | --- | --- |
| AXI4-REQ-001 | 读事务（Read） | 支持 AR 通道发起读请求，R 通道接收数据/响应，支持读突发（burst） | `tvip_axi_master_read_sequence` | 主动激励 + 被动监控 |
| AXI4-REQ-002 | 写事务（Write） | 支持 AW/W 通道发起写请求与写数据，B 通道接收写响应 | `tvip_axi_master_write_sequence` | 主动激励 + 被动监控 |
| AXI4-REQ-003 | 突发类型（Burst Type） | 支持 FIXED / INCR / WRAP 三种突发类型（长度限制见 REQ-003A） | `tvip_axi_types_pkg`（burst type） | 主动激励 + 检查 |
| AXI4-REQ-003A | 突发长度（Burst Length） | 长度合法性：**INCR 1–256**；**FIXED 1–16**；**WRAP 仅 2/4/8/16**；AXI4-Lite 固定 len=0（1 beat） | `tvip_axi_types_pkg`（burst length） | 主动激励 + 检查 |
| AXI4-REQ-003B | 突发地址生成（Burst Address Generation） | 由 `AxADDR/AxSIZE/AxLEN/AxBURST` 计算每个 beat 的实际 byte address；正确处理 wrap boundary、narrow/unaligned 组合 | 新增（参考实现具备，本 VIP 显式建模） | 主动激励 + 检查 |
| AXI4-REQ-003C | 突发合法性（Burst Legality） | 检查：4KB 边界、WRAP 长度与 wrap boundary、AxSIZE 合法性（≤ DATA_W/8）、地址对齐/unaligned 规则、**禁止提前终止**、WLAST/RLAST 一致性 | 新增 | Checker/SVA |
| AXI4-REQ-004 | Outstanding（未完成请求） | 多笔未完成事务，Master 可重叠地址/数据，Slave 可延迟响应；配置细化见 REQ-046/0510 | `configuration.outstanding_responses` | 主动激励 + 检查 |
| AXI4-REQ-005 | ID 管理 | 可配置 ID 宽度（0–32 bit，AXI4-Lite 固定 0），支持多 ID 与 ID 排序 | `tvip_axi_configuration.id_width` | 主动激励 + 检查 |
| AXI4-REQ-006 | 背压（Backpressure） | Master/Slave 可配置握手通道（VALID/READY）默认值与延迟 | `default_*ready` + `*_ready_delay` | 主动激励 |
| AXI4-REQ-007 | 延迟写数据/写响应 | Slave 支持延迟写数据（gapped write data）与延迟响应 | `write_data_delay`、`response_delay`、`response_start_delay` | 主动激励 |
| AXI4-REQ-008 | 响应排序（in/out-of-order） | Slave 按 ID 的 in-order 与 out-of-order 响应 | `response_ordering` | 主动激励 + 检查 |
| AXI4-REQ-009 | 读交织（Read Interleave） | Slave 读数据交织（多 ID 交错返回） | `enable_response_interleaving`、`min/max_interleave_size` | 主动激励 + 检查 |

## 2.2 AXI4-Full 与 AXI4-Lite 能力剖面

AXI4 与 AXI4-Lite 是**两种能力剖面**，独立 Qualification 回归（`vip_tool regression --profile axi4 / --profile axi4lite`）：

| Capability | AXI4 Full | AXI4-Lite | 说明 |
| --- | :---: | :---: | --- |
| ID | ✅ | ❌ | Lite 无 ID（id_width=0） |
| Burst（INCR/FIXED/WRAP） | ✅ | ❌ | Lite 仅单 beat（len=0） |
| Outstanding | ✅ | 有限（≤1 pending） | Lite 每次仅一笔事务 |
| Exclusive Access | ✅ | ❌ | Lite 不支持 AxLOCK |
| QoS / Region | ✅ | ❌ | Lite 固定 qos=0、region=0 |
| Narrow / Unaligned | ✅ | 视实现 | Lite 允许 narrow/unaligned 写 |
| AxCACHE / AxPROT | ✅ | ✅（固定值） | Lite 信号存在但语义受限 |
| R / W | ✅ | ✅ | 均支持读/写 |

## 2.3 Feature 扩展（P0/P1 能力补齐）

| ID | Feature | 说明 | 对应能力 |
| --- | --- | --- | --- |
| AXI4-REQ-0100 | **Narrow Transfer** | 支持 `transfer_size < bus_width`（如 DATA_WIDTH=64、AWSIZE=2 → 每 beat 4B）。Master 产生、Slave 接收、Monitor 重建、Checker 检查 byte lane；Coverage 覆盖 `SIZE × BUS_WIDTH × BURST_TYPE`。理解 AxSIZE/WSTRB/AxADDR/byte lane 关系（lane 随地址与 burst 移动） | 激励 + 监控 + 检查 + 覆盖 |
| AXI4-REQ-0101 | **Unaligned Transfer** | 合法 unaligned 访问：unaligned read / write / unaligned+narrow / unaligned+INCR burst。首拍有效 byte lane、WSTRB 取值、地址推进；检查 WSTRB/byte lane、地址递增、4KB 边界 | 激励 + 监控 + 检查 |
| AXI4-REQ-0102 | **Write Strobe / Partial Write** | Master 生成合法 WSTRB（partial & sparse byte enable）；Slave memory model **仅更新 WSTRB=1 的 byte**；Checker 校验 WSTRB 不越界；Coverage 覆盖 full/partial/edge/sparse/narrow/unaligned strobe | 激励 + 参考模型 + 检查 + 覆盖 |
| AXI4-REQ-0103 | **Exclusive Access（独占访问）** | 使用 `AxLOCK`（EXCLUSIVE=1）表达独占访问：Master 发起 exclusive read/write，Slave memory 维护独占标记与同地址冲突检测，EXOKAY/OKAY 语义正确；配 `exclusive_support`（REQ-0511） | 激励 + 参考模型 + 检查 + 覆盖 |
| AXI4-REQ-0104 | **Sideband（AxCACHE/AxPROT/AxQOS/AxREGION/AxUSER）** | 边带信号 capability 模型（PRESENT/DRIVE/CHECK/COVERAGE，见 §2.4） | 激励 + 检查 + 覆盖 |
| AXI4-REQ-0105 | **Reset 中 outstanding 行为** | 复位对 outstanding 事务的影响：复位期间 VALID=0、握手终止、未响应事务丢失策略；复位释放无残留；Checker 校验复位无未完成握手 | 激励 + 检查 |

## 2.4 Sideband Capability 矩阵

| Signal | PRESENT | Random Drive | CHECK | Coverage | 备注 |
| --- | :---: | :---: | :---: | :---: | --- |
| AxCACHE | ✅ | ✅ | ✅ | ✅ | 合法编码检查（0011/0010/...） |
| AxPROT | ✅ | ✅ | ✅ | ✅ | 合法编码检查 |
| AxQOS | ✅ | ✅ | 基本合法性 | ✅ | 无协议非法值，做字段覆盖 |
| AxREGION | ✅ | ✅ | 基本合法性 | ✅ | 字段覆盖 |
| AxUSER | ✅ | 可选 | - | 可选 | V1.0 保留信号，optional drive |
| AWATOP | ✅ | V2.0 | V2.0 | V2.0 | V1.0 保留，置常量 |

> 该矩阵与 HWIF capability 对齐，可作为 HWIF 自动生成 capability matrix 的输入。

## 2.5 能力边界声明（Exclusive 与 Locked 分离）

| 能力 | 支持 | 说明 |
| --- | --- | --- |
| AXI4（完整信号集） | ✅ | 采用 HWIF 完整 AXI 信号：awvalid/awid/awaddr/awlen/awsize/awburst/awlock/awcache/awprot/awqos/awregion/awatop/awuser + w/b/ar/r |
| AXI4-Lite | ✅ | `protocol=AXI4_LITE` 剖面；无 ID、无 burst、固定 qos=0、无 exclusive |
| AXI-Stream / ACE / CHI | ❌ | 另立 VIP |
| **Exclusive Access** | ✅ V1.0 | 使用 `AxLOCK`（HWIF `awlock/arlock` required）；实现独占语义（REQ-0103/0115） |
| **AXI3 Locked Transaction** | ❌ | **AXI4 已移除 locked transactions**；`AxLOCK` 仅表达 exclusive access |
| Narrow Transfer | ✅ V1.0 | REQ-0100 |
| Unaligned Transfer | ✅ V1.0 | REQ-0101 |
| Write Strobe / Partial Write | ✅ V1.0 | REQ-0102 |
| **Write Data Interleaving（AXI3 WID）** | ❌ | AXI4 已移除；W 数据必须按 AW 顺序提供（REQ-0114） |
| Region | ✅ V1.0 | `awregion/arregion` required；驱动 + 基本检查 |
| ATOP | ⬜ 接口保留 | `awatop` capability；V1.0 置常量，V2.0 激活 |
| USER | ⬜ 接口保留 | `*user` capability；V1.0 optional drive |

> **HWIF 一致性说明**：tvip-axi 参考接口与 HWIF `IFC-AXI-001` 核心信号一致，但**缺 `awlock/arlock`、`awregion/arregion` 与 `awatop`/`*user`**。本 VIP 采用 HWIF 完整信号集，不得照搬 tvip-axi（见 §25）。

---

# 3. Protocol Rule Requirements（REQ-010 ~ REQ-019 + 扩展）

以下为必须被检查的协议规则（映射 Checker/SVA，见 RTM）。V1.0 目标 25~30 条规则。

## 3.1 基础规则

| ID | 规则 | 描述 | 对应检查 |
| --- | --- | --- | --- |
| AXI4-REQ-010 | VALID 不依赖 READY | VALID 拉高后保持到握手完成，不得等待 READY | CHK/SVA |
| AXI4-REQ-011 | 握手机制 | 仅当 VALID && READY 同时为高时传输发生；数据在握手沿采样 | CHK/SVA |
| AXI4-REQ-012 | 4KB 边界 | INCR/WRAP 突发不得跨越 4KB 地址边界 | CHK/SVA |
| AXI4-REQ-013 | 突发长度/大小合法 | ARLEN/AWLEN 符合 REQ-003A；ARSIZE/AWSIZE ≤ DATA_W/8；Lite 固定 len=0 | CHK/SVA |
| AXI4-REQ-014 | WLAST/RLAST | 最后一拍必须置 WLAST/RLAST，且与突发长度一致 | CHK/SVA |
| AXI4-REQ-015 | ID 排序 | in-order 下同 ID 响应/数据按请求顺序；out-of-order 仅不同 ID 可乱序 | CHK |
| AXI4-REQ-016 | 响应跟随请求 | B 响应在对应写事务（含所有 W 数据）之后；R 响应跟随 AR | CHK |
| AXI4-REQ-017 | 读数据顺序 | 单笔读事务内 R 数据顺序不可打乱；交织仅跨 ID | CHK |
| AXI4-REQ-018 | 复位行为 | 复位期间 VALID=0；复位释放后握手正常；无 outstanding 残留（配合 REQ-0105） | CHK/SVA |
| AXI4-REQ-019 | 响应编码 | BRESP/RRESP 合法（OKAY/EXOKAY/SLVERR/DECERR）；EXOKAY 仅用于 exclusive | CHK/SVA |

## 3.2 扩展规则（P0/P1）

| ID | 规则 | 描述 | 对应检查 |
| --- | --- | --- | --- |
| AXI4-REQ-0110 | **Payload Stability** | `VALID=1 && READY=0` 时各通道 payload 保持稳定（AW/W/AR/B/R 全通道） | SVA |
| AXI4-REQ-0111 | **Narrow Byte Lane** | narrow transfer 时有效 byte lane 由 AxADDR/AxSIZE 决定并随 burst 移动；不得越界 | CHK/SVA |
| AXI4-REQ-0112 | **WSTRB 合法性** | WSTRB 只置位当前 transfer 覆盖范围内的 byte lane | CHK/SVA |
| AXI4-REQ-0113 | **Unaligned 规则** | 首拍 lane/WSTRB/地址推进符合规范；unaligned+narrow+INCR 正确 | CHK |
| AXI4-REQ-0114 | **Write Data Ordering（negative rule）** | W 数据按 AW 事务顺序；**禁止 AXI3 式 write-data interleaving** | CHK |
| AXI4-REQ-0115 | **Exclusive 语义** | 独占 read 后同地址同 ID 独占 write 返回 EXOKAY；冲突/未配对处理 | CHK + 参考模型 |
| AXI4-REQ-0116 | **禁止提前终止** | burst 开始后不得提前终止（WLAST/RLAST 前不得结束） | SVA |

> 每条规则可映射 Checker/SVA，并进入 RTM 与 Mutation 目标清单。

---

# 4. Transaction Model Requirements（REQ-0106 ~ REQ-0107）

## 4.1 Field Classification（REQ-0106）

事务模型完整描述一笔 AXI 事务，字段分类：

```text
Request Fields    id / address / burst / len / size / memory_type / protection / qos / region / lock(exclusive) / strobe / data
Response Fields   response / response_data / status / error
Observation Fields  start_time / end_time / latency / channel_timestamp
Derived Fields    effective_address / total_bytes / aligned / boundary_crossing / transaction_class
```

## 4.2 Transaction Helper Capability（REQ-0107）

提供统一语义计算层，Driver、Monitor、Checker、Coverage 复用，不各自实现协议算法：

```text
is_legal() / is_aligned() / get_transfer_size() / get_effective_address() / get_payload_size()
get_transaction_length() / get_beat_address() / get_byte_lane() / check_boundary() / get_ordering_domain()
```

## 4.3 Constraint Model

定义"什么是合法 AXI transaction space"（配合 `constraint_mode` REQ-0513）：

| 模式 | 说明 |
| --- | --- |
| legal-only random | 合法空间内随机（address/id/burst/len/size/alignment/4KB/strobe/qos/cache/prot/region/response/delay） |
| directed | 定向构造（测试指定合法场景） |
| constraint override | 用户覆盖默认约束（`constraint_mode=DIRECTED`） |
| illegal generation | 关闭合法约束生成非法事务（配合 Violation Injector / Mutation） |

典型 illegal 场景：

```text
illegal_wrap_length      illegal_wstrb           cross_4kb
early_wlast              missing_wlast           unstable_awaddr
invalid_burst            unstable_awlen/size     invalid_id
```

---

# 5. Verification Capability Requirements（组件能力，REQ-020 ~ REQ-033）

本节定义 VIP 必须提供的**验证能力**。组件名/继承为**建议目标架构**（详见 `architecture.md`），需求层不锁死实现。

| ID | 能力 | 建议组件 | 需求说明 | 参考实现 |
| --- | --- | --- | --- | --- |
| AXI4-REQ-020 | 接口 interface | `axi4_if` | 5 通道**完整 AXI 信号**（无下划线命名）与 clocking block / modport（master/slave/monitor）；信号以 HWIF `IFC-AXI-001` 为唯一基准 | HWIF `axi_if` |
| AXI4-REQ-021 | 事务 transaction | `axi4_item` | 读/写访问描述（id/address/burst/len/size/memory_type/protection/qos/region/lock/strobe/data/response）；含窄/非对齐字段、时序事件；满足 §4 Transaction Model | `tvip_axi_item.svh`（补齐 strobe/lock/exclusive） |
| AXI4-REQ-022 | 配置 config | `axi4_configuration` | 统一配置接口，见 §7 与 §8 REQ-083 | `tvip_axi_configuration.svh` |
| AXI4-REQ-023 | Master Agent | `axi4_master_agent` | 组装 master sequencer/driver/monitor（写+读监控），ACTIVE/PASSIVE | `tvip_axi_master_agent.svh` |
| AXI4-REQ-024 | Slave Agent | `axi4_slave_agent` | 组装 slave sequencer/driver/monitor + data monitor，ACTIVE/PASSIVE | `tvip_axi_slave_agent.svh` |
| AXI4-REQ-025 | Sequencer | `axi4_master/slave_sequencer` | 标准 UVM sequencer 机制承载 sequence | `tvip_axi_*_sequencer.svh` |
| AXI4-REQ-026 | Driver | `axi4_master/slave_driver` | 按事务驱动接口信号；narrow/unaligned/WSTRB、延迟/排序/交织/exclusive | `tvip_axi_*_driver.svh`（补齐） |
| AXI4-REQ-027 | Monitor | `axi4_master/slave_monitor`（写/读分离） | 被动采样重建事务（Observation Model），正确处理 narrow/unaligned/byte lane，标准 analysis 发布（REQ-082） | `tvip_axi_*_monitor.svh` |
| AXI4-REQ-028 | Checker | `axi4_checker` | 协议规则检查（REQ-010~019 + 0110~0116），错误注入预期检测；AXI Ordering Model（§5.1）；结构化违规输出（REQ-087） | 新增 |
| AXI4-REQ-029 | 断言 SVA | `axi4_assertions` | 时序/握手/边界 SVA（payload stability、burst legality，可 bind interface） | 新增 |
| AXI4-REQ-030 | 覆盖模型 | `axi4_coverage` | 四层/五层覆盖（§10），含 SIZE×BUS_WIDTH×BURST、WSTRB 形态、exclusive 交叉 | 新增 |
| AXI4-REQ-031 | 存储模型 | `axi4_memory` | Slave 内存镜像；narrow/unaligned（仅更新 WSTRB=1 byte）、exclusive 独占标记与冲突检测；用户自定义（REQ-084） | `tvip_axi_memory.svh`（补齐） |
| AXI4-REQ-032 | 状态对象 | `axi4_status` | 运行时状态（memory 句柄、outstanding 计数 read/write/per-id）；支撑 REQ-088 | `tvip_axi_status.svh` |
| AXI4-REQ-033 | RAL 集成 | `axi4_ral_adapter/predictor` | UVM RAL **frontdoor access 与 prediction** 集成（能力要求 REQ-086） | `tvip_axi_ral_*.svh` |

## 5.1 AXI Ordering Model（排序模型）

Checker 内部维护按 ID 的排序模型：

```text
read_request_queue[ID]    write_request_queue[ID]
read_response_queue[ID]   write_response_queue[ID]
```

检查项：same-ID ordering、different-ID reordering、RID↔ARID、BID↔AWID、read interleaving、write response ordering、**write data ordering（REQ-0114）**。

---

# 6. Stimulus / Sequence Requirements（REQ-0108 ~ REQ-0109）

## 6.1 Primitive Operations（REQ-0108）

覆盖协议基本操作：`read`、`write`、`burst_read`、`burst_write`（对应高层 API，见 §8 REQ-081）。

## 6.2 Standard Sequences（REQ-0109）

提供典型场景 Sequence：`base` / `read` / `write` / `access` / `default` / `stress` / `error` / `reset`。

## 6.3 High-level Programmatic API

通过高层 API 完成基本激励，无需了解 Driver 内部实现（能力要求见 §8 REQ-081）；具体签名由 `api-reference.md` 定义。

---

# 7. Configuration Requirements（REQ-040 ~ REQ-059 + 扩展）

分层配置：system → agent → component，以统一 Configuration Interface 暴露（§8 REQ-083）。

## 7.1 协议与位宽

| ID | 配置项 | 类型/范围 | 默认 | 说明 |
| --- | --- | --- | --- | --- |
| AXI4-REQ-040 | `protocol` | `AXI4_FULL` / `AXI4_LITE` | AXI4_FULL | 能力剖面（§2.2） |
| AXI4-REQ-041 | `id_width` | 0–32 | 8 | ID 位宽（Lite 固定 0） |
| AXI4-REQ-042 | `address_width` | 1–64 | 32 | 地址位宽 |
| AXI4-REQ-043 | `data_width` | 8/16/32/64/128/256/512/1024 | 32 | 数据位宽（Lite 仅 32/64） |
| AXI4-REQ-044 | `max_burst_length` | 1–256 | 256 | 最大突发长度（按 REQ-003A；Lite 固定 1） |

## 7.2 行为特性

| ID | 配置项 | 类型/范围 | 默认 | 说明 |
| --- | --- | --- | --- | --- |
| AXI4-REQ-045 | `response_ordering` | IN_ORDER / OUT_OF_ORDER | OUT_OF_ORDER | Slave 响应排序 |
| AXI4-REQ-046 | `outstanding_responses` | ≥0 | 0 | 未完成响应数（0=不限制）；细化 REQ-0510 |
| AXI4-REQ-047 | `enable_response_interleaving` | 0/1 | 0 | 读交织使能 |
| AXI4-REQ-048 | `min/max_interleave_size` | ≥0 | 0/0 | 交织粒度 |
| AXI4-REQ-049 | `response_weight_*` | -1.. | -1 | 响应加权（OKAY/EXOKAY/SLVERR/DECERR） |

## 7.3 时序/背压

| ID | 配置项 | 类型 | 说明 |
| --- | --- | --- | --- |
| AXI4-REQ-050 | `request_start_delay` | delay_config | 请求开始延迟 |
| AXI4-REQ-051 | `write_data_delay` | delay_config | 写数据延迟（gapped） |
| AXI4-REQ-052 | `response_start_delay` / `response_delay` | delay_config | 响应延迟 |
| AXI4-REQ-053 | `default_*ready` + `*_ready_delay` | bit + delay_config | 各通道 READY 默认值与延迟（背压） |
| AXI4-REQ-054 | `reset_by_agent` | 0/1 | Agent 驱动复位 |

## 7.4 本 Suite 扩展开关

| ID | 配置项 | 说明 |
| --- | --- | --- |
| AXI4-REQ-055 | `enable_checker` | 协议检查使能（默认 1） |
| AXI4-REQ-056 | `enable_coverage` | 功能覆盖使能（默认 1） |
| AXI4-REQ-057 | `enable_error_injection` | 错误注入使能 |
| AXI4-REQ-058 | `transaction_log` | 事务日志开关与 verbosity |
| AXI4-REQ-059 | `agent_mode` | ACTIVE_MASTER / ACTIVE_SLAVE / PASSIVE / DISABLED |

## 7.5 扩展配置（P0/P1）

| ID | 配置项 | 说明 |
| --- | --- | --- |
| AXI4-REQ-0510 | `max_outstanding_read/write/per_id` | outstanding 细粒度上限 |
| AXI4-REQ-0511 | `exclusive_support` | Exclusive 使能（默认 1；Lite 强制 0） |
| AXI4-REQ-0512 | `drive_*_cache/prot/qos/region/user` | Sideband 随机驱动开关 |
| AXI4-REQ-0513 | `constraint_mode` | LEGAL_ONLY / DIRECTED / ILLEGAL（配合 Violation Injector，§4.3） |

---

# 8. External Interface / Public API Requirements（REQ-080 ~ REQ-092）

本节定义用户**如何使用与集成** VIP 的外部能力契约。**只约定能力，不规定 API 签名**。

| ID | 需求 | 说明 |
| --- | --- | --- |
| AXI4-REQ-080 | **Public API** | 稳定、文档化的公共调用接口；用户无需访问 Driver/Monitor/内部队列等实现细节 |
| AXI4-REQ-081 | **Programmatic Access** | 高层调用接口完成 `read`/`write`/`burst_read`/`burst_write`；同时支持标准 UVM Sequence |
| AXI4-REQ-082 | **Observation Interface** | 标准事务观察接口，供 Scoreboard/Coverage/性能分析订阅已重建 transaction |
| AXI4-REQ-083 | **Configuration Interface** | 统一配置接口（profile/位宽/outstanding/delay/backpressure/checker/coverage/error injection/debug）；预定义 Profile + override |
| AXI4-REQ-084 | **Slave Behavior Customization** | 用户自定义 memory content/response/delay/backpressure/error response，无需修改 VIP 源码 |
| AXI4-REQ-085 | **Extension Mechanism** | 非侵入式扩展（transaction/response/monitoring），不绑定具体机制（policy/callback/factory） |
| AXI4-REQ-086 | **RAL Integration** | UVM RAL frontdoor access 与 prediction 集成 |
| AXI4-REQ-087 | **Violation Interface** | 结构化违规报告（rule/severity/channel/time/transaction context），外部组件订阅，机器可读 |
| AXI4-REQ-088 | **Runtime Status** | 运行时状态查询：outstanding read/write、pending response、queue/activity、violation count |
| AXI4-REQ-089 | **Timeout Detection** | 可配置 transaction/channel timeout，检测无响应/deadlock/配置错误 |
| AXI4-REQ-090 | **Passive Analysis** | Passive 模式支持 transaction reconstruction/protocol checking/coverage/statistics（SoC 场景） |
| AXI4-REQ-091 | **Machine-readable Capability** | machine-readable metadata（protocol/profiles/agent modes/features/operations/config/sequences/coverage/limitations/version）供 VIP Repo/FuseSoC/Skill/AI Agent 消费 |
| AXI4-REQ-092 | **Compatibility** | 同 major 内 Public API backward compatible；破坏性变更升 major |

---

# 9. Reference / Behavior Model Requirements

## 9.1 Memory / Data Model（REQ-031）

Slave 存储模型能力：read/write/peek/poke/initialize/clear/load/partial update/error injection；**仅更新 WSTRB=1 的 byte**；exclusive 独占标记与冲突检测。

## 9.2 Response Model（REQ-084）

用户自定义：normal/error response、response latency、response ordering、address-dependent response，无需修改源码。

---

# 10. Coverage Requirements

Coverage 建立 **Coverage Model**（对应 REQ-030）。

## 10.1 Feature Coverage

所有 P0/P1 Feature（§2.1/§2.3）均有对应覆盖。

## 10.2 Field Coverage

覆盖关键字段：type、length、size、response、ID、attribute、WSTRB 形态。

## 10.3 Cross Coverage

关键维度交叉覆盖：

```text
SIZE × BUS_WIDTH × BURST_TYPE
TYPE × RESPONSE
LENGTH × SIZE
ID × ORDERING
ERROR × TRANSACTION
```

## 10.4 Scenario Coverage

basic、boundary、outstanding、backpressure、reset、error、concurrency、stress。

## 10.5 Protocol Rule Coverage

每条 Protocol Rule 证明：Checker exists、Checker exercised、Violation can be detected（配合 §11 Mutation）。

---

# 11. Error / Violation Injection Requirements

## 11.1 Violation Selection（REQ-057）

指定：violation type、channel、transaction type、filter、injection probability、injection count。

## 11.2 Mutation Targets（REQ-075）

每个高优先级 Protocol Rule 至少一个 Mutation/Violation Case 验证其检测能力（检测率 ≥95%）。

---

# 12. RAL / Model Integration Requirements

适用（寄存器类总线）：UVM RAL frontdoor access、adapter、predictor、monitor-based prediction、sequencer integration（REQ-033/086）。

---

# 13. Debug Requirements（REQ-064 ~ REQ-067）

| ID | 需求 | 说明 |
| --- | --- | --- |
| AXI4-REQ-064 | 事务日志 | 全字段 `convert2string`，verbosity 分级，含窄/非对齐/strobe/exclusive 字段 |
| AXI4-REQ-065 | 查询命令 | 运行时查询输出 outstanding 细粒度状态（REQ-088） |
| AXI4-REQ-066 | 错误分类 | 协议/环境/数据错误，`[REQ-xxx]` 定位 |
| AXI4-REQ-067 | 协议栈分层 | 事务级为主；复杂场景加 DataLink（交织/乱序）日志 |

---

# 14. Timeout / Deadlock Requirements

支持可配置（可关闭）：handshake/request/response/transaction timeout、potential deadlock 检测（REQ-089）。VIP 不因单一 DUT 异常无限等待导致 regression 无法结束。

---

# 15. Statistics / Performance Requirements（REQ-0117）

根据协议/Profile 支持：transaction count、bandwidth、latency、outstanding depth、retry count、backpressure cycles、utilization、response distribution、error statistics。统计数据通过标准接口查询。

---

# 16. Transaction Recording / Replay Requirements（REQ-0118）

## 16.1 Recording

可选 Transaction Recording，输出 UVM transaction DB / JSON / CSV 等结构化格式。

## 16.2 Replay

按已记录 transaction 重建激励；**V1.0 规划中（N/A），V2.0 支持**。

---

# 17. Machine-readable Capability Requirements

提供 machine-readable metadata（REQ-091），描述 protocol/profiles/agent modes/capabilities/operations/configuration/sequences/checker_rules/coverage/limitations/simulators/dependencies，供 VIP Repo/FuseSoC/Skill/AI Agent 消费。

---

# 18. Engineering / Integration Requirements（REQ-060 ~ REQ-063）

| ID | 需求 | 说明 |
| --- | --- | --- |
| AXI4-REQ-060 | 仿真器支持 | VCS（UVM 1.2，`-ntb_opts uvm-1.2`）；Xcelium/DSim 需验证 |
| AXI4-REQ-061 | 编译入口 | `Makefile`（vcs/xcelium 双入口）+ `filelist.f`；正式交付 FuseSoC `.core` |
| AXI4-REQ-062 | 回归分层 | smoke/feature/full（`vip_tool.py regression --tier`）；Profile 回归 `--profile axi4/axi4lite` |
| AXI4-REQ-063 | 回归记录 | 统一写入 `reports/quality/run_log.md`，与 Evidence Index 关联 |

UVM：UVM 1.2；SystemVerilog：标准；Build：filelist/Makefile/FuseSoC；Package：仅暴露 `axi4_pkg`/`axi4_if`（Public）。

---

# 19. Compatibility Requirements

Public API 遵循语义化版本兼容；同 major 内不得破坏 transaction/config/observation contract、public operations、interface parameters、public metadata（REQ-092）。

---

# 20. Deliverable Requirements（REQ-068 ~ REQ-070）

| ID | 需求 | 说明 |
| --- | --- | --- |
| AXI4-REQ-068 | 文档交付 | user-guide / configuration / architecture / limitation / api-reference |
| AXI4-REQ-069 | 示例与自验证 | `examples/` 最小 DUT + `self_test/`（smoke/feature/corner/error/random/stress） |
| AXI4-REQ-070 | 源码交付模式 | open（Apache-2.0 兼容） |

---

# 21. Self-Test Requirements

独立于真实 DUT 的 Self-Test，覆盖 smoke/feature/corner/error/random/stress/reset（REQ-069）。

---

# 22. Qualification Requirements（REQ-071 ~ REQ-076）

| ID | 需求 | 判定 |
| --- | --- | --- |
| AXI4-REQ-071 | 结构/元数据检查 | `vip_tool.py vip-check` PASS（G1/G2 前置） |
| AXI4-REQ-072 | 编译 | UVM 1.2 全工程编译 PASS |
| AXI4-REQ-073 | 自验证回归 | `vip_tool.py regression --tier full` PASS（G3） |
| AXI4-REQ-074 | 覆盖率闭合 | `vip_tool.py coverage-check` PASS（G4） |
| AXI4-REQ-075 | Mutation 检测率 | `vip_tool.py mutation-test` ≥ 阈值（G5） |
| AXI4-REQ-076 | FuseSoC Core 校验 | `vip_tool.py gen-core --check` PASS |

---

# 23. Limitations

| ID | Limitation | Planned Version |
| --- | --- | --- |
| LIM-001 | ATOP 原子操作仅保留信号，不驱动 | V2.0 |
| LIM-002 | USER 边带信号 optional drive | V2.0 |
| LIM-003 | Transaction Recording / Replay | V2.0 |
| LIM-004 | AXI3 兼容（locked / write-data interleaving）不支持 | N/A |
| LIM-005 | 仿真器：Xcelium / DSim 未实测 | 发布前验证 |

---

# 24. Requirement Priority

需求优先级定义：

```text
P0 — 发布阻塞，核心协议/基础能力
P1 — 标准版本应支持
P2 — 增强能力
P3 — Future
```

同时标记：`Required` / `Optional` / `N/A` / `Future`。
（V1.0 P0：REQ-001~009 + 0100~0105 + 协议规则；P1：0104/0110~0116/0510~0513 等。）

---

# 25. Requirement Traceability Matrix

完整追溯链由 `docs/rtm.md` 维护：

```text
Requirement → Implementation → Checker → Test → Coverage → Result
```

每条 REQ 关联 Impl/Checker/SVA/Test/Coverage/Mutation/Evidence（见 `docs/rtm.md`）。

---

# 26. G0 Requirement Review Checklist

进入 Architecture / Implementation 前确认：

### Protocol

* [x] 协议版本明确（AXI4，IHI 0022E）
* [x] Profile 明确（FULL_UVM；AXI4_FULL/AXI4_LITE 双剖面）
* [x] Feature List 完整（REQ-001~009 + 003A/B/C + 0100~0105）
* [x] Protocol Rule 完整（REQ-010~019 + 0110~0116）
* [x] Sideband / Optional Feature 边界明确（§2.4 能力矩阵）
* [x] Reset 行为明确（REQ-0105/018）
* [x] Unsupported Feature 明确（AXI3 locked/write-interleave/ATOP/USER）

### Verification Capability

* [x] Active / Passive Role 明确（REQ-023/024/090）
* [x] Driver / Monitor / Checker / Assertion 能力明确（REQ-026~029）
* [x] Coverage Model 明确（§10 五层）
* [x] Error Injection 明确（REQ-057 + §11）
* [x] Self-Test 明确（REQ-069 + §21）

### External Interface

* [x] DUT Connection Contract 明确（REQ-020/082）
* [x] Configuration / Stimulus / Observation / Violation / Status API 能力明确（REQ-080~088）
* [x] Extension Mechanism 明确（REQ-085）

### Engineering

* [x] Simulator / UVM / Build Interface 明确（REQ-060~062）
* [x] Package / Dependency / FuseSoC 明确（§18）

### Quality

* [x] Debug / Timeout 能力明确（REQ-064~067/089）
* [x] Requirement Traceability / Qualification Gate / Limitation / Compatibility Policy 明确（§22-25）
* [x] 与 HWIF Contract 一致（信号/宽度/方向/时序以 HWIF 为唯一 SSOT，不重复定义；见 §25/§27）

---

# 27. Requirement Completion Definition

当以下五个问题全部可以明确回答时，AXI4 VIP Requirement 完整：

### 1. 协议上，它支持什么？

```text
AXI4 / AXI4-Lite 能力剖面；read/write/burst/outstanding/ID/exclusive/narrow/unaligned/WSTRB ...
```

### 2. 验证上，它能做什么？

```text
Stimulus（Master/Slave/Sequence） + Monitor（重建） + Checker/SVA（协议规则） + Coverage + Error Injection
```

### 3. 用户怎么使用它？

```text
Public API（REQ-080~085）+ Configuration（REQ-083）+ Sequence / High-level Operation + Extension
```

### 4. 工程上，它怎么进入项目？

```text
Simulator（VCS）+ Build（filelist/Makefile/FuseSoC）+ Repository + Metadata（REQ-091）
```

### 5. 如何证明 VIP 自己是正确的？

```text
Self-Test + RTM + Coverage + Mutation + Regression + Qualification（REQ-071~076）
```

---

# 附录 A. Requirement ID 索引

| 分组 | 编号范围 | 数量 |
| --- | --- | --- |
| Protocol —— Feature List（核心） | AXI4-REQ-001 ~ 009（含 003A/B/C） | 12 |
| Protocol —— Feature 扩展（P0/P1） | AXI4-REQ-0100 ~ 0105 | 6 |
| Transaction Model | AXI4-REQ-0106 ~ 0107 | 2 |
| Stimulus / Sequence | AXI4-REQ-0108 ~ 0109 | 2 |
| Protocol Rules（基础） | AXI4-REQ-010 ~ 019 | 10 |
| Protocol Rules（扩展） | AXI4-REQ-0110 ~ 0116 | 7 |
| Verification —— 组件能力 | AXI4-REQ-020 ~ 033 | 14 |
| Configuration（基础） | AXI4-REQ-040 ~ 059 | 20 |
| Configuration（扩展） | AXI4-REQ-0510 ~ 0513 | 4 |
| External Interface | AXI4-REQ-080 ~ 092 | 13 |
| Engineering —— 运行环境 | AXI4-REQ-060 ~ 063 | 4 |
| Engineering —— 可调试性 | AXI4-REQ-064 ~ 067 | 4 |
| Engineering —— Statistics | AXI4-REQ-0117 | 1 |
| Engineering —— Recording/Replay | AXI4-REQ-0118 | 1 |
| Delivery | AXI4-REQ-068 ~ 070 | 3 |
| Qualification | AXI4-REQ-071 ~ 076 | 6 |

> 编号一经发布不得重用；废弃需求标记 `deprecated` 而非删除。

---

# 附录 B. 与 HWIF 契约一致性（G0 检查）

- VIP 接口信号集合、方向、位宽以 `aixsilicon:hwif:axi`（`IFC-AXI-001`）为**唯一基准**；
- 依赖 HWIF 的 `aw`/`w`/`b`/`ar`/`r` 五通道定义与 `resp_encoding`、`burst_types`、`transfer` 语义；
- **命名规范**：AXI 标准命名（无下划线，如 `awvalid`/`awlock`/`awregion`/`awuser`），与 HWIF 契约及 `axi_if` 一致；
- **接口信号**：`axi4_if` 采用 HWIF **完整信号集**，含必选 `awlock/arlock`（用于 **exclusive**）、`awregion/arregion` 与 capability `awatop`/`*user`；
- **Exclusive 语义**：`awlock/arlock=1` 表达 **exclusive access**（REQ-0103/0115），**不表达** AXI3 式 locked transaction；
- tvip-axi 参考接口仅核心信号与 HWIF 一致，**不得直接照搬**（缺 lock/region/atop/user、narrow/unaligned/strobe 语义）；
- VIP **不重复定义**接口契约；HWIF 契约变更 → 本需求同步更新 + CHANGELOG 记录。
