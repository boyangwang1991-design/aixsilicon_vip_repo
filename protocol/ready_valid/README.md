# Ready/Valid VIP（P0）

通用 Ready/Valid 握手协议 VIP，VLNV（规划）：`aix:vip:ready_valid:1.0.0`。

- 优先级：**P0**（所有数据通路 / CBB 环境依赖）
- 状态：规划中（骨架待生成）

## 计划能力

- Source / Sink / Monitor 三种角色；
- 随机 stall（valid 保持、ready 随机拉低）、backpressure；
- packet 模式（payload + 控制/状态字段，可含 TKEEP/TLAST 语义）；
- timeout、X/Z 检测、协议检查与功能覆盖；
- 多实例、固定种子可复现。

## 依赖

- `aix:vip:common:^1.0`
