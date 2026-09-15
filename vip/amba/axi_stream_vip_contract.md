---
document_type: vip-requirements
document_id: aixsilicon:vip:axi4_stream:req
name: axi4_stream
version: 0.1.0
target_version: 1.0.0
status: draft
profile: FULL_UVM
protocol_baseline: AMBA AXI4-Stream, ARM IHI 0051A
---

# AIXSILICON AXI4-Stream VIP 需求规格

本文定义待开发 VIP 的功能、边界、接口合同、验证与验收要求，不代表已实现或已通过验证。本文中的 MUST/必须为验收要求，SHOULD/建议为架构建议。除明确标为后续扩展的项目外，均纳入 V1.0；实现可分阶段，发布不可静默裁剪。

| 项目 | 定义 |
|---|---|
| VIP 名称 | `axi4_stream`；类及文件前缀 `axi4_stream_` |
| 建议 VLNV | `aixsilicon:vip:axi4_stream:1.0.0` |
| 交付形式 | 参数化 SystemVerilog interface + UVM 类库 + 独立 Checker/SVA + 序列库 + 自验证环境 |
| 基线 | 传统 AXI4-Stream 信号集合，ARM IHI 0051A |
| 角色 | Source/Master、Sink/Slave、Passive Monitor |
| 主要用途 | FIFO、Register Slice、Width Converter、DMA 流接口、MUX/DEMUX、流式计算 IP、CDC Bridge 的接口与端到端验证 |
| 管理方式 | YAML 维护需求/参数/功能开关，FuseSoC 管理依赖与运行目标 |

## 1. 定位与范围

### 1.1 产品目标

REQ-SCP-001：VIP 必须独立完成合法激励、接收背压、总线监测、协议检查、功能覆盖、错误注入和可复现调试。

REQ-SCP-002：必须支持 beat 级和 packet 级 API，并保留四态总线观测；支持连续无包流、单包、多包和按 `(TID,TDEST)` 标识的交织流。

REQ-SCP-003：必须提供可复用的端到端流比较组件；默认比较模式必须显式配置，不得假定所有 DUT 都逐拍透明。

REQ-SCP-004：每个 agent 对应一个时钟域和一个单向 AXI4-Stream 接口；双向链路使用两个 agent；CDC DUT 两侧分别部署 agent，由 scoreboard 跨域关联。

REQ-SCP-005：FULL_UVM、PASSIVE_UVM、CHECKER_ONLY 三种构建方式必须可用。CHECKER_ONLY 不依赖 UVM package，也不启动驱动线程。

### 1.2 明确边界

| 项目 | V1.0 定义 |
|---|---|
| AXI memory-mapped | 不实现 AW/W/B/AR/R、地址、burst、response、exclusive |
| RAL | AXI4-Stream 无寄存器访问语义；不提供通用 RAL adapter；DMA 的 APB/AXI-Lite 配置由其他 VIP 负责 |
| TUSER | 支持传输、随机化、掩码、比较及自定义解码，不内置统一业务含义 |
| 视频/音频/张量 | 提供扩展接口；SOF、EOL、采样格式、张量形状归应用 profile |
| 时钟/复位 | 顶层专用 agent 拥有驱动权；流 agent 响应复位，可通过 sequencer 请求复位场景 |
| CDC | 验证数据完整性与复位合同，不宣称证明亚稳态安全或替代 CDC 静态检查 |
| AXI5-Stream/TWAKEUP/奇偶校验扩展 | 后续版本；不得宣称覆盖 IHI 0051B 的全部扩展 |
| Pass-through BFM | V1.0 不要求插入式转发 BFM；使用两侧 agent + DUT/测试桥接逻辑 |

## 2. 参数与配置合同

REQ-CFG-001：静态端口形状使用 elaboration 参数，运行期行为使用 config object；不得在传输中改变位宽或端口存在性。

以下是本 VIP 的支持目标，不是协议规定的最大值。

