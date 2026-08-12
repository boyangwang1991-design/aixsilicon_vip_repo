# APB VIP Requirements

Requirement ID 前缀：`REQ-APB-`。状态：`planned` / `implemented` / `verified`。

| ID | 需求 | 状态 |
|---|---|---|
| REQ-APB-001 | 支持 ACTIVE_MASTER 模式，可发起独立读写事务 | planned |
| REQ-APB-002 | 支持 ACTIVE_SLAVE（responder）模式，可响应读写并返回 wait / error | planned |
| REQ-APB-003 | 支持 PASSIVE 模式，仅采样事务并广播到 transaction_ap / error_ap | planned |
| REQ-APB-004 | 支持 wait state（PREADY=0 的随机 backpressure） | planned |
| REQ-APB-005 | 支持 slave error 响应（PSLVERR）与合法错误响应注入 | planned |
| REQ-APB-006 | 提供协议检查（PSEL/PENABLE 时序、setup 阶段、X/Z 检测、timeout） | planned |
| REQ-APB-007 | 提供 Functional Coverage（地址、读写、wait、error 交叉） | planned |
| REQ-APB-008 | 提供 RAL adapter / predictor（frontdoor、backdoor） | planned |
| REQ-APB-009 | 支持多实例运行，实例名可配置 | planned |
| REQ-APB-010 | 支持固定随机种子可复现 | planned |
| REQ-APB-011 | 配置必须通过 config object 传递，禁止全局变量 | planned |
| REQ-APB-012 | 提供自检测试与最小示例（smoke） | planned |

## 协议规范

- 名称：ARM AMBA APB
- 受控版本标识：`IHI 0024H`（APB4）
- 规范正文引用位置：内部受控（不随仓库分发）
