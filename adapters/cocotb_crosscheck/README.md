# cocotb_crosscheck — cocotb 交叉验证

基于 cocotb 的独立 oracle 与交叉验证模型，用于验证 UVM VIP 的正确性。

## 参考模型

- [cocotbext-axi](https://github.com/alexforencich/cocotbext-axi)：AXI / AXI-Lite / AXI-Stream / APB Python BFM 与 Memory Model（MIT）；
- 用途：作为独立 oracle、快速原型与交叉验证模型，不替代 UVM VIP。

## 使用

- 内部 UVM Master ↔ cocotbext 参考 Slave；
- cocotbext BFM ↔ 内部 Slave 模型；
- 生成对拍报告并纳入 Qualification 证据。

> 需 Python 3.8+ 与 cocotb。当前系统 Python 为 3.6，运行时请使用项目提供的 venv。
