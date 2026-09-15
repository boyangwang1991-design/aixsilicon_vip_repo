# AHB UVM VIP — 0.1.0 开发版本

本资产实现 AHB-Lite、AHB5 与 Classic 的部分能力，完整验收目标为 [169 条原始合同](docs/contract.md)。开发用例通过不等于完整 1.0.0 资格认证。

- [中文使用指南](docs/user-guide.md)
- [文档导航](docs/README.md)
- [最新综合报告](reports/qualification.md)

## 目录约定

reports/ 直接保存最新一轮的七类报告，以 qualification.md 为综合入口，不建立 run-id 子目录。日志、编译产物、波形、缓存、机器中间数据和历史归档全部放在本 VIP 的 build/，不使用工作区根 build，不提交或上传 build。

## 运行入口

使用宿主 uv 环境，先按使用指南在本 VIP 的 build 内适配并冻结执行输入，再调用最新版 suite。tools 已接入 AHB_RUN_ROOT；实际执行使用 build 内源码快照，并显式设置本 VIP/build 下的运行根。src 和测试断言的变更、运行适配、证据复核应分别记录；不静默沿用旧 PASS。

验收范围和 AI 出口结论流程以 [验收说明](docs/acceptance.md) 为准。历史工具输出已迁移至本 VIP/build，运行须指定 LOG_DIR 或 AHB_RUN_ROOT。

## 当前资格状态

版本验收清单为draft，当前不授权出口；历史执行通过及旧候选不等于新版本验收完成。以 [当前总览](reports/latest.md) 和 [版本验收说明](docs/acceptance.md) 为准。
