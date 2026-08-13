# protocol — 协议 VIP

本目录存放协议类 VIP（总线与握手协议）。每个 VIP 遵循 [`apb/`](apb/) 标准模板。

| VIP | 目录 | 优先级 | 状态 |
|---|---|---|---|
| APB | [`apb/`](apb/) | P0 | 骨架完成（V0 Prototype） |
| Ready/Valid | [`ready_valid/`](ready_valid/) | P0 | 规划中 |
| HAC-IF | [`hac_if/`](hac_if/) | P0 | 规划中（CTRL/EVENT 先行） |
| AXI4-Lite | [`axi_lite/`](axi_lite/) | P1 | 规划中 |
| AXI4 | [`axi/`](axi/) | P1 | 规划中 |
| AXI-Stream | [`axi_stream/`](axi_stream/) | P1 | 规划中 |
| AHB-Lite | [`ahb_lite/`](ahb_lite/) | P1 | 规划中 |

> 新建 VIP：复制 `apb/` 模板并全局重命名，或使用
> `tools/vip_new/generate_vip.py`（见 [`tools/`](../tools/)）。
