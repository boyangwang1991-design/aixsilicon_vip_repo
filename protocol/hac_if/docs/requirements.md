# HAC-IF VIP Requirements

Requirement ID 前缀：`REQ-HAC-`。状态：`planned` / `implemented` / `verified`。

| ID | 需求 | 状态 |
|---|---|---|
| REQ-HAC-001 | 支持 ACTIVE_CORE 模式，可发起任务命令并消费完成/取消 | planned |
| REQ-HAC-002 | 支持 ACTIVE_SHELL（responder）模式，可接收命令并返回完成状态 | planned |
| REQ-HAC-003 | 支持 PASSIVE 模式，仅采样并广播事务 | planned |
| REQ-HAC-004 | 提供 hac_ctrl_agent（cmd/cpl/cancel/status） | planned |
| REQ-HAC-005 | 提供 hac_stream_agent（valid/ready/data/keep/last/id/user） | planned |
| REQ-HAC-006 | 提供 hac_mem_agent（读/写请求/响应，Tag 关联） | planned |
| REQ-HAC-007 | 提供 hac_lmem_agent（本地存储请求/响应） | planned |
| REQ-HAC-008 | 提供 hac_event_agent（事件与 severity 分类） | planned |
| REQ-HAC-009 | 提供 hac_protocol_checker（背压 Payload 稳定、Job ID 唯一、Tag 不提前复用、quiescent 无 Outstanding、Reset 后定义状态、完成不能无对应命令） | planned |
| REQ-HAC-010 | 提供 scoreboard 与 reference memory | planned |
| REQ-HAC-011 | 提供 error_injector（超时、丢响应、重复响应、AXI 错误映射） | planned |
| REQ-HAC-012 | 提供 coverage_model（Profile×Capability、长度/对齐/边界、Outstanding 深度、背压、乱序深度、错误×阶段、Reset/Cancel/Timeout×状态、Job×Memory 并发） | planned |
| REQ-HAC-013 | 提供 virtual_sequence 编排 Profile P0/P1/P2 场景 | planned |
| REQ-HAC-014 | 提供 AXI Adapter 一致性验证环境入口 | planned |
| REQ-HAC-015 | 支持多实例运行，实例名可配置 | planned |
| REQ-HAC-016 | 支持固定随机种子可复现 | planned |
| REQ-HAC-017 | 配置必须通过 config object 传递，禁止全局变量 | planned |
| REQ-HAC-018 | 提供自检测试与最小示例（smoke） | planned |

## 协议规范

- 名称：AIXSILICON HAC-IF（Hardware Accelerator Core Interface）
- 受控版本标识：`HAC-IF V0.1`
- 规范正文引用位置：`aixsilicon_hwif_repo/accelerator/hac_if/spec/hac_if_spec.md`（内部受控）
