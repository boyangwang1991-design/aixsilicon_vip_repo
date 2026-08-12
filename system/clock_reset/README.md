# Clock/Reset VIP（P0）

通用时钟/复位系统服务 VIP，VLNV（规划）：`aix:vip:clock_reset:1.0.0`。

- 优先级：**P0**（所有环境依赖）
- 状态：规划中（参考 PULP `common_verification`）

## 计划能力

- 多时钟生成（频率、相位、抖动占位）；
- 复位序列（上电、热复位、软件复位）；
- reset glitch 注入、动态频率切换；
- 时钟/复位约束检查与覆盖；
- 与 reset 相关的协议中断（reset 中断事务）。

## 参考

- [PULP common_verification](https://github.com/pulp-platform/common_verification)（含 FuseSoC Core）
