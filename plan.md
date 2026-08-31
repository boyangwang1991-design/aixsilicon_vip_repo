我建议把 `aixsilicon-vip-repo` 做成一个非常“干净”的**认证 VIP 资产库**：它不负责开发过程，而只负责**规划、准入、版本化、发布、FuseSoC 分发和质量管理**。

也就是说：

> **VIP Development Suite = VIP 工厂**
> **VIP REPO = 经过验收的 VIP 产品货架**

这样边界会非常清楚。

FuseSoC 本身非常适合做这一层分发：它会递归扫描 library 下的 `.core` 文件，可以把整个 VIP REPO 直接注册为一个 FuseSoC library；core 用 VLNV 做唯一标识，也支持 filesets、targets 和 dependency 管理。([FuseSoC][1])

---

# 1. VIP REPO 的核心定位

我建议定义成：

**AIXSILICON VIP REPO**

> 面向 IP / SoC 验证的标准化、可复用、可版本管理的 Verification IP 资产仓库。
> 仓库原则上只接收由 `VIP Development Suite` 开发并通过质量门禁的 VIP，并通过 FuseSoC 提供统一发现、依赖和调用能力。

它重点解决五件事情：

1. **我们需要哪些 VIP**
2. **现在哪些 VIP 已经有了**
3. **每个 VIP 能不能放心用**
4. **怎么一条命令拉入验证工程**
5. **VIP 怎么持续升级而不会影响已有项目**

---

# 2. 整个 REPO 不要设计得太复杂

我推荐：

```text
aixsilicon-vip-repo/
│
├── README.md
├── vip_plan.md
├── vip_catalog.md
│
├── vip/
│   ├── amba/
│   │   ├── axi4/
│   │   ├── axi4_lite/
│   │   ├── apb/
│   │   └── ahb/
│   │
│   ├── peripheral/
│   │   ├── uart/
│   │   ├── spi/
│   │   ├── i2c/
│   │   └── gpio/
│   │
│   ├── memory/
│   │   ├── sram/
│   │   └── ddr/
│   │
│   ├── chip/
│   │   ├── interrupt/
│   │   ├── clock_reset/
│   │   └── power/
│   │
│   └── ...
│
├── templates/
│   └── vip-template/
│
├── docs/
│   ├── vip-standard.md
│   ├── quality-standard.md
│   ├── version-policy.md
│   └── contribution-guide.md
│
└── tools/
    ├── check_vip.py
    ├── gen_catalog.py
    └── regression.py
```

我反而**不推荐**建立很多诸如 `registry/metadata/database/releases/...` 的复杂目录。

FuseSoC `.core` 本身已经承担了相当一部分机器可读描述。

---

# 3. 每个 VIP 应该是一个完整、独立的产品

例如：

```text
vip/amba/axi4/
│
├── README.md
├── CHANGELOG.md
├── aixsilicon_vip_axi4.core
│
├── docs/
│   ├── architecture.md
│   ├── user-guide.md
│   ├── configuration.md
│   └── limitation.md
│
├── src/
│   ├── axi4_pkg.sv
│   │
│   ├── transaction/
│   │   └── axi4_item.sv
│   │
│   ├── agent/
│   │   ├── axi4_agent.sv
│   │   ├── axi4_driver.sv
│   │   ├── axi4_monitor.sv
│   │   └── axi4_sequencer.sv
│   │
│   ├── sequences/
│   │   ├── axi4_base_sequence.sv
│   │   ├── axi4_read_sequence.sv
│   │   └── axi4_write_sequence.sv
│   │
│   ├── coverage/
│   │   └── axi4_coverage.sv
│   │
│   ├── checker/
│   │   ├── axi4_checker.sv
│   │   └── axi4_assertions.sv
│   │
│   └── env/
│       └── axi4_env.sv
│
├── examples/
│   ├── smoke/
│   └── master_slave/
│
├── tests/
│   ├── smoke/
│   ├── protocol/
│   ├── error/
│   └── random/
│
└── quality/
    └── qualification.md
```

