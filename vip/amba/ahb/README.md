# AHB UVM VIP — 0.1.0 开发版本

开发目录位于 `aixsilicon_vip_repo/vip/amba/ahb`。基于相邻 `ahb_contract.md` 实现，使用 vip-development-suite；当前不是全规格认证的 1.0.0 发布。

已实现参数化 interface、Manager/Subordinate/Passive agent、独立 monitor/checker、流水驱动、burst、memory/reservation、AHB5 strobe/USER/parity、经典仲裁及 RETRY/SPLIT、RAL、scoreboard 和自验证工程。实际支持范围与缺口见 [逐项 RTM](docs/rtm.md) 和 [用户指南](docs/user-guide.md)。

从本目录运行（使用 workflow 根 uv 环境；需要 VCS/UVM1.2 许可证）：

```bash
uv run --no-sync python tools/run.py full
uv run --no-sync python tools/run.py stress --seed 1 --count 500000
uv run --no-sync python tools/seed_matrix.py
uv run --no-sync python tools/mutate.py
uv run --no-sync fusesoc --cores-root=. run --target=smoke --tool=vcs aixsilicon:vip:ahb:0.1.0
```

`full` 是13组开发回归；合同发布矩阵另见 `config/regression.yaml`。完整发布还需要补齐实现缺口、强制覆盖和跨工具认证。源文件必须按core顺序编译；class文件由package include。

- [回归结果](reports/regression/regression_summary.yaml)、[变异结果](reports/mutation/mutation_summary.yaml)、[认证结果](reports/qualification_summary.yaml)
- [运行记录](reports/run_log.md)、[Skill优化报告](reports/skill-improvement-report.md)（SK-009记录开发目录规则）
- [需求](docs/requirement.md)、[架构](docs/architecture.md)、[验证计划](docs/validation-plan.md)
