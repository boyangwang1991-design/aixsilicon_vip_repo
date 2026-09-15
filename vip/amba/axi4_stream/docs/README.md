# docs/ — VIP 文档

VIP 文档脉络（每个主题一份完整模板，scaffold 实例化后由对应子 skill 填充）：

| 文档 | 内容 | 生成方 |
| --- | --- | --- |
| [`requirement.md`](requirement.md) | 需求规格（Feature/Protocol Rules/Config Space/Qualification Req） | vip-requirement |
| [`architecture.md`](architecture.md) | 架构与设计（Profile/组件/三大模型/接口时序/错误处理） | vip-architecture / vip-development |
| [`validation-plan.md`](validation-plan.md) | 验证/自验证方案 + 五层覆盖模型 | vip-test / vip-coverage |
| [`rtm.md`](rtm.md) | 需求追溯矩阵（Req→Impl→Checker→Test→Coverage→Result） | vip-qualification |
| [`user-guide.md`](user-guide.md) | 用户指南（使用/配置/接口信号/限制） | vip-release |

```text
requirement → architecture → validation-plan → rtm（开发闭环）
                              ↘ user-guide（交付）
README.md（项目根总览） + reports/（Gate 与认证证据唯一出口）
```
