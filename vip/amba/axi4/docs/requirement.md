# AIXSILICON AXI4 VIP — Requirement Specification（需求规格）

> **Document ID**: `aixsilicon:vip:axi4:req` · 版本: 1.0.0-g0-baseline
> **VIP Name**: `axi4`
> **Category**: `amba`
> **Protocol / Interface**: AMBA AXI4 / AXI4-Lite（ARM IHI 0022E）
> **Target Version**: `1.0.0`
> **Profile**: `FULL_UVM`
> **Status**: `G0 PASS / Requirement Freeze`（baseline：协议能力 + 验证能力 + 外部契约 + 工程质量；模型细节下沉 Architecture）
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
* 数据传输结构：narrow / unaligned / WSTRB（partial & sparse & zero-strobe）；
* 主要使用场景：IP 级协议验证、SoC 集成监控（PASSIVE）、寄存器访问（RAL）。

### Out of Scope

* AXI-Stream / ACE / ACE-Lite / CHI（另立 VIP-003/VIP-101/VIP-201）；
* **AXI3 兼容**：locked transaction、write-data interleaving（AXI4 已移除，不支持）；
* **ATOP 原子操作**（AXI5 / AMBA 5 Atomic 扩展）：本 VIP 为 AXI4 定位，**不支持也不激活** ATOP；
* **USER 边带信号随机驱动**（V1.0 optional）。

## 1.3 Design Principles

1. **Protocol Correctness** —— 行为符合 ARM IHI 0022E 与 `requirement.md`。
2. **Reusable** —— 不绑定具体 DUT、项目或 Testbench。
3. **Configurable** —— 通过配置控制协议能力（profile/位宽/特性开关）与运行行为（延迟/背压/检查/覆盖）。
4. **Observable** —— 所有重要事务、通道事件和状态可观察（observation stream / runtime status）。
5. **Checkable** —— 协议违规能够自动识别（Checker/SVA，结构化 Violation）。
6. **Extensible** —— 用户无需修改 VIP 源码即可定制行为（policy/callback/factory）。
7. **Debuggable** —— 提供足够的事务、通道、beat 和错误信息。
8. **Qualifiable** —— VIP 自身能力可系统化验证（Self-Test/RTM/Coverage/Mutation）。

## 1.4 文档分层原则

本规格是 **Requirement Specification**，只回答 **What**：

> VIP 必须提供什么能力、用户能够做什么、系统必须满足什么约束。

**How**（组件拆分、继承、内部队列、policy/callback 选型、exclusive monitor 内部状态、event stream 结构）
属于 `architecture.md`；
**API 签名**（类/方法/参数/analysis port）属于 `user-guide.md`（API Reference，方案 A）。
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

# 2. Protocol Capability Requirements（Feature List，REQ-PRO-001 ~ REQ-PRO-021）

AXI4 能力以 **Feature Model** 组织：Feature → Requirement → Sequence → Monitor → Checker/SVA → Coverage → Self-Test → Mutation。

## 2.1 核心 Feature

| ID | Feature | 说明 | 参考实现 | 对应能力 |
| --- | --- | --- | --- | --- |
| AXI4-REQ-PRO-001 | 读事务（Read） | 支持 AR 通道发起读请求，R 通道接收数据/响应，支持读突发（burst） | `tvip_axi_master_read_sequence` | 主动激励 + 被动监控 |
| AXI4-REQ-PRO-002 | 写事务（Write） | 支持 AW/W 通道发起写请求与写数据，B 通道接收写响应 | `tvip_axi_master_write_sequence` | 主动激励 + 被动监控 |
| AXI4-REQ-PRO-003 | 突发类型（Burst Type） | 支持 FIXED / INCR / WRAP 三种突发类型（长度限制见 REQ-PRO-004） | `tvip_axi_types_pkg`（burst type） | 主动激励 + 检查 |
| AXI4-REQ-PRO-004 | 突发长度（Burst Length） | 长度合法性：**INCR 1–256**；**FIXED 1–16**；**WRAP 仅 2/4/8/16**；AXI4-Lite 固定 len=0（1 beat） | `tvip_axi_types_pkg`（burst length） | 主动激励 + 检查 |
| AXI4-REQ-PRO-005 | 突发地址生成（Burst Address Generation） | 由 `AxADDR/AxSIZE/AxLEN/AxBURST` 计算每个 beat 的实际 byte address；正确处理 wrap boundary、narrow/unaligned 组合 | 新增（参考实现具备，本 VIP 显式建模） | 主动激励 + 检查 |
| AXI4-REQ-PRO-006 | 突发合法性（Burst Legality） | 检查：4KB 边界、WRAP 长度与 wrap boundary、AxSIZE 合法性（≤ DATA_W/8）、地址对齐/unaligned 规则、**禁止提前终止**、WLAST/RLAST 一致性 | 新增 | Checker/SVA |
| AXI4-REQ-PRO-007 | Outstanding（未完成请求） | 多笔未完成事务，Master 可重叠地址/数据，Slave 可延迟响应；配置细化见 REQ-CFG-007/CFG-021 | `configuration.outstanding_responses` | 主动激励 + 检查 |
| AXI4-REQ-PRO-008 | ID 管理 | 可配置 ID 宽度（0–32 bit，AXI4-Lite 固定 0），支持多 ID 与 ID 排序 | `tvip_axi_configuration.id_width` | 主动激励 + 检查 |
| AXI4-REQ-PRO-009 | 背压（Backpressure） | Master/Slave 可配置握手通道（VALID/READY）默认值与延迟 | `default_*ready` + `*_ready_delay` | 主动激励 |
| AXI4-REQ-PRO-010 | **Channel Timing / Response Delay** | 通道时序与响应延迟：Master 侧 request/data gap（如 W 数据延迟、gapped write data）；Slave 侧 response delay 与 backpressure（WREADY 控制接受节奏）。Master 驱动与 Slave 背压分开描述 | `write_data_delay`、`response_delay`、`response_start_delay` | 主动激励 |
| AXI4-REQ-PRO-011 | 响应排序（in/out-of-order） | Slave 按 ID 的 in-order 与 out-of-order 响应 | `response_ordering` | 主动激励 + 检查 |
| AXI4-REQ-PRO-012 | 读交织（Read Interleave） | Slave 读数据交织（多 ID 交错返回） | `enable_response_interleaving`、`min/max_interleave_size` | 主动激励 + 检查 |

## 2.2 AXI4-Full 与 AXI4-Lite 能力剖面

AXI4 与 AXI4-Lite 是**两种能力剖面**，独立 Qualification 回归（`vip_tool regression --profile axi4 / --profile axi4lite`）。

> **协议事实（Signal presence vs Semantic default）**：AXI4-Lite 标准接口信号集合精简（`AWADDR/AWPROT/WDATA/WSTRB/BRESP` 与 `ARADDR/ARPROT/RDATA/RRESP`），
> **不含** `AxCACHE/AxLOCK/AxLEN/AxSIZE/AxBURST/AxQOS/AxREGION/ID`。AXI4-Lite 事务固定单 beat、使用完整数据总线宽度（32/64 bit）、**无 AxSIZE 故无 Narrow Transfer**。
> `AxCACHE` 在 Lite 语义为固定默认（Non-modifiable / Non-bufferable），不代表接口上存在可驱动的 Lite 信号。
> 下表区分 **Signal presence** 与 **Semantic default**（对应 §2.4 PRESENT/DRIVE/CHECK 模型）。

