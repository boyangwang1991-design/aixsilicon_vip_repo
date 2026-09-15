# AHB VIP 静态需求追溯

## 1. 目的

保留 169 条需求的设计期追溯，不在源文档存本次状态。

## 2. 原则

测试见证不等于完整需求验收；全部条件成立才允许报告 PASS。

## 3. 输入

contract.md、requirements.yaml、architecture.md 和 verification-plan.yaml。

## 4. 模型

需求 → 实现 → 检查/测试 → 对应执行证据。

## 5. 状态位置

PASS/FAIL/NOT_RUN/BLOCKED/WAIVED 仅写对应运行的 RTM 材料的 metadata。

## 6. 优先级

采用原合同与 requirements.yaml；不因开发版本删减需求。

## 7. 静态映射

以下历史设计说明用于定位复核对象，不作为对应执行证据。

| 需求 | 实现 | 相关测试 | 复核重点或历史设计说明 |
| --- | --- | --- | --- |
| AHB-SCP-001 | src/agent/ahb_agent.sv | system, extensions | 双方Active已运行，Passive monitor已运行；完整Passive agent角色接入仍需专用用例 |
| AHB-SCP-002 | src/agent/ahb_agent.sv | system, extensions | capability 导出及全拓扑竞争验收尚未完成 |
| AHB-SCP-003 | src/agent/ahb_agent.sv | system, extensions | capability 导出及全拓扑竞争验收尚未完成 |
| AHB-SCP-004 | src/agent/ahb_agent.sv | system, extensions | system 四 Manager/四共享目标，不同等待与地址区域读回 |
| AHB-SCP-005 | src/agent/ahb_agent.sv | system, extensions | capability 导出及全拓扑竞争验收尚未完成 |
| AHB-SCP-006 | src/agent/ahb_agent.sv | system, extensions | capability 导出及全拓扑竞争验收尚未完成 |
| AHB-SCP-007 | src/agent/ahb_agent.sv | system, extensions | user-guide 明确 CDC/一致性/系统原子性可见范围 |
| AHB-CFG-001 | src/ahb_if.sv; src/ahb_config.sv | widths, extensions, unit | 结构配置冻结、每类非法组合与运行时快照测试不完整 |
| AHB-CFG-002 | src/ahb_if.sv; src/ahb_config.sv | widths, extensions, unit | 结构配置冻结、每类非法组合与运行时快照测试不完整 |
| AHB-CFG-003 | src/ahb_if.sv; src/ahb_config.sv | widths, extensions, unit | system 按寄存的数据阶段目标选择响应；vectors V02 |
| AHB-CFG-004 | src/ahb_if.sv; src/ahb_config.sv | widths, extensions, unit | 结构配置冻结、每类非法组合与运行时快照测试不完整 |
| AHB-CFG-005 | src/ahb_if.sv; src/ahb_config.sv | widths, extensions, unit | 结构配置冻结、每类非法组合与运行时快照测试不完整 |
| AHB-CFG-006 | src/ahb_if.sv; src/ahb_config.sv | widths, extensions, unit | 零宽编译/运行通过；完整capability覆盖裁剪尚缺 |
| AHB-CFG-007 | src/ahb_if.sv; src/ahb_config.sv | widths, extensions, unit | structural freeze已实现并有三项unit断言；每类非法依赖组合测试尚未齐全 |
| AHB-CFG-008 | src/ahb_if.sv; src/ahb_config.sv | widths, extensions, unit | 结构配置冻结、每类非法组合与运行时快照测试不完整 |
| AHB-CFG-009 | src/ahb_if.sv; src/ahb_config.sv | widths, extensions, unit | 结构配置冻结、每类非法组合与运行时快照测试不完整 |
| AHB-CFG-010 | src/ahb_if.sv; src/ahb_config.sv | widths, extensions, unit | extensions 同仿真 Lite32/AHB5_128 |
| AHB-TRN-001 | src/transaction/ahb_item.sv; src/sequences/ahb_base_seq.sv | unit, vectors, reset | 完整回调链、BUSY/IDLE 计划及取消 API 尚缺 |
| AHB-TRN-002 | src/transaction/ahb_item.sv; src/sequences/ahb_base_seq.sv | unit, vectors, reset | 完整回调链、BUSY/IDLE 计划及取消 API 尚缺 |
| AHB-TRN-003 | src/transaction/ahb_item.sv; src/sequences/ahb_base_seq.sv | unit, vectors, reset | 完整回调链、BUSY/IDLE 计划及取消 API 尚缺 |
| AHB-TRN-004 | src/transaction/ahb_item.sv; src/sequences/ahb_base_seq.sv | unit, vectors, reset | 完整回调链、BUSY/IDLE 计划及取消 API 尚缺 |
| AHB-TRN-005 | src/transaction/ahb_item.sv; src/sequences/ahb_base_seq.sv | unit, vectors, reset | 完整回调链、BUSY/IDLE 计划及取消 API 尚缺 |
| AHB-TRN-006 | src/transaction/ahb_item.sv; src/sequences/ahb_base_seq.sv | unit, vectors, reset | 完整回调链、BUSY/IDLE 计划及取消 API 尚缺 |
| AHB-TRN-007 | src/transaction/ahb_item.sv; src/sequences/ahb_base_seq.sv | unit, vectors, reset | 完整回调链、BUSY/IDLE 计划及取消 API 尚缺 |
| AHB-TRN-008 | src/transaction/ahb_item.sv; src/sequences/ahb_base_seq.sv | unit, vectors, reset | 完整回调链、BUSY/IDLE 计划及取消 API 尚缺 |
| AHB-TRN-009 | src/transaction/ahb_item.sv; src/sequences/ahb_base_seq.sv | unit, vectors, reset | 完整回调链、BUSY/IDLE 计划及取消 API 尚缺 |
| AHB-TRN-010 | src/transaction/ahb_item.sv; src/sequences/ahb_base_seq.sv | unit, vectors, reset | 完整回调链、BUSY/IDLE 计划及取消 API 尚缺 |
| AHB-BAS-001 | src/agent/ahb_driver.sv; src/agent/ahb_monitor.sv | vectors, smoke, system | 全宽度/HSIZE、256拍无气泡及转移交叉未闭合 |
| AHB-BAS-002 | src/agent/ahb_driver.sv; src/agent/ahb_monitor.sv | vectors, smoke, system | 全宽度/HSIZE、256拍无气泡及转移交叉未闭合 |
| AHB-BAS-003 | src/agent/ahb_driver.sv; src/agent/ahb_monitor.sv | vectors, smoke, system | smoke 256个连续写，逐完成周期断言无气泡；另256读回匹配 |
| AHB-BAS-004 | src/agent/ahb_driver.sv; src/agent/ahb_monitor.sv | vectors, smoke, system | 全宽度/HSIZE、256拍无气泡及转移交叉未闭合 |
| AHB-BAS-005 | src/agent/ahb_driver.sv; src/agent/ahb_monitor.sv | vectors, smoke, system | 全宽度/HSIZE、256拍无气泡及转移交叉未闭合 |
| AHB-BAS-006 | src/agent/ahb_driver.sv; src/agent/ahb_monitor.sv | vectors, smoke, system | 全宽度/HSIZE、256拍无气泡及转移交叉未闭合 |
| AHB-BAS-007 | src/agent/ahb_driver.sv; src/agent/ahb_monitor.sv | vectors, smoke, system | 全宽度/HSIZE、256拍无气泡及转移交叉未闭合 |
| AHB-BAS-008 | src/agent/ahb_driver.sv; src/agent/ahb_monitor.sv | vectors, smoke, system | 全宽度/HSIZE、256拍无气泡及转移交叉未闭合 |
| AHB-BAS-009 | src/agent/ahb_driver.sv; src/agent/ahb_monitor.sv | vectors, smoke, system | 全宽度/HSIZE、256拍无气泡及转移交叉未闭合 |
| AHB-BAS-010 | src/agent/ahb_driver.sv; src/agent/ahb_monitor.sv | vectors, smoke, system | 全宽度/HSIZE、256拍无气泡及转移交叉未闭合 |
| AHB-BST-001 | src/ahb_types_pkg.sv; src/checker/ahb_checker.sv | unit, burst, negative | 大块拆分、动态 INCR 与全端序/宽度组合未闭合 |
| AHB-BST-002 | src/ahb_types_pkg.sv; src/checker/ahb_checker.sv | unit, burst, negative | 大块拆分、动态 INCR 与全端序/宽度组合未闭合 |
| AHB-BST-003 | src/ahb_types_pkg.sv; src/checker/ahb_checker.sv | unit, burst, negative | unit 全WRAP起点；negative错误SEQ地址；MUT-ADDR |
| AHB-BST-004 | src/ahb_types_pkg.sv; src/checker/ahb_checker.sv | unit, burst, negative | negative ALIGN/SIZE/BOUNDARY 正反例 |
| AHB-BST-005 | src/ahb_types_pkg.sv; src/checker/ahb_checker.sv | unit, burst, negative | 大块拆分、动态 INCR 与全端序/宽度组合未闭合 |
| AHB-BST-006 | src/ahb_types_pkg.sv; src/checker/ahb_checker.sv | unit, burst, negative | 大块拆分、动态 INCR 与全端序/宽度组合未闭合 |
| AHB-BST-007 | src/ahb_types_pkg.sv; src/checker/ahb_checker.sv | unit, burst, negative | 大块拆分、动态 INCR 与全端序/宽度组合未闭合 |
| AHB-BST-008 | src/ahb_types_pkg.sv; src/checker/ahb_checker.sv | unit, burst, negative | 大块拆分、动态 INCR 与全端序/宽度组合未闭合 |
| AHB-BST-009 | src/ahb_types_pkg.sv; src/checker/ahb_checker.sv | unit, burst, negative | 大块拆分、动态 INCR 与全端序/宽度组合未闭合 |
| AHB-BST-010 | src/ahb_types_pkg.sv; src/checker/ahb_checker.sv | unit, burst, negative | 大块拆分、动态 INCR 与全端序/宽度组合未闭合 |
| AHB-BST-011 | src/ahb_types_pkg.sv; src/checker/ahb_checker.sv | unit, burst, negative | 大块拆分、动态 INCR 与全端序/宽度组合未闭合 |
| AHB-RSP-001 | src/agent/ahb_slave_driver.sv; src/agent/ahb_driver.sv | error, vectors, negative | 完整 ERROR 触发维度、burst停止/继续策略未完成 |
| AHB-RSP-002 | src/agent/ahb_slave_driver.sv; src/agent/ahb_driver.sv | error, vectors, negative | 完整 ERROR 触发维度、burst停止/继续策略未完成 |
| AHB-RSP-003 | src/agent/ahb_slave_driver.sv; src/agent/ahb_driver.sv | error, vectors, negative | 完整 ERROR 触发维度、burst停止/继续策略未完成 |
| AHB-RSP-004 | src/agent/ahb_slave_driver.sv; src/agent/ahb_driver.sv | error, vectors, negative | 完整 ERROR 触发维度、burst停止/继续策略未完成 |
| AHB-RSP-005 | src/agent/ahb_slave_driver.sv; src/agent/ahb_driver.sv | error, vectors, negative | 完整 ERROR 触发维度、burst停止/继续策略未完成 |
| AHB-RSP-006 | src/agent/ahb_slave_driver.sv; src/agent/ahb_driver.sv | error, vectors, negative | 完整 ERROR 触发维度、burst停止/继续策略未完成 |
| AHB-RSP-007 | src/agent/ahb_slave_driver.sv; src/agent/ahb_driver.sv | error, vectors, negative | 完整 ERROR 触发维度、burst停止/继续策略未完成 |
| AHB-RSP-008 | src/agent/ahb_slave_driver.sv; src/agent/ahb_driver.sv | error, vectors, negative | 完整 ERROR 触发维度、burst停止/继续策略未完成 |
| AHB-LCK-001 | src/classic/ahb_arbiter.sv; src/checker/ahb_checker.sv | classic, negative | 系统所有权 lock checker 与竞争场景未闭合 |
| AHB-LCK-002 | src/classic/ahb_arbiter.sv; src/checker/ahb_checker.sv | classic, negative | 系统所有权 lock checker 与竞争场景未闭合 |
| AHB-LCK-003 | src/classic/ahb_arbiter.sv; src/checker/ahb_checker.sv | classic, negative | 系统所有权 lock checker 与竞争场景未闭合 |
| AHB-LEG-001 | src/classic/ahb_arbiter.sv; src/agent/ahb_driver.sv; src/classic/ahb_classic_model.sv | classic, classic_agent, unit | 经典规范全文差异审查、多活动 Master 交接与锁竞争未完成 |
| AHB-LEG-002 | src/classic/ahb_arbiter.sv; src/agent/ahb_driver.sv; src/classic/ahb_classic_model.sv | classic, classic_agent, unit | 经典规范全文差异审查、多活动 Master 交接与锁竞争未完成 |
| AHB-LEG-003 | src/classic/ahb_arbiter.sv; src/agent/ahb_driver.sv; src/classic/ahb_classic_model.sv | classic, classic_agent, unit | 经典规范全文差异审查、多活动 Master 交接与锁竞争未完成 |
| AHB-LEG-004 | src/classic/ahb_arbiter.sv; src/agent/ahb_driver.sv; src/classic/ahb_classic_model.sv | classic, classic_agent, unit | 经典规范全文差异审查、多活动 Master 交接与锁竞争未完成 |
| AHB-LEG-005 | src/classic/ahb_arbiter.sv; src/agent/ahb_driver.sv; src/classic/ahb_classic_model.sv | classic, classic_agent, unit | 经典规范全文差异审查、多活动 Master 交接与锁竞争未完成 |
| AHB-LEG-006 | src/classic/ahb_arbiter.sv; src/agent/ahb_driver.sv; src/classic/ahb_classic_model.sv | classic, classic_agent, unit | 经典规范全文差异审查、多活动 Master 交接与锁竞争未完成 |
| AHB-LEG-007 | src/classic/ahb_arbiter.sv; src/agent/ahb_driver.sv; src/classic/ahb_classic_model.sv | classic, classic_agent, unit | 经典规范全文差异审查、多活动 Master 交接与锁竞争未完成 |
| AHB-LEG-008 | src/classic/ahb_arbiter.sv; src/agent/ahb_driver.sv; src/classic/ahb_classic_model.sv | classic, classic_agent, unit | 经典规范全文差异审查、多活动 Master 交接与锁竞争未完成 |
| AHB-LEG-009 | src/classic/ahb_arbiter.sv; src/agent/ahb_driver.sv; src/classic/ahb_classic_model.sv | classic, classic_agent, unit | 经典规范全文差异审查、多活动 Master 交接与锁竞争未完成 |
| AHB-LEG-010 | src/classic/ahb_arbiter.sv; src/agent/ahb_driver.sv; src/classic/ahb_classic_model.sv | classic, classic_agent, unit | 经典规范全文差异审查、多活动 Master 交接与锁竞争未完成 |
| AHB-SEC-001 | src/model/ahb_devices.sv; src/scoreboard/ahb_bridge_scoreboard.sv | unit, extensions | HPROT语义解码及权限/属性变换全矩阵未完成 |
| AHB-SEC-002 | src/model/ahb_devices.sv; src/scoreboard/ahb_bridge_scoreboard.sv | unit, extensions | HPROT语义解码及权限/属性变换全矩阵未完成 |
| AHB-SEC-003 | src/model/ahb_devices.sv; src/scoreboard/ahb_bridge_scoreboard.sv | unit, extensions | HPROT语义解码及权限/属性变换全矩阵未完成 |
| AHB-SEC-004 | src/model/ahb_devices.sv; src/scoreboard/ahb_bridge_scoreboard.sv | unit, extensions | HPROT语义解码及权限/属性变换全矩阵未完成 |
| AHB-SEC-005 | src/model/ahb_devices.sv; src/scoreboard/ahb_bridge_scoreboard.sv | unit, extensions | HPROT语义解码及权限/属性变换全矩阵未完成 |
| AHB-SEC-006 | src/model/ahb_devices.sv; src/scoreboard/ahb_bridge_scoreboard.sv | unit, extensions | HPROT语义解码及权限/属性变换全矩阵未完成 |
| AHB-ATM-001 | src/ahb_config.sv | 无对应系统验收 | 原子属性依赖与系统交错可见性 checker 尚未实现 |
| AHB-ATM-002 | src/ahb_config.sv | 无对应系统验收 | 原子属性依赖与系统交错可见性 checker 尚未实现 |
| AHB-EXC-001 | src/model/ahb_memory.sv; src/checker/ahb_checker.sv | unit, extensions, negative | 跨四接口身份映射、全部失配原因与可见性通知验收未闭合 |
| AHB-EXC-002 | src/model/ahb_memory.sv; src/checker/ahb_checker.sv | unit, extensions, negative | 跨四接口身份映射、全部失配原因与可见性通知验收未闭合 |
| AHB-EXC-003 | src/model/ahb_memory.sv; src/checker/ahb_checker.sv | unit, extensions, negative | 跨四接口身份映射、全部失配原因与可见性通知验收未闭合 |
| AHB-EXC-004 | src/model/ahb_memory.sv; src/checker/ahb_checker.sv | unit, extensions, negative | 跨四接口身份映射、全部失配原因与可见性通知验收未闭合 |
| AHB-EXC-005 | src/model/ahb_memory.sv; src/checker/ahb_checker.sv | unit, extensions, negative | 跨四接口身份映射、全部失配原因与可见性通知验收未闭合 |
| AHB-EXC-006 | src/model/ahb_memory.sv; src/checker/ahb_checker.sv | unit, extensions, negative | 跨四接口身份映射、全部失配原因与可见性通知验收未闭合 |
| AHB-EXC-007 | src/model/ahb_memory.sv; src/checker/ahb_checker.sv | unit, extensions, negative | 跨四接口身份映射、全部失配原因与可见性通知验收未闭合 |
| AHB-EXC-008 | src/model/ahb_memory.sv; src/checker/ahb_checker.sv | unit, extensions, negative | 跨四接口身份映射、全部失配原因与可见性通知验收未闭合 |
| AHB-EXC-009 | src/model/ahb_memory.sv; src/checker/ahb_checker.sv | unit, extensions, negative | 跨四接口身份映射、全部失配原因与可见性通知验收未闭合 |
| AHB-EXC-010 | src/model/ahb_memory.sv; src/checker/ahb_checker.sv | unit, extensions, negative | 跨四接口身份映射、全部失配原因与可见性通知验收未闭合 |
| AHB-STR-001 | src/model/ahb_memory.sv; src/agent/ahb_monitor.sv | unit, extensions, negative | 所有 strobe模式 × HSIZE × 等待未闭合 |
| AHB-STR-002 | src/model/ahb_memory.sv; src/agent/ahb_monitor.sv | unit, extensions, negative | unit inactive_strobe；MUT-MASK 检出 |
| AHB-STR-003 | src/model/ahb_memory.sv; src/agent/ahb_monitor.sv | unit, extensions, negative | 所有 strobe模式 × HSIZE × 等待未闭合 |
| AHB-STR-004 | src/model/ahb_memory.sv; src/agent/ahb_monitor.sv | unit, extensions, negative | 所有 strobe模式 × HSIZE × 等待未闭合 |
| AHB-STR-005 | src/model/ahb_memory.sv; src/agent/ahb_monitor.sv | unit, extensions, negative | 所有 strobe模式 × HSIZE × 等待未闭合 |
| AHB-USR-001 | src/agent/ahb_monitor.sv; src/scoreboard/ahb_bridge_scoreboard.sv | extensions, negative | 可替换 USER 策略与拆分/聚合专用验证尚缺 |
| AHB-USR-002 | src/agent/ahb_monitor.sv; src/scoreboard/ahb_bridge_scoreboard.sv | extensions, negative | 可替换 USER 策略与拆分/聚合专用验证尚缺 |
| AHB-USR-003 | src/agent/ahb_monitor.sv; src/scoreboard/ahb_bridge_scoreboard.sv | extensions, negative | 可替换 USER 策略与拆分/聚合专用验证尚缺 |
| AHB-USR-004 | src/agent/ahb_monitor.sv; src/scoreboard/ahb_bridge_scoreboard.sv | extensions, negative | 可替换 USER 策略与拆分/聚合专用验证尚缺 |
| AHB-PAR-001 | src/checker/ahb_checker.sv; src/ahb_types_pkg.sv | unit, extensions | 完整信号级故障 API、所有保护组有效/无效窗口配对验证尚缺 |
| AHB-PAR-002 | src/checker/ahb_checker.sv; src/ahb_types_pkg.sv | unit, extensions | 完整信号级故障 API、所有保护组有效/无效窗口配对验证尚缺 |
| AHB-PAR-003 | src/checker/ahb_checker.sv; src/ahb_types_pkg.sv | unit, extensions | 完整信号级故障 API、所有保护组有效/无效窗口配对验证尚缺 |
| AHB-PAR-004 | src/checker/ahb_checker.sv; src/ahb_types_pkg.sv | unit, extensions | 完整信号级故障 API、所有保护组有效/无效窗口配对验证尚缺 |
| AHB-PAR-005 | src/checker/ahb_checker.sv; src/ahb_types_pkg.sv | unit, extensions | 完整信号级故障 API、所有保护组有效/无效窗口配对验证尚缺 |
| AHB-PAR-006 | src/checker/ahb_checker.sv; src/ahb_types_pkg.sv | unit, extensions | unit 同组双位翻转采用不检出预期；user-guide限制 |
| AHB-MEM-001 | src/model/ahb_memory.sv; src/model/ahb_devices.sv; src/scoreboard/ahb_bridge_scoreboard.sv | unit, smoke, system | 同周期同址冲突调度、桥接丢失/重复/转换负测未闭合 |
| AHB-MEM-002 | src/model/ahb_memory.sv; src/model/ahb_devices.sv; src/scoreboard/ahb_bridge_scoreboard.sv | unit, smoke, system | 同周期同址冲突调度、桥接丢失/重复/转换负测未闭合 |
| AHB-MEM-003 | src/model/ahb_memory.sv; src/model/ahb_devices.sv; src/scoreboard/ahb_bridge_scoreboard.sv | unit, smoke, system | smoke WAIT=0写提交计数，system WAIT=1/2/3计数，error失败无提交 |
| AHB-MEM-004 | src/model/ahb_memory.sv; src/model/ahb_devices.sv; src/scoreboard/ahb_bridge_scoreboard.sv | unit, smoke, system | 同周期同址冲突调度、桥接丢失/重复/转换负测未闭合 |
| AHB-MEM-005 | src/model/ahb_memory.sv; src/model/ahb_devices.sv; src/scoreboard/ahb_bridge_scoreboard.sv | unit, smoke, system | 同周期同址冲突调度、桥接丢失/重复/转换负测未闭合 |
| AHB-MEM-006 | src/model/ahb_memory.sv; src/model/ahb_devices.sv; src/scoreboard/ahb_bridge_scoreboard.sv | unit, smoke, system | 同周期同址冲突调度、桥接丢失/重复/转换负测未闭合 |
| AHB-MEM-007 | src/model/ahb_memory.sv; src/model/ahb_devices.sv; src/scoreboard/ahb_bridge_scoreboard.sv | unit, smoke, system | 同周期同址冲突调度、桥接丢失/重复/转换负测未闭合 |
| AHB-MEM-008 | src/model/ahb_memory.sv; src/model/ahb_devices.sv; src/scoreboard/ahb_bridge_scoreboard.sv | unit, smoke, system | 同周期同址冲突调度、桥接丢失/重复/转换负测未闭合 |
| AHB-MEM-009 | src/model/ahb_memory.sv; src/model/ahb_devices.sv; src/scoreboard/ahb_bridge_scoreboard.sv | unit, smoke, system | vectors 仅monitor/checker无memory；指南明确范围 |
| AHB-RST-001 | src/agent/ahb_driver.sv; src/agent/ahb_monitor.sv | reset, vectors, classic | 重提交、sequence kill、各协议阶段复位矩阵未完成 |
| AHB-RST-002 | src/agent/ahb_driver.sv; src/agent/ahb_monitor.sv | reset, vectors, classic | 重提交、sequence kill、各协议阶段复位矩阵未完成 |
| AHB-RST-003 | src/agent/ahb_driver.sv; src/agent/ahb_monitor.sv | reset, vectors, classic | 重提交、sequence kill、各协议阶段复位矩阵未完成 |
| AHB-RST-004 | src/agent/ahb_driver.sv; src/agent/ahb_monitor.sv | reset, vectors, classic | 重提交、sequence kill、各协议阶段复位矩阵未完成 |
| AHB-RST-005 | src/agent/ahb_driver.sv; src/agent/ahb_monitor.sv | reset, vectors, classic | 重提交、sequence kill、各协议阶段复位矩阵未完成 |
| AHB-RST-006 | src/agent/ahb_driver.sv; src/agent/ahb_monitor.sv | reset, vectors, classic | 重提交、sequence kill、各协议阶段复位矩阵未完成 |
| AHB-RST-007 | src/agent/ahb_driver.sv; src/agent/ahb_monitor.sv | reset, vectors, classic | 重提交、sequence kill、各协议阶段复位矩阵未完成 |
| AHB-RST-008 | src/agent/ahb_driver.sv; src/agent/ahb_monitor.sv | reset, vectors, classic | 重提交、sequence kill、各协议阶段复位矩阵未完成 |
| AHB-CHK-001 | src/checker/ahb_checker.sv; src/checker/ahb_violation.sv | negative, unit, vectors | 全部规则正反例与完整前后周期诊断窗口尚缺 |
| AHB-CHK-002 | src/checker/ahb_checker.sv; src/checker/ahb_violation.sv | negative, unit, vectors | 全部规则正反例与完整前后周期诊断窗口尚缺 |
| AHB-CHK-003 | src/checker/ahb_checker.sv; src/checker/ahb_violation.sv | negative, unit, vectors | 全部规则正反例与完整前后周期诊断窗口尚缺 |
| AHB-CHK-004 | src/checker/ahb_checker.sv; src/checker/ahb_violation.sv | negative, unit, vectors | 全部规则正反例与完整前后周期诊断窗口尚缺 |
| AHB-CHK-005 | src/checker/ahb_checker.sv; src/checker/ahb_violation.sv | negative, unit, vectors | 全部规则正反例与完整前后周期诊断窗口尚缺 |
| AHB-CHK-006 | src/checker/ahb_checker.sv; src/checker/ahb_violation.sv | negative, unit, vectors | 全部规则正反例与完整前后周期诊断窗口尚缺 |
| AHB-CHK-007 | src/checker/ahb_checker.sv; src/checker/ahb_violation.sv | negative, unit, vectors | 全部规则正反例与完整前后周期诊断窗口尚缺 |
| AHB-CHK-008 | src/checker/ahb_checker.sv; src/checker/ahb_violation.sv | negative, unit, vectors | 全部规则正反例与完整前后周期诊断窗口尚缺 |
| AHB-CHK-009 | src/checker/ahb_checker.sv; src/checker/ahb_violation.sv | negative, unit, vectors | 全部规则正反例与完整前后周期诊断窗口尚缺 |
| AHB-NEG-001 | self_test/tb/ahb_negative_tb.sv; tools/mutate.py | negative, unit | 统一在线故障注入 API 与实例/时间窗口限定匹配尚缺 |
| AHB-NEG-002 | self_test/tb/ahb_negative_tb.sv; tools/mutate.py | negative, unit | 统一在线故障注入 API 与实例/时间窗口限定匹配尚缺 |
| AHB-NEG-003 | self_test/tb/ahb_negative_tb.sv; tools/mutate.py | negative, unit | 统一在线故障注入 API 与实例/时间窗口限定匹配尚缺 |
| AHB-NEG-004 | self_test/tb/ahb_negative_tb.sv; tools/mutate.py | negative, unit | 统一在线故障注入 API 与实例/时间窗口限定匹配尚缺 |
| AHB-NEG-005 | self_test/tb/ahb_negative_tb.sv; tools/mutate.py | negative, unit | 统一在线故障注入 API 与实例/时间窗口限定匹配尚缺 |
| AHB-NEG-006 | self_test/tb/ahb_negative_tb.sv; tools/mutate.py | negative, unit | 统一在线故障注入 API 与实例/时间窗口限定匹配尚缺 |
| AHB-COV-001 | src/coverage/ahb_coverage.sv | full 回归各实例 AHB_BIN | 仅基础 bin 已实现；强制扩展、经典、阶段交叉与完整统计尚缺 |
| AHB-COV-002 | src/coverage/ahb_coverage.sv | full 回归各实例 AHB_BIN | 仅基础 bin 已实现；强制扩展、经典、阶段交叉与完整统计尚缺 |
| AHB-COV-003 | src/coverage/ahb_coverage.sv | full 回归各实例 AHB_BIN | 仅基础 bin 已实现；强制扩展、经典、阶段交叉与完整统计尚缺 |
| AHB-COV-004 | src/coverage/ahb_coverage.sv | full 回归各实例 AHB_BIN | 仅基础 bin 已实现；强制扩展、经典、阶段交叉与完整统计尚缺 |
| AHB-COV-005 | src/coverage/ahb_coverage.sv | full 回归各实例 AHB_BIN | 仅基础 bin 已实现；强制扩展、经典、阶段交叉与完整统计尚缺 |
| AHB-COV-006 | src/coverage/ahb_coverage.sv | full 回归各实例 AHB_BIN | 仅基础 bin 已实现；强制扩展、经典、阶段交叉与完整统计尚缺 |
| AHB-COV-007 | src/coverage/ahb_coverage.sv | full 回归各实例 AHB_BIN | 仅基础 bin 已实现；强制扩展、经典、阶段交叉与完整统计尚缺 |
| AHB-COV-008 | src/coverage/ahb_coverage.sv | full 回归各实例 AHB_BIN | 仅基础 bin 已实现；强制扩展、经典、阶段交叉与完整统计尚缺 |
| AHB-COV-009 | src/coverage/ahb_coverage.sv | full 回归各实例 AHB_BIN | 仅基础 bin 已实现；强制扩展、经典、阶段交叉与完整统计尚缺 |
| AHB-UVM-001 | src/agent/ahb_agent.sv; src/ral/ahb_ral.sv; aixsilicon_vip_ahb_0.1.0.core | ral, smoke, extensions | IEEE1800.2构建、sequence kill和所有场景序列库未完成 |
| AHB-UVM-002 | src/agent/ahb_agent.sv; src/ral/ahb_ral.sv; aixsilicon_vip_ahb_0.1.0.core | ral, smoke, extensions | IEEE1800.2构建、sequence kill和所有场景序列库未完成 |
| AHB-UVM-003 | src/agent/ahb_agent.sv; src/ral/ahb_ral.sv; aixsilicon_vip_ahb_0.1.0.core | ral, smoke, extensions | IEEE1800.2构建、sequence kill和所有场景序列库未完成 |
| AHB-UVM-004 | src/agent/ahb_agent.sv; src/ral/ahb_ral.sv; aixsilicon_vip_ahb_0.1.0.core | ral, smoke, extensions | IEEE1800.2构建、sequence kill和所有场景序列库未完成 |
| AHB-UVM-005 | src/agent/ahb_agent.sv; src/ral/ahb_ral.sv; aixsilicon_vip_ahb_0.1.0.core | ral, smoke, extensions | IEEE1800.2构建、sequence kill和所有场景序列库未完成 |
| AHB-UVM-006 | src/agent/ahb_agent.sv; src/ral/ahb_ral.sv; aixsilicon_vip_ahb_0.1.0.core | ral, smoke, extensions | IEEE1800.2构建、sequence kill和所有场景序列库未完成 |
| AHB-UVM-007 | src/agent/ahb_agent.sv; src/ral/ahb_ral.sv; aixsilicon_vip_ahb_0.1.0.core | ral, smoke, extensions | IEEE1800.2构建、sequence kill和所有场景序列库未完成 |
| AHB-UVM-008 | src/agent/ahb_agent.sv; src/ral/ahb_ral.sv; aixsilicon_vip_ahb_0.1.0.core | ral, smoke, extensions | IEEE1800.2构建、sequence kill和所有场景序列库未完成 |
| AHB-UVM-009 | src/agent/ahb_agent.sv; src/ral/ahb_ral.sv; aixsilicon_vip_ahb_0.1.0.core | ral, smoke, extensions | 实际FuseSoC导出工程smoke通过；core相对路径与显式编译顺序 |
| AHB-UVM-010 | src/agent/ahb_agent.sv; src/ral/ahb_ral.sv; aixsilicon_vip_ahb_0.1.0.core | ral, smoke, extensions | IEEE1800.2构建、sequence kill和所有场景序列库未完成 |
| AHB-NFR-001 | tools/run.py; src/agent/ahb_monitor.sv | full, stress | 第二商业工具、各模式性能/RSS及调度复现验收未完成 |
| AHB-NFR-002 | tools/run.py; src/agent/ahb_monitor.sv | full, stress | 源代码无厂商DPI/加密依赖；所有核心回归 |
| AHB-NFR-003 | tools/run.py; src/agent/ahb_monitor.sv | full, stress | 第二商业工具、各模式性能/RSS及调度复现验收未完成 |
| AHB-NFR-004 | tools/run.py; src/agent/ahb_monitor.sv | full, stress | 第二商业工具、各模式性能/RSS及调度复现验收未完成 |
| AHB-NFR-005 | tools/run.py; src/agent/ahb_monitor.sv | full, stress | 第二商业工具、各模式性能/RSS及调度复现验收未完成 |
| AHB-NFR-006 | tools/run.py; src/agent/ahb_monitor.sv | full, stress | 第二商业工具、各模式性能/RSS及调度复现验收未完成 |
| AHB-NFR-007 | tools/run.py; src/agent/ahb_monitor.sv | full, stress | unit/vectors/negative 独立状态、地址、mask、parity、reservation测试 |
| AHB-NFR-008 | tools/run.py; src/agent/ahb_monitor.sv | full, stress | 第二商业工具、各模式性能/RSS及调度复现验收未完成 |
| AHB-ACC-001 | docs/rtm.md; tools/run.py; tools/mutate.py | full, mutation, stress | 发布全需求/100%强制覆盖与旧版规范审查门禁未闭合 |
| AHB-ACC-002 | docs/rtm.md; tools/run.py; tools/mutate.py | full, mutation, stress | 发布全需求/100%强制覆盖与旧版规范审查门禁未闭合 |
| AHB-ACC-003 | docs/rtm.md; tools/run.py; tools/mutate.py | full, mutation, stress | 发布全需求/100%强制覆盖与旧版规范审查门禁未闭合 |
| AHB-ACC-004 | docs/rtm.md; tools/run.py; tools/mutate.py | full, mutation, stress | 发布全需求/100%强制覆盖与旧版规范审查门禁未闭合 |
| AHB-ACC-005 | docs/rtm.md; tools/run.py; tools/mutate.py | full, mutation, stress | 六类源码变异均编译成功且对应语义测试精确检出 |
| AHB-ACC-006 | docs/rtm.md; tools/run.py; tools/mutate.py | full, mutation, stress | 发布全需求/100%强制覆盖与旧版规范审查门禁未闭合 |
| AHB-ACC-007 | docs/rtm.md; tools/run.py; tools/mutate.py | full, mutation, stress | 发布全需求/100%强制覆盖与旧版规范审查门禁未闭合 |
| AHB-ACC-008 | docs/rtm.md; tools/run.py; tools/mutate.py | full, mutation, stress | 发布全需求/100%强制覆盖与旧版规范审查门禁未闭合 |