| 参数 | V1.0 支持目标 / 默认 |
|---|---|
| `DATA_WIDTH` | 有 TDATA 时为 8 的正整数倍，8～4096；默认 64；包括 24/40/96 等非 2 的幂宽度 |
| `HAS_TDATA` | 0/1，默认 1；0 时支持仅侧带/边界控制流 |
| `HAS_TREADY` | 0/1，默认 1；0 时有效 ready 恒为 1 |
| `HAS_TKEEP` | 0/1，默认 1；宽度为 DATA_WIDTH/8 |
| `HAS_TSTRB` | 0/1，默认 0；宽度为 DATA_WIDTH/8 |
| `HAS_TLAST` | 0/1，默认 1 |
| `ID_WIDTH` | 0～32，默认 0；0 表示 TID 缺省 |
| `DEST_WIDTH` | 0～32，默认 0；0 表示 TDEST 缺省 |
| `USER_WIDTH` | 0～4096，默认 0；0 表示 TUSER 缺省 |
| `ROLE` | SOURCE / SINK / PASSIVE；必须显式设置 |
| `PACKET_MODE` | TLAST / CONTINUOUS / FIXED_BEATS；默认随端口配置显式选择，不隐式推断 |
| `COMPARE_MODE` | EXACT_BEAT / LOGICAL_STREAM / CUSTOM |
| `MAX_OPEN_STREAMS` | 默认 256，可配置；使用稀疏容器，不按 ID 位数展开全空间 |
| `MAX_PACKET_BEATS` | 默认 65536；VIP 资源限制，可配置，不是协议包长限制 |
| `CAPTURE_MODE` | FULL / STREAMING；后者支持增量输出、有限历史缓存 |
| `MAX_READY_WAIT` | 默认 0＝关闭；启用后为环境 watchdog |
| `MAX_PACKET_IDLE` | 默认 0＝关闭；启用后为应用/环境 watchdog |
| `CHECK_ENABLE` / `COVERAGE_ENABLE` | 默认开，按规则/覆盖组可裁剪 |

REQ-CFG-002：缺省信号必须在统一 adapter 中归一化：TREADY 缺省为 1；TKEEP 缺省为全 1；TSTRB 缺省时按有效 TKEEP 归一化；两者均缺省为全 1；TID/TDEST 缺省为 0。未存在的物理信号不得参加 X/stability 检查。

REQ-CFG-003：TLAST 缺省时必须显式选择连续流或应用定义的边界策略；FIXED_BEATS 是本地应用解释，不能宣称在总线上检测到 TLAST。不能统一将缺省 TLAST 解释为“一拍一包”。

REQ-CFG-004：USER_WIDTH 不要求为 lane 数的整数倍；只有选择 `PER_BYTE` 映射时才检查整除关系。默认 TUSER 是原始不透明位向量。

REQ-CFG-005：HAS_TDATA=0 时禁止开启 TKEEP/TSTRB，数据宽度不产生有效数据语义。物理占位端口至少 1 bit，避免 `[-1:0]`；通过 wrapper 隐藏缺省端口，行为与检查必须按存在性裁剪。

REQ-CFG-006：不支持的配置必须在 build/elaboration 阶段明确失败，输出配置名、值和原因，禁止静默截断。virtual interface 参数与 agent 参数不一致必须失败。

REQ-CFG-007：约束随机化失败必须报告，不能继续使用旧 item。支持保存有效配置、随机 seed、测试名和版本，完成可重放记录。

## 3. 握手与字节语义

REQ-PRO-001：只有在 ACLK 上升沿、复位无效且 `TVALID===1 && effective_TREADY===1` 时产生一次成功传输。valid-only 和 ready-only 均不是成功传输。

REQ-PRO-002：Source 有待发送数据时，不得以观察到 TREADY 为拉高 TVALID 的前提；必须支持 sink 等待 TVALID 后才拉高 TREADY 的合法交互。

REQ-PRO-003：TVALID 拉高后，直到握手完成必须保持；背压期间 TDATA、TKEEP、TSTRB、TLAST、TID、TDEST、TUSER 所有存在的字段保持稳定。稳定性检查覆盖解除背压并完成握手的那个边沿。空闲时不限制 payload 变化。

REQ-PRO-004：允许 TREADY 在 TVALID 之前、同周期或之后拉高；允许任意合法背压和连续每周期一拍。协议不提供天然的最大等待周期。

REQ-PRO-005：按 lane `i` 对应 `TDATA[8*i +: 8]`，低 lane 先进入规范化逻辑流。应用多字节数值的端序由应用指定，不能混入总线 lane 排序。

