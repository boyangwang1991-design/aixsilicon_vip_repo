# AIXSILICON VIP Repository

**VIP 认证资产库（VIP 产品货架）**：面向 IP / SoC 验证的标准化、可复用、可版本管理的
Verification IP 资产仓库。

> 仓库原则上只接收由 **VIP Development Suite** 开发并通过质量门禁的 VIP，并通过 FuseSoC
> 提供统一发现、依赖和调用能力。

```
VIP Development Suite = VIP 工厂（负责规划、开发、Self Test、Qualification）
VIP REPO            = 经过验收的 VIP 产品货架（负责 Plan → Accept → Qualify → Catalog → Version → Distribute）
```

本仓库**不承担"如何开发 VIP"**——开发方法、质量规范与模板在 `vip-repo-maintainer`
（skill）中定义与执行；本仓库只接收其验收通过的交付件。

## 目录结构

```text
aixsilicon-vip-repo/
├── README.md            # 本文件：仓库定位与使用说明（含由脚本生成的状态总览）
├── registry.yaml        # VIP 状态索引（唯一 SSOT：id/name/family/group/profile/priority/hwif/status/version/path）
├── fusesoc.conf         # FuseSoC 库注册
├── CHANGELOG.md         # 平台版本
├── LICENSE              # Apache-2.0
├── vip/                 # 已准入 VIP 工程包（按分类组织，仅含 Qualified 资产）
│   ├── amba/            # AMBA 总线协议 VIP（axi4 / axi4_lite / axi_stream / apb4 / ahb_lite ...）
│   ├── peripheral/      # 外设协议 VIP（uart / spi / i2c / gpio / timer / watchdog ...）
│   ├── memory/          # 存储类 VIP（sram / generic_memory / flash / ddr ...）
│   ├── chip/            # 芯片基础设施 VIP（interrupt / clock_reset / power / dma_traffic ...）
│   ├── debug/           # 调试接口 VIP（jtag / swd / riscv_debug）
│   ├── io/              # 网络/IO 协议 VIP（ethernet_mac / mdio / pcie / usb / mipi）
│   ├── storage/         # 存储接口 VIP（sd / emmc / ufs）
│   ├── safety/          # 功能安全/故障注入 VIP（ecc_injection / fault_injection ...）
│   └── common/          # 通用验证基础设施 VIP（csr_access / generic_stream ...）
└── tools/               # 仓库级确定性脚本
    ├── gen_catalog.py   # 从 registry.yaml 生成 README 状态总览
    ├── check_vip.py     # VIP 准入结构/元数据检查（G1/G2）
    └── regression.py    # VIP 回归入口（G7）
```

## FuseSoC 使用

将本仓库注册为 FuseSoC 库后，可以按 VLNV 直接声明依赖并运行：

```bash
# 注册库
fusesoc library add aixsilicon-vip /path/to/aixsilicon_vip_repo

# 列出 / 查看 / 运行已准入 VIP
fusesoc core list
fusesoc core show aixsilicon:vip:axi4:1.0.0
fusesoc run --target smoke aixsilicon:vip:axi4:1.0.0
```

VLNV 命名统一为：`aixsilicon:vip:<name>:<version>`。

调用最终变成 `aixsilicon:vip:axi4:1.0.0`，而不是 `../../../../../common/vip/axi/src/...`。

## registry.yaml

`registry.yaml` 是 VIP 状态的机器可读索引（唯一 SSOT），每条含：

| 字段 | 说明 |
| --- | --- |
| `id` | VIP ID（如 `VIP-001`） |
| `name` | 英文短名（VLNV name，如 `axi4`） |
| `family` | 中文/英文名（VIP 族） |
| `group` | 类别路径（如 `vip/amba`） |
| `profile` | `FULL_UVM` / `LIGHTWEIGHT` / `PASSIVE` / `CHECKER_ONLY` / `MODEL` |
| `priority` | P0~P3 |
| `hwif` | 对应 HWIF 接口契约（如 `axi4`） |
| `description` | 能力描述 |
| `status` | `planned` / `developing` / `qualified` / `deprecated` |
| `version` | 版本（SemVer）或 `-` |
| `path` | VIP 相对路径 |

生命周期：

```text
Planned（仅存在于 registry.yaml）
   ↓
Developing（在 VIP Development Suite 开发工作区，原则上不进入本仓库）
   ↓
Qualified（通过质量门禁后 merge 到本仓库 vip/ 下）
   ↓
Deprecated（保留以保证已有项目可复现）
```

