# AXI4-Stream VIP Requirement Specification（需求规格）

> 本文件是源码设计文档，源自本仓需求合同 `../axi_stream_vip_contract.md`
> （document_id `aixsilicon:vip:axi4_stream:req`，v0.1.0）。
> 本文只记录需求，不记录本次执行结果。运行结果、回归/覆盖数值、Gate 与证据
> 写入本 VIP 的 `reports/<run-id>` 报告 metadata。
> 机器可读的 REQ ID 权威清单在 `config/requirements.yaml`；
> 冻结的 case/priority/bin 集合在 `config/verification-plan.yaml`。

---

> **Document ID**: `aixsilicon:vip:axi4_stream:req`
> **VIP Name**: `axi4_stream`
> **Category**: `amba`
> **Protocol / Interface**: `AMBA AXI4-Stream（ARM IHI 0051A）`
> **Target Version**: `1.0.0`
> **Profile**: `FULL_UVM`
> **Status**: `Draft`
> **Owner**: `amba-vip`
> **Reference Specification**: `AMBA AXI4-Stream, ARM IHI 0051A`
> **HWIF Contract**: 当前仓库未提供 AXI4-Stream HWIF 契约；见 §23 与架构 §6
> **Target VLNV**: `aixsilicon:vip:axi4_stream:1.0.0`

---

# 1. Overview

## 1.1 Purpose

本 VIP 验证 AMBA AXI4-Stream 接口，提供主动激励（Source）、接收背压（Sink）、
被动监测、协议检查、功能覆盖、错误注入、性能统计与可复现调试能力，
用于 FIFO、Register Slice、Width Converter、DMA 流接口、MUX/DEMUX、
流式计算 IP、CDC Bridge 的接口与端到端验证。

REQ-SCP-001：VIP 必须独立完成合法激励、接收背压、总线监测、协议检查、功能覆盖、错误注入和可复现调试。

REQ-SCP-002：必须支持 beat 级和 packet 级 API，并保留四态总线观测；支持连续无包流、单包、多包和按 `(TID,TDEST)` 标识的交织流。

REQ-SCP-003：必须提供可复用的端到端流比较组件；默认比较模式必须显式配置，不得假定所有 DUT 都逐拍透明。

REQ-SCP-004：每个 agent 对应一个时钟域和一个单向 AXI4-Stream 接口；双向链路使用两个 agent；CDC DUT 两侧分别部署 agent，由 scoreboard 跨域关联。

REQ-SCP-005：FULL_UVM、PASSIVE_UVM、CHECKER_ONLY 三种构建方式必须可用。CHECKER_ONLY 不依赖 UVM package，也不启动驱动线程。

## 1.2 Design Principles

1. **Protocol Correctness** —— 行为符合 AMBA AXI4-Stream（IHI 0051A）。
2. **Reusable** —— 不绑定具体 DUT、项目或 Testbench。
3. **Configurable** —— 端口存在性与运行行为均显式配置，无隐式推断。
4. **Observable** —— monitor 独立重建 beat/packet 并保留四态原始值。
5. **Checkable** —— 协议违规结构化输出并区分 PROTOCOL/APPLICATION/WATCHDOG/CONFIG/VIP_INTERNAL。
6. **Extensible** —— 用户无需修改源码即可扩展 sequence、policy、USER 映射与参考模型。
7. **Debuggable** —— 提供事务、错误、统计与 epoch 信息。
8. **Qualifiable** —— VIP 自身可被系统化验证（自验证 fixture + golden vector + 变异）。

---

# 2. Protocol Capability

本章定义 VIP 支持的协议能力与参数/配置合同，不描述实现方式。

## 2.1 参数与配置合同

REQ-CFG-001：静态端口形状使用 elaboration 参数，运行期行为使用 config object；不得在传输中改变位宽或端口存在性。

REQ-CFG-002：缺省信号必须在统一 adapter 中归一化：TREADY 缺省为 1；TKEEP 缺省为全 1；TSTRB 缺省时按有效 TKEEP 归一化；两者均缺省为全 1；TID/TDEST 缺省为 0。未存在的物理信号不得参加 X/stability 检查。

REQ-CFG-003：TLAST 缺省时必须显式选择连续流或应用定义的边界策略；FIXED_BEATS 是本地应用解释，不能宣称在总线上检测到 TLAST。不能统一将缺省 TLAST 解释为“一拍一包”。

REQ-CFG-004：USER_WIDTH 不要求为 lane 数的整数倍；只有选择 `PER_BYTE` 映射时才检查整除关系。默认 TUSER 是原始不透明位向量。