| TKEEP[i] | TSTRB[i] | 分类 | 比较语义 |
|---|---|---|---|
| 1 | 1 | DATA | 保留位置与数据值 |
| 1 | 0 | POSITION | 保留位置，数据值无效 |
| 0 | 0 | NULL | 逻辑流可移除，原始 beat 记录必须保留 |
| 0 | 1 | 非法组合 | 协议错误 |

REQ-PRO-006：合法随机流必须支持稀疏 TKEEP、非尾拍 partial beat、POSITION bytes、全 NULL beat；不得将“只有尾拍能不满”“TKEEP 必须连续”硬编码为协议规则。

REQ-PRO-007：全 NULL beat 可携带 TLAST，组包器必须保留对应包结束事件。逻辑比较时不能因删除所有 NULL 而丢掉包边界。无 TLAST 的全 NULL beat 是否允许被 DUT 消除，由其流变换合同配置。

REQ-PRO-008：包不受 AXI memory-mapped 的 256 beat 或 4KB 边界约束；无地址和 burst 字段。测试应覆盖大于 256 beat 的包。

REQ-PRO-009：同一 `(TID,TDEST)` 的 beat 构成相应逻辑流，允许不同流在 beat 间交织。一个 stream key 只维护一个当前未完成包；协议没有另一个 packet ID 来区分该 key 下重叠的包。

REQ-PRO-010：TID/TDEST 可以在成功传输之间变化；不得在等待当前拍接收期间变化。变化后属于另一个 key，不应直接判为“包内 ID 错误”。不允许交织的 DUT profile 可另外约束。

## 4. Transaction 数据模型与 API

REQ-TXN-001：必须分别定义 beat item、packet item、ready policy item、observed event 和 error event。控制请求与总线事实分离。

| 对象 | 必需内容 |
|---|---|
| beat item | 四态 data/keep/strb/last/id/dest/user；存在性由配置给出；发送前 idle 周期；local transaction ID；错误注入计划 |
| observed beat | 原始采样值、归一化语义、interface ID、reset epoch、时间戳、周期号、握手状态、等待周期 |
| packet item | stream key、beat 集合或流式片段、data byte 数、position byte 数、包结束类型、开始/结束时间、状态 |
| ready policy item | 模式、延迟、开/关周期、随机分布、触发点、持续次数 |
| error event | rule ID、类别、严重级别、实例、epoch、时间/周期、前后采样、相关 stream/packet、注入关联 |

REQ-TXN-002：packet API 必须支持 `from_bytes`、`from_beats` 和增量构造；from_bytes 默认生成紧密排列 DATA、最后一拍用 TKEEP 标识余数。无 TKEEP 时不能静默填充有效字节，应拒绝无法精确表示的长度，或要求明确 padding 合同。

REQ-TXN-003：支持 0 数据字节包、1 字节包、单 beat、长包。0 字节包要求相应端口能表达，例如带 TLAST 的全 NULL beat；只有 POSITION 的包也必须可表达。无法表达的请求必须失败。

REQ-TXN-004：完成状态至少为 ACCEPTED、ABORTED_BY_RESET、CANCELED_BEFORE_VALID、WATCHDOG_EXPIRED、REJECTED_CONFIG。ACCEPTED 仅表示所有相应 beat 被接口接收，不表示 DUT 已完成业务处理。

REQ-TXN-005：发送前取消允许撤销排队 item；一旦 TVALID 已拉高，正常取消或 timeout 不得撤销当前拍。默认让该拍继续等待并报告 watchdog；需要中止仿真或复位时通过 test policy 处理，禁止正常 driver 自行破坏协议。

REQ-TXN-006：支持 `send_beat`、`send_packet`、`set_ready_policy`、`wait_for_accepted`、`wait_for_packet`、`drain`、统计快照等能力。非阻塞提交必须返回 handle，队列有界且达到上限时有明确阻塞/失败语义。

REQ-TXN-007：copy/clone/compare/print/pack 必须完整覆盖业务字段；analysis port 发布独立快照，防止复用可变对象导致历史数据被覆盖。

## 5. Source Agent

REQ-SRC-001：支持 directed、constrained-random、可重放文件输入，以及用户自定义 sequence；同一份输入在相同配置、seed 和仿真器版本下可复现。

REQ-SRC-002：支持零间隔连续发送、固定/随机 beat 间隔、packet 间隔、稀疏流、突发式流量。所有延迟发生在尚未断言 TVALID 的阶段；不得在 stall 中更换 payload。