`status=qualified` 的条目在 `vip/` 下存在完整工程包；`planned` 条目仅为规划候选，无物理目录。

## 当前已准入 VIP

> 以下状态总览由 [`tools/gen_catalog.py`](tools/gen_catalog.py) 依据
> [`registry.yaml`](registry.yaml:1)（SSOT）自动生成；**修改 `registry.yaml` 后必须运行**
> `uv run python tools/gen_catalog.py --root .` 刷新本节，勿手工编辑。

<!-- REGISTRY-STATUS:BEGIN -->
> 本节由 `tools/gen_catalog.py` 依据 `registry.yaml`（SSOT）自动生成。
> 修改 `registry.yaml` 后必须运行 `uv run python tools/gen_catalog.py --root .` 刷新本节；勿手工编辑。
> 最后更新：`2026-08-31T00:00:00Z`

### 总览

| 指标           | 数量 |
|----------------|------|
| 总条目（vips） | 52   |
| qualified      | 0    |
| developing     | 2    |
| planned        | 50   |
| deprecated     | 0    |
| 准入率         | 0.0% |

### 已准入 VIP（0）

（当前无已准入 VIP）

### 按类别分布（qualified / developing / planned）

| 类别           | qualified | developing | planned | 合计 |
|----------------|-----------|------------|---------|------|
| vip/amba       | 0         | 2          | 6       | 8    |
| vip/chip       | 0         | 0          | 11      | 11   |
| vip/common     | 0         | 0          | 4       | 4    |
| vip/debug      | 0         | 0          | 3       | 3    |
| vip/io         | 0         | 0          | 5       | 5    |
| vip/memory     | 0         | 0          | 6       | 6    |
| vip/peripheral | 0         | 0          | 8       | 8    |
| vip/safety     | 0         | 0          | 4       | 4    |
| vip/storage    | 0         | 0          | 3       | 3    |

### 按 Profile 分布

| Profile      | 数量 |
|--------------|------|
| CHECKER_ONLY | 4    |
| FULL_UVM     | 23   |
| LIGHTWEIGHT  | 20   |
| MODEL        | 4    |
| PASSIVE      | 1    |

### 按优先级分布

| 优先级 | qualified | 其他 | 合计 |
|--------|-----------|------|------|
| P0     | 0         | 23   | 23   |
| P1     | 0         | 23   | 23   |
| P2     | 0         | 6    | 6    |

### VIP 明细（按分类）

#### vip/amba（8）

| ID      | VIP                             | 状态       | Profile     | 优先级 | 质量(M/Qual) | 版本 | 功能                                                                                          |
|---------|---------------------------------|------------|-------------|--------|--------------|------|-----------------------------------------------------------------------------------------------|
| VIP-001 | [axi4](vip/amba/axi4/README.md) | developing | FULL_UVM    | P0     | M0 / NOT_RUN | -    | Master/Slave/Monitor/Checker/Coverage、outstanding、out-of-order、4KB boundary                |
| VIP-002 | axi4_lite                       | planned    | FULL_UVM    | P0     | M0 / NOT_RUN | -    | Master/Slave/Monitor/Checker                                                                  |
| VIP-003 | axi_stream                      | planned    | LIGHTWEIGHT | P0     | M0 / NOT_RUN | -    | Source/Sink/Monitor/Packet Check、TKEEP/TLAST                                                 |
| VIP-004 | [apb](vip/amba/apb/README.md)   | developing | FULL_UVM    | P0     | M0 / NOT_RUN | -    | APB3/4/5 Master/Slave/Monitor/Checker/SVA、wait state、slave error、RME/PNSE、check_type、RAL |
| VIP-005 | ahb_lite                        | planned    | FULL_UVM    | P0     | M0 / NOT_RUN | -    | Master/Slave/Monitor/Checker、burst、split                                                    |
| VIP-101 | ace_lite                        | planned    | FULL_UVM    | P1     | M0 / NOT_RUN | -    | Coherency-lite transaction verification                                                       |
| VIP-201 | ace                             | planned    | FULL_UVM    | P2     | M0 / NOT_RUN | -    | Cache coherency verification                                                                  |
| VIP-202 | chi                             | planned    | FULL_UVM    | P2     | M0 / NOT_RUN | -    | Coherent hub interface verification                                                           |

#### vip/chip（11）

