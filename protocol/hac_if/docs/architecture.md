# HAC-IF VIP Architecture

> 依据 [`digest/hwif.md`](../../../../../digest/hwif.md:800) 第 19.1 节验证资产结构。

## 组件结构

```text
hac_if_vip/
├── hac_ctrl_agent
├── hac_stream_agent
├── hac_mem_agent
├── hac_lmem_agent
├── hac_event_agent
├── hac_protocol_checker
├── hac_scoreboard
├── hac_reference_memory
├── hac_error_injector
├── hac_coverage_model
└── hac_virtual_sequence
```

## 层次

- `src/hac_if_pkg.sv`：包入口，`import aix_hac_if_pkg` / `aix_hac_ctrl_pkg` / `aix_hac_mem_pkg` 等；
- `src/hac_ctrl_agent.sv`：任务控制 Agent（cmd/cpl/cancel/status 子组件）；
- `src/hac_mem_agent.sv`：访存 Agent（req/rsp，Tag 关联）；
- `src/hac_protocol_checker.sv`：全局不变量检查；
- `sva/hac_if_assertions.sv`：接口层 SVA 绑定（与 HWIF 的 sva 配套，协议侧在此）；
- `seq/`：各接口族 sequence；
- `tb/`：smoke env 与 test；
- `examples/`：接入示例。

## 模式

- `ACTIVE_CORE`：驱动 HAC Core 侧接口；
- `ACTIVE_SHELL`：驱动 HAC Shell 侧接口（responder）；
- `PASSIVE`：仅采样。

## 集成

- AXI Adapter 一致性：由 `cbb-repo components/hac_if/hac_axi_adapter` + 本 VIP 的 `hac_mem_agent` + AXI VIP 共同搭建。
