# vendor/manifests — 第三方来源 Manifest

每个拟引入的第三方来源一个 YAML Manifest，记录 G0 准入所需信息：
URL、锁定 commit、tag、作者、许可证、NOTICE、审计状态与使用方式。

## 现有清单

| Manifest | 来源 | 许可证 | 采用等级 |
|---|---|---|---|
| [`accellera-uvm-core.yaml`](accellera-uvm-core.yaml) | Accellera UVM Core | Apache-2.0 | A |
| [`lowrisc-opentitan.yaml`](lowrisc-opentitan.yaml) | OpenTitan | Apache-2.0 | A |
| [`tvip-axi.yaml`](tvip-axi.yaml) | TVIP-AXI | Apache-2.0 | A- |
| [`tvip-apb.yaml`](tvip-apb.yaml) | TVIP-APB | Apache-2.0 | B+ |
| [`pulp-common_verification.yaml`](pulp-common_verification.yaml) | PULP common_verification | Solderpad 0.51 | A- |
| [`pulp-axi.yaml`](pulp-axi.yaml) | PULP AXI | Solderpad 0.51 | A- |
| [`core-v-verif.yaml`](core-v-verif.yaml) | CORE-V-VERIF | Solderpad v2.0 | A- |
| [`chipsalliance-riscv-dv.yaml`](chipsalliance-riscv-dv.yaml) | riscv-dv | Apache-2.0 | A |
| [`cocotbext-axi.yaml`](cocotbext-axi.yaml) | cocotbext-axi | MIT | A- |
| [`zipcpu-wb2axip.yaml`](zipcpu-wb2axip.yaml) | wb2axip | Apache-2.0（需核查） | B+ |

> 模板见 [`_template.yaml`](_template.yaml)。参考克隆与完整来源记录见
> [`reference/REFERENCE_MANIFEST.md`](../../reference/REFERENCE_MANIFEST.md)。
