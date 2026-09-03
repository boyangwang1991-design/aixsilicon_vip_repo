# APB VIP — Mutation / FI 检出率报告

> 执行: `make -C self_test mutation`（VCS W-2024.09-SP1 / UVM 1.2 / seed=1）· 2026-09-03
> **Case 表 SSOT**: [validation-plan.md §5](../../docs/validation-plan.md)（本文件只记结果）
> 实现: [self_test/apb_fi_test.sv](../../self_test/apb_fi_test.sv)

## 结论

**检出率 5/5 = 100%**（`FI_ALL_DETECTED`）

| Case | 注入 | 检出点 | 检出次数 |
|---|---|---|---|
| FI-001 | extended SETUP | SVA-A1（RUL-001） | 1 |
| FI-002 | 跳过 SETUP 直接 ACCESS | SVA-A2b（RUL-002） | 1 |
| FI-003 | wait 期地址翻转 | SVA-B1（RUL-003） | 21 |
| FI-004 | 读事务非法 PSTRB | SVA-F1（RUL-006） | 1 |
| FI-005 | ACCESS 挂死（wait=20 > timeout=16） | CHK-R9 超时 violation（RUL-009） | 4 |

原始日志：`self_test/build/logs/fi.log`（本报告由 run_log 2026-09-03 记录汇出）。

## anti-overcheck 复归确认

FI 改动后 error tier（UT17/UT18）复归 `UVM_ERROR=0`——未对合法 DUT 行为
（PREADY 常高 during SETUP / PSLVERR 窗外非零）产生误报。

## 检出机制说明

- SVA 检出计数：`apb_if.sva_hit_cnt[rule_id]`（assert fail 时递增）；
- UVM checker 检出计数：`apb_protocol_checker.hit_cnt[rule_id]`（report_violation 递增）；
- 汇总判定：`apb_fi_test.report_phase` 输出 `FI_SUMMARY` + `FI_ALL_DETECTED`。
