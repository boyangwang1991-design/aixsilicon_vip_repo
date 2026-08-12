# protocol_properties — 协议属性库

集中存放协议属性断言，供动态仿真（SVA）与 formal 共用。

## 约定

- 属性与 Checker 独立于 driver/monitor 实现，避免共享同一错误假设；
- 每个属性标注：协议条款、Requirement ID、Test ID、Coverage ID；
- 与 `safety/`、`tests/mutation/` 配合验证检测能力。