REQ-CFG-005：HAS_TDATA=0 时禁止开启 TKEEP/TSTRB，数据宽度不产生有效数据语义。物理占位端口至少 1 bit，避免 `[-1:0]`；通过 wrapper 隐藏缺省端口，行为与检查必须按存在性裁剪。

REQ-CFG-006：不支持的配置必须在 build/elaboration 阶段明确失败，输出配置名、值和原因，禁止静默截断。virtual interface 参数与 agent 参数不一致必须失败。

REQ-CFG-007：约束随机化失败必须报告，不能继续使用旧 item。支持保存有效配置、随机 seed、测试名和版本，完成可重放记录。

参数支持目标（需求合同 §2 表）：`DATA_WIDTH` 8～4096（8 的倍数）、`HAS_TDATA/HAS_TREADY/HAS_TKEEP/HAS_TSTRB/HAS_TLAST`、
`ID_WIDTH/DEST_WIDTH` 0～32、`USER_WIDTH` 0～4096、`ROLE`、`PACKET_MODE`、
`COMPARE_MODE`、`MAX_OPEN_STREAMS`（默认 256，稀疏容器）、`MAX_PACKET_BEATS`（默认 65536，VIP 资源限制）、
`CAPTURE_MODE`、`MAX_READY_WAIT`、`MAX_PACKET_IDLE`、`CHECK_ENABLE`/`COVERAGE_ENABLE`。

## 2.2 握手与字节语义

REQ-PRO-001：只有在 ACLK 上升沿、复位无效且 `TVALID===1 && effective_TREADY===1` 时产生一次成功传输。valid-only 和 ready-only 均不是成功传输。

REQ-PRO-002：Source 有待发送数据时，不得以观察到 TREADY 为拉高 TVALID 的前提；必须支持 sink 等待 TVALID 后才拉高 TREADY 的合法交互。

REQ-PRO-003：TVALID 拉高后，直到握手完成必须保持；背压期间 TDATA、TKEEP、TSTRB、TLAST、TID、TDEST、TUSER 所有存在的字段保持稳定。稳定性检查覆盖解除背压并完成握手的那个边沿。空闲时不限制 payload 变化。

REQ-PRO-004：允许 TREADY 在 TVALID 之前、同周期或之后拉高；允许任意合法背压和连续每周期一拍。协议不提供天然的最大等待周期。

REQ-PRO-005：按 lane `i` 对应 `TDATA[8*i +: 8]`，低 lane 先进入规范化逻辑流。应用多字节数值的端序由应用指定，不能混入总线 lane 排序。

REQ-PRO-006：合法随机流必须支持稀疏 TKEEP、非尾拍 partial beat、POSITION bytes、全 NULL beat；不得将“只有尾拍能不满”“TKEEP 必须连续”硬编码为协议规则。

REQ-PRO-007：全 NULL beat 可携带 TLAST，组包器必须保留对应包结束事件。逻辑比较时不能因删除所有 NULL 而丢掉包边界。无 TLAST 的全 NULL beat 是否允许被 DUT 消除，由其流变换合同配置。

REQ-PRO-008：包不受 AXI memory-mapped 的 256 beat 或 4KB 边界约束；无地址和 burst 字段。测试应覆盖大于 256 beat 的包。

REQ-PRO-009：同一 `(TID,TDEST)` 的 beat 构成相应逻辑流，允许不同流在 beat 间交织。一个 stream key 只维护一个当前未完成包；协议没有另一个 packet ID 来区分该 key 下重叠的包。

REQ-PRO-010：TID/TDEST 可以在成功传输之间变化；不得在等待当前拍接收期间变化。变化后属于另一个 key，不应直接判为“包内 ID 错误”。不允许交织的 DUT profile 可另外约束。

## 2.3 明确边界（V1.0 不做的能力）

| 项目 | V1.0 定义 |
|---|---|
| AXI memory-mapped | 不实现 AW/W/B/AR/R、地址、burst、response、exclusive |
| RAL | AXI4-Stream 无寄存器访问语义；不提供通用 RAL adapter |
| TUSER | 支持传输、随机化、掩码、比较及自定义解码，不内置统一业务含义 |
| 时钟/复位 | 顶层专用 agent 拥有驱动权；流 agent 响应复位 |
| CDC | 验证数据完整性与复位合同，不宣称证明亚稳态安全 |
| AXI5-Stream/TWAKEUP/奇偶校验 | 后续版本 |
| Pass-through BFM | V1.0 不要求插入式转发 BFM |

---

# 3. Protocol Rules

## 3.1 规则清单（Checker / SVA）

