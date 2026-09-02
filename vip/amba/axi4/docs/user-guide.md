# AXI4 VIP — User Guide

> **Document ID**: `AXI4_USER_GUIDE_001`
> **VIP Name**: `axi4`
> **Protocol / Interface**: `AXI4 / AXI4-Lite`（IHI 0022E）
> **Version**: `1.0.0`
> **Status**: `Active（对应 1.0.0 实现；S10~S19 后持续更新）`
> **Owner**: `aixsilicon_vip_repo`
> **Target VLNV**: `aixsilicon:vip:axi4:1.0.0`
> **Profile**: `FULL_UVM`

---

# 0. 快速上手（5 分钟跑通你的第一个 AXI4 验证环境）

> 本章面向"第一次用这个 VIP"的工程师：三步接入 → 一段代码发起读写 → 看懂输出。

## 0.1 这个 VIP 是什么、能干什么

`axi4` VIP 是一个**自包含的 UVM 1.2 验证 IP**，把它放进你的验证环境后，它能：

1. **当主机（Master）**：向你的 DUT 发起 AXI4 读/写事务（单拍、burst、narrow、
   unaligned、exclusive 等），你只需在 sequence 里调 4 个高层 API；
2. **当从机（Slave）**：内置一个内存 + 响应策略模型，自动应答 AW/W/AR
   （可用于环回自测，或给无协议能力的 DUT 陪练）；
3. **当裁判（Checker/SVA/Coverage）**：被动监听总线，实时重建事务并按
   RUL-001~017 协议规则逐条检查，违规立即报 `UVM_ERROR`（含 rule_id 定位）。

三个核心模型（也是三个 agent 视角）：

```text
Stimulus:      Sequence → Driver → 接口      （发起协议行为）
Observation:   接口 → Monitor → 事务流        （还原协议行为）
Qualification: 事务流 → Checker/SVA/Coverage  （评判协议行为）
```

## 0.2 三步接入你的环境

**第 1 步：例化接口**（信号全集对齐 HWIF `IFC-AXI-001`，与你的 DUT 直连）

```systemverilog
axi4_if #(.ID_WIDTH(8), .ADDRESS_WIDTH(32), .DATA_WIDTH(32)) vif (
  .aclk(aclk), .areset_n(areset_n));
```

**第 2 步：config_db 四件套**（把接口与配置交给 VIP）

```systemverilog
axi4_configuration master_cfg = axi4_configuration::type_id::create("master_cfg");
void'(master_cfg.randomize() with {
  protocol   == AXI4_PROTOCOL;          // 或 AXI4LITE_PROTOCOL
  agent_mode == AXI4_ACTIVE_MASTER;     // 当主机
});
master_cfg.vif = vif;

uvm_config_db #(virtual axi4_if)::set(null, "*", "vif", vif);
uvm_config_db #(axi4_configuration)::set(null, "*", "master_cfg", master_cfg);
// slave 同理（slave_cfg / AXI4_ACTIVE_SLAVE）；status 可选
```

**第 3 步：跑 VIP 自带的 smoke 测试确认环境通了**

```bash
make -C self_test smoke     # PASS 判定：UVM_ERROR=0
```

## 0.3 写你的第一条测试（四种高层 API）

从 `axi4_master_base_seq` 派生你的 sequence，直接使用高层 API：

