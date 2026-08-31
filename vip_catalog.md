# AIXSILICON VIP Catalog

> 由 `tools/gen_catalog.py` 依据 `registry.yaml`（SSOT）自动生成；勿手工编辑。
> 最后更新：`2026-08-31T00:00:00Z`

完整 VIP 明细（52 条），按类别分组。

## vip/amba（8）

| ID      | VIP        | 名称       | Profile     | 优先级 | HWIF       | 状态    | 质量(M/Qual) | 版本 | 描述                                                                           |
|---------|------------|------------|-------------|--------|------------|---------|--------------|------|--------------------------------------------------------------------------------|
| VIP-001 | axi4       | AXI4       | FULL_UVM    | P0     | axi4       | planned | M0 / NOT_RUN | -    | Master/Slave/Monitor/Checker/Coverage、outstanding、out-of-order、4KB boundary |
| VIP-002 | axi4_lite  | AXI4-Lite  | FULL_UVM    | P0     | axi4_lite  | planned | M0 / NOT_RUN | -    | Master/Slave/Monitor/Checker                                                   |
| VIP-003 | axi_stream | AXI-Stream | LIGHTWEIGHT | P0     | axi_stream | planned | M0 / NOT_RUN | -    | Source/Sink/Monitor/Packet Check、TKEEP/TLAST                                  |
| VIP-004 | apb4       | APB4       | FULL_UVM    | P0     | apb4       | planned | M0 / NOT_RUN | -    | Master/Slave/Monitor/Checker、wait state、slave error                          |
| VIP-005 | ahb_lite   | AHB-Lite   | FULL_UVM    | P0     | ahb_lite   | planned | M0 / NOT_RUN | -    | Master/Slave/Monitor/Checker、burst、split                                     |
| VIP-101 | ace_lite   | ACE-Lite   | FULL_UVM    | P1     | ace_lite   | planned | M0 / NOT_RUN | -    | Coherency-lite transaction verification                                        |
| VIP-201 | ace        | ACE        | FULL_UVM    | P2     | ace        | planned | M0 / NOT_RUN | -    | Cache coherency verification                                                   |
| VIP-202 | chi        | CHI        | FULL_UVM    | P2     | chi        | planned | M0 / NOT_RUN | -    | Coherent hub interface verification                                            |

## vip/chip（11）

| ID      | VIP              | 名称              | Profile     | 优先级 | HWIF        | 状态    | 质量(M/Qual) | 版本 | 描述                                        |
|---------|------------------|-------------------|-------------|--------|-------------|---------|--------------|------|---------------------------------------------|
| VIP-014 | interrupt        | Generic Interrupt | LIGHTWEIGHT | P0     | interrupt   | planned | M0 / NOT_RUN | -    | IRQ generation/priority/masking             |
| VIP-015 | clock            | Clock             | LIGHTWEIGHT | P0     | clock       | planned | M0 / NOT_RUN | -    | Clock generation/jitter/frequency change    |
| VIP-016 | reset            | Reset             | LIGHTWEIGHT | P0     | reset       | planned | M0 / NOT_RUN | -    | POR/warm reset/reset sequencing             |
| VIP-017 | clock_reset      | Clock Reset       | LIGHTWEIGHT | P0     | clock_reset | planned | M0 / NOT_RUN | -    | CRG combined stimulus/check                 |
| VIP-018 | dma_traffic      | DMA Traffic       | LIGHTWEIGHT | P0     | dma         | planned | M0 / NOT_RUN | -    | Configurable traffic generation             |
| VIP-108 | plic             | PLIC              | FULL_UVM    | P1     | plic        | planned | M0 / NOT_RUN | -    | RISC-V interrupt controller verification    |
| VIP-109 | gic              | GIC               | FULL_UVM    | P1     | gic         | planned | M0 / NOT_RUN | -    | ARM interrupt subsystem verification        |
| VIP-110 | mailbox          | Mailbox           | LIGHTWEIGHT | P1     | mailbox     | planned | M0 / NOT_RUN | -    | Core-to-core message verification           |
| VIP-111 | power_control    | Power Control     | MODEL       | P1     | power       | planned | M0 / NOT_RUN | -    | Power state/isolation/retention             |
| VIP-112 | dvfs             | DVFS              | MODEL       | P1     | dvfs        | planned | M0 / NOT_RUN | -    | Voltage-frequency state transition modeling |
| VIP-113 | descriptor_model | Descriptor Model  | LIGHTWEIGHT | P1     | descriptor  | planned | M0 / NOT_RUN | -    | Descriptor chain/ring behavior              |