| Rule ID | 检查要求 | 缺省 |
|---|---|---|
| AXIS-P001 | 复位期间 TVALID 为 0 | ERROR |
| AXIS-P002 | 复位释放后的首个采样边沿仍观察到 TVALID 为 0 | ERROR |
| AXIS-P003 | stall 后到完成接收前 TVALID 持续为 1 | ERROR |
| AXIS-P004 | stall 期间及恢复握手边沿，所有存在的 payload/sideband 稳定；每个字段有独立诊断子码 | ERROR |
| AXIS-P005 | TVALID 有效时，TKEEP=0 不得对应 TSTRB=1 | ERROR |
| AXIS-P006 | 复位外 TVALID、存在的 TREADY 不得未知 | ERROR |
| AXIS-P007 | TVALID 有效时存在的 qualifier、TLAST、ID、DEST 不得未知 | ERROR |
| AXIS-P008 | TVALID 有效时 DATA bytes 不得未知；POSITION/NULL 的数据值不做有效载荷 X 检查 | ERROR |
| AXIS-P009 | TVALID 有效时 TUSER 的有效检查位不得未知；缺省 mask 为全有效 | ERROR |
| AXIS-A001 | 固定包长、最大包长、禁止交织、连续 TKEEP、仅末拍 partial 等 | 关闭，应用配置启用 |
| AXIS-A002 | TUSER 的 SOF/EOL/错误标志/张量含义及传播规则 | 关闭，应用插件启用 |
| AXIS-W001 | ready 等待超过配置阈值 | 关闭；启用后 WARNING |
| AXIS-W002 | packet 长时间无进展或无结束 | 关闭；启用后 WATCHDOG |
| AXIS-C001 | 位宽、端口、模式不兼容 | FATAL |
| AXIS-I001 | 内部队列/组包上限溢出、对象生命周期错误 | ERROR/FATAL |

REQ-CHK-001：SVA 可 bind，也可直接例化；复位取消未完成的时序检查。P004 的稳定性检查与 P008 的数据值有效性检查独立，不能因为 NULL 数据不比较而放宽 stall 稳定性。

REQ-CHK-002：P002 时间合同：ARESETn 拉高后的第一个 ACLK 上升沿仍采样到 TVALID=0；source 可在该边沿之后驱动下一周期 valid，后续边沿才接收。测试必须覆盖 release 相位。

REQ-CHK-003：每条规则可单独开关、改变严重度、设置限报次数，并输出结构化事件。SVA 与 UVM checker 同时启用时必须避免重复计数，或明确其关联 ID。

REQ-CHK-004：纯黑盒 Checker 不能仅凭波形证明 source 没有等待 ready 才产生 valid，也不能证明接口不存在组合路径。前者使用 WAIT_VALID 对抗测试及进展条件，后者由结构检查/设计约束补充，不伪装成完整 SVA 证明。

REQ-CHK-005：不能要求复位时 TREADY=0，也不能普遍要求 TDATA/TLAST/TID 等 payload 清零。额外要求只能来自 DUT profile。

## 3.2 Checker 类别

Checker 必须区分 PROTOCOL、APPLICATION、WATCHDOG、CONFIG、VIP_INTERNAL 五类，
不得将 vendor 建议或业务约束统一报告为协议错误。

---

# 7. Configuration

配置分层为 `VIP → Agent → Component`，分四类：

* **Protocol（结构）**：由 elaboration 参数给出（HAS_*、宽度、ID/DEST/USER 宽度），
  在 build 阶段与 virtual interface 核对（REQ-CFG-001/006）。
* **Behavior（运行）**：`ROLE`、`PACKET_MODE`、`COMPARE_MODE`、背压策略、
  drop/replication 与路由合同、CDC 复位合同。
* **Timing**：`idle_cycles`、ready delay/概率/周期、`MAX_READY_WAIT`、
  `MAX_PACKET_IDLE`。
* **Verification**：`CHECK_ENABLE`、`COVERAGE_ENABLE`、逐组覆盖开关、
  错误注入、日志与统计。

REQ-INT-003（配置更新约束）：运行期间可更新 ready policy、日志及统计选项；影响组包/比较语义的配置只能在 drain/复位后更新，并记录配置 epoch。Role 运行期切换不纳入 V1.0。

预定义配置 profile：`DEFAULT`、`ZERO_DELAY`、`HEAVY_BACKPRESSURE`、`STRESS`、`PASSIVE`。

---

# 8. External Interface

## 8.1 Public API

VIP 必须提供稳定、文档化的公共接口（详见 `docs/user-guide.md`）：

