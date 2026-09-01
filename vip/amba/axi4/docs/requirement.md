# AIXSILICON AXI4 VIP — 需求规格（Requirement Specification）

> 文档 ID: `aixsilicon:vip:axi4:req` · 版本: 0.2.0-draft · 状态: Planned（G0 修订中）
>
> 本文档是 AXI4 VIP 需求的唯一 SSOT。来源：
> - 参考实现: `repos/aixsilicon_vip_repo/reference/tvip-axi`（Apache-2.0，Taichi Ishitani）
> - 协议规范: ARM AMBA AXI4 协议（IHI 0022E），AXI4-Lite（IHI 0022E 附录）
> - HWIF 契约: `aixsilicon:hwif:axi`（`IFC-AXI-001`，[`axi.interface.yaml`](../../../../../aixsilicon_hwif_repo/bus/axi/contract/axi.interface.yaml)）
> - VIP Plan 条目: `repos/aixsilicon_vip_repo/registry.yaml` `VIP-001`（axi4，FULL_UVM，P0）

---

## 1. 概述（Overview）

本 VIP 提供面向 **AMBA AXI4 / AXI4-Lite** 协议的标准、可复用验证组件，覆盖 Master（initiator）与 Slave（target）两侧，
以及被动监控（PASSIVE）场景。VIP 聚焦"可观察 → 可理解 → 可检查 → 可激励"四个层次，
作为 IP/SoC 验证中的协议层资产，供 `ip-development-suite` / `soc-integration-suite` 复用。

- **Profile**: `FULL_UVM`（AXI4 属复杂协议，需完整 agent/driver/monitor/sequencer/sequence）
- **VLNV**: `aixsilicon:vip:axi4:1.0.0`（目标发布版本）
- **依赖 HWIF**: `aixsilicon:hwif:axi`（`IFC-AXI-001`）—— 信号/宽度/方向/时序以 HWIF 契约为准，VIP 不重复定义接口契约
- **参考实现**: `tvip-axi` 提供能力基线（功能/配置/组件/序列库），本需求在此基础上补齐协议检查（Checker/SVA）、
  覆盖率闭合、错误注入与自验证（VIP Self Test）能力，达到 AIXSILICON VIP 质量门禁（G0–G6）。
- **双 Protocol Profile**: 本 VIP 区分 `AXI4_FULL`（完整 AXI4）与 `AXI4_LITE`（AXI4-Lite）两种能力剖面，
  以 `protocol` 配置选择，避免在 sequence 内散落 `if(protocol==AXI4LITE)`（见 §2.2 与 §5）。

---

## 2. Feature List（功能需求 REQ-001 ~ REQ-009 + 扩展）

AXI4 能力以 **Feature Model** 组织：Feature → Requirement → Sequence → Monitor → Checker/SVA → Coverage → Self-Test → Mutation。
以下为核心 Feature 与新增能力。

### 2.1 核心 Feature

| ID | Feature | 说明 | 参考实现 | 对应能力 |
| --- | --- | --- | --- | --- |
| AXI4-REQ-001 | 读事务（Read） | 支持 AR 通道发起读请求，R 通道接收数据/响应，支持读突发（burst） | `tvip_axi_master_read_sequence` | 主动激励 + 被动监控 |
| AXI4-REQ-002 | 写事务（Write） | 支持 AW/W 通道发起写请求与写数据，B 通道接收写响应 | `tvip_axi_master_write_sequence` | 主动激励 + 被动监控 |
| AXI4-REQ-003 | 突发类型（Burst Type） | 支持 FIXED / INCR / WRAP 三种突发类型（长度限制见 REQ-003A） | `tvip_axi_types_pkg`（burst type） | 主动激励 + 检查 |
| AXI4-REQ-003A | 突发长度（Burst Length） | 长度合法性：**INCR 1–256**；**FIXED 1–16**；**WRAP 仅 2/4/8/16**；AXI4-Lite 固定 len=0（1 beat） | `tvip_axi_types_pkg`（burst length） | 主动激励 + 检查 |
| AXI4-REQ-003B | 突发地址生成（Burst Address Generation） | VIP 必须能由 `AxADDR/AxSIZE/AxLEN/AxBURST` 计算每个 beat 的实际 byte address；正确处理 wrap boundary、narrow/unaligned 组合 | 新增（参考实现具备，本 VIP 显式建模） | 主动激励 + 检查 |
| AXI4-REQ-003C | 突发合法性（Burst Legality） | 检查：4KB 边界、WRAP 长度与 wrap boundary、AxSIZE 合法性（≤ DATA_W/8）、地址对齐/unaligned 规则、**禁止提前终止**、WLAST/RLAST 一致性 | 新增 | Checker/SVA |
| AXI4-REQ-004 | Outstanding（未完成请求） | 支持多笔未完成事务，Master 可重叠地址/数据，Slave 可延迟响应；配置细化见 REQ-045/0511（read/write/per-id） | `configuration.outstanding_responses` | 主动激励 + 检查 |
| AXI4-REQ-005 | ID 管理 | 支持可配置 ID 宽度（0–32 bit，AXI4-Lite 固定 0），支持多 ID 与 ID 排序 | `tvip_axi_configuration.id_width` | 主动激励 + 检查 |
| AXI4-REQ-006 | 背压（Backpressure） | Master/Slave 均可配置握手通道（VALID/READY）的默认值与延迟，制造 backpressure | `default_*ready` + `*_ready_delay` | 主动激励 |
| AXI4-REQ-007 | 延迟写数据/写响应 | Slave 支持延迟写数据（gapped write data）与延迟响应 | `write_data_delay`、`response_delay`、`response_start_delay` | 主动激励 |
| AXI4-REQ-008 | 响应排序（in-order / out-of-order） | Slave 支持按 ID 的 in-order 与 out-of-order 响应返回 | `response_ordering` | 主动激励 + 检查 |
| AXI4-REQ-009 | 读交织（Read Interleave） | Slave 支持读数据交织（多 ID 读事务数据交错返回） | `enable_response_interleaving`、`min/max_interleave_size` | 主动激励 + 检查 |