这里有一个重要原则：

> **一个 VIP 目录拿出来，本身就应该能够独立理解、独立验证、独立发布。**

---

# 4. 一个“优秀 VIP”应该包含什么

我建议 VIP Development Suite 和 VIP REPO 共用一套 Definition of Done。

可以归纳成八部分。

| 维度              | 必备内容                                            |
| --------------- | ----------------------------------------------- |
| Interface Model | interface / clocking block / config             |
| Transaction     | sequence item / transaction definition          |
| Stimulus        | sequencer / sequence library                    |
| Driver          | 主动驱动协议                                          |
| Monitor         | 被动监听、transaction reconstruction                 |
| Checking        | protocol checker / scoreboard / reference model |
| Coverage        | functional coverage                             |
| Assertions      | protocol / timing SVA                           |
| Environment     | agent / env / virtual interface                 |
| Test            | smoke / normal / corner / error / random        |
| Documentation   | architecture / usage / config / limitation      |
| Package         | FuseSoC `.core`                                 |
| Quality         | regression / coverage / lint / known issues     |

其中我尤其建议把下面四样定义为**优秀 VIP 的关键指标**：

### A. Passive mode

不仅能主动激励 DUT，还应该能：

```text
Active VIP
    Driver
    Monitor
    Sequencer

Passive VIP
    Monitor
    Checker
    Coverage
```

因为 SoC 集成阶段大量场景其实只需要 Monitor + Checker。

---

### B. Protocol checker

例如 AXI：

```text
AWVALID/AWREADY
WVALID/WREADY
BVALID/BREADY

ARVALID/ARREADY
RVALID/RREADY

burst length
burst boundary
ID ordering
response
outstanding
...
```

VIP 不应该只是：

> “帮我发 AXI transaction。”

而应该能够回答：

> **“这个 AXI 行为是不是合法。”**

---

### C. Coverage model

例如：

```text
Burst Type
× Burst Length
× Transfer Size
× Response
× Outstanding
× ID
× Backpressure
```

这样 VIP 才真正成为验证资产。

---

### D. Self Qualification

VIP 自己必须有测试 VIP 的测试。

也就是：

```text
DUT test
        ↓
      VIP

同时：

VIP
 ↓
VIP Self Test
```

否则非常容易出现：

> DUT bug 还是 VIP bug？

说不清楚。

---

# 5. vip_plan.md 很重要

你提到 **Plan VIP List**，我非常赞成。

而且按照你整个 AIXSILICON 的方法，我依然建议：

> **Markdown 是人和 Agent 的 SSOT。**

而不是让人直接维护 YAML。

例如：

```markdown
# AIXSILICON VIP Plan

## AMBA

| VIP | Priority | Status | Version | Owner | Capability |
|---|---|---|---|---|---|
| AXI4 | P0 | Qualified | 1.0.0 | xxx | Master/Slave/Monitor |
| AXI4-Lite | P0 | Developing | - | xxx | Master/Slave |
| APB4 | P0 | Planned | - | - | Master/Slave |
| AHB-Lite | P1 | Planned | - | - | Master/Slave |

## Peripheral

| VIP | Priority | Status |
|---|---|---|
| UART | P0 | Planned |
| SPI | P0 | Planned |
| I2C | P0 | Planned |
| GPIO | P1 | Planned |

## Chip Infrastructure

| VIP | Priority |
|---|---|
| Interrupt | P0 |
| Clock/Reset | P0 |
| SRAM | P0 |
```

然后 Agent 自动提取：

```text
vip_plan.md
     ↓
gen_catalog.py
     ↓
vip_catalog.yaml
     ↓
AIXSILICON平台
```

这样未来 AIXSILICON 页面上可以直接显示：

```text
VIP Catalog

AMBA                 4 / 7
Peripheral           3 / 8
Memory               2 / 5
Chip Infrastructure  5 / 9
```

---

