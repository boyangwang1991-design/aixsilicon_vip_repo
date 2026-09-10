# AHB VIP requirement traceability — 0.1.0 development candidate

# 1. Purpose
逐条保留原合同169个ID，区分开发用例通过与完整验收。

# 2. Principles
同一条复合需求只有全部验收满足才PASS；未实现为FAIL，已具备部分实现但验收不足为NOT_RUN。

# 3. Inputs
`contract.md`、`../config/requirements.yaml`、`architecture.md`、`validation-plan.md`。

# 4. Model
需求 → 组件 → 检查/测试 → 原始日志。test witness 仅表示相关证据，不表示整个需求通过。

# 5. Status
PASS/FAIL/NOT_RUN；本次无WAIVED。

# 6. Priority
合同全部为发布P0；0.1.0不是已认证1.0.0。

# 7. Master RTM
下表是逐ID状态唯一权威表；完整原文和验收条件见 `contract.md`。

| Requirement | Implementation | Test witness / Checker | Coverage | Result | Evidence / remaining gap |
| --- | --- | --- | --- | --- | --- |
| AHB-SCP-001 | src/agent/ahb_agent.sv | system, extensions | reports/coverage/coverage_summary.yaml | NOT_RUN | 双方Active已运行，Passive monitor已运行；完整Passive agent角色接入仍需专用用例 |
| AHB-SCP-002 | src/agent/ahb_agent.sv | system, extensions | reports/coverage/coverage_summary.yaml | NOT_RUN | capability 导出及全拓扑竞争验收尚未完成 |
| AHB-SCP-003 | src/agent/ahb_agent.sv | system, extensions | reports/coverage/coverage_summary.yaml | NOT_RUN | capability 导出及全拓扑竞争验收尚未完成 |
| AHB-SCP-004 | src/agent/ahb_agent.sv | system, extensions | reports/coverage/coverage_summary.yaml | PASS | system 四 Manager/四共享目标，不同等待与地址区域读回 |
| AHB-SCP-005 | src/agent/ahb_agent.sv | system, extensions | reports/coverage/coverage_summary.yaml | NOT_RUN | capability 导出及全拓扑竞争验收尚未完成 |
| AHB-SCP-006 | src/agent/ahb_agent.sv | system, extensions | reports/coverage/coverage_summary.yaml | NOT_RUN | capability 导出及全拓扑竞争验收尚未完成 |
| AHB-SCP-007 | src/agent/ahb_agent.sv | system, extensions | reports/coverage/coverage_summary.yaml | PASS | user-guide 明确 CDC/一致性/系统原子性可见范围 |
| AHB-CFG-001 | src/ahb_if.sv; src/ahb_config.sv | widths, extensions, unit | reports/coverage/coverage_summary.yaml | NOT_RUN | 结构配置冻结、每类非法组合与运行时快照测试不完整 |
| AHB-CFG-002 | src/ahb_if.sv; src/ahb_config.sv | widths, extensions, unit | reports/coverage/coverage_summary.yaml | NOT_RUN | 结构配置冻结、每类非法组合与运行时快照测试不完整 |
| AHB-CFG-003 | src/ahb_if.sv; src/ahb_config.sv | widths, extensions, unit | reports/coverage/coverage_summary.yaml | PASS | system 按寄存的数据阶段目标选择响应；vectors V02 |
| AHB-CFG-004 | src/ahb_if.sv; src/ahb_config.sv | widths, extensions, unit | reports/coverage/coverage_summary.yaml | NOT_RUN | 结构配置冻结、每类非法组合与运行时快照测试不完整 |
| AHB-CFG-005 | src/ahb_if.sv; src/ahb_config.sv | widths, extensions, unit | reports/coverage/coverage_summary.yaml | NOT_RUN | 结构配置冻结、每类非法组合与运行时快照测试不完整 |
| AHB-CFG-006 | src/ahb_if.sv; src/ahb_config.sv | widths, extensions, unit | reports/coverage/coverage_summary.yaml | NOT_RUN | 零宽编译/运行通过；完整capability覆盖裁剪尚缺 |
| AHB-CFG-007 | src/ahb_if.sv; src/ahb_config.sv | widths, extensions, unit | reports/coverage/coverage_summary.yaml | NOT_RUN | structural freeze已实现并有三项unit断言；每类非法依赖组合测试尚未齐全 |
| AHB-CFG-008 | src/ahb_if.sv; src/ahb_config.sv | widths, extensions, unit | reports/coverage/coverage_summary.yaml | NOT_RUN | 结构配置冻结、每类非法组合与运行时快照测试不完整 |
| AHB-CFG-009 | src/ahb_if.sv; src/ahb_config.sv | widths, extensions, unit | reports/coverage/coverage_summary.yaml | NOT_RUN | 结构配置冻结、每类非法组合与运行时快照测试不完整 |
| AHB-CFG-010 | src/ahb_if.sv; src/ahb_config.sv | widths, extensions, unit | reports/coverage/coverage_summary.yaml | PASS | extensions 同仿真 Lite32/AHB5_128 |
| AHB-TRN-001 | src/transaction/ahb_item.sv; src/sequences/ahb_base_seq.sv | unit, vectors, reset | reports/coverage/coverage_summary.yaml | NOT_RUN | 完整回调链、BUSY/IDLE 计划及取消 API 尚缺 |
| AHB-TRN-002 | src/transaction/ahb_item.sv; src/sequences/ahb_base_seq.sv | unit, vectors, reset | reports/coverage/coverage_summary.yaml | FAIL | 完整回调链、BUSY/IDLE 计划及取消 API 尚缺 |
| AHB-TRN-003 | src/transaction/ahb_item.sv; src/sequences/ahb_base_seq.sv | unit, vectors, reset | reports/coverage/coverage_summary.yaml | NOT_RUN | 完整回调链、BUSY/IDLE 计划及取消 API 尚缺 |
| AHB-TRN-004 | src/transaction/ahb_item.sv; src/sequences/ahb_base_seq.sv | unit, vectors, reset | reports/coverage/coverage_summary.yaml | NOT_RUN | 完整回调链、BUSY/IDLE 计划及取消 API 尚缺 |
| AHB-TRN-005 | src/transaction/ahb_item.sv; src/sequences/ahb_base_seq.sv | unit, vectors, reset | reports/coverage/coverage_summary.yaml | NOT_RUN | 完整回调链、BUSY/IDLE 计划及取消 API 尚缺 |
| AHB-TRN-006 | src/transaction/ahb_item.sv; src/sequences/ahb_base_seq.sv | unit, vectors, reset | reports/coverage/coverage_summary.yaml | NOT_RUN | 完整回调链、BUSY/IDLE 计划及取消 API 尚缺 |
| AHB-TRN-007 | src/transaction/ahb_item.sv; src/sequences/ahb_base_seq.sv | unit, vectors, reset | reports/coverage/coverage_summary.yaml | NOT_RUN | 完整回调链、BUSY/IDLE 计划及取消 API 尚缺 |
| AHB-TRN-008 | src/transaction/ahb_item.sv; src/sequences/ahb_base_seq.sv | unit, vectors, reset | reports/coverage/coverage_summary.yaml | FAIL | 完整回调链、BUSY/IDLE 计划及取消 API 尚缺 |
| AHB-TRN-009 | src/transaction/ahb_item.sv; src/sequences/ahb_base_seq.sv | unit, vectors, reset | reports/coverage/coverage_summary.yaml | NOT_RUN | 完整回调链、BUSY/IDLE 计划及取消 API 尚缺 |
| AHB-TRN-010 | src/transaction/ahb_item.sv; src/sequences/ahb_base_seq.sv | unit, vectors, reset | reports/coverage/coverage_summary.yaml | NOT_RUN | 完整回调链、BUSY/IDLE 计划及取消 API 尚缺 |
| AHB-BAS-001 | src/agent/ahb_driver.sv; src/agent/ahb_monitor.sv | vectors, smoke, system | reports/coverage/coverage_summary.yaml | NOT_RUN | 全宽度/HSIZE、256拍无气泡及转移交叉未闭合 |
| AHB-BAS-002 | src/agent/ahb_driver.sv; src/agent/ahb_monitor.sv | vectors, smoke, system | reports/coverage/coverage_summary.yaml | NOT_RUN | 全宽度/HSIZE、256拍无气泡及转移交叉未闭合 |
| AHB-BAS-003 | src/agent/ahb_driver.sv; src/agent/ahb_monitor.sv | vectors, smoke, system | reports/coverage/coverage_summary.yaml | PASS | smoke 256个连续写，逐完成周期断言无气泡；另256读回匹配 |
| AHB-BAS-004 | src/agent/ahb_driver.sv; src/agent/ahb_monitor.sv | vectors, smoke, system | reports/coverage/coverage_summary.yaml | NOT_RUN | 全宽度/HSIZE、256拍无气泡及转移交叉未闭合 |
| AHB-BAS-005 | src/agent/ahb_driver.sv; src/agent/ahb_monitor.sv | vectors, smoke, system | reports/coverage/coverage_summary.yaml | NOT_RUN | 全宽度/HSIZE、256拍无气泡及转移交叉未闭合 |
| AHB-BAS-006 | src/agent/ahb_driver.sv; src/agent/ahb_monitor.sv | vectors, smoke, system | reports/coverage/coverage_summary.yaml | NOT_RUN | 全宽度/HSIZE、256拍无气泡及转移交叉未闭合 |
| AHB-BAS-007 | src/agent/ahb_driver.sv; src/agent/ahb_monitor.sv | vectors, smoke, system | reports/coverage/coverage_summary.yaml | NOT_RUN | 全宽度/HSIZE、256拍无气泡及转移交叉未闭合 |
| AHB-BAS-008 | src/agent/ahb_driver.sv; src/agent/ahb_monitor.sv | vectors, smoke, system | reports/coverage/coverage_summary.yaml | NOT_RUN | 全宽度/HSIZE、256拍无气泡及转移交叉未闭合 |
| AHB-BAS-009 | src/agent/ahb_driver.sv; src/agent/ahb_monitor.sv | vectors, smoke, system | reports/coverage/coverage_summary.yaml | NOT_RUN | 全宽度/HSIZE、256拍无气泡及转移交叉未闭合 |
| AHB-BAS-010 | src/agent/ahb_driver.sv; src/agent/ahb_monitor.sv | vectors, smoke, system | reports/coverage/coverage_summary.yaml | NOT_RUN | 全宽度/HSIZE、256拍无气泡及转移交叉未闭合 |
| AHB-BST-001 | src/ahb_types_pkg.sv; src/checker/ahb_checker.sv | unit, burst, negative | reports/coverage/coverage_summary.yaml | NOT_RUN | 大块拆分、动态 INCR 与全端序/宽度组合未闭合 |
| AHB-BST-002 | src/ahb_types_pkg.sv; src/checker/ahb_checker.sv | unit, burst, negative | reports/coverage/coverage_summary.yaml | NOT_RUN | 大块拆分、动态 INCR 与全端序/宽度组合未闭合 |
| AHB-BST-003 | src/ahb_types_pkg.sv; src/checker/ahb_checker.sv | unit, burst, negative | reports/coverage/coverage_summary.yaml | PASS | unit 全WRAP起点；negative错误SEQ地址；MUT-ADDR |
| AHB-BST-004 | src/ahb_types_pkg.sv; src/checker/ahb_checker.sv | unit, burst, negative | reports/coverage/coverage_summary.yaml | PASS | negative ALIGN/SIZE/BOUNDARY 正反例 |
| AHB-BST-005 | src/ahb_types_pkg.sv; src/checker/ahb_checker.sv | unit, burst, negative | reports/coverage/coverage_summary.yaml | FAIL | 大块拆分、动态 INCR 与全端序/宽度组合未闭合 |
| AHB-BST-006 | src/ahb_types_pkg.sv; src/checker/ahb_checker.sv | unit, burst, negative | reports/coverage/coverage_summary.yaml | NOT_RUN | 大块拆分、动态 INCR 与全端序/宽度组合未闭合 |
| AHB-BST-007 | src/ahb_types_pkg.sv; src/checker/ahb_checker.sv | unit, burst, negative | reports/coverage/coverage_summary.yaml | NOT_RUN | 大块拆分、动态 INCR 与全端序/宽度组合未闭合 |
| AHB-BST-008 | src/ahb_types_pkg.sv; src/checker/ahb_checker.sv | unit, burst, negative | reports/coverage/coverage_summary.yaml | NOT_RUN | 大块拆分、动态 INCR 与全端序/宽度组合未闭合 |
| AHB-BST-009 | src/ahb_types_pkg.sv; src/checker/ahb_checker.sv | unit, burst, negative | reports/coverage/coverage_summary.yaml | NOT_RUN | 大块拆分、动态 INCR 与全端序/宽度组合未闭合 |
| AHB-BST-010 | src/ahb_types_pkg.sv; src/checker/ahb_checker.sv | unit, burst, negative | reports/coverage/coverage_summary.yaml | NOT_RUN | 大块拆分、动态 INCR 与全端序/宽度组合未闭合 |
| AHB-BST-011 | src/ahb_types_pkg.sv; src/checker/ahb_checker.sv | unit, burst, negative | reports/coverage/coverage_summary.yaml | NOT_RUN | 大块拆分、动态 INCR 与全端序/宽度组合未闭合 |
| AHB-RSP-001 | src/agent/ahb_slave_driver.sv; src/agent/ahb_driver.sv | error, vectors, negative | reports/coverage/coverage_summary.yaml | NOT_RUN | 完整 ERROR 触发维度、burst停止/继续策略未完成 |
| AHB-RSP-002 | src/agent/ahb_slave_driver.sv; src/agent/ahb_driver.sv | error, vectors, negative | reports/coverage/coverage_summary.yaml | NOT_RUN | 完整 ERROR 触发维度、burst停止/继续策略未完成 |
| AHB-RSP-003 | src/agent/ahb_slave_driver.sv; src/agent/ahb_driver.sv | error, vectors, negative | reports/coverage/coverage_summary.yaml | NOT_RUN | 完整 ERROR 触发维度、burst停止/继续策略未完成 |
| AHB-RSP-004 | src/agent/ahb_slave_driver.sv; src/agent/ahb_driver.sv | error, vectors, negative | reports/coverage/coverage_summary.yaml | NOT_RUN | 完整 ERROR 触发维度、burst停止/继续策略未完成 |
| AHB-RSP-005 | src/agent/ahb_slave_driver.sv; src/agent/ahb_driver.sv | error, vectors, negative | reports/coverage/coverage_summary.yaml | FAIL | 完整 ERROR 触发维度、burst停止/继续策略未完成 |
| AHB-RSP-006 | src/agent/ahb_slave_driver.sv; src/agent/ahb_driver.sv | error, vectors, negative | reports/coverage/coverage_summary.yaml | NOT_RUN | 完整 ERROR 触发维度、burst停止/继续策略未完成 |
| AHB-RSP-007 | src/agent/ahb_slave_driver.sv; src/agent/ahb_driver.sv | error, vectors, negative | reports/coverage/coverage_summary.yaml | NOT_RUN | 完整 ERROR 触发维度、burst停止/继续策略未完成 |
| AHB-RSP-008 | src/agent/ahb_slave_driver.sv; src/agent/ahb_driver.sv | error, vectors, negative | reports/coverage/coverage_summary.yaml | NOT_RUN | 完整 ERROR 触发维度、burst停止/继续策略未完成 |
| AHB-LCK-001 | src/classic/ahb_arbiter.sv; src/checker/ahb_checker.sv | classic, negative | reports/coverage/coverage_summary.yaml | NOT_RUN | 系统所有权 lock checker 与竞争场景未闭合 |
| AHB-LCK-002 | src/classic/ahb_arbiter.sv; src/checker/ahb_checker.sv | classic, negative | reports/coverage/coverage_summary.yaml | NOT_RUN | 系统所有权 lock checker 与竞争场景未闭合 |
| AHB-LCK-003 | src/classic/ahb_arbiter.sv; src/checker/ahb_checker.sv | classic, negative | reports/coverage/coverage_summary.yaml | NOT_RUN | 系统所有权 lock checker 与竞争场景未闭合 |
| AHB-LEG-001 | src/classic/ahb_arbiter.sv; src/agent/ahb_driver.sv; src/classic/ahb_classic_model.sv | classic, classic_agent, unit | reports/coverage/coverage_summary.yaml | NOT_RUN | 经典规范全文差异审查、多活动 Master 交接与锁竞争未完成 |
| AHB-LEG-002 | src/classic/ahb_arbiter.sv; src/agent/ahb_driver.sv; src/classic/ahb_classic_model.sv | classic, classic_agent, unit | reports/coverage/coverage_summary.yaml | NOT_RUN | 经典规范全文差异审查、多活动 Master 交接与锁竞争未完成 |
| AHB-LEG-003 | src/classic/ahb_arbiter.sv; src/agent/ahb_driver.sv; src/classic/ahb_classic_model.sv | classic, classic_agent, unit | reports/coverage/coverage_summary.yaml | NOT_RUN | 经典规范全文差异审查、多活动 Master 交接与锁竞争未完成 |
| AHB-LEG-004 | src/classic/ahb_arbiter.sv; src/agent/ahb_driver.sv; src/classic/ahb_classic_model.sv | classic, classic_agent, unit | reports/coverage/coverage_summary.yaml | NOT_RUN | 经典规范全文差异审查、多活动 Master 交接与锁竞争未完成 |
| AHB-LEG-005 | src/classic/ahb_arbiter.sv; src/agent/ahb_driver.sv; src/classic/ahb_classic_model.sv | classic, classic_agent, unit | reports/coverage/coverage_summary.yaml | NOT_RUN | 经典规范全文差异审查、多活动 Master 交接与锁竞争未完成 |
| AHB-LEG-006 | src/classic/ahb_arbiter.sv; src/agent/ahb_driver.sv; src/classic/ahb_classic_model.sv | classic, classic_agent, unit | reports/coverage/coverage_summary.yaml | NOT_RUN | 经典规范全文差异审查、多活动 Master 交接与锁竞争未完成 |
| AHB-LEG-007 | src/classic/ahb_arbiter.sv; src/agent/ahb_driver.sv; src/classic/ahb_classic_model.sv | classic, classic_agent, unit | reports/coverage/coverage_summary.yaml | NOT_RUN | 经典规范全文差异审查、多活动 Master 交接与锁竞争未完成 |
| AHB-LEG-008 | src/classic/ahb_arbiter.sv; src/agent/ahb_driver.sv; src/classic/ahb_classic_model.sv | classic, classic_agent, unit | reports/coverage/coverage_summary.yaml | NOT_RUN | 经典规范全文差异审查、多活动 Master 交接与锁竞争未完成 |
| AHB-LEG-009 | src/classic/ahb_arbiter.sv; src/agent/ahb_driver.sv; src/classic/ahb_classic_model.sv | classic, classic_agent, unit | reports/coverage/coverage_summary.yaml | NOT_RUN | 经典规范全文差异审查、多活动 Master 交接与锁竞争未完成 |
| AHB-LEG-010 | src/classic/ahb_arbiter.sv; src/agent/ahb_driver.sv; src/classic/ahb_classic_model.sv | classic, classic_agent, unit | reports/coverage/coverage_summary.yaml | NOT_RUN | 经典规范全文差异审查、多活动 Master 交接与锁竞争未完成 |
| AHB-SEC-001 | src/model/ahb_devices.sv; src/scoreboard/ahb_bridge_scoreboard.sv | unit, extensions | reports/coverage/coverage_summary.yaml | NOT_RUN | HPROT语义解码及权限/属性变换全矩阵未完成 |
| AHB-SEC-002 | src/model/ahb_devices.sv; src/scoreboard/ahb_bridge_scoreboard.sv | unit, extensions | reports/coverage/coverage_summary.yaml | NOT_RUN | HPROT语义解码及权限/属性变换全矩阵未完成 |
| AHB-SEC-003 | src/model/ahb_devices.sv; src/scoreboard/ahb_bridge_scoreboard.sv | unit, extensions | reports/coverage/coverage_summary.yaml | NOT_RUN | HPROT语义解码及权限/属性变换全矩阵未完成 |
| AHB-SEC-004 | src/model/ahb_devices.sv; src/scoreboard/ahb_bridge_scoreboard.sv | unit, extensions | reports/coverage/coverage_summary.yaml | FAIL | HPROT语义解码及权限/属性变换全矩阵未完成 |
| AHB-SEC-005 | src/model/ahb_devices.sv; src/scoreboard/ahb_bridge_scoreboard.sv | unit, extensions | reports/coverage/coverage_summary.yaml | NOT_RUN | HPROT语义解码及权限/属性变换全矩阵未完成 |
| AHB-SEC-006 | src/model/ahb_devices.sv; src/scoreboard/ahb_bridge_scoreboard.sv | unit, extensions | reports/coverage/coverage_summary.yaml | NOT_RUN | HPROT语义解码及权限/属性变换全矩阵未完成 |
| AHB-ATM-001 | src/ahb_config.sv | 无对应系统验收 | reports/coverage/coverage_summary.yaml | FAIL | 原子属性依赖与系统交错可见性 checker 尚未实现 |
| AHB-ATM-002 | src/ahb_config.sv | 无对应系统验收 | reports/coverage/coverage_summary.yaml | FAIL | 原子属性依赖与系统交错可见性 checker 尚未实现 |
| AHB-EXC-001 | src/model/ahb_memory.sv; src/checker/ahb_checker.sv | unit, extensions, negative | reports/coverage/coverage_summary.yaml | NOT_RUN | 跨四接口身份映射、全部失配原因与可见性通知验收未闭合 |
| AHB-EXC-002 | src/model/ahb_memory.sv; src/checker/ahb_checker.sv | unit, extensions, negative | reports/coverage/coverage_summary.yaml | NOT_RUN | 跨四接口身份映射、全部失配原因与可见性通知验收未闭合 |
| AHB-EXC-003 | src/model/ahb_memory.sv; src/checker/ahb_checker.sv | unit, extensions, negative | reports/coverage/coverage_summary.yaml | NOT_RUN | 跨四接口身份映射、全部失配原因与可见性通知验收未闭合 |
| AHB-EXC-004 | src/model/ahb_memory.sv; src/checker/ahb_checker.sv | unit, extensions, negative | reports/coverage/coverage_summary.yaml | NOT_RUN | 跨四接口身份映射、全部失配原因与可见性通知验收未闭合 |
| AHB-EXC-005 | src/model/ahb_memory.sv; src/checker/ahb_checker.sv | unit, extensions, negative | reports/coverage/coverage_summary.yaml | NOT_RUN | 跨四接口身份映射、全部失配原因与可见性通知验收未闭合 |
| AHB-EXC-006 | src/model/ahb_memory.sv; src/checker/ahb_checker.sv | unit, extensions, negative | reports/coverage/coverage_summary.yaml | NOT_RUN | 跨四接口身份映射、全部失配原因与可见性通知验收未闭合 |
| AHB-EXC-007 | src/model/ahb_memory.sv; src/checker/ahb_checker.sv | unit, extensions, negative | reports/coverage/coverage_summary.yaml | NOT_RUN | 跨四接口身份映射、全部失配原因与可见性通知验收未闭合 |
| AHB-EXC-008 | src/model/ahb_memory.sv; src/checker/ahb_checker.sv | unit, extensions, negative | reports/coverage/coverage_summary.yaml | NOT_RUN | 跨四接口身份映射、全部失配原因与可见性通知验收未闭合 |
| AHB-EXC-009 | src/model/ahb_memory.sv; src/checker/ahb_checker.sv | unit, extensions, negative | reports/coverage/coverage_summary.yaml | NOT_RUN | 跨四接口身份映射、全部失配原因与可见性通知验收未闭合 |
| AHB-EXC-010 | src/model/ahb_memory.sv; src/checker/ahb_checker.sv | unit, extensions, negative | reports/coverage/coverage_summary.yaml | NOT_RUN | 跨四接口身份映射、全部失配原因与可见性通知验收未闭合 |
| AHB-STR-001 | src/model/ahb_memory.sv; src/agent/ahb_monitor.sv | unit, extensions, negative | reports/coverage/coverage_summary.yaml | NOT_RUN | 所有 strobe模式 × HSIZE × 等待未闭合 |
| AHB-STR-002 | src/model/ahb_memory.sv; src/agent/ahb_monitor.sv | unit, extensions, negative | reports/coverage/coverage_summary.yaml | PASS | unit inactive_strobe；MUT-MASK 检出 |
| AHB-STR-003 | src/model/ahb_memory.sv; src/agent/ahb_monitor.sv | unit, extensions, negative | reports/coverage/coverage_summary.yaml | NOT_RUN | 所有 strobe模式 × HSIZE × 等待未闭合 |
| AHB-STR-004 | src/model/ahb_memory.sv; src/agent/ahb_monitor.sv | unit, extensions, negative | reports/coverage/coverage_summary.yaml | NOT_RUN | 所有 strobe模式 × HSIZE × 等待未闭合 |
| AHB-STR-005 | src/model/ahb_memory.sv; src/agent/ahb_monitor.sv | unit, extensions, negative | reports/coverage/coverage_summary.yaml | NOT_RUN | 所有 strobe模式 × HSIZE × 等待未闭合 |
| AHB-USR-001 | src/agent/ahb_monitor.sv; src/scoreboard/ahb_bridge_scoreboard.sv | extensions, negative | reports/coverage/coverage_summary.yaml | NOT_RUN | 可替换 USER 策略与拆分/聚合专用验证尚缺 |
| AHB-USR-002 | src/agent/ahb_monitor.sv; src/scoreboard/ahb_bridge_scoreboard.sv | extensions, negative | reports/coverage/coverage_summary.yaml | NOT_RUN | 可替换 USER 策略与拆分/聚合专用验证尚缺 |
| AHB-USR-003 | src/agent/ahb_monitor.sv; src/scoreboard/ahb_bridge_scoreboard.sv | extensions, negative | reports/coverage/coverage_summary.yaml | NOT_RUN | 可替换 USER 策略与拆分/聚合专用验证尚缺 |
| AHB-USR-004 | src/agent/ahb_monitor.sv; src/scoreboard/ahb_bridge_scoreboard.sv | extensions, negative | reports/coverage/coverage_summary.yaml | NOT_RUN | 可替换 USER 策略与拆分/聚合专用验证尚缺 |
| AHB-PAR-001 | src/checker/ahb_checker.sv; src/ahb_types_pkg.sv | unit, extensions | reports/coverage/coverage_summary.yaml | NOT_RUN | 完整信号级故障 API、所有保护组有效/无效窗口配对验证尚缺 |
| AHB-PAR-002 | src/checker/ahb_checker.sv; src/ahb_types_pkg.sv | unit, extensions | reports/coverage/coverage_summary.yaml | NOT_RUN | 完整信号级故障 API、所有保护组有效/无效窗口配对验证尚缺 |
| AHB-PAR-003 | src/checker/ahb_checker.sv; src/ahb_types_pkg.sv | unit, extensions | reports/coverage/coverage_summary.yaml | NOT_RUN | 完整信号级故障 API、所有保护组有效/无效窗口配对验证尚缺 |
| AHB-PAR-004 | src/checker/ahb_checker.sv; src/ahb_types_pkg.sv | unit, extensions | reports/coverage/coverage_summary.yaml | NOT_RUN | 完整信号级故障 API、所有保护组有效/无效窗口配对验证尚缺 |
| AHB-PAR-005 | src/checker/ahb_checker.sv; src/ahb_types_pkg.sv | unit, extensions | reports/coverage/coverage_summary.yaml | NOT_RUN | 完整信号级故障 API、所有保护组有效/无效窗口配对验证尚缺 |
| AHB-PAR-006 | src/checker/ahb_checker.sv; src/ahb_types_pkg.sv | unit, extensions | reports/coverage/coverage_summary.yaml | PASS | unit 同组双位翻转采用不检出预期；user-guide限制 |
| AHB-MEM-001 | src/model/ahb_memory.sv; src/model/ahb_devices.sv; src/scoreboard/ahb_bridge_scoreboard.sv | unit, smoke, system | reports/coverage/coverage_summary.yaml | NOT_RUN | 同周期同址冲突调度、桥接丢失/重复/转换负测未闭合 |
| AHB-MEM-002 | src/model/ahb_memory.sv; src/model/ahb_devices.sv; src/scoreboard/ahb_bridge_scoreboard.sv | unit, smoke, system | reports/coverage/coverage_summary.yaml | NOT_RUN | 同周期同址冲突调度、桥接丢失/重复/转换负测未闭合 |
| AHB-MEM-003 | src/model/ahb_memory.sv; src/model/ahb_devices.sv; src/scoreboard/ahb_bridge_scoreboard.sv | unit, smoke, system | reports/coverage/coverage_summary.yaml | PASS | smoke WAIT=0写提交计数，system WAIT=1/2/3计数，error失败无提交 |
| AHB-MEM-004 | src/model/ahb_memory.sv; src/model/ahb_devices.sv; src/scoreboard/ahb_bridge_scoreboard.sv | unit, smoke, system | reports/coverage/coverage_summary.yaml | NOT_RUN | 同周期同址冲突调度、桥接丢失/重复/转换负测未闭合 |
| AHB-MEM-005 | src/model/ahb_memory.sv; src/model/ahb_devices.sv; src/scoreboard/ahb_bridge_scoreboard.sv | unit, smoke, system | reports/coverage/coverage_summary.yaml | NOT_RUN | 同周期同址冲突调度、桥接丢失/重复/转换负测未闭合 |
| AHB-MEM-006 | src/model/ahb_memory.sv; src/model/ahb_devices.sv; src/scoreboard/ahb_bridge_scoreboard.sv | unit, smoke, system | reports/coverage/coverage_summary.yaml | FAIL | 同周期同址冲突调度、桥接丢失/重复/转换负测未闭合 |
| AHB-MEM-007 | src/model/ahb_memory.sv; src/model/ahb_devices.sv; src/scoreboard/ahb_bridge_scoreboard.sv | unit, smoke, system | reports/coverage/coverage_summary.yaml | NOT_RUN | 同周期同址冲突调度、桥接丢失/重复/转换负测未闭合 |
| AHB-MEM-008 | src/model/ahb_memory.sv; src/model/ahb_devices.sv; src/scoreboard/ahb_bridge_scoreboard.sv | unit, smoke, system | reports/coverage/coverage_summary.yaml | NOT_RUN | 同周期同址冲突调度、桥接丢失/重复/转换负测未闭合 |
| AHB-MEM-009 | src/model/ahb_memory.sv; src/model/ahb_devices.sv; src/scoreboard/ahb_bridge_scoreboard.sv | unit, smoke, system | reports/coverage/coverage_summary.yaml | PASS | vectors 仅monitor/checker无memory；指南明确范围 |
| AHB-RST-001 | src/agent/ahb_driver.sv; src/agent/ahb_monitor.sv | reset, vectors, classic | reports/coverage/coverage_summary.yaml | NOT_RUN | 重提交、sequence kill、各协议阶段复位矩阵未完成 |
| AHB-RST-002 | src/agent/ahb_driver.sv; src/agent/ahb_monitor.sv | reset, vectors, classic | reports/coverage/coverage_summary.yaml | NOT_RUN | 重提交、sequence kill、各协议阶段复位矩阵未完成 |
| AHB-RST-003 | src/agent/ahb_driver.sv; src/agent/ahb_monitor.sv | reset, vectors, classic | reports/coverage/coverage_summary.yaml | NOT_RUN | 重提交、sequence kill、各协议阶段复位矩阵未完成 |
| AHB-RST-004 | src/agent/ahb_driver.sv; src/agent/ahb_monitor.sv | reset, vectors, classic | reports/coverage/coverage_summary.yaml | NOT_RUN | 重提交、sequence kill、各协议阶段复位矩阵未完成 |
| AHB-RST-005 | src/agent/ahb_driver.sv; src/agent/ahb_monitor.sv | reset, vectors, classic | reports/coverage/coverage_summary.yaml | NOT_RUN | 重提交、sequence kill、各协议阶段复位矩阵未完成 |
| AHB-RST-006 | src/agent/ahb_driver.sv; src/agent/ahb_monitor.sv | reset, vectors, classic | reports/coverage/coverage_summary.yaml | NOT_RUN | 重提交、sequence kill、各协议阶段复位矩阵未完成 |
| AHB-RST-007 | src/agent/ahb_driver.sv; src/agent/ahb_monitor.sv | reset, vectors, classic | reports/coverage/coverage_summary.yaml | NOT_RUN | 重提交、sequence kill、各协议阶段复位矩阵未完成 |
| AHB-RST-008 | src/agent/ahb_driver.sv; src/agent/ahb_monitor.sv | reset, vectors, classic | reports/coverage/coverage_summary.yaml | NOT_RUN | 重提交、sequence kill、各协议阶段复位矩阵未完成 |
| AHB-CHK-001 | src/checker/ahb_checker.sv; src/checker/ahb_violation.sv | negative, unit, vectors | reports/coverage/coverage_summary.yaml | NOT_RUN | 全部规则正反例与完整前后周期诊断窗口尚缺 |
| AHB-CHK-002 | src/checker/ahb_checker.sv; src/checker/ahb_violation.sv | negative, unit, vectors | reports/coverage/coverage_summary.yaml | NOT_RUN | 全部规则正反例与完整前后周期诊断窗口尚缺 |
| AHB-CHK-003 | src/checker/ahb_checker.sv; src/checker/ahb_violation.sv | negative, unit, vectors | reports/coverage/coverage_summary.yaml | NOT_RUN | 全部规则正反例与完整前后周期诊断窗口尚缺 |
| AHB-CHK-004 | src/checker/ahb_checker.sv; src/checker/ahb_violation.sv | negative, unit, vectors | reports/coverage/coverage_summary.yaml | NOT_RUN | 全部规则正反例与完整前后周期诊断窗口尚缺 |
| AHB-CHK-005 | src/checker/ahb_checker.sv; src/checker/ahb_violation.sv | negative, unit, vectors | reports/coverage/coverage_summary.yaml | NOT_RUN | 全部规则正反例与完整前后周期诊断窗口尚缺 |
| AHB-CHK-006 | src/checker/ahb_checker.sv; src/checker/ahb_violation.sv | negative, unit, vectors | reports/coverage/coverage_summary.yaml | NOT_RUN | 全部规则正反例与完整前后周期诊断窗口尚缺 |
| AHB-CHK-007 | src/checker/ahb_checker.sv; src/checker/ahb_violation.sv | negative, unit, vectors | reports/coverage/coverage_summary.yaml | NOT_RUN | 全部规则正反例与完整前后周期诊断窗口尚缺 |
| AHB-CHK-008 | src/checker/ahb_checker.sv; src/checker/ahb_violation.sv | negative, unit, vectors | reports/coverage/coverage_summary.yaml | NOT_RUN | 全部规则正反例与完整前后周期诊断窗口尚缺 |
| AHB-CHK-009 | src/checker/ahb_checker.sv; src/checker/ahb_violation.sv | negative, unit, vectors | reports/coverage/coverage_summary.yaml | NOT_RUN | 全部规则正反例与完整前后周期诊断窗口尚缺 |
| AHB-NEG-001 | self_test/tb/ahb_negative_tb.sv; tools/mutate.py | negative, unit | reports/coverage/coverage_summary.yaml | NOT_RUN | 统一在线故障注入 API 与实例/时间窗口限定匹配尚缺 |
| AHB-NEG-002 | self_test/tb/ahb_negative_tb.sv; tools/mutate.py | negative, unit | reports/coverage/coverage_summary.yaml | NOT_RUN | 统一在线故障注入 API 与实例/时间窗口限定匹配尚缺 |
| AHB-NEG-003 | self_test/tb/ahb_negative_tb.sv; tools/mutate.py | negative, unit | reports/coverage/coverage_summary.yaml | NOT_RUN | 统一在线故障注入 API 与实例/时间窗口限定匹配尚缺 |
| AHB-NEG-004 | self_test/tb/ahb_negative_tb.sv; tools/mutate.py | negative, unit | reports/coverage/coverage_summary.yaml | NOT_RUN | 统一在线故障注入 API 与实例/时间窗口限定匹配尚缺 |
| AHB-NEG-005 | self_test/tb/ahb_negative_tb.sv; tools/mutate.py | negative, unit | reports/coverage/coverage_summary.yaml | NOT_RUN | 统一在线故障注入 API 与实例/时间窗口限定匹配尚缺 |
| AHB-NEG-006 | self_test/tb/ahb_negative_tb.sv; tools/mutate.py | negative, unit | reports/coverage/coverage_summary.yaml | NOT_RUN | 统一在线故障注入 API 与实例/时间窗口限定匹配尚缺 |
| AHB-COV-001 | src/coverage/ahb_coverage.sv | full 回归各实例 AHB_BIN | reports/coverage/coverage_summary.yaml | NOT_RUN | 仅基础 bin 已实现；强制扩展、经典、阶段交叉与完整统计尚缺 |
| AHB-COV-002 | src/coverage/ahb_coverage.sv | full 回归各实例 AHB_BIN | reports/coverage/coverage_summary.yaml | FAIL | 仅基础 bin 已实现；强制扩展、经典、阶段交叉与完整统计尚缺 |
| AHB-COV-003 | src/coverage/ahb_coverage.sv | full 回归各实例 AHB_BIN | reports/coverage/coverage_summary.yaml | FAIL | 仅基础 bin 已实现；强制扩展、经典、阶段交叉与完整统计尚缺 |
| AHB-COV-004 | src/coverage/ahb_coverage.sv | full 回归各实例 AHB_BIN | reports/coverage/coverage_summary.yaml | FAIL | 仅基础 bin 已实现；强制扩展、经典、阶段交叉与完整统计尚缺 |
| AHB-COV-005 | src/coverage/ahb_coverage.sv | full 回归各实例 AHB_BIN | reports/coverage/coverage_summary.yaml | FAIL | 仅基础 bin 已实现；强制扩展、经典、阶段交叉与完整统计尚缺 |
| AHB-COV-006 | src/coverage/ahb_coverage.sv | full 回归各实例 AHB_BIN | reports/coverage/coverage_summary.yaml | NOT_RUN | 仅基础 bin 已实现；强制扩展、经典、阶段交叉与完整统计尚缺 |
| AHB-COV-007 | src/coverage/ahb_coverage.sv | full 回归各实例 AHB_BIN | reports/coverage/coverage_summary.yaml | FAIL | 仅基础 bin 已实现；强制扩展、经典、阶段交叉与完整统计尚缺 |
| AHB-COV-008 | src/coverage/ahb_coverage.sv | full 回归各实例 AHB_BIN | reports/coverage/coverage_summary.yaml | FAIL | 仅基础 bin 已实现；强制扩展、经典、阶段交叉与完整统计尚缺 |
| AHB-COV-009 | src/coverage/ahb_coverage.sv | full 回归各实例 AHB_BIN | reports/coverage/coverage_summary.yaml | NOT_RUN | 仅基础 bin 已实现；强制扩展、经典、阶段交叉与完整统计尚缺 |
| AHB-UVM-001 | src/agent/ahb_agent.sv; src/ral/ahb_ral.sv; aixsilicon_vip_ahb_0.1.0.core | ral, smoke, extensions | reports/coverage/coverage_summary.yaml | NOT_RUN | IEEE1800.2构建、sequence kill和所有场景序列库未完成 |
| AHB-UVM-002 | src/agent/ahb_agent.sv; src/ral/ahb_ral.sv; aixsilicon_vip_ahb_0.1.0.core | ral, smoke, extensions | reports/coverage/coverage_summary.yaml | NOT_RUN | IEEE1800.2构建、sequence kill和所有场景序列库未完成 |
| AHB-UVM-003 | src/agent/ahb_agent.sv; src/ral/ahb_ral.sv; aixsilicon_vip_ahb_0.1.0.core | ral, smoke, extensions | reports/coverage/coverage_summary.yaml | NOT_RUN | IEEE1800.2构建、sequence kill和所有场景序列库未完成 |
| AHB-UVM-004 | src/agent/ahb_agent.sv; src/ral/ahb_ral.sv; aixsilicon_vip_ahb_0.1.0.core | ral, smoke, extensions | reports/coverage/coverage_summary.yaml | NOT_RUN | IEEE1800.2构建、sequence kill和所有场景序列库未完成 |
| AHB-UVM-005 | src/agent/ahb_agent.sv; src/ral/ahb_ral.sv; aixsilicon_vip_ahb_0.1.0.core | ral, smoke, extensions | reports/coverage/coverage_summary.yaml | NOT_RUN | IEEE1800.2构建、sequence kill和所有场景序列库未完成 |
| AHB-UVM-006 | src/agent/ahb_agent.sv; src/ral/ahb_ral.sv; aixsilicon_vip_ahb_0.1.0.core | ral, smoke, extensions | reports/coverage/coverage_summary.yaml | NOT_RUN | IEEE1800.2构建、sequence kill和所有场景序列库未完成 |
| AHB-UVM-007 | src/agent/ahb_agent.sv; src/ral/ahb_ral.sv; aixsilicon_vip_ahb_0.1.0.core | ral, smoke, extensions | reports/coverage/coverage_summary.yaml | NOT_RUN | IEEE1800.2构建、sequence kill和所有场景序列库未完成 |
| AHB-UVM-008 | src/agent/ahb_agent.sv; src/ral/ahb_ral.sv; aixsilicon_vip_ahb_0.1.0.core | ral, smoke, extensions | reports/coverage/coverage_summary.yaml | FAIL | IEEE1800.2构建、sequence kill和所有场景序列库未完成 |
| AHB-UVM-009 | src/agent/ahb_agent.sv; src/ral/ahb_ral.sv; aixsilicon_vip_ahb_0.1.0.core | ral, smoke, extensions | reports/coverage/coverage_summary.yaml | PASS | 实际FuseSoC导出工程smoke通过；core相对路径与显式编译顺序 |
| AHB-UVM-010 | src/agent/ahb_agent.sv; src/ral/ahb_ral.sv; aixsilicon_vip_ahb_0.1.0.core | ral, smoke, extensions | reports/coverage/coverage_summary.yaml | NOT_RUN | IEEE1800.2构建、sequence kill和所有场景序列库未完成 |
| AHB-NFR-001 | tools/run.py; src/agent/ahb_monitor.sv | full, stress | reports/coverage/coverage_summary.yaml | NOT_RUN | 第二商业工具、各模式性能/RSS及调度复现验收未完成 |
| AHB-NFR-002 | tools/run.py; src/agent/ahb_monitor.sv | full, stress | reports/coverage/coverage_summary.yaml | PASS | 源代码无厂商DPI/加密依赖；所有核心回归 |
| AHB-NFR-003 | tools/run.py; src/agent/ahb_monitor.sv | full, stress | reports/coverage/coverage_summary.yaml | NOT_RUN | 第二商业工具、各模式性能/RSS及调度复现验收未完成 |
| AHB-NFR-004 | tools/run.py; src/agent/ahb_monitor.sv | full, stress | reports/coverage/coverage_summary.yaml | NOT_RUN | 第二商业工具、各模式性能/RSS及调度复现验收未完成 |
| AHB-NFR-005 | tools/run.py; src/agent/ahb_monitor.sv | full, stress | reports/coverage/coverage_summary.yaml | NOT_RUN | 第二商业工具、各模式性能/RSS及调度复现验收未完成 |
| AHB-NFR-006 | tools/run.py; src/agent/ahb_monitor.sv | full, stress | reports/coverage/coverage_summary.yaml | NOT_RUN | 第二商业工具、各模式性能/RSS及调度复现验收未完成 |
| AHB-NFR-007 | tools/run.py; src/agent/ahb_monitor.sv | full, stress | reports/coverage/coverage_summary.yaml | PASS | unit/vectors/negative 独立状态、地址、mask、parity、reservation测试 |
| AHB-NFR-008 | tools/run.py; src/agent/ahb_monitor.sv | full, stress | reports/coverage/coverage_summary.yaml | NOT_RUN | 第二商业工具、各模式性能/RSS及调度复现验收未完成 |
| AHB-ACC-001 | docs/rtm.md; tools/run.py; tools/mutate.py | full, mutation, stress | reports/coverage/coverage_summary.yaml | NOT_RUN | 发布全需求/100%强制覆盖与旧版规范审查门禁未闭合 |
| AHB-ACC-002 | docs/rtm.md; tools/run.py; tools/mutate.py | full, mutation, stress | reports/coverage/coverage_summary.yaml | NOT_RUN | 发布全需求/100%强制覆盖与旧版规范审查门禁未闭合 |
| AHB-ACC-003 | docs/rtm.md; tools/run.py; tools/mutate.py | full, mutation, stress | reports/coverage/coverage_summary.yaml | NOT_RUN | 发布全需求/100%强制覆盖与旧版规范审查门禁未闭合 |
| AHB-ACC-004 | docs/rtm.md; tools/run.py; tools/mutate.py | full, mutation, stress | reports/coverage/coverage_summary.yaml | NOT_RUN | 发布全需求/100%强制覆盖与旧版规范审查门禁未闭合 |
| AHB-ACC-005 | docs/rtm.md; tools/run.py; tools/mutate.py | full, mutation, stress | reports/coverage/coverage_summary.yaml | PASS | 六类源码变异均编译成功且对应语义测试精确检出 |
| AHB-ACC-006 | docs/rtm.md; tools/run.py; tools/mutate.py | full, mutation, stress | reports/coverage/coverage_summary.yaml | NOT_RUN | 发布全需求/100%强制覆盖与旧版规范审查门禁未闭合 |
| AHB-ACC-007 | docs/rtm.md; tools/run.py; tools/mutate.py | full, mutation, stress | reports/coverage/coverage_summary.yaml | NOT_RUN | 发布全需求/100%强制覆盖与旧版规范审查门禁未闭合 |
| AHB-ACC-008 | docs/rtm.md; tools/run.py; tools/mutate.py | full, mutation, stress | reports/coverage/coverage_summary.yaml | NOT_RUN | 发布全需求/100%强制覆盖与旧版规范审查门禁未闭合 |