```systemverilog
class my_test_seq extends axi4_master_base_seq;
  `uvm_object_utils(my_test_seq)
  function new(string name = "my_test_seq"); super.new(name); endfunction

  virtual task body();
    axi4_data rdata;
    axi4_data wdata[];
    axi4_data rdata_burst[];

    // ① 单拍写 / 单拍读
    write(32'h0000_1000, 32'hDEAD_BEEF);         // 写一个字
    read(32'h0000_1000, rdata);                  // 读回校验
    if (rdata !== 32'hDEAD_BEEF)
      `uvm_error(get_type_name(), "read-back mismatch")

    // ② burst 写（4 拍 INCR）
    wdata = new[4];
    foreach (wdata[i]) wdata[i] = 32'h1234_0000 + i;
    burst_write(32'h0000_2000, wdata,
                '{default:4'b1111}, 4);          // burst_len=4

    // ③ burst 读
    burst_read(32'h0000_2000, 4, 4, rdata_burst);

    // ④ item 级控制（需要 WRAP/narrow/exclusive 等精细控制时）
    begin
      axi4_master_item item;
      item = axi4_master_item::type_id::create("it");
      item.access_type  = AXI4_WRITE_ACCESS;
      item.address      = 32'h0000_3000;
      item.burst_length = 4;
      item.burst_size   = 4;
      item.burst_type   = AXI4_WRAPPING_BURST;   // WRAP burst
      item.data         = wdata;
      item.strobe       = '{4'b1111, 4'b1111, 4'b1111, 4'b1111};
      start_item(item);
      finish_item(item);
    end
  endtask
endclass
```

## 0.4 输出怎么看

| 关键字 | 含义 |
| --- | --- |
| `UVM_ERROR : N` | 错误总数（协议违规 + 测试断言）；PASS 判定见下 |
| `VIOLATION [AXI4-REQ-RUL-xxx]` | 协议违规（rule_id 直接定位 requirement 条目） |
| `检查 N 笔事务，违规 M 个` | checker 统计（违规应为注入测试的预期值） |
| `coverage [axi4_coverage] access=...` | 功能覆盖各 covergroup 百分比 |

## 0.5 常用命令速查

```bash
make -C self_test compile     # 编译（VCS -full64 -ntb_opts uvm-1.2）
make -C self_test smoke       # 最小正向（环境通了没有？）
make -C self_test full        # 9 tier 全回归（含 error/concurrent/ral）
make -C self_test unit        # L1 Unit Test（79 golden cases）
make -C self_test negative    # 负向注入（4 类非法事务，mutation 检测）
make -C self_test fi          # FI 专项（响应异常/exclusive 总线级）
make -C self_test cov_full    # 覆盖采样 + vdb（G4）
```

## 0.6 常见问题（FAQ）

**Q1：读回数据全 0？**
→ 检查 slave 是否为 ACTIVE（PASSIVE 模式无 driver 不应答）；
→ 检查地址是否落在 slave memory 几何内（默认 64KB）。

**Q2：B/R 超时 `响应超时 (id=..)`？**
→ DUT 没有应答；可开 `enable_timeout=1` 让 VIP 主动报超时而不是挂死。

**Q3：怎么让 slave 制造背压/慢响应？**
→ `slave_cfg.awready_delay/wready_delay`（delay_kind=1 随机范围），
   `response_start_delay`；运行期改 `enabled` 即可阶段化生效。

**Q4：怎么注入非法事务测 DUT 的检查能力？**
→ 两种方式：约束随机产生非法（`random_constraint_mode`）或 item 级注入钩子
   （`inject_early_wlast`/`inject_unstable_payload`/`inject_missing_wlast`/
   `inject_valid_drop`，参考 `self_test/tb/axi4_error_test.sv`）。

---

# 1. Introduction（必填）

`axi4` VIP 是自包含 UVM 1.2 验证 IP，用于 AMBA AXI4 / AXI4-Lite 总线验证。

三个核心模型：

```text
Stimulus Model      Sequence → Driver → Interface    （axi4_master_agent）
Observation Model   Interface → Monitor → Transaction（write/read monitor）
Qualification Model Transaction → Checker/Coverage/SVA  （axi4_checker/coverage/assertions）
```

**Monitor/Checker 优先原则**：Monitor 只观察重建，协议检查由 Checker/SVA 独立完成；
Driver 最后。

# 2. Supported Capabilities（必填：与 requirement 一致）

| 能力 | 支持 | 说明 |
| --- | --- | --- |
| Read/Write/INCR/FIXED/WRAP burst | ✅ V1.0 | PRO-001~005 |
| 4KB 边界（合法+非法检测） | ✅ | PRO-006 / RUL-003 |
| Narrow / Unaligned / Byte-Lane | ✅ | PRO-013/014/021 |
| WSTRB partial / zero-strobe | ✅ | PRO-015 |
| Exclusive（AxLOCK） | ✅（模型级） | PRO-016/RUL-016 |
| Sideband CACHE/PROT/QOS/REGION | ✅ 驱动+重建 | PRO-017 |
| Reset（EXTERNAL/VIP_CONTROLLED 规划） | ✅ 基础 | PRO-018/RUL-009 |
| Outstanding 写（B 后台收） | ✅ | PRO-007 |
| Outstanding 读（async_read，多 ID） | ✅ | PRO-007/008 |
| Backpressure/延迟（ready_delay 跨沿） | ✅ | PRO-009/010 |
| AW/W 解耦（W-before-AW） | ✅ 实现并验证 | PRO-019 |
| Exclusive 总线级（EXOKAY/冲突） | ✅ | PRO-016/RUL-016 |
| RAL（adapter + predictor） | ✅ | VER-014 |
| Item 级注入钩子（负向） | ✅ | RUL-001/005/011/017 |
| timeout（B/R 等待超时） | ✅ | API-010 |
| 多 ID 乱序/交织完整并发 | ⚠️ 读同步路径下交织待 G4 | PRO-008 |
| Interleave（响应交织） | ⚠️ 配置存在 | PRO-011/012 |
| AXI3 locked / WID interleave / ATOP | ❌ | requirement §23 |

# 3. Package Contents（必填）

```text
vip/amba/axi4/
├── docs/            requirement/architecture/validation-plan/rtm/user-guide
├── src/             types/if/config/status/memory/transaction/agent/sequences/checker/env/coverage/ral
├── self_test/       Makefile + filelist + tb（9 tier + rul/fi/passive/cov_sweep 专项）
├── fault_injection/ FI-001~015 案例索引（injector 类在 src/env；README 含状态）
├── fusesoc/         FuseSoC core（aixsilicon_vip_axi4_1.0.0.core 已生成）
├── qualification/   待建（G5 证据包）
└── reports/         logs + quality/run_log.md
```

# 4. Dependencies（必填）

| 依赖 | 版本 |
| --- | --- |
| SystemVerilog/UVM | UVM 1.2（`-ntb_opts uvm-1.2`） |
| Simulator | VCS W-2024.09-SP1（Required）；Xcelium/Questa 未验证 |
| 外部库 | 无（自包含，不依赖 tue/tvip-common） |
| HWIF | `aixsilicon:hwif:axi`（IFC-AXI-001，接口契约唯一来源） |

# 5. Build and Compile（必填）

```bash
make -C self_test compile      # VCS -sverilog -full64 -timescale=1ns/1ps -ntb_opts uvm-1.2
make -C self_test smoke        # 最小正向
make -C self_test full         # 9 tier 全回归（smoke/feature/corner/negative/
                               #  random/stress/concurrent/error/ral）
make -C self_test unit         # L1 Unit Test（79 golden cases）
make -C self_test rul          # RUL 专项（M1 valid-drop + M2 missing-WLAST）
make -C self_test fi           # FI 专项（FI-013 非预期响应 + FI-015 exclusive 总线级）
make -C self_test passive      # timeout 专项（suppress_r 构造 R 超时窗口）
make -C self_test cov_sweep    # G4 覆盖 sweep（strobe/exclusive/len×size/4KB）
make -C self_test cov_full     # 6 tier 覆盖采样 + vdb（urg merge 复跑用）
```

产物：`self_test/build/simv`；日志 `self_test/build/logs/<test>.log`；
PASS 判定：`UVM_ERROR == ALLOW_ERRORS` 且 `UVM_FATAL == 0`（corner=1、negative=4 为
预期违规注入）。

# 6. DUT Interface Connection（按Profile：C/M 精简为检查接口连接）

```systemverilog
axi4_if #(.ID_WIDTH(8), .ADDRESS_WIDTH(32), .DATA_WIDTH(32)) vif (
  .aclk(aclk), .areset_n(areset_n));
```

信号全集对齐 HWIF IFC-AXI-001：必选 `awlock/arlock`、`awregion/arregion`；
capability `awatop`/`*user`（AXI4 profile 下 awatop 不激活）。

# 7. Agent Modes（按Profile：P/C/M 只列适用模式）

| 模式 | 用途 |
| --- | --- |
| `AXI4_ACTIVE_MASTER` | master 激励（sequencer+driver+双 monitor） |
| `AXI4_ACTIVE_SLAVE` | slave 响应（driver+memory+三 monitor） |
| `AXI4_PASSIVE` | 仅 monitor（PASSIVE 专项验证 NOT_RUN） |
| `AXI4_DISABLED` | 关闭 agent |

# 8. Basic Configuration（必填）

| 配置 | 含义 | 默认 |
| --- | --- | --- |
| `protocol` | AXI4_PROTOCOL / AXI4LITE_PROTOCOL | AXI4 |
| `agent_mode` | 见 §7 | ACTIVE_MASTER |
| `data_width` | 8~1024（Lite 仅 32/64） | 32 |
| `id_width` | Lite 固定 0 | 8 |
| `max_burst_length` | Lite 固定 1 | 256 |
| `response_ordering` | IN_ORDER/OUT_OF_ORDER | OUT_OF_ORDER |
| `enable_checker/coverage/error_injection` | suite 开关 | 1/1/0 |
| `enable_timeout` | VIP 运行时超时（非 AXI 协议机制） | 0 |
| `exclusive_support` | exclusive 支持 | 1 |
| `drive_awcache/awprot/awqos/awregion` | sideband 驱动 | 1（aruser=0） |
| `default_*ready` | READY 默认（背压需 `*_ready_delay`，未接通） | 1 |

# 9. Configuration Profiles（按Profile：C/M 精简）

`get_axi4_profile()` / `get_axi4lite_profile()` 静态工厂。delay 配置对象
`request_start_delay/write_data_delay/response_*_delay` 存在（运行时消费待接通）。

# 10. Environment Integration（按Profile：P/C/M 无 agent 环境）

参考 `self_test/tb/axi4_smoke_env.sv`：

* master_cfg/slave_cfg 从 config_db 取或随机化；
* 共享同一 `vif`；
* checker 接 master monitor `request/response_item_port`（请求级规则去重：slave 侧
  不接 request 流）+ 双侧 `response_item_port` → `monitor_imp`；
* coverage 接双侧 `transaction_ap`。

# 11. Sending Basic Transactions（按Profile：P/C/M N/A）

继承 `axi4_master_base_seq` 可直接调用高层 API（见 §13）。

# 12. Sequence API（按Profile：仅含激励的 Profile；L 可简化）

| Sequence | 用途 |
| --- | --- |
| `axi4_smoke_seq` | 8 笔写读回环 |
| `axi4_master_write_seq` | 随机/定向写（len/size/4KB/WRAP 对齐约束） |
| `axi4_master_read_seq` | 随机/定向读（同上） |
| `axi4_master_access_seq` | 多笔交替访问 |
| `axi4_slave_default_seq` | slave 自动响应 |

# 13. High-Level Operation API（按Profile：仅含激励的 Profile）

```systemverilog
write(address, data);                            // 单拍写
read(address, data);                             // 单拍读
burst_write(addr, data[], strobe[], len, size);  // burst 写（narrow 用 size<4）
burst_read(addr, len, size, data[]);             // burst 读
```

# 14. Random Traffic（按Profile：P/C/M N/A）

`axi4_random_seq`（100 事务 baseline）/ `axi4_stress_seq`（300 事务）；
seed 由 `+ntb_random_seed` 控制；minimum baseline 非 qualification guarantee。

# 15. Scenario Sequences（按Profile：P/C/M N/A）

corner/negative 测试（`axi4_corner_seq` / `axi4_negative_seq`）展示 4KB/WRAP/unaligned/
zero-strobe 与 RUL 负向注入模式。

# 16. Using Active Target / Slave（按协议：仅含 Target 的协议；P/C N/A）

ACTIVE_SLAVE agent 自动响应：driver 采集 AW+W、按 burst/WSTRB 更新 memory、驱动
B/R；exclusive 按 memory 标记返回 EXOKAY/OKAY。

# 17. Target Response Configuration（按协议：仅含 Target 的协议）

`response_ordering`（OUT_OF_ORDER 默认）、响应权重（okay/exokay/slave/decode）配置
存在；policy 运行时消费待接通（K2）。

# 18. Behavior / Response Customization（按协议/按Profile：Target 行为定制；M 核心）

响应行为定制（替换 policy 组件）规划中（architecture §20）；当前可通过 injector
+ response weights 配置控制响应类型。

# 19. Memory / Data Model（按协议：仅存储/数据类；M 核心）

`axi4_memory`：byte-addressable；`set_geometry(addr_width, data_w, size)`；
`initialize/clear/load_from_array/peek_byte/poke_byte`；
`read_burst/read_beat/write_beat`（WSTRB 门控、beat lane 语义）；
`exclusive_read/exclusive_write/clear_exclusive/is_exclusive_tagged`。

# 20. Passive Monitoring（按Profile：P 核心）

PASSIVE 模式实例化双 monitor 只采样；专项验证 NOT_RUN。

# 21. Transaction Observation（按Profile：P 核心）

```systemverilog
master_agent.write_monitor.transaction_ap.connect(sub.analysis_export);
master_agent.write_monitor.request_item_port.connect(...);
master_agent.write_monitor.response_item_port.connect(...);
```

`axi4_item` 含 request/response/timing/derived 字段与 `axi4_compare` 字段级比较。

# 22. Protocol Checker（按Profile：C 核心）

`axi4_checker`：request/response/monitor 三输入流；检查 PRO-010（len）、PRO-012
（WRAP 对齐）、RUL-003（4KB）、RUL-010（响应编码/EXOKAY）、RUL-007（拍数一致性）；
`violation_ap` 输出结构化 `axi4_violation`（rule_id/severity/channel/timestamp/context）。

# 23. Protocol Violation（按Profile：C 核心）

violation `rule_id` 关联 `AXI4-REQ-xxx`；severity ERROR/WARNING；context 内嵌
item.convert2string；用户可订阅 `violation_ap`。

# 24. Assertions（按Profile：C 核心）

`axi4_assertions`：valid hold（RUL-001）、wlast/rlast（RUL-005）、reset（RUL-009）、
payload stability（RUL-011）、握手 cover（RUL-002）；bind 到 interface 或在 tb 顶层
实例化（smoke_tb 示例）。

# 25. Functional Coverage（按Profile：P/C 至少 Rule Coverage）

`axi4_coverage` 接 transaction_ap；四层覆盖（Requirement/Field/Cross/Temporal）模型
已建，闭合为 G4 工作。

# 26. Error / Violation Injection（按Profile：C 必填）

```systemverilog
env.injector.injection_type    = AXI4_INJ_CROSS_4KB; // 9 种类型
env.injector.injection_enabled = 1;
env.injector.injection_probability = 100;
env.injector.injection_count   = 3;
```

类型全集：`ILLEGAL_WRAP_LENGTH/ILLEGAL_WSTRB/CROSS_4KB/EARLY_WLAST/MISSING_WLAST/
UNSTABLE_AWADDR/INVALID_BURST/INVALID_ID/INVALID_RESPONSE`。

# 27. Reset Usage（按Profile：所有有状态组件 reset）

driver `reset_signals()` 复位期间保持 VALID=0；SVA `a_reset_valid` 监督；
Reset Ownership（EXTERNAL/VIP_CONTROLLED）规划（architecture §29）。

# 28. Timeout（按协议：仅含等待语义的协议；无等待语义 N/A）

AXI4 无协议级 timeout；VIP `enable_timeout/timeout_cycles` 为运行时监控能力，
归类 Environment/Runtime violation（非 AXI 协议违规，不入 RUL 映射）。

# 29. RAL Integration（按协议：仅寄存器类总线；其余 N/A）

REQ-VER-014（P1 Required，V1.0 Target）：**尚未实现/验证（G6 Release blocker）**；
实现后提供 `axi4_ral_adapter/predictor` frontdoor + prediction。

# 30. Runtime Status（按Profile）

`axi4_status`：outstanding 计数（read/write/per-id）、violation/timeout 计数；
经 `uvm_config_db` 下发共享。

# 31. Statistics（可选：非 P0/P1 可省略）

STA-001（P2/Optional）：规划中（对比独立计数验证，NOT_RUN）。

# 32. Transaction Logging（按Profile：C/M 精简）

`transaction_log_verbosity`（UVM_LOW~DEBUG）；item.convert2string 结构化输出。

# 33. Transaction Recording（可选）

REQ-REC-001（P3/Future 2.0）：V1.0 不实现 → N/A。

# 34. Extension（按Profile：C/M 精简为 checker/policy 扩展）

Factory override / Response Policy 替换 / Sequence 扩展（architecture §26/§20）；
extension 专项验证 NOT_RUN。

# 35. Configuration Dump（按Profile）

`uvm_config_db` dump + cfg field automation（`uvm_field_*` 全字段打印）。

# 36. Debug Workflow（按Profile：C/M 精简为检查侧调试）

失败定位流：`violation_ap` rule_id → logs/`<test>.log` 的 VIOLATION 上下文
（type/addr/len/size/burst/strobe）→ 对照 RUL/PRO requirement 条目。

# 37. Common Issues（必填）

* **读回全 0**：确认 ACTIVE_SLAVE + memory 写路径（本轮已修复 slave 普通写）；
* **负向测试 FAIL 判定**：corner/negative 的 UVM_ERROR 是预期（Makefile
  `ALLOW_ERRORS` 与 report_phase 双重校验"必须检出且无超额"）；
* **AXI4-Lite**：`protocol==AXI4LITE_PROTOCOL`（len=1、无 ID、no burst）；
* **窄传输比对**：期望数据须按 beat lane 位置摆放（lane_shift = beat_addr%data_bytes）。

# 38. Recommended Usage（按Profile）

推荐环境组合：ACTIVE_MASTER + ACTIVE_SLAVE + checker + coverage + assertions；
随机基线 seed_count≥10（§35 minimum baseline）；stress 建议加大 seed/事务量。

# 39. Machine-Readable Metadata（必填）

`metadata/vip.yaml` 待建（G5）；生成时声明 capabilities/checker rules/limitations
与实现一致（`aixsilicon:vip:axi4:1.0.0`）。

# 40. Example Projects（按Profile：按 Profile 给示例）

`self_test/tb/` 即最小示例工程（smoke_tb + 全部测试）；`examples/axi4_example_top.sv`
为最小集成示例（axi4_if + 时钟复位 + UVM 配置/启动），集成要点见
`examples/README.md`。

# 41. Limitations（必填）

见 §2 ❌/⚠️ 项与 rtm.md §36/§40 及 `qualification/known_limitations.md`。当前核心限制：

* 多 ID 乱序/交织完整并发（读同步路径，`async_read` 已具备但响应交织注入待扩）；
* 响应交织（`enable_response_interleaving`）运行时消费未接通；
* S10~S19 已闭环：outstanding 写/读、AW/W 解耦（W-before-AW）、背压/延迟（跨沿）、
  exclusive 总线级、RAL adapter/predictor、timeout 路径、注入钩子（RUL-001/005/011/017）；
* 第三方仿真器（Xcelium/Questa）未验证（仅 VCS）。

# 42. Version Compatibility（必填）

| 项 | 兼容 |
| --- | --- |
| VLNV | `aixsilicon:vip:axi4:1.0.0`（目标发布） |
| HWIF | `aixsilicon:hwif:axi`（IFC-AXI-001） |
| UVM | 1.2（无 1.1d 兼容承诺） |
| SemVer | MAJOR 变更需 re-qualification |

# 43. Reporting VIP Issues（必填）

通过 aixsilicon_vip_repo issue 流程；提交时附：test 名称、日志片段（VIOLATION 行）、
配置 dump、seed 与 simulator 版本。

# 44. Quick Start（按Profile：按 Profile 给最小示例）

```bash
make -C self_test smoke     # 1 分钟内完成编译+smoke 回环验证
```

```systemverilog
// 测试内最小激励
axi4_smoke_seq seq = axi4_smoke_seq::type_id::create("seq");
seq.start(env.master_agent.sequencer);
```

# 45. User Guide Completion Checklist（必填）

* [x] 能力/限制与 requirement 一致（§2/§41）
* [x] 编译/集成/配置/API 说明（§5~§13）
* [x] Checker/Violation/Injection 说明（§22/23/26）
* [x] Common Issues（§37）
* [x] Limitations/Compatibility（§41/42）
* [ ] metadata/vip.yaml 交付后补 §39 细节
* [ ] RAL 实现后补 §29

# 46. Definition of User Guide Complete（必填）

当用户可仅凭本文完成：编译、集成、配置、激励、观察、检查、错误注入、故障定位时
视为完成。当前达成主体（G3 状态对应实现）；RAL/metadata 交付后补齐剩余章节。
