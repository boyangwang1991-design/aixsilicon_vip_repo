# Reference 参考开源项目清单

本目录保存从开源社区下载的**参考项目**，用于架构研究、协议参考与交叉验证。
依据 `plan.md` 第 8、9 节：第三方代码不直接复制进本仓库源码目录，仅作为参考；
如需引入正式依赖，走 `vendor/` 准入流程（G0~G5）。

- 下载日期：2026-08-12
- 克隆方式：`git clone --depth 1`（浅克隆，锁定当前默认分支 HEAD）
- 更新策略：锁定 commit；如需升级必须更新本清单并重新审计

## 来源总表

| # | 目录 | 项目 | URL | 锁定 commit | 许可证 | 采用等级 | 备注 |
|---|---|---|---|---|---|---|---|
| 1 | [`uvm-core/`](uvm-core/) | Accellera UVM Core | https://github.com/accellera-official/uvm-core | `78c06547` | Apache-2.0 | A | IEEE 1800.2 参考实现，标准依赖基线 |
| 2 | [`opentitan/`](opentitan/) | OpenTitan | https://github.com/lowRISC/opentitan | `49df6acd` | Apache-2.0 | A | `hw/dv/sv` 含 cip_lib / dv_utils / csr_utils / tl_agent / push_pull_agent / uart_agent / spi_agent / i2c_agent / jtag_agent |
| 3 | [`tvip-axi/`](tvip-axi/) | TVIP-AXI | https://github.com/taichi-ishitani/tvip-axi | `cd53d927` | Apache-2.0 | A- | AXI 代码起点候选 |
| 4 | [`tvip-apb/`](tvip-apb/) | TVIP-APB | https://github.com/taichi-ishitani/tvip-apb | `948f88f5` | Apache-2.0 | B+ | 与自研 APB 骨架做对比 PoC |
| 5 | [`pulp-common_verification/`](pulp-common_verification/) | PULP common_verification | https://github.com/pulp-platform/common_verification | `c5d97a1f` | Solderpad 0.51 | A- | clk/reset、timeout、ready/valid、watchdog，含 FuseSoC Core |
| 6 | [`pulp-axi/`](pulp-axi/) | PULP AXI | https://github.com/pulp-platform/axi | `4da15979` | Solderpad 0.51 | A- | AXI 类型/测试组件/压力场景，作对拍 DUT |
| 7 | [`core-v-verif/`](core-v-verif/) | CORE-V-VERIF | https://github.com/openhwgroup/core-v-verif | `f3b1f971` | Solderpad v2.0（逐文件核查） | A- | 参考 SoC/CPU 环境分层与 ISS 协同 |
| 8 | [`riscv-dv/`](riscv-dv/) | CHIPS Alliance riscv-dv | https://github.com/chipsalliance/riscv-dv | `b7a0b4b0` | Apache-2.0 | A | RISC-V 随机指令生成与覆盖 |
| 9 | [`cocotbext-axi/`](cocotbext-axi/) | cocotbext-axi | https://github.com/alexforencich/cocotbext-axi | `b2d126c4` | MIT | A- | Python BFM 与 Memory Model，独立 oracle |
| 10 | [`wb2axip/`](wb2axip/) | ZipCPU wb2axip | https://github.com/ZipCPU/wb2axip | `2e8d3bc2` | Apache-2.0（README 声明，需逐文件核查） | B+ | AXI-Lite/APB 形式属性参考 |
| 11 | [`pulp-uvm-components/`](pulp-uvm-components/) | PULP uvm-components | https://github.com/pulp-platform/uvm-components | `666872eb` | Solderpad 0.51 | C | 已于 2025-11-28 归档，仅历史参考 |
| 12 | [`awesome-open-hardware-verification/`](awesome-open-hardware-verification/) | Awesome Open Hardware Verification | https://github.com/ben-marshall/awesome-open-hardware-verification | `0d3627b6` | MIT | 发现渠道 | 候选发现清单 |

## 重要目录（参考用途）

### OpenTitan `hw/dv/sv/`（最值得参考）

```text
hw/dv/sv/
├── cip_lib/
├── dv_utils/
├── csr_utils/
├── tl_agent/
├── push_pull_agent/
├── uart_agent/
├── spi_agent/
├── i2c_agent/
└── jtag_agent/
```

需要剥离的耦合：TL-UL、CIP 基类、HJSON/DVSim 配置、OpenTitan 目录假设、
专用 alert/interrupt 语义。本仓库统一到 YAML SSOT 与 FuseSoC。

### PULP common_verification（建议直接依赖或重构进入 DV Common）

- clk/reset、timeout、watchdog、ready/valid master/slave、随机等待；
- 含 FuseSoC Core，需核对具体许可证文件（Solderpad 0.51）。

### TVIP-AXI / TVIP-APB（代码起点候选）

- AXI4 / AXI4-Lite Master/Slave、乱序、延迟、RAL adapter/predictor；
- 引入前需补协议覆盖、SVA、更多工具兼容与完整自测。

## 使用与合规说明

1. 本目录仅为参考克隆，不作为本仓库编译依赖；
2. 如需引入，必须按 [`docs/qualification/third_party_admission.md`](../docs/qualification/third_party_admission.md) 的 G0~G5 流程审计；
3. GPL/AGPL、未知许可证或仅限非商业使用的资产默认不进入正式库；
4. 使用 Solderpad 系（pulp-*、core-v-verif）资产前必须经公司法务/开源办公室确认；
5. 本仓库原创代码与这些参考项目相互独立，版权归各自作者。

## 更新记录

- 2026-08-12：首次下载 12 个参考项目（浅克隆，锁定 HEAD commit）。
