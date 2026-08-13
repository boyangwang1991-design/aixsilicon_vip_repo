# HAC-IF VIP Spec Control

- 协议族：HAC-IF（Hardware Accelerator Core Interface）
- 版本：V0.1（立项输入，`digest/hwif.md`）
- 受控位置：`aixsilicon_hwif_repo/accelerator/hac_if/`（契约 SSOT：YAML Contract / SV Interface / spec）

## 接口族

| 接口族 | 定位 |
|---|---|
| HAC-CTRL | 任务启动、接收、完成和取消 |
| HAC-STREAM | 流式输入输出 |
| HAC-MEM | 面向系统地址空间的访存请求/响应 |
| HAC-LMEM | 本地 SRAM/Scratchpad 访问 |
| HAC-EVENT | 完成、错误、性能及中断事件 |
| HAC-MGMT | 复位、功耗、隔离、调试和生命周期 |

## 全局不变量（Checker 依据）

1. `valid=1 && ready=0` 时 Payload 必须稳定；
2. `job_id` 在未完成任务集合中唯一；
3. `tag` 完成前不得重用；不同 `tag` 允许乱序，同一 `tag` 内保持顺序；
4. 每个请求最终完成或明确超时；
5. 完成不能无对应命令；
6. `quiescent` 时无 Outstanding；
7. Reset 后输出进入定义状态；
8. 不支持的 Capability 不得产生相关事务。

> 本文只做受控引用，不复制协议正文。
