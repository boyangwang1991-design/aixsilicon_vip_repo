# AXI-Stream VIP（P1）

AXI-Stream UVM VIP，VLNV（规划）：`aix:vip:axi_stream:1.0.0`。

- 优先级：**P1**（数据通路 / CBB 高频使用）
- 状态：规划中

## 计划能力

- packet 建模：payload、TKEEP/TSTRB/TLAST/TID/TDEST/TUSER；
- backpressure 与随机 stall；
- Source / Sink / Monitor 角色；
- 数据完整性检查、协议检查、功能覆盖；
- 与 cocotbext-axi（AXI-Stream Python BFM）交叉验证。
