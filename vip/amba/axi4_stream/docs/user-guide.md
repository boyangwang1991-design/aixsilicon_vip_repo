# axi4_stream VIP User Guide（用户指南）

> 本文件是源码设计文档，按实际实现编写。不在此填写本次执行结果。

> **VIP Name**: `axi4_stream`
> **Protocol / Interface**: `AMBA AXI4-Stream（ARM IHI 0051A）`
> **Version**: `1.0.0`
> **Release Status**: `Draft`（未发布；资格判定由 `vip_tool.py qualify` 计算）
> **VLNV**: `aixsilicon:vip:axi4_stream:1.0.0`
> **Supported Profile**: `FULL_UVM`（同时支持 PASSIVE agent 角色）
> **Supported Simulator**: `VCS W-2024.09-SP1`（已验证环境）
> **UVM Version**: `1.2`

---

# 1. Introduction

`axi4_stream` 是面向 AMBA AXI4-Stream 的可复用验证组件：提供 Source 主动激励、
Sink 背压接收、Passive 监测、协议检查（UVM checker + SVA）、功能覆盖、
错误注入、性能统计与端到端比较。

设计/验证过程请参考：

```text
docs/requirement.md       What（需求）
docs/architecture.md      How（架构）
docs/validation-plan.md   验证策略
docs/rtm.md               追溯
```

---

# 2. Capabilities

* Source agent：零气泡流水发送、idle 间隔、packet/beat API、多 stream 交织。
* Sink agent：9 种 ready 策略（背压）。
* Monitor：独立采样、按 `(interface_id, epoch, TID, TDEST)` 组包、5 个 analysis port。
* Checker：15 条规则、五类区分（PROTOCOL/APPLICATION/WATCHDOG/CONFIG/VIP_INTERNAL）。
* SVA：`axi4_stream_assertions` 可 bind 或例化。
* Coverage：10 个 covergroup + 重点交叉。
* Scoreboard：EXACT_BEAT / LOGICAL_STREAM / CUSTOM 三模式。
* 统计：accepted/data/position/null bytes、包计数、idle、`valid&&!ready`、吞吐/利用率。

**不支持**：AXI memory-mapped（AW/W/B/AR/R）、RAL、AXI5-Stream 扩展、
pass-through BFM、CDC 亚稳态证明。

---

# 3. Package

```systemverilog
import axi4_stream_pkg::*;      // 唯一对外 package
```

接口类型 `axi4_stream_if` 在 `src/axi4_stream_if.sv` 中定义；纯语义函数在
`axi4_stream_types_pkg`（由 `axi4_stream_pkg` 转出）。

---

# 4. Dependencies

* UVM 1.2（`-ntb_opts uvm-1.2`）。
* SystemVerilog：class / constraint / covergroup / SVA / 四态 `logic`。
* 无 DPI、无第三方库、无 RAL。

---

# 5. Build

```bash
# FuseSoC
fusesoc run --target=smoke aixsilicon:vip:axi4_stream:1.0.0
# 或直接使用 self_test/Makefile（BUILD_DIR/LOG_DIR 必须位于 build/ 下）
make -C self_test compile BUILD_DIR=$PWD/build/dev LOG_DIR=$PWD/build/dev/logs
```

---

# 6. Interface Connection

```systemverilog
axi4_stream_if #(
  .DATA_WIDTH(64), .ID_WIDTH(4), .DEST_WIDTH(2), .USER_WIDTH(8),
  .HAS_TDATA(1'b1), .HAS_TREADY(1'b1), .HAS_TKEEP(1'b1),
  .HAS_TSTRB(1'b0), .HAS_TLAST(1'b1)
) s_axis (.aclk(aclk), .aresetn(aresetn));

assign dut.s_axis_tdata  = s_axis.tdata;
assign s_axis.tready     = dut.s_axis_tready;
```

* 时钟/复位由**顶层**统一驱动（REQ-RST-001）；流 agent 只响应复位。
* 缺省端口保留 1 bit 占位；行为与检查按 `exists_*()` 裁剪。
* `TID/TDEST/TUSER` 的存在性由对应宽度参数 > 0 决定。

---

# 7. Agent Modes

| 角色 | 说明 | 创建组件 |
|---|---|---|
| `AXIS_ROLE_SOURCE` | 主动发送 | monitor + driver + sequencer（+ env 级 checker/coverage） |
| `AXIS_ROLE_SINK` | 只驱动 TREADY | monitor + sink_driver |
| `AXIS_ROLE_PASSIVE` | 只观测 | monitor |

