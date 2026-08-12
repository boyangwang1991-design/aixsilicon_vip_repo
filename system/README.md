# system — 系统服务 VIP

本目录存放与具体协议无关的系统服务类 VIP（时钟/复位、中断、存储器、CSR 访问等）。

| VIP | 目录 | 优先级 | 状态 |
|---|---|---|---|
| Clock/Reset | [`clock_reset/`](clock_reset/) | P0 | 规划中 |
| Generic Memory | [`generic_memory/`](generic_memory/) | P0 | 规划中 |
| Interrupt | [`interrupt/`](interrupt/) | P0 | 规划中 |
| CSR Access | [`csr_access/`](csr_access/) | P1 | 规划中 |
| DMA Traffic | [`dma_traffic/`](dma_traffic/) | P2 | 规划中 |
| Boot Host | [`boot_host/`](boot_host/) | P2 | 规划中 |
| Power State | [`power_state/`](power_state/) | P2 | 规划中 |
