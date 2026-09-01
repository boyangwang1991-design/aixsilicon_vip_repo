# AIXSILICON AXI4 VIP — 架构与设计（Architecture）

> 文档 ID: `aixsilicon:vip:axi4:arch` · 版本: 0.2.0-draft · 状态: Planned（G1 待确认，按 requirement 0.2.0 同步）
>
> 上游输入: [`docs/requirement.md`](requirement.md)（AXI4-REQ-xxx）· HWIF `aixsilicon:hwif:axi`（`IFC-AXI-001`）
> 参考实现: `repos/aixsilicon_vip_repo/reference/tvip-axi`

---

## 1. Profile 判断

| 判定项 | 值 | 理由 |
| --- | --- | --- |
| Profile | **`FULL_UVM`** | AXI4 属复杂协议：5 通道握手、burst/outstanding/ID 排序/交织，需完整 agent/driver/monitor/sequencer/sequence 与 UVM RAL 集成 |
| 参考依据 | registry.yaml `VIP-001` profile=FULL_UVM | 与 VIP Plan 一致 |
| HWIF | `aixsilicon:hwif:axi`（`IFC-AXI-001`） | 接口契约唯一来源，VIP 不重复定义信号/宽度/时序 |

> 原则：VIP ≠ 仅 UVM。虽然 Profile 为 FULL_UVM，但**观察与检查优先于激励**（Observe → Understand → Check → Generate Stimulus）。

---

## 2. 组件列表（Component List）

| 组件 | 类型 | 职责 | 依赖 | 对应 REQ |
| --- | --- | --- | --- | --- |
| `axi4_if` | interface + clocking block + modport | 提供 5 通道**完整 AXI 信号**（含 awlock/awregion/awatop/awuser 等）与 master/slave/monitor 时钟块；采样边界 | HWIF `IFC-AXI-001` | AXI4-REQ-020 |
| `axi4_types_pkg` | package | 类型/枚举/编解码函数（id/address/burst/response/cache/prot/qos） | - | AXI4-REQ-020 |
| `axi4_configuration` | `uvm_object` | 配置空间（§5 requirement） | - | AXI4-REQ-022 |
| `axi4_status` | `uvm_object` | 运行时状态（含 memory 句柄） | config | AXI4-REQ-032 |
| `axi4_memory` | `uvm_object` | Slave 存储镜像/行为模型 | status | AXI4-REQ-031 |
| `axi4_item` | `uvm_sequence_item` | 读/写事务描述 + 时序事件 | config/status | AXI4-REQ-021 |
| `axi4_payload_store` | helper | 事务负载暂存（支持 gapped 写数据、交织） | - | AXI4-REQ-026/027 |
| `axi4_master_agent` | `uvm_agent` | Master 侧组件组装（ACTIVE/PASSIVE） | seq/drv/mon | AXI4-REQ-023 |
| `axi4_master_sequencer` | `uvm_sequencer` | Master 序列仲裁 | - | AXI4-REQ-025 |
| `axi4_master_driver` | `uvm_driver` | Master 激励（AW/W 地址数据 + B/R 接收） | vif | AXI4-REQ-026 |
| `axi4_master_write_monitor` / `axi4_master_read_monitor` | `uvm_monitor` | Master 侧被动采样写/读通道，重建事务 | vif | AXI4-REQ-027 |
| `axi4_slave_agent` | `uvm_agent` | Slave 侧组件组装（ACTIVE/PASSIVE） | seq/drv/mon | AXI4-REQ-024 |
| `axi4_slave_sequencer` | `uvm_sequencer` | Slave 序列仲裁 | - | AXI4-REQ-025 |
| `axi4_slave_driver` | `uvm_driver` | Slave 激励（AW/W 接收 + B 响应 + AR 接收 + R 数据）；延迟/排序/交织 | vif | AXI4-REQ-026 |
| `axi4_slave_write_monitor` / `axi4_slave_read_monitor` | `uvm_monitor` | Slave 侧被动采样 | vif | AXI4-REQ-027 |
| `axi4_slave_data_monitor` | `uvm_monitor` | 写数据（W 通道）专项监控 | vif | AXI4-REQ-027 |
| `axi4_checker` | `uvm_scoreboard` | 协议规则检查（REQ-010~019）+ 错误注入预期 | analysis ports | AXI4-REQ-028 |
| `axi4_assertions` | SVA module | 握手/时序/边界断言（绑定 interface） | vif | AXI4-REQ-029 |
| `axi4_coverage` | `uvm_subscriber` | 四层覆盖模型 | analysis ports | AXI4-REQ-030 |
| `axi4_env` | `uvm_env` | 顶层环境（master+slave agent + checker + coverage + ral） | - | AXI4-REQ-023/024 |
| `axi4_ral_adapter` / `axi4_ral_predictor` | RAL | 寄存器模型总线适配/预测 | - | AXI4-REQ-033 |
| `axi4_violation_injector` | agent 组件 | 协议违规注入（错误注入框架） | - | AXI4-REQ-057 |