| Capability | AXI4 Full | AXI4-Lite | 说明 |
| --- | :---: | :---: | --- |
| ID | ✅ | ❌ | Lite 无 ID（id_width=0） |
| Burst（INCR/FIXED/WRAP） | ✅ | ❌ | Lite 仅单 beat（len=0）；不提供 AxSIZE/AxBURST/AxLEN 信号 |
| Multiple Outstanding | ✅ | ✅（无 ID-based reordering） | Lite 可配置 outstanding depth，但无 ID 故不支持 ID-based reordering |
| Out-of-order（不同 ID） | ✅ | ❌ | Lite 仅 in-order |
| Exclusive Access | ✅ | ❌ | Lite 不支持 AxLOCK |
| Narrow Transfer（AxSIZE < bus width） | ✅ | ❌ | Lite 使用完整数据总线宽度；**narrow ≠ partial write** |
| Unaligned Address | ✅ | ✅ | Lite 允许 unaligned（低 bit 地址参与 byte lane 选择） |
| Partial Write / WSTRB | ✅ | ✅ | Lite 用 WSTRB 控制实际写入 byte |
| Zero-strobe Write（WSTRB==0） | ✅ | ✅ | WSTRB 可全 0：memory 不更新、事务按协议完成（REQ-PRO-015） |
| AxPROT | ✅ | ✅ | Lite 支持 AxPROT |
| AxCACHE（signal presence） | ✅ | ❌ | Lite 无 AxCACHE 信号；语义固定 Non-modifiable / Non-bufferable |
| Cache semantics | ✅ | 固定默认 | Lite 视为固定 Non-modifiable / Non-bufferable |
| AxQOS | ✅ | ❌ | Lite 无信号；固定 qos=0 |
| AxREGION | ✅ | ❌ | Lite 无信号；固定 region=0 |
| R / W | ✅ | ✅ | 均支持读/写 |

> **V1.0 实现限制**：Lite profile 下 VIP 默认/限制为 **1 outstanding**（属于 Implementation Profile / Limitation，非协议能力）——见 §23 LIM-006。

## 2.3 Feature 扩展（P0/P1 能力补齐）

| ID | Feature | 说明 | 对应能力 |
| --- | --- | --- | --- |
| AXI4-REQ-PRO-013 | **Narrow Transfer** | 支持 `transfer_size < bus_width`（如 DATA_WIDTH=64、AWSIZE=2 → 每 beat 4B）。Master 产生、Slave 接收、Monitor 重建、Checker 检查 byte lane；Coverage 覆盖 `SIZE × BUS_WIDTH × BURST_TYPE`。理解 AxSIZE/WSTRB/AxADDR/byte lane 关系（lane 随地址与 burst 移动） | 激励 + 监控 + 检查 + 覆盖 |
| AXI4-REQ-PRO-014 | **Unaligned Transfer** | 合法 unaligned 访问：unaligned read / write / unaligned+narrow / unaligned+INCR burst。首拍有效 byte lane、WSTRB 取值、地址推进；检查 WSTRB/byte lane、地址递增、4KB 边界 | 激励 + 监控 + 检查 |
| AXI4-REQ-PRO-015 | **Write Strobe / Partial Write（含 Zero-strobe）** | Master 生成合法 WSTRB（partial & sparse byte enable）；Slave memory model **仅更新 WSTRB=1 的 byte**；Checker 校验 WSTRB 不越界；Coverage 覆盖 full/partial/edge/sparse/narrow/unaligned strobe。**含 Zero-strobe write（WSTRB==0）**：不要求 WSTRB 至少一个 bit=1，`WSTRB='0` 时 memory 不更新、事务仍按协议完成 | 激励 + 参考模型 + 检查 + 覆盖 |
| AXI4-REQ-PRO-016 | **Exclusive Access（独占访问）** | 使用 `AxLOCK`（EXCLUSIVE=1）表达独占访问；按 ARM exclusive access 规则维护 exclusive monitor（REQ-RUL-016 详述） | 激励 + 参考模型 + 检查 + 覆盖 |
| AXI4-REQ-PRO-017 | **Sideband（AxCACHE/AxPROT/AxQOS/AxREGION/AxUSER）** | 边带信号 capability 模型（PRESENT/DRIVE/CHECK/COVERAGE，见 §2.4） | 激励 + 检查 + 覆盖 |
| AXI4-REQ-PRO-018 | **Reset 中 VIP 行为** | VIP 内部状态处理：复位期间 VALID=0（协议规则见 REQ-RUL-009）、握手终止、未响应事务丢弃策略、checker 状态清空；复位释放无残留（确定性恢复） | 激励 + 检查 |
| AXI4-REQ-PRO-019 | **Write Address/Data Decoupling（AW/W 解耦）** | AW 与 W 是**独立通道**：支持 AW before W、W before AW、AW∥W same-cycle，以及多笔写事务下合法的 AW/W association。Driver/Slave Monitor 必须正确重建该解耦关系 | 激励 + 监控 + 检查 |
| AXI4-REQ-PRO-020 | **Handshake Pattern（握手形态）** | 激励能力：产生/响应 READY-before-VALID、VALID-before-READY、same-cycle handshake，以及持续/间歇 backpressure 等合法握手形态（激励能力，不强制 DUT 行为） | 激励 + 检查 |
| AXI4-REQ-PRO-021 | **Address / Byte-Lane Model** | VIP 必须支持完整 Address/Byte-Lane 语义：aligned / unaligned / narrow / unaligned+narrow / INCR/FIXED/WRAP byte lanes / WSTRB lane legality（详细计算能力见 REQ-TRN-002，此处不重复展开） | 激励 + 监控 + 检查 + 覆盖 |

## 2.4 Sideband Capability 矩阵

| Signal | PRESENT | Random Drive | CHECK | Coverage | 备注 |
| --- | :---: | :---: | :---: | :---: | --- |
| AxCACHE | ✅ | ✅ | ✅ | ✅ | 合法编码检查（0011/0010/...） |
| AxPROT | ✅ | ✅ | ✅ | ✅ | 合法编码检查 |
| AxQOS | ✅ | ✅ | 基本合法性 | ✅ | 无协议非法值，做字段覆盖 |
| AxREGION | ✅ | ✅ | 基本合法性 | ✅ | 字段覆盖 |
| AxUSER | ✅ | 可选 | - | 可选 | V1.0 保留信号，optional drive |
| AWATOP | ⬜ superset 保留 | ❌ | ❌ | ❌ | **AXI5/AMBA5 Atomic 扩展，非 AXI4 capability**；AXI4 profile 下驱动/钳位为非原子值，不激活 |

> 该矩阵与 HWIF capability 对齐，可作为 HWIF 自动生成 capability matrix 的输入。
> **AWATOP 定位**：HWIF 可作为统一接口 superset 保留 `awatop` 信号；本 AXI4 VIP **不把 ATOP 当作 AXI4 capability**，
> 在 AXI4 profile 下将其驱动/钳位为非原子值（不激活）。原子事务支持不在 AXI4 V1.0 范围内（见 §23 LIM-001）。

## 2.5 能力边界声明（Exclusive 与 Locked 分离 + ATOP 边界）

