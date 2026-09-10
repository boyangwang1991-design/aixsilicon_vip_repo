# AHB validation plan
# 1. Purpose
Validate actual bus behavior independently of producer logic. Contract scope remains all 169 requirements.
# 2. Validation Objectives
Every released rule has positive and exact negative evidence; no false completion, duplicate write, lost abort, or inactive-lane corruption.
# 3. Validation Scope
Lite/AHB5/Classic are distinct. Development full target is only the currently implemented test executable set; it is not contract full acceptance.
# 4. Validation Strategy
L1 pure golden arithmetic, memory, policy, configuration and transactions. L2 standalone bus vectors with handwritten expected addresses/data. L3 independent checker injections. L4 active agents against observations. L5 multi-instance/system. L6 stress. L7 cross-tool qualification.
# 8. Smoke Validation
32 unique back-to-back writes followed by 32 reads, exact data checks, 64 completions, 32 memory commits. Run wait=0,1,3,15,256. No UVM errors/fatals or missing completion oracle allowed.
# 13. Monitor Validation
V01 two different address/data writes; V02 three waits then read; V03 fixed BUSY→SEQ; V04 INCR BUSY→NONSEQ; V05 two-cycle ERROR candidate cancellation; V06 non-base WRAP4; V11 reset abort. V07/08 strobe and V09 exclusive in model/extension tests; V10 ownership and V12 parity require separate vectors beyond existing end-to-end coverage.
# 17. Protocol Checker Validation
negative.f uses explicit sampled cycles with exact rule ID, cycle and count. Every unrelated diagnostic causes failure. Legal baseline checks unknown inactive data and IDLE address changes. Positive signal-level vectors exercise exception paths.
# 19. Violation / Mutation Validation
The following source mutations are required independently of signal fault injection; each uses a fresh copied workspace and expected failing oracle.

| Mutation | Injected change | Expected test | Priority |
| --- | --- | --- | --- |
| MUT-ADDR | increment by twice beat size | unit wrap/address golden | P0 |
| MUT-PIPE | monitor associates next address with prior data | vectors V01 | P0 |
| MUT-ERROR | suppress first ERROR cycle requirement | negative two-cycle oracle | P0 |
| MUT-MASK | commit inactive strobe lanes | unit inactive_strobe | P0 |
| MUT-EXCL | skip reservation invalidation | unit granule_invalidation | P0 |
| MUT-PARITY | invert generated parity | unit parity_tail10/17 | P0 |

# 26. Configuration Validation
Parameter edge matrix AW10/17/33/64, DW8..1024, zero/nonzero optional widths, extension dependency rejection. Mixed 32-bit Lite and 128-bit AHB5 in the same simulation. Seeded YAML configuration must match actual elaborated component settings.
# 31. RAL Validation
Frontdoor byte/full reads/writes, endian lanes, failed response, abort and exclusive exclusion; unsupported sparse mask rejected before drive; no implicit RMW.
# 32. Coverage Model Validation
Record explicit bin IDs with counts, separate normal/error/abort/injection. Merge only compatible profile definitions; derive union by IDs. Mandatory denominators are frozen from applicable capabilities, not observed hits.
# 37. Regression Strategy
Required tiers (full): unit, vectors, smoke, negative, extensions, burst, error, reset, ral, classic, system, mutation, stress, portability.
Contract acceptance requires 100 seeds per major configuration and one million completed valid beats. No missing tier can be silently removed. Development run.py full executes implemented baseline tiers only.
# 39. Simulator Validation
VCS/UVM1.2 primary. Another commercial simulator and IEEE1800.2 implementation separately compiled/run; absent tools are NOT_RUN.
# 40. Build / Packaging Validation
Compile packages in dependency order and include class bodies exactly once. Fresh build uses self_test/Makefile and FuseSoC smoke/regression targets. Require process success plus positive oracle plus zero unexpected errors/fatals.
# 41. Metadata Validation
config/profiles.yaml and requirements.yaml validate types, ranges, dependencies and authoritative ID set; run fingerprint includes actual elaboration inputs and source version.
# 48. Validation Test Naming
Executable tier and test ID appear in logs and machine summaries. Fixed random seed passed to simulator.
# 49. Validation Case Template
Each case has requirement IDs, applicability, trigger, expected cycle/event/data, exact error expectation and command/log. NOT_RUN stays in required denominator.
# 50. Validation Matrix

