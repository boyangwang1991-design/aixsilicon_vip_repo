---
document_id: aixsilicon:vip:ahb:req
document_type: requirement
title: AIXSILICON AHB VIP 需求规格
version: 0.9.0-review
target_version: 1.0.0
status: proposed_baseline
vip_name: ahb
category: amba
vlnv: aixsilicon:vip:ahb:1.0.0
implementation_profile: FULL_UVM
protocol_profiles: [AHB_LITE, AHB5, AHB_CLASSIC]
default_profile: AHB_LITE
owner: TBD
date: 2026-09-10
---

# AIXSILICON AHB VIP 需求规格

## 1. 目标与规范性约定

本 VIP 用于验证 AHB Manager（Master）、Subordinate（Slave）、互联、桥接器、寄存器接口及存储控制器；提供主动激励、响应建模、被动监测、协议检查、功能覆盖、数据参考模型和 UVM RAL 接入能力。本规格同时作为 VIP Development Suite 的完整输入样例，要求 Suite 能处理协议版本差异、可选特性依赖、复杂流水时序、负向测试以及需求追踪。

本文“必须”表示对应配置下的验收要求；“建议”表示架构或集成建议。所有带 `AHB-` 编号的条目均为规范性需求。表中“验收”是最低证据要求，不代替后续完整验证方案。

协议可选不等于产品可不实现：本产品 V1.0 应实现本文全部特性能力，但允许用户在实例配置中关闭不适用功能。开发可分阶段，未完成的剖面必须明确标为未发布，不得以一个全局 PASS 掩盖缺项。本文为待评审基线，不声明已经实现、通过协议认证或完成 G0 冻结。

### 1.1 参考基线与来源

