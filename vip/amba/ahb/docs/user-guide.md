# AHB VIP 使用指南

## 1. 简介

0.1.0 开发候选；完整 1.0.0 合同尚需验收。本指南描述实际 API、运行边界和已知限制。

## 2. 能力

参数化 Manager/Subordinate/Passive agent、流水、burst、等待/错误/复位、稀疏存储、exclusive、AHB5 strobe/USER/parity、Classic 仲裁/RETRY/SPLIT、RAL 与桥接记分板。实现存在不等于已完成全协议认证。

## 3. 目录

src/config/docs/unit_test/self_test/examples 是稳定输入；reports/qualification.md 是最新流程报告。运行根的 logs/evidence/coverage/metadata/gates/work/core 是可复现产物，全部位于本 VIP 的 build，不提交或上传。

## 4. 依赖

宿主 uv 环境、GNU make、VCS/UVM1.2 和有效许可证。无需子仓虚拟环境。

## 5. 构建与运行

从 workflow 根目录使用宿主 uv 环境。运行前核对输出路径；当前 tools 下的历史入口仍会写旧 reports 路径，不得直接调用。

1. 在本 VIP 的 build 内建立独立输入副本，保留 src 和测试断言，适配工具 cwd、LOG_DIR、临时目录及原始数据输出路径。
2. 核对 config/verification-plan.yaml 和 config/build.yaml，冻结本次输入。所有 169 条需求仍在验收分母中。
3. 将 AHB_INPUT 设置为该输入副本的绝对路径，使用显式的新运行 ID：

```bash
uv run --no-sync python .roo/skills/vip-development-suite/scripts/vip_tool.py regression \
  --root "$AHB_INPUT" --vip ahb --tier full --seed 1 --run-id "$AHB_RUN_ID"
```

suite 默认使用该输入自身的 build；由于输入已在 AHB/build 内，所有产物仍在真实 AHB 的 build 树下。不可把 --build-root 指向工作区根。补充等待、种子、压力和变异测试必须使用相同冻结输入和指定的运行根。

脚本记录命令和日志，AI 分析后撰写 metadata，再运行 report-check/qualify。最新六份阶段报告直接保存在源 reports 中，latest.md 提供综合入口。冻结执行副本仍在 build 中保留供原判定复核。最新报告记录实际命令和证据路径，历史 PASS 不直接沿用。

## 6. 接口连接

ahb_if 的结构参数顺序 AW,DW,BW,PW,MW,AU,DU,RU,PROFILE,SECURE,EXCLUSIVE,STROBE,PARITY 必须与 agent 和 config_db 的 vif 类型一致。PROFILE 0/1/2 分别为 Lite/AHB5/Classic。HREADY 必须由数据阶段目标选择。clocking 输入 #1step、输出 #0；复位建议在 negedge 释放。

## 8. 基本配置

通过 factory 创建 ahb_config，设置与接口匹配的宽度/特性和 mode，build 前用 config_db 设置 cfg 与精确参数化 vif。结构配置在 build 冻结，响应策略在地址接受时取快照。参照 ahb_extensions_tb 的混合宽度实例。

## 11. 发送事务

继承 ahb_base_seq，在 agent.sequencer 上启动；submit 入队、get_response 等完成、transfer 合并两步，write/read 使用总线 lane 格式，burst_transfer 收集突发响应。raw=1 仅供故意违规注入。返回状态区分 ERROR、EXCLUSIVE_FAIL、RESET_ABORT、WATCHDOG、CANCEL_BEFORE_ACCEPT、RETRY、SPLIT；原始 HRESP 单独保留。

## 18. 模型扩展

config_db 的 policy 注入 ahb_response_policy；select_response 决定等待和响应。memory 注入 ahb_memory；peek/poke/load/dump、初始化策略与预约可用。read-clear/W1C/FIFO 在成功完成时产生副作用；失败写默认不提交。后门避开采样边沿；同址并发共享存储未提供调度无关仲裁保证。

## 20. 独立观测

monitor.transaction_ap/request_ap/cycle_ap/error_ap/burst_ap 分别发布完成、地址、周期、诊断和有界突发块。订阅对象只读，编辑前 clone。history_limit 限制历史；bounded_chunk 不等于协议突发结束。只看协议无法推断未初始化数据的正确性。

## 25. 覆盖

AHB_BIN/AHB_STATS 为诊断导出；只能在模型与配置匹配时按 bin 合并。全合同覆盖仪器化缺口必须保留。

## 29. RAL

ahb_reg_adapter 设置 cfg 并连接 map/manager sequencer；monitor.transaction_ap 连接 predictor.bus_in。预测只采纳成功完成；无 HWSTRB 的稀疏使能拒绝，不自动读改写。

## 34. 系统比较

ahb_bridge_scoreboard 按路径处理上下游完成字节；translation policy 指定宽度、端序、地址映射、错误扇出与属性变换。USER 需显式映射；缺失/重复字节在 check_phase 失败。不据单条路径推断 CDC、全系统原子性或一致性。

## 37. 常见问题

vif 类型不匹配先检查结构参数；持续等待检查数据阶段 HREADY；初次读 X 检查 INIT_X/预装载；缺响应检查 sequence 是否被提前终止。工具执行失败保留原始日志。

## 39. 机器合同

verification-plan.yaml 冻结集合；report-context 输出身份；报告仅一个 VIP_METADATA 块，遵循 vip.execution/v1。

## 41. 限制

S2/S3 全文、第二工具/IEEE1800.2、完整 feature dependency 与交叉、所有 checker 正负向、系统原子性/可见性、USER 转换和 sequence kill/re-submit 尚需验收。

## 42. 版本

0.1.0 未等同于正式发布 1.0.0；目录整理和重跑不自动更新 registry/catalog。

## 43. 问题报告

提供剖面、工具/UVM版本、seed、源指纹、规则 ID、命令与 build 日志。报告正文用中文。

## 45. 指南检查

命令、API、角色、时序、模型、独立观测与限制对应当前实现。

## 46. 完成定义

可复现执行记录与显式完整合同状态齐备；指南不能代替 RTM 验收。

验收范围和 AI 出口结论流程以 [验收说明](acceptance.md) 为准。历史工具输出已迁移至本 VIP/build，运行须指定 LOG_DIR 或 AHB_RUN_ROOT。