```systemverilog
cfg.role = AXIS_ROLE_SOURCE;  cfg.role_configured = 1'b1;   // 必须显式设置
uvm_config_db#(axi4_stream_config)::set(null, "uvm_test_top.env.src_agent", "cfg", cfg);
uvm_config_db#(virtual axi4_stream_if)::set(null, "uvm_test_top.env.src_agent", "vif", vif);
```

---

# 8. Configuration

```systemverilog
axi4_stream_config cfg = axi4_stream_config::type_id::create("cfg");
cfg.data_width = 64; cfg.id_width = 4; cfg.dest_width = 2; cfg.user_width = 8;
cfg.has_tkeep = 1'b1; cfg.has_tstrb = 1'b0; cfg.has_tlast = 1'b1;
cfg.role = AXIS_ROLE_SOURCE; cfg.role_configured = 1'b1;
cfg.packet_mode = AXIS_PKT_TLAST; cfg.packet_mode_configured = 1'b1;
cfg.compare_mode = AXIS_CMP_EXACT_BEAT;
cfg.max_open_streams = 256; cfg.max_packet_beats = 65536;
cfg.max_ready_wait = 0;   // 0 = 关闭 watchdog
```

`validate()` 在 agent `build_phase` 执行；非法配置（宽度非 8 倍数、
HAS_TDATA=0 开 TKEEP、宽度越界等）会以 `uvm_fatal` 报告配置名/值/原因。

---

# 9. Config Profiles

| Profile | 效果 |
|---|---|
| `AXIS_PROFILE_DEFAULT` | 不改动 |
| `AXIS_PROFILE_ZERO_DELAY` | 无额外背压（配 ALWAYS_READY） |
| `AXIS_PROFILE_HEAVY_BACKPRESSURE` | `max_queue_depth=256` |
| `AXIS_PROFILE_STRESS` | `max_packet_beats=1000000`、STREAMING capture、`history_limit=8192` |
| `AXIS_PROFILE_PASSIVE` | `role=PASSIVE` |

```systemverilog
cfg.apply_profile(AXIS_PROFILE_STRESS);
```

---

# 10. Environment Integration

```systemverilog
class my_env extends uvm_env;
  axi4_stream_smoke_env axis_env;   // 或在自建 env 中分别例化 agent/checker/coverage
  function void build_phase(uvm_phase phase);
    axis_env = axi4_stream_smoke_env::type_id::create("axis_env", this);
  endfunction
endclass
```

`axi4_stream_env` 提供 checker/coverage/scoreboard 的同接口装配；
`axi4_stream_smoke_env` 提供 source→sink 双侧闭环。

---

# 11. Sending

```systemverilog
axi4_stream_multi_packet_seq seq = axi4_stream_multi_packet_seq::type_id::create("seq");
seq.set_config(cfg);
seq.n_packets = 4; seq.n_beats = 8;
seq.start(env.src_agent.sequencer);
```

---

# 12. Sequence API

| 序列 | 用途 |
|---|---|
| `axi4_stream_single_beat_seq` | 单 beat 单字节包 |
| `axi4_stream_multi_packet_seq` | 多包 |
| `axi4_stream_random_length_seq` | 随机长度（`min_bytes`/`max_bytes`） |
| `axi4_stream_boundary_length_seq` | 0/1/lane-1/lane/lane+1/255 字节 |
| `axi4_stream_data_pattern_seq` | 全 0/全 1/递增/walking-one |
| `axi4_stream_qualifier_seq` | 稀疏 keep/POSITION/NULL/全 NULL TLAST/仅 POSITION |
| `axi4_stream_stall_seq` | idle 间隔 |
| `axi4_stream_multi_key_seq` | 多 key、逐 beat 交织或每包切换 |
| `axi4_stream_continuous_seq` | 无 TLAST 连续流 |
| `axi4_stream_error_inject_seq` | 协议错误注入（`inject_rule`） |
| `axi4_stream_stress_seq` | 压力 |

公共字段：`n_beats`、`n_sequences`、`idle_cycles`、`key`。

---

# 13. High-Level API

```systemverilog
byte unsigned bytes[$];
bytes = '{8'hde, 8'had, 8'hbe, 8'hef, 8'h00};   // 5 字节
seq.send_bytes(bytes);                            // 自动拆成 2 拍（4+1）
seq.send_beats(16, .last_on_final(1'b1));         // 16 拍，末拍 TLAST
```

packet API：

