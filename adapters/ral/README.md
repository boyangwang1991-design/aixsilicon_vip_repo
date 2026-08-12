# ral — UVM RAL 适配

统一 RAL adapter / predictor 封装，供各协议 VIP（APB、AXI-Lite 等）复用。

## 内容

- 各 VIP 的 `*_ral_adapter`（如 `protocol/apb/src/apb_ral_adapter.sv`）；
- predictor 与 frontdoor/backdoor 访问的统一基类（规划中）。

## 依赖

- SystemRDL / PeakRDL 生成的寄存器模型（CSR 定义属于 IP 仓库，不在本仓库重复定义）。
