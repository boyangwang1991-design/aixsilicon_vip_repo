# 协议规则矩阵

现有规则注册表为 config/checkers.yaml，具体条件见 src/checker/ahb_checker.sv。

历史输入记录 S1 为 IHI0033C，S2 为 B.b，S3 为 IHI0011A。现有测试覆盖部分实现，尚未完成全部规范全文核对，不据 Issue C 结果声明 B.b/Classic 完整兼容。

等待例外和响应规则使用独立向量；parity 分组尾宽和逐组负向验收仍需补齐。环境 watchdog 与能力策略单独分类。
