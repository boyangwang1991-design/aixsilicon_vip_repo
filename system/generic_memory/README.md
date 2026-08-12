# Generic Memory VIP（P0）

通用存储器模型（SRAM/ROM）服务 VIP，VLNV（规划）：`aix:vip:generic_memory:1.0.0`。

- 优先级：**P0**（IP 与 SoC 普遍需要）
- 状态：规划中

## 计划能力

- SRAM / ROM 模型，可配置深度、宽度、初始化内容；
- 读/写延迟模型、背靠背与随机延迟；
- 错误注入（地址越界、单/多比特翻转、未初始化读）；
- backdoor 读写（与 RAL predictor 协同）；
- 协议无关，可挂接 APB / AXI / 自定义接口。

## 参考

- [cocotbext-axi Memory Model](https://github.com/alexforencich/cocotbext-axi)（Python，MIT）