# 6. VIP 生命周期建议非常简单

不要搞太多状态。

我建议就：

```text
Planned
   ↓
Developing
   ↓
Qualified
   ↓
Deprecated
```

其中：

### Planned

只出现在：

```text
vip_plan.md
```

目录甚至都不需要存在。

---

### Developing

在 VIP Development Suite 的开发 workspace 中。

**原则上不要进入正式 VIP REPO。**

---

### Qualified

通过：

```text
Structure Check
Lint
Compile
Smoke
Regression
Protocol Check
Coverage
Documentation Check
FuseSoC Check
        ↓
Qualified
```

之后 merge 到：

```text
aixsilicon-vip-repo
```

---

### Deprecated

仍然保留，以保证已有项目能够复现。

---

# 7. FuseSoC 应成为 VIP 的标准调用接口

这点我建议明确写进规范：

> **任何正式 VIP 必须提供 FuseSoC Core 描述。**

例如：

```yaml
CAPI=2:

name: aixsilicon:vip:axi4:1.0.0

description: AIXSILICON AXI4 Verification IP

filesets:

  vip:
    files:
      - src/axi4_pkg.sv
      - src/transaction/axi4_item.sv
      - src/agent/axi4_driver.sv
      - src/agent/axi4_monitor.sv
      - src/agent/axi4_agent.sv
    file_type: systemVerilogSource

targets:

  default:
    filesets:
      - vip

  smoke:
    filesets:
      - vip
      - tb
```

FuseSoC CAPI2 对 filesets、targets、parameters 等都有原生支持，因此非常适合把 VIP 从“源码目录”变成“可声明依赖的验证组件”。([GitHub][2])

调用最终可以变成：

```text
aixsilicon:vip:axi4:1.0.0
```

而不是：

```text
../../../../../common/vip/axi/src/...
```

这对你后续整个 IP Development Suite / SoC Verification Suite 非常关键。

---

# 8. 建议统一 VLNV

AIXSILICON 自己的东西统一：

```text
aixsilicon:vip:<name>:<version>
```

例如：

```text
aixsilicon:vip:axi4:1.0.0
aixsilicon:vip:apb4:1.2.0
aixsilicon:vip:uart:2.0.0
aixsilicon:vip:sram:1.0.0
```

未来其它 Repo 可以自然形成：

```text
aixsilicon:ip:ram_ctrl:1.0.0

aixsilicon:cbb:fifo:2.1.0

aixsilicon:vip:axi4:1.1.0

aixsilicon:hwif:axi4:1.0.0
```

整个资产生态就统一了。

---

# 9. 一个关键点：VIP 不要全部强制 UVM

这一点我会特别强调。

VIP REPO 管的是**Verification IP**，而不是：

> UVM Class Library。

所以可以允许：

```text
VIP
├── Interface
├── BFM
├── Monitor
├── Checker
├── Assertion
├── Coverage
└── UVM Adapter
```

比如 SRAM VIP / Clock Reset VIP / Interrupt VIP，有时候：

```text
BFM + Monitor + Checker + SVA
```

已经非常好用。

如果所有东西都强行：

```text
uvm_agent
uvm_driver
uvm_monitor
uvm_sequence
...
```

反而会把简单 VIP 搞得很重。

因此推荐 VIP Development Suite 支持：

```text
VIP Profile

FULL_UVM
LIGHTWEIGHT
PASSIVE
CHECKER_ONLY
MODEL
```

这是很有价值的分类。

---

# 10. VIP REPO 和其他 Repo 的关系

我建议最终形成：

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

尤其这里：

### HWIF REPO

定义：

```text
AXI
APB
UART
Interrupt
Clock Reset
...
```

的**接口契约**。

### VIP REPO

针对 HWIF 提供：

```text
Stimulus
Monitor
Checker
Coverage
Assertion
```

所以：

```text
HWIF
 ↓
VIP
```

最好存在明确对应关系。

比如：