### 2.2 AXI4-Full 与 AXI4-Lite 能力剖面

AXI4 与 AXI4-Lite 不是"同一协议的开关"，而是**两种能力剖面**，独立于后续 Qualification 回归
（`vip_tool regression --profile axi4` / `--profile axi4lite`）：

| Capability | AXI4 Full | AXI4-Lite | 说明 |
| --- | :---: | :---: | --- |
| ID | ✅ | ❌ | Lite 无 ID（id_width=0） |
| Burst（INCR/FIXED/WRAP） | ✅ | ❌ | Lite 仅单 beat（len=0） |
| Outstanding | ✅ | 有限（≤1 pending） | Lite 每次仅一笔事务 |
| Exclusive Access | ✅ | ❌ | Lite 不支持 AxLOCK |
| QoS / Region | ✅ | ❌ | Lite 固定 qos=0、region=0 |
| Narrow / Unaligned | ✅ | 视实现（data_w≤总线宽） | Lite 允许 narrow/unaligned 写 |
| AxCACHE / AxPROT | ✅ | ✅（固定值） | Lite 信号存在但语义受限 |
| R / W | ✅ | ✅ | 均支持读/写 |

### 2.3 Feature 扩展（P0/P1 能力补齐）

| ID | Feature | 说明 | 对应能力 |
| --- | --- | --- | --- |
| AXI4-REQ-0100 | **Narrow Transfer** | 支持 `transfer_size < bus_width`（如 DATA_WIDTH=64、AWSIZE=2 → 每 beat 4B）。Master 能产生、Slave 能接收、Monitor 正确重建、Checker 检查 byte lane；Coverage 覆盖 `SIZE × BUS_WIDTH × BURST_TYPE`。VIP 必须理解 AxSIZE/WSTRB/AxADDR/byte lane 关系（lane 随地址与 burst 移动） | 激励 + 监控 + 检查 + 覆盖 |
| AXI4-REQ-0101 | **Unaligned Transfer** | 支持合法 unaligned 访问：unaligned read / unaligned write / unaligned+narrow / unaligned+INCR burst。VIP 必须知道首拍有效 byte lane、WSTRB 取值、下一拍地址推进；检查 WSTRB/byte lane 合法性、地址递增、4KB 边界 | 激励 + 监控 + 检查 |
| AXI4-REQ-0102 | **Write Strobe / Partial Write** | Master 生成合法 WSTRB：支持 partial write（部分字节写）与 sparse byte enable；Slave memory model **仅更新 WSTRB=1 的 byte**；Checker 校验 WSTRB 不覆盖当前 transfer 之外的 byte lane；Coverage 覆盖 full/partial/edge/sparse/narrow/unaligned strobe | 激励 + 参考模型 + 检查 + 覆盖 |
| AXI4-REQ-0103 | **Exclusive Access（独占访问）** | 使用 `AxLOCK`（EXCLUSIVE=1）表达独占访问：Master 发起 exclusive read/write，Slave memory 维护独占标记与同地址冲突检测，响应编码 EXOKAY/OKAY 语义正确；配 `exclusive_support` 开关（见 REQ-0513） | 激励 + 参考模型 + 检查 + 覆盖 |
| AXI4-REQ-0104 | **Sideband（AxCACHE/AxPROT/AxQOS/AxREGION/AxUSER）** | 对边带信号建立 capability 模型（PRESENT/DRIVE/CHECK/COVERAGE，见 §2.4），而非仅"接口保留、置常量" | 激励 + 检查 + 覆盖 |
| AXI4-REQ-0105 | **Reset 中 outstanding 行为** | 定义复位对 outstanding 事务的影响：复位期间所有 VALID=0、握手终止、未响应事务丢失策略；复位释放后无残留状态；Checker 校验复位无未完成握手 | 激励 + 检查 |

