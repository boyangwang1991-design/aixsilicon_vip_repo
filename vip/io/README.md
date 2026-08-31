# vip/io — 网络 / IO 协议 VIP

网络/IO 协议 VIP。规划条目（详见 [`registry.yaml`](../registry.yaml)）：

| ID | VIP | Priority | Profile | Status |
|---|---|---|---|---|
| VIP-117 | Ethernet MAC | P1 | FULL_UVM | Planned |
| VIP-118 | MDIO | P1 | LIGHTWEIGHT | Planned |
| VIP-203 | PCIe | P2 | FULL_UVM | Planned |
| VIP-204 | USB | P2 | FULL_UVM | Planned |
| VIP-205 | MIPI CSI/DSI | P2 | FULL_UVM | Planned |

> 复杂标准协议（PCIe/USB/MIPI）不一定要自行开发完整 commercial-grade VIP，
> 视项目需要决定自研范围或引入第三方（经 provenance 流程）。
> 各 VIP 处于 `planned` 状态，暂无物理目录。
