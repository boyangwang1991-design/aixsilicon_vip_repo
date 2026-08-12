# AXI4 VIP（P1/P2）

完整 AXI4 UVM VIP，VLNV（规划）：`aix:vip:axi:1.0.0`。

- 优先级：**P1（P2 完整化）**
- 状态：规划中

## 计划能力

- Burst、ID、Outstanding、乱序、窄传输、非对齐、4KB 边界；
- exclusive / atomic 策略（按首版支持矩阵逐步加入）；
- 高并发 Master 与可编程 Slave responder；
- Memory model 与 scoreboard adapter；
- 性能监测（延迟/带宽/stall）；
- 协议覆盖与大量负向测试；
- 与 TVIP-AXI、PULP AXI 及可用商业 VIP 交叉验证。

## 参考

- [TVIP-AXI](https://github.com/taichi-ishitani/tvip-axi)（Apache-2.0）
- [PULP AXI](https://github.com/pulp-platform/axi)（Solderpad 系）

> 完整 AXI 不应因赶节点而提前标为 Qualified。