### 2.4 Sideband Capability 矩阵

"接口里有信号" ≠ "VIP 支持该 feature"。V1.0 对各边带信号明确 capability 分级：

| Signal | PRESENT | Random Drive | CHECK | Coverage | 备注 |
| --- | :---: | :---: | :---: | :---: | --- |
| AxCACHE | ✅ | ✅ | ✅ | ✅ | 合法编码检查（0011/0010/...） |
| AxPROT | ✅ | ✅ | ✅ | ✅ | 合法编码检查 |
| AxQOS | ✅ | ✅ | 基本合法性 | ✅ | 无协议非法值，做字段覆盖 |
| AxREGION | ✅ | ✅ | 基本合法性 | ✅ | 字段覆盖 |
| AxUSER | ✅ | 可选 | - | 可选 | V1.0 保留信号，optional drive |
| AWATOP | ✅ | V2.0 | V2.0 | V2.0 | V1.0 保留，置常量（见能力边界） |

> 该矩阵与 HWIF capability 对齐，可作为 HWIF 自动生成 capability matrix 的输入。

### 2.5 能力边界声明（修正：Exclusive 与 Locked 分离）

| 能力 | 支持 | 说明 |
| --- | --- | --- |
| AXI4（完整信号集） | ✅ | 采用 HWIF 完整 AXI 信号：awvalid/awid/awaddr/awlen/awsize/awburst/awlock/awcache/awprot/awqos/awregion/awatop/awuser + w/b/ar/r 对应信号 |
| AXI4-Lite | ✅ | 通过 `protocol=AXI4_LITE` 剖面切换；无 ID、无 burst、固定 qos=0、无 exclusive |
| AXI-Stream / ACE / CHI | ❌ | 另立 VIP（VIP-003/VIP-101/VIP-201） |
| **Exclusive Access（独占访问）** | ✅ V1.0 支持 | 使用 `AxLOCK`（HWIF `awlock/arlock` 为 **required**）；VIP 接口含此信号，且实现独占语义（REQ-0103/0115） |
| **AXI3 Locked Transaction** | ❌ 不支持 | **AXI4 已移除 locked transactions**；`AxLOCK` 在 AXI4 中仅用于表达 exclusive access，不得解释为 AXI3 式 locked burst |
| Narrow Transfer | ✅ V1.0 | REQ-0100 |
| Unaligned Transfer | ✅ V1.0 | REQ-0101 |
| Write Strobe / Partial Write | ✅ V1.0 | REQ-0102；`axi4_memory` 仅更新 WSTRB=1 的 byte |
| **Write Data Interleaving（AXI3 WID）** | ❌ 不支持 | **AXI4 已移除 write-data interleaving**；W 数据必须按 AW 事务顺序提供（REQ-0114 negative rule） |
| Region（区域标识） | ✅ V1.0 | HWIF `awregion/arregion` 为 **required**；接口含信号 + 驱动 + 基本检查 |
| ATOP（原子操作） | ⬜ 接口保留 | HWIF `awatop` 为 capability；V1.0 置常量/不驱动，V2.0 激活 |
| USER 边带信号 | ⬜ 接口保留 | HWIF `awuser/wuser/buser/aruser/ruser` 为 capability；V1.0 可选驱动 |

> **HWIF 一致性说明（重要）**：tvip-axi 参考接口与 HWIF `IFC-AXI-001` 的**核心信号一致**，
> 但参考实现**缺少 HWIF 契约标记为必选的 `awlock/arlock` 与 `awregion/arregion`**，
> 且 `awatop`/`*user` 等 capability 亦缺失。HWIF 契约已按 AXI 标准命名（无下划线）修复。
> 本 VIP **采用 HWIF 完整信号集**（含 lock/region/atop/user），不得直接照搬 tvip-axi 接口；
> 具体信号清单见 REQ-020 与 architecture.md §5/§7。

