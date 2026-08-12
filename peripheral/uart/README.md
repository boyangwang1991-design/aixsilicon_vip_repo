# UART VIP（P1）

UART UVM VIP，VLNV（规划）：`aix:vip:uart:1.0.0`。

- 优先级：**P1**
- 状态：规划中

## 计划能力

- 波特率、数据位（5~8）、校验位（none/even/odd）、stop bit；
- break 检测、framing error、parity error、overrun 检测；
- 发送 / 接收 / Monitor 角色；
- 与真实 UART IP 或 OpenTitan `uart_agent` 架构参考对拍。

## 参考

- [OpenTitan `hw/dv/sv/uart_agent`](https://github.com/lowRISC/opentitan)（Apache-2.0）
