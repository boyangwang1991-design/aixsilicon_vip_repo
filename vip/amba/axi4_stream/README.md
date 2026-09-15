# axi4_stream VIP

AMBA AXI4-Stream（ARM IHI 0051A）可复用验证组件。

| 项目 | 值 |
|---|---|
| VLNV | `aixsilicon:vip:axi4_stream:1.0.0` |
| Profile | `FULL_UVM`（同时支持 PASSIVE agent 角色与 CHECKER_ONLY 独立构建） |
| Category | `amba` |
| 角色 | Source（主动激励）、Sink（背压接收）、Passive（只观测） |
| 基线 | UVM 1.2；已验证仿真器 VCS W-2024.09-SP1 |

> 本目录是源码开发资产。G0–G5 阶段报告均为有效 PASS（见 `reports/`，run-004）；
> 范围外未验证能力（Arm 逐规则章节映射、第二仿真器矩阵等）记入
> `reports/qualification.md` 的 `known_limitations`，不构成协议认证。

## 目录

| 路径 | 用途 |
|---|---|
| `docs/requirement.md` | 需求规格（源自 `../axi_stream_vip_contract.md`，90 条 REQ） |
| `docs/architecture.md` | 架构与设计（组件矩阵、时序 skew、ADR） |
| `docs/validation-plan.md` | 验证策略与退出判据 |
| `docs/rtm.md` | 设计期需求追溯（逐 ID） |
| `docs/user-guide.md` | 参数、角色、API、诊断与限制 |
| `config/requirements.yaml` | 权威 REQ ID 清单 |
| `config/verification-plan.yaml` | 冻结 case/priority 与四项 coverage bin 清单 |
| `config/qualification.yaml` | 覆盖阈值（只能更严格） |
| `config/release-plan.yaml` | 版本验收承诺（frozen）：release_scope + 16 项 acceptance_items |
| `config/build.yaml` | FuseSoC filesets/targets（含 `checker_only`） |
| `src/` | UVM 类库、参数化 interface、checker/SVA、语义模型、序列库 |
| `unit_test/` | L1 golden vector（semantic/transaction/config/checker） |
| `self_test/` | 独立 DUT fixture、自验证环境、10 个 tier、Makefile |
| `examples/` | 集成示例与最小示例环境 |
| `tools/mutate.py` | 源码变异验证（隔离副本内执行） |
| `tools/structural_check.py` | 静态结构检查（REQ-CHK-004 的结构性补充证据） |
| `tools/seed_matrix.py` | 多 seed 矩阵（REQ-ACC-005，每 tier 编译一次后重复运行） |
| `tools/coverage_merge.py` | 覆盖 bin 归集（bin→hit 完整映射） |
| `aixsilicon_vip_axi4_stream_1.0.0.core` | FuseSoC CAPI=2 交付 |
| `reports/<kind>.md` | 七类 AI 结论报告（requirement/architecture/regression/coverage/mutation/rtm/qualification） |

## 运行

```bash
# 编译与 L1 golden vector
make -C self_test unit BUILD_DIR=$PWD/build/dev LOG_DIR=$PWD/build/dev/logs SEED=1
# 端到端（source -> register slice -> sink，含 scoreboard 比较）
make -C self_test smoke BUILD_DIR=$PWD/build/dev LOG_DIR=$PWD/build/dev/logs SEED=1
# 自定义（unit + 全部 tier + cdc + structural + mutation + coverage + seed_matrix）
make -C self_test regression BUILD_DIR=$PWD/build/dev LOG_DIR=$PWD/build/dev/logs SEED=1
# FuseSoC
fusesoc run --target=checker_only aixsilicon:vip:axi4_stream:1.0.0
```

测试 tier：`smoke`、`feature`、`corner`、`random`、`stress`、`config`、`passive`、
`reset`、`perf`、`cancel`、`sched`、`cdc`、`inject`（负向）、`checker_only`；
辅助目标：`structural`、`mutation`、`coverage`、`seed_matrix`。
`stress` 规模由 `+AXIS_STRESS_BEATS` 控制；多 seed 矩阵由 `SEED_TIERS` 选择 tier。

## 运行纪律

* 所有日志、编译中间产物、覆盖数据库、抽取 metadata、机器 Gate、生成 core 与
  本地候选包都写入 **本 VIP 的 `build/<run-id>`**，不提交、不上传。
* `reports/<run-id>` 保留流程报告；原始运行证据不混入 reports。
* 每次正式执行使用新的 run-id；源码/配置/计划或证据变化后必须重跑，不能沿用旧 Gate。

## 当前状态（run-004）

| 报告 | 计算状态 |
|---|---|
| requirement（G0 本范围） | PASS |
| architecture（G1 本范围） | PASS |
| regression（G2/G3） | PASS（compile + unit + 15 tier + checker_only + structural + seed_matrix 60/60） |
| coverage（G4） | PASS（四项 bin 集合与计划一致、命中率 100%） |
| mutation | PASS（12/12，P0 全命中） |
| rtm | PASS（90 条 REQ 逐 ID 映射） |
| qualification（G5） | PASS（16 项版本承诺全部满足） |

证据根：`build/run-004/`。范围外未验证能力见
`reports/qualification.md` 的 `known_limitations`。