| 能力 | 支持 | 说明 |
| --- | --- | --- |
| AXI4（完整信号集） | ✅ | 采用 HWIF 完整 AXI 信号：awvalid/awid/awaddr/awlen/awsize/awburst/awlock/awcache/awprot/awqos/awregion/awuser + w/b/ar/r（awatop 为 superset 保留，AXI4 profile 置非原子值） |
| AXI4-Lite | ✅ | `protocol=AXI4_LITE` 剖面；精简信号集（§2.2）；无 ID、无 burst、无 exclusive、AxCACHE 固定默认 |
| AXI-Stream / ACE / CHI | ❌ | 另立 VIP |
| **Exclusive Access** | ✅ V1.0 | 使用 `AxLOCK`（HWIF `awlock/arlock` required）；按 ARM exclusive monitor 规则（REQ-RUL-016 详述） |
| **AXI3 Locked Transaction** | ❌ | **AXI4 已移除 locked transactions**；`AxLOCK` 仅表达 exclusive access |
| Narrow Transfer | ✅ V1.0 | REQ-PRO-013 |
| Unaligned Transfer | ✅ V1.0 | REQ-PRO-014 |
| Write Strobe / Partial Write（含 Zero-strobe） | ✅ V1.0 | REQ-PRO-015 |
| **Write Data Interleaving（AXI3 WID）** | ❌ | AXI4 已移除；W 数据必须按 AW 事务顺序提供（REQ-RUL-015） |
| Write Address/Data Decoupling | ✅ V1.0 | AW/W 独立通道（REQ-PRO-019） |
| Handshake Pattern | ✅ V1.0 | READY-before/VALID-before/same-cycle（REQ-PRO-020） |
| Address / Byte-Lane Model | ✅ V1.0 | aligned/unaligned/narrow/lane（REQ-PRO-021） |
| Region | ✅ V1.0 | `awregion/arregion` required；驱动 + 基本检查 |
| **ATOP（AXI5 Atomic）** | ❌ V1.0（superset 保留） | `awatop` 为 HWIF superset 信号；AXI4 profile 驱动/钳位为非原子值，**不激活**（非 AXI4 capability） |
| USER | ⬜ 接口保留 | `*user` capability；V1.0 optional drive |

> **HWIF 一致性说明**：tvip-axi 参考接口与 HWIF `IFC-AXI-001` 核心信号一致，但**缺 `awlock/arlock`、`awregion/arregion` 与 `awatop`/`*user`**。本 VIP 采用 HWIF 完整信号集，不得照搬 tvip-axi（见附录 B）。
> **产品边界**：本 VIP 为 **AXI4 / AXI4-Lite**（IHI 0022E）定位；AXI5 / AMBA5 Atomic（AWATOP）不在 AXI4 V1.0 范围内。

---

# 3. Protocol Rule Requirements（REQ-RUL-001 ~ REQ-RUL-017）

以下为必须被检查的协议规则（映射 Checker/SVA，见 RTM）。

## 3.1 基础规则

| ID | 规则 | 描述 | 对应检查 |
| --- | --- | --- | --- |
| AXI4-REQ-RUL-001 | VALID 生成独立性 + 保持（stability） | ① **VALID assertion 不得依赖 READY**（VALID 拉高不等待 READY）；② **一旦 VALID 断言，保持到握手完成**；③ payload 在 stalled 期间保持稳定（对应 REQ-RUL-011）。三条子语义分别映射 Checker/SVA 与 Mutation | CHK/SVA |
| AXI4-REQ-RUL-002 | 握手机制 | 仅当 VALID && READY 同时为高时传输发生；数据在握手沿采样 | CHK/SVA |
| AXI4-REQ-RUL-003 | 4KB 边界 | INCR/WRAP 突发不得跨越 4KB 地址边界 | CHK/SVA |
| AXI4-REQ-RUL-004 | 突发长度/大小合法 | ARLEN/AWLEN 符合 REQ-PRO-004；ARSIZE/AWSIZE ≤ DATA_W/8；Lite 固定 len=0 | CHK/SVA |
| AXI4-REQ-RUL-005 | WLAST/RLAST | 最后一拍必须置 WLAST/RLAST，且与突发长度一致 | CHK/SVA |
| AXI4-REQ-RUL-006 | ID 排序 | in-order 下同 ID 响应/数据按请求顺序；out-of-order 仅不同 ID 可乱序 | CHK |
| AXI4-REQ-RUL-007 | 响应跟随请求 | B 响应在对应写事务（含所有 W 数据）之后；R 响应跟随 AR | CHK |
| AXI4-REQ-RUL-008 | 读数据顺序 | 单笔读事务内 R 数据顺序不可打乱；交织仅跨 ID | CHK |
| AXI4-REQ-RUL-009 | 复位行为（协议规则） | 复位断言期间相应 VALID 输出满足协议 reset requirements（VALID=0） | CHK/SVA |
| AXI4-REQ-RUL-010 | 响应编码 | BRESP/RRESP 合法（OKAY/EXOKAY/SLVERR/DECERR）；EXOKAY 仅用于 exclusive | CHK/SVA |

## 3.2 扩展规则（P0/P1）

| ID | 规则 | 描述 | 对应检查 |
| --- | --- | --- | --- |
| AXI4-REQ-RUL-011 | **Payload Stability** | `VALID=1 && READY=0` 时各通道 payload 保持稳定（AW/W/AR/B/R 全通道） | SVA |
| AXI4-REQ-RUL-012 | **Narrow Byte Lane** | narrow transfer 时有效 byte lane 由 AxADDR/AxSIZE 决定并随 burst 移动；不得越界 | CHK/SVA |
| AXI4-REQ-RUL-013 | **WSTRB 合法性** | WSTRB 只置位当前 transfer 覆盖范围内的 byte lane（含 WSTRB==0 合法场景） | CHK/SVA |
| AXI4-REQ-RUL-014 | **Unaligned 规则** | 首拍 lane/WSTRB/地址推进符合规范；unaligned+narrow+INCR 正确 | CHK |
| AXI4-REQ-RUL-015 | **Write Data Ordering（negative rule）** | W 数据按 AW 事务顺序；**禁止 AXI3 式 write-data interleaving**；与 REQ-PRO-019（AW/W 解耦）配合 | CHK |
| AXI4-REQ-RUL-016 | **Exclusive Access Semantics** | VIP 必须按照 AXI4 exclusive-access 规则维护 exclusive transaction association，检查 exclusive read/write 的 **ID、地址范围及相关 transaction attributes（size/len/burst）匹配关系**、exclusive monitor **建立/失效（invalidation）**行为，以及 **EXOKAY/OKAY response semantics**（exclusive write 成功返回 EXOKAY；monitor 失效导致失败时返回 OKAY 且不更新 slave memory）。具体内部模型（monitor[ID]/address range/size/len/burst/invalidation）下沉 `architecture.md` | CHK + 参考模型 |
| AXI4-REQ-RUL-017 | **禁止提前终止（burst 完整性）** | 已发出的 burst 必须完成 `AxLEN+1` 个 data transfer；不得通过提前拉 WLAST/RLAST 或停止后续 beat 的方式缩短 burst | SVA |

> 每条规则可映射 Checker/SVA，并进入 RTM 与 Mutation 目标清单（REQ-QLF-005）。

---

# 4. Transaction Model Requirements（REQ-TRN-001 ~ REQ-TRN-003）

## 4.1 Field Classification（REQ-TRN-001）

事务模型完整描述一笔 AXI 事务，字段分类：

```text
Request Fields    id / address / burst / len / size / memory_type / protection / qos / region / lock(exclusive) / strobe / data
Response Fields   response / response_data / status / error
Observation Fields  start_time / end_time / latency / channel_timestamp
Derived Fields    effective_address / total_bytes / aligned / boundary_crossing / transaction_class
```

## 4.2 Transaction Helper Capability（REQ-TRN-002）

