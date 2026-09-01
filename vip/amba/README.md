# vip/amba — AMBA 总线协议 VIP

AMBA 总线/点对点协议 VIP。规划条目（详见 [`registry.yaml`](../registry.yaml)）：

| ID | VIP | Priority | Profile | Status |
|---|---|---|---|---|
| VIP-001 | AXI4 | P0 | FULL_UVM | Developing |
| VIP-002 | AXI4-Lite | P0 | FULL_UVM | Planned |
| VIP-003 | AXI-Stream | P0 | LIGHTWEIGHT | Planned |
| VIP-004 | APB4 | P0 | FULL_UVM | Planned |
| VIP-005 | AHB-Lite | P0 | FULL_UVM | Planned |
| VIP-101 | ACE-Lite | P1 | FULL_UVM | Planned |
| VIP-201 | ACE | P2 | FULL_UVM | Planned |
| VIP-202 | CHI | P2 | FULL_UVM | Planned |

> 各 VIP 除 **VIP-001（AXI4）** 外均处于 `planned` 状态，暂无物理目录。
> **VIP-001（AXI4）** 已在 [`axi4/`](axi4/) 建立开发工程包（`developing` 状态，当前仅 docs/，尚未 Qualified）。
> 各 VIP Qualified 后在此实例化正式工程包。
