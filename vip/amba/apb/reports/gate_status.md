# APB VIP — Gate Status（G0-G6 判定与证据索引）

> **VLNV**: `aixsilicon:vip:apb:1.0.0` · 更新: 2026-09-03
> 本文件是 Gate 判定唯一 SSOT；执行过程证据见 [run_log.md](run_log.md)；
> Limitations 唯一来源 [docs/requirement.md §23](../docs/requirement.md)。

## Gate 判定

| Gate | 判定 | 证据索引 |
|---|---|---|
| G0 Requirement | **PASS** | [requirement.md](../docs/requirement.md) 1.0.0-g0-baseline-r3.1（两轮协议审核闭环，修正记录 §28） |
| G1 Architecture | **PASS** | [architecture.md](../docs/architecture.md) 1.0.0-arch-r4（4 blocker 闭合：ADR-0 两层分离/真单一 monitor/prefetch/response ownership） |
| G2 Code | **PASS** | run_log 2026-09-03：编译零 error + L1 unit **554/554**（types 72 + item 438 + config 44；`make -C self_test unit`） |
| G3 Self-Verification | **PASS** | run_log 2026-09-03：5 tier 全绿 `UVM_ERROR=0`（smoke/feature/corner/error/random）+ anti-overcheck UT17/18 + APB5 专项（UT13/14/20/21）PASS |
| G4 Coverage | **PARTIAL** | [coverage_report.md](coverage/coverage_report.md)：feature=100% / cross=97.2% / assertion=98.6% **PASS**；requirement=98.6% 待 cr_dir_error（WRITE×ABORTED，timing reset 干扰高风险，定性 known-hole） |
| G5 Qualification | **PARTIAL** | mutation 5/5 检出率 100%（[mutation/](mutation/)）；RTM 终审/门禁全项待 G4 收口 |
| G6 Release | NOT_RUN | 待 G4/G5 全绿后 `vip_tool.py gen-core/release` |

## Qualification 剩余项

- [ ] G4：覆盖率收集与 CP-01..08/CR-01..06 闭合（能力开关裁剪后口径）
- [ ] G4：APB5 专项实例（UT13/14/20/21——USER 三宽度/WAKEUP/RME/check_type）
- [ ] G5：rtm.md Result 列按最终回归回填终审
- [ ] G6：`registry.yaml` status → qualified + gen_catalog 刷新 + release 打包

## 已知限制（SSOT：requirement §23）

见 [requirement.md §23](../docs/requirement.md)（LIM-001..005）——本文件不重复。
