# HAC-IF VIP Testbench

> 骨架目录。规划 TB 结构如下，实现待填充。

```text
tb/
├── hac_if_smoke_env.sv     # smoke 环境（CTRL + EVENT 最小组合）
├── hac_if_smoke_tb.sv      # smoke TB
├── hac_if_smoke_test.sv    # smoke test
└── hac_if_regression_env.sv # 回归环境（含 MEM/STREAM/LMEM/Event）
```

- smoke 覆盖 `TEST-HAC-001`（CTRL 单任务正常完成）；
- 回归覆盖 `docs/testplan.md` 中 target=regression 的用例。
