# AIXSILICON APB VIP — User Guide

> **VLNV**: `aixsilicon:vip:apb:1.0.0` · UVM 1.2 · VCS（xrun 预留）

---

# 1. 最小集成（Requester + Completer loopback）

```systemverilog
// 1) 编译文件：apb_types_pkg.sv → apb_if.sv → apb_pkg.sv（filelist 顺序固定）
// 2) tb 顶层实例化 interface（APB4 基线）
apb_if #(
  .ADDR_WIDTH(32), .DATA_WIDTH(32),
  .HAS_PSTRB(1'b1), .HAS_PPROT(1'b1)
) u_if (.pclk, .presetn, .check_enable(1'b0));

// 3) SVA bind（elaboration 参数）
bind apb_if apb_protocol_sva #(.HAS_PSTRB(HAS_PSTRB), .HAS_PPROT(HAS_PPROT))
  u_apb_sva (bus(u_if));
```

```systemverilog
// 4) env 中 config + apb_env
apb_config cfg = apb_config::type_id::create("cfg");
cfg.protocol_version = APB4;
cfg.agent_mode       = APB_ACTIVE_MASTER;
uvm_config_db#(apb_config)::set(null, "*", "config", cfg);
uvm_config_db#(virtual apb_if)::set(null, "*", "vif", u_if);
```

# 2. 配置速查

| 字段 | 默认 | 说明 |
|---|---|---|
| protocol_version | APB4 | APB3/APB4/APB5 |
| agent_mode | APB_PASSIVE | ACTIVE_MASTER/ACTIVE_SLAVE/PASSIVE/DISABLED |
| slave_response_mode | APB_ZERO_WAIT | ZERO/FIXED/RANDOM/SEQUENCE_CONTROLLED |
| slave_error_mode | APB_ERR_NEVER | NEVER/RANDOM/ADDRESS_RANGE/SEQUENCE_CONTROLLED |
| timeout_cycles / timeout_severity | 1000 / UVM_ERROR | 超时检测与报告级别（policy） |
| enable_x_check | 1 | 有效窗口 X/Z 检查（VER-013） |
| check_pslverr_recommendation | 0 | RUL-005 非有效期 REC 检查（INFO/WARN） |
| allow_protocol_violation | **0** | 负向总门（默认绝不产生非法协议） |

**能力一致性（C-8）**：`apb_env` build_phase 自动执行
`validate_interface_vs_config()`——runtime 开关与 interface HAS_*/WIDTH 参数
不一致直接 FATAL（如 `enable_wakeup=1` 但 `HAS_PWAKEUP=0`）。

# 3. APB5 能力实例化

```systemverilog
// RME + USER + WAKEUP + CHECK 全能力（正交叠加）
apb_if #(
  .ADDR_WIDTH(32), .DATA_WIDTH(32),
  .HAS_PSTRB(1), .HAS_PPROT(1),
  .USER_REQ_WIDTH(8), .USER_DATA_WIDTH(8), .USER_RESP_WIDTH(4),
  .HAS_PWAKEUP(1), .HAS_PNSE(1), .HAS_CHECK(1)
) u_if5 (.pclk, .presetn, .check_enable(1'b1));

// config 侧对应
cfg.protocol_version = APB5;
cfg.rme_support      = 1;    // → enable_prot 自动置 1（CFG-002）
cfg.enable_wakeup    = 1;
cfg.user_req_width   = 8;    // 0=不存在，>0=存在
cfg.user_data_width  = 8;
cfg.user_resp_width  = 4;
cfg.check_type       = APB_CHECK_ODD_PARITY_BYTE_ALL;
```

# 4. Sequence 使用

```systemverilog
apb_write_sequence wseq = apb_write_sequence::type_id::create("wseq");
wseq.num_writes = 8;
void'(wseq.start(env.master_agent.sequencer));

// 自定义：继承 apb_base_sequence 用 do_write/do_read
```

**Public API 仅两个入口**（ADR-13）：sequence + UVM RAL。env 无 blocking 读写 API。

# 5. RAL 集成

```systemverilog
apb_reg_adapter adapter = apb_reg_adapter::type_id::create("adapter");
adapter.configure(cfg);           // supports_byte_enable = APB4+ && enable_strb
regmodel.default_map.set_sequencer(env.master_agent.sequencer, adapter);
regmodel.default_map.set_auto_predict(1);
// P1 predictor：
// env.predictor.reg_predictor.map = regmodel.default_map;
// env.monitor.transaction_ap.connect(env.predictor.analysis_export);
```

# 6. 负向测试（默认禁用）

```systemverilog
cfg.allow_protocol_violation = 1;
// item 级注入（ERR-005/006）
it.inject_extended_setup  = 1;  // 延长 SETUP（RUL-001 负向）
it.inject_illegal_penable = 1;  // 跳 SETUP（RUL-002）
it.inject_unstable_addr   = 1;  // wait 期翻转地址（RUL-003）
it.inject_illegal_strb    = 1;  // 读 strb!=0（RUL-006）
it.inject_unaligned_addr  = 1;  // UNPREDICTABLE 分层（不判 ERROR）
```

# 7. 回归

```bash
make -C self_test unit          # L1 golden vectors（G2）
make -C self_test smoke         # UT01/02
make -C self_test regression    # 5 tier 全量
make -C self_test full          # unit + regression
```

# 8. 已知限制

* Completer 为 generic memory-backed responder，不做外设语义 golden（LIM-005）；
* *CHK 奇校验位级 checker，无独立 parity reference model（LIM-001）；
* 多 slave decode/mux（interconnect）不在 VIP 范围（LIM-003）。