| ID      | VIP              | 状态    | Profile     | 优先级 | 质量(M/Qual) | 版本 | 功能                                        |
|---------|------------------|---------|-------------|--------|--------------|------|---------------------------------------------|
| VIP-014 | interrupt        | planned | LIGHTWEIGHT | P0     | M0 / NOT_RUN | -    | IRQ generation/priority/masking             |
| VIP-015 | clock            | planned | LIGHTWEIGHT | P0     | M0 / NOT_RUN | -    | Clock generation/jitter/frequency change    |
| VIP-016 | reset            | planned | LIGHTWEIGHT | P0     | M0 / NOT_RUN | -    | POR/warm reset/reset sequencing             |
| VIP-017 | clock_reset      | planned | LIGHTWEIGHT | P0     | M0 / NOT_RUN | -    | CRG combined stimulus/check                 |
| VIP-018 | dma_traffic      | planned | LIGHTWEIGHT | P0     | M0 / NOT_RUN | -    | Configurable traffic generation             |
| VIP-108 | plic             | planned | FULL_UVM    | P1     | M0 / NOT_RUN | -    | RISC-V interrupt controller verification    |
| VIP-109 | gic              | planned | FULL_UVM    | P1     | M0 / NOT_RUN | -    | ARM interrupt subsystem verification        |
| VIP-110 | mailbox          | planned | LIGHTWEIGHT | P1     | M0 / NOT_RUN | -    | Core-to-core message verification           |
| VIP-111 | power_control    | planned | MODEL       | P1     | M0 / NOT_RUN | -    | Power state/isolation/retention             |
| VIP-112 | dvfs             | planned | MODEL       | P1     | M0 / NOT_RUN | -    | Voltage-frequency state transition modeling |
| VIP-113 | descriptor_model | planned | LIGHTWEIGHT | P1     | M0 / NOT_RUN | -    | Descriptor chain/ring behavior              |

#### vip/common（4）

| ID      | VIP                 | 状态    | Profile     | 优先级 | 质量(M/Qual) | 版本 | 功能                                            |
|---------|---------------------|---------|-------------|--------|--------------|------|-------------------------------------------------|
| VIP-019 | csr_access          | planned | FULL_UVM    | P0     | M0 / NOT_RUN | -    | Read/write/access-type checking、CSR/RAL access |
| VIP-020 | generic_stream      | planned | LIGHTWEIGHT | P0     | M0 / NOT_RUN | -    | Generic valid-ready stream、packet source/sink  |
| VIP-122 | scoreboard_model    | planned | MODEL       | P1     | M0 / NOT_RUN | -    | Generic transaction compare                     |
| VIP-123 | performance_monitor | planned | PASSIVE     | P1     | M0 / NOT_RUN | -    | Latency/bandwidth/outstanding statistics        |

#### vip/debug（3）

| ID      | VIP         | 状态    | Profile  | 优先级 | 质量(M/Qual) | 版本 | 功能                          |
|---------|-------------|---------|----------|--------|--------------|------|-------------------------------|
| VIP-114 | jtag        | planned | FULL_UVM | P1     | M0 / NOT_RUN | -    | TAP state/IR/DR/boundary scan |
| VIP-115 | swd         | planned | FULL_UVM | P1     | M0 / NOT_RUN | -    | ARM serial debug              |
| VIP-116 | riscv_debug | planned | FULL_UVM | P1     | M0 / NOT_RUN | -    | DMI/debug module interaction  |

#### vip/io（5）

| ID      | VIP          | 状态    | Profile     | 优先级 | 质量(M/Qual) | 版本 | 功能                                |
|---------|--------------|---------|-------------|--------|--------------|------|-------------------------------------|
| VIP-117 | ethernet_mac | planned | FULL_UVM    | P1     | M0 / NOT_RUN | -    | Frame generate/monitor/CRC          |
| VIP-118 | mdio         | planned | LIGHTWEIGHT | P1     | M0 / NOT_RUN | -    | PHY management                      |
| VIP-203 | pcie         | planned | FULL_UVM    | P2     | M0 / NOT_RUN | -    | TLP/DLLP/link behavior              |
| VIP-204 | usb          | planned | FULL_UVM    | P2     | M0 / NOT_RUN | -    | Endpoint/transfer/protocol checking |
| VIP-205 | mipi         | planned | FULL_UVM    | P2     | M0 / NOT_RUN | -    | Packet/lane behavior                |

#### vip/memory（6）

