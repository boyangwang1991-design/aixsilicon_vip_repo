# 实现路线图

> 依据 `plan.md` 第 13 节。以下按 5 人核心团队估算：
> 1 名架构/负责人、2 名 VIP 工程师、1 名 DV Flow/CI 工程师、1 名验证与 Qualification 工程师；
> 形式验证、法务/开源合规与协议专家兼职支持。

## 阶段 0：立项与技术选型（2 周）

- VIP Charter 与仓库边界；
- UVM 版本与仿真器基线（UVM 1.2 与 IEEE 1800.2 兼容策略）；
- VIP Metadata / Testplan / Release Manifest Schema；
- 开源候选清单与 License Review 模板；
- APB、AXI 开源 PoC 方案；
- P0 需求基线与 TODO Board。

## 阶段 1：公共底座（4 周）

- 仓库骨架（本仓库已完成）；
- `aix:vip:common`；
- FuseSoC target 模板；
- Clock/Reset、Ready/Valid 基础组件；
- CI 最小闭环；
- 文档、Testplan、Coverage 模板；
- Catalog 导出器初版。

> 出口：新建 VIP 可以由模板在 1 天内生成骨架并跑通 smoke。

## 阶段 2：APB 与系统基础 VIP（6 周）

- APB VIP、Generic Memory VIP、Interrupt VIP、CSR/RAL adapter；
- OpenTitan / TVIP / PULP 候选审计与对拍。

> 出口：APB 达到 V3 Qualified，其余达到 V2 Beta；至少接入一个真实 IP。

## 阶段 3：AXI4-Lite 与 AXI-Stream（8 周）

- AXI4-Lite VIP、AXI-Stream VIP；
- SVA / Protocol Checker；
- cocotbext / PULP 交叉验证；
- reset / backpressure / error / mutation 测试；
- 多仿真器兼容。

> 出口：AXI4-Lite 达到 V3，AXI-Stream 达到 V2。

## 阶段 4：完整 AXI4（10~12 周）

- Burst、ID、Outstanding、乱序、窄传输、非对齐、4KB 边界；
- 高并发 Master 与可编程 Slave responder；
- Memory model 与 scoreboard adapter；
- 性能监测、协议覆盖与大量负向测试；
- 与 TVIP-AXI、PULP AXI 及可用商业 VIP 交叉验证。

> 出口：AXI4 达到 V2 Beta；完整 AXI 不应因赶节点而提前标为 Qualified。

## 阶段 5：外设与 SoC 服务 VIP（8~12 周）

- UART、SPI/QSPI、I2C、JTAG/DMI、Boot Host、Power State；
- 复用 OpenTitan Agent 架构，去除 TL-UL 与 CIP 耦合。

## 阶段 6：功能安全与规模化运营（持续）

- Bus / Interrupt / ECC / Clock / Reset 故障注入；
- Fault Campaign Schema 与自动执行；
- PIC、总线安全、CRG、存储安全机制接入；
- 质量 Dashboard；
- UVM Verification Skill 自动选型、装配与 Gate。

## 出口定义（一期完成）

- P0 VIP 具有稳定 VLNV 与 FuseSoC 依赖；
- APB、AXI4-Lite 等至少一个主干 VIP 达到 Qualified；
- 至少两个真实项目成功复用；
- 开源来源、许可证、修改与 SBOM 可追踪；
- Requirement / Test / Coverage / Evidence 闭环；
- Checker 通过负向与 mutation 测试证明检测能力；
- 多仿真器兼容；
- Catalog 可查询能力、版本、质量与兼容关系；
- UVM Verification Skill Suite 能自动发现并装配 VIP；
- 项目不再重复生成 APB/AXI/UART 等基础 Agent。