- AHB-SCP-001 — T/I：三种角色分别运行；Passive 对所有总线信号零驱动。
- AHB-SCP-002 — I/N：非法组合在 run 前失败并指出冲突字段。
- AHB-SCP-003 — T：分别验证寻址、响应路由和并发竞争。
- AHB-SCP-004 — T：至少四 Manager、四 Subordinate，停顿互不串扰。
- AHB-SCP-005 — T/N：合法但不支持的请求可发送，并验证 DUT 指定错误策略。
- AHB-SCP-006 — I/N：配置、日志与测试清单一致。
- AHB-SCP-007 — I：用户指南给出可观察性边界。
- AHB-CFG-001 — I/T：合法参数编译、各角色接入参考 DUT。
- AHB-CFG-002 — I：按角色信号矩阵核对方向、宽度、presence。
- AHB-CFG-003 — T/N：A 等待时地址切换至 B，A 的数据响应仍归 A。
- AHB-CFG-004 — T/N：所有启停组合和缺失信号配置检查。
- AHB-CFG-005 — I/T：对照接口矩阵、宽度边界和零宽度配置。
- AHB-CFG-006 — I/T：全关闭扩展配置可编译、运行。
- AHB-CFG-007 — N：每类冲突至少一个反例。
- AHB-CFG-008 — T：等待期间更改配置不污染正在执行的 beat。
- AHB-CFG-009 — N/T：重叠、空洞、边界及优先级。
- AHB-CFG-010 — T：32-bit Lite 与 128-bit AHB5 混合运行。
- AHB-TRN-001 — T：逐周期参考轨迹与事件一一对齐。
- AHB-TRN-002 — I/T：序列 API 可直接表达各类请求。
- AHB-TRN-003 — N：禁用特性字段不得被静默忽略。
- AHB-TRN-004 — T：错误位于首/中/末 beat 时结果精确。
- AHB-TRN-005 — T：上层调用能无歧义处理每个结果。
- AHB-TRN-006 — T：ERROR、复位和撤销场景无重复或伪事务。
- AHB-TRN-007 — T：同一场景可由高级 API 和 beat API 等价执行。
- AHB-TRN-008 — I/T：回调不会绕过 monitor，无法事后篡改已发布事务。
- AHB-TRN-009 — T：复制后修改原事务不会影响已发布记录。
- AHB-TRN-010 — I/T：长软件队列仍按接口实际顺序完成。
- AHB-BAS-001 — T/C：方向×宽度×合法 HSIZE。
- AHB-BAS-002 — T：读写交替、不同地址连续访问不串拍。
- AHB-BAS-003 — P/T：连续 256 beat，填充/排空之外无 VIP 引入气泡。
- AHB-BAS-004 — T：未选中、IDLE、BUSY 和 HREADY 低时不产生新有效 beat。
- AHB-BAS-005 — T：每拍不同 HSIZE/方向/目标，随机停顿，逐字节比对。
- AHB-BAS-006 — T/A：检查 memory callback 次数与有效 beat 数相等。
- AHB-BAS-007 — T/N/A：合法变化零误报，违反有效阶段保持规则必报。
- AHB-BAS-008 — T/N：非有效读周期随机变化不误报；有效拍损坏可检出。
- AHB-BAS-009 — T/C：四种切换×0/1/多等待。
- AHB-BAS-010 — T：关闭 watchdog 可持续等待；开启后按指定原因终止测试。
- AHB-BST-001 — T/C：全部 HBURST×读写。
- AHB-BST-002 — T：1、2、3、17、256、1024 beat，必要时分割合法边界。
- AHB-BST-003 — T/N：每个 wrap 起点偏移及错误回绕地址。
- AHB-BST-004 — T/N：边界前最后合法传输及故意跨界。
- AHB-BST-005 — T：拆分后数据、地址和字节数守恒。
- AHB-BST-006 — T/N：首个有效拍之后、内部、尾部边界，合法与非法对照。
- AHB-BST-007 — T/A：明确终止原因后重新 NONSEQ 启动。
- AHB-BST-008 — T：互联两侧轨迹不同仍能正确比对。
- AHB-BST-009 — T：每个合法 lane、HSIZE、多宽度读回。
- AHB-BST-010 — T/N：无效 lane 随机/X 不误报；有效 lane X 可诊断。
- AHB-BST-011 — T/N：raw 非对齐被识别，高层拆分可读回。
- AHB-RSP-001 — T/C：等待 0、1、2、15、256 和随机长尾。
- AHB-RSP-002 — T/N/A：正确、缺少首周期、缺少完成周期均有测试。
- AHB-RSP-003 — T：0/1/多前置等待，错误只完成一次。
- AHB-RSP-004 — T：错误首/中/末拍，两策略下记录无丢失、无重复。
- AHB-RSP-005 — T：每种触发命中精确，固定 seed 可复现。
- AHB-RSP-006 — T：默认策略与设备回调策略分别验证。
- AHB-RSP-007 — T：空洞访问、空闲与 BUSY。
- AHB-RSP-008 — T：后续 100 个正确访问全部匹配。
- AHB-LCK-001 — T/C：有锁/无锁×读写×等待/错误。
- AHB-LCK-002 — T：有/无竞争及可见性不足的报告。
- AHB-LCK-003 — I/N：不会用 HEXCL 替代 HMASTLOCK。
- AHB-LEG-001 — I/T：对照 S3 接口及系统拓扑审查。
- AHB-LEG-002 — T/N：grant 变化与真正获得总线不得混同。
- AHB-LEG-003 — T：不同 Master 数据模式、等待及 back-to-back 交接。
- AHB-LEG-004 — T：竞争、无竞争、持续请求、优先级变化。
- AHB-LEG-005 — T/N：合法两周期非 OKAY 响应与损坏时序对照。
- AHB-LEG-006 — T：单次及多次 RETRY 后成功，无重复提交。
- AHB-LEG-007 — T：释放前不能错误重新授权，释放后可恢复。
- AHB-LEG-008 — T：无限重试场景可诊断结束。
- AHB-LEG-009 — T/A：逐场景对照已核对 S3 条款。
- AHB-LEG-010 — T/I：公平与非公平策略分别验收。
- AHB-SEC-001 — T/C：Secure/Non-secure×读写×等待/ERROR。
- AHB-SEC-002 — T：允许/拒绝矩阵与预期一致。
- AHB-SEC-003 — T：同址跨安全域读写及排他干扰。
- AHB-SEC-004 — I/T：合法编码表、非法组合、属性传播。
- AHB-SEC-005 — T/N：合法但禁止的访问与非法编码有不同诊断。
- AHB-SEC-006 — T：属性丢失或错误改写可检出。
- AHB-ATM-001 — I/N：不兼容配置可诊断。
- AHB-ATM-002 — T：完整可见与不完整可见环境分别报告。
- AHB-EXC-001 — T：总线成功但排他失败、排他成功、总线错误。
- AHB-EXC-002 — I/T：模型配置与 DUT reservation 合同一致。
- AHB-EXC-003 — T/C：每种失配单独观察结果。
- AHB-EXC-004 — T：同粒度冲突和粒度外无冲突。
- AHB-EXC-005 — T：失败前后目标字节及邻近字节比较。
- AHB-EXC-006 — T/N/A：逐限制正反例。
- AHB-EXC-007 — T/N：等待、错误、普通传输中错误拉高。
- AHB-EXC-008 — T：四 Manager，同局部 ID、不同全局身份。
- AHB-EXC-009 — T：复位后旧配对不能误成功。
- AHB-EXC-010 — T：外部干扰通知使结果更新。
- AHB-STR-001 — T/N：下一地址出现时仍使用当前 beat strobe。
- AHB-STR-002 — T：窄传输时非活动 lane 的 strobe 任意变化不改变目标外字节。
- AHB-STR-003 — T/C：各模式×合法 HSIZE×等待。
- AHB-STR-004 — T/N：false-positive 专项验证。
- AHB-STR-005 — T/N：接口兼容矩阵检查。
- AHB-USR-001 — T：每阶段不同模式，流水与等待下不串拍。
- AHB-USR-002 — I/T：两个不同 USER 插件独立工作。
- AHB-USR-003 — T/N：合法变化零误报，非法变化可诊断。
- AHB-USR-004 — I/T：拆分/合并测试匹配明确合同。
- AHB-PAR-001 — I/T：对照 S1 第 12 章及附录 A.2 的完整矩阵。
- AHB-PAR-002 — T：10/17/33/64-bit 地址及 USER 尾组。
- AHB-PAR-003 — N：每个存在的保护组至少一次单 bit 检出。
- AHB-PAR-004 — T：中断、错误响应及仅记录等策略由 DUT 合同选择。
- AHB-PAR-005 — T/N：有效/无效窗口成对注入。
- AHB-PAR-006 — N/I：单 bit 与同组双 bit 注入使用不同预期。
- AHB-MEM-001 — T/P：相距较远的地址写读，存储开销随使用量增长。
- AHB-MEM-002 — T：每策略可重复且未初始化可区分。
- AHB-MEM-003 — T：长等待写与回调计数。
- AHB-MEM-004 — T：至少存储、寄存器副作用、FIFO 三种示例。
- AHB-MEM-005 — T：同周期冲突可重复，exclusive 失效通知完整。
- AHB-MEM-006 — T：多 Manager 同址冲突无仿真竞态。
- AHB-MEM-007 — N：故意丢拍、改数据、错路由能被发现。
- AHB-MEM-008 — T/N：正常转换匹配；丢失、重复、错 lane 可检出。
- AHB-MEM-009 — I/T：protocol-only 模式报告范围。
- AHB-RST-001 — T/I：外部与环境驱动两种接入。
- AHB-RST-002 — T/A：空闲、地址、数据、等待、ERROR、SPLIT 中复位。
- AHB-RST-003 — T：完成与复位相邻边沿有确定结果。
- AHB-RST-004 — T：多请求队列中途 reset。
- AHB-RST-005 — T：warm reset 保持和 cold reset 清除。
- AHB-RST-006 — T：复位后连续访问与 clean start 结果一致。
- AHB-RST-007 — T：各阶段停止，无永久 objection 或挂死。
- AHB-RST-008 — T：无 HCLK 时不会错误累计总线等待周期。
- AHB-CHK-001 — I/T：不实例化 driver 也能发现协议违规。
- AHB-CHK-002 — I：checker registry 无重复 ID、无孤立需求。
- AHB-CHK-003 — T/N/A：每类都有合法/违规轨迹。
- AHB-CHK-004 — T/N：有效和无效周期分别注入 X。
- AHB-CHK-005 — T：同一运行可统计五种分类。
- AHB-CHK-006 — I/T：汇总包含启用、命中、豁免和缺测项。
- AHB-CHK-007 — N：连续违规不会导致无限报错或 monitor 崩溃。
- AHB-CHK-008 — I/T：仅凭日志可定位预设错误。
- AHB-CHK-009 — I/N：注入共同模型可能漏掉的 off-by-one 错误仍可检出。
- AHB-NEG-001 — T：纯合法回归零非预期 checker 报告。
- AHB-NEG-002 — N：每类注入命中对应规则。
- AHB-NEG-003 — N：逐项精确定位，非目标规则关联说明。
- AHB-NEG-004 — N：扩展开启/关闭测试都有明确预期。
- AHB-NEG-005 — N：一次注入结束后检查自动恢复。
- AHB-NEG-006 — N：漏报、多报、错报分别判失败。
- AHB-COV-001 — C/I：每个适用 bin 可追踪需求。
- AHB-COV-002 — C：定向闭合关键边界。
- AHB-COV-003 — C：禁用特性自动剔除相应 bin。
- AHB-COV-004 — C：每项对应经典需求。
- AHB-COV-005 — I/C：非法组合 ignore 并注明原因。
- AHB-COV-006 — T/C：三类报表可分开查看。
- AHB-COV-007 — I/P：大配置下覆盖内存可控。
- AHB-COV-008 — T：手工短轨迹与统计完全一致；稀疏写按有效字节统计。
- AHB-COV-009 — I：相同 seed 与版本可复现定位。
- AHB-UVM-001 — T/I：两套配置分别构建并运行核心回归。
- AHB-UVM-002 — T：factory override 和重命名 env 均正常。
- AHB-UVM-003 — T：新目录按指南可启动 smoke。
- AHB-UVM-004 — T：frontdoor 访问、错误映射和 mirror 更新。
- AHB-UVM-005 — T/N：读清寄存器不能被隐式 RMW。
- AHB-UVM-006 — T：错误和副作用寄存器回归。
- AHB-UVM-007 — T：压力及中断用例全部可收敛。
- AHB-UVM-008 — T/I：每序列有适用配置和复现实例。
- AHB-UVM-009 — T：干净工作区调用 core 运行。
- AHB-UVM-010 — I/T：配置往返和非法输入检查。
- AHB-NFR-001 — T/I：保存实际版本、命令、日志；不宣称全工具支持。
- AHB-NFR-002 — I/T：关闭扩展可运行核心用例。
- AHB-NFR-003 — T：边沿敏感场景在两款工具结果一致。
- AHB-NFR-004 — T：轨迹 hash/事件序列比较。
- AHB-NFR-005 — P：报告 RSS、队列高水位和完成计数。
- AHB-NFR-006 — P：固定参考环境形成基线，后续同环境退化超过 20% 需解释。
- AHB-NFR-007 — T：针对回绕、流水推进、失败写和状态失效的边界测试。
- AHB-NFR-008 — I：无未解释高严重度告警。
- AHB-ACC-001 — I：逐 ID RTM 无空洞。
- AHB-ACC-002 — T：可复现清单与结果；数值为项目验收门槛，不是协议规定。
- AHB-ACC-003 — C/I：不能只报告一个未经解释的总覆盖率。
- AHB-ACC-004 — T/N：checker 自身有检出与误报证据。
- AHB-ACC-005 — N：预期测试能抓住人为缺陷。
- AHB-ACC-006 — T/I：明确 pairwise 及关键高阶组合清单。
- AHB-ACC-007 — I/T：S2/S3 审查记录与适用性清单齐全。
- AHB-ACC-008 — I：在干净工作区复现发布 smoke 与代表性回归。
# 51. Requirement Coverage Review
Master RTM holds per-ID final state, and test source/log references. Partial supporting tests do not automatically close a compound requirement.
# 52. Exit Criteria
All applicable requirements and mandatory bins 100%; full directed suite; 100 seeds; million beats; six mutation classes; second tool; no unreviewed warnings.
# 53. Validation Evidence
reports/logs and reports/regression hold commands, versions, exit status, oracles, timestamps and source fingerprints.
# 54. Validation Review Checklist
This is a frozen full-contract plan; implemented tests do not redefine its denominator. Any missing mandatory tier blocks G3/G5.
# 55. Definition of Validation Plan Complete
All original acceptance statements remain linked to executable or explicitly pending tests.