| ID      | VIP            | 状态    | Profile     | 优先级 | 质量(M/Qual) | 版本 | 功能                                       |
|---------|----------------|---------|-------------|--------|--------------|------|--------------------------------------------|
| VIP-006 | sram           | planned | LIGHTWEIGHT | P0     | M0 / NOT_RUN | -    | Read/Write/Latency/ECC injection           |
| VIP-007 | generic_memory | planned | LIGHTWEIGHT | P0     | M0 / NOT_RUN | -    | Configurable latency/width/error injection |
| VIP-102 | flash          | planned | LIGHTWEIGHT | P1     | M0 / NOT_RUN | -    | Read/Program/Erase model                   |
| VIP-103 | efuse_otp      | planned | LIGHTWEIGHT | P1     | M0 / NOT_RUN | -    | Program/read/lock/lifecycle behavior       |
| VIP-104 | rom            | planned | LIGHTWEIGHT | P1     | M0 / NOT_RUN | -    | Read model/initialization                  |
| VIP-105 | ddr            | planned | MODEL       | P1     | M0 / NOT_RUN | -    | Command/data/timing model                  |

#### vip/peripheral（8）

| ID      | VIP      | 状态    | Profile     | 优先级 | 质量(M/Qual) | 版本 | 功能                              |
|---------|----------|---------|-------------|--------|--------------|------|-----------------------------------|
| VIP-008 | uart     | planned | FULL_UVM    | P0     | M0 / NOT_RUN | -    | TX/RX/baud/parity/framing error   |
| VIP-009 | spi      | planned | FULL_UVM    | P0     | M0 / NOT_RUN | -    | Master/Slave/CPOL/CPHA/multi-CS   |
| VIP-010 | i2c      | planned | FULL_UVM    | P0     | M0 / NOT_RUN | -    | Master/Slave/arbitration/ACK-NACK |
| VIP-011 | gpio     | planned | LIGHTWEIGHT | P0     | M0 / NOT_RUN | -    | Input/Output/Interrupt stimulus   |
| VIP-012 | timer    | planned | LIGHTWEIGHT | P0     | M0 / NOT_RUN | -    | Counter/compare/interrupt         |
| VIP-013 | watchdog | planned | LIGHTWEIGHT | P0     | M0 / NOT_RUN | -    | Timeout/reset/interrupt           |
| VIP-106 | pwm      | planned | LIGHTWEIGHT | P1     | M0 / NOT_RUN | -    | Duty/period/edge checking         |
| VIP-107 | rtc      | planned | LIGHTWEIGHT | P1     | M0 / NOT_RUN | -    | Counter/alarm/calendar behavior   |

#### vip/safety（4）

| ID      | VIP                 | 状态    | Profile      | 优先级 | 质量(M/Qual) | 版本 | 功能                                      |
|---------|---------------------|---------|--------------|--------|--------------|------|-------------------------------------------|
| VIP-021 | ecc_injection       | planned | CHECKER_ONLY | P0     | M0 / NOT_RUN | -    | SEC/DED fault injection                   |
| VIP-022 | parity_injection    | planned | CHECKER_ONLY | P0     | M0 / NOT_RUN | -    | Register/memory parity injection          |
| VIP-023 | fault_injection     | planned | CHECKER_ONLY | P0     | M0 / NOT_RUN | -    | Generic protocol/datapath fault injection |
| VIP-121 | lockstep_comparison | planned | CHECKER_ONLY | P1     | M0 / NOT_RUN | -    | Dual-core/dual-path mismatch injection    |

#### vip/storage（3）

| ID      | VIP  | 状态    | Profile  | 优先级 | 质量(M/Qual) | 版本 | 功能                        |
|---------|------|---------|----------|--------|--------------|------|-----------------------------|
| VIP-119 | sd   | planned | FULL_UVM | P1     | M0 / NOT_RUN | -    | Command/data/card model     |
| VIP-120 | emmc | planned | FULL_UVM | P1     | M0 / NOT_RUN | -    | Command/boot/data transfer  |
| VIP-206 | ufs  | planned | FULL_UVM | P2     | M0 / NOT_RUN | -    | High-speed storage protocol |

<!-- REGISTRY-STATUS:END -->

## 与其他仓库的关系

```text
                    AIXSILICON
                         │
               FuseSoC / Metadata
                         │
       ┌─────────────────┼─────────────────┐
       │                 │                 │
    IP REPO           CBB REPO          VIP REPO
       │                 │                 │
   Design IP         RTL Building       Verification
                         Block             Asset
       │                 │                 │
       └─────────────────┼─────────────────┘
                         │
                      HWIF REPO
                         │
                 Interface Contract
```

HWIF 定义接口契约，VIP 针对 HWIF 提供 Stimulus / Monitor / Checker / Coverage / Assertion：

```text
aixsilicon:hwif:axi4
        ↕
aixsilicon:vip:axi4
```

## License

Apache-2.0，详见 [LICENSE](LICENSE)。
