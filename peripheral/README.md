# peripheral — 外设 VIP

本目录存放外设协议类 VIP。每个 VIP 遵循 [`protocol/apb/`](../protocol/apb/) 标准模板。

| VIP | 目录 | 优先级 | 状态 |
|---|---|---|---|
| UART | [`uart/`](uart/) | P1 | 规划中 |
| SPI/QSPI | [`spi/`](spi/) | P1 | 规划中 |
| I2C | [`i2c/`](i2c/) | P1 | 规划中 |
| GPIO | [`gpio/`](gpio/) | P2 | 规划中 |
| JTAG/DMI | [`jtag_dmi/`](jtag_dmi/) | P1 | 规划中 |

> 外设 VIP 建议复用 OpenTitan Agent 架构，但剥离 TL-UL 与 CIP 耦合。