提供**统一语义计算能力**（aligned/byte-lane/beat address/4KB/ordering 等），Driver、Monitor、Checker、Coverage 复用，不各自实现协议算法：

```text
is_legal() / is_aligned() / get_transfer_size() / get_effective_address() / get_payload_size()
get_transaction_length() / get_beat_address() / get_byte_lane() / check_boundary() / get_ordering_domain()
```

> Address/Byte-Lane 计算细节收敛于此（REQ-PRO-021 只声明能力、§4.2A 引用，不再重复展开）。

> **实现方法**（如 `convert2string`、具体方法签名）属 `architecture.md`；本规格只约定**能力**（结构化、verbosity 可调的文本表示等）。

## 4.2A Address / Byte-Lane Model（REQ-PRO-021）

为 Transaction Semantic Model 的正式子能力，**由 Semantic Helper（REQ-TRN-002）统一计算**；
Driver/Monitor/Checker/Coverage 复用，不各自实现。能力范围（aligned/unaligned/narrow/INCR/FIXED/WRAP lane/WSTRB legality）见 REQ-PRO-021。

## 4.3 Protocol Event Observation（REQ-TRN-003）

完整 transaction 不能描述全部 AXI 时序行为（如 W before AW、READY before VALID、stall 若干拍、R interleave switching point）。
VIP 必须能够**观察并结构化表示关键 channel-level protocol event**，至少包括：

```text
AW handshake
W handshake
B handshake
AR handshake
R handshake
reset
stall/backpressure
```

供 Checker / Scenario Coverage / Statistics / Debug 消费。event stream 结构（如 `protocol_event_ap`）下沉 `architecture.md`。

## 4.4 Constraint Model

定义"什么是合法 AXI transaction space"（配合 `random_constraint_mode` REQ-CFG-024）。明确**两层错误生成机制**，职责不重叠：

### A. Illegal Transaction Generation（事务层非法字段）

产生 transaction-layer illegal fields（由随机约束/非法生成实现）：

```text
illegal length
illegal burst
cross 4KB
illegal WSTRB
```

### B. Protocol Violation Injection（信号/时序违规）

制造 signal/timing violation（由 Violation Injector 实现，不能靠 transaction randomization）：

```text
VALID drops before handshake
payload changes while stalled
early WLAST
response without request
```

| 模式 | 说明 |
| --- | --- |
| legal-only random | 合法空间内随机（address/id/burst/len/size/alignment/4KB/strobe/qos/cache/prot/region/response/delay） |
| directed | 定向构造（测试指定合法场景） |
| constraint override | 用户覆盖默认约束（`random_constraint_mode=DIRECTED`） |
| illegal generation | 关闭合法约束生成非法事务（配合 Illegal Transaction Generator） |

---

# 5. Verification Capability Requirements（组件能力，REQ-VER-001 ~ REQ-VER-014）

本节定义 VIP 必须提供的**验证能力**。组件名/继承为**建议目标架构**（详见 `architecture.md`），需求层不锁死实现。

| ID | 能力 | 建议组件 | 需求说明 | 参考实现 |
| --- | --- | --- | --- | --- |
| AXI4-REQ-VER-001 | 接口 interface | `axi4_if` | 5 通道**完整 AXI 信号**（无下划线命名）与 clocking block / modport（master/slave/monitor）；信号以 HWIF `IFC-AXI-001` 为唯一基准 | HWIF `axi_if` |
| AXI4-REQ-VER-002 | 事务 transaction | `axi4_item` | 读/写访问描述（id/address/burst/len/size/memory_type/protection/qos/region/lock/strobe/data/response）；含窄/非对齐字段、时序事件；满足 §4 Transaction Model | `tvip_axi_item.svh`（补齐 strobe/lock/exclusive） |
| AXI4-REQ-VER-003 | 配置 config | `axi4_configuration` | 统一配置接口，见 §7 与 §8 REQ-API-004 | `tvip_axi_configuration.svh` |
| AXI4-REQ-VER-004 | Master Agent | `axi4_master_agent` | 组装 master sequencer/driver/monitor（写+读监控），ACTIVE/PASSIVE | `tvip_axi_master_agent.svh` |
| AXI4-REQ-VER-005 | Slave Agent | `axi4_slave_agent` | 组装 slave target driver、protocol monitor 及 behavior model integration，ACTIVE/PASSIVE；是否含专项 data monitor 由 Architecture 决定 | `tvip_axi_slave_agent.svh` |
| AXI4-REQ-VER-006 | Sequencer | `axi4_master/slave_sequencer` | 标准 UVM sequencer 机制承载 sequence | `tvip_axi_*_sequencer.svh` |
| AXI4-REQ-VER-007 | Driver | `axi4_master/slave_driver` | 按事务驱动接口信号；narrow/unaligned/WSTRB、延迟/排序/交织/exclusive；支持 AW/W 解耦（PRO-019）与握手形态（PRO-020） | `tvip_axi_*_driver.svh`（补齐） |
| AXI4-REQ-VER-008 | Monitor | `axi4_master/slave_monitor`（写/读分离） | 被动采样重建事务（Observation Model），正确处理 narrow/unaligned/byte lane、AW/W 解耦，标准 analysis 发布（REQ-API-003） | `tvip_axi_*_monitor.svh` |
| AXI4-REQ-VER-009 | Checker | `axi4_checker` | 协议规则检查（REQ-RUL-001~RUL-017），错误注入预期检测；AXI Ordering Model（§5.1）；结构化违规输出（REQ-API-008） | 新增 |
| AXI4-REQ-VER-010 | 断言 SVA | `axi4_assertions` | 时序/握手/边界 SVA（payload stability、burst legality，可 bind interface） | 新增 |
| AXI4-REQ-VER-011 | 覆盖模型 | `axi4_coverage` | 四层/五层覆盖（§10），含 SIZE×BUS_WIDTH×BURST、WSTRB 形态、exclusive 交叉、temporal/event 覆盖 | 新增 |
| AXI4-REQ-VER-012 | 存储模型 | `axi4_memory` | Slave 内存镜像；narrow/unaligned（仅更新 WSTRB=1 byte，含 Zero-strobe）、exclusive 独占标记与冲突检测；用户自定义（REQ-API-005） | `tvip_axi_memory.svh`（补齐） |
| AXI4-REQ-VER-013 | 状态对象 | `axi4_status` | 运行时状态（memory 句柄、outstanding 计数 read/write/per-id）；支撑 REQ-API-009 | `tvip_axi_status.svh` |
| AXI4-REQ-VER-014 | RAL 集成 | `axi4_ral_adapter/predictor` | UVM RAL **frontdoor access 与 prediction** 集成（能力要求 REQ-API-007） | `tvip_axi_ral_*.svh` |

## 5.1 AXI Ordering Model（排序模型）

VIP 必须建立能够检查以下行为的 Ordering Model（实现细节——按 ID 的队列结构——见 `architecture.md` §5.1）：

```text
same-ID ordering
different-ID reordering
response association（RID↔ARID、BID↔AWID）
read interleaving（跨 ID）
write response ordering
write data ordering（REQ-RUL-015）
```

---

# 6. Stimulus / Sequence Requirements（REQ-STM-001 ~ REQ-STM-002）

## 6.1 Primitive Operations（REQ-STM-001）

覆盖协议基本操作：`read`、`write`、`burst_read`、`burst_write`（对应高层 API，见 §8 REQ-API-002）。

## 6.2 Standard Sequences（REQ-STM-002）

