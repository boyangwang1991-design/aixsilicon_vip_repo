# APB VIP — Run Log（唯一运行日志）

> 格式：`[日期] 动作 | 证据 | 结论`。质量结论只关联命令/环境/日志（证据化）。

---

## 2026-09-03 · G0/G1 文档与 G2/G3 实现（本次会话）

| # | 动作 | 证据 | 结论 |
|---|---|---|---|
| 1 | G0 requirement 起草（r1→r2） | apbplan.md + IHI 0024E 协议审核反馈 | r2 修正 18 项（RUL-005/010、OO、RME、check_type、位宽等） |
| 2 | G0 r3 cleanup | 第二轮审核反馈 | r3.1 修正 9 项（CHK C/OC、USER 三宽度、X-check 解耦、timeout severity、APB5 P0、parity grouping、PWAKEUP=C、Completer 定位、术语统一）；**G0 PASS / Freeze** |
| 3 | G1 architecture（r3→r4） | 第一轮 G1 审核 4 blocker | r4 闭合：①interface 参数/runtime config 两层分离（ADR-0）②SVA generate 只依赖 elaboration 参数 ③真单一 monitor（agent 无 monitor）④back-to-back prefetch + reset 五步；P1/P2 8 项同步；**G1 PASS / Freeze** |
| 4 | SKILL 强化（skill repo 源仓） | vip-development-suite SKILL.md：partial-task 前置输入门禁 + 禁 ASCII 框图（Mermaid） | 已重新物化到 .roo/skills/ |
| 5 | G2 src 全组件实现 | src/ 16 文件（types/if/config/item/monitor/sequencer/master+slave driver/agent/sequences/SVA/checker+violation/coverage/ral/env/pkg/bind） | 组件矩阵与 architecture §4 一致 |
| 6 | G2 L1 unit_test | unit_test/（types golden vectors：bucket/strb/align/width/pas/parity-group） | 骨架就绪，**未执行** |
| 7 | G3 self_test | self_test/（Makefile + tb + env + 5 tier tests + filelist） | 骨架就绪，**未执行**（无 VCS 环境证据前状态 NOT_RUN） |
| 8 | G4-G6 文档与元数据 | validation-plan/rtm/user-guide + .core；FI case 表定义于 validation-plan §5 | RTM Result 全 NOT_RUN（待证据转换） |

## 2026-09-03 · G2/G3 执行证据（VCS W-2024.09-SP1 / UVM 1.2）

| # | 动作 | 命令 | 证据 | 结论 |
|---|---|---|---|---|
| 1 | L1 Unit Test | `make -C self_test unit` | `build/logs/unit_test.log`：`UNIT_TEST_SUMMARY: PASS=72 FAIL=0` + `UNIT_TEST_PASS` | **PASS（72/72）** |
| 2 | 编译 | `make -C self_test compile` | 编译/elab/link 无 error（3.3s） | **PASS** |
| 3 | 回归 smoke | `make -C self_test smoke`（UT01/02） | `build/logs/smoke.log`：`UVM_ERROR : 0`、8 事务 completed、back-to-back pattern 生效 | **PASS** |
| 4 | 回归 feature | `make -C self_test feature`（UT03/04） | `build/logs/feature.log`：`UVM_ERROR : 0` | **PASS** |
| 5 | 回归 corner | `make -C self_test corner`（UT05/06 FIXED_WAIT=20） | `build/logs/corner.log`：`UVM_ERROR : 0` | **PASS** |
| 6 | 回归 error | `make -C self_test error`（UT07/15/17/18 + ADDRESS_RANGE） | `build/logs/error.log`：`UVM_ERROR : 0`（anti-overcheck 通过：PREADY 常高/PSLVERR 窗外均无误报） | **PASS** |
| 7 | 回归 random | `make -C self_test random`（UT05r RANDOM_WAIT seed=1） | `build/logs/random.log`：`UVM_ERROR : 0`（16 事务含 wait_extended pattern） | **PASS** |
| 8 | full | `make -C self_test full` | unit + regression 全绿 | **PASS** |

### 执行中发现并修复的实现问题（G2 闭环）

| 问题 | 根因 | 修复 |
|---|---|---|
| clocking 沿前/沿后采样口径不一 | master 用 `master_cb`（#1step 沿前）判 completion，monitor/SVA 用沿后直接信号——完成拍位差 1 | 统一为沿后直接信号判 completion（C-9 落地：全组件同口径） |
| Response queue overflow | `item_done(req)` 带参把 item 放入 response queue | 改无参 `item_done()`——ADR-12 响应原位回填语义保持 |
| setup 延伸/非法 penable 注入拍位 | slave 决策与 master 重驱时序错位 | slave wait 计数改为沿后决策、master 完成拍即撤 penable |