# 8. Requirement-to-Architecture Trace
按 §7 的组件路径定位 architecture 组件矩阵；模型与策略分离。

# 9. Requirement-to-Implementation Trace
§7列出的源码为实际存在组件；FAIL项可能只有字段或部分基础结构。

# 10. Requirement-to-Validation Trace
用例名对应 tools/run.py tier；mutation 对应 reports/mutation/mutation_summary.yaml。

# 11. Validation Result Matrix
reports/regression/full_s1_w0.yaml：13/13开发用例通过；不覆盖所有原合同验收条件。

# 12. Protocol Rule Trace
config/checkers.yaml 与 docs/protocol_rule_matrix.md；逐规范条款全文复核尚未闭合。

# 13. Checker Trace
src/checker/ahb_checker.sv；negative直接构造周期，unit独立构造parity；所有规则完整正反例矩阵仍未完成。

# 14. Assertion Trace
src/checker/ahb_assertions.sv；error/burst/reset使用；没有完整assertion覆盖数据库。

# 15. Coverage Trace
覆盖率证据详见 reports/coverage；不从多个百分比取max冒充bin并集。

# 16. Feature Coverage Matrix
已有方向/burst/size/wait/response与基础属性bin；其余强制bin记为open hole。

# 17. Protocol Rule Coverage
规则命中见negative/unit；未把非法流量填入正常功能bin。