提供典型场景 Sequence：`base` / `read` / `write` / `access` / `default` / `stress` / `error` / `reset`。

## 6.3 High-level Programmatic API

通过高层 API 完成基本激励，无需了解 Driver 内部实现（能力要求见 §8 REQ-API-002）；具体签名由 `user-guide.md`（API Reference）定义。

---

# 7. Configuration Requirements（REQ-CFG-001 ~ REQ-CFG-024）

分层配置：system → agent → component，以统一 Configuration Interface 暴露（§8 REQ-API-004）。

## 7.1 协议与位宽

| ID | 配置项 | 类型/范围 | 默认 | 说明 |
| --- | --- | --- | --- | --- |
| AXI4-REQ-CFG-001 | `protocol` | `AXI4_FULL` / `AXI4_LITE` | AXI4_FULL | 能力剖面（§2.2） |
| AXI4-REQ-CFG-002 | `id_width` | 0–32 | 8 | ID 位宽（Lite 固定 0） |
| AXI4-REQ-CFG-003 | `address_width` | 1–64 | 32 | 地址位宽 |
| AXI4-REQ-CFG-004 | `data_width` | 8/16/32/64/128/256/512/1024 | 32 | 数据位宽（Lite 仅 32/64） |
| AXI4-REQ-CFG-005 | `max_burst_length` | 1–256 | 256 | 最大突发长度（按 REQ-PRO-004；Lite 固定 1） |

## 7.2 行为特性

| ID | 配置项 | 类型/范围 | 默认 | 说明 |
| --- | --- | --- | --- | --- |
| AXI4-REQ-CFG-006 | `response_ordering` | IN_ORDER / OUT_OF_ORDER | **IN_ORDER** | Slave 响应排序；默认 IN_ORDER（deterministic + simplest legal，便于 bring-up），需 stress 时再配 OUT_OF_ORDER（STRESS/ORDERING profile） |
| AXI4-REQ-CFG-007 | `outstanding_responses` | ≥0 | 0 | **deprecated**：未完成响应数总上限（0=不限制）。细粒度限制以 REQ-CFG-021（`max_outstanding_read/write/per_id`）为准；两者同时设置时以 CFG-021 细粒度为准，CFG-007 仅作 compatibility alias |
| AXI4-REQ-CFG-008 | `enable_response_interleaving` | 0/1 | 0 | 读交织使能 |
| AXI4-REQ-CFG-009 | `min/max_interleave_size` | ≥0 | 0/0 | 交织粒度 |
| AXI4-REQ-CFG-010 | `response_weight_*` | -1.. | -1 | 响应加权（OKAY/EXOKAY/SLVERR/DECERR） |

## 7.3 时序/背压

| ID | 配置项 | 类型 | 说明 |
| --- | --- | --- | --- |
| AXI4-REQ-CFG-011 | `request_start_delay` | delay_config | 请求开始延迟 |
| AXI4-REQ-CFG-012 | `write_data_delay` | delay_config | 写数据延迟（gapped） |
| AXI4-REQ-CFG-013 | `response_start_delay` / `response_delay` | delay_config | 响应延迟 |
| AXI4-REQ-CFG-014 | `default_*ready` + `*_ready_delay` | bit + delay_config | 各通道 READY 默认值与延迟（背压；支持 READY-before/VALID-before/same-cycle 形态，PRO-020） |
| AXI4-REQ-CFG-015 | `reset_by_agent` | 0/1 | Agent 驱动复位 |

## 7.4 本 Suite 扩展开关

| ID | 配置项 | 说明 |
| --- | --- | --- |
| AXI4-REQ-CFG-016 | `enable_checker` | 协议检查使能（默认 1） |
| AXI4-REQ-CFG-017 | `enable_coverage` | 功能覆盖使能（默认 1） |
| AXI4-REQ-CFG-018 | `enable_error_injection` | 错误注入使能 |
| AXI4-REQ-CFG-019 | `transaction_log` | 事务日志开关与 verbosity |
| AXI4-REQ-CFG-020 | `agent_mode` | ACTIVE_MASTER / ACTIVE_SLAVE / PASSIVE / DISABLED |

## 7.5 扩展配置（P0/P1）

| ID | 配置项 | 说明 |
| --- | --- | --- |
| AXI4-REQ-CFG-021 | `max_outstanding_read/write/per_id` | outstanding 细粒度上限 |
| AXI4-REQ-CFG-022 | `exclusive_support` | Exclusive 使能（默认 1；Lite 强制 0） |
| AXI4-REQ-CFG-023 | `drive_*_cache/prot/qos/region/user` | Sideband 随机驱动开关 |
| AXI4-REQ-CFG-024 | `random_constraint_mode` | LEGAL_ONLY / DIRECTED / ILLEGAL（配合 §4.4 两层错误生成）。**注**：字段名避免用 `constraint_mode`（UVM `uvm_object::constraint_mode()` 内置方法冲突），实现用 `random_constraint_mode` |

---

# 8. External Interface / Public API Requirements（REQ-API-001 ~ REQ-API-013）

本节定义用户**如何使用与集成** VIP 的外部能力契约。**只约定能力，不规定 API 签名**。

| ID | 需求 | 说明 |
| --- | --- | --- |
| AXI4-REQ-API-001 | **Public API** | 稳定、文档化的公共调用接口；用户无需访问 Driver/Monitor/内部队列等实现细节 |
| AXI4-REQ-API-002 | **Programmatic Access** | 高层调用接口完成 `read`/`write`/`burst_read`/`burst_write`；同时支持标准 UVM Sequence |
| AXI4-REQ-API-003 | **Observation Interface** | 标准事务观察接口，供 Scoreboard/Coverage/性能分析订阅已重建 transaction；**至少支持 completed transaction observation**；对 channel/timing-level 能力，可提供 **protocol-event observation**（对应 REQ-TRN-003） |
| AXI4-REQ-API-004 | **Configuration Interface** | 统一配置接口（profile/位宽/outstanding/delay/backpressure/checker/coverage/error injection/debug）；预定义 Profile + override |
| AXI4-REQ-API-005 | **Slave Behavior Customization** | 用户自定义 memory content/response/delay/backpressure/error response，无需修改 VIP 源码 |
| AXI4-REQ-API-006 | **Extension Mechanism** | 非侵入式扩展（transaction/response/monitoring），不绑定具体机制（policy/callback/factory） |
| AXI4-REQ-API-007 | **RAL Integration** | UVM RAL frontdoor access 与 prediction 集成 |
| AXI4-REQ-API-008 | **Violation Interface** | 结构化违规报告（rule/severity/channel/time/transaction context），外部组件订阅，机器可读 |
| AXI4-REQ-API-009 | **Runtime Status** | 运行时状态查询：outstanding read/write、pending response、queue/activity、violation count |
| AXI4-REQ-API-010 | **Timeout Detection** | 可配置 transaction/channel timeout，检测无响应/deadlock/配置错误 |
| AXI4-REQ-API-011 | **Passive Analysis** | Passive 模式支持 transaction reconstruction/protocol checking/coverage/statistics（SoC 场景） |
| AXI4-REQ-API-012 | **Machine-readable Capability** | machine-readable metadata（protocol/profiles/agent modes/features/operations/config/sequences/coverage/limitations/version）供 VIP Repo/FuseSoC/Skill/AI Agent 消费 |
| AXI4-REQ-API-013 | **Compatibility** | 同 major 内 Public API backward compatible；破坏性变更升 major |

---

# 9. Reference / Behavior Model Requirements