REQ-SRC-003：必须可连续一拍/周期，不得由于 `item_done`、事务获取或 packet 切换自动插入气泡。实现预取并保证采样/驱动无 race。

REQ-SRC-004：支持多 stream 的 round-robin、weighted-random 和显式顺序调度；支持 packet 连续和 beat 交织。保持每个 key 内已提交顺序。

REQ-SRC-005：合法生成器与非法注入器分离；缺省只能产生满足当前 profile 的合法事务。source 无权驱动 TREADY，也不能依赖 monitor 返回完成信息作为未来发送的循环前提。

## 6. Sink Agent 与背压

REQ-SNK-001：Sink 只驱动 TREADY，所有接收数据来自 monitor，不得修改 DUT 驱动的信号。

| 背压模式 | 必须支持的行为 |
|---|---|
| ALWAYS_READY | 持续接收 |
| FIXED_DELAY | 在观察到有效请求后延迟 N 拍接收，定义 N=0 边界 |
| RANDOM | 带 seed 的随机 ready，概率和连续 stall 长度可配置 |
| PERIODIC | ready 高 M 拍、低 N 拍 |
| WAIT_VALID | 先等待 TVALID 再产生 ready，用于发现 source 依赖 ready 的问题 |
| BURST_ACCEPT | 接收 K 拍后暂停 N 拍 |
| TARGETED | 包首/包中/包尾、指定 key 或第 K 拍施加背压 |
| BUFFER_MODEL | 根据可配置缓冲深度和消费速率产生 ready |
| SCRIPTED | 使用周期脚本或用户回调生成 ready |

REQ-SNK-002：必须覆盖 TLAST 等待、首拍等待、长时间等待后恢复，以及 ready 先到和 valid 先到；同一拍不可被重复接收。

REQ-SNK-003：ready 决策和接收处理不能形成软件环路死锁。BUFFER_MODEL 达到容量前必须考虑已承诺的接收周期，不能因为 monitor 队列溢出静默丢拍。

REQ-SNK-004：HAS_TREADY=0 时关闭所有背压驱动，接收吞吐必须匹配每周期一拍；资源不足是 VIP 容量错误，不能假装接口施加了背压。

## 7. Monitor 与组包

REQ-MON-001：Monitor 必须完全依赖实际 interface，不得使用 driver item 作为总线事实。Passive 模式不得改变任何总线或时钟复位信号。

REQ-MON-002：提供独立 beat_ap、packet_ap、error_ap、reset_ap，必要时提供 cycle_ap。beat_ap 只发布已完成握手；cycle_ap/error_ap 可包含未完成或非法采样。

REQ-MON-003：按 `(interface_id,reset_epoch,TID,TDEST)` 独立组包；TLAST 在完成握手后结束该 key 的包。其他 key 的传输不结束本 key 的包。

REQ-MON-004：无 TLAST 模式必须支持无限连续流的增量输出，不能一直等待包结束或无限保存数据。FIXED_BEATS 的结束必须标为 synthetic，不冒充协议 TLAST。

REQ-MON-005：仿真结束时报告每个未完成包、最后握手、等待状态和缓存占用。连续流在约定 drain 边界可正常结束；TLAST 模式未完成包按 test policy 判定，不能静默 PASS。

REQ-MON-006：旁路中途启用监控时标识 PARTIAL_CAPTURE；第一个包可能缺包头，不能拿它进行完整端到端比较。严格验收从复位开始监控。

REQ-MON-007：保留原始四态值；遇到未知 key 或 qualifier 时报告并按明确策略隔离该事件，不能将 X 转成 0 后进入正常 scoreboard。

## 8. Checker / SVA

Checker 必须区分 PROTOCOL、APPLICATION、WATCHDOG、CONFIG、VIP_INTERNAL 五类，不得将 vendor 建议或业务约束统一报告为协议错误。

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
| AXIS-P009 | TVALID 有效时 TUSER 的有效检查位不得未知；缺省 mask 为全有效，可由 profile 声明无效位 | ERROR |
| AXIS-A001 | 固定包长、最大包长、禁止交织、连续 TKEEP、仅末拍 partial 等 | 关闭，应用配置启用 |
| AXIS-A002 | TUSER 的 SOF/EOL/错误标志/张量含义及传播规则 | 关闭，应用插件启用 |
| AXIS-W001 | ready 等待超过配置阈值 | 关闭；启用后 WARNING 或 test 指定严重度 |
| AXIS-W002 | packet 长时间无进展或无结束 | 关闭；启用后 WATCHDOG |
| AXIS-C001 | 位宽、端口、模式不兼容 | FATAL |
| AXIS-I001 | 内部队列/组包上限溢出、对象生命周期错误 | ERROR/FATAL |

