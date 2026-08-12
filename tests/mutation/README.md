# mutation — Mutation 测试

人为注入 DUT 或 VIP 缺陷，验证 Checker / Coverage 的检测能力。

- 时序缺陷注入（setup 违反、过早响应）；
- 数据损坏注入；
- 协议错误注入；
- 每次 mutation 必须被至少一个 Checker / SVA 检测（0 逃逸目标）；
- 结果纳入 Qualification 证据。
