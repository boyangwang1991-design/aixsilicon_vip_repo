# testplan_check — Testplan / Coverage / RTM 校验

校验 testplan 与 coverage 定义，并检查 Requirement / Test / Coverage ID 的 RTM 一致性。

## 用法

```bash
python3 tools/testplan_check/check_testplan.py protocol/apb/docs/testplan.md
python3 tools/testplan_check/check_testplan.py --all
```

## 校验项

- Test ID（`TEST-<VIP>-NNN`）唯一；
- Coverage ID（`COV-<VIP>-NNN`）唯一；
- Test 引用的 Requirement ID 存在于 `requirements.md`；
- Coverage 引用的 Requirement / Test ID 存在；
- 所有正式 VIP 必须具备 requirements / testplan / coverage_plan 三份文档。