| 类别 | 能力 |
|---|---|
| 事务模型 | beat item、packet item（`from_bytes`/`from_beats`/增量）、ready policy item、observed beat/packet、error event |
| 激励 API | `send_beat`、`send_packet`、序列库（§12 场景）、`set_ready_policy` |
| 观测 API | `beat_ap`、`packet_ap`、`error_ap`、`reset_ap`、`cycle_ap` |
| 状态/统计 API | `get_stats`、`open_packet_count`、`accepted_count`、配置 epoch |
| 违规 API | 结构化 error event（rule ID/类别/严重度/实例/epoch/时间/周期/前后采样/关联 stream/packet/注入关联） |
| 比较 API | `compare_mode`（EXACT_BEAT/LOGICAL_STREAM/CUSTOM）、reference model 扩展点 |

REQ-TXN-001：必须分别定义 beat item、packet item、ready policy item、observed event 和 error event。控制请求与总线事实分离。

REQ-TXN-002：packet API 必须支持 `from_bytes`、`from_beats` 和增量构造；from_bytes 默认生成紧密排列 DATA、最后一拍用 TKEEP 标识余数。无 TKEEP 时不能静默填充有效字节，应拒绝无法精确表示的长度，或要求明确 padding 合同。

REQ-TXN-003：支持 0 数据字节包、1 字节包、单 beat、长包。0 字节包要求相应端口能表达，例如带 TLAST 的全 NULL beat；只有 POSITION 的包也必须可表达。无法表达的请求必须失败。

REQ-TXN-004：完成状态至少为 ACCEPTED、ABORTED_BY_RESET、CANCELED_BEFORE_VALID、WATCHDOG_EXPIRED、REJECTED_CONFIG。ACCEPTED 仅表示所有相应 beat 被接口接收，不表示 DUT 已完成业务处理。

REQ-TXN-005：发送前取消允许撤销排队 item；一旦 TVALID 已拉高，正常取消或 timeout 不得撤销当前拍。默认让该拍继续等待并报告 watchdog；需要中止仿真或复位时通过 test policy 处理，禁止正常 driver 自行破坏协议。

REQ-TXN-006：支持 `send_beat`、`send_packet`、`set_ready_policy`、`wait_for_accepted`、`wait_for_packet`、`drain`、统计快照等能力。非阻塞提交必须返回 handle，队列有界且达到上限时有明确阻塞/失败语义。

REQ-TXN-007：copy/clone/compare/print/pack 必须完整覆盖业务字段；analysis port 发布独立快照，防止复用可变对象导致历史数据被覆盖。

## 8.2 Interface Connection

REQ-INT-001：驱动与采样 skew 在 architecture.md 明确；monitor 与 checker 对同一边沿的解释一致，避免 blocking assignment race。

REQ-INT-002：通过 virtual interface、uvm_config_db、analysis port 和标准 sequence 通道集成；不得依赖 DUT 内部层次路径或全局可变 singleton。

REQ-INT-004：FuseSoC 至少提供 compile、smoke、regression、checker_only 目标，外部库版本固定；文档提供 Source-DUT、DUT-Sink、两侧比较和 Passive 例子。

REQ-INT-005：主验收使用支持 class、constraint、covergroup、SVA 和四态语义的 UVM 仿真环境。UVM 1.2 为兼容基线；具体仿真器与版本在 G1 固定。Verilator 可提供受限目标，但必须列出其实际缺失能力，不将二态结果作为 X 检查验收证据。

---

# 10. Coverage

## 10.1 覆盖组

| 覆盖组 | 要求 |
|---|---|
| Handshake | ready-before-valid、valid-before-ready、同拍、背靠背、不同 stall 长度 |
| Packet | 单/多 beat、0/1/边界字节、长包、TLAST stall、abort、连续流 |
| Qualifier | DATA/POSITION/NULL、全 keep/稀疏/全 NULL、非法组合 |
| Stream | 单 key、多 key、交织深度、key 切换、同 key 多包 |
| Sideband | ID/DEST 边界和典型值，TUSER 模式/掩码；不枚举全位空间 |
| Reset | idle/valid/stall/last/多未完成包阶段，释放后首拍 |
| Configuration | 数据宽度、缺省端口组合、各构建模式 |
| Errors | 每个 rule 的注入、检出、预期匹配 |
| Transform | 扩宽/缩宽、非整数宽度比、partial、POSITION、NULL、USER mapping |

REQ-COV-001：握手覆盖只在成功接收时采样；stall 长度在等待结束/中断时采样；reset/error 独立采样。不得用“生成过 item”替代“总线发生过”。

REQ-COV-002：重点交叉至少包含 `TLAST × stall`、`qualifier × packet_position`、`reset_phase × handshake_state`、`stream_interleave × backpressure`、`width_ratio × partial × TLAST`。

