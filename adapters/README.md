# adapters — 适配层

统一第三方 / 交叉验证适配器，隔离不同来源组件，统一 transaction 抽象与结果接口。

| 子目录 | 内容 |
|---|---|
| [`ral/`](ral/) | UVM RAL adapter / predictor 统一封装 |
| [`scoreboard/`](scoreboard/) | 通用 Scoreboard 与 compare policy 适配 |
| [`commercial_vip/`](commercial_vip/) | 商业 VIP 适配（受控内部仓库，遵守许可证） |
| [`cocotb_crosscheck/`](cocotb_crosscheck/) | cocotb 交叉验证模型（oracle / 对拍） |
