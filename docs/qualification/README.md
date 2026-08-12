# Qualification 体系

本目录定义 VIP 的测试层次、质量 Gate 与第三方资产准入流程。

## 测试层次

| 层次 | 目标 |
|---|---|
| Structure Test | 文件、metadata、VLNV、依赖、Schema 正确 |
| Compile Test | 多仿真器编译与 elaboration 通过 |
| Component Unit Test | transaction、config、sequence、driver、monitor 单元行为正确 |
| Loopback Test | Master—Slave—Monitor 闭环 |
| Checker Negative Test | 每一类协议错误都能被检测 |
| Reference DUT Test | 在开源或内部黄金 DUT 上验证 |
| Cross-model Test | 与独立 VIP / BFM 对拍 |
| Stress Test | 长时间、随机 stall、多 Outstanding、reset 打断 |
| Mutation Test | 人为注入 DUT 或 VIP 缺陷，验证检测能力 |
| Integration Test | 在真实 IP、CBB 与 Subsystem 中复用 |

## 质量 Gate

| Gate | 出口条件 |
|---|---|
| V0 Prototype | 单仿真器编译，基本事务跑通，不允许正式项目依赖 |
| V1 Alpha | Master/Slave/Passive 基本完成，单元测试通过 |
| V2 Beta | 两个 DUT、两个仿真器、基础 coverage 与 negative test 通过 |
| V3 Qualified | RTM 闭环、协议覆盖达标、mutation test 通过、文档齐全 |
| V4 Proven | 至少两个项目使用并完成问题闭环，兼容矩阵稳定 |

正式 Catalog 默认只显示 `Qualified` 与 `Proven` 版本。

## 建议指标

- Requirement 覆盖率：100%；
- Planned Test 执行率：100%；
- Planned Functional Coverage 覆盖率：100%，覆盖点命中率按协议设 Gate；
- 所有 P0/P1 Protocol Checker 负向用例：100% 检测；
- 严重等级 S0/S1 缺陷：0；
- 至少 VCS / Xcelium / Questa 中的两种通过；
- 同一 seed 与同一工具版本可复现；
- Release 包包含命令、工具版本、日志 hash、源码 hash 与依赖锁定；
- 公共 VIP 不允许存在未声明的项目层次路径依赖。

## 文档

- [`third_party_admission.md`](third_party_admission.md) —— 第三方资产准入流程（G0~G5）