REQ-CHK-001：SVA 可 bind，也可直接例化；复位取消未完成的时序检查。P004 的稳定性检查与 P008 的数据值有效性检查独立，不能因为 NULL 数据不比较而放宽 stall 稳定性。

REQ-CHK-002：P002 时间合同：ARESETn 拉高后的第一个 ACLK 上升沿仍采样到 TVALID=0；source 可在该边沿之后驱动下一周期 valid，后续边沿才接收。测试必须覆盖 release 相位。

REQ-CHK-003：每条规则可单独开关、改变严重度、设置限报次数，并输出结构化事件。SVA 与 UVM checker 同时启用时必须避免重复计数，或明确其关联 ID。

REQ-CHK-004：纯黑盒 Checker 不能仅凭波形证明 source 没有等待 ready 才产生 valid，也不能证明接口不存在组合路径。前者使用 WAIT_VALID 对抗测试及进展条件，后者由结构检查/设计约束补充，不伪装成完整 SVA 证明。

REQ-CHK-005：不能要求复位时 TREADY=0，也不能普遍要求 TDATA/TLAST/TID 等 payload 清零。额外要求只能来自 DUT profile。

## 9. Scoreboard 与参考模型

REQ-SCB-001：必须提供以下三种明确区分的模式，默认 EXACT_BEAT；DUT 的 reset、routing、user mapping、ordering 合同在连接时显式提供。

| 模式 | 比较内容 | 适用 |
|---|---|---|
| EXACT_BEAT | beat 个数、qualifier、边界、ID/DEST/USER；DATA 有效 lane 的值；可选择 RAW_ALL_BITS 调试 | FIFO、register slice、透明 CDC |
| LOGICAL_STREAM | DATA(value)、POSITION、END_PACKET 有序 token；按约定去除 NULL，与 beat 分组解耦 | packing、width conversion |
| CUSTOM | 用户参考模型产生 expected output，再由通用匹配组件消费 | 运算、协议封装、数据重排 |

REQ-SCB-002：LOGICAL_STREAM 保留 POSITION token，不比较其 TDATA；NULL 可以移除，但 END_PACKET 不得移除或跨包合并。支持 `TKEEP=0 && TLAST=1` 形成独立结束事件。

REQ-SCB-003：TUSER 跨位宽转换不能默认按 beat 生搬硬比。提供 OPAQUE_PER_BEAT、PER_BYTE、PER_PACKET、CUSTOM 映射；没有映射合同的非透明转换必须配置失败或明确标识“不检查该维度”，不得宣称完整 PASS。

REQ-SCB-004：透明 FIFO/CDC 默认保留全局输入顺序；多流交换/仲裁 DUT 可以显式改为逐 key 保序。禁止默认仅按 key 比较而漏掉本应全局保序的错误。

REQ-SCB-005：MUX/DEMUX/路由的 reference contract 必须定义 source-port 与 stream key 的映射、TID/TDEST 是否重写、输出端口选择。若不同输入使用相同 key 且输出无法区分，必须由仲裁/重写合同消歧，不能任意搜索一个匹配 payload。

REQ-SCB-006：支持发现丢失、重复、数据破坏、顺序错误、错路由和包边界变化；输出最早差异及上下文。允许丢弃或广播时必须明确配置 drop/replication 规则和期望计数。

REQ-SCB-007：匹配基于 monitor 接收事实；可另外比较 source 提交意图与入口接收记录，以发现 driver 自身丢包，但不能用同一个 driver 缓存同时充当所有 oracle。

REQ-SCB-008：结束时必须排空已接受的 expected 数据，或按 reset/drop 合同结算；不可通过统一清空队列掩盖丢数。未知值不得被二态转换或普通 equality 的不确定结果吞掉。

## 10. Reset、取消与恢复

REQ-RST-001：支持 ARESETn 异步断言、同步释放的合法使用；测试时钟/复位由顶层统一控制，避免多个 agent 同时驱动。

