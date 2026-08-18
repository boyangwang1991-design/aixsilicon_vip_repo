# AXI4 VIP（P1/P2）

完整 AXI4 UVM VIP，VLNV：`aix:vip:axi:1.0.0`。

- 优先级：**P1（P2 完整化）**
- 状态：**prototype（基于 TVIP-AXI overlay 引入）**

## 来源

本 VIP 基于 [TVIP-AXI](https://github.com/taichi-ishitani/tvip-axi) 引入，采用 overlay 策略：

- **upstream/**：原始 TVIP-AXI 代码（Apache-2.0 许可证）
  - Revision: `cd53d9275610438a1960e967b4b896c816d61ce6`
  - 包含依赖：tue、tvip-common
- **aixsilicon/**：本地 adapter、wrapper、扩展（待开发）
- **tests/**：测试用例与 PoC
- **metadata/**：vip.yaml、provenance.yaml

## 功能特性

- Master and slave agent
- Support AXI4 and AXI4-Lite protocols
- Highly configurable (address width, data width, ID width, etc.)
- Support delayed write data and response
- Support gapped write data and read response
- Response ordering: in-order / out of order
- Support read interleave
- Include UVM RAL adapter and predictor

## 仿真器支持

| 仿真器 | 状态 |
|---|---|
| VCS | beta（已验证） |
| Xcelium | beta |
| Questa | unsupported |
| Verilator | unsupported |

## 快速开始

```bash
cd tests/
make compile
make default
```

## 计划能力

- Burst、ID、Outstanding、乱序、窄传输、非对齐、4KB 边界；
- exclusive / atomic 策略（按首版支持矩阵逐步加入）；
- 高并发 Master 与可编程 Slave responder；
- Memory model 与 scoreboard adapter；
- 性能监测（延迟/带宽/stall）；
- 协议覆盖与大量负向测试；
- 与 PULP AXI 及可用商业 VIP 交叉验证。

## 参考

- [TVIP-AXI](https://github.com/taichi-ishitani/tvip-axi)（Apache-2.0）
- [PULP AXI](https://github.com/pulp-platform/axi)（Solderpad 系）

> 完整 AXI 不应因赶节点而提前标为 Qualified。
