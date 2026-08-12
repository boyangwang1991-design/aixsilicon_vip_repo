# transaction_policy — 事务策略

统一的数据比较与事务处理策略，避免各 VIP 各自实现不一致的 compare。

## 能力

- 字段级 compare policy；
- 允许忽略不稳定字段（如随机延迟、时间戳）；
- 4-state 严格比较与 2-state 模型比较；
- masked compare（按位屏蔽）；
- order-aware 与 out-of-order compare（结合 transaction ID 关联）；
- mismatch 必须可失败并输出原始证据。

## 使用

参考基类 [`vip_common_pkg/src/vip_common_compare_policy.sv`](../vip_common_pkg/src/vip_common_compare_policy.sv)，
各协议 VIP 通过继承并覆盖 `compare_fields()` 实现协议字段比较。

## 规划文件

- [`src/vip_transaction_policy.sv`](src/vip_transaction_policy.sv) — 策略基类（规划中）
