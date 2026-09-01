# AIXSILICON AXI4 VIP — 需求规格（Requirement Specification）

> 文档 ID: `aixsilicon:vip:axi4:req` · 版本: 0.1.0-draft · 状态: Planned（G0 待确认）
>
> 本文档是 AXI4 VIP 需求的唯一 SSOT。来源：
> - 参考实现: `repos/aixsilicon_vip_repo/reference/tvip-axi`（Apache-2.0，Taichi Ishitani）
> - 协议规范: ARM AMBA AXI4 协议（IHI 0022E），AXI4-Lite（IHI 0022E 附录）
> - HWIF 契约: `aixsilicon:hwif:axi`（`IFC-AXI-001`，[`axi.interface.yaml`](../../../../aixsilicon_hwif_repo/bus/axi/contract/axi.interface.yaml)）
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

---

## 2. Feature List（功能需求 REQ-001 ~ REQ-009）

| ID | 需求 | 说明 | 参考实现 | 对应能力 |
| --- | --- | --- | --- | --- |
| AXI4-REQ-001 | 读事务（Read） | 支持 AR 通道发起读请求，R 通道接收数据/响应，支持读突发（burst） | `tvip_axi_master_read_sequence` | 主动激励 + 被动监控 |
| AXI4-REQ-002 | 写事务（Write） | 支持 AW/W 通道发起写请求与写数据，B 通道接收写响应 | `tvip_axi_master_write_sequence` | 主动激励 + 被动监控 |
| AXI4-REQ-003 | 突发（Burst） | 支持 FIXED / INCR / WRAP 三种突发类型；突发长度 1–256（AXI4-Lite 固定 1） | `tvip_axi_types_pkg`（burst type/length） | 主动激励 + 检查 |
| AXI4-REQ-004 | Outstanding（未完成请求） | 支持多笔未完成事务（outstanding requests/responses），Master 可重叠地址/数据，Slave 可延迟响应 | `configuration.outstanding_responses` | 主动激励 + 检查 |
| AXI4-REQ-005 | ID 管理 | 支持可配置 ID 宽度（0–32 bit，AXI4-Lite 固定 0），支持多 ID 与 ID 排序 | `tvip_axi_configuration.id_width` | 主动激励 + 检查 |
| AXI4-REQ-006 | 背压（Backpressure） | Master/Slave 均可配置握手通道（VALID/READY）的默认值与延迟，制造 backpressure | `default_*ready` + `*_ready_delay` | 主动激励 |
| AXI4-REQ-007 | 延迟写数据/写响应 | Slave 支持延迟写数据（gapped write data）与延迟响应 | `write_data_delay`、`response_delay`、`response_start_delay` | 主动激励 |
| AXI4-REQ-008 | 响应排序（in-order / out-of-order） | Slave 支持按 ID 的 in-order 与 out-of-order 响应返回 | `response_ordering` | 主动激励 + 检查 |
| AXI4-REQ-009 | 读交织（Read Interleave） | Slave 支持读数据交织（多 ID 读事务数据交错返回） | `enable_response_interleaving`、`min/max_interleave_size` | 主动激励 + 检查 |

### 能力边界声明

| 能力 | 支持 | 说明 |
| --- | --- | --- |
| AXI4（完整信号集） | ✅ | 采用 HWIF 完整 AXI 信号：awvalid/awid/awaddr/awlen/awsize/awburst/awlock/awcache/awprot/awqos/awregion/awatop/awuser + w/b/ar/r 对应信号 |
| AXI4-Lite | ✅ | 通过 `protocol` 配置切换；无 ID、无 burst、固定 qos=0 |
| AXI-Stream / ACE / CHI | ❌ | 另立 VIP（VIP-003/VIP-101/VIP-201） |
| Lock（锁定访问） | ✅ V1.0 采用 | HWIF `awlock/arlock` 为 **required**；VIP 接口含此信号（tvip-axi 参考缺失，本 VIP 补齐） |
| Region（区域标识） | ✅ V1.0 采用 | HWIF `awregion/arregion` 为 **required**；VIP 接口含此信号（tvip-axi 参考缺失，本 VIP 补齐） |
| ATOP（原子操作） | ✅ 接口含信号 | HWIF `awatop` 为 capability；VIP 接口保留该信号，V1.0 可置常量/不做驱动，后续版本激活 |
| User 边带信号 | ✅ 接口含信号 | HWIF `awuser/wuser/buser/aruser/ruser` 为 capability；VIP 接口保留，V1.0 可置常量 |
| Exclusive（独占）访问 | 后续评估 | HWIF capability `exclusive`；V1.0 不强制 |

