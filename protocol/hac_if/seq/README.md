# HAC-IF VIP Sequences

> 骨架目录。规划序列如下，实现待填充。

| 序列 | 说明 |
|---|---|
| `hac_ctrl_base_seq` | 单任务命令/完成基础序列 |
| `hac_ctrl_multi_job_seq` | 多任务与 Job ID 关联 |
| `hac_ctrl_cancel_seq` | Busy 期间取消 |
| `hac_mem_rw_seq` | 读/写访存基础序列 |
| `hac_mem_ooo_seq` | 跨 Tag 乱序序列 |
| `hac_stream_stress_seq` | 随机背压流序列 |
| `hac_event_seq` | 事件注入序列 |
| `hac_mgmt_drain_seq` | Drain/Quiescent 序列 |
| `hac_virtual_sequence` | Profile P0/P1/P2 编排入口 |