## vip/common（4）

| ID      | VIP                 | 名称                   | Profile     | 优先级 | HWIF   | 状态    | 质量(M/Qual) | 版本 | 描述                                            |
|---------|---------------------|------------------------|-------------|--------|--------|---------|--------------|------|-------------------------------------------------|
| VIP-019 | csr_access          | Generic Register / CSR | FULL_UVM    | P0     | csr    | planned | M0 / NOT_RUN | -    | Read/write/access-type checking、CSR/RAL access |
| VIP-020 | generic_stream      | Generic Stream         | LIGHTWEIGHT | P0     | stream | planned | M0 / NOT_RUN | -    | Generic valid-ready stream、packet source/sink  |
| VIP-122 | scoreboard_model    | Scoreboard Model       | MODEL       | P1     | -      | planned | M0 / NOT_RUN | -    | Generic transaction compare                     |
| VIP-123 | performance_monitor | Performance Monitor    | PASSIVE     | P1     | -      | planned | M0 / NOT_RUN | -    | Latency/bandwidth/outstanding statistics        |

## vip/debug（3）

| ID      | VIP         | 名称         | Profile  | 优先级 | HWIF        | 状态    | 质量(M/Qual) | 版本 | 描述                          |
|---------|-------------|--------------|----------|--------|-------------|---------|--------------|------|-------------------------------|
| VIP-114 | jtag        | JTAG         | FULL_UVM | P1     | jtag        | planned | M0 / NOT_RUN | -    | TAP state/IR/DR/boundary scan |
| VIP-115 | swd         | SWD          | FULL_UVM | P1     | swd         | planned | M0 / NOT_RUN | -    | ARM serial debug              |
| VIP-116 | riscv_debug | RISC-V Debug | FULL_UVM | P1     | riscv_debug | planned | M0 / NOT_RUN | -    | DMI/debug module interaction  |

## vip/io（5）

| ID      | VIP          | 名称         | Profile     | 优先级 | HWIF    | 状态    | 质量(M/Qual) | 版本 | 描述                                |
|---------|--------------|--------------|-------------|--------|---------|---------|--------------|------|-------------------------------------|
| VIP-117 | ethernet_mac | Ethernet MAC | FULL_UVM    | P1     | eth_mac | planned | M0 / NOT_RUN | -    | Frame generate/monitor/CRC          |
| VIP-118 | mdio         | MDIO         | LIGHTWEIGHT | P1     | mdio    | planned | M0 / NOT_RUN | -    | PHY management                      |
| VIP-203 | pcie         | PCIe         | FULL_UVM    | P2     | pcie    | planned | M0 / NOT_RUN | -    | TLP/DLLP/link behavior              |
| VIP-204 | usb          | USB          | FULL_UVM    | P2     | usb     | planned | M0 / NOT_RUN | -    | Endpoint/transfer/protocol checking |
| VIP-205 | mipi         | MIPI CSI/DSI | FULL_UVM    | P2     | mipi    | planned | M0 / NOT_RUN | -    | Packet/lane behavior                |

## vip/memory（6）

| ID      | VIP            | 名称                 | Profile     | 优先级 | HWIF   | 状态    | 质量(M/Qual) | 版本 | 描述                                       |
|---------|----------------|----------------------|-------------|--------|--------|---------|--------------|------|--------------------------------------------|
| VIP-006 | sram           | SRAM                 | LIGHTWEIGHT | P0     | sram   | planned | M0 / NOT_RUN | -    | Read/Write/Latency/ECC injection           |
| VIP-007 | generic_memory | Generic Memory Model | LIGHTWEIGHT | P0     | memory | planned | M0 / NOT_RUN | -    | Configurable latency/width/error injection |
| VIP-102 | flash          | Flash                | LIGHTWEIGHT | P1     | flash  | planned | M0 / NOT_RUN | -    | Read/Program/Erase model                   |
| VIP-103 | efuse_otp      | eFuse/OTP            | LIGHTWEIGHT | P1     | efuse  | planned | M0 / NOT_RUN | -    | Program/read/lock/lifecycle behavior       |
| VIP-104 | rom            | ROM                  | LIGHTWEIGHT | P1     | rom    | planned | M0 / NOT_RUN | -    | Read model/initialization                  |
| VIP-105 | ddr            | DDR Controller-side  | MODEL       | P1     | ddr    | planned | M0 / NOT_RUN | -    | Command/data/timing model                  |