```text
aixsilicon:hwif:axi4
        ↕
aixsilicon:vip:axi4
```

这会让你的 Repo 体系非常漂亮。

---

# 11. 我建议第一批 Plan VIP List

不要一开始贪多。

### P0｜SoC / IP 开发最常用

```text
AXI4
AXI4-Lite
APB4
AHB-Lite

Clock / Reset
Interrupt
SRAM

UART
SPI
I2C
GPIO
```

### P1

```text
ACE / ACE-Lite
CHI

DMA Traffic Model
Flash
eFuse
Timer
Watchdog

JTAG
SWD
```

### P2

再开始做复杂协议：

```text
PCIe
DDR
USB
Ethernet
MIPI
...
```

复杂标准协议甚至不一定值得自行开发完整 commercial-grade VIP，后面可以根据项目需要决定自研范围。

---

# 12. VIP Development Suite 与 VIP REPO 的边界

最后我建议把整个流程固定下来：

```text
            vip_plan.md
                  │
                  ▼
        VIP Development Suite
                  │
         ┌────────┴────────┐
         │                 │
      Develop           Self Test
         │                 │
         └────────┬────────┘
                  ▼
            Qualification
                  │
       ┌──────────┼──────────┐
       │          │          │
     Code       Docs       Quality
       │          │          │
       └──────────┼──────────┘
                  ▼
             VIP RELEASE
                  │
                  ▼
       ┌────────────────────┐
       │ AIXSILICON VIP REPO│
       └────────────────────┘
                  │
          FuseSoC Library
                  │
      ┌───────────┼───────────┐
      ▼           ▼           ▼
 IP Development  SoC DV    CBB Development
    Suite         Suite         Suite
```

其中 **VIP REPO 本身不要承担“如何开发 VIP”**。

这些规则应该在：

```text
vip-development-suite/
```

里面。

VIP REPO 只负责：

> **Plan → Accept → Qualify → Catalog → Version → Distribute**

---

我认为最值得坚持的三条设计原则是：

> **① VIP REPO 只收 Qualified VIP，不做开发垃圾场。**
> **② Markdown 管规划和质量说明，FuseSoC `.core` 管机器调用。**
> **③ VIP 不等于 UVM；Checker / Monitor / Coverage / Assertion 是 VIP 的一等公民。**

这样未来 `IP REPO / CBB REPO / VIP REPO / HWIF REPO` 可以共享非常相似的资产治理框架，而 `VIP Development Suite` 负责把 VIP 按这个标准生产出来。

[1]: https://fusesoc.readthedocs.io/_/downloads/en/stable/pdf/?utm_source=chatgpt.com "FuseSoC Documentation"
[2]: https://github.com/olofk/fusesoc/blob/main/fusesoc/capi2/generator.py?utm_source=chatgpt.com "fusesoc/fusesoc/capi2/generator.py at main · olofk/fusesoc · GitHub"


可以，而且我建议把这件事定义成 VIP 的“Qualification Evidence”，而不是简单的 regression pass。

因为 VIP 的“正确性”和“完整性”其实是两个不同问题：

* **正确性**：VIP 的行为、检查、采样、协议解释是对的。
* **完整性**：协议规定的重要场景、边界、异常、组合空间都被覆盖到了。

要充分证明，最好不是靠单一测试，而是靠一组相互独立的证据链。

我建议给每个正式 VIP 强制要求下面 6 类证据：

1. **Spec Traceability**
   把协议规范条款映射到 VIP 能力。
   例如 AXI4：
   `SPEC-AXI-001 -> AW handshake checker -> TC-023/TC-024 -> COVERPOINT CP_AW`
   最终形成：
   `Protocol Requirement -> Implementation -> Test -> Coverage`
   这一步最关键，因为它证明“不是凭感觉说完整”。

2. **Self-Verification**
   VIP 必须有独立的 self-test bench。
   不要拿 DUT 顺便测 VIP，而要专门“故意制造合法/非法行为”来验证 VIP。
   比如：

   * 合法 transaction 必须不报错
   * 非法 burst 必须准确报错
   * 错误 response 必须捕获
   * backpressure / outstanding / reorder 都要验证
     最好支持 fault injection。

