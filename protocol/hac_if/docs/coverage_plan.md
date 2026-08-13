# HAC-IF VIP Coverage Plan

> 依据 [`digest/hwif.md`](../../../../../digest/hwif.md:874) 第 19.4 节 Coverage 规划。

## 功能覆盖点

| 覆盖点 | 说明 |
|---|---|
| Profile×Capability 交叉 | P0/P1/P2 × 各可选能力开关 |
| 请求长度、对齐、边界 | 单 Beat/多 Beat、4KB、非对齐 |
| Outstanding 深度 | Read/Write Outstanding 水位 |
| 背压位置和持续时间 | cmd/cpl/req/rsp/stream 各通道背压 |
| 响应乱序深度 | 跨 Tag 乱序深度 |
| 错误类型 × 执行阶段 | 参数/访存/计算/ECC/超时 × 各阶段 |
| Reset/Cancel/Timeout × 事务状态 | 生命周期 × 事务状态 |
| Job 并发度 × Memory 并发度 | 多任务 × 多 Tag |

## 覆盖率模型

- `hac_ctrl_cg`：cmd/cpl/cancel、job_id 唯一、状态码；
- `hac_mem_cg`：opcode×len×tag 复用×乱序；
- `hac_stream_cg`：keep/last/id/user 交叉；
- `hac_event_cg`：event_type×severity×source；
- `hac_mgmt_cg`：drain/reset/isolate 状态机。