---

## 3. Protocol Rules（协议规则 REQ-010 ~ REQ-019 + 扩展）

以下为必须被检查的协议规则（对应 Checker/SVA 可检查项，见 RTM）。
一级分类 + 细分规则共同构成 Checker 规格基线（V1.0 目标 25~30 条规则）。

### 3.1 基础规则

| ID | 规则 | 描述 | 对应检查 |
| --- | --- | --- | --- |
| AXI4-REQ-010 | VALID 不依赖 READY | VALID 一旦拉高必须保持到握手完成，不得等待 READY 才拉高 | CHK/SVA |
| AXI4-REQ-011 | 握手机制 | 仅当 VALID && READY 同时为高时传输发生；数据只在握手沿采样 | CHK/SVA |
| AXI4-REQ-012 | 4KB 边界 | INCR/WRAP 突发不得跨越 4KB 地址边界 | CHK/SVA |
| AXI4-REQ-013 | 突发长度/大小合法 | ARLEN/AWLEN 符合 REQ-003A（INCR 1–256 / FIXED 1–16 / WRAP 2/4/8/16）；ARSIZE/AWSIZE ≤ DATA_W/8；AXI4-Lite 固定 len=0 | CHK/SVA |
| AXI4-REQ-014 | WLAST/RLAST | 写数据最后一拍必须置 WLAST；读数据最后一拍必须置 RLAST，且与突发长度一致 | CHK/SVA |
| AXI4-REQ-015 | ID 排序 | in-order 模式下，同 ID 写响应/读数据必须按请求顺序返回；out-of-order 仅不同 ID 可乱序 | CHK |
| AXI4-REQ-016 | 响应跟随请求 | B 响应必须出现在对应写事务（含所有 W 数据）之后；R 响应跟随 AR 请求 | CHK |
| AXI4-REQ-017 | 读数据顺序 | 单笔读事务内 R 数据顺序不可打乱；交织仅允许跨 ID | CHK |
| AXI4-REQ-018 | 复位行为 | 复位期间所有 VALID 必须为 0；复位释放后握手正常；复位时无 outstanding 残留（与 REQ-0105 配合） | CHK/SVA |
| AXI4-REQ-019 | 响应编码 | BRESP/RRESP 编码合法（OKAY=00/EXOKAY=01/SLVERR=10/DECERR=11）；EXOKAY 仅用于 exclusive（REQ-0115） | CHK/SVA |

### 3.2 扩展规则（P0/P1）

| ID | 规则 | 描述 | 对应检查 |
| --- | --- | --- | --- |
| AXI4-REQ-0110 | **Payload Stability** | `VALID=1 && READY=0` 时，各通道 payload 必须保持稳定：AWVALID 时 AWADDR/AWID/AWLEN/AWSIZE/AWBURST（+AWLOCK/AWCACHE/AWPROT/AWQOS/AWREGION）稳定；WVALID 时 WDATA/WSTRB/WLAST 稳定；ARVALID 时 AR 通道稳定；BVALID 时 BRESP/BID 稳定；RVALID 时 RDATA/RRESP/RID/RLAST 稳定 | SVA |
| AXI4-REQ-0111 | **Narrow Byte Lane** | narrow transfer（size < data_w/8）时，有效 byte lane 由 AxADDR/AxSIZE 决定并随 burst 移动；byte lane 不得越界 | CHK/SVA |
| AXI4-REQ-0112 | **WSTRB 合法性** | WSTRB 只允许置位当前 transfer 覆盖范围内的 byte lane；不得覆盖 transfer 之外的 byte | CHK/SVA |
| AXI4-REQ-0113 | **Unaligned 规则** | unaligned 起始地址：首拍 lane/WSTRB/地址推进符合规范；unaligned+narrow+INCR 组合正确 | CHK |
| AXI4-REQ-0114 | **Write Data Ordering（negative rule）** | W 数据必须按 AW 事务顺序提供；**禁止 AXI3 式 write-data interleaving（无 WID）** | CHK |
| AXI4-REQ-0115 | **Exclusive 语义** | 独占 read 后同地址、同 ID 的独占 write 成功返回 EXOKAY；不同 ID 或非独占 write 返回 OKAY；同地址冲突检测；独占未配对处理 | CHK + 参考模型 |
| AXI4-REQ-0116 | **禁止提前终止** | burst 一旦开始不得提前终止（WLAST/RLAST 之前不得结束）；AXI4-Lite 无 burst | SVA |

