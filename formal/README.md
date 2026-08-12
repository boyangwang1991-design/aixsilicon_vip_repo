# formal — 形式验证

协议属性（SVA）与 formal harness，用于协议属性形式验证（可选 Target）。

| 子目录 | 内容 |
|---|---|
| [`protocol_properties/`](protocol_properties/) | 各协议的属性断言库（与 SVA 复用） |
| [`harness/`](harness/) | formal 顶层与环境（时钟/复位/假设） |

## 参考

- [ZipCPU wb2axip](https://github.com/ZipCPU/wb2axip)：AXI-Lite / APB / Wishbone 形式属性与反例经验（Apache-2.0）；
- [Accellera OVL](https://www.accellera.org/downloads/standards/ovl)：通用 Assertion Checker（Apache-2.0 条款）。
