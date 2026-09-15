# 示例入口

最小 UVM 环境为 self_test/tb/ahb_smoke_tb.sv 与 ahb_smoke_env.sv。混合宽度和 AHB5 扩展示例见 ahb_extensions_tb.sv，RAL 集成见 ahb_ral_tb.sv，四 Manager/四目标例程见 ahb_system_tb.sv。时钟与复位由环境提供，agent 不自行产生。

执行前按 [使用指南](../docs/user-guide.md)准备 build 内的冻结输入和输出路径；不要从源码目录直接调用仍采用旧路径的 make/工具入口。

验收范围和 AI 出口结论流程以 [验收说明](../docs/acceptance.md) 为准。历史工具输出已迁移至本 VIP/build，运行须指定 LOG_DIR 或 AHB_RUN_ROOT。