### 组件裁剪与 Profile 矩阵核对

| 组件 | FULL_UVM 应有 | 本 VIP | 说明 |
| --- | --- | --- | --- |
| interface | ✅ | ✅ | |
| config | ✅ | ✅ | |
| transaction | ✅ | ✅ | |
| driver | ✅ | ✅ | master/slave |
| sequencer | ✅ | ✅ | master/slave |
| sequence | ✅ | ✅ | base/read/write/access/default |
| monitor | ✅ | ✅ | 写/读分离 + data monitor |
| checker | ✅ | ✅ | 本 Suite 补齐 |
| assertion | ✅ | ✅ | 本 Suite 补齐 |
| coverage | ✅ | ✅ | 本 Suite 补齐 |
| agent | ✅ | ✅ | master/slave |

---

## 3. 三大核心模型

### 3.1 Stimulus Model（Stimulus → Driver → Interface）

```text
Sequence (axi4_base/read/write/access/default)
   │  item (axi4_item)
   ▼
Driver (master_driver / slave_driver)
   │  clocking block (master_cb / slave_cb)
   ▼
axi4_if (AW/W/B/AR/R 通道)
```

- Master 侧：`axi4_master_write_sequence` / `axi4_master_read_sequence` 生成事务 → `axi4_master_driver` 驱动 AW/W（或发起 AR）并接收 B/R。
- Slave 侧：`axi4_slave_default_sequence` 通过监控重建的请求 → `axi4_slave_driver` 控制 READY 背压、响应延迟/排序/交织（`response_ordering`、`enable_response_interleaving`）、以及响应类型（`response_weight_*`）。
- 参考实现对应：`tvip_axi_master_*_sequence`、`tvip_axi_slave_*_sequence`、`tvip_axi_*_driver`。

### 3.2 Observation Model（Interface → Monitor → Transaction）

```text
axi4_if (monitor_cb)
   ▼
Monitor（master/slave 写监控 + 读监控 + data monitor）
   │  重建 axi4_item（含时序 begin/end 事件与时间戳）
   ▼
analysis port（address_item_port / request_item_port / response_item_port）
```

- 被动采样所有通道，重建完整事务（id/addr/len/size/burst/memory_type/protection/qos/data/strobe/response）。
- 参考实现对应：`tvip_axi_monitor_base`（地址/写数据/响应三线程）、`tvip_axi_payload_store`（支持 gapped 写数据与交织重建）。

### 3.3 Qualification Model（Transaction → Checker/Coverage/Assertion）

```text
analysis port ──► axi4_checker（协议规则 REQ-010~019）
             └─► axi4_coverage（四层覆盖）
SVA ──► axi4_assertions（握手/时序/边界）
```

