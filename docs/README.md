# Docs

本目录存放 AIXSILICON VIP Repository 的全部文档，按主题组织。

| 子目录 | 内容 |
|---|---|
| [`architecture/`](architecture/) | 总体架构、实现路线图 |
| [`development-guide/`](development-guide/) | 开发指南、单 VIP 标准模板说明 |
| [`integration-guide/`](integration-guide/) | 在 IP / CBB / Subsystem / SoC 中的集成方法 |

> **质量/方法类内容已收编到私有 skill
> [`vip-repo-maintainer`](../../aixsilicon_skill_repo/skills/vip-repo-maintainer/SKILL.md)**：
> 测试层次、质量 Gate（G0-G9/M0-M5）、第三方准入（G0-G5）、代码规范、六层架构、统一端口、
> 装配流程等见 skill `references/`。仓库内不再重复维护。

## 文档规范

- 文档统一使用中文（简体），术语保留英文；
- 每个正式 VIP 必须提供：`requirements.md`、`architecture.md`、`user_guide.md`、`testplan.md`、`coverage_plan.md`；
- Requirement / Test / Coverage 均使用稳定 ID，并相互建立映射（RTM）。