REQ-COV-003：配置关闭的功能必须排除对应 bin，不可通过权重隐藏未覆盖；不可达 bin 需要可审计 waiver。不要全量交叉所有参数造成覆盖爆炸。

## 10.2 冻结 bin 清单

机器可读的完整 bin ID 集合在 `config/verification-plan.yaml` 的 `coverage_bins`
（四项：requirement_coverage / feature_coverage / cross_coverage / assertion_coverage）。
覆盖报告必须提交完整 bin→hit 映射，不能只提交百分比或删除未命中 bin。

---

# 13. Debug

REQ-MON-002：提供独立 beat_ap、packet_ap、error_ap、reset_ap，必要时提供 cycle_ap。beat_ap 只发布已完成握手；cycle_ap/error_ap 可包含未完成或非法采样。

REQ-MON-005：仿真结束时报告每个未完成包、最后握手、等待状态和缓存占用。连续流在约定 drain 边界可正常结束；TLAST 模式未完成包按 test policy 判定，不能静默 PASS。

REQ-MON-006：旁路中途启用监控时标识 PARTIAL_CAPTURE；第一个包可能缺包头，不能拿它进行完整端到端比较。严格验收从复位开始监控。

REQ-MON-007：保留原始四态值；遇到未知 key 或 qualifier 时报告并按明确策略隔离该事件，不能将 X 转成 0 后进入正常 scoreboard。

REQ-PERF-001：至少报告 accepted beats、data bytes、position bytes、null bytes、完成/中止包数、源空闲周期、`valid&&!ready` 周期和活动周期。

REQ-PERF-002：有效吞吐使用 DATA bytes/观测时间；总线利用率使用 accepted beats/有效时钟周期。position byte 不计为有效数据吞吐。复位周期与 warm-up 窗口是否排除必须明确。

REQ-PERF-003：单端口可报告 valid-to-handshake 等待时间；端到端延迟必须有两端关联，不能将单端等待当成 DUT 延迟。跨时钟域使用统一仿真时间，不直接相减两侧周期号。

REQ-PERF-004：支持按接口、key、packet 汇总；长测试默认限制历史存储与详细日志，支持 streaming scoreboard/摘要输出，禁止未完成连续流造成无界内存增长。

---

# 17. Machine-readable Capability

- `config/requirements.yaml`：权威 REQ ID 清单（id、优先级、家族、验证方法）。
- `config/verification-plan.yaml`：冻结的 requirement/architecture/regression/mutation/rtm
  case 集合与四项 coverage bin 清单（`vip.plan/v1`）。
- `config/qualification.yaml`：覆盖阈值（只能比套件缺省更严格）。
- `.core`（FuseSoC CAPI=2）：VLNV `aixsilicon:vip:axi4_stream:1.0.0`，
  提供 `default`/`lint`/`smoke`/`unit_sim`/`regression`/`example` 目标。
- 源码内 `axi4_stream_config::validate`：结构配置在 build 阶段失败并输出配置名/值/原因。

---

# 18. Engineering

## 18.1 Source 生成

*target_version 内的实现状态见 G3*

REQ-SRC-001：支持 directed、constrained-random、可重放文件输入，以及用户自定义 sequence；同一份输入在相同配置、seed 和仿真器版本下可复现。

REQ-SRC-002：支持零间隔连续发送、固定/随机 beat 间隔、packet 间隔、稀疏流、突发式流量。所有延迟发生在尚未断言 TVALID 的阶段；不得在 stall 中更换 payload。

REQ-SRC-003：必须可连续一拍/周期，不得由于 `item_done`、事务获取或 packet 切换自动插入气泡。实现预取并保证采样/驱动无 race。

REQ-SRC-004：支持多 stream 的 round-robin、weighted-random 和显式顺序调度；支持 packet 连续和 beat 交织。保持每个 key 内已提交顺序。

REQ-SRC-005：合法生成器与非法注入器分离；缺省只能产生满足当前 profile 的合法事务。source 无权驱动 TREADY，也不能依赖 monitor 返回完成信息作为未来发送的循环前提。

## 18.2 Sink 与背压

REQ-SNK-001：Sink 只驱动 TREADY，所有接收数据来自 monitor，不得修改 DUT 驱动的信号。必须支持 ALWAYS_READY、FIXED_DELAY、RANDOM、PERIODIC、WAIT_VALID、BURST_ACCEPT、TARGETED、BUFFER_MODEL、SCRIPTED 九种背压模式。

REQ-SNK-002：必须覆盖 TLAST 等待、首拍等待、长时间等待后恢复，以及 ready 先到和 valid 先到；同一拍不可被重复接收。