## 8. 架构映射

按组件职责核对架构文档。

## 9. 实现映射

实现路径以本表为线索，报告中重新核查存在性。

## 10. 验证映射

test 字段只能引用冻结 regression case。

## 11. 结果矩阵

逐次结果由 AI 阅读日志后写入运行报告。

## 29. 构建追溯

编译命令、工具版本、退出码和日志保存在 evidence/raw。

## 30. 元数据追溯

报告绑定对应冻结输入与计划指纹。

## 31. 文档追溯

docs 保存中文稳定输入；reports/latest.md 保存最新综合报告，原始证据位于本 VIP 的 build。

## 35. 需求闭合

任何部分证据不足以关闭复合需求。

## 36. 未覆盖需求

逐项保留未执行状态；不缩小分母。

## 37. 失败验证

保留原始失败日志与原因，不能仅替换摘要。

## 38. 已知问题

需求 §23 和本表复核重点为检查输入。

## 39. 豁免

v1 不接受 WAIVED 作为通过。

## 40. 限制映射

协议源审查、跨工具、系统原子性、完整覆盖等缺口关联完整验收。

## 41. 证据索引

运行报告 evidence 数组给出相对路径与 SHA256。

## 42. 证据结构

logs/evidence/coverage/metadata/gates 位于 RUN_ROOT；最新阶段报告直接位于源 VIP 的 reports，latest.md 保存综合报告；报告中的身份与证据路径绑定其明确列出的冻结执行输入。

## 43. 发布条件

六类报告、结构和 core 均通过才可创建本地候选。

## 44. 认证声明

以 qualify 重新计算为准；开发测试成功不等于认证。

## 45. 签核

发布与上传需要单独授权；重跑和文档更新不代表发布。

## 46. 复核清单

ID 全量保留、映射存在、证据新鲜、未关闭项说明完整。

## 47. 完成定义

全部适用需求有完整验收证据；否则明确保留阻断。