REQ-RST-002：复位断言必须使 Source 停止有效发送；已握手历史保留，当前未完成 beat 标为 ABORTED_BY_RESET，排队但未发送 item 按 FLUSH/RETAIN 配置处理，默认 FLUSH。释放后如需重发必须形成新 epoch 下的明确请求。

REQ-RST-003：复位不能虚构 AXI4-Stream 的 error response。接口没有返回响应；VIP 的 abort 仅是测试软件状态。

REQ-RST-004：monitor 关闭当前未完成 packet 并发布 reset-aborted 事件，reset_epoch 增加；scoreboard 根据 DUT 合同处理已接受但尚未输出的数据。

REQ-RST-005：CDC 两侧独立复位时必须配置 BOTH_FLUSH、PRESERVE 或 CUSTOM 合同，以及两侧 epoch 的关联；未知合同应停止严格比较并报告配置缺失，不能假定任意单侧复位会清空另一侧。

REQ-RST-006：覆盖空闲、首拍、stall 中、TLAST stall、包中、多 key 未完成时复位，以及连续多次复位、复位后首拍和队列保留/清除。

REQ-RST-007：最小复位脉宽是环境/DUT 约束，不能把特定 vendor 的 16 周期要求作为所有 AXI4-Stream 的强制规则。

## 11. 错误注入与负向验证

REQ-ERR-001：错误注入缺省关闭，启用时指定 rule、注入位置、持续周期/次数、seed 和期望告警；禁止全局关闭 checker 来运行负向测试。

| 注入类型 | 验证对象 |
|---|---|
| stall 中撤销 TVALID | VALID 保持规则 |
| stall 中逐项修改 TDATA/TKEEP/TSTRB/TLAST/TID/TDEST/TUSER | 各字段稳定性规则 |
| TKEEP=0、TSTRB=1 | 字节限定符规则 |
| valid/ready/有效控制/有效数据位注入 X | 四态检查，仅在支持四态的仿真器上验收 |
| reset 期间 valid 非零、过早恢复 valid | 复位规则 |
| 提前/缺失 TLAST、错 TUSER 含义 | 应用合同或端到端 scoreboard；不自动判协议非法 |
| 合法握手下丢 beat、重复、乱序、错数据/路由 | 故障 DUT fixture + scoreboard |
| 持续 backpressure 或持续 idle | watchdog 和停止流程；不是天然协议错误 |

REQ-ERR-002：每个注入场景必须匹配预期 rule ID、数量范围和严重度；额外意外告警导致失败，预期告警缺失也导致失败。相关连带告警必须在测试清单中显式允许。

REQ-ERR-003：注入应通过 driver 的专用破坏路径或独立 fault fixture 实现。不能让正常 constraint/driver 代码长期处于可非法运行状态。

## 12. 序列库与场景

REQ-SEQ-001：至少交付下列可组合序列，每个序列支持 seed、repeat、stream、长度和时序配置。

1. 单 beat、单字节、单包、多包、连续一拍/周期。
2. 随机包长，边界 0/1、lane-1/lane/lane+1 字节、255/256/257 beat、资源上限附近。
3. DATA 全 0/全 1、递增、walking-one/zero、随机模式。
4. 全 keep、稀疏 keep、首/中/尾 partial、POSITION、NULL、全 NULL TLAST。
5. ready 先到、valid 先到、同时握手、周期/随机/长 stall、TLAST stall。
6. 多 key 持续流、逐 beat 交织、每包切换、同 key 连续包。
7. 无 TLAST 连续流、无 TREADY 满速流、仅侧带流。
8. 包中和 stall 中复位、独立 CDC 复位恢复。
9. 逐项协议错误注入及应用错误注入。
10. 长时间压力、有限缓存、drain、主动 cancel、watchdog。

## 13. 功能覆盖率

REQ-COV-001：握手覆盖只在成功接收时采样；stall 长度在等待结束/中断时采样；reset/error 独立采样。不得用“生成过 item”替代“总线发生过”。

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

REQ-COV-002：重点交叉至少包含 `TLAST × stall`、`qualifier × packet_position`、`reset_phase × handshake_state`、`stream_interleave × backpressure`、`width_ratio × partial × TLAST`。

REQ-COV-003：配置关闭的功能必须排除对应 bin，不可通过权重隐藏未覆盖；不可达 bin 需要可审计 waiver。不要全量交叉所有参数造成覆盖爆炸。

