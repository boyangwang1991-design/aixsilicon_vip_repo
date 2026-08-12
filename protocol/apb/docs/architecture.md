# APB VIP Architecture

VLNV：`aix:vip:apb:1.0.0`，依赖 `aix:vip:common:^1.0`。

## 组件

```text
apb_agent
├── apb_sequencer        # 事务序列器
├── apb_master_driver    # ACTIVE_MASTER：驱动 PADDR/PWRITE/PENABLE/PSEL，采样 PREADY
├── apb_slave_driver     # ACTIVE_SLAVE：响应读写，返回 wait/error
├── apb_monitor          # 采样总线，广播 transaction_ap / error_ap / performance_ap
├── apb_coverage         # 功能覆盖
├── apb_checker          # 协议时序检查（与 SVA 互补）
└── apb_ral_adapter      # UVM RAL adapter / predictor
```

## 接口

`apb_if` 提供：

- 虚接口信号：`pclk`、`presetn`、`psel`、`penable`、`paddr`、`pwrite`、`pwdata`、`prdata`、`pready`、`pslverr`；
- clocking block（`master_cb` / `slave_cb` / `monitor_cb`）与 modport；
- 事务结构体：`apb_transfer_t`（方向、地址、数据、wait、error）。

## 端口（统一约定）

- `transaction_ap`：完整事务；
- `error_ap`：协议错误与异常事件；
- `performance_ap`：延迟 / stall 性能事件（可选）。

## 设计决策

- 结构与协议差异通过 config object / policy class 表达，不使用编译宏；
- 数据比较使用字段级 compare policy（`vip_common_compare_policy`），禁止只依赖 `uvm_object::compare()`；
- monitor 与 driver 独立实现解析逻辑，避免共享同一个错误假设。
