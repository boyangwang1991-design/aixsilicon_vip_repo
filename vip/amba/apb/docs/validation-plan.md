# AIXSILICON APB VIP — Validation Plan

> **Document ID**: `aixsilicon:vip:apb:val` · 版本: 1.0.0
> **上游输入**: requirement r3.1（G0）/ architecture r4（G1）

---

# 1. 验证策略（三层）

```text
L1 Unit Test      无 UVM golden vector（types/config/位宽/parity）   → G2 门禁
L2 Component Test self_test 回归（smoke/feature/corner/error/random）→ G3 门禁
L3 Qualification  coverage / mutation / RTM / 文档                    → G4/G5 门禁
```

# 2. L1 Unit Test（VAL-001）

| 组 | 覆盖 | 对应 |
|---|---|---|
| wait_bucket | 0/1/2-4/5-15/16+ 分桶 | CP-04 |
| strb_class | none/full/single/contig/sparse | CP-06 |
| aligned | 32/16/8 位宽对齐判定 | TRN-004/CR-04 |
| width_legal | 8/16/32 + 非法 12/64/0/33 拒绝 | CFG-003/004/UT19 |
| pas_space | Secure/NonSecure/Root/Realm | CP-07/PRO-013 |
| parity_group | 全组/末组（addr_width=12）奇校验 | CT-4/CFG-008 |

通过条件：`FAIL_CNT==0`，打印 `UNIT_TEST_PASS`。

# 3. L2 Self Test（VAL-002，UT01-UT22 映射）

| Tier | Tests | UT |
|---|---|---|
| smoke | apb_smoke_test（basic w/r） | UT01/02 |
| feature | apb_feature_test（incrementing + ZERO_WAIT） | UT03/04/11/12 |
| corner | apb_corner_test（FIXED_WAIT=20 长等待） | UT05/06 |
| error | apb_error_test（ADDRESS_RANGE slverr + anti-overcheck） | UT07/15/17/18 |
| random | apb_random_test（RANDOM_WAIT，seed=1） | UT05r |

**anti-overcheck 类别**（UT17/UT18 固化）：PREADY 常高 during SETUP 合法、
PSLVERR 非有效期非零不判 FAIL——若 checker 误报将产生 UVM_ERROR 使 tier 失败。
APB5 专项（UT13/14/20/21）与 UT16 RAL、UT22 X-check 随 APB5 配置实例在
G3 扩展轮执行（本版 filelist 基线为 APB4）。

# 4. 覆盖策略（VAL-003，G4）

* 覆盖层级：Requirement（CP/CR↔REQ/RUL 映射）→ Feature（PRO-001..016）→
  Cross（CR-01..06）→ Assertion（SVA A1/B1/C1/F1/G1/H1）；
* 闭合入口：`make -C self_test cov`（6 functional tier：smoke/feature/corner/
  error/random/sweep）→ `uv run python reports/coverage/coverage_merge.py`
  （union 合并 + 四层判定 + hole 分析；G4 执行）；
* sweep tier（`apb_cov_sweep_test`）：定向打 PSTRB 10 shape / PPROT×R/W /
  地址区域+对齐 / wait 5 桶 / slverr 区 / B2B；
* APB5 专项（`make apb5`，独立 tb5）：闭合 CP-07 cp_pas（PNSE×PPROT[1]
  四 PAS bins）+ USER 三宽度 + WAKEUP + CHK（UT13/14/20/21）；
* ABORTED 覆盖：sweep 带 `+ntb_reset_abort=1` 打断 read（CR-02 read×aborted）；
  完整 reset 场景（UT08-10）为后续扩展项。

# 5. Mutation / Fault Injection（VAL-004，G5）

> FI case 表为本节 SSOT；实现 `self_test/apb_fi_test.sv`；结果 `reports/mutation/`。
> 注入载体：master `inject_*` 字段（ERR-005/006，`allow_protocol_violation=1` 门）。

| Case | Fault | 注入方式 | 期望检出 |
|---|---|---|---|
| FI-001 | SETUP 延长（RUL-001） | `it.inject_extended_setup=1` | SVA-A1 |
| FI-002 | 跳过 SETUP 直接 ACCESS（RUL-002） | `it.inject_illegal_penable=1`（IDLE 直接 ACCESS） | SVA-A2b |
| FI-003 | wait 期地址不稳定（RUL-003） | `it.inject_unstable_addr=1` | SVA-B1 |
| FI-004 | 读事务非法 PSTRB（RUL-006） | `it.inject_illegal_strb=1` | SVA-F1 |
| FI-005 | ACCESS 挂死（RUL-009/TIM-001） | completer FIXED_WAIT=20 > `timeout_cycles=16` | CHK-R9 超时 violation |
| FI-006 | PSLVERR 错误响应路径 | completer ADDRESS_RANGE region（`slave_regions[0].slverr=1`） | 事务级 slverr 传播（UT07） |
| FI-007（反向） | unaligned 地址（TRN-005） | `it.inject_unaligned_addr=1` | **不判 protocol ERROR**（UNPREDICTABLE 分层——验证不误报） |

检出率 = 检出 / 注入，目标 100%（RUL 类）；FI-007 为反向 mutation（验证不过严）。
检出计数机制：SVA 侧 `apb_if.sva_hit_cnt[rule_id]`、UVM checker 侧
`checker.hit_cnt[rule_id]`；汇总判定 `FI_ALL_DETECTED`（见 apb_fi_test）。

# 6. 通过标准

* G2：编译零 error + L1 全绿；
* G3：5 tier 全绿（`UVM_ERROR: 0`）+ anti-overcheck 通过；
* G4：CP-01..08 闭合（能力相关 CP 按配置裁剪后闭合）；
* G5：mutation 检出率 100%（RUL 类）；
* G6：reports/gate_status.md 判定齐备 + README/core 齐备（CHANGELOG 由 release 阶段生成）。