3. **Golden Model / Cross Check**
   对 transaction-level 行为，尽可能用独立 reference model 做比对。
   比如：

   ```text
   Stimulus
      ├─ VIP Driver -> DUT/Protocol Model
      └─ Reference Model
                 ↓
              Compare
   ```

   重点是 reference model 最好不要复用 VIP 内部实现代码，否则会形成“同源错误”。

4. **Checker Mutation Test**
   这是非常有效的一招。
   主动向协议行为注入错误：

   ```text
   handshake violation
   illegal burst
   invalid response
   ordering error
   timeout
   ID mismatch
   alignment error
   ```

   然后统计：

   > VIP 应该抓出的错误，实际抓出了多少。

   可以定义：
   `Checker Detection Rate = Detected Faults / Injected Faults`

   对一个优秀 VIP，我甚至建议这项成为发布门禁。

5. **Coverage Closure**
   不仅看 code coverage，而是至少看三层：

   * Protocol Requirement Coverage
   * Functional Coverage
   * Checker / Assertion Coverage

   比如 AXI：
   `burst_type × burst_len × size × outstanding × response × backpressure`

   还要特别关注：

   * 边界值
   * 最大/最小配置
   * 非法输入
   * 并发
   * reset 中断
   * timeout
   * ordering
   * 随机组合

6. **Independent Qualification**
   最好让 VIP 的开发者和 VIP 的 qualification 用不同的 test set。
   即：

   ```text
   VIP Developer
        ↓
   Development Tests

   Qualification
        ↓
   Independent Qualification Tests
   ```

   这样可信度会高很多。

我建议你直接给 VIP REPO 定义一个统一的 `qualification/`：

```text
vip/amba/axi4/
├── src/
├── tests/
├── docs/
└── qualification/
    ├── requirement_traceability.md
    ├── qualification_plan.md
    ├── qualification_report.md
    ├── fault_injection.md
    ├── coverage_report.md
    ├── known_limitations.md
    └── evidence/
```

其中 `requirement_traceability.md` 可以成为整个体系的核心，例如：

| Requirement | Capability   | Checker      | Test         | Coverage | Result |
| ----------- | ------------ | ------------ | ------------ | -------- | ------ |
| AXI-R001    | AW handshake | SVA-AW-01    | TC-AW-001    | CP-AW    | PASS   |
| AXI-R002    | Burst length | CHK-BURST-01 | TC-BURST-003 | CP-LEN   | PASS   |
| AXI-R003    | 4KB boundary | CHK-4KB-01   | TC-BURST-010 | CP-4KB   | PASS   |

这样你最终不是说：

> “我们跑了 5000 个 test，所以 VIP 是对的。”

而是说：

> “协议规范中的 100% 强制条款都被结构化建模，每一条都有实现、检查、测试和覆盖证据；同时通过 mutation/fault injection 证明 checker 能捕获预期错误。”

这个说服力完全不是一个量级。

我甚至建议最终给 VIP 定义一个 Qualification Score，例如：

```text
Requirement Traceability     100%
Mandatory Feature Coverage   100%
Functional Coverage          >= 95%
Checker Mutation Detection   100% mandatory / >=95% overall
Assertion Coverage           >= 95%
Regression Pass              100%
Known Critical Issues        0
```

但这里有一个重要认识：

**数字越高不一定越可信，traceability 比单纯 coverage 百分比更重要。**

所以我会把一个“优秀 VIP”的可信证据总结成一个闭环：

```text
SPEC
 ↓
Requirement Model
 ↓
VIP Capability
 ↓
Checker / Driver / Monitor
 ↓
Qualification Test
 ↓
Fault Injection
 ↓
Coverage
 ↓
Qualification Report
```