- **Checker**：验证事务是否符合协议（4KB 边界、WLAST/RLAST、ID 排序、响应编码、复位行为等），并验证 Violation Injector 注入的错误被正确检测（Mutation 检测率）。
- **Coverage**：Requirement / Feature / Cross / Assertion 四层覆盖，闭合后进入 G4。
- **Assertions**：SVA 覆盖握手规则（VALID 不依赖 READY、传输条件、4KB 边界、复位）。
- 参考实现对应：checker/coverage/assertions 为**本 Suite 新增能力**（tvip-axi 参考未含协议检查与覆盖，需补齐以达 AIXSILICON 门禁）。

---

## 4. 模式支持（Modes）

| 模式 | 配置 | 组件激活 | 场景 |
| --- | --- | --- | --- |
| `ACTIVE_MASTER` | agent_mode=ACTIVE_MASTER | master 全组件 | 激励 DUT-Slave |
| `ACTIVE_SLAVE` | agent_mode=ACTIVE_SLAVE | slave 全组件 + memory | 激励 DUT-Master |
| `PASSIVE` | agent_mode=PASSIVE | 仅 monitor + checker + coverage | SoC 集成监控，不产生激励 |
| `DISABLED` | agent_mode=DISABLED | 无 | 拓扑中未使用 |

> 支持 Master-only、Slave-only 与全环境（`axi4_env` 同时含 master/slave agent 做自测试/环回）。

---

## 5. 与 HWIF 的关系

| 项 | 内容 |
| --- | --- |
| HWIF 引用 | `aixsilicon:hwif:axi`（`IFC-AXI-001`，`aixsilicon:interface:axi:1.0.0` core） |
| 信号来源 | 5 通道（aw/w/b/ar/r）信号集合、方向、位宽、握手与语义以 HWIF 契约为**唯一基准** |
| 命名规范 | 采用 AXI 标准命名（无下划线，如 `awvalid`/`awaddr`/`awlock`/`awregion`/`awuser`），与 HWIF 契约及 `axi_if` 一致 |
| 复用方式 | VIP `axi4_if` 的端口与 HWIF `axi_if`/`axi_pkg` 聚合结构对齐（View B/A）；VIP 不重新定义接口契约 |
| 完整信号集 | VIP 采用 HWIF **完整 AXI 信号**：含必选 `awlock/arlock`、`awregion/arregion`，以及 capability `awatop`/`awuser/wuser/buser/aruser/ruser`（V1.0 保留信号、可置常量）；`awlock/arlock` 在 AXI4 中**仅表达 exclusive access**（REQ-0103/0115），不表达 AXI3 式 locked transaction |
| 与 tvip-axi 差异 | tvip-axi 参考接口仅核心信号与 HWIF 一致，**缺 lock/region/atop/user**；`axi4_if` 以 HWIF 契约为准，不得照搬 tvip-axi |
| 变更联动 | HWIF 契约变更 → 本架构同步更新 + CHANGELOG 记录（HWIF 为唯一 SSOT） |

**依赖链**：

```text
aixsilicon:hwif:axi ──► aixsilicon:vip:axi4 ──► ip-development-suite / soc-integration-suite
```

---

## 6. 包结构与目录布局

