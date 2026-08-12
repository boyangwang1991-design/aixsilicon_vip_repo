# 开发指南

本目录面向 VIP 开发工程师，说明如何新增、修改与发布一个 VIP。

## 目录

- 单 VIP 标准模板：见 [`protocol/apb/README.md`](../../protocol/apb/README.md)
- 代码规范：见 [`CONTRIBUTING.md`](../../CONTRIBUTING.md)
- Metadata Schema：见 [`schema/README.md`](../../schema/README.md)

## 新建一个 VIP 的步骤（目标：1 天内跑通 smoke）

1. 复制模板目录（以 `protocol/apb/` 为蓝本）到目标位置（`protocol/`、`peripheral/`、`system/` 或 `safety/`）；
2. 重命名所有文件与内部标识符（`apb_*` → `<vip>_*`），VLNV 改为 `aix:vip:<vip>:1.0.0`；
3. 编写 `metadata/vip.yaml`、`metadata/compatibility.yaml`、`metadata/release_manifest.yaml`；
4. 填充 `docs/requirements.md`、`docs/testplan.md`、`docs/coverage_plan.md` 并建立 ID 映射；
5. 实现 `src/` 下的 item / config / driver / monitor / agent / coverage / checker；
6. 添加 `seq/` 基础序列与 `tests/` 自测；
7. 通过 `tools/metadata_check/` 与 `tools/testplan_check/` 校验；
8. 用 FuseSoC 跑 `unit_sim` / `smoke` target；
9. 提交 PR，进入 Qualification 流程。

## FuseSoC Target 规范

每个 VIP 至少提供（见 `aix_vip_<vip>_1.0.0.core`）：

| Target | 作用 |
|---|---|
| `default` | 作为其他 Core 依赖时提供 package / interface / agent |
| `lint` | 编译结构与静态规则检查 |
| `unit_sim` | VIP 单元测试 |
| `smoke` | 最小 Master—Slave 闭环 |
| `regression` | 标准回归入口 |
| `negative` | 非法时序、错误响应与协议异常测试 |
| `example` | 最小集成示例 |
| `formal` | 协议属性或 Checker 形式验证（可选） |
| `package` | 生成正式发布包 |

## Agent 模式

所有协议 Agent 统一支持 `ACTIVE_MASTER` / `ACTIVE_SLAVE` / `PASSIVE` / `DISABLED`，
可以只启用 Monitor、Checker 或 Coverage；Agent 数量与实例名可配置。

## 统一能力（每个正式 VIP 必须具备）

1. 正常事务生成；2. backpressure 与随机延迟；3. reset 中断事务；4. X/Z 检测策略；
5. timeout 机制；6. 协议错误检测；7. 合法错误响应注入；8. Functional Coverage；
9. RAL 或 Scoreboard 适配；10. 自检测试与最小示例；11. 多实例运行；
12. 固定随机种子可复现；13. 仿真器兼容矩阵；14. 性能开销可测量。