REQ-SNK-003：ready 决策和接收处理不能形成软件环路死锁。BUFFER_MODEL 达到容量前必须考虑已承诺的接收周期，不能因为 monitor 队列溢出静默丢拍。

REQ-SNK-004：HAS_TREADY=0 时关闭所有背压驱动，接收吞吐必须匹配每周期一拍；资源不足是 VIP 容量错误，不能假装接口施加了背压。

## 18.3 Monitor 与组包

REQ-MON-001：Monitor 必须完全依赖实际 interface，不得使用 driver item 作为总线事实。Passive 模式不得改变任何总线或时钟复位信号。

REQ-MON-003：按 `(interface_id,reset_epoch,TID,TDEST)` 独立组包；TLAST 在完成握手后结束该 key 的包。其他 key 的传输不结束本 key 的包。

REQ-MON-004：无 TLAST 模式必须支持无限连续流的增量输出，不能一直等待包结束或无限保存数据。FIXED_BEATS 的结束必须标为 synthetic，不冒充协议 TLAST。

## 18.4 复位

REQ-RST-001：支持 ARESETn 异步断言、同步释放的合法使用；测试时钟/复位由顶层统一控制，避免多个 agent 同时驱动。

REQ-RST-002：复位断言必须使 Source 停止有效发送；已握手历史保留，当前未完成 beat 标为 ABORTED_BY_RESET，排队但未发送 item 按 FLUSH/RETAIN 配置处理，默认 FLUSH。释放后如需重发必须形成新 epoch 下的明确请求。

REQ-RST-003：复位不能虚构 AXI4-Stream 的 error response。接口没有返回响应；VIP 的 abort 仅是测试软件状态。

REQ-RST-004：monitor 关闭当前未完成 packet 并发布 reset-aborted 事件，reset_epoch 增加；scoreboard 根据 DUT 合同处理已接受但尚未输出的数据。

REQ-RST-005：CDC 两侧独立复位时必须配置 BOTH_FLUSH、PRESERVE 或 CUSTOM 合同，以及两侧 epoch 的关联；未知合同应停止严格比较并报告配置缺失，不能假定任意单侧复位会清空另一侧。

REQ-RST-006：覆盖空闲、首拍、stall 中、TLAST stall、包中、多 key 未完成时复位，以及连续多次复位、复位后首拍和队列保留/清除。

REQ-RST-007：最小复位脉宽是环境/DUT 约束，不能把特定 vendor 的 16 周期要求作为所有 AXI4-Stream 的强制规则。

## 18.5 错误注入

REQ-ERR-001：错误注入缺省关闭，启用时指定 rule、注入位置、持续周期/次数、seed 和期望告警；禁止全局关闭 checker 来运行负向测试。

REQ-ERR-002：每个注入场景必须匹配预期 rule ID、数量范围和严重度；额外意外告警导致失败，预期告警缺失也导致失败。相关连带告警必须在测试清单中显式允许。

REQ-ERR-003：注入应通过 driver 的专用破坏路径或独立 fault fixture 实现。不能让正常 constraint/driver 代码长期处于可非法运行状态。

## 18.6 Scoreboard 与参考模型

REQ-SCB-001：必须提供 EXACT_BEAT / LOGICAL_STREAM / CUSTOM 三种明确区分的模式，默认 EXACT_BEAT；DUT 的 reset、routing、user mapping、ordering 合同在连接时显式提供。

REQ-SCB-002：LOGICAL_STREAM 保留 POSITION token，不比较其 TDATA；NULL 可以移除，但 END_PACKET 不得移除或跨包合并。支持 `TKEEP=0 && TLAST=1` 形成独立结束事件。

REQ-SCB-003：TUSER 跨位宽转换不能默认按 beat 生搬硬比。提供 OPAQUE_PER_BEAT、PER_BYTE、PER_PACKET、CUSTOM 映射；没有映射合同的非透明转换必须配置失败或明确标识“不检查该维度”，不得宣称完整 PASS。

REQ-SCB-004：透明 FIFO/CDC 默认保留全局输入顺序；多流交换/仲裁 DUT 可以显式改为逐 key 保序。禁止默认仅按 key 比较而漏掉本应全局保序的错误。

REQ-SCB-005：MUX/DEMUX/路由的 reference contract 必须定义 source-port 与 stream key 的映射、TID/TDEST 是否重写、输出端口选择。若不同输入使用相同 key 且输出无法区分，必须由仲裁/重写合同消歧，不能任意搜索一个匹配 payload。