# 18. Mutation Trace
六种必需变异的定义仅在validation-plan §19，执行证据在mutation_summary。

# 19. Mutation Summary
6/6编译后精确检出；编译失败不算检出。

# 20. Configuration Trace
profiles.yaml的三个配置；widths验证结构边界，extensions验证混合类型。classic32 testbench为classic_agent。

# 21. Public API Trace
base_seq submit/transfer/read/write/burst_transfer/exclusive_pair；尚缺完整回调和大块拆分。

# 22. Agent Mode Trace
smoke双方active，vectors passive独立激励。

# 23. Reset Trace
vectors V11、reset、unit reservation reset、classic arbiter reset；完整各阶段矩阵尚缺。

# 24. Timeout / Deadlock Trace
watchdog分类为环境策略；测试总超时由run.py强制，不宣称AHB固有timeout。

# 25. Target / Behavior Model Trace
memory与devices的unit测试；同址并发次序尚未固定。

# 26. RAL Trace
ral前门成功/ERROR mirror过滤；全部端序、稀疏、设备副作用组合未验证。

# 27. Debug Capability Trace
rule ID、instance、cycle和context item已提供；完整前后窗口尚缺。

# 28. Statistics Trace
AHB_STATS包含完成/错误/abort/有效字节/等待；未包括完整延迟与队列高水位。

