# report_adapter — 日志与结果上报适配

统一的日志、结果与 Evidence 上报接口。

## 能力

- 统一日志格式（含 VIP VLNV、组件、severity）；
- 结果上报到 DVSim / Dashboard / Catalog 可消费的结构化数据；
- Evidence 记录（seed、工具版本、源码 hash、日志 hash）用于 Release Manifest。

## 规划文件

- [`src/vip_report_adapter.sv`](src/vip_report_adapter.sv) — 上报适配器（规划中）
