# 流程报告

本目录保存七类 AI 结论报告（每类保留最新一份，不建 run-id 子目录）：

| 报告 | 消费入口 |
| --- | --- |
| `requirement.md` | `report-check --kind requirement` |
| `architecture.md` | `report-check --kind architecture` |
| `regression.md` | `report-check --kind regression` |
| `coverage.md` | `coverage-check` |
| `mutation.md` | `mutation-test` |
| `rtm.md` | `report-check --kind rtm` |
| `qualification.md` | `qualify` |

报告使用 `vip.acceptance/v1` metadata 合同；`qualification.md` 额外绑定
`config/release-plan.yaml`（frozen）与 `release_scope`。

原始日志、编译产物、波形、缓存、覆盖率数据库、metadata 抽取副本、机器 Gate 结果
与生成 core 都在本 VIP 的 `build/<run-id>/`，不提交、不上传。报告中的 evidence
路径相对于同 run-id 的 build 运行根（`logs/`、`evidence/`、`coverage/`）。

当前结论（run-004）：七类报告均 PASS；`qualify` 计算 PASS。
未验证能力（Arm 逐规则章节映射、第二仿真器矩阵、1000000 beat 压力规模、
完整能力矩阵）记入 `qualification.md` 的 `known_limitations`，不改变已验证出口范围。
