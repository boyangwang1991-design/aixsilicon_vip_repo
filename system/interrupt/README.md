# Interrupt VIP（P0）

通用中断系统服务 VIP，VLNV（规划）：`aix:vip:interrupt:1.0.0`。

- 优先级：**P0**（SoC 集成与 PIC 需要）
- 状态：规划中

## 计划能力

- pulse / level 中断建模；
- mask、priority、pending、enable 语义；
- 中断风暴（storm）、丢失/重复中断检测；
- 中断延迟测量（performance event）；
- 与 `safety/interrupt_fault/` 协同（stuck-at、lost、duplicate、late）。