如果你后面要把这个真正纳入 `VIP Development Suite`，我建议再增加一个专门的 `vip-qualification` 阶段，最终只有生成完整 Qualification Evidence 的 VIP 才允许进入 VIP REPO 的 `Qualified` 状态。


可以。我建议先做一版“常用芯片研发 VIP 规划清单”，按优先级和复用价值组织，方便后续直接纳入 `vip_plan.md`。

### 推荐 VIP LIST

| 分类                              | VIP                        | 建议优先级 | 典型能力                                           |
| ------------------------------- | -------------------------- | ----: | ---------------------------------------------- |
| **AMBA / On-Chip Bus**          | AXI4 VIP                   |    P0 | Master / Slave / Monitor / Checker / Coverage  |
|                                 | AXI4-Lite VIP              |    P0 | Master / Slave / Monitor / Checker             |
|                                 | APB4 VIP                   |    P0 | Master / Slave / Monitor / Checker             |
|                                 | AHB-Lite VIP               |    P0 | Master / Slave / Monitor / Checker             |
|                                 | AXI-Stream VIP             |    P0 | Source / Sink / Monitor / Packet Check         |
|                                 | ACE-Lite VIP               |    P1 | Coherency-lite transaction verification        |
|                                 | ACE VIP                    |    P2 | Cache coherency verification                   |
|                                 | CHI VIP                    |    P2 | Coherent hub interface verification            |
| **Memory**                      | SRAM VIP                   |    P0 | Read / Write / Latency / ECC injection         |
|                                 | ROM VIP                    |    P1 | Read model / initialization                    |
|                                 | Generic Memory Model       |    P0 | Configurable latency / width / error injection |
|                                 | DDR Controller-side VIP    |    P1 | Command / data / timing model                  |
|                                 | Flash VIP                  |    P1 | Read / Program / Erase model                   |
|                                 | eFuse / OTP VIP            |    P1 | Program / read / lock / lifecycle behavior     |
| **Peripheral**                  | UART VIP                   |    P0 | TX / RX / baud / parity / framing error        |
|                                 | SPI VIP                    |    P0 | Master / Slave / CPOL / CPHA / multi-CS        |
|                                 | I2C VIP                    |    P0 | Master / Slave / arbitration / ACK-NACK        |
|                                 | GPIO VIP                   |    P0 | Input / Output / Interrupt stimulus            |
|                                 | Timer VIP                  |    P0 | Counter / compare / interrupt                  |
|                                 | Watchdog VIP               |    P0 | Timeout / reset / interrupt                    |
|                                 | PWM VIP                    |    P1 | Duty / period / edge checking                  |
|                                 | RTC VIP                    |    P1 | Counter / alarm / calendar behavior            |
| **Interrupt / Control**         | Generic Interrupt VIP      |    P0 | IRQ generation / priority / masking            |
|                                 | PLIC VIP                   |    P1 | RISC-V interrupt controller verification       |
|                                 | GIC VIP                    |    P1 | ARM interrupt subsystem verification           |
|                                 | Mailbox VIP                |    P1 | Core-to-core message verification              |
| **Clock / Reset / Power**       | Clock VIP                  |    P0 | Clock generation / jitter / frequency change   |
|                                 | Reset VIP                  |    P0 | POR / warm reset / reset sequencing            |
|                                 | Clock Reset VIP            |    P0 | CRG combined stimulus/check                    |
|                                 | Power Control VIP          |    P1 | Power state / isolation / retention            |
|                                 | DVFS VIP                   |    P1 | Voltage-frequency state transition modeling    |
| **DMA / Data Movement**         | DMA Traffic VIP            |    P0 | Configurable traffic generation                |
|                                 | Memory Traffic Generator   |    P0 | Burst / bandwidth / latency / congestion       |
|                                 | Descriptor Model VIP       |    P1 | Descriptor chain / ring behavior               |
| **Debug**                       | JTAG VIP                   |    P1 | TAP state / IR / DR / boundary scan            |
|                                 | SWD VIP                    |    P1 | ARM serial debug                               |
|                                 | RISC-V Debug VIP           |    P1 | DMI / debug module interaction                 |
| **Networking / IO**             | Ethernet MAC VIP           |    P1 | Frame generate / monitor / CRC                 |
|                                 | MDIO VIP                   |    P1 | PHY management                                 |
|                                 | PCIe VIP                   |    P2 | TLP / DLLP / link behavior                     |
|                                 | USB VIP                    |    P2 | Endpoint / transfer / protocol checking        |
|                                 | MIPI CSI/DSI VIP           |    P2 | Packet / lane behavior                         |
| **Storage**                     | SD / SDIO VIP              |    P1 | Command / data / card model                    |
|                                 | eMMC VIP                   |    P1 | Command / boot / data transfer                 |
|                                 | UFS VIP                    |    P2 | High-speed storage protocol                    |
| **Safety / Reliability**        | ECC Injection VIP          |    P0 | SEC/DED fault injection                        |
|                                 | Parity Error Injection VIP |    P0 | Register / memory parity injection             |
|                                 | Fault Injection VIP        |    P0 | Generic protocol / datapath fault injection    |
|                                 | Lockstep Comparison VIP    |    P1 | Dual-core / dual-path mismatch injection       |
| **Verification Infrastructure** | Generic Register VIP       |    P0 | Read/write/access-type checking                |
|                                 | CSR / RAL Access VIP       |    P0 | Register access stimulus                       |
|                                 | Stream VIP                 |    P0 | Generic valid-ready stream                     |
|                                 | Packet VIP                 |    P0 | Generic packet source/sink                     |
|                                 | Scoreboard Model VIP       |    P1 | Generic transaction compare                    |
|                                 | Performance Monitor VIP    |    P1 | Latency / bandwidth / outstanding statistics   |

