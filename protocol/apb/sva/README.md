# SVA — APB 协议属性

存放 APB 协议属性断言（SVA），与 `src/apb_checker.sv` 互补。
SVA 用于 formal 与动态仿真，覆盖时序与稳定性规则：

- PENABLE 不先于 PSEL；
- PADDR/PWRITE/PWDATA 在 setup 阶段保持稳定；
- PREADY 为高时事务在一个周期内完成；
- reset 期间信号保持稳定；
- X/Z 传播检测。

## 文件

- [`apb_checker_assert.sv`](apb_checker_assert.sv) — 协议断言（骨架）