> 每条规则必须可映射到至少一个 Checker 或 SVA，并进入 RTM 与错误注入（Mutation）目标清单。

---

## 4. 组件需求（The Engine，REQ-020 ~ REQ-033）

按 Profile=`FULL_UVM` 裁剪组件（组件矩阵见 [`vip-architecture`](../../../../../../.roo/skills/vip-development-suite/skills/vip-architecture/SKILL.md)）。

| ID | 组件 | 类型 | 需求说明 | 参考实现 |
| --- | --- | --- | --- | --- |
| AXI4-REQ-020 | 接口 interface | `axi4_if` | 提供 5 通道**完整 AXI 信号**（无下划线标准命名：awvalid/awid/awaddr/awlen/awsize/awburst/awlock/awcache/awprot/awqos/awregion/awatop/awuser 等）与 clocking block / modport（master/slave/monitor）；信号以 HWIF `IFC-AXI-001` 为唯一基准 | HWIF `axi_if`（tvip-axi 仅作参考，缺 lock/region/atop/user） |
| AXI4-REQ-021 | 事务 transaction | `axi4_item extends uvm_sequence_item` | 读/写访问描述：id/address/burst/len/size/memory_type/protection/qos/region/lock(exclusive)/strobe(WSTRB 语义)/data/response；含窄/非对齐字段、时序字段与 begin/end 事件；满足 Constraint Model（§6） | `tvip_axi_item.svh`（补齐 strobe 语义/lock/exclusive） |
| AXI4-REQ-022 | 配置 config | `axi4_configuration` | 见 §5 配置需求 | `tvip_axi_configuration.svh` |
| AXI4-REQ-023 | Master Agent | `axi4_master_agent extends uvm_agent` | 组装 master sequencer/driver/monitor（写监控 + 读监控），支持 ACTIVE/PASSIVE | `tvip_axi_master_agent.svh` |
| AXI4-REQ-024 | Slave Agent | `axi4_slave_agent extends uvm_agent` | 组装 slave sequencer/driver/monitor + data monitor，支持 ACTIVE/PASSIVE | `tvip_axi_slave_agent.svh` |
| AXI4-REQ-025 | Sequencer | `axi4_master_sequencer` / `axi4_slave_sequencer` | 基于 `uvm_sequencer`，承载 sequence 发送 | `tvip_axi_*_sequencer.svh` |
| AXI4-REQ-026 | Driver | `axi4_master_driver` / `axi4_slave_driver` | 按事务驱动接口信号；支持 narrow/unaligned/WSTRB 生成、延迟写数据/响应、响应排序、读交织、exclusive 响应 | `tvip_axi_*_driver.svh`（补齐 narrow/unaligned/exclusive） |
| AXI4-REQ-027 | Monitor | `axi4_master_monitor` / `axi4_slave_monitor`（写/读分离） | 被动采样并重建事务（Observation Model），正确处理 narrow/unaligned/byte lane，输出 analysis port | `tvip_axi_*_monitor.svh` |
| AXI4-REQ-028 | Checker | `axi4_checker extends uvm_scoreboard` | 协议规则检查（REQ-010~019 + 0110~0116），支持错误注入预期检测；Ordering Model（§4.1） | 新增（参考未含，本 Suite 补齐） |
| AXI4-REQ-029 | 断言 SVA | `axi4_assertions` | 时序/握手/边界 SVA（含 payload stability、burst legality，可绑定 interface） | 新增 |
| AXI4-REQ-030 | 覆盖模型 | `axi4_coverage` | 四层覆盖（见 vip-coverage）；含 SIZE×BUS_WIDTH×BURST、WSTRB 形态、exclusive 等交叉覆盖 | 新增 |
| AXI4-REQ-031 | 存储模型 | `axi4_memory` | Slave 侧内存镜像，读写访问行为模型；支持 **narrow/unaligned（仅更新 WSTRB=1 byte）**、延迟、错误注入、**exclusive 独占标记与冲突检测** | `tvip_axi_memory.svh`（补齐 WSTRB 语义/exclusive） |
| AXI4-REQ-032 | 状态对象 | `axi4_status` | 保存运行时状态（含 memory 句柄、outstanding 计数 read/write/per-id） | `tvip_axi_status.svh` |
| AXI4-REQ-033 | RAL 集成 | `axi4_ral_adapter` / `axi4_ral_predictor` | 提供 UVM RAL 寄存器模型到 AXI 总线的 adapter/predictor | `tvip_axi_ral_*.svh` |

