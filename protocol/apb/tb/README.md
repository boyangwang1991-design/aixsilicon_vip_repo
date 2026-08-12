# tb — APB Testbench

自检测试环境（VIP 内部验证用，不属于项目 Testbench）。

## 文件

- [`apb_smoke_tb.sv`](apb_smoke_tb.sv) — smoke 顶层（时钟/复位、接口、DUT 占位、UVM harness）
- [`apb_smoke_env.sv`](apb_smoke_env.sv) — 最小环境：Master Agent + Slave Agent + Monitor
- [`apb_smoke_test.sv`](apb_smoke_test.sv) — smoke 测试用例

## 运行

```bash
fusesoc run --target=smoke aix:vip:apb:1.0.0
```
