# safety — 功能安全故障注入

本目录存放功能安全（FuSa）故障注入 VIP，用于验证 Safety Mechanism 的检测能力。

| VIP | 目录 | 优先级 | 状态 |
|---|---|---|---|
| Bus Fault | [`bus_fault/`](bus_fault/) | P2 | 规划中 |
| ECC/Parity Fault | [`ecc_parity_fault/`](ecc_parity_fault/) | P2 | 规划中 |
| Interrupt Fault | [`interrupt_fault/`](interrupt_fault/) | P2 | 规划中 |
| Clock/Reset Fault | [`clock_reset_fault/`](clock_reset_fault/) | P2 | 规划中 |
| Fault Campaign | [`fault_campaign/`](fault_campaign/) | P2 | 规划中 |

> 依赖 `common/fault_injection/` 的统一注入框架。
> 所有故障注入必须提供：Fault ID、注入窗口、预期机制、检测时间、覆盖与证据。
