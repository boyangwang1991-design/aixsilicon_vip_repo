# AXI4 VIP 集成反馈（来自 IP：pqc）

> 来源：`aixsilicon_ip_repo/ips/security/crypto/pqc`（PQC 加速器）UVM 集成
> 日期：2026-09-17 · VIP 版本：`aixsilicon:vip:axi4:1.0.0` · 仿真器：VCS W-2024.09-SP1 / UVM 1.2
>
> 本文件由 PQC 集成方记录，供 `vip-development-suite` 修改并回归。

## F-AXI4-01（阻塞级）`virtual axi4_if` 无参数，无法对接非默认位宽的 DUT

**现象**：`axi4_env` / `axi4_master_agent` / `axi4_slave_agent` / 各 driver/monitor
均声明**未参数化**的虚接口：

```systemverilog
virtual axi4_if   vif;                       // axi4_configuration.sv / axi4_monitor.sv 等
uvm_config_db #(virtual axi4_if)::get(...)   // 无参数
```

而 `axi4_if` 是参数化接口（`ID_WIDTH/ADDRESS_WIDTH/DATA_WIDTH/USER_WIDTH`）。
当 DUT 的 AXI4 主机位宽与默认值不同（PQC 为 **DATA_WIDTH=128、ADDRESS_WIDTH=40**）时，
在 harness 中例化 `axi4_if #(.DATA_WIDTH(128), .ADDRESS_WIDTH(40))` 后，
`uvm_config_db#(virtual axi4_if)::set(...)` 与 VIP 内部的
`uvm_config_db#(virtual axi4_if)::get(...)` 是**不同的特化类型**：

```
Error-[ICVITFC] Incompatible virtual interface usage
  harness.u_axi_if 与 apb/axi4 内部形式参数类型不兼容
```

**影响**：VIP 目前只能验证位宽等于默认值的 DUT；128-bit/40-bit AXI4 主机无法接入，
集成方只能放弃 AXI 侧验证（PQC 侧因 DMA 数据通路本身尚未闭合而暂缓，见下）。

**建议**（任一即可）：
- 改为标准做法：VIP 内部使用**参数化虚接口的 typedef 别名**并在 core 中暴露
  `AXI4_DATA_WIDTH` / `AXI4_ADDR_WIDTH` 参数，由其生成 `virtual axi4_if #(...)`；
- 或提供 `axi4_if` 的 `macromodule`/`typedef` 封装层，使 `virtual` 类型与配置一致。

## 已确认工作正常的部分

- `axi4_types_pkg` / `axi4_if` / `axi4_pkg` 的包与接口结构清晰，类型（burst/response/
  protection）语义完整；
- `axi4_memory` 提供的 memory-backed responder 对 slave 侧建模有用；
- `axi4_configuration` 字段命名规范（`address_width`/`data_width`/`agent_mode` 等），
  集成方一次性即可对齐。

> 注：PQC 的 AXI4 侧验证本轮**未启用**——除上述接口限制外，DUT 的
> `input DMA → 算法 → output DMA → completion` 数据通路本身在 RTL 中仍未闭合
> （见 PQC `reports/report.md` ISSUE A03/A11）。用桩响应器强行跑通会产生假通过，
> 因此按"与 RTL 同步延后"处理，待数据通路闭环后再用可参数化的 VIP 接入。