> **HWIF 一致性说明（重要）**：tvip-axi 参考接口与 HWIF `IFC-AXI-001` 的**核心信号一致**，
> 但参考实现**缺少 HWIF 契约标记为必选的 `awlock/arlock` 与 `awregion/arregion`**，
> 且 `awatop`/`*user` 等 capability 亦缺失。HWIF 契约已按 AXI 标准命名（无下划线）修复。
> 本 VIP **采用 HWIF 完整信号集**（含 lock/region/atop/user），不得直接照搬 tvip-axi 接口；
> 具体信号清单见 REQ-020 与 architecture.md §5/§7。

---

## 3. Protocol Rules（协议规则 REQ-010 ~ REQ-019）

以下为必须被检查的协议规则（对应 Checker/SVA 可检查项，见 RTM）。

| ID | 规则 | 描述 | 对应检查 |
| --- | --- | --- | --- |
| AXI4-REQ-010 | VALID 不依赖 READY | VALID 一旦拉高必须保持到握手完成，不得等待 READY 才拉高 | CHK/SVA |
| AXI4-REQ-011 | 握手机制 | 仅当 VALID && READY 同时为高时传输发生；数据只在握手沿采样 | CHK/SVA |
| AXI4-REQ-012 | 4KB 边界 | INCR/WRAP 突发不得跨越 4KB 地址边界 | CHK/SVA |
| AXI4-REQ-013 | 突发长度/大小合法 | ARLEN/AWLEN（0–255，即 1–256 拍）、ARSIZE/AWSIZE ≤ DATA_W/8；AXI4-Lite 固定 len=0、size=数据宽度 | CHK/SVA |
| AXI4-REQ-014 | WLAST/RLAST | 写数据最后一拍必须置 WLAST；读数据最后一拍必须置 RLAST，且与突发长度一致 | CHK/SVA |
| AXI4-REQ-015 | ID 排序 | in-order 模式下，同 ID 写响应/读数据必须按请求顺序返回；out-of-order 仅不同 ID 可乱序 | CHK |
| AXI4-REQ-016 | 响应跟随请求 | B 响应必须出现在对应写事务（含所有 W 数据）之后；R 响应跟随 AR 请求 | CHK |
| AXI4-REQ-017 | 读数据顺序 | 单笔读事务内 R 数据顺序不可打乱；交织仅允许跨 ID | CHK |
| AXI4-REQ-018 | 复位行为 | 复位期间所有 VALID 必须为 0；复位释放后握手正常 | CHK/SVA |
| AXI4-REQ-019 | 响应编码 | BRESP/RRESP 编码合法（OKAY=00/EXOKAY=01/SLVERR=10/DECERR=11） | CHK/SVA |

> 每条规则必须可映射到至少一个 Checker 或 SVA，并进入 RTM 与错误注入（Mutation）目标清单。

---

## 4. 组件需求（The Engine，REQ-020 ~ REQ-030）

按 Profile=`FULL_UVM` 裁剪组件（组件矩阵见 [`vip-architecture`](../../../../.roo/skills/vip-development-suite/skills/vip-architecture/SKILL.md)）。

| ID | 组件 | 类型 | 需求说明 | 参考实现 |
| --- | --- | --- | --- | --- |
| AXI4-REQ-020 | 接口 interface | `axi4_if` | 提供 5 通道**完整 AXI 信号**（无下划线标准命名：awvalid/awid/awaddr/awlen/awsize/awburst/awlock/awcache/awprot/awqos/awregion/awatop/awuser 等）与 clocking block / modport（master/slave/monitor）；信号以 HWIF `IFC-AXI-001` 为唯一基准 | HWIF `axi_if`（tvip-axi 仅作参考，缺 lock/region/atop/user） |
| AXI4-REQ-021 | 事务 transaction | `axi4_item extends uvm_sequence_item` | 读/写访问描述：id/address/burst/len/size/memory_type/protection/qos/data/strobe/response，含时序字段与 begin/end 事件 | `tvip_axi_item.svh` |
| AXI4-REQ-022 | 配置 config | `axi4_configuration` | 见 §5 配置需求 | `tvip_axi_configuration.svh` |
| AXI4-REQ-023 | Master Agent | `axi4_master_agent extends uvm_agent` | 组装 master sequencer/driver/monitor（写监控 + 读监控），支持 ACTIVE/PASSIVE | `tvip_axi_master_agent.svh` |
| AXI4-REQ-024 | Slave Agent | `axi4_slave_agent extends uvm_agent` | 组装 slave sequencer/driver/monitor + data monitor，支持 ACTIVE/PASSIVE | `tvip_axi_slave_agent.svh` |
| AXI4-REQ-025 | Sequencer | `axi4_master_sequencer` / `axi4_slave_sequencer` | 基于 `uvm_sequencer`，承载 sequence 发送 | `tvip_axi_*_sequencer.svh` |
| AXI4-REQ-026 | Driver | `axi4_master_driver` / `axi4_slave_driver` | 按事务驱动接口信号；Slave 支持延迟写数据/响应、响应排序、读交织 | `tvip_axi_*_driver.svh` |
| AXI4-REQ-027 | Monitor | `axi4_master_monitor` / `axi4_slave_monitor`（写/读分离） | 被动采样并重建事务（Observation Model），输出 analysis port | `tvip_axi_*_monitor.svh` |
| AXI4-REQ-028 | Checker | `axi4_checker extends uvm_scoreboard` | 协议规则检查（REQ-010~019），支持错误注入预期检测 | 新增（参考未含，本 Suite 补齐） |
| AXI4-REQ-029 | 断言 SVA | `axi4_assertions` | 时序/握手/边界 SVA（可绑定 interface） | 新增 |
| AXI4-REQ-030 | 覆盖模型 | `axi4_coverage` | 四层覆盖（见 vip-coverage） | 新增 |