```systemverilog
axi4_stream_packet_item pkt = axi4_stream_packet_item::type_id::create("pkt");
pkt.from_bytes(bytes, key, cfg.has_tkeep, cfg.byte_lanes());   // 无 TKEEP 且长度不可表达时返回 0
pkt.from_beats(beats, key);
pkt.append_beat(beat);
```

---

# 14. Random

所有序列使用 `$urandom`；seed 由命令行的 `+ntb_random_seed`（仿真器）与
`+AXIS_SEED`（VIP）双通道提供，便于重放。

---

# 15. Scenario

多 key 交织：`kseq.per_beat_interleave = 1'b1`、`kseq.n_keys = 4`、`kseq.beats_per_key = 6`。
逐 key 包切换：`per_beat_interleave = 1'b0`。

---

# 16. Active Target（Sink）

| 策略 | 说明 | 关键字段 |
|---|---|---|
| `AXIS_READY_ALWAYS` | 持续接收 | - |
| `AXIS_READY_FIXED_DELAY` | 观察 valid 后延迟 N 拍 | `delay`（N=0 合法） |
| `AXIS_READY_RANDOM` | 随机 ready | `prob_percent`、`max_stall`、`seed` |
| `AXIS_READY_PERIODIC` | 高 M 低 N | `high_cycles`、`low_cycles` |
| `AXIS_READY_WAIT_VALID` | 等 valid 再 ready | - |
| `AXIS_READY_BURST_ACCEPT` | 收 K 停 N | `burst_k`、`burst_n` |
| `AXIS_READY_TARGETED` | 每第 K 拍施加背压 | `target_beat` |
| `AXIS_READY_BUFFER_MODEL` | 按深度与消费速率 | `buffer_depth`、`consume_rate` |
| `AXIS_READY_SCRIPTED` | 脚本/回调 | `enable`、`repeat_count` |

```systemverilog
axi4_stream_ready_item rp = axi4_stream_ready_item::type_id::create("rp");
rp.mode = AXIS_READY_RANDOM; rp.prob_percent = 70; rp.max_stall = 5; rp.seed = 42;
uvm_config_db#(axi4_stream_ready_item)::set(null, "*snk_agent*", "ready_policy", rp);
// 或运行期更换（只影响背压语义，不影响组包/比较语义）：
env.snk_agent.sink_driver.set_ready_policy(rp);
```

---

# 17. Target Response

Sink 只驱动 TREADY，不修改 DUT 驱动信号；接收数据全部来自 monitor。

---

# 18. Behavior Customization

扩展 compare 行为：继承 `axi4_stream_reference_model` 并覆盖 `predict()`，
配 `cfg.compare_mode = AXIS_CMP_CUSTOM`。

扩展应用规则：`checker.set_rule_enable("AXIS-A001", 1'b1)` 并实现应用约束。

---

# 19. Memory / Data

**N/A**：AXI4-Stream 无地址/存储语义。

---

# 20. Passive

`cfg.role = AXIS_ROLE_PASSIVE` 时只创建 monitor；PASSIVE 不写任何总线或时钟复位信号。
旁路中途启用时 monitor 会标记 `PARTIAL_CAPTURE`，第一个包不可用于完整比较。

---

# 21. Observation

| Port | 元素 | 时机 |
|---|---|---|
| `beat_ap` | `axi4_stream_observed_beat` | 仅完成握手 |
| `packet_ap` | `axi4_stream_observed_packet` | 包结束/增量输出 |
| `error_ap` | `axi4_stream_error_event` | 违规与内部告警 |
| `reset_ap` | `axi4_stream_observed_packet` | 复位中止未完成包 |
| `cycle_ap` | `axi4_stream_observed_beat` | 每拍原始采样（可含未完成/非法） |

```systemverilog
env.src_agent.monitor.packet_ap.connect(my_scoreboard.imp);
```

---

# 22. Checker

```systemverilog
checker.set_rule_enable("AXIS-W001", 1'b1);
checker.set_rule_severity("AXIS-W001", AXIS_SEV_WARNING);
checker.set_rule_max_report("AXIS-P004", 10);
int hits = checker.rule_hits("AXIS-P004");
```

---

# 23. Violation

`axi4_stream_error_event` 字段：`rule_id`、`category`、`severity`、`interface_id`、
`reset_epoch`、`timestamp`、`cycle`、`before_sample`、`after_sample`、`key`、
`packet_beat_index`、`injection_ref`、`description`。

---

# 24. Assertions