## 9.1 Memory / Data Model（REQ-VER-012）

Slave 存储模型能力：read/write/peek/poke/initialize/clear/load/partial update/error injection；**仅更新 WSTRB=1 的 byte**（WSTRB='0 时不更新、事务照常完成，REQ-PRO-015）；exclusive 独占标记与冲突检测（REQ-RUL-016）。

## 9.2 Response Model（REQ-API-005）

用户自定义：normal/error response、response latency、response ordering、address-dependent response，无需修改源码。

---

# 10. Coverage Requirements

Coverage 建立 **Coverage Model**（对应 REQ-VER-011）。

## 10.1 Feature Coverage

所有 P0/P1 Feature（§2.1/§2.3）均有对应覆盖。

## 10.2 Field Coverage

覆盖关键字段：type、length、size、response、ID、attribute、WSTRB 形态（full/partial/edge/sparse/zero）。

## 10.3 Cross Coverage

关键维度交叉覆盖：

```text
SIZE × BUS_WIDTH × BURST_TYPE
TYPE × RESPONSE
LENGTH × SIZE
ID × ORDERING
ERROR × TRANSACTION
```

## 10.4 Scenario Coverage（含 Temporal / Event Coverage）

basic、boundary、outstanding、backpressure、reset、error、concurrency、stress。

Scenario/Temporal Coverage 明确包含（利用 REQ-TRN-003 Protocol Event Model）：

```text
AW before W
W before AW
same-cycle AW/W
READY before VALID
VALID before READY
stall length
outstanding depth
interleave switching
```

## 10.5 Protocol Rule Coverage

每条 Protocol Rule 证明：Checker exists、Checker exercised、Violation can be detected（配合 §11 Mutation）。

## 10.6 Coverage 闭合指标（区分两类指标）

**不要混为一谈：**

### A. Requirement / Feature Exercise（必须）

```text
P0  = 100%
P1 Required = 100%
```

这是"每条 P0/P1 Feature 被 Self-Test/Regression 实际触发"的硬指标。

### B. Functional Coverage Bin（阈值，非强制 100%）

```text
Functional Coverage ≥ 阈值（如 90%）
```

允许存在 `legal-but-unreachable configuration cross`、`excluded profile`、`optional feature combination`
等不要求 100% 的 bin；闭合判定基于 RTM + 覆盖率报告，非"所有 bin 100%"。

---

# 11. Error / Violation Injection Requirements

## 11.1 Violation Selection（REQ-CFG-018）

指定：violation type、channel、transaction type、filter、injection probability、injection count。
区分两类错误生成（§4.4）：**Illegal Transaction Generation**（事务层非法字段）与 **Protocol Violation Injection**（信号/时序违规）。

## 11.2 Mutation Targets（REQ-QLF-005）

- 每个高优先级 Protocol Rule 至少一个 Mutation/Violation Case 验证其检测能力；
- **Overall mutation detection ≥ 95%**；
- **同时所有 P0 Protocol Rule 的 mandatory mutation 必须 100% detected**（防止"漏掉关键规则但总体 ≥95%"的假通过）。

---

# 12. RAL / Model Integration Requirements

适用（寄存器类总线）：UVM RAL frontdoor access、adapter、predictor、monitor-based prediction、sequencer integration（REQ-VER-014 / REQ-API-007）。

---

# 13. Debug Requirements（REQ-DBG-001 ~ REQ-DBG-004）

| ID | 需求 | 说明 |
| --- | --- | --- |
| AXI4-REQ-DBG-001 | 事务日志 | Transaction 必须支持**完整、结构化、verbosity 可控的文本表示**（实现可用 `convert2string`），含窄/非对齐/strobe/exclusive 字段 |
| AXI4-REQ-DBG-002 | 查询命令 | 运行时查询输出 outstanding 细粒度状态（REQ-API-009） |
| AXI4-REQ-DBG-003 | 错误分类 | 协议/环境/数据错误，`[REQ-xxx]` 定位 |
| AXI4-REQ-DBG-004 | 日志分层 | 支持 **Transaction / Channel / Beat 三层日志**；默认 Transaction Level，复杂 ordering/interleaving/debug 时启用 Channel/Beat Level |

---

# 14. Timeout / Deadlock Requirements

支持可配置（可关闭）：handshake/request/response/transaction timeout、potential deadlock 检测（REQ-API-010）。VIP 不因单一 DUT 异常无限等待导致 regression 无法结束。

---

# 15. Statistics / Performance Requirements（REQ-STA-001）

根据协议/Profile 支持（AXI-specific，**无 retry count**——AXI 响应仅 OKAY/EXOKAY/SLVERR/DECERR，无 AHB/SPLIT/RETRY）：

```text
transaction count
bandwidth
latency
outstanding depth
backpressure cycles
channel utilization
response distribution
exclusive success/failure
protocol violation count
timeout count
```

统计数据通过标准接口查询。

---

# 16. Transaction Recording / Replay Requirements（REQ-REC-001）

## 16.1 Recording

可选 Transaction Recording，输出 UVM transaction DB / JSON / CSV 等结构化格式。

## 16.2 Replay

按已记录 transaction 重建激励；**V1.0 规划中（N/A），V2.0 支持**。

---

# 17. Machine-readable Capability Requirements

提供 machine-readable metadata（REQ-API-012），描述 protocol/profiles/agent modes/capabilities/operations/configuration/sequences/checker_rules/coverage/limitations/simulators/dependencies，供 VIP Repo/FuseSoC/Skill/AI Agent 消费。metadata 逐条携带 Priority/Status/Target/Profile 字段（见 §24）。

---

# 18. Engineering / Integration Requirements（REQ-ENG-001 ~ REQ-ENG-004）

| ID | 需求 | 说明 |
| --- | --- | --- |
| AXI4-REQ-ENG-001 | 仿真器支持 | VCS（UVM 1.2，`-ntb_opts uvm-1.2`）；Xcelium/DSim 需验证 |
| AXI4-REQ-ENG-002 | 编译入口 | `Makefile`（vcs/xcelium 双入口）+ `filelist.f`；正式交付 FuseSoC `.core` |
| AXI4-REQ-ENG-003 | 回归分层 | smoke/feature/full（`vip_tool.py regression --tier`）；Profile 回归 `--profile axi4/axi4lite` |
| AXI4-REQ-ENG-004 | 回归记录 | 统一写入 `reports/run_log.md`，与 Evidence Index 关联 |

UVM：UVM 1.2；SystemVerilog：标准；Build：filelist/Makefile/FuseSoC；Package：仅暴露 `axi4_pkg`/`axi4_if`（Public）。

---

# 19. Compatibility Requirements

Public API 遵循语义化版本兼容；同 major 内不得破坏 transaction/config/observation contract、public operations、interface parameters、public metadata（REQ-API-013）。

---

# 20. Deliverable Requirements（REQ-DEL-001 ~ REQ-DEL-003）

| ID | 需求 | 说明 |
| --- | --- | --- |
| AXI4-REQ-DEL-001 | 文档交付 | user-guide（含 API Reference）/ configuration / architecture / limitation |
| AXI4-REQ-DEL-002 | 示例与自验证 | `examples/` 最小 DUT + `self_test/`（smoke/feature/corner/error/random/stress） |
| AXI4-REQ-DEL-003 | 源码交付模式 | open（Apache-2.0 兼容） |

---

# 21. Self-Test Requirements

独立于真实 DUT 的 Self-Test，覆盖 smoke/feature/corner/error/random/stress/reset（REQ-DEL-002）。

