# SPI/QSPI VIP（P1）

SPI / QSPI UVM VIP，VLNV（规划）：`aix:vip:spi:1.0.0`。

- 优先级：**P1**
- 状态：规划中

## 计划能力

- Mode 0~3、bit order（LSB/MSB first）、chip select 管理；
- single / dual / quad 数据线；
- 帧/命令/地址/数据阶段建模；
- 错误注入（协议违规、相位错误、超时）；
- 参考 OpenTitan `spi_agent`。
