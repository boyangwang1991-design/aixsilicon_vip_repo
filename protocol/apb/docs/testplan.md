# APB VIP Testplan

Test ID 前缀：`TEST-APB-`。依据 `schema/testplan.schema.yaml`。

| ID | 名称 | 层次 | Target | Requirement | 状态 |
|---|---|---|---|---|---|
| TEST-APB-001 | 单次写事务 | unit | unit_sim | REQ-APB-001 | planned |
| TEST-APB-002 | 单次读事务 | unit | unit_sim | REQ-APB-001 | planned |
| TEST-APB-003 | Master—Slave loopback | loopback | smoke | REQ-APB-001, REQ-APB-002 | planned |
| TEST-APB-004 | 随机 wait state | stress | regression | REQ-APB-004 | planned |
| TEST-APB-005 | slave error 响应与注入 | checker_negative | negative | REQ-APB-005 | planned |
| TEST-APB-006 | PENABLE 过早断言（checker 检测） | checker_negative | negative | REQ-APB-006 | planned |
| TEST-APB-007 | X/Z 检测 | checker_negative | negative | REQ-APB-006 | planned |
| TEST-APB-008 | timeout 检测 | checker_negative | negative | REQ-APB-006 | planned |
| TEST-APB-009 | RAL frontdoor 读写 | integration | regression | REQ-APB-008 | planned |
| TEST-APB-010 | 多实例（双 master + slave） | integration | regression | REQ-APB-009 | planned |
| TEST-APB-011 | 固定种子可复现 | unit | unit_sim | REQ-APB-010 | planned |
| TEST-APB-012 | mutation（注入时序缺陷，验证 checker） | mutation | regression | REQ-APB-006 | planned |

## YAML 侧载定义（供 testplan_check 消费）

```yaml
# testplan 结构化数据，可放置于 docs/testplan.data.yaml
schema_version: "1.0"
vip_vlnv: aix:vip:apb:1.0.0
tests:
  - { id: TEST-APB-001, name: "单次写事务", level: unit, target: unit_sim, status: planned }
```