---

# 22. Qualification Requirements（REQ-QLF-001 ~ REQ-QLF-006）

| ID | 需求 | 判定 |
| --- | --- | --- |
| AXI4-REQ-QLF-001 | 结构/元数据检查 | `vip_tool.py vip-check` PASS（G1/G2 前置） |
| AXI4-REQ-QLF-002 | 编译 | UVM 1.2 全工程编译 PASS |
| AXI4-REQ-QLF-003 | 自验证回归 | `vip_tool.py regression --tier full` PASS（G3） |
| AXI4-REQ-QLF-004 | 覆盖率闭合 | `vip_tool.py coverage-check` PASS（G4） |
| AXI4-REQ-QLF-005 | Mutation 检测率 | `vip_tool.py mutation-test`：总体 ≥95% + P0 mandatory 100%（G5） |
| AXI4-REQ-QLF-006 | FuseSoC Core 校验 | `vip_tool.py gen-core --check` PASS |

---

# 23. Limitations

| ID | Limitation | Planned Version |
| --- | --- | --- |
| LIM-001 | ATOP 原子操作（AXI5/AMBA5）不在 AXI4 范围；`awatop` superset 信号在 AXI4 profile 下钳位非原子值 | N/A（AXI4 定位） |
| LIM-002 | USER 边带信号 optional drive | V2.0 |
| LIM-003 | Transaction Recording / Replay | V2.0 |
| LIM-004 | AXI3 兼容（locked / write-data interleaving）不支持 | N/A |
| LIM-005 | 仿真器：Xcelium / DSim 未实测 | 发布前验证 |
| LIM-006 | AXI4-Lite max outstanding = 1（Implementation Profile，非协议能力） | **Current: V1.0；Planned Removal: V1.x / V2.0** |
| LIM-007 | **E2 unstable payload（RUL-011 SVA）未检出**：注入翻转发生在 W stalled 期，master/slave clocking 沿错位使 SVA 窗口未命中；且 stall 窗依赖 slave FIXED=2 未保证触发 | G4 统一采样沿（`@(posedge vif.aclk)` 顶层信号）+ 确定性 stall |
| LIM-008 | **C3 W-before-AW 解耦（PRO-019）回环断言未接入**：slave 预收线程与 master clocking 采样错位 → 预收漏采（驱动实现保留，验证 NOT_RUN）；outstanding 读异步化/多 ID 乱序交织完整并发未验证 | G4 per-beat 所有权仲裁 + 独立 PR（读路径异步化） |

> **架构边界（设计决策，非缺陷）**：monitor 不直接更新 memory（§14 冻结）；
> W 无 ID 按到达顺序归属；RAL adapter 单拍（burst_length=1，符合 VER-014）。
> 架构边界详见 architecture.md，不计入 LIM。

---

# 24. Requirement Priority（逐条字段化）

需求优先级定义：

```text
P0 — 发布阻塞，核心协议/基础能力
P1 — 标准版本应支持
P2 — 增强能力
P3 — Future
```

同时标记：`Required` / `Optional` / `N/A` / `Future`。

> **字段化规则**：每条 Requirement 在 RTM/metadata 中携带 `Priority / Status / Target Release / Profile` 字段。
> 优先级的**逐条指派**见下方表格（机器生成 RTM / metadata 的依据）；实现时各 Requirement 表可追加对应列或并入 metadata。

### Priority 指派（V1.0 基准）

| ID 范围 | 类别 | Priority | Status | Target | Profile |
| --- | --- | :---: | --- | --- | --- |
| REQ-PRO-001 ~ PRO-012 | 核心 Feature | P0 | Required | 1.0 | FULL/LITE |
| REQ-PRO-013 ~ PRO-018 | Feature 扩展（基础） | P0 | Required | 1.0 | FULL |
| REQ-PRO-019 | AW/W Decoupling | **P0** | Required | 1.0 | FULL |
| REQ-PRO-020 | Handshake Pattern | **P1** | Required | 1.0 | FULL |
| REQ-PRO-021 | Byte-Lane Model | **P0** | Required | 1.0 | FULL |
| REQ-RUL-001 ~ RUL-010 | Protocol Rules（基础） | P0 | Required | 1.0 | FULL/LITE |
| REQ-RUL-011 | Payload Stability | **P0** | Required | 1.0 | FULL/LITE |
| REQ-RUL-012 ~ RUL-017 | Protocol Rules（扩展） | P1 | Required | 1.0 | FULL |
| REQ-TRN-001 ~ TRN-003 | Transaction Model（含 Protocol Event） | P0 | Required | 1.0 | FULL/LITE |
| REQ-STM-001 ~ STM-002 | Stimulus / Sequence | P0 | Required | 1.0 | FULL/LITE |
| REQ-VER-001 ~ VER-013 | Verification 组件 | P0 | Required | 1.0 | FULL/LITE |
| REQ-VER-014 | RAL 集成 | **P1** | Required | 1.0 | FULL |
| REQ-CFG-001 ~ CFG-020 | Configuration（基础） | P0 | Required | 1.0 | FULL/LITE |
| REQ-CFG-021 ~ CFG-024 | Configuration（扩展） | P1 | Required | 1.0 | FULL |
| REQ-API-001 ~ API-005 | Public/Programmatic/Observation/Config/Slave 定制 | P0 | Required | 1.0 | FULL/LITE |
| REQ-API-008 / API-011 / API-012 | Violation / Passive / Metadata | P0 | Required | 1.0 | FULL/LITE |
| REQ-API-006 / API-007 / API-009 / API-010 / API-013 | Extension / RAL / Runtime / Timeout / Compatibility | **P1** | Required | 1.0 | FULL |
| REQ-DBG-001 ~ DBG-004 | Debug | P1 | Required | 1.0 | FULL/LITE |
| REQ-STA-001 | Statistics | P2 | Optional | 1.0 | FULL |
| REQ-REC-001 | Recording / Replay | P3 | Future | 2.0 | FULL |
| REQ-ENG-001 ~ ENG-004 | Engineering | P0 | Required | 1.0 | FULL/LITE |
| REQ-DEL-001 ~ DEL-003 | Deliverable | P0 | Required | 1.0 | FULL/LITE |
| REQ-QLF-001 ~ QLF-006 | Qualification | P0 | Required | 1.0 | FULL/LITE |

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
* [x] Feature List 完整（REQ-PRO-001~PRO-021）
* [x] Protocol Rule 完整（REQ-RUL-001~RUL-017）
* [x] Sideband / Optional Feature 边界明确（§2.4 能力矩阵）
* [x] Reset 行为明确（协议规则 REQ-RUL-009 + VIP 行为 REQ-PRO-018）
* [x] Unsupported Feature 明确（AXI3 locked/write-interleave/ATOP/USER）
* [x] **AXI4-Lite capability matrix 修正**（§2.2：Narrow vs Partial Write、AxCACHE/QOS/REGION signal vs semantic、outstanding 实现策略）
* [x] **Exclusive semantics 精炼**（REQ-PRO-016 + REQ-RUL-016）
* [x] **AW/W Decoupling 明确**（REQ-PRO-019）

### Verification Capability

* [x] Active / Passive Role 明确（REQ-VER-004/VER-005/API-011）
* [x] Driver / Monitor / Checker / Assertion 能力明确（REQ-VER-007~VER-010）
* [x] Coverage Model 明确（§10，含 Temporal/Event）
* [x] Error Injection 明确（REQ-CFG-018 + §11 两层模型）
* [x] Self-Test 明确（REQ-DEL-002 + §21）