我建议第一阶段不要铺太大，先收敛成 **P0 核心库**，大约 20 个左右：

```text
AXI4
AXI4-Lite
AXI-Stream
APB4
AHB-Lite

SRAM
Generic Memory

UART
SPI
I2C
GPIO
Timer
Watchdog

Interrupt
Clock
Reset
Clock-Reset

DMA Traffic
Memory Traffic Generator

Register / CSR
Generic Stream

ECC Injection
Parity Injection
Fault Injection
```

这批 VIP 的特点是：**协议简单或中等复杂、复用率极高、非常适合自研、几乎所有 IP / SoC 项目都会用到。**

反而像 `PCIe / DDR / USB / CHI / MIPI` 这种，我建议放到 P2，不要一开始就投入，因为要做到真正可信的完整 VIP，开发和 qualification 成本会高很多。

如果你希望直接进入 REPO，我还建议 `vip_plan.md` 用下面这些字段：

| ID      | VIP           | Category       | Priority | Profile       | Status  | HWIF  | Version | Owner | Qualification |
| ------- | ------------- | -------------- | -------- | ------------- | ------- | ----- | ------- | ----- | ------------- |
| VIP-001 | AXI4          | AMBA           | P0       | FULL_UVM      | Planned | axi4  | -       | -     | -             |
| VIP-002 | APB4          | AMBA           | P0       | FULL_UVM      | Planned | apb4  | -       | -     | -             |
| VIP-003 | SRAM          | Memory         | P0       | LIGHTWEIGHT   | Planned | sram  | -       | -     | -             |
| VIP-004 | Clock         | Infrastructure | P0       | LIGHTWEIGHT   | Planned | clock | -       | -     | -             |
| VIP-005 | ECC Injection | Safety         | P0       | CHECKER/MODEL | Planned | -     | -       | -     | -             |

其中 `Profile` 建议固定为：

`FULL_UVM / LIGHTWEIGHT / PASSIVE / CHECKER_ONLY / MODEL`

这样这个 VIP List 不只是“愿望清单”，而会直接成为 **VIP Development Suite 的开发 Backlog + VIP REPO 的产品路线图**。




