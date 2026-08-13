# HAC-IF VIP（P0/P1/P2）

> HAC-IF（Hardware Accelerator Core Interface）UVM VIP，VLNV（规划）：`aix:vip:hac_if:1.0.0`。
> 依据 [`digest/hwif.md`](../../../../../digest/hwif.md:1) 第 19 节验证规划与 HWIF Repo 的 HAC-IF 契约。

- 优先级：**P0（CTRL/EVENT 先行，随后 MEM/STREAM）**
- 状态：规划中（骨架待生成）

## 计划能力

- `hac_ctrl_agent`：任务命令/完成/取消 Agent；
- `hac_stream_agent`：流式输入输出 Agent；
- `hac_mem_agent`：系统访存 Request/Response Agent；
- `hac_lmem_agent`：本地存储 Agent；
- `hac_event_agent`：事件 Agent；
- `hac_protocol_checker`：背压 Payload 稳定、Job ID 唯一、Tag 不提前复用、quiescent 无 Outstanding、Reset 后定义状态；
- `hac_scoreboard` / `hac_reference_memory`；
- `hac_error_injector`：超时、丢响应、重复响应、AXI 错误映射；
- `hac_coverage_model`：Profile×Capability 交叉、背压、乱序深度、错误×阶段；
- `hac_virtual_sequence`。

## 依赖

- `aix:vip:common:^1.0`
- HWIF `aix:interface:hac_if:0.1.0` 及各族接口

## 参考

- HAC-IF 协议规格：`aixsilicon_hwif_repo/accelerator/hac_if/spec/hac_if_spec.md`
- AXI Adapter 一致性验证环境：`cbb-repo components/hac_if/hac_axi_adapter`