### 4.1 AXI Ordering Model（排序模型）

AXI 排序是 VIP 最核心的 Checker 之一。`axi4_checker` 内部维护按 ID 的队列模型：

```text
read_request_queue[ID]    write_request_queue[ID]
read_response_queue[ID]   write_response_queue[ID]
```

检查项：same-ID ordering、different-ID reordering、RID↔ARID 匹配、BID↔AWID 匹配、
read interleaving 合法性、write response ordering、**write data ordering（REQ-0114）**。

---

## 5. 配置需求（Configuration Interface，REQ-040 ~ REQ-059 + 扩展）

配置空间基于 `tvip_axi_configuration`，并在其基础上补充本 Suite 要求的调试/检查/覆盖开关。分层配置：system → agent → component。

### 5.1 协议与位宽

| ID | 配置项 | 类型/范围 | 默认 | 说明 |
| --- | --- | --- | --- | --- |
| AXI4-REQ-040 | `protocol` | `AXI4_FULL` / `AXI4_LITE` | AXI4_FULL | 能力剖面选择（§2.2），影响约束空间与组件激活 |
| AXI4-REQ-041 | `id_width` | 0–32 | 8 | ID 位宽（AXI4_LITE 固定 0） |
| AXI4-REQ-042 | `address_width` | 1–64 | 32 | 地址位宽 |
| AXI4-REQ-043 | `data_width` | 8/16/32/64/128/256/512/1024 | 32 | 数据位宽（AXI4_LITE 仅 32/64） |
| AXI4-REQ-044 | `max_burst_length` | 1–256 | 256 | 最大突发长度（按 REQ-003A 各类型限制；AXI4_LITE 固定 1） |

### 5.2 行为特性

| ID | 配置项 | 类型/范围 | 默认 | 说明 |
| --- | --- | --- | --- | --- |
| AXI4-REQ-045 | `response_ordering` | IN_ORDER / OUT_OF_ORDER | OUT_OF_ORDER | Slave 响应排序模式 |
| AXI4-REQ-046 | `outstanding_responses` | ≥0 | 0 | 允许的未完成响应数（0=不限制）；更细粒度见 REQ-0511 |
| AXI4-REQ-047 | `enable_response_interleaving` | 0/1 | 0 | 读数据交织使能 |
| AXI4-REQ-048 | `min/max_interleave_size` | ≥0 | 0/0 | 交织粒度范围 |
| AXI4-REQ-049 | `response_weight_*` | -1.. | -1 | 各响应（OKAY/EXOKAY/SLVERR/DECERR）加权，用于随机响应注入 |

### 5.3 时序/背压

| ID | 配置项 | 类型 | 说明 |
| --- | --- | --- | --- |
| AXI4-REQ-050 | `request_start_delay` | delay_config | 请求开始延迟（Slave 侧） |
| AXI4-REQ-051 | `write_data_delay` | delay_config | 写数据延迟（gapped write data） |
| AXI4-REQ-052 | `response_start_delay` / `response_delay` | delay_config | 响应开始/响应延迟 |
| AXI4-REQ-053 | `default_awready/wready/bready/arready/rready` + `*_ready_delay` | bit + delay_config | 各通道 READY 默认值与延迟（背压控制） |
| AXI4-REQ-054 | `reset_by_agent` | 0/1 | 是否由 Agent 驱动复位 |

### 5.4 本 Suite 扩展开关（新增，参考实现无）

| ID | 配置项 | 说明 |
| --- | --- | --- |
| AXI4-REQ-055 | `enable_checker` | 协议检查使能（默认 1） |
| AXI4-REQ-056 | `enable_coverage` | 功能覆盖使能（默认 1） |
| AXI4-REQ-057 | `enable_error_injection` | 错误注入使能（Violation Injector） |
| AXI4-REQ-058 | `transaction_log` | 事务日志开关与 verbosity |
| AXI4-REQ-059 | `agent_mode` | ACTIVE_MASTER / ACTIVE_SLAVE / PASSIVE / DISABLED |

### 5.5 扩展配置（P0/P1）