## 14. 性能统计与资源

REQ-PERF-001：至少报告 accepted beats、data bytes、position bytes、null bytes、完成/中止包数、源空闲周期、`valid&&!ready` 周期和活动周期。

REQ-PERF-002：有效吞吐使用 DATA bytes/观测时间；总线利用率使用 accepted beats/有效时钟周期。position byte 不计为有效数据吞吐。复位周期与 warm-up 窗口是否排除必须明确。

REQ-PERF-003：单端口可报告 valid-to-handshake 等待时间；端到端延迟必须有两端关联，不能将单端等待当成 DUT 延迟。跨时钟域使用统一仿真时间，不直接相减两侧周期号。

REQ-PERF-004：支持按接口、key、packet 汇总；长测试默认限制历史存储与详细日志，支持 streaming scoreboard/摘要输出，禁止未完成连续流造成无界内存增长。

## 15. 架构约束与集成建议

推荐组件如下，文件拆分可在 architecture.md 中调整，需求 ID 不随拆分变化。

| 组件 | 职责 |
|---|---|
| `axi4_stream_if` | 参数化信号、clocking block、modport、存在性 adapter |
| `axi4_stream_config` | 行为配置、profile、参数一致性校验 |
| `axi4_stream_beat/packet/ready_item` | 事务和控制模型 |
| `axi4_stream_source_driver` | Source 握手、预取、合法/专用非法驱动路径 |
| `axi4_stream_sink_driver` | 背压策略与接收容量模型 |
| `axi4_stream_monitor` | 独立采样、组包、事件发布 |
| `axi4_stream_checker` | 独立 SV/SVA 协议规则 |
| `axi4_stream_coverage` | 功能覆盖 |
| `axi4_stream_stream_model` | lane/byte/token 规范化 |
| `axi4_stream_scoreboard` | 透明/流语义/自定义比较 |
| `axi4_stream_agent/env` | 角色组合、多接口连接 |
| `sequences` | directed/random/negative/stress 序列 |

REQ-INT-001：驱动与采样 skew 在 architecture.md 明确；monitor 与 checker 对同一边沿的解释一致，避免 blocking assignment race。

REQ-INT-002：通过 virtual interface、uvm_config_db、analysis port 和标准 sequence 通道集成；不得依赖 DUT 内部层次路径或全局可变 singleton。

REQ-INT-003：运行期间可更新 ready policy、日志及统计选项；影响组包/比较语义的配置只能在 drain/复位后更新，并记录配置 epoch。Role 运行期切换不纳入 V1.0。

REQ-INT-004：FuseSoC 至少提供 compile、smoke、regression、checker_only 目标，外部库版本固定；文档提供 Source-DUT、DUT-Sink、两侧比较和 Passive 例子。

REQ-INT-005：主验收使用支持 class、constraint、covergroup、SVA 和四态语义的 UVM 仿真环境。UVM 1.2 为兼容基线；具体仿真器与版本在 G1 固定。Verilator 可提供受限目标，但必须列出其实际缺失能力，不将二态结果作为 X 检查验收证据。

## 16. VIP 自验证与验收

### 16.1 独立验证结构

REQ-VAL-001：自验证必须包含简单独立 source/sink fixture 验证 active agent、手工期望 trace 验证 monitor/checker，以及带可控故障的 DUT 验证 scoreboard。仅 source/sink VIP 自环不能完成验收，避免共享 bug 相互抵消。

REQ-VAL-002：至少包含直连、register slice、同步 FIFO、异步 FIFO fixture、宽度变换 fixture、2 入/2 出路由 fixture。fixture 的参考行为应可人工审查，不依赖被测 VIP 的同一规范化函数生成 oracle。

### 16.2 最小配置回归矩阵

| 维度 | 强制覆盖点 |
|---|---|
| 数据位宽 | 8、24、32、64、128、512、1024、4096 |
| 可选字段 | 常用最简、全信号、无 ready、无 last、只有 keep、只有 strb、两者均无、仅侧带 |
| ID/DEST | 0、1、8、32 位边界，至少一个多 key 场景 |
| USER | 0、1、非 lane 整数倍、PER_BYTE 整数倍、4096 位编译边界 |
| 宽度转换 | 32↔64、24↔40；至少一个 POSITION 和全 NULL TLAST 场景 |
| CDC | 快到慢、慢到快、同频异相；双侧及单侧复位合同 |
| 构建 | FULL_UVM、PASSIVE_UVM、CHECKER_ONLY |