### External Interface

* [x] DUT Connection Contract 明确（REQ-VER-001/API-003）
* [x] Configuration / Stimulus / Observation / Violation / Status API 能力明确（REQ-API-001~API-009）
* [x] Extension Mechanism 明确（REQ-API-006）

### Engineering

* [x] Simulator / UVM / Build Interface 明确（REQ-ENG-001~ENG-003）
* [x] Package / Dependency / FuseSoC 明确（§18）

### Quality

* [x] Debug / Timeout 能力明确（REQ-DBG-001~DBG-004/API-010）
* [x] Requirement Traceability / Qualification Gate / Limitation / Compatibility Policy 明确（§22-25）
* [x] 与 HWIF Contract 一致（信号/宽度/方向/时序以 HWIF 为唯一 SSOT，不重复定义；见附录 B）
* [x] **Requirement ID 局部编号完成**（AXI4-REQ-<CAT>-<NNN>，附录 A/C）
* [x] **P0/P1 冲突消除**（§24 逐条字段化）
* [x] **Required/Optional/Future 字段化**（§24 + §17 metadata）
* [x] **How 下沉 Architecture**（§5.1 Ordering Model、§4.3 Event Model、exclusive monitor 内部模型、convert2string 表述）

---

# 27. Requirement Completion Definition

当以下五个问题全部可以明确回答时，AXI4 VIP Requirement 完整：

### 1. 协议上，它支持什么？

```text
AXI4 / AXI4-Lite 能力剖面；read/write/burst/outstanding/ID/exclusive/narrow/unaligned/WSTRB/AW/W 解耦/握手形态 ...
```

### 2. 验证上，它能做什么？

```text
Stimulus（Master/Slave/Sequence） + Monitor（重建） + Checker/SVA（协议规则） + Coverage + Error Injection
```

### 3. 用户怎么使用它？

```text
Public API（REQ-API-001~API-013）+ Configuration（REQ-API-004）+ Sequence / High-level Operation + Extension
```

### 4. 工程上，它怎么进入项目？

```text
Simulator（VCS）+ Build（filelist/Makefile/FuseSoC）+ Repository + Metadata（REQ-API-012）
```

### 5. 如何证明 VIP 自己是正确的？

```text
Self-Test + RTM + Coverage + Mutation + Regression + Qualification（REQ-QLF-001~QLF-006）
```

---

# 附录 A. Requirement ID 索引

| 分组 | 类别 | 编号范围 | 数量 |
| --- | --- | --- | --- |
| Protocol —— Feature List（核心） | PRO | `AXI4-REQ-PRO-001` ~ `PRO-012` | 12 |
| Protocol —— Feature 扩展 | PRO | `AXI4-REQ-PRO-013` ~ `PRO-021` | 9 |
| Protocol Rules（基础+扩展） | RUL | `AXI4-REQ-RUL-001` ~ `RUL-017` | 17 |
| Transaction Model | TRN | `AXI4-REQ-TRN-001` ~ `TRN-003` | 3 |
| Stimulus / Sequence | STM | `AXI4-REQ-STM-001` ~ `STM-002` | 2 |
| Verification —— 组件能力 | VER | `AXI4-REQ-VER-001` ~ `VER-014` | 14 |
| Configuration（基础+扩展） | CFG | `AXI4-REQ-CFG-001` ~ `CFG-024` | 24 |
| External Interface | API | `AXI4-REQ-API-001` ~ `API-013` | 13 |
| Engineering —— 运行环境 | ENG | `AXI4-REQ-ENG-001` ~ `ENG-004` | 4 |
| Engineering —— 可调试性 | DBG | `AXI4-REQ-DBG-001` ~ `DBG-004` | 4 |
| Engineering —— Statistics | STA | `AXI4-REQ-STA-001` | 1 |
| Engineering —— Recording/Replay | REC | `AXI4-REQ-REC-001` | 1 |
| Delivery | DEL | `AXI4-REQ-DEL-001` ~ `DEL-003` | 3 |
| Qualification | QLF | `AXI4-REQ-QLF-001` ~ `QLF-006` | 6 |

> **编号一经发布不得重用**；废弃需求标记 `deprecated` 而非删除。

---

# 附录 B. 与 HWIF 契约一致性（G0 检查）

- VIP 接口信号集合、方向、位宽以 `aixsilicon:hwif:axi`（`IFC-AXI-001`）为**唯一基准**；
- 依赖 HWIF 的 `aw`/`w`/`b`/`ar`/`r` 五通道定义与 `resp_encoding`、`burst_types`、`transfer` 语义；
- **命名规范**：AXI 标准命名（无下划线，如 `awvalid`/`awlock`/`awregion`/`awuser`），与 HWIF 契约及 `axi_if` 一致；
- **接口信号**：`axi4_if` 采用 HWIF **完整信号集**，含必选 `awlock/arlock`（用于 **exclusive**）、`awregion/arregion` 与 capability `awatop`/`*user`；
- **Exclusive 语义**：`awlock/arlock=1` 表达 **exclusive access**（REQ-PRO-016/RUL-016），**不表达** AXI3 式 locked transaction；
- **AWATOP 边界**：`awatop` 为 HWIF superset 信号（AXI5/AMBA5 Atomic），AXI4 profile 下驱动/钳位为非原子值、不激活（非 AXI4 capability）；
- tvip-axi 参考接口仅核心信号与 HWIF 一致，**不得直接照搬**（缺 lock/region/atop/user、narrow/unaligned/strobe 语义）；
- VIP **不重复定义**接口契约；HWIF 契约变更 → 本需求同步更新（版本语义变更记于 reports/run_log.md 版本小节）。

---

# 附录 C. Requirement 编号体系（局部编号）

采用 **`AXI4-REQ-<CATEGORY>-<NNN>` 局部编号**：

- 每个类别（`PRO/RUL/TRN/STM/VER/CFG/API/ENG/DBG/STA/REC/DEL/QLF`）**独立从 001 起编**；
- **新增需求只影响所属类别**（在本类别末尾追加 `NNN`），**无需全局重排**；
- 编号一经发布不得重用；废弃标记 `deprecated`；
- 工具化（RTM/Coverage/Mutation/metadata）按 `CATEGORY` 分组统计，避免旧式 `REQ-010/0100/0101` 排序混乱。

| 类别 | 含义 | 示例 |
| --- | --- | --- |
| PRO | Protocol capability / Feature | `AXI4-REQ-PRO-016`（Exclusive） |
| RUL | Protocol Rule | `AXI4-REQ-RUL-003`（4KB 边界） |
| TRN | Transaction Model | `AXI4-REQ-TRN-003`（Protocol Event） |
| STM | Stimulus / Sequence | `AXI4-REQ-STM-002` |
| VER | Verification 组件 | `AXI4-REQ-VER-009`（Checker） |
| CFG | Configuration | `AXI4-REQ-CFG-006`（response_ordering） |
| API | External Interface / Public API | `AXI4-REQ-API-008`（Violation） |
| ENG | Engineering | `AXI4-REQ-ENG-002`（Build） |
| DBG | Debug | `AXI4-REQ-DBG-004`（日志分层） |
| STA | Statistics | `AXI4-REQ-STA-001` |
| REC | Recording / Replay | `AXI4-REQ-REC-001` |
| DEL | Deliverable | `AXI4-REQ-DEL-002`（Self-Test） |
| QLF | Qualification | `AXI4-REQ-QLF-005`（Mutation） |
