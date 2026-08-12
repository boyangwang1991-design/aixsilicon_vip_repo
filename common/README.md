# DV Common（公共底座）

所有 VIP 与项目环境共同依赖的通用 UVM 基类与公共组件，VLNV：`aix:vip:common:1.0.0`。

> 目标：防止各 VIP 重复造轮子。公共组件必须在 `aix:vip:common` 中统一，
> 项目专用 Env / Testcase 不放入本目录。

## 子目录

| 子目录 | 内容 |
|---|---|
| [`vip_common_pkg/`](vip_common_pkg/) | 公共 package 与基类（config / agent / monitor / driver / transaction / compare policy） |
| [`transaction_policy/`](transaction_policy/) | 字段级 compare policy、忽略不稳定字段、masked compare、order-aware compare |
| [`fault_injection/`](fault_injection/) | 统一错误注入基类（interface、campaign、随机注入） |
| [`coverage_utils/`](coverage_utils/) | 覆盖率收集辅助（coverage 合并、门限报告） |
| [`report_adapter/`](report_adapter/) | 日志 / 结果上报适配（与 DVSim / Dashboard 对接） |

## 统一端口（见 `docs/architecture/README.md`）

每个 Monitor 至少提供 `transaction_ap`、`error_ap`，按需提供 `request_ap` / `response_ap` / `performance_ap`。

## Agent 模式

所有协议 Agent 统一支持 `ACTIVE_MASTER` / `ACTIVE_SLAVE` / `PASSIVE` / `DISABLED`，
配置一律通过 config object 传递，禁止依赖全局变量。
