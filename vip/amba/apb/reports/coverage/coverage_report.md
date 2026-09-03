# APB VIP 覆盖率报告（G4，VCS W-2024.09-SP1 / UVM 1.2）

> 数据来源：`make -C self_test cov`（5 functional tier，功能覆盖取 UVM covergroup
> `get_coverage()`，无 urg/license 依赖）；合并 = 各 tier union（max）。
> 时间戳见各 `build/logs/cov_<tier>.log`。

## 四层覆盖判定

| 层 | 目标 | 合并后 | 判定 |
|---|---|---|---|
| requirement_coverage | 100% | 98.6% | FAIL |
| feature_coverage | 95% | 100.0% | PASS |
| cross_coverage | 90% | 97.2% | PASS |
| assertion_coverage | 95% | 98.6% | PASS |

## 各 coverpoint/cross 合并覆盖率

| 覆盖点 | 层 | smoke | feature | corner | error | random | 合并 |
|---|---|---|---|---|---|---|---|
| assertion_coverage | - |  36 |  36 |  27 |  27 |  71 |  98 | 98% |
| cg_apb | - |  36 |  36 |  27 |  27 |  71 |  98 | 98% |
| cp_addr_region | feature |  33 |  33 |  33 |  33 |  33 | 100 | 100% |
| cp_align | feature |  50 |  50 |  50 |  50 | 100 | 100 | 100% |
| cp_direction | feature | 100 | 100 |  50 |  50 | 100 | 100 | 100% |
| cp_error | feature |  33 |  33 |  33 |  33 |  33 | 100 | 100% |
| cp_pas | feature |   0 |   0 |   0 |   0 |   0 |   0 | 100% |
| cp_pattern | feature |  33 |  33 |  33 |  33 | 100 | 100 | 100% |
| cp_pprot | feature |   0 |   0 |   0 |   0 |  87 | 100 | 100% |
| cp_strb | feature |  40 |  40 |  20 |  20 |  80 | 100 | 100% |
| cp_wait | feature |  20 |  20 |  20 |  20 |  80 | 100 | 100% |
| cr_addr_dir | cross |  33 |  33 |  16 |  16 |  33 | 100 | 100% |
| cr_dir_error | cross |  33 |  33 |  16 |  16 |  33 |  83 | 83% |
| cr_dir_pat | cross |  33 |  33 |  16 |  16 |  83 | 100 | 100% |
| cr_dir_wait | cross |  20 |  20 |  10 |  10 |  70 | 100 | 100% |
| cr_prot_dir | cross |   0 |   0 |   0 |   0 |  68 | 100 | 100% |
| cr_strb_align | cross |  20 |  20 |  10 |  10 |  70 | 100 | 100% |
| cross_coverage | - |  23 |  23 |  11 |  11 |  59 |  97 | 97% |
| feature_coverage | - |  36 |  36 |  27 |  27 |  71 |  98 | 98% |
| requirement_coverage | - |  36 |  36 |  27 |  27 |  71 |  98 | 98% |

## Coverage Hole 分析

| hole | 合并 | 所属层 | 补漏方向 |
|---|---|---|---|
| assertion_coverage | 98% | - | 专项激励 sweep |
| cg_apb | 98% | - | 专项激励 sweep |
| cr_dir_error | 83% | cross | 依赖 dir_error 相关 hole 闭合 |
| cross_coverage | 97% | - | 专项激励 sweep |
| feature_coverage | 98% | - | 专项激励 sweep |
| requirement_coverage | 98% | - | 专项激励 sweep |

## 结论

四层判定：requirement=FAIL / feature=PASS / cross=PASS / assertion=PASS。
未达标层见 hole 分析，补漏后用 `make -C self_test cov` 重跑并更新本报告。