| ID | 配置项 | 说明 |
| --- | --- | --- |
| AXI4-REQ-0510 | `max_outstanding_read` / `max_outstanding_write` / `max_outstanding_per_id` | outstanding 细粒度上限（REQ-004/046 深化） |
| AXI4-REQ-0511 | `exclusive_support` | Exclusive Access 使能（默认 1；AXI4_LITE 强制 0）；含 exclusive 序列权重 |
| AXI4-REQ-0512 | `drive_*_cache/prot/qos/region/user` | Sideband 随机驱动开关（对应 §2.4 capability 矩阵） |
| AXI4-REQ-0513 | `constraint_mode` | Constraint Model 开关：LEGAL_ONLY / DIRECTED / ILLEGAL（配合 Violation Injector，见 §6） |

---

## 6. Transaction Constraint Model（事务约束空间）

可复用 VIP 必须显式定义"什么是合法 AXI transaction space"，而非只有 sequence。`axi4_item` 约束体系：

| 模式 | 说明 |
| --- | --- |
| legal-only random | 在合法空间内随机（address/id/burst/len/size/alignment/4KB/strobe/qos/cache/prot/region/response/delay 约束） |
| directed | 定向构造（测试指定的合法场景） |
| constraint override | 用户可覆盖默认约束（`constraint_mode=DIRECTED`） |
| illegal generation | 关闭特定合法约束生成非法事务（配合 Violation Injector / Mutation Test） |

典型 illegal 场景（Violation Injector 目标）：

```text
illegal_wrap_length      illegal_wstrb           cross_4kb
early_wlast              missing_wlast           unstable_awaddr
invalid_burst            unstable_awlen/size     invalid_id
```

> 这使 Mutation Test 设计干净：`legal constraint → disable → 生成特定非法事务 → Checker 预期检测`。

---

## 7. 运行环境需求（The Toolkit，REQ-060 ~ REQ-063）

| ID | 需求 | 说明 |
| --- | --- | --- |
| AXI4-REQ-060 | 仿真器支持 | VCS（UVM 1.2，`-ntb_opts uvm-1.2`）；Xcelium / DSim 需验证（参考实现声明支持） |
| AXI4-REQ-061 | 编译入口 | VIP Self Test 工程 `Makefile`（vcs/xcelium 双入口）+ `filelist.f`；正式交付 FuseSoC `.core`（gen-core 生成） |
| AXI4-REQ-062 | 回归分层 | smoke / feature / full（`vip_tool.py regression --tier`）；Profile 回归 `--profile axi4 / axi4lite` |
| AXI4-REQ-063 | 回归记录 | 统一写入 `reports/quality/run_log.md`，与 Evidence Index 关联 |

---

## 8. 可调试性需求（Debug-ability，REQ-064 ~ REQ-067）

| ID | 需求 | 说明 |
| --- | --- | --- |
| AXI4-REQ-064 | 事务日志 | `item` 全字段 `convert2string`，按 verbosity 分级（参考实现含 begin/end 时间戳；含窄/非对齐/strobe/exclusive 字段） |
| AXI4-REQ-065 | 查询命令 | `debug_report()` 输出 outstanding 细粒度状态（见下），辅助 Address/Data/Response channel 解耦调试 |
| AXI4-REQ-066 | 错误分类 | 协议错误 / 环境错误 / 数据错误，错误信息带 `[REQ-xxx]` 定位 |
| AXI4-REQ-067 | 协议栈分层 | 事务级（Transaction）为主；复杂场景可加数据链路级（DataLink，如交织/乱序）日志 |

`debug_report()` 建议输出（Outstanding 精细化）：

```text
READ:
  ID 0x01 : 4 outstanding      ID 0x02 : 2 outstanding

WRITE:
  AW pending : 3               W active : 1      B pending : 2
```

---

## 9. 交付需求（The Manual，REQ-068 ~ REQ-070）

| ID | 需求 | 说明 |
| --- | --- | --- |
| AXI4-REQ-068 | 文档交付 | 用户指南（user-guide）、配置手册（configuration）、架构（architecture）、限制（limitation） |
| AXI4-REQ-069 | 示例与自验证 | `examples/` 最小 DUT + `self_test/` VIP Self Test（smoke/feature/corner/error/random/stress） |
| AXI4-REQ-070 | 源码交付模式 | open（Apache-2.0 兼容；参考 tvip-axi 为 Apache-2.0） |

---

## 10. Qualification Requirements（REQ-071 ~ REQ-076）

进入 Qualification（G5）前必须满足（详见 [`vip-qualification`](../../../../../../.roo/skills/vip-development-suite/skills/vip-qualification/SKILL.md)）：

