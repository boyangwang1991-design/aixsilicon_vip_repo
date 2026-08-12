# scoreboard — 通用 Scoreboard

通用 Scoreboard 框架与数据比较策略（字段级 compare、masked、order-aware/out-of-order）。

## 能力

- 基于 `vip_common_compare_policy` 的字段级比较；
- transaction ID 关联（OOO 场景）；
- mismatch 可失败并输出原始证据；
- 与各协议 VIP 的 `transaction_ap` 对接。