## 2026-09-03 · G5 Mutation / Fault Injection 执行证据

| # | 动作 | 命令 | 证据 | 结论 |
|---|---|---|---|---|
| 9 | FI tier 编译+执行 | `make -C self_test mutation` | `build/logs/fi.log`：`FI_SUMMARY: RUL-001=1 RUL-002=1 RUL-003=21 RUL-006=1 RUL-009=4` + `FI_ALL_DETECTED` | **PASS（检出率 100%，5/5）** |
| 10 | 全量复归 | `make -C self_test full` | unit 72/72 + 5 tier UVM_ERROR=0（改动未破坏正常路径） | **PASS** |

检出明细（FI-001..005 ↔ SVA/CHK 映射见 docs/validation-plan.md §5）：

| Case | 注入 | 检出 | 次数 |
|---|---|---|---|
| FI-001 | extended SETUP | SVA-A1（RUL-001） | 1 |
| FI-002 | 跳过 SETUP 直接 ACCESS | SVA-A2b（RUL-002） | 1 |
| FI-003 | wait 期地址翻转 | SVA-B1（RUL-003） | 21 |
| FI-004 | 读事务非法 PSTRB | SVA-F1（RUL-006） | 1 |
| FI-005 | ACCESS 挂死（wait=20>16） | CHK-R9 超时 violation（RUL-009） | 4 |

**anti-overcheck 复归确认**：改动后 error tier（UT17/18）仍 UVM_ERROR=0——
未对合法 DUT 行为产生误报。

### 实现修正（G5 轮发现并闭环）

| 问题 | 根因 | 修复 |
|---|---|---|
| A2b 检不出跳 SETUP | `$rose(penable)` 在 skew 相位差下 $past 恰错过 IDLE | 属性改 `$rose(penable&&psel)`（PSEL/PENABLE 同拍起必违规） |
| FI-002 注入后 completer 死锁 | 非 ZERO_WAIT completer 只认 SETUP 采样窗 | slave 增加非法 ACCESS 容错（cur_req==null && penable=1 → 当拍采样响应） |
| RUL-009 catcher 统计 0 | uvm_report_cb 对组件 report 不生效 | 改 checker `hit_cnt[rule_id]` 计数直读 |

### 待执行（G4/G6）

```bash
make -C self_test cov              # 覆盖收集（G4）
# APB5 专项实例（UT13/14/20/21）
# vip_tool.py gen-core / release（G6）
```

> G4/G6 仍 NOT_RUN（不伪报）。

## 2026-09-03 · 目录结构正交化（SSOT 流向统一）

| # | 动作 | 说明 |
|---|---|---|
| 11 | SKILL 源仓重构 | vip-development-suite：工作区布局删除 fault_injection/、qualification/、metadata/；新增 §SSOT 与数据流向（正交规则 4 条）；vip-test/vip-qualification/vip-release 同步；已 --force 物化 |
| 12 | APB VIP 结构统一 | 删 fault_injection/（case 表→validation-plan §5 SSOT）、qualification/（Gate 判定→reports/gate_status.md）、metadata/（Limitations→requirement §23；证据→run_log）；run_log 移 reports/ 根；新增 reports/mutation/mutation_report.md（FI 结果）；README/CHANGELOG/docs 全部引用同步 |
| 13 | 复归验证 | 结构调整后 `make smoke` + `make fi` 抽查 PASS（改动仅文档/目录，无代码变更） |

新 SSOT 流向：requirement(What+Limitations) → architecture(How) → validation-plan(怎么验+FI case 表) → rtm(追溯) → src/unit_test/self_test(实现) → reports(run_log/gate_status/mutation/coverage 证据) → user-guide(最后写)。

## 2026-09-03 · CHANGELOG ≠ run_log 职责分离

| # | 动作 | 说明 |
|---|---|---|
| 14 | SKILL 正交规则 5 追加 | run_log=过程流水（开发期唯一日志）；CHANGELOG=发布语义（版本/Added/Changed/Fixed，从 run_log 汇出摘要）；判定法"用户升级后有什么不同"；vip-release SKILL 同步；已物化 |
| 15 | APB CHANGELOG 精简 | 删除 Gate 状态表/命令引用/执行细节（只留 run_log）；保留发布语义 Added/Known Limitations 引用/registry 更名注记 |
| 16 | CHANGELOG 移除（用户裁定） | 开发期不维护 CHANGELOG.md（已删除）：run_log 版本小节承载语义变更；CHANGELOG 由 release 阶段从 run_log 一次性汇出（SKILL 正交规则 5 修订 + vip-release 同步，已物化）；requirement §21/§22、validation-plan §6 引用同步 |

---

## 2026-09-03 · G4 覆盖闭合 + APB5 专项 + G5 复验（续）