### 参考模型 / 存储模型（Slave 侧）

| ID | 组件 | 类型 | 需求说明 |
| --- | --- | --- | --- |
| AXI4-REQ-031 | 存储模型 | `axi4_memory` | Slave 侧内存镜像，读写访问行为模型，支持延迟/错误注入 | `tvip_axi_memory.svh` |
| AXI4-REQ-032 | 状态对象 | `axi4_status` | 保存运行时状态（含 memory 句柄） | `tvip_axi_status.svh` |
| AXI4-REQ-033 | RAL 集成 | `axi4_ral_adapter` / `axi4_ral_predictor` | 提供 UVM RAL 寄存器模型到 AXI 总线的 adapter/predictor | `tvip_axi_ral_*.svh` |

---

## 5. 配置需求（Configuration Interface，REQ-040 ~ REQ-048）

配置空间基于 `tvip_axi_configuration`，并在其基础上补充本 Suite 要求的调试/检查/覆盖开关。分层配置：system → agent → component。

### 5.1 协议与位宽

| ID | 配置项 | 类型/范围 | 默认 | 说明 |
| --- | --- | --- | --- | --- |
| AXI4-REQ-040 | `protocol` | AXI4 / AXI4LITE | AXI4 | 协议模式，影响约束空间 |
| AXI4-REQ-041 | `id_width` | 0–32 | 8 | ID 位宽（AXI4-Lite 固定 0） |
| AXI4-REQ-042 | `address_width` | 1–64 | 32 | 地址位宽 |
| AXI4-REQ-043 | `data_width` | 8/16/32/64/128/256/512/1024 | 32 | 数据位宽（AXI4-Lite 仅 32/64） |
| AXI4-REQ-044 | `max_burst_length` | 1–256 | 256 | 最大突发长度（AXI4-Lite 固定 1） |

### 5.2 行为特性

| ID | 配置项 | 类型/范围 | 默认 | 说明 |
| --- | --- | --- | --- | --- |
| AXI4-REQ-045 | `response_ordering` | IN_ORDER / OUT_OF_ORDER | OUT_OF_ORDER | Slave 响应排序模式 |
| AXI4-REQ-046 | `outstanding_responses` | ≥0 | 0 | 允许的未完成响应数（0=不限制） |
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

---

## 6. 运行环境需求（The Toolkit，REQ-060 ~ REQ-063）

| ID | 需求 | 说明 |
| --- | --- | --- |
| AXI4-REQ-060 | 仿真器支持 | VCS（UVM 1.2，`-ntb_opts uvm-1.2`）；Xcelium / DSim 需验证（参考实现声明支持） |
| AXI4-REQ-061 | 编译入口 | VIP Self Test 工程 `Makefile`（vcs/xcelium 双入口）+ `filelist.f`；正式交付 FuseSoC `.core`（gen-core 生成） |
| AXI4-REQ-062 | 回归分层 | smoke / feature / full（`vip_tool.py regression --tier`） |
| AXI4-REQ-063 | 回归记录 | 统一写入 `reports/quality/run_log.md`，与 Evidence Index 关联 |

---

## 7. 可调试性需求（Debug-ability，REQ-064 ~ REQ-067）