```systemverilog
axi4_stream_assertions #(.HAS_TREADY(1'b1), .HAS_TKEEP(1'b1), .HAS_TSTRB(1'b0))
u_sva (.aclk(aclk), .aresetn(aresetn), .tvalid(vif.tvalid), .tready(vif.tready),
       .tdata(vif.tdata[7:0]), .tkeep(vif.tkeep[0]), .tstrb(vif.tstrb[0]), .tlast(vif.tlast));
```

或 `bind axi4_stream_if axi4_stream_assertions u_bind (...);`

---

# 25. Coverage

`axi4_stream_coverage` 是 `uvm_subscriber #(axi4_stream_observed_beat)`：
`beat_ap` 直接连接其 `analysis_export`；error/reset 事件经
`axis_error_sub`/`axis_reset_sub` 转发（`sample_error`/`sample_reset`）。

逐组开关：`cfg.cov_handshake_enable` … `cfg.cov_transform_enable`。

---

# 26. Error Injection

```systemverilog
axi4_stream_beat_item b = seq.make_beat('1, keep, strb, 1'b0);
b.inject_enable = 1'b1;
b.inject_rule   = "AXIS-P004";   // stall 中修改 TDATA
```

支持：`AXIS-P003`（撤销 VALID）、`AXIS-P004`（改 TDATA）、
`AXIS-P004-KEEP/-LAST/-ID`、`AXIS-P005`（TKEEP=0/TSTRB=1）。
注入缺省关闭；禁止全局关闭 checker 来运行负向测试。

---

# 27. Reset

* 复位由顶层驱动；`aresetn` 低有效。
* driver 等待复位释放后开始驱动；在途 beat 标 `AXIS_ST_ABORTED_BY_RESET`。
* monitor 增加 `reset_epoch` 并在 `reset_ap` 发布被中止包。
* 排队未发送 item 默认 FLUSH（`cfg.reset_retain_queued` 可改为 RETAIN）。
* CDC 两侧独立复位必须显式配置 `cfg.cdc_reset_configured` 与 `cdc_reset`。

---

# 28. Timeout

`cfg.max_ready_wait` / `cfg.max_packet_idle` 缺省 0（关闭）。
启用后分别由 AXIS-W001（WARNING）与 AXIS-W002（WATCHDOG）报告。
TB 亦应设置自己的仿真级 timeout。

---

# 29. RAL

**N/A**：AXI4-Stream 无寄存器访问语义。

---

# 30. Runtime

```systemverilog
env.snk_agent.sink_driver.set_ready_policy(new_policy);   // 运行期可换
cfg.begin_semantic_update(1'b1);   // 语义配置更新须在 drain/复位后，epoch+1
```

---

# 31. Statistics

```systemverilog
longint accepted, data_bytes, pos, nullb, pkts, aborts, idle, vnr, active, max_wait;
env.src_agent.monitor.get_stats(accepted, data_bytes, pos, nullb, pkts, aborts,
                                idle, vnr, active, max_wait);
int open_pkts = env.src_agent.monitor.open_packet_count();
```

---

# 32. Logging

driver 的每拍信息在 `UVM_HIGH`；env 汇总在 `UVM_LOW`；
建议调试时 `+UVM_VERBOSITY=UVM_HIGH`。

---

# 33. Recording

`axi4_stream_observed_packet` 支持 `to_tokens()` 输出逻辑流 token，便于导出与重放比对。

---

# 34. Extension

* `axi4_stream_reference_model`：CUSTOM 比较、路由重写合同。
* ready policy 的 SCRIPTED 模式预留用户回调位。
* 应用规则 AXIS-A001/A002 缺省关闭，由应用启用。

---

# 35. Config Dump

`cfg.convert2string()` 输出全部关键字段（含 epoch）；
`event.convert2string()` 输出结构化的违规上下文。

---

# 36. Debug

1. 检查 `cfg.validate()` 是否 fatal（配置问题最先暴露）。
2. 检查 `check_vif()` 是否 fatal（vif 与 cfg 参数不一致）。
3. `UVM_HIGH` 下看 driver 的 `stall=` 与 `handshake` 行。
4. 看 env 汇总的 `SCOREBOARD matched/mismatched/unexpected/dropped/unknown`。

---

# 37. Common Issues