```text
vip/amba/axi4/
├── docs/
│   ├── requirement.md        # 本 VIP 需求 SSOT（G0）
│   └── architecture.md       # 本文档（G1）
├── src/
│   ├── axi4_types_pkg.sv     # 类型/枚举/编解码（源自 tvip_axi_types_pkg）
│   ├── axi4_if.sv            # interface + clocking block + modport（对齐 HWIF）
│   ├── axi4_pkg.sv           # 包入口
│   ├── axi4_configuration.sv
│   ├── axi4_status.sv
│   ├── axi4_memory.sv
│   ├── axi4_item.sv
│   ├── transaction/
│   ├── agent/                # master_agent / slave_agent / driver / monitor / sequencer
│   ├── sequences/            # base / read / write / access / default
│   ├── coverage/             # axi4_coverage.sv
│   ├── checker/              # axi4_checker.sv + axi4_assertions.sv
│   ├── env/                  # axi4_env.sv
│   └── ral/                  # axi4_ral_adapter.sv / axi4_ral_predictor.sv
├── sva/                      # axi4_assertions（SVA）
├── fault_injection/          # violation injector + mutation cases
├── self_test/                # VIP Self Test（tb + tests）
├── examples/                 # 最小集成示例 DUT
├── fusesoc/                  # .core（gen-core 生成，VLNV aixsilicon:vip:axi4）
└── qualification/            # RTM / reports / evidence
```

---

## 7. 时序与关键实现要点

- **时钟块**：`master_cb`/`slave_cb`/`monitor_cb` 三套 clocking block（源自 `tvip_axi_if.sv`），驱动/监控共享同一 vif 但按角色采样。
- **接口信号**：`axi4_if` 以 HWIF `IFC-AXI-001` 为准生成，采用**完整 AXI 信号集**（无下划线命名）：
  - 必选：`awvalid/awready/awid/awaddr/awlen/awsize/awburst/awlock/awcache/awprot/awqos/awregion`、`wvalid/wready/wdata/wstrb/wlast`、
    `bvalid/bready/bid/bresp`、`arvalid/arready/arid/araddr/arlen/arsize/arburst/arlock/arcache/arprot/arqos/arregion`、`rvalid/rready/rid/rdata/rresp/rlast`；
  - capability 保留信号：`awatop`、`awuser/wuser/buser/aruser/ruser`（V1.0 可置常量/不做驱动，后续版本激活）；
  - 在 tvip-axi 基础上**新增 `awlock/arlock` 与 `awregion/arregion`**（HWIF 必选）。
  - **Exclusive 语义**：`awlock/arlock=1` 表达 **exclusive access**（master 发起独占读/写，slave memory 维护独占标记与 EXOKAY 响应，REQ-0103/0115）；**不支持** AXI3 式 locked transaction。
- **握手驱动**：READY 默认值与延迟配置（`default_*ready` + `*_ready_delay`）实现可控背压；VALID 保持规则由 driver 保证、由 checker/SVA 验证。
- **响应引擎（Slave）**：按 `response_ordering` 与 ID 分流至独立响应队列；`start_delay`/`response_delay` 控制延迟；交织粒度受 `min/max_interleave_size` 约束（源自 `tvip_axi_slave_driver` 的 start_delay_consumer / response_item 机制）。
- **写数据对齐**：`axi4_payload_store` 支持 W 数据与 AW 地址到达顺序不一致（gapped write data）与读数据交织重建；**W 数据必须按 AW 事务顺序提供，禁止 AXI3 式 write-data interleaving**（REQ-0114）。
- **数据传输语义**：支持 narrow / unaligned / WSTRB（partial & sparse strobe）——`axi4_item` 携带 strobe 语义，`axi4_memory` 仅更新 WSTRB=1 的 byte，Monitor 正确重建 byte lane（REQ-0100/0101/0102）。
- **错误注入**：`axi4_violation_injector` 基于配置在指定通道注入违规（handshake/4KB/burst/ID ordering/response），由 `axi4_checker` 检测，形成 Mutation 检测率。

---

## 8. 完成标准（G1 Checklist）

- [x] Profile 判断合理（FULL_UVM，理由充分）
- [x] 组件裁剪与 Profile 一致（对照组件矩阵）
- [x] 三大核心模型明确（Stimulus / Observation / Qualification）
- [x] 与 HWIF 契约一致（引用 `aixsilicon:hwif:axi`）
- [x] 与 docs/requirement.md 能力覆盖一致（REQ-001~076 + 0100/0103/0110 扩展；Exclusive 与 AXI3 Locked 语义分离）
