# vip_common_pkg — `aix:vip:common`

公共 package 与基类，所有 VIP 共同依赖。

## 内容

| 文件 | 说明 |
|---|---|
| [`src/vip_common_pkg.sv`](src/vip_common_pkg.sv) | 公共包：agent 模式枚举、config 基类 |
| [`src/vip_common_transaction.sv`](src/vip_common_transaction.sv) | 事务基类（pack/unpack/打印/ID 关联） |
| [`src/vip_common_monitor.sv`](src/vip_common_monitor.sv) | Monitor 基类（统一 analysis port） |
| [`src/vip_common_agent.sv`](src/vip_common_agent.sv) | Agent 基类（按 mode 装配） |
| [`src/vip_common_compare_policy.sv`](src/vip_common_compare_policy.sv) | 字段级比较策略 |

## 依赖

- UVM（IEEE 1800.2 / UVM 1.2 兼容基线）

## Target

| Target | 说明 |
|---|---|
| `default` | 提供 package / 基类供其他 Core 依赖 |
| `lint` | 静态检查 |
| `unit_sim` | 公共组件单元测试 |
