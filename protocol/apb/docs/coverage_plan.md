# APB VIP Coverage Plan

Coverage ID 前缀：`COV-APB-`。依据 `schema/coverage.schema.yaml`。

| ID | 名称 | 覆盖点 | Requirement | Test |
|---|---|---|---|---|
| COV-APB-001 | 地址覆盖 | 地址空间分段（低位/高位/边界） | REQ-APB-001 | TEST-APB-001,002 |
| COV-APB-002 | 读写交叉 | write × read × transfer | REQ-APB-001 | TEST-APB-001,002 |
| COV-APB-003 | wait 状态覆盖 | wait 次数 0/1/2/多拍 | REQ-APB-004 | TEST-APB-004 |
| COV-APB-004 | error 响应覆盖 | OKAY/ERROR、注入时机 | REQ-APB-005 | TEST-APB-005 |
| COV-APB-005 | 协议异常覆盖 | 非法 PENABLE、X/Z、timeout | REQ-APB-006 | TEST-APB-006,007,008 |

## 命中门限

- 每覆盖组目标命中率：100%（正式 Gate 前按协议确定门限）；
- 覆盖点命名遵循 `vip_coverage_utils` 的登记规范，便于 merge 与导出。
