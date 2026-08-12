# AXI4-Lite VIP（P1）

AXI4-Lite UVM VIP，VLNV（规划）：`aix:vip:axi_lite:1.0.0`。

- 优先级：**P1**（CSR 与 SoC 外设高频使用）
- 状态：规划中

## 计划能力

- 独立读写、backpressure、错误响应（BRESP=DECERR/SLVERR）；
- RAL adapter / predictor；
- 协议检查、功能覆盖、SVA；
- 与 TVIP-AXI、cocotbext-axi 交叉验证。

## 参考

- [TVIP-AXI](https://github.com/taichi-ishitani/tvip-axi)（Apache-2.0）
- [cocotbext-axi](https://github.com/alexforencich/cocotbext-axi)（MIT）
