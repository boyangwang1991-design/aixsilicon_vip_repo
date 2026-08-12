# APB VIP

APB（Advanced Peripheral Bus）UVM VIP，VLNV：`aix:vip:apb:1.0.0`。

> 本目录同时作为 **VIP 标准模板**，新建 VIP 时复制本目录并全局重命名 `apb_*` → `<vip>_*`，
> 参考 [`docs/development-guide/README.md`](../../docs/development-guide/README.md)。

## 功能

- 支持 `ACTIVE_MASTER` / `ACTIVE_SLAVE` / `PASSIVE` / `DISABLED` 模式；
- 独立读写、wait state、slave error 响应、backpressure（wait）；
- RAL adapter / predictor（frontdoor、backdoor）；
- Protocol Checker（地址/数据时序、PSEL/PENABLE 协议、X/Z 检测、timeout）；
- Functional Coverage 与 Scoreboard 适配；
- 固定随机种子可复现，支持多实例。

## 目录结构

```text
protocol/apb/
├── README.md
├── docs/          # requirements / architecture / user_guide / testplan / coverage_plan
├── metadata/      # vip.yaml / compatibility.yaml / release_manifest.yaml
├── src/           # apb_pkg / apb_if / item / config / agent / sequencer / driver / monitor / coverage / checker / ral_adapter
├── sva/           # 协议属性与 checker 断言
├── seq/           # base / normal / stress / negative 序列
├── tb/            # 自测 testbench
├── tests/         # 测试用例
├── examples/      # 最小集成示例
├── aix_vip_apb_1.0.0.core
└── CHANGELOG.md
```

## FuseSoC Target

| Target | 说明 |
|---|---|
| `default` | 提供 package / interface / agent |
| `lint` | 静态检查 |
| `unit_sim` | 单元测试 |
| `smoke` | 最小 Master—Slave 闭环 |
| `regression` | 标准回归 |
| `negative` | 协议异常 / 错误响应测试 |
| `example` | 最小集成示例 |
| `formal` | 协议属性形式验证（可选） |
| `package` | 生成发布包 |

## 文档

- 需求：[`docs/requirements.md`](docs/requirements.md)
- 架构：[`docs/architecture.md`](docs/architecture.md)
- 用户指南：[`docs/user_guide.md`](docs/user_guide.md)
- 测试计划：[`docs/testplan.md`](docs/testplan.md)
- 覆盖计划：[`docs/coverage_plan.md`](docs/coverage_plan.md)