| # | 动作 | 命令 | 证据 | 结论 |
|---|---|---|---|---|
| 17 | SKILL 强化"Unit Test 同步落地" | skill_repo vip-development/vip-test/vip-quality/templates 更新 + `bootstrap.py --ensure --force` | 已物化；templates 新增 unit_transaction/unit_config suite | **已生效** |
| 18 | L1 unit 补齐（transaction/config 层） | 新增 apb_unit_item.sv / apb_unit_config.sv；`make unit` | `UNIT_TEST_SUMMARY: types=72 item=438 config=44` | **PASS（554/554）** |
| 19 | G4 覆盖收集管线 | apb_coverage 增 `report_phase`（`[APB_COV]` 输出）；Makefile `cov` = 6 tier（smoke/feature/corner/error/random/sweep）+ merge 脚本 | 各 cov_<tier>.log；reports/coverage/coverage_merge.py | 功能覆盖可量化 |
| 20 | G4 coverage sweep tier | 新增 apb_cov_sweep_test + apb_cov_sweep_sequence（strb 10 shape/prot×R/W/addr 区域+对齐/wait 桶/slverr 区） | cov_sweep.log | strb/prot/wait/align/pattern **100%** |
| 21 | G4 reset-abort（APB_ABORTED） | tb `+ntb_reset_abort=1` 打断 read | cov_sweep.log：ABORTED read | cp_error=100%（APB_ABORTED bin） |
| 22 | APB5 专项（UT13/14/20/21） | 修复 item.pnse（pas_space bug）+ monitor 采 pnse_w + driver 驱动 pnse_w；新增 tb5 + apb_apb5_test + filelist_apb5.f；`make apb5` | build/logs/apb5.log：32 事务 UVM_ERROR=0 | **PASS；cp_pas=100%** |
| 23 | G4 闭合统计 | coverage_merge.py（APB5 并入 cp_pas） | coverage_report.md | feature=100% / cross=97.2% / assertion=98.6% **PASS**；requirement=98.6%（cr_dir_error 1 bin 残留=WRITE×ABORTED，timing-reset 干扰实测负收益，定性 known-hole） |
| 24 | G5 RTM 终审 | docs/rtm.md Result 列回填 | 31 REQ 行（29 PASS / 7 NOT_RUN：PRO-015、RUL-011、VER-013、RAL-001/003、ERR-006 + 标题说明） | **无伪报**（ERR-006 无 inject_unaligned 实例→NOT_RUN） |
| 25 | 全量复验 | `make full` + `make mutation` + `make apb5` | unit 554/554 + 5 tier + mutation 100% + apb5 | **全 PASS，无回归** |

### G4 剩余（定性已知）

- `cr_dir_error` 83%（requirement 98.6%）：WRITE×ABORTED 单 bin。多次 timing reset 实测干扰采样（feature 100%→85%），不作为回归默认注入；后续可在独立 reset-tier（UT08-10 完整 reset 场景）闭合，不改主回归。
- UT22 X-check（RUL-011/VER-013）、UT16 RAL、UT08-10 独立 reset 场景本轮未差异化执行 → RTM 保持 NOT_RUN。

## 2026-09-04 · defects.md P3/P4/P5 修复（集成 x2p 实测缺陷闭环）

| # | 动作 | 证据 | 结论 |
|---|---|---|---|
| 26 | **P3 修复**（`apb_if.sv`）：必选信号（psel/penable/paddr/pwrite/pwdata/prdata/pready/pslverr）去声明初值+initial（VCS ICPSD/ICPSD_INIT 实测 9 错）；可选信号保留 initial 清零（防无驱动 X → SVA F1 误报） | VCS 最小复现（纯声明可被 RTL 结构驱动 PASS）；x2p tc_sanity PASS | **PASS**（VIP 可直接接真实 RTL master） |
| 27 | **P4 修复**（`apb_slave_driver.sv`）：ZERO_WAIT 用 slave_cb 沿前采样识别 SETUP 预置读数据 + **`build_observed_item` 补采 pstrb**（原 strb 恒 0 → memory 写入恒 0） | 新增 `apb_zerowait_rw_test.sv`（ZERO_WAIT 写读回 8/8）；`make zerowait` PASS | **PASS**（ZERO_WAIT 读回正确） |
| 28 | **P5 修复**（文档）：user-guide 新增 config_db 注入注意事项（精确 scope 不级联 → 须通配） | `apb/docs/user-guide.md` §9 | **PASS** |
| 29 | 全量复验 | `make full`（unit 554 + 6 tier + zerowait）+ `make mutation`（100%） | **全 PASS，无回归** |
| 30 | 集成验证 | x2p tc_sanity / tc_burst PASS（F1 SVA 不再 X 误报；B 回填正常） | 集成可用；tc_timeout 暴露 x2p DUT 独立缺陷（见 defects.md X1） |