| ID | 需求 | 说明 |
| --- | --- | --- |
| AXI4-REQ-064 | 事务日志 | `item` 全字段 `convert2string`，按 verbosity 分级（参考实现含 begin/end 时间戳） |
| AXI4-REQ-065 | 查询命令 | `debug_report()` 输出当前状态（outstanding、队列深度、激活响应） |
| AXI4-REQ-066 | 错误分类 | 协议错误 / 环境错误 / 数据错误，错误信息带 `[REQ-xxx]` 定位 |
| AXI4-REQ-067 | 协议栈分层 | 事务级（Transaction）为主；复杂场景可加数据链路级（DataLink，如交织/乱序）日志 |

---

## 8. 交付需求（The Manual，REQ-068 ~ REQ-070）

| ID | 需求 | 说明 |
| --- | --- | --- |
| AXI4-REQ-068 | 文档交付 | 用户指南（user-guide）、配置手册（configuration）、架构（architecture）、限制（limitation） |
| AXI4-REQ-069 | 示例与自验证 | `examples/` 最小 DUT + `self_test/` VIP Self Test（smoke/feature/corner/error/random/stress） |
| AXI4-REQ-070 | 源码交付模式 | open（Apache-2.0 兼容；参考 tvip-axi 为 Apache-2.0） |

---

## 9. Qualification Requirements（REQ-071 ~ REQ-076）

进入 Qualification（G5）前必须满足（详见 [`vip-qualification`](../../../../.roo/skills/vip-development-suite/skills/vip-qualification/SKILL.md)）：

| ID | 需求 | 判定 |
| --- | --- | --- |
| AXI4-REQ-071 | 结构/元数据检查 | `vip_tool.py vip-check` PASS（G1/G2 前置） |
| AXI4-REQ-072 | 编译 | UVM 1.2 全工程编译 PASS |
| AXI4-REQ-073 | 自验证回归 | `vip_tool.py regression --tier full` PASS（G3） |
| AXI4-REQ-074 | 覆盖率闭合 | `vip_tool.py coverage-check` PASS（G4） |
| AXI4-REQ-075 | Mutation/错误注入检测率 | `vip_tool.py mutation-test` 达到阈值（G5） |
| AXI4-REQ-076 | FuseSoC Core 校验 | `vip_tool.py gen-core --check` PASS（VLNV `aixsilicon:vip:axi4`） |

---

## 10. Requirement ID 索引

| 分组 | 编号范围 | 数量 |
| --- | --- | --- |
| Feature List | AXI4-REQ-001 ~ 009 | 9 |
| Protocol Rules | AXI4-REQ-010 ~ 019 | 10 |
| 组件需求 | AXI4-REQ-020 ~ 033 | 14 |
| 配置需求 | AXI4-REQ-040 ~ 059 | 20 |
| 运行环境 | AXI4-REQ-060 ~ 063 | 4 |
| 可调试性 | AXI4-REQ-064 ~ 067 | 4 |
| 交付需求 | AXI4-REQ-068 ~ 070 | 3 |
| Qualification | AXI4-REQ-071 ~ 076 | 6 |

> 编号一经发布不得重用；废弃需求标记 `deprecated` 而非删除。

---

## 11. 与 HWIF 契约一致性（G0 检查）

- VIP 接口信号集合、方向、位宽以 `aixsilicon:hwif:axi`（`IFC-AXI-001`）为**唯一基准**；
- 本 VIP 依赖 HWIF 的 `aw`/`w`/`b`/`ar`/`r` 五通道定义与 `resp_encoding`、`burst_types`、`transfer` 语义；
- **命名规范**：信号采用 AXI 标准命名（无下划线，如 `awvalid`/`awaddr`/`awlock`/`awregion`/`awuser`），
  与 HWIF 契约及 `axi_if` 一致；
- **接口信号**：`axi4_if` 采用 HWIF **完整信号集**，含必选 `awlock/arlock`、`awregion/arregion` 与
  capability `awatop`/`*user`（V1.0 保留信号、可置常量）；
- tvip-axi 参考接口仅核心信号与 HWIF 一致，**不得直接照搬**（参考缺 lock/region/atop/user）；
- VIP **不重复定义**接口契约；若 HWIF 契约变更，本需求同步更新并在 CHANGELOG 记录。

---

## 12. 完成标准（G0 Checklist）

- [x] Feature List（REQ-001~009）
- [x] Protocol Rules（REQ-010~019，可映射 Checker/SVA）
- [x] 组件需求（REQ-020~033，Engine 组件清单）
- [x] 配置需求（REQ-040~059，配置空间 + 分层）
- [x] 运行环境需求（REQ-060~063）
- [x] 可调试性需求（REQ-064~067）
- [x] 交付需求（REQ-068~070）
- [x] Qualification Requirements（REQ-071~076）
- [x] 与 HWIF 契约一致（引用 `aixsilicon:hwif:axi`）