| ID | 需求 | 判定 |
| --- | --- | --- |
| AXI4-REQ-071 | 结构/元数据检查 | `vip_tool.py vip-check` PASS（G1/G2 前置） |
| AXI4-REQ-072 | 编译 | UVM 1.2 全工程编译 PASS |
| AXI4-REQ-073 | 自验证回归 | `vip_tool.py regression --tier full` PASS（G3） |
| AXI4-REQ-074 | 覆盖率闭合 | `vip_tool.py coverage-check` PASS（G4） |
| AXI4-REQ-075 | Mutation/错误注入检测率 | `vip_tool.py mutation-test` 达到阈值（G5） |
| AXI4-REQ-076 | FuseSoC Core 校验 | `vip_tool.py gen-core --check` PASS（VLNV `aixsilicon:vip:axi4`） |

---

## 11. Requirement ID 索引

| 分组 | 编号范围 | 数量 |
| --- | --- | --- |
| Feature List（核心） | AXI4-REQ-001 ~ 009（含 003A/003B/003C） | 12 |
| Feature 扩展（P0/P1） | AXI4-REQ-0100 ~ 0105 | 6 |
| Protocol Rules（基础） | AXI4-REQ-010 ~ 019 | 10 |
| Protocol Rules（扩展） | AXI4-REQ-0110 ~ 0116 | 7 |
| 组件需求 | AXI4-REQ-020 ~ 033 | 14 |
| 配置需求（基础） | AXI4-REQ-040 ~ 059 | 20 |
| 配置需求（扩展） | AXI4-REQ-0510 ~ 0513 | 4 |
| 运行环境 | AXI4-REQ-060 ~ 063 | 4 |
| 可调试性 | AXI4-REQ-064 ~ 067 | 4 |
| 交付需求 | AXI4-REQ-068 ~ 070 | 3 |
| Qualification | AXI4-REQ-071 ~ 076 | 6 |

> 编号一经发布不得重用；废弃需求标记 `deprecated` 而非删除。

---

## 12. 与 HWIF 契约一致性（G0 检查）

- VIP 接口信号集合、方向、位宽以 `aixsilicon:hwif:axi`（`IFC-AXI-001`）为**唯一基准**；
- 本 VIP 依赖 HWIF 的 `aw`/`w`/`b`/`ar`/`r` 五通道定义与 `resp_encoding`、`burst_types`、`transfer` 语义；
- **命名规范**：信号采用 AXI 标准命名（无下划线，如 `awvalid`/`awaddr`/`awlock`/`awregion`/`awuser`），
  与 HWIF 契约及 `axi_if` 一致；
- **接口信号**：`axi4_if` 采用 HWIF **完整信号集**，含必选 `awlock/arlock`（用于 **exclusive**）、`awregion/arregion` 与
  capability `awatop`/`*user`（V1.0 保留信号、可置常量）；
- **Exclusive 语义**：`awlock/arlock=1` 表达 **exclusive access**（REQ-0103/0115），**不表达** AXI3 式 locked transaction；
- tvip-axi 参考接口仅核心信号与 HWIF 一致，**不得直接照搬**（参考缺 lock/region/atop/user，且缺 narrow/unaligned/strobe 语义）；
- VIP **不重复定义**接口契约；若 HWIF 契约变更，本需求同步更新并在 CHANGELOG 记录。

---

## 13. 完成标准（G0 Checklist）

- [x] Feature List（REQ-001~009 + 003A/003B/003C）
- [x] Feature 扩展：Narrow（0100）/ Unaligned（0101）/ WSTRB（0102）/ Exclusive（0103）/ Sideband（0104）/ Reset（0105）
- [x] 能力边界：**Exclusive Access（V1.0 支持，AxLOCK）与 AXI3 Locked（不支持）分离修正**
- [x] AXI4-Full / AXI4-Lite 双能力剖面（§2.2）
- [x] Protocol Rules（REQ-010~019 + 0110~0116，可映射 Checker/SVA）
- [x] AXI Ordering Model + write-data ordering negative rule（REQ-0114）
- [x] Payload stability（REQ-0110）
- [x] Transaction Constraint Model（§6）
- [x] 组件需求（REQ-020~033，Engine 组件清单，含 exclusive/narrow/strobe 能力）
- [x] 配置需求（REQ-040~059 + 0510~0513，配置空间 + 分层）
- [x] 运行环境需求（REQ-060~063）
- [x] 可调试性需求（REQ-064~067，outstanding 细粒度 debug_report）
- [x] 交付需求（REQ-068~070）
- [x] Qualification Requirements（REQ-071~076）
- [x] 与 HWIF 契约一致（引用 `aixsilicon:hwif:axi`）
