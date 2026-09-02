# AXI4 VIP 集成示例（examples/）

最小集成示例：演示 VIP 作为 master agent 接入用户系统的标准方式。

## 文件

| 文件 | 说明 |
| --- | --- |
| [`axi4_example_top.sv`](axi4_example_top.sv) | 顶层：axi4_if + 时钟复位 + UVM 配置/启动（master+slave 环回） |

## 使用

```bash
# 完整自验证环境（推荐入口，含 9 tier 回归）
make -C ../self_test full

# FuseSoC 方式（smoke 目标）
fusesoc --cores-root .. run --target=smoke aixsilicon:vip:axi4:1.0.0
```

## 集成要点

1. **接口**：实例化 `axi4_if`（参数 ID_WIDTH/ADDRESS_WIDTH/DATA_WIDTH 对齐 HWIF `IFC-AXI-001`）；
2. **配置**：`axi4_configuration` 选 `AXI4_ACTIVE_MASTER`/`AXI4_ACTIVE_SLAVE`/`AXI4_PASSIVE`；
3. **config_db**：`vif`/`master_cfg`/`slave_cfg`/`status` 四项；
4. **测试**：从 `axi4_master_base_seq` 派生用户 sequence（高层 API：`write()/read()/burst_write()`）；
5. **被动监控**：`agent_mode=AXI4_PASSIVE` 时仅 monitor 采样（SoC 集成阶段）。

## 最小 DUT 说明

示例以 VIP 自带 slave（内存 + 响应策略）作为最小 DUT——真实 DUT 集成时将
`slave_agent` 替换为 DUT 的 AXI 接口即可；checker/coverage 连接方式不变。