# 29. Build / Simulator Trace
reports/regression记录VCS版本、命令、退出码；FuseSoC实际导出运行见reports/fusesoc_smoke.log。

# 30. Metadata Trace
config/schema与requirements.yaml；原合同ID集合由tools/check_config.py校验。

# 31. Documentation Trace
README入口 → requirement/architecture/validation-plan/rtm/user-guide。

# 32. Regression Summary
reports/regression/regression_summary.yaml保留全合同required tiers，未缩减分母。

# 33. Simulator Summary
VCS W-2024.09-SP1 / UVM1.2实测；第二商业工具和IEEE1800.2未验证。

# 34. Coverage Summary
mandatory bin/交叉尚未100%；详见hole报告。

# 35. Requirement Closure Summary
逐ID状态汇总由reports/regression/regression_summary.yaml从本表生成；PASS仅限§7明示条目。

# 36. Uncovered Requirement
§7所有FAIL/NOT_RUN行均为剩余工作，禁止删行提升覆盖率。

# 37. Failed Validation
当前13组开发回归无失败；完整Qualification因未闭合项FAIL，二者不可混同。

# 38. Known Issues
已修复结构配置冻结、monitor内部对象隔离及静态多驱动；共享同址调度与完整功能范围仍见requirement §23。

# 39. Waiver
没有批准的不可达bin排除或需求豁免。

# 40. Limitation Trace
requirement §23为实现限制主记录；各需求的影响见§7。

# 41. Evidence Index
reports/run_log.md及结构化regression/mutation/coverage/qualification摘要。

# 42. Recommended Evidence Structure
每个运行独立目录、源码/配置指纹、seed、工具版本、命令、原始日志与退出码。

# 43. Release Readiness
尚不可作为完整AHB V1.0发布；未修改registry为Qualified/Released。

# 44. Final Qualification Statement
仅由vip_tool.py qualify --write生成reports/qualification_summary.yaml。

# 45. Sign-Off
用户授权自主实施，不代表用户接受未完成需求或豁免质量门槛。

# 46. RTM Review Checklist
169条唯一ID全保留；状态与证据已区分；剩余验收未签核。

# 47. Definition of RTM Complete
本追溯清单已建立；全部需求闭合仍未完成。