REQ-SCB-006：支持发现丢失、重复、数据破坏、顺序错误、错路由和包边界变化；输出最早差异及上下文。允许丢弃或广播时必须明确配置 drop/replication 规则和期望计数。

REQ-SCB-007：匹配基于 monitor 接收事实；可另外比较 source 提交意图与入口接收记录，以发现 driver 自身丢包，但不能用同一个 driver 缓存同时充当所有 oracle。

REQ-SCB-008：结束时必须排空已接受的 expected 数据，或按 reset/drop 合同结算；不可通过统一清空队列掩盖丢数。未知值不得被二态转换或普通 equality 的不确定结果吞掉。

---

# 19. Compatibility

| 项目 | V1.0 合法性声明 |
|---|---|
| AXI4-Stream 基线 | AMBA AXI4-Stream，ARM IHI 0051A；不宣称覆盖 IHI 0051B 全部扩展 |
| AXI memory-mapped | 不兼容、不实现；与 AXI4/AXI4-Lite VIP 无共享代码 |
| UVM | 兼容基线 UVM 1.2 |
| 仿真器 | 主验收为支持四态与 SVA 的 UVM 仿真器；Verilator 仅受限目标且不得作为 X 检查证据 |
| HWIF | 本仓暂无 AXI4-Stream HWIF 契约；当前接口为该 VIP 的 development binding，不宣称与公共 HWIF 兼容 |
| CDC | 验证数据完整性与复位合同，不宣称证明亚稳态安全或替代 CDC 静态检查 |
| RAL | 不提供 |

REQ-INT-005 的兼容性边界与 REQ-SCP-005 的三种构建方式同时适用：
FULL_UVM、PASSIVE_UVM、CHECKER_ONLY 必须可用；CHECKER_ONLY 不依赖 UVM package。

---

# 20. Deliverable

| 交付件 | 内容 |
|---|---|
| `docs/requirement.md` | 本需求规格（源自需求合同） |
| `config/requirements.yaml` | 权威 REQ ID、优先级、家族、验证方法 |
| `config/verification-plan.yaml` | 冻结 case/priority/bin 集合 |
| `config/qualification.yaml` | 覆盖阈值 |
| `docs/architecture.md` | 组件、线程、采样/驱动时序、复位、事件与参考模型设计 |
| `docs/validation-plan.md` | 合法/非法测试、配置矩阵、覆盖策略、预期规则 |
| `docs/rtm.md` | 需求→实现→测试→覆盖 设计期追溯 |
| `src/` | UVM 类库、参数化 interface、Checker/SVA、语义模型、序列库 |
| `unit_test/` | L1 golden vector 套件（semantic/transaction/config/checker） |
| `self_test/` | 独立 DUT fixture、自验证环境、8 类测试 |
| `examples/` | 集成示例（Source-DUT、DUT-Sink、两侧比较、Passive） |
| `aixsilicon_vip_axi4_stream_1.0.0.core` | FuseSoC 依赖与运行目标 |
| `docs/user-guide.md` | 参数、角色、API、应用 profile、诊断和限制 |
| `reports/<run-id>/` | 实际工具版本、运行证据、覆盖、缺陷和 waiver |

---

# 22. Qualification

REQ-ACC-001：所有 mandatory requirement 均映射到实现、测试和证据；RTM 不允许悬空 mandatory 项。

REQ-ACC-002：合法定向和随机回归无非预期 ERROR/FATAL；每条协议规则的负向测试均能命中预期规则且没有未解释额外告警。

REQ-ACC-003：适用的 mandatory 功能覆盖 bin 全部命中或有逐项批准的 waiver；不能仅凭总代码覆盖率宣布协议完备。

REQ-ACC-004：至少一次连续 10000 beat 的 ALWAYS_READY 测试证明无 VIP 自带气泡；至少一个 1000000 accepted beat 压力测试证明无丢失/重复、统计守恒且 FULL capture 关闭时内存有界。

REQ-ACC-005：每个核心合法场景至少 20 个固定 seed；失败必须输出可重放配置和最小相关窗口。后续是否扩增 seed 由覆盖缺口和缺陷决定。

REQ-ACC-006：reset/cancel/watchdog 测试不发生静默挂死、不撤销正常 stall beat、不错误接受复位中的 beat。

REQ-ACC-007：至少在一个完整四态 UVM 仿真器上全量通过；若宣称跨仿真器支持，则在第二个声明版本完成规定兼容矩阵。发布报告列明真实环境，禁止泛称“所有仿真器”。

## 22.1 VIP 自验证结构

REQ-VAL-001：自验证必须包含简单独立 source/sink fixture 验证 active agent、手工期望 trace 验证 monitor/checker，以及带可控故障的 DUT 验证 scoreboard。仅 source/sink VIP 自环不能完成验收，避免共享 bug 相互抵消。

