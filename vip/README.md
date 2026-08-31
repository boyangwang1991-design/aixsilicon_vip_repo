# vip/ — 已准入 VIP 工程包

本目录只存放 **Qualified（已通过质量门禁）** 的 VIP 工程包，按分类组织。

> 原则：**VIP REPO 只收 Qualified VIP，不做开发垃圾场。**
> 规划中的 VIP 只存在于 [`registry.yaml`](../registry.yaml)（`planned` 状态，无物理目录）；
> 正在开发的 VIP 位于 VIP Development Suite 开发工作区（`developing` 状态）；
> 只有通过全部质量门禁的 VIP 才会 merge 到这里（`qualified` 状态）。

## 分类

| 分类目录 | 内容 | 状态 |
|---|---|---|
| [`amba/`](amba/) | AMBA 总线协议 VIP（AXI4/AXI4-Lite/AXI-Stream/APB4/AHB-Lite/ACE/CHI） | 规划中 |
| [`peripheral/`](peripheral/) | 外设协议 VIP（UART/SPI/I2C/GPIO/Timer/Watchdog/PWM/RTC） | 规划中 |
| [`memory/`](memory/) | 存储类 VIP（SRAM/Generic Memory/Flash/eFuse-OTP/ROM/DDR） | 规划中 |
| [`chip/`](chip/) | 芯片基础设施 VIP（Interrupt/Clock/Reset/CRG/DMA/Power/DVFS） | 规划中 |
| [`debug/`](debug/) | 调试接口 VIP（JTAG/SWD/RISC-V Debug） | 规划中 |
| [`io/`](io/) | 网络/IO 协议 VIP（Ethernet MAC/MDIO/PCIe/USB/MIPI） | 规划中 |
| [`storage/`](storage/) | 存储接口 VIP（SD/SDIO/eMMC/UFS） | 规划中 |
| [`safety/`](safety/) | 功能安全/故障注入 VIP（ECC/Parity/Fault/Lockstep） | 规划中 |
| [`common/`](common/) | 通用验证基础设施 VIP（CSR/Stream/Scoreboard/Performance） | 规划中 |

## 单个 VIP 标准布局

每个 Qualified VIP 是一个完整、独立的产品（目录拿出来即可独立理解、验证、发布）：

```text
vip/<category>/<vip-name>/
├── README.md
├── CHANGELOG.md
├── aixsilicon_vip_<name>_<version>.core   # FuseSoC Core（VLNV 唯一）
├── docs/
│   ├── architecture.md
│   ├── user-guide.md
│   ├── configuration.md
│   └── limitation.md
├── src/
│   ├── <name>_pkg.sv
│   ├── transaction/
│   ├── agent/           # driver / monitor / sequencer
│   ├── sequences/
│   ├── coverage/
│   ├── checker/         # checker + assertions
│   └── env/
├── examples/            # smoke / master_slave
├── tests/               # smoke / protocol / error / random
└── qualification/
    ├── requirement_traceability.md
    ├── qualification_plan.md
    ├── qualification_report.md
    ├── fault_injection.md
    ├── coverage_report.md
    ├── known_limitations.md
    └── evidence/
```

> 新 VIP 准入时的结构与模板规范由 `vip-repo-maintainer` skill 定义与约束。