矩阵使用边界点和 pairwise 组合，不要求全部笛卡尔积。每条支持能力至少有正向测试，所有非法配置至少有代表性拒绝测试。

### 16.3 发布判据

REQ-ACC-001：所有 mandatory requirement 均映射到实现、测试和证据；RTM 不允许悬空 mandatory 项。

REQ-ACC-002：合法定向和随机回归无非预期 ERROR/FATAL；每条协议规则的负向测试均能命中预期规则且没有未解释额外告警。

REQ-ACC-003：适用的 mandatory 功能覆盖 bin 全部命中或有逐项批准的 waiver；不能仅凭总代码覆盖率宣布协议完备。

REQ-ACC-004：至少一次连续 10000 beat 的 ALWAYS_READY 测试证明无 VIP 自带气泡；至少一个 1000000 accepted beat 压力测试证明无丢失/重复、统计守恒且 FULL capture 关闭时内存有界。

REQ-ACC-005：每个核心合法场景至少 20 个固定 seed；失败必须输出可重放配置和最小相关窗口。后续是否扩增 seed 由覆盖缺口和缺陷决定。

REQ-ACC-006：reset/cancel/watchdog 测试不发生静默挂死、不撤销正常 stall beat、不错误接受复位中的 beat。

REQ-ACC-007：至少在一个完整四态 UVM 仿真器上全量通过；若宣称跨仿真器支持，则在第二个声明版本完成规定兼容矩阵。发布报告列明真实环境，禁止泛称“所有仿真器”。

## 17. 交付件与实施阶段

| 交付件 | 内容 |
|---|---|
| `requirements.md` | 本需求合同及变更记录 |
| `requirements.yaml` | req ID、优先级、适用 profile、验证方法 |
| `config_schema.yaml` | 参数、默认值、范围、约束、端口存在性 |
| `architecture.md` | 组件、线程、采样/驱动时序、复位、事件及参考模型设计 |
| `verification_plan.md` | 合法/非法测试、配置矩阵、覆盖策略、预期规则 |
| `rtm` | 需求→实现→测试→覆盖→结果追溯 |
| `src/` | UVM、interface、Checker/SVA、模型、序列库 |
| `tests/`、`examples/` | 独立自验证 fixture、集成示例、回归清单 |
| `.core` | FuseSoC 依赖与运行目标 |
| `user_guide.md` | 参数、角色、API、应用 profile、诊断和限制 |
| `validation_report.md` | 实际工具版本、运行证据、覆盖、缺陷和 waiver |

推荐按以下顺序实施，各阶段持续更新 RTM：

1. G1：冻结端口/参数、规则映射、reset 采样语义、事务字段；同步编写 verification plan。
2. G2：Source/Sink/Passive、握手与 reset、beat monitor、基础 checker、自验证直连与 FIFO。
3. G3：packet/multi-stream、全部 qualifier、背压、覆盖与错误注入。
4. G4：logical-stream scoreboard、width conversion、routing、CDC reset 合同。
5. G5：配置矩阵、压力、完整四态负向回归、文档与发布验收。

## 18. 参考依据与冻结事项

- [Arm IHI 0051 协议入口](https://developer.arm.com/documentation/ihi0051/)：协议主依据；本规格选择 AXI4-Stream 基线，不将后续版本的所有扩展纳入 V1.0。正式 G1 应保存合法获取的固定版本和逐规则章节映射。
- [AMD AXI4-Stream VIP PG277](https://docs.amd.com/v/u/en-US/pg277-axi4stream-vip)：参照其发送、接收、监测和检查能力；其检查表将 VALID/payload 保持、复位释放、字节限定符列为检查项，MAXWAITS 属建议，特定复位脉宽属于 vendor 配置要求。

本次已核对 PG277 的协议检查表和功能说明；Arm 当前在线入口未返回可逐页核验的协议正文。因此本文是工程规划草案，G1 的 Arm 固定版本章节映射仍需完成，不能将此草案标记为协议认证或 G1 PASS。位宽上限、队列容量、API、覆盖和发布门槛均为本项目设计要求，并非引用 vendor 的实现限制。
