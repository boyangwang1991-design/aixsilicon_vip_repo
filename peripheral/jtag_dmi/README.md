# JTAG/DMI VIP（P1）

JTAG / DMI UVM VIP，VLNV（规划）：`aix:vip:jtag_dmi:1.0.0`。

- 优先级：**P1**
- 状态：规划中

## 计划能力

- TAP 状态机、IR/DR 移位、bypass/idcode 指令；
- DMI request/response（RISC-V Debug）、地址/数据/操作码；
- 超时与错误（非法指令、TCK 约束违反）；
- 参考 OpenTitan `jtag_agent` 与 RISC-V Debug 规范。