## vip/peripheral（8）

| ID      | VIP      | 名称     | Profile     | 优先级 | HWIF     | 状态    | 质量(M/Qual) | 版本 | 描述                              |
|---------|----------|----------|-------------|--------|----------|---------|--------------|------|-----------------------------------|
| VIP-008 | uart     | UART     | FULL_UVM    | P0     | uart     | planned | M0 / NOT_RUN | -    | TX/RX/baud/parity/framing error   |
| VIP-009 | spi      | SPI      | FULL_UVM    | P0     | spi      | planned | M0 / NOT_RUN | -    | Master/Slave/CPOL/CPHA/multi-CS   |
| VIP-010 | i2c      | I2C      | FULL_UVM    | P0     | i2c      | planned | M0 / NOT_RUN | -    | Master/Slave/arbitration/ACK-NACK |
| VIP-011 | gpio     | GPIO     | LIGHTWEIGHT | P0     | gpio     | planned | M0 / NOT_RUN | -    | Input/Output/Interrupt stimulus   |
| VIP-012 | timer    | Timer    | LIGHTWEIGHT | P0     | timer    | planned | M0 / NOT_RUN | -    | Counter/compare/interrupt         |
| VIP-013 | watchdog | Watchdog | LIGHTWEIGHT | P0     | watchdog | planned | M0 / NOT_RUN | -    | Timeout/reset/interrupt           |
| VIP-106 | pwm      | PWM      | LIGHTWEIGHT | P1     | pwm      | planned | M0 / NOT_RUN | -    | Duty/period/edge checking         |
| VIP-107 | rtc      | RTC      | LIGHTWEIGHT | P1     | rtc      | planned | M0 / NOT_RUN | -    | Counter/alarm/calendar behavior   |

## vip/safety（4）

| ID      | VIP                 | 名称                   | Profile      | 优先级 | HWIF | 状态    | 质量(M/Qual) | 版本 | 描述                                      |
|---------|---------------------|------------------------|--------------|--------|------|---------|--------------|------|-------------------------------------------|
| VIP-021 | ecc_injection       | ECC Injection          | CHECKER_ONLY | P0     | -    | planned | M0 / NOT_RUN | -    | SEC/DED fault injection                   |
| VIP-022 | parity_injection    | Parity Error Injection | CHECKER_ONLY | P0     | -    | planned | M0 / NOT_RUN | -    | Register/memory parity injection          |
| VIP-023 | fault_injection     | Fault Injection        | CHECKER_ONLY | P0     | -    | planned | M0 / NOT_RUN | -    | Generic protocol/datapath fault injection |
| VIP-121 | lockstep_comparison | Lockstep Comparison    | CHECKER_ONLY | P1     | -    | planned | M0 / NOT_RUN | -    | Dual-core/dual-path mismatch injection    |

## vip/storage（3）

| ID      | VIP  | 名称    | Profile  | 优先级 | HWIF | 状态    | 质量(M/Qual) | 版本 | 描述                        |
|---------|------|---------|----------|--------|------|---------|--------------|------|-----------------------------|
| VIP-119 | sd   | SD/SDIO | FULL_UVM | P1     | sd   | planned | M0 / NOT_RUN | -    | Command/data/card model     |
| VIP-120 | emmc | eMMC    | FULL_UVM | P1     | emmc | planned | M0 / NOT_RUN | -    | Command/boot/data transfer  |
| VIP-206 | ufs  | UFS     | FULL_UVM | P2     | ufs  | planned | M0 / NOT_RUN | -    | High-speed storage protocol |
