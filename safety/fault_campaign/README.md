# Fault Campaign（P2）

故障注入战役编排：自动化的故障注入计划、执行与证据收集。

- 优先级：**P2**
- 状态：规划中

## 计划能力

- Fault ID 与命名规范（与 `schema/coverage.schema.yaml` 对齐）；
- 注入窗口（何时注入、持续时间、概率）；
- 预期机制（Expected Mechanism）与检测时间记录；
- 覆盖与证据（每次注入的日志、覆盖率、结果）；
- 自动执行与报告（接入 CI / Nightly 与质量 Dashboard）。

## Schema

Fault Campaign 使用结构化定义，配合 `common/fault_injection/` 统一注入框架。