REQ-VAL-002：至少包含直连、register slice、同步 FIFO、异步 FIFO fixture、宽度变换 fixture、2 入/2 出路由 fixture。fixture 的参考行为应可人工审查，不依赖被测 VIP 的同一规范化函数生成 oracle。

---

# 23. Limitations

1. **无全局 PASS 声明**：本文是需求规格，不是实现或验证通过的证明。
2. **协议章节映射未完成**：需求合同 §18 明确 Arm 当前在线入口未返回可逐页核验的
   协议正文，G1 的 Arm 固定版本逐规则章节映射仍需完成，不能标记为协议认证。
3. **HWIF 未复用**：本仓暂无 AXI4-Stream HWIF 契约，`axi4_stream_if` 是明确命名的
   development binding，用于独立测试；不得宣称已与公共 HWIF 兼容。
4. **CDC 边界**：只验证数据完整性与复位合同，不证明亚稳态安全。
5. **Pass-through BFM**：V1.0 不提供插入式转发 BFM。
6. **AXI5-Stream 扩展**：TWAKEUP、奇偶校验等不在 V1.0 范围。
7. **PASSIVE 模式**：本 VIP 的 PASSIVE 是 agent 角色（只观测），PERF 统计中的
   端到端延迟需要两端关联，单 agent 无法给出。
8. **CHECKER_ONLY**：已提供独立 target（`make -C self_test checker_only` 与
   `.core` 的 `checker_only`），不 import `uvm_pkg`、不创建 driver/sequencer；
   其判定为纯语义自检 + SVA 编译/运行（见 `docs/rtm.md` REQ-SCP-005）。

---

# 24. 需求优先级

| 优先级 | 含义 | 覆盖范围 |
|---|---|---|
| P0 | V1.0 必须实现并通过 | 全部 90 条 REQ 在冻结计划中均为 required |
| P1 | 建议实现，不阻塞 V1.0 | 当前无；后续扩展（AXI5-Stream、pass-through BFM）另行评审 |

优先级由 `config/requirements.yaml` 与 `config/verification-plan.yaml` 冻结；
结果报告不得设置或修改 required/priority。

---

# 25. Requirement Traceability Matrix

设计期追溯见 `docs/rtm.md`（§7 Master RTM 逐 ID 覆盖全部 90 条 REQ）。
逐次执行状态只写本次运行的 `reports/<run-id>/rtm.md`。

---

# 26. G0 Requirement Review Checklist

| # | 检查项 | 状态依据 |
|---|---|---|
| G0-1 | 需求范围与边界（§1、§19）已明确且无歧义 | 需求合同 §1.2 + 本文 §1/§19 |
| G0-2 | 参数与配置空间完整、含缺省与非法组合（§2、§7） | REQ-CFG-001..007 |
| G0-3 | 协议规则可映射到 Checker/SVA（§3） | 15 条 rule ID 表 |
| G0-4 | 事务模型与公共 API 已定义（§8） | REQ-TXN-001..007 |
| G0-5 | 覆盖组与交叉已定义且可机器化（§10） | REQ-COV-001..003 |
| G0-6 | 复位/取消/看门狗合同完整（§18.4） | REQ-RST-001..007 |
| G0-7 | 验收判据可观测、可判定（§22） | REQ-ACC-001..007 |
| G0-8 | 限制与不做项显式声明（§23） | 本文 §23 |
| G0-9 | Arm 固定版本逐规则章节映射 | **未完成**：合同 §18 已声明 G1 仍需完成 |

**G0 状态**：NOT_RUN（G0-9 未完成；需求评审记录写入 `reports/<run-id>/requirement.md`）。

---

# 27. Requirement Completion Definition

需求文档完成定义（本文件层面）：

- [x] 90 条 REQ ID 唯一、稳定、可机器提取（`config/requirements.yaml`）。
- [x] 每条 REQ 归属五个需求类别之一（Protocol / Verification Capability /
      External Interface / Engineering / Qualification）。
- [x] 不适用项显式标 N/A 或移入 §19/§23，不保留空占位。
- [x] 与需求合同 `../axi_stream_vip_contract.md` 的 REQ ID 集合一致。
- [ ] G0-9（Arm 逐规则章节映射）—— **未完成**，不得标记 G0 PASS。

> 实现与验证的完成定义见 `docs/validation-plan.md` §55 与 `docs/rtm.md` §47；
> Gate 由 `vip_tool.py` 依据 `reports/<run-id>/` 的 metadata 计算，本文不构成 PASS 证据。
