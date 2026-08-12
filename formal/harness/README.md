# harness — formal 环境

formal 顶层与环境模板（时钟/复位生成、输入假设、binding 模块）。

## 约定

- 通过 `binding` 或 `assert module` 方式例化属性，不修改 RTL；
- 提供输入假设（assume）与时钟/复位约束；
- 每个 VIP 的 `formal` Target 引用对应 harness。
