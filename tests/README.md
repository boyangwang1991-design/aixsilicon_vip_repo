# tests — 测试体系

按计划第 10.1 节的测试层次组织的统一测试目录（跨 VIP 的公共测试与工具）。

| 子目录 | 层次 |
|---|---|
| [`unit/`](unit/) | 组件单元测试（transaction / config / sequence / driver / monitor） |
| [`compatibility/`](compatibility/) | 多仿真器 / 多 DUT 兼容性测试 |
| [`negative/`](negative/) | Checker 负向测试（每类协议错误都能被检测） |
| [`stress/`](stress/) | 长时间、随机 stall、多 Outstanding、reset 打断 |
| [`mutation/`](mutation/) | Mutation 测试（注入 DUT / VIP 缺陷验证检测能力） |

> 各 VIP 自己的测试放在 `protocol/<vip>/tests/`；本目录存放公共测试框架与工具。
