# fault_injection — 统一错误/故障注入

为所有 VIP 提供统一的错误注入框架，作为 `safety/` 功能安全 VIP 的基础。

## 能力

- 统一错误注入接口（正常 / 合法错误响应 / 协议异常）；
- 注入窗口（何时注入）、注入概率与随机种子控制；
- 与 Checker 的检测结果关联，用于负向测试与 mutation 测试；
- 与 Fault Campaign（`safety/fault_campaign/`）对接。

## 规划文件

- [`src/vip_fault_injector.sv`](src/vip_fault_injector.sv) — 注入器基类（规划中）
