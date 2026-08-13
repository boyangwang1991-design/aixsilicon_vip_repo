# HAC-IF VIP Testplan

Test ID 前缀：`TEST-HAC-`。依据 `schema/testplan.schema.yaml`。

| ID | 名称 | 层次 | Target | Requirement | 状态 |
|---|---|---|---|---|---|
| TEST-HAC-001 | CTRL 单任务正常完成 | unit | unit_sim | REQ-HAC-001, REQ-HAC-002 | planned |
| TEST-HAC-002 | CTRL 连续 Back-to-back 任务 | stress | regression | REQ-HAC-004 | planned |
| TEST-HAC-003 | CTRL 多任务与 Job ID 关联 | unit | unit_sim | REQ-HAC-009 | planned |
| TEST-HAC-004 | CTRL 完成通道背压 | stress | regression | REQ-HAC-009 | planned |
| TEST-HAC-005 | CTRL Busy 期间取消 | unit | unit_sim | REQ-HAC-001 | planned |
| TEST-HAC-006 | CTRL Reset/Drain 在各执行阶段 | integration | regression | REQ-HAC-006 | planned |
| TEST-HAC-007 | CTRL 非法 Opcode 和 Descriptor | checker_negative | negative | REQ-HAC-009 | planned |
| TEST-HAC-008 | MEM 单 Beat 和多 Beat 读写 | unit | unit_sim | REQ-HAC-006 | planned |
| TEST-HAC-009 | MEM 最大长度、4KB 边界和非对齐 | stress | regression | REQ-HAC-006 | planned |
| TEST-HAC-010 | MEM 多 Tag Outstanding | stress | regression | REQ-HAC-006, REQ-HAC-012 | planned |
| TEST-HAC-011 | MEM 跨 Tag 乱序、Tag 内保序 | checker_positive | regression | REQ-HAC-009 | planned |
| TEST-HAC-012 | MEM 数据与响应背压 | stress | regression | REQ-HAC-006 | planned |
| TEST-HAC-013 | MEM AXI Decode/Slave 错误映射 | checker_negative | negative | REQ-HAC-011 | planned |
| TEST-HAC-014 | MEM 超时、丢响应、重复响应 | checker_negative | negative | REQ-HAC-011 | planned |
| TEST-HAC-015 | STREAM 连续满吞吐 | unit | unit_sim | REQ-HAC-005 | planned |
| TEST-HAC-016 | STREAM 随机背压 | stress | regression | REQ-HAC-005 | planned |
| TEST-HAC-017 | STREAM 部分 keep 与包边界 | unit | unit_sim | REQ-HAC-005 | planned |
| TEST-HAC-018 | STREAM 多 ID 交织规则 | unit | unit_sim | REQ-HAC-005 | planned |
| TEST-HAC-019 | MGMT Drain 与 Quiescent | integration | regression | REQ-HAC-009 | planned |
| TEST-HAC-020 | ECC Correctable/Uncorrectable | unit | unit_sim | REQ-HAC-007 | planned |
| TEST-HAC-021 | Fatal 状态及错误证据保持 | checker_negative | negative | REQ-HAC-008 | planned |
| TEST-HAC-022 | AXI Adapter 一致性验证 | integration | regression | REQ-HAC-014 | planned |
| TEST-HAC-023 | Profile P0/P1/P2 虚拟序列 | integration | regression | REQ-HAC-013 | planned |
| TEST-HAC-024 | mutation（注入握手缺陷，验证 checker） | mutation | regression | REQ-HAC-009 | planned |

## YAML 侧载定义（供 testplan_check 消费）

```yaml
# testplan 结构化数据，可放置于 docs/testplan.data.yaml
schema_version: "1.0"
vip_vlnv: aix:vip:hac_if:1.0.0
tests:
  - { id: TEST-HAC-001, name: "CTRL 单任务正常完成", level: unit, target: unit_sim, status: planned }
```