| 编号 | 参考资料 | 用途 |
|---|---|---|
| S1 | [Arm AMBA AHB Protocol Specification，IHI 0033C](https://documentation-service.arm.com/static/6141bf0d674a052ae36ca811) | AHB-Lite/AHB5 主基线；章节 2–12、附录 A 为规则定位入口 |
| S2 | [Arm IHI 0033 B.b 文档入口](https://developer.arm.com/documentation/ihi0033/bb/) | AHB5 旧版本兼容配置，冻结前需取得正文并做差异核对 |
| S3 | [Arm IHI 0011A 文档入口](https://developer.arm.com/documentation/ihi0011/a/) | 经典 AMBA 2 AHB 兼容剖面，冻结前需取得正文并做逐条核对 |
| S4 | [Arm AMBA 规范目录](https://www.arm.com/architecture/system-architectures/amba/amba-specifications) | 规范入口和后续版本变更检查 |

本次已核对 S1 正文；S2/S3 当前仅作为参考入口，不声称已经逐条核对。本文选择明确的 Issue C 基线，不宣称其为最新版本。有关经典 AHB 的需求是产品规划，必须在该剖面发布前补齐 S3 的条款映射与审查。

Issue C 涵盖信号宽度属性、写选通、USER 更新、有效性规则与接口奇偶校验，不能把较早 AHB5 的特性集当作 Issue C 的完整范围。[来源：S1，修订记录及目录](https://documentation-service.arm.com/static/6141bf0d674a052ae36ca811)

以下大量条目是本项目自行定义的 VIP 行为、API、模型策略和验收要求；不是 Arm 标准的翻译或替代文本。凡依赖协议细节的 checker，最终必须链接至选定版次原文，并区分强制规则、推荐项和实现策略。

### 1.2 需求字段与追踪规则

每个需求 ID 全局唯一，不随章节调整重编号。条目默认优先级为 P0、目标为 V1.0；所属章节声明的适用范围由条目继承。独立条目可进一步细化为子需求，但不得删除父需求的验收责任。

验证方法：`T` 定向/随机仿真；`N` 负向或故障注入；`A` 协议断言/状态检查；`C` 功能覆盖；`I` 静态审查/集成检查；`P` 性能与资源测量。

推荐追踪链：`TC → FL → REQ`，同时 `CHK/COV → FL/REQ`。本文件中的表格 ID 是权威需求标识；机器导出元数据由 Suite 按自己的既有 schema 生成，不要求为了本样例改变 Suite 的解析协议。

## 2. 产品边界与协议剖面

| 剖面 | 目标 | 关键能力 | 排除的混用 |
|---|---|---|---|
| AHB_LITE | 单接口 AHB-Lite，允许集成进多 Manager 的互联系统 | 流水、Burst、BUSY、Wait、ERROR、Lock | 不出现经典 AHB 的 SPLIT/RETRY 与共享总线仲裁信号 |
| AHB5 | AHB5，默认 Issue C | 基础能力与可配置安全属性、扩展内存属性、Exclusive、USER、写选通、接口保护 | Exclusive 的 HMASTER 不能被解释成总线 grant；不引入 AXI ID/乱序响应 |
| AHB_CLASSIC | AMBA 2 经典共享总线 AHB | 多 Master 仲裁、所有权交接、Lock、SPLIT、RETRY | 不自动叠加 AHB5 扩展 |

| ID | 需求 | 验收 |
|---|---|---|
| AHB-SCP-001 | 必须提供 Manager Active、Subordinate Active、Passive 三种角色；Active 实例必须包含独立 monitor。 | T/I：三种角色分别运行；Passive 对所有总线信号零驱动。 |
| AHB-SCP-002 | 必须将协议剖面、规范版次、角色、信号 presence、运行策略分开配置；不允许仅用一个 `ahb5_enable` 控制全部差异。 | I/N：非法组合在 run 前失败并指出冲突字段。 |
| AHB-SCP-003 | 必须支持单 Manager/单 Subordinate、单 Manager/多 Subordinate、多 Manager/多 Subordinate 的测试环境组装。 | T：分别验证寻址、响应路由和并发竞争。 |
| AHB-SCP-004 | 多 Manager 的 AHB-Lite/AHB5 验证必须通过多实例及互联环境完成；每接口独立跟踪流水状态。 | T：至少四 Manager、四 Subordinate，停顿互不串扰。 |
| AHB-SCP-005 | 必须支持只读、只写、读写、仅 SINGLE、受限 HSIZE 等 DUT capability 描述；区分 DUT 不支持功能与协议非法流量。 | T/N：合法但不支持的请求可发送，并验证 DUT 指定错误策略。 |
| AHB-SCP-006 | 必须提供 capability 查询与导出，列明 supported/enabled/tested/unsupported，不允许以静默降级代替未支持报错。 | I/N：配置、日志与测试清单一致。 |
| AHB-SCP-007 | VIP 不承担 DUT CDC、缓存一致性、功能安全等级或系统原子性的自动证明；可通过观察插件和专用环境验证相关系统要求。 | I：用户指南给出可观察性边界。 |

## 3. 参数、接口与配置

### 3.1 配置能力范围

下表是产品支持范围；旧版协议配置必须使用该版允许的信号宽度与 presence。软件队列深度、等待上限等是 VIP 参数，不是 AHB 线上字段或协议限制。

| 项目 | 支持范围/默认 |
|---|---|
| 默认配置 | AHB_LITE / Issue C / Manager Active / 32-bit 地址 / 32-bit 数据 / little-endian |
| 数据宽度 | 8、16、32、64、128、256、512、1024 bit；各版次合法性另行检查 |
| Issue C 地址宽度 | 产品支持 10–64 bit，逐整数支持；旧版兼容配置为 32 bit |
| HBURST presence | Issue C 支持宽度 0 或 3；无该信号时按对应缺省语义处理 |
| HPROT presence | 支持宽度 0、4、7，与版次及 Extended_Memory_Types 联动 |
| HMASTER width | Issue C AHB5 产品支持 0–8 bit；经典剖面按经典接口单独定义 |
| USER width | Issue C：USER_REQ_WIDTH 0–128、USER_DATA_WIDTH 0–DATA_WIDTH/2、USER_RESP_WIDTH 0–16 |
| Endianness | Little-endian、Byte-invariant big-endian；Word-invariant big-endian 仅在适用版次兼容模式启用 |
| 功能属性 | Secure_Transfers、Extended_Memory_Types、Exclusive_Transfers、Write_Strobes、Check_Type、原子性相关属性 |
| Check_Type | False、Odd_Parity_Byte_All；自定义保护仅作为 vendor extension |
| 随机等待 | 0、固定值、范围随机、加权随机、外部回调；可单独设置异常长等待 |
| 超时 | 默认协议 timeout 关闭；test watchdog 默认 100000 HCLK，可配置 |
| 软件请求队列 | 默认 16，支持 1–1024；不能解释为 1024 个线上 outstanding |
| 响应存储模型 | 默认 byte-addressable sparse memory；未初始化读默认返回 X 并报告 |
| 错误写模型 | 默认不提交；支持用户显式提供部分提交/设备副作用回调 |

### 3.2 接口需求

| ID | 需求 | 验收 |
|---|---|---|
| AHB-CFG-001 | 必须提供类型安全的 SystemVerilog interface、角色 modport 和采样/驱动时序契约；结构参数与运行配置分离。 | I/T：合法参数编译、各角色接入参考 DUT。 |
| AHB-CFG-002 | 必须完整支持基础信号 HCLK、HRESETn、HADDR、HTRANS、HWRITE、HSIZE、HBURST、HPROT、HMASTLOCK、HWDATA、HRDATA、HREADY、HRESP，以及 Subordinate 侧 HSEL/HREADYOUT。 | I：按角色信号矩阵核对方向、宽度、presence。 |
| AHB-CFG-003 | 必须明确 HREADY 为本接口流水推进依据，HREADYOUT 为 Subordinate 响应输出；不得用当前地址 HSEL 直接决定当前数据响应归属。 | T/N：A 等待时地址切换至 B，A 的数据响应仍归 A。 |
| AHB-CFG-004 | 必须支持 AHB5 的 HNONSEC、HEXCL、HMASTER、HEXOKAY，并与相关 property 联动。 | T/N：所有启停组合和缺失信号配置检查。 |
| AHB-CFG-005 | 必须支持 Issue C 的 HWSTRB、HAUSER、HWUSER、HRUSER、HBUSER，以及已启用的全部 CHK 信号。 | I/T：对照接口矩阵、宽度边界和零宽度配置。 |
| AHB-CFG-006 | 零宽度表示逻辑信号不存在，不得产生非法 SV 范围、幽灵驱动或误覆盖；内部占位实现不得泄漏到用户语义。 | I/T：全关闭扩展配置可编译、运行。 |
| AHB-CFG-007 | 必须校验 feature dependency、参数范围、接口和 config 一致性；结构配置必须在 build 完成前冻结。 | N：每类冲突至少一个反例。 |
| AHB-CFG-008 | 运行时允许调整随机分布、等待、错误策略和日志；影响当前事务的配置必须做事务快照，调整从后续事务生效。 | T：等待期间更改配置不污染正在执行的 beat。 |
| AHB-CFG-009 | 必须配置地址区域、DUT 支持的 transfer size、读写权限、安全域和响应策略；重叠区域必须显式优先级或拒绝。 | N/T：重叠、空洞、边界及优先级。 |
| AHB-CFG-010 | 同一仿真必须支持不同宽度、剖面和配置的 VIP 实例；不得使用未隔离的全局状态。 | T：32-bit Lite 与 128-bit AHB5 混合运行。 |

## 4. 事务模型与公开 API

适用范围：全部剖面，扩展字段按 capability 启用。

| ID | 需求 | 验收 |
|---|---|---|
| AHB-TRN-001 | 必须同时提供 beat 级事务和 burst 级聚合；可分别发布周期事件、地址接受事件、完成事件和诊断事件。 | T：逐周期参考轨迹与事件一一对齐。 |
| AHB-TRN-002 | 请求必须包含方向、起始地址、HSIZE、HBURST、数据列表、属性、BUSY/IDLE 插入计划及用户 tag。 | I/T：序列 API 可直接表达各类请求。 |
| AHB-TRN-003 | 扩展请求必须包含 security、exclusive、manager identity、user、write strobe 与故障计划；字段有效性由剖面判定。 | N：禁用特性字段不得被静默忽略。 |
| AHB-TRN-004 | 完成记录必须包含读数据、逐 beat HRESP/HEXOKAY、等待周期、地址接受/完成时间、实际地址及终止原因。 | T：错误位于首/中/末 beat 时结果精确。 |
| AHB-TRN-005 | 必须分别表示 OKAY、ERROR、EXCLUSIVE_FAIL、RESET_ABORT、WATCHDOG、CANCEL_BEFORE_ACCEPT 和经典 RETRY/SPLIT；协议响应与 VIP 状态不得共用含糊编码。 | T：上层调用能无歧义处理每个结果。 |
| AHB-TRN-006 | 必须区分 requested、offered、accepted、completed、aborted 生命周期；未接受的流水候选不能计入成功完成。 | T：ERROR、复位和撤销场景无重复或伪事务。 |
| AHB-TRN-007 | 必须提供同步 read/write、异步提交、等待完成、burst、exclusive pair 和用户自定义 sequence 接口。 | T：同一场景可由高级 API 和 beat API 等价执行。 |
| AHB-TRN-008 | 回调至少覆盖请求合法性调整、地址驱动前、响应选择、数据生成、事务完成和故障注入；回调时序与所有权必须文档化。 | I/T：回调不会绕过 monitor，无法事后篡改已发布事务。 |
| AHB-TRN-009 | 必须实现深拷贝、比较、打印和事务记录；数组、扩展对象、四态值不得丢失。 | T：复制后修改原事务不会影响已发布记录。 |
| AHB-TRN-010 | 内部 transaction ID 只用于调试与关联；不能假设 AHB 总线携带该 ID 或支持乱序返回。 | I/T：长软件队列仍按接口实际顺序完成。 |

## 5. 基础传输与流水

适用范围：全部剖面；来源定位 S1 第 3、5、8 章，经典版差异由规则表覆盖。

| ID | 需求 | 验收 |
|---|---|---|
| AHB-BAS-001 | 必须支持所有配置数据宽度下的单次读写、窄传输和满宽传输。 | T/C：方向×宽度×合法 HSIZE。 |
| AHB-BAS-002 | 必须按 HCLK 采样边沿建立地址阶段与后续数据阶段的对应关系。 | T：读写交替、不同地址连续访问不串拍。 |
| AHB-BAS-003 | 零等待且请求充足时，普通传输必须达到稳态每 HCLK 完成一个 beat，不得因 UVM item 握手强制插空。 | P/T：连续 256 beat，填充/排空之外无 VIP 引入气泡。 |
| AHB-BAS-004 | 必须根据有效地址接受条件采纳请求；Subordinate 监测应包含 HSEL、HREADY 与有效 HTRANS 判断。 | T：未选中、IDLE、BUSY 和 HREADY 低时不产生新有效 beat。 |
| AHB-BAS-005 | 地址、写数据、读数据和响应必须按各自阶段跟踪；后续地址不得覆盖当前写数据的地址与属性。 | T：每拍不同 HSIZE/方向/目标，随机停顿，逐字节比对。 |
| AHB-BAS-006 | 必须支持 IDLE/NONSEQ/SEQ/BUSY 的合法组合；IDLE/BUSY 不产生实际存储访问。 | T/A：检查 memory callback 次数与有效 beat 数相等。 |
| AHB-BAS-007 | 必须支持等待期间规范允许的 IDLE/BUSY 转换；checker 不得使用“所有信号在 HREADY 低时一律稳定”的简化规则。 | T/N/A：合法变化零误报，违反有效阶段保持规则必报。 |
| AHB-BAS-008 | 必须支持普通等待期间写数据保持，读数据仅在相应有效完成条件下采信；ERROR 等例外按版本规则处理。 | T/N：非有效读周期随机变化不误报；有效拍损坏可检出。 |
| AHB-BAS-009 | 必须覆盖 R→R、R→W、W→R、W→W 连续传输及各组合中的等待。 | T/C：四种切换×0/1/多等待。 |
| AHB-BAS-010 | 对没有协议定义最大等待的场景，必须把过长等待报告为环境 watchdog/policy，不得宣称违反 AHB 固有 timeout。 | T：关闭 watchdog 可持续等待；开启后按指定原因终止测试。 |

## 6. Burst、地址与字节映射

| ID | 需求 | 验收 |
|---|---|---|
| AHB-BST-001 | 必须生成和识别 SINGLE、INCR、INCR4/8/16、WRAP4/8/16；固定长度按有效数据 beat 计数。 | T/C：全部 HBURST×读写。 |
| AHB-BST-002 | INCR 必须支持用户指定有限长度及动态结束；资源保护上限属于生成器策略，monitor 不得因正常长 burst 溢出。 | T：1、2、3、17、256、1024 beat，必要时分割合法边界。 |
| AHB-BST-003 | Burst 地址模型必须独立检查增量与 wrap；WRAP 起点可位于 wrap 窗口内任一合法 beat 地址，不得强制从窗口基址开始。 | T/N：每个 wrap 起点偏移及错误回绕地址。 |
| AHB-BST-004 | 必须对自然对齐、HSIZE 与总线宽度关系、增量 burst 的 1KB 边界约束做合法性检查。 | T/N：边界前最后合法传输及故意跨界。 |
| AHB-BST-005 | 高层大块访问 API 可按 1KB 边界及 DUT 能力拆分请求；底层 raw API 不得悄悄修正负向测试流量。 | T：拆分后数据、地址和字节数守恒。 |
| AHB-BST-006 | 必须支持 burst 内可配置数量和位置的 BUSY，并检查固定/未定长 burst 的不同终止规则。 | T/N：首个有效拍之后、内部、尾部边界，合法与非法对照。 |
| AHB-BST-007 | 必须检查 burst 内应保持的属性和 SEQ 地址关系；错误、复位、互联打断等合法上下文不应被当作普通序列损坏。 | T/A：明确终止原因后重新 NONSEQ 启动。 |
| AHB-BST-008 | 必须允许 Subordinate 侧看到被互联拆分或提前终止的 burst，并记录实际观察长度；是否违规依观察点和可见上下文判断。 | T：互联两侧轨迹不同仍能正确比对。 |
| AHB-BST-009 | 必须为全部 endian 模式定义地址到 byte lane 的映射；参考模型统一以字节地址存储。 | T：每个合法 lane、HSIZE、多宽度读回。 |
| AHB-BST-010 | 数据比对应使用有效 byte mask 和 valid mask；不能强制未用数据 lane 为零，也不能在未知有效数据上以二态比较判成功。 | T/N：无效 lane 随机/X 不误报；有效 lane X 可诊断。 |
| AHB-BST-011 | 不得宣称基础 AHB 支持任意 unaligned 单笔传输；高层非对齐访问只能显式拆成合法访问并暴露拆分结果。 | T/N：raw 非对齐被识别，高层拆分可读回。 |

## 7. 响应、错误与恢复

| ID | 需求 | 验收 |
|---|---|---|
| AHB-RSP-001 | Subordinate 必须支持零等待、固定等待、随机等待及脚本化逐 beat 等待。 | T/C：等待 0、1、2、15、256 和随机长尾。 |
| AHB-RSP-002 | 必须支持 OKAY 和符合剖面时序的 ERROR；AHB-Lite/AHB5 ERROR 包含两周期响应过程，不能实现为普通单周期错误脉冲。 | T/N/A：正确、缺少首周期、缺少完成周期均有测试。 |
| AHB-RSP-003 | 必须允许 ERROR 前插入普通等待，区分普通等待与错误响应阶段。 | T：0/1/多前置等待，错误只完成一次。 |
| AHB-RSP-004 | Manager 必须正确处理 ERROR 对流水候选地址的取消/继续；提供停止剩余 burst 与按协议继续的策略。 | T：错误首/中/末拍，两策略下记录无丢失、无重复。 |
| AHB-RSP-005 | 必须支持地址、方向、HSIZE、属性、beat 索引、概率、次数与用户回调触发 ERROR。 | T：每种触发命中精确，固定 seed 可复现。 |
| AHB-RSP-006 | 错误写入副作用必须使用显式模型策略；默认 memory model 不提交失败写，但 checker 不得据此认定所有 DUT 错误写均无副作用。 | T：默认策略与设备回调策略分别验证。 |
| AHB-RSP-007 | 默认目标模型必须区分有效未映射访问和 IDLE/BUSY；前者执行配置的错误策略，后者不制造虚假访问错误。 | T：空洞访问、空闲与 BUSY。 |
| AHB-RSP-008 | 连续错误、错误后正确访问、等待中错误、错误中复位必须恢复到一致状态。 | T：后续 100 个正确访问全部匹配。 |

## 8. Lock 与经典 AHB 兼容

### 8.1 Lock：全部适用剖面

| ID | 需求 | 验收 |
|---|---|---|
| AHB-LCK-001 | 必须支持合法 locked sequence，覆盖读改写、多拍、等待和错误；锁属性随相应地址阶段关联。 | T/C：有锁/无锁×读写×等待/错误。 |
| AHB-LCK-002 | 系统级 lock checker 必须观察相关所有权/路由，才可判断其他 Manager 是否非法插入；仅单接口 monitor 不得宣称验证全局互斥。 | T：有/无竞争及可见性不足的报告。 |
| AHB-LCK-003 | 必须区分 locked transfer 与 exclusive transfer，分别配置、生成、统计和验证。 | I/N：不会用 HEXCL 替代 HMASTLOCK。 |

### 8.2 AHB_CLASSIC：独立兼容包

本节全部条目在经典剖面启用时为 P0；可作为较后开发里程碑，但未完成前必须明确 V1.0 经典剖面未验收。

| ID | 需求 | 验收 |
|---|---|---|
| AHB-LEG-001 | 必须提供经典 HRESP[1:0]、HBUSREQ、HGRANT、HLOCK、HMASTER、HMASTLOCK、HSPLIT 相关接口绑定，并按观察点区分信号来源。 | I/T：对照 S3 接口及系统拓扑审查。 |
| AHB-LEG-002 | 必须支持 Master 申请、授权、撤销申请、默认 Master、无请求场景及有效所有权转移。 | T/N：grant 变化与真正获得总线不得混同。 |
| AHB-LEG-003 | 必须分别跟踪地址阶段 Master 与数据阶段 Master，覆盖交接时上一 Master 的写数据/响应。 | T：不同 Master 数据模式、等待及 back-to-back 交接。 |
| AHB-LEG-004 | 必须提供可配置固定优先级与轮询的参考 arbiter BFM；可禁用该 BFM 以连接 DUT arbiter。 | T：竞争、无竞争、持续请求、优先级变化。 |
| AHB-LEG-005 | 必须生成、识别并检查 OKAY/ERROR/RETRY/SPLIT 的各自合法时序。 | T/N：合法两周期非 OKAY 响应与损坏时序对照。 |
| AHB-LEG-006 | RETRY 必须作为一次尝试被拒绝记录，支持重新申请和重发；不得把该尝试计为数据访问成功。 | T：单次及多次 RETRY 后成功，无重复提交。 |
| AHB-LEG-007 | SPLIT 必须跟踪被拆分 Master、屏蔽与 HSPLIT 释放；支持多 Subordinate 释放及多 Master 等待。 | T：释放前不能错误重新授权，释放后可恢复。 |
| AHB-LEG-008 | 必须支持 retry/split 重试上限与 watchdog，明确是 VIP 策略；不在协议上凭空增加响应编码。 | T：无限重试场景可诊断结束。 |
| AHB-LEG-009 | 必须覆盖 burst 被抢占后的合法恢复、锁定期间仲裁、复位清除 split 状态及经典版锁约束。 | T/A：逐场景对照已核对 S3 条款。 |
| AHB-LEG-010 | 仲裁公平性必须按选定策略与“竞争者最终释放”等环境假设验证，不得将固定优先级可能饥饿判为协议错误。 | T/I：公平与非公平策略分别验收。 |

## 9. AHB5 安全与内存属性

适用范围：AHB5；功能启用时为强制需求。

| ID | 需求 | 验收 |
|---|---|---|
| AHB-SEC-001 | 必须生成、采样、检查和覆盖 HNONSEC；支持每个事务选择安全属性。 | T/C：Secure/Non-secure×读写×等待/ERROR。 |
| AHB-SEC-002 | 响应模型必须支持按地址和安全属性配置访问权限；权限拒绝是模型/DUT 策略，不是每个安全属性切换都必须报错。 | T：允许/拒绝矩阵与预期一致。 |
| AHB-SEC-003 | 必须支持同一数值地址的安全域共享或隔离存储策略，并与 exclusive monitor 的身份/域匹配配置一致。 | T：同址跨安全域读写及排他干扰。 |
| AHB-SEC-004 | 必须支持基础与扩展 HPROT 的原始值和语义解码；不能把 7-bit 属性当作任意 USER 位。 | I/T：合法编码表、非法组合、属性传播。 |
| AHB-SEC-005 | 必须提供特权/非特权、指令/数据及内存属性相关激励；协议合法性与 DUT 权限策略检查分别报告。 | T/N：合法但禁止的访问与非法编码有不同诊断。 |
| AHB-SEC-006 | 必须在互联环境支持安全属性和 HPROT 的透传、允许的变换与默认值检查；变换策略由 DUT 合同给出。 | T：属性丢失或错误改写可检出。 |
| AHB-ATM-001 | 必须记录 Single_Copy_Atomicity_Size 和 Multi_Copy_Atomicity 等适用属性，验证配置依赖；不将单接口有序完成等同于系统原子性。 | I/N：不兼容配置可诊断。 |
| AHB-ATM-002 | 系统验证扩展必须支持按声明原子粒度构造多 Manager 交错读写及可见性检查；缺少观察点时结果为未验证。 | T：完整可见与不完整可见环境分别报告。 |

## 10. AHB5 Exclusive

适用范围：AHB5 且 Exclusive_Transfers 开启；源规则定位 S1 第 10 章。

| ID | 需求 | 验收 |
|---|---|---|
| AHB-EXC-001 | 必须支持 exclusive read、exclusive write 及组合序列，正确区分 HRESP 总线结果和 HEXOKAY 排他结果。 | T：总线成功但排他失败、排他成功、总线错误。 |
| AHB-EXC-002 | 必须提供可替换的 exclusive access monitor 参考模型，配置保留粒度、容量、替换策略及外部失效入口。 | I/T：模型配置与 DUT reservation 合同一致。 |
| AHB-EXC-003 | 必须覆盖成功配对、无先行 read 的 write、read 后不写、地址/尺寸/属性/身份不匹配及 reservation 被替换。 | T/C：每种失配单独观察结果。 |
| AHB-EXC-004 | 必须验证其他 Manager 的普通/排他写、重叠字节写与不同地址写对 reservation 的影响；以实际配置粒度判断。 | T：同粒度冲突和粒度外无冲突。 |
| AHB-EXC-005 | 在支持排他的区域，失败 exclusive write 不得提交参考存储更新；不支持排他区域的行为按明确的目标合同建模。 | T：失败前后目标字节及邻近字节比较。 |
| AHB-EXC-006 | 必须校验 exclusive 的传输形式、配对字段、BUSY 限制及同身份的阶段重叠限制；不得照搬 AXI exclusive burst 模型。 | T/N/A：逐限制正反例。 |
| AHB-EXC-007 | 必须检查 HEXOKAY 的有效条件、与 HRESP 的相容性以及对应数据阶段，避免归到下一笔地址。 | T/N：等待、错误、普通传输中错误拉高。 |
| AHB-EXC-008 | 必须支持至少两个以上逻辑身份竞争，以及跨接口身份重映射；不同 Manager 不得因局部 ID 相同共享 reservation。 | T：四 Manager，同局部 ID、不同全局身份。 |
| AHB-EXC-009 | 复位必须按环境合同清除 reservation；仅 VIP 重启与 DUT 复位不得被无条件视为相同系统事件。 | T：复位后旧配对不能误成功。 |
| AHB-EXC-010 | 未观察到所有写入来源时，系统 exclusive checker 必须报告可见性限制；支持外部写/缓存/后门更新的失效通知。 | T：外部干扰通知使结果更新。 |

## 11. Issue C 写选通、USER 与接口保护

### 11.1 Write_Strobes

| ID | 需求 | 验收 |
|---|---|---|
| AHB-STR-001 | 必须支持 HWSTRB 的驱动、采样、保持检查及逐 beat 变化，按写数据阶段关联。 | T/N：下一地址出现时仍使用当前 beat strobe。 |
| AHB-STR-002 | 有效写入 mask 必须由地址/尺寸确定的活动 lane 与 HWSTRB 共同形成；不能仅依据 strobe 更新内存。 | T：窄传输时非活动 lane 的 strobe 任意变化不改变目标外字节。 |
| AHB-STR-003 | 必须覆盖全一、全零、单 byte、交替和稀疏 strobe；全零写必须完成但不更新任何 byte。 | T/C：各模式×合法 HSIZE×等待。 |
| AHB-STR-004 | 非活动 lane 的 strobe 为一不得被当作通用协议违规；读时 strobe 的推荐行为不得提升为强制错误。 | T/N：false-positive 专项验证。 |
| AHB-STR-005 | 不支持写选通的目标只接受相容的非稀疏使用方式；禁止静默把稀疏写扩大成全写。 | T/N：接口兼容矩阵检查。 |

### 11.2 USER

| ID | 需求 | 验收 |
|---|---|---|
| AHB-USR-001 | 必须支持 HAUSER、HWUSER、HRUSER、HBUSER，并按请求、写数据、读数据和响应各自有效阶段关联。 | T：每阶段不同模式，流水与等待下不串拍。 |
| AHB-USR-002 | USER 只提供载荷与可插拔语义，核心 VIP 不得将用户编码解释为协议固定权限、QoS 或事务 ID。 | I/T：两个不同 USER 插件独立工作。 |
| AHB-USR-003 | 必须支持 USER 稳定性/有效性检查、覆盖及互联透传检查，包含 ERROR 例外与零宽度。 | T/N：合法变化零误报，非法变化可诊断。 |
| AHB-USR-004 | 宽度转换环境必须允许配置数据 USER 的 byte 级映射和响应 USER 聚合规则，缺少策略时禁止猜测。 | I/T：拆分/合并测试匹配明确合同。 |

### 11.3 Interface Protection

| ID | 需求 | 验收 |
|---|---|---|
| AHB-PAR-001 | Check_Type=Odd_Parity_Byte_All 时必须完整生成与校验该配置存在的全部保护信号，不得只实现数据 parity。 | I/T：对照 S1 第 12 章及附录 A.2 的完整矩阵。 |
| AHB-PAR-002 | 必须按各保护组的信号拼接、粒度、非整字节宽度与有效周期计算 parity；支持地址宽度非 8 倍数。 | T：10/17/33/64-bit 地址及 USER 尾组。 |
| AHB-PAR-003 | 必须提供受保护数据位翻转、check bit 翻转、多位翻转和指定周期注入，报告受影响信号组。 | N：每个存在的保护组至少一次单 bit 检出。 |
| AHB-PAR-004 | 必须区分 parity 检出与 DUT 后续处理策略；不要求 parity 错误必然映射为 AHB ERROR。 | T：中断、错误响应及仅记录等策略由 DUT 合同选择。 |
| AHB-PAR-005 | 必须处理等待、空闲、未选中、复位与错误期间各保护组的检查使能，不能一律按数据完成拍采样。 | T/N：有效/无效窗口成对注入。 |
| AHB-PAR-006 | 必须说明奇偶校验对多 bit 故障的检测局限；偶数位翻转未触发 parity 不得自动判 checker 失效。 | N/I：单 bit 与同组双 bit 注入使用不同预期。 |

## 12. Subordinate 数据模型与系统比对

| ID | 需求 | 验收 |
|---|---|---|
| AHB-MEM-001 | 必须提供 byte-addressable sparse memory，覆盖 64-bit 地址空间而不按地址空间全量分配。 | T/P：相距较远的地址写读，存储开销随使用量增长。 |
| AHB-MEM-002 | 必须支持 zero、constant、address-pattern、seeded-random、X 和文件预装策略；已初始化有效位与实际数据分开保存。 | T：每策略可重复且未初始化可区分。 |
| AHB-MEM-003 | 普通成功写默认只在有效完成时提交一次；等待期间不重复触发写副作用。 | T：长等待写与回调计数。 |
| AHB-MEM-004 | 必须支持只读、只写、读清、写一清、FIFO window 等设备行为插件；总线数据模型与设备语义解耦。 | T：至少存储、寄存器副作用、FIFO 三种示例。 |
| AHB-MEM-005 | 必须提供 backdoor peek/poke/load/dump，并规定与 frontdoor 同时访问的调度与模型同步规则。 | T：同周期冲突可重复，exclusive 失效通知完整。 |
| AHB-MEM-006 | 必须支持共享 memory model 的多实例访问；操作顺序以实际观测的提交顺序及明确冲突策略定义。 | T：多 Manager 同址冲突无仿真竞态。 |
| AHB-MEM-007 | 被动参考 scoreboard 必须以实际观察的成功数据事件更新，不得用 driver 想发送的请求代替 DUT 行为。 | N：故意丢拍、改数据、错路由能被发现。 |
| AHB-MEM-008 | 互联/桥接 scoreboard 必须支持可配置地址映射、宽度变换、burst 拆分、错误传播和属性转换。 | T/N：正常转换匹配；丢失、重复、错 lane 可检出。 |
| AHB-MEM-009 | 无数据模型或无法看见数据来源时，可独立运行协议 checker；必须明确数据完整性未验证。 | I/T：protocol-only 模式报告范围。 |

## 13. Reset、取消与异常环境

| ID | 需求 | 验收 |
|---|---|---|
| AHB-RST-001 | 必须处理低有效复位及配置的合法释放时序；时钟/复位驱动为可选独立环境能力，agent 不得擅自驱动外部 reset。 | T/I：外部与环境驱动两种接入。 |
| AHB-RST-002 | 复位时主动端必须进入该剖面规定的总线状态，清除流水、burst、响应、仲裁及 reservation 临时状态。 | T/A：空闲、地址、数据、等待、ERROR、SPLIT 中复位。 |
| AHB-RST-003 | 已完成 beat 必须保留记录；未完成操作必须产生明确 abort，等待 API 不能永久挂起。 | T：完成与复位相邻边沿有确定结果。 |
| AHB-RST-004 | 软件排队请求默认在 reset 后撤销；可显式配置重提交，重新提交必须使用新 attempt 关联且不重复提交已完成写。 | T：多请求队列中途 reset。 |
| AHB-RST-005 | memory 清除、保持、重新预装必须可配置；协议状态复位不得隐式要求 SRAM 内容清零。 | T：warm reset 保持和 cold reset 清除。 |
| AHB-RST-006 | 必须在复位后恢复接收新请求，且不发布复位前的幽灵完成/残留 checker 事件。 | T：复位后连续访问与 clean start 结果一致。 |
| AHB-RST-007 | sequence kill/stop 不得把已接受的总线事务直接删除；必须按 drain、协议可取消点或环境复位策略收敛。 | T：各阶段停止，无永久 objection 或挂死。 |
| AHB-RST-008 | 必须支持仿真中时钟暂停与恢复的健壮性测试；墙钟/仿真时间 watchdog 与 HCLK 周期 watchdog 分开。 | T：无 HCLK 时不会错误累计总线等待周期。 |

## 14. 协议 Checker 与错误注入

### 14.1 Checker 产品要求

| ID | 需求 | 验收 |
|---|---|---|
| AHB-CHK-001 | 必须支持独立 bind/interface checker 与 UVM monitor 场景检查；局部时序检查优先 SVA，长事务关联允许程序化实现。 | I/T：不实例化 driver 也能发现协议违规。 |
| AHB-CHK-002 | 每条 checker 必须拥有稳定 ID、协议版次、条款位置、启用条件、严重级别、观测信号与需求引用。 | I：checker registry 无重复 ID、无孤立需求。 |
| AHB-CHK-003 | 必须覆盖信号合法性、地址/数据阶段关联、保持规则、HTRANS、Burst/HSIZE/地址、ERROR、reset 与已启用扩展。 | T/N/A：每类都有合法/违规轨迹。 |
| AHB-CHK-004 | 必须按信号有效性窗口检查 X/Z；不得检查规范允许无效的载荷并产生误报。 | T/N：有效和无效周期分别注入 X。 |
| AHB-CHK-005 | 必须分别报告 protocol violation、DUT capability violation、environment policy、data mismatch、expected injection。 | T：同一运行可统计五种分类。 |
| AHB-CHK-006 | 必须允许逐规则 enable/severity/waiver；waiver 必须有原因、适用配置、失效条件，不能用全局降级掩盖失败。 | I/T：汇总包含启用、命中、豁免和缺测项。 |
| AHB-CHK-007 | checker 必须对非法流量继续保持可控状态，限制派生错误洪泛；诊断应保留首因与上下文。 | N：连续违规不会导致无限报错或 monitor 崩溃。 |
| AHB-CHK-008 | 错误报告至少包含 rule ID、实例、cycle、阶段、地址、transaction tag、实际/预期及前后周期快照。 | I/T：仅凭日志可定位预设错误。 |
| AHB-CHK-009 | 禁止仅通过 Manager 与 Subordinate 同源逻辑互连自测证明协议正确；必须有独立手写周期向量或独立参考实现。 | I/N：注入共同模型可能漏掉的 off-by-one 错误仍可检出。 |

### 14.2 负向测试能力

| ID | 需求 | 验收 |
|---|---|---|
| AHB-NEG-001 | 必须将合法随机激励与非法注入分离；默认不生成协议非法事务。 | T：纯合法回归零非预期 checker 报告。 |
| AHB-NEG-002 | 必须支持非法 HSIZE、非对齐、错误 SEQ 地址、非法 burst 变化、跨界和错误 BUSY 位置注入。 | N：每类注入命中对应规则。 |
| AHB-NEG-003 | 必须支持等待期间非法控制/写数据变化、错误阶段响应、单周期 ERROR 和响应错配。 | N：逐项精确定位，非目标规则关联说明。 |
| AHB-NEG-004 | 必须支持非法 exclusive、security/USER 篡改、strobe 数据破坏与 parity 故障，按特性存在性启用。 | N：扩展开启/关闭测试都有明确预期。 |
| AHB-NEG-005 | 必须支持信号级非法注入，允许绕过正常 transaction 约束；所有被绕过检查必须记录，不得永久关闭 checker。 | N：一次注入结束后检查自动恢复。 |
| AHB-NEG-006 | expected-error 匹配必须限定 rule ID、实例、次数及时间窗口；无关错误即使出现在负向用例中仍导致失败。 | N：漏报、多报、错报分别判失败。 |

## 15. 功能覆盖与性能统计

| ID | 需求 | 验收 |
|---|---|---|
| AHB-COV-001 | 必须提供方向、HTRANS、HBURST、HSIZE、地址对齐/lane、endianness、wait length、response、lock 的基础覆盖。 | C/I：每个适用 bin 可追踪需求。 |
| AHB-COV-002 | 必须覆盖流水转移、目标切换、BUSY 数量/位置、ERROR 的 beat 位置、取消/继续、burst 终止原因和复位阶段。 | C：定向闭合关键边界。 |
| AHB-COV-003 | 必须提供安全属性、扩展 HPROT、exclusive 成败原因/竞争、USER、strobe 模式、parity 组/窗口覆盖。 | C：禁用特性自动剔除相应 bin。 |
| AHB-COV-004 | 经典剖面必须覆盖请求/授权/所有权交接、仲裁竞争、RETRY 次数、SPLIT 释放和锁状态。 | C：每项对应经典需求。 |
| AHB-COV-005 | 必须至少定义 read/write×burst×size、wait×response×pipeline transition、reset×phase、exclusive outcome×interference 的关键交叉。 | I/C：非法组合 ignore 并注明原因。 |
| AHB-COV-006 | 必须区分正常完成覆盖、错误路径覆盖、非法注入覆盖；不能用非法注入填满正常功能 bins。 | T/C：三类报表可分开查看。 |
| AHB-COV-007 | 覆盖模型必须按 capability 裁剪，避免全字段笛卡尔积；所有 exclusions 有版本化原因。 | I/P：大配置下覆盖内存可控。 |
| AHB-COV-008 | 必须统计实际有效字节吞吐、beat 吞吐、等待、BUSY、IDLE、错误率、接受到完成延迟和端到端排队延迟。 | T：手工短轨迹与统计完全一致；稀疏写按有效字节统计。 |
| AHB-COV-009 | 必须导出机器可读结果，至少含配置指纹、seed、VIP/工具版本、需求覆盖、checker 命中和未完成事务。 | I：相同 seed 与版本可复现定位。 |

## 16. UVM 集成、RAL 与可用性

| ID | 需求 | 验收 |
|---|---|---|
| AHB-UVM-001 | 必须支持 UVM 1.2；IEEE 1800.2/UVM 实现兼容性作为单独构建配置验证，不能仅改版本字符串。 | T/I：两套配置分别构建并运行核心回归。 |
| AHB-UVM-002 | 必须符合 factory/config_db/sequence/analysis port 常规集成方式，实例路径不硬编码。 | T：factory override 和重命名 env 均正常。 |
| AHB-UVM-003 | 必须提供 agent config、env config、virtual sequence 示例和最小可运行工程；不依赖私有 DUT 层次。 | T：新目录按指南可启动 smoke。 |
| AHB-UVM-004 | 必须提供 UVM RAL adapter 与 passive predictor，支持成功/错误状态、端序、窄访问及配置的 byte-enable 能力。 | T：frontdoor 访问、错误映射和 mirror 更新。 |
| AHB-UVM-005 | 不支持 HWSTRB 的配置不得把任意稀疏 RAL byte enable 直接映射为一笔总线写；可拆合法访问或拒绝，RMW 必须显式授权设备语义。 | T/N：读清寄存器不能被隐式 RMW。 |
| AHB-UVM-006 | predictor 必须只依据可确认的数据与设备语义更新；ERROR、reset abort、失败 exclusive 不得盲目更新 mirror。 | T：错误和副作用寄存器回归。 |
| AHB-UVM-007 | 多实例、并行 sequence、reset 和 sequence kill 必须无 objection 泄漏、无响应丢失、无队列死锁。 | T：压力及中断用例全部可收敛。 |
| AHB-UVM-008 | 必须提供可扩展的约束随机序列库：基础、burst、等待、错误、reset、lock、exclusive、安全、USER、strobe、parity、经典仲裁。 | T/I：每序列有适用配置和复现实例。 |
| AHB-UVM-009 | 必须提供 FuseSoC core、依赖/编译顺序、smoke/regression target 和命令说明；不得含用户机器绝对路径。 | T：干净工作区调用 core 运行。 |
| AHB-UVM-010 | 必须以 YAML 维护 profile/capability/回归清单并校验 schema；日志中的配置指纹与实际展开配置一致。 | I/T：配置往返和非法输入检查。 |

## 17. 非功能、可移植性与质量要求

| ID | 需求 | 验收 |
|---|---|---|
| AHB-NFR-001 | 必须在 VCS 完成发布验收；至少另一款支持所需 UVM/SVA 的商业仿真器完成兼容回归。未运行的工具标未验证。 | T/I：保存实际版本、命令、日志；不宣称全工具支持。 |
| AHB-NFR-002 | 关键协议行为不能依赖厂商专有 DPI/加密库；可选性能扩展必须有等价可运行路径。 | I/T：关闭扩展可运行核心用例。 |
| AHB-NFR-003 | 必须避免 TB 与 DUT 采样/驱动竞态，明确 clocking block/skew 和 NBA 关系。 | T：边沿敏感场景在两款工具结果一致。 |
| AHB-NFR-004 | 相同配置、seed、工具版本和执行模式必须复现总线事务轨迹；不同并发调度下的不可保证项应说明。 | T：轨迹 hash/事件序列比较。 |
| AHB-NFR-005 | trace 关闭且历史缓存有界时，持续传输不得使事务历史无界增长；百万 beat 压测应排除 memory 内容正常增长后检查泄漏。 | P：报告 RSS、队列高水位和完成计数。 |
| AHB-NFR-006 | 发布必须测量 driver-only、monitor、checker、coverage、trace 各模式的仿真吞吐和内存，不设脱离机器/工具的绝对速度承诺。 | P：固定参考环境形成基线，后续同环境退化超过 20% 需解释。 |
| AHB-NFR-007 | 协议状态机、地址/lane、parity 和 reservation 模型必须有独立单元测试；不能以字段 getter 测试数量替代行为验证。 | T：针对回绕、流水推进、失败写和状态失效的边界测试。 |
| AHB-NFR-008 | 必须完成编译告警审查、代码静态检查和公开 API 文档检查；lint 工具名称与适用范围按实际工具填写。 | I：无未解释高严重度告警。 |

## 18. 最低验收场景矩阵

本节提供验证方案的下限。Suite 应据需求进一步拆解 Feature、TC、Checker、Coverage，不能仅把此表复制成最终验证方案。

| 场景族 | 必须覆盖 | 主要需求族 |
|---|---|---|
| BASIC | 所有合法 HSIZE、所有 lane、连续读写、0/1/多等待 | BAS/BST |
| PIPELINE | A 数据等待时 B 地址出现、读写切换、多目标响应归属 | CFG/BAS |
| BURST | 全部 burst、WRAP 全起点、BUSY 合法转换、1KB 边界 | BST |
| ERROR | 首/中/末拍、前置等待、流水取消/继续、错误后恢复 | RSP |
| RESET | 地址/写数据/读数据/等待/ERROR 中复位、队列和 RAL 收敛 | RST/UVM |
| LOCK | 竞争者存在/不存在、等待、错误、释放和交接 | LCK/LEG |
| SECURE | 安全域×权限×读写×目标区域，属性透传 | SEC |
| EXCLUSIVE | 成功、各种失配、干扰写、容量替换、reset、多身份 | EXC |
| STROBE | 全零/稀疏/全一、非活动 lane 任意值、端序、等待 | STR/BST |
| USER | 四种 USER 阶段、不同宽度、关闭、错误和等待 | USR |
| PARITY | 每个保护组、尾组、有效/无效窗口、单/多 bit 错误 | PAR |
| CLASSIC | 仲裁交接、锁、RETRY、SPLIT/HSPLIT、默认 Master | LEG |
| SYSTEM | 多实例互联、宽度/地址转换、错误传播、模型共享 | SCP/MEM |
| NEGATIVE | 每条 checker 正例、反例、豁免、expected-error 精确匹配 | CHK/NEG |
| RAL | 字节访问、错误、端序、byte enable、副作用寄存器 | UVM/MEM |
| STRESS | 百万 beat、有界资源、长等待、并发 sequence、停止/恢复 | NFR/RST |

### 18.1 必须具备的独立周期向量

1. 两笔 back-to-back 写，写数据与后一笔地址不同，证明数据阶段关联正确。
2. 当前写等待三拍，下一地址为读，证明 monitor 不重复采纳地址。
3. 固定 burst 等待中的 BUSY→SEQ，证明 checker 无误报。
4. INCR 等待中的 BUSY→NONSEQ，证明旧 burst 正确终止且新请求只接受一次。
5. ERROR 两周期取消流水候选，证明未接受请求不会更新数据模型。
6. WRAP4 起点不在窗口基址，证明地址回绕正确。
7. 窄写的非活动 lane strobe 为一，证明只更新有效活动字节。
8. 全零 strobe 写正常完成，证明完成数增加、字节写入数不增加。
9. exclusive 总线 OKAY、排他失败，证明没有错误地写入支持排他的目标。
10. 地址阶段与数据阶段不同目标/不同 Master，证明响应按数据阶段归属。
11. 复位在等待中发生，证明 API 返回 abort 且没有历史残留完成。
12. 非整字节地址/USER 宽度的 parity 尾组，证明分组和有效性正确。

## 19. 发布门禁与交付物

| ID | 需求 | 验收 |
|---|---|---|
| AHB-ACC-001 | 每个发布剖面所有适用需求必须有实现映射和验证证据；未实现、未运行、未覆盖、不可观察不得标 PASS。 | I：逐 ID RTM 无空洞。 |
| AHB-ACC-002 | 必须通过全部定向测试；每个主要配置至少 100 个固定种子，总计不少于 100 万个有效 beat。关键扩展除组合测试外有隔离测试。 | T：可复现清单与结果；数值为项目验收门槛，不是协议规定。 |
| AHB-ACC-003 | 强制功能 bins 和关键交叉在排除已批准不可达项后达到 100%；各排除项包含理由和受影响需求。 | C/I：不能只报告一个未经解释的总覆盖率。 |
| AHB-ACC-004 | 每条发布 checker 必须至少一条合法无误报轨迹和一条目标违规检出轨迹；合法但非典型行为有独立回归。 | T/N：checker 自身有检出与误报证据。 |
| AHB-ACC-005 | 必须对地址增量、流水关联、ERROR 时序、byte mask、exclusive 失效、parity 分组至少各做一类人工变异测试。 | N：预期测试能抓住人为缺陷。 |
| AHB-ACC-006 | 所有主要接口参数取最小、默认、最大值，并对 feature dependency 做组合覆盖；不要求穷举无意义全组合。 | T/I：明确 pairwise 及关键高阶组合清单。 |
| AHB-ACC-007 | 声明兼容旧版或经典剖面前，必须完成对应规范全文核对、差异规则表及回归，不能复用 Issue C 标志冒充旧版验证。 | I/T：S2/S3 审查记录与适用性清单齐全。 |
| AHB-ACC-008 | 最终交付必须包括需求、架构、验证方案、RTM、用户指南、源码、示例、打包文件、回归清单、测试报告和已知限制。 | I：在干净工作区复现发布 smoke 与代表性回归。 |

建议交付文件：

```text
docs/requirement.md
docs/architecture.md
docs/validation_plan.md
docs/rtm.md
docs/user_guide.md
docs/protocol_rule_matrix.md
docs/release_notes.md
src/                   # interface、transaction、agent、checker、coverage、model、RAL
sequences/
examples/
tests/                 # 单元、周期向量、集成、checker negative、regression
config/                # YAML profiles/capabilities
ahb.core
```

目录为建议，不强制 Suite 改变已有工程组织；交付内容与可追踪性是强制要求。

## 20. 架构提示（非规范性）

建议用共享事务层、地址/数据阶段跟踪层和剖面规则层组织代码。Manager 与 Subordinate 的 driver 可以共享类型和纯计算工具，但 monitor 的事务重建必须来自总线观测。Checker 规则库按 `protocol_profile + spec_issue + capability` 选择；经典仲裁可独立子包，避免污染 Lite/AHB5 基础状态机。

地址、byte-lane、burst、parity 是适合独立单元测试的纯计算模型；exclusive reservation、数据副作用和互联关联则适合状态模型。Subordinate response policy 与 memory/device backend 应可替换，避免为了特殊 DUT 改核心协议逻辑。

建议分四个开发里程碑：

| 里程碑 | 内容 | 对外状态 |
|---|---|---|
| M1 | Lite 基础、全部 burst、wait/error/reset、monitor/checker/coverage/RAL | Lite 候选版 |
| M2 | AHB5 安全属性、扩展 HPROT、Exclusive 与多实例系统验证 | AHB5 基础候选版 |
| M3 | Issue C strobe/USER/parity、宽度参数与完整负向回归 | Issue C 完整候选版 |
| M4 | 经典仲裁/SPLIT/RETRY、跨工具回归与全部门禁 | 本规格全范围 V1.0 |

开发顺序可以调整，但如果仅完成 M1，发布说明只能声称已验收相应 Lite 能力。

## 21. 用于 VIP Development Suite 的检查重点

本节是使用本规格进行 Suite 测试的方法，不增加 AHB 协议规则。

| 检查项 | 合格产物应体现 |
|---|---|
| 需求拆解 | 章节适用条件正确继承，复杂条目进一步分解，ID 不丢失 |
| 协议事实 | Lite/AHB5/经典 AHB 分开；Issue C 特性不遗漏 |
| 架构质量 | 数据阶段与地址阶段分离；monitor 不依赖 driver 内部状态 |
| Checker 质量 | 合法例外有正向测试，负向测试有规则级预期 |
| 模型质量 | byte mask、错误写副作用、exclusive reservation 与系统可见性明确 |
| 覆盖质量 | 能力裁剪、有效分母、正负向覆盖分开 |
| 工程质量 | 干净构建、参数边界、跨工具证据、seed 可复现 |
| 状态诚实性 | 未实现/未运行/不可观察清楚标记，不凭文档完整宣称 G0 或 V1.0 PASS |

最需要防止的生成错误：把 AHB 当成无流水握手总线；把等待期间所有变化都判违规；把 ERROR 当一拍；把软件请求队列当总线 outstanding；把经典 SPLIT/RETRY 加到 Lite；遗漏 HBUSER 与完整 CHK；照搬 AXI strobe 或 exclusive 规则；用同一份错误算法在 driver/monitor/scoreboard 中互相“验证通过”。
