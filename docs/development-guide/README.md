# 开发指南

本目录面向 VIP 开发工程师，说明如何新增、修改与发布一个 VIP。

> **代码规范、统一能力、六层架构等通用方法已收编到私有 skill
> [`vip-repo-maintainer`](../../../aixsilicon_skill_repo/skills/vip-repo-maintainer/references/repository-conventions.md)**
> （`references/repository-conventions.md` §8-§11），不再在仓库内重复维护。

## 目录

- 单 VIP 标准模板：见 [`protocol/apb/README.md`](../../protocol/apb/README.md)
- 代码规范：见 [`CONTRIBUTING.md`](../../CONTRIBUTING.md)
- Metadata Schema：见 [`schema/README.md`](../../schema/README.md)

## 新建一个 VIP 的步骤（目标：1 天内跑通 smoke）

1. 使用 `vip-repo-maintainer` 套件生成骨架（统一入口 `vip_tool.py scaffold`，按 VIP 分类选择
   `uvm`/`lite`/`checker`/`bfm` 模板），或参考 `protocol/apb/` 手动拷贝；
2. 修改生成骨架与描述中的占位符（VLNV 改为 `aixsilicon:vip:<vip>:<semver>`）；
3. 编写 `metadata/vip.yaml`、`metadata/compatibility.yaml`、`metadata/release_manifest.yaml`；
4. 填充 `docs/requirements.md`、`docs/testplan.md`、`docs/coverage_plan.md` 并建立 ID 映射；
5. 实现 `src/` 下的 item / config / driver / monitor / agent / coverage / checker；
6. 添加 `seq/` 基础序列与 `tests/` 自测；
7. 用 `vip_tool.py structure-check / metadata-check / testplan-check` 校验；
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

> 详见 skill [`vip-repo-maintainer`](../../../aixsilicon_skill_repo/skills/vip-repo-maintainer/SKILL.md)
> 的质量/兼容 references 与 `vip_tool.py` 确定性检查。