| 现象 | 原因与处理 |
|---|---|
| `未获取 virtual interface` | 未对 `*_agent`（及其 monitor/driver 子路径）设置 `vif` |
| `ROLE 未显式设置` | 忘记 `cfg.role_configured = 1'b1` |
| `virtual interface 与 config 参数不一致` | vif 参数与 cfg 镜像不一致，改一处即可 |
| `get_next_item called twice ...` | 自定义 driver 未配对 `item_done()` |
| `未匹配到 expected 包` | DUT 非透明（需 LOGICAL_STREAM 或 CUSTOM）、或串接了两侧 monitor 顺序错误 |
| `结束仍有 N 个 expected 包未匹配` | DUT 丢包，或 expected 队列未按 reset/drop 合同结算 |
| `AXIS-P004 ... 必须保持稳定` | 真实违反稳定性，或把背靠背新 beat 误当 stall（检查 `prev_stall` 语义） |
| `TVALID 有效时 TUSER ... 不得为未知` | item 的 `user` 未初始化（4 态默认 X），显式赋 `'0` |
| `PARTIAL_CAPTURE` warning | 监控中途启用；严格验收应从复位开始抓 |

---

# 38. Usage（端到端示例）

```systemverilog
// 1) 双侧 agent + 端到端比较
axi4_stream_smoke_env env = axi4_stream_smoke_env::type_id::create("env", this);
uvm_config_db#(axi4_stream_config)::set(null, "*env.src_agent", "cfg", src_cfg);
uvm_config_db#(axi4_stream_config)::set(null, "*env.snk_agent", "cfg", snk_cfg);
uvm_config_db#(virtual axi4_stream_if)::set(null, "*env.src_agent",  "vif", src_vif);
uvm_config_db#(virtual axi4_stream_if)::set(null, "*env.snk_agent",  "vif", snk_vif);

// 2) 发数据
axi4_stream_multi_packet_seq seq = ... ; seq.set_config(src_cfg);
seq.start(env.src_agent.sequencer);
```

完整可运行示例见 `self_test/tb/axi4_stream_smoke_tb.sv` 与 `examples/`。

---

# 39. Metadata

运行报告与门禁 metadata 契约见套件 `references/report-metadata.md`。

---

# 40. Examples

| 示例 | 位置 |
|---|---|
| Source → register slice → Sink | `self_test/tb/axi4_stream_smoke_tb.sv` |
| Fixture（reg slice / FIFO / width up / router / fault） | `self_test/tb/axi4_stream_dut_fixtures.sv` |
| 集成模板 | `examples/axi4_stream_example_top.sv` |

---

# 41. Limitations

见 `docs/requirement.md` §23。要点：无全局 PASS 声明；Arm 逐规则章节映射未完成；
无公共 HWIF 复用（development binding）；CDC 不证明亚稳态安全；
无 pass-through BFM；无 AXI5-Stream 扩展；CHECKER_ONLY 独立构建路径未单独评审。

---

# 42. Compatibility

AMBA AXI4-Stream（IHI 0051A）；UVM 1.2；VCS W-2024.09-SP1。
不支持 AXI memory-mapped 混用；不宣称覆盖 IHI 0051B 全部扩展。

---

# 43. Issues

已知缺口清单见 `docs/rtm.md` §7 gap 列（复位矩阵、错误注入场景化、
CHECKER_ONLY 独立构建、1000000 beat 压力、20 seed 矩阵、第二仿真器矩阵）。

---

# 44. Quick Start

```bash
# L1 语义 golden vector
make -C self_test unit BUILD_DIR=$PWD/build/x LOG_DIR=$PWD/build/x/logs
# 最小端到端
make -C self_test smoke BUILD_DIR=$PWD/build/x LOG_DIR=$PWD/build/x/logs SEED=1
```

---

# 45. Checklist

| # | 检查 | 说明 |
|---|---|---|
| 1 | vif 与 cfg 参数一致 | `check_vif()` 会拦截 |
| 2 | `role`/`role_configured` 已设置 | 否则 fatal |
| 3 | `HAS_TLAST=0` 时 `packet_mode_configured` | 否则 fatal |
| 4 | 时钟/复位由顶层统一驱动 | 避免多 agent 同时驱动 |
| 5 | compare_mode 与 DUT 透明性匹配 | 非透明须 LOGICAL_STREAM/CUSTOM |
| 6 | CDC 复位合同已配置 | 否则停止严格比较 |
| 7 | error/reset 订阅者已连接 | 否则对应覆盖组不采样 |

---

# 46. Complete

本文档与实现保持一致：API、参数、模式名、判据行均取自实际源码
（`axi4_stream_config`、`axi4_stream_*_seq`、`axi4_stream_ready_item`、
`axi4_stream_checker`、`axi4_stream_scoreboard`、`axi4_stream_monitor`）。
若发现文档与实现不一致，以 `docs/requirement.md` 与源码为准并同步修订本文。
