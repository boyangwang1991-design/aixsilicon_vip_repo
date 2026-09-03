# AIXSILICON APB VIP — Requirement Specification（需求规格）

> **Document ID**: `aixsilicon:vip:apb:req` · 版本: 1.0.0-g0-baseline-r3.1
> **VIP Name**: `apb`
> **Category**: `amba`
> **Protocol / Interface**: AMBA APB3 / APB4 / APB5（ARM IHI 0024E）
> **Target Version**: `1.0.0`（**APB3/APB4/APB5 完整 conformance 均为 P0**，见 §24）
> **Profile**: `FULL_UVM`
> **Status**: `G0 PASS / Requirement Freeze`（r3 cleanup：*CHK C/OC 矩阵、USER 三宽度、
>   X-check 解耦、timeout severity 解耦、APB5 conformance 升 P0、parity grouping；
>   修正记录 §28。r3 后 Requirement 停止扩展，进入 G1）
> **Owner**: `<owner>`
> **Reference Specification**: ARM AMBA APB Protocol（ARM IHI 0024E；APB3/APB4 为其子集）
> **HWIF Contract**: `aixsilicon:hwif:apb`（`IFC-APB-001`，
>   [`apb.interface.yaml`](../../../../../aixsilicon_hwif_repo/bus/apb/apb4/contract/apb.interface.yaml)）
> **Target VLNV**: `aixsilicon:vip:apb:1.0.0`

> VIP Plan 条目: `repos/aixsilicon_vip_repo/registry.yaml`（条目名 apb，FULL_UVM，P0）
> 立项计划: [`vip/amba/apbplan.md`](../apbplan.md)

> **术语约定**：协议文档层一律使用 **Requester / Completer**（IHI 0024E 术语）；
> UVM 类名沿用业界习惯 `apb_master_*` / `apb_slave_*`，等价映射
> `master ≡ requester`、`slave ≡ completer`。

---

# 1. Overview

## 1.1 Purpose

本 VIP 用于验证 **AMBA APB3 / APB4 / APB5** 协议，提供标准化、可复用的：

* 主动激励（Requester 侧 master agent、Completer 侧 slave agent）；
* 被动监控（PASSIVE monitor）；
* 协议检查（Checker + SVA-first；含 **anti-overcheck** 设计——防误报合法 DUT）；
* 功能覆盖（Coverage，含 CP-07/08）；
* 错误注入（Completer response/error 注入 + Requester negative testing）；
* UVM RAL 集成（P0：adapter；P1：predictor）。

**定位**：轻量级标准入门 VIP——"简单协议 + 完整 VIP 工程能力"，作为 AXI4 之后的
第二个标杆 VIP，服务 UART/GPIO/Timer/CRG/EFUSE/Watchdog/CSR 等 APB 外设验证。

- **Profile**: `FULL_UVM`
- **VLNV**: `aixsilicon:vip:apb:1.0.0`
- **命名说明**：VIP 名 `apb`（非 `apb4`）——产品覆盖 APB3/APB4/APB5 三版本，
  由 `protocol_version` 配置选择；HWIF 同名对齐（`aixsilicon:hwif:apb`）。
- **版本能力模型**：APB3 ⊂ APB4 ⊂ APB5；能力开关**正交化**（§7），不用编译宏。

## 1.2 Scope

### In Scope

* APB3（PADDR/PSEL/PENABLE/PWRITE/PWDATA/PRDATA/PREADY/PSLVERR）；
* APB4 扩展（PSTRB、PPROT）；
* APB5 扩展（PAUSER/PWUSER/PRUSER/PBUSER、PWAKEUP、PNSE/RME、*CHK 信号族）；
* Requester 激励：IDLE→SETUP→ACCESS 相位、back-to-back transfer；
* Completer 响应：ZERO_WAIT / FIXED_WAIT / RANDOM_WAIT / SEQUENCE_CONTROLLED，
  错误策略 NEVER / RANDOM / ADDRESS_RANGE / SEQUENCE_CONTROLLED；
* Passive Monitor：统一单 monitor，transaction 重建；
* Protocol Checker：Phase / Stability / PENABLE / PREADY validity / PSLVERR validity /
  Signal Validity / 可选 X/Z checking / Write Strobe / Reset；
* Functional Coverage（含 CP-07 physical_address_space、CP-08 transfer_phase_pattern）；
* Reset 场景：任意相位复位 → 事务状态 APB_ABORTED。

### Out of Scope

* **APB Interconnect/Fabric**（多 slave decode/mux 进 driver——属 CBB/IP）；
  monitor 允许观察多 PSEL（NUM_SLAVES 参数）但不做 decode 决策；
* APB2 及更早版本；
* Q-Channel / PChannel（APB5 外设控制通道，另立需求）；
* 完整 parity generator/reference model（V1.0 做 *CHK 信号通道 + 奇校验位级
  checker + validity checker，见 LIM-001）。

## 1.3 Design Principles

1. **Protocol Correctness** —— 行为符合 ARM IHI 0024E（含 Signal Validity 语义）。
2. **Reusable** —— 不绑定具体 DUT/项目。
3. **Configurable** —— 版本/位宽/能力开关/运行行为由 config 控制；能力位正交。
4. **Observable** —— 事务、相位、等待、错误可观察。
5. **Checkable + Anti-overcheck** —— SVA-first + UVM checker；**不误报合法 DUT**
   （PREADY 非完成拍任意值合法、PSLVERR 非有效期仅 recommendation、UNPREDICTABLE≠ERROR；
   UT17/UT18 固化为 anti-overcheck 测试类别）。
6. **Default-Safe** —— 默认配置绝不产生非法协议/UNPREDICTABLE 行为；
   负向需显式 `allow_protocol_violation=1`。
7. **Qualifiable** —— Self-Test/RTM/Coverage/Mutation 证据化。

## 1.4 文档分层原则

本规格只回答 **What**；组件拆分/内部状态机/Policy 选型属于 `architecture.md`（How）；
API 签名属于 `user-guide.md`。协议相位状态（IDLE/SETUP/ACCESS）是协议事实，可在本规格；
driver 用 FSM 还是 task flow 是 How，归 architecture。
**事件的检测（What）与事件后的 UVM 行为/policy（How）分离**（如 timeout severity，§14）。

---

# 2. Protocol Capability（Feature List）

## 2.1 Feature ID 总表

| Feature ID | Feature | APB3 | APB4 | APB5 | 类别 |
|---|---|---|---|---|---|
| PRO-001 | IDLE 状态（PSEL=0） | ✅ | ✅ | ✅ | Transfer |
| PRO-002 | SETUP phase（PSEL=1, PENABLE=0，恰 1 拍） | ✅ | ✅ | ✅ | Transfer |
| PRO-003 | ACCESS phase（PSEL=1, PENABLE=1） | ✅ | ✅ | ✅ | Transfer |
| PRO-004 | READ transfer | ✅ | ✅ | ✅ | Transfer |
| PRO-005 | WRITE transfer | ✅ | ✅ | ✅ | Transfer |
| PRO-006 | WAIT STATE（PREADY=0 延长 ACCESS） | ✅ | ✅ | ✅ | Flow |
| PRO-007 | PSLVERR 错误响应 | ✅ | ✅ | ✅ | Response |
| PRO-008 | BACK-TO-BACK transfer（无 IDLE 间隔） | ✅ | ✅ | ✅ | Transfer |
| PRO-009 | PSTRB write strobe | – | ✅ | ✅ | APB4 |
| PRO-010 | PPROT protection | – | ✅ | ✅ | APB4 |
| PRO-011 | USER signaling（PAUSER/PWUSER/PRUSER/PBUSER，**三宽度独立** §7） | – | – | ✅ | APB5 |
| PRO-012 | PWAKEUP（Wakeup_Signal property） | – | – | ✅ | APB5 |
| PRO-013 | RME / PNSE（Realm Management Extension） | – | – | ✅ | APB5 |
| PRO-014 | INTERFACE CHECK / PARITY（*CHK 信号族） | – | – | ✅ | APB5 |
| PRO-015 | RESET 行为（任意相位可复位） | ✅ | ✅ | ✅ | Reset |
| PRO-016 | 事务状态 ABORTED | ✅ | ✅ | ✅ | Reset |

APB5 能力树（正交可叠加）：

```text
APB5
├── User signaling（user_req_width / user_data_width / user_resp_width）
├── Wakeup（enable_wakeup ↔ Wakeup_Signal property）
├── RME / PNSE（rme_support）
└── Interface check / parity（check_type）
```

## 2.2 Capability 矩阵（对齐 IHI 0024E Appendix B 信号属性）

属性记号：

```text
Y  = Mandatory（必选）
O  = Optional（可选）
OO = Optional for output ports / Mandatory for input ports（按端口方向）
C  = Conditional（条件必选）
OC = Optional conditional（条件可选）
N  = Must not be present（不得存在）
```

| 信号 | APB3 | APB4 | APB5 | 说明 |
|---|---|---|---|---|
| PCLK/PRESETn | Y | Y | Y | 时钟复位 |
| PADDR | Y | Y | Y | |
| PSELx | Y | Y | Y | |
| PENABLE | Y | Y | Y | |
| PWRITE | Y | Y | Y | |
| PWDATA | Y | Y | Y | |
| PRDATA | Y | Y | Y | |
| **PREADY** | **OO** | **OO** | **OO** | Completer 可不实现输出（Requester 输入侧 tie 高即零等待，IHI 0024E 明确允许固定两周期 peripheral） |
| **PSLVERR** | **OO** | **OO** | **OO** | Completer 可不实现（Requester 输入侧 tie 0 仍为合法接口） |
| PSTRB | N | O | O | APB3 不得存在 |
| PPROT | N | O | O | APB3 不得存在；RME 时 C |
| PAUSER | N | N | OC | user_req_width>0 |
| PWUSER/PRUSER | N | N | OC | user_data_width>0 |
| PBUSER | N | N | OC | user_resp_width>0 |
| **PWAKEUP** | N | N | **C** | **Wakeup_Signal property：True→必选存在；False→不得存在**（非"存在但不用"） |
| PNSE | N | N | C | RME_Support=True 时必选，且此时 PPROT 必选 |
| PADDRCHK | N | N | **C** | Check_Type≠False 时必选 |
| PCTRLCHK | N | N | **C** | 同上 |
| PSELxCHK | N | N | **C** | 同上 |
| PENABLECHK | N | N | **C** | 同上 |
| PWDATACHK | N | N | **C** | 同上 |
| PSTRBCHK | N | N | **C** | 同上（随 PSTRB 存在） |
| PREADYCHK | N | N | **C** | 同上 |
| PRDATACHK | N | N | **C** | 同上 |
| PSLVERRCHK | N | N | **OC** | 可选条件 |
| PWAKEUPCHK | N | N | **C** | 条件：Check_Type 且 Wakeup_Signal |
| PAUSERCHK/PWUSERCHK/PRUSERCHK/PBUSERCHK | N | N | **OC** | 随对应 USER 信号 |

**OO 语义**（VIP 落地，OO-1/OO-2）：

* OO-1：VIP 完整驱动/采样 PREADY/PSLVERR（VIP 端口不缺省）；
* OO-2：DUT 侧未实现 PREADY（恒高）或 PSLVERR（恒 0）时，VIP 配置
  `dut_pready_tied_high=1` / `dut_pslverr_tied_low=1` 跳过对应 checker 项。

## 2.3 APB5 Interface Check / Parity 能力协议化（PRO-014）

`check_type` 配置（正交能力，非布尔；IHI 0024E Check_Type 仅两态）：

```systemverilog
typedef enum {
    APB_CHECK_NONE,               // Check_Type = False：无 *CHK
    APB_CHECK_ODD_PARITY_BYTE_ALL // Check_Type = Odd_Parity_Byte_All（唯一合法 parity 类型）
} apb_check_type_e;
```

* CT-1：`check_type != APB_CHECK_NONE` 时，C 类 *CHK（PADDRCHK/PCTRLCHK/PSELxCHK/
  PENABLECHK/PWDATACHK/PSTRBCHK/PREADYCHK/PRDATACHK）**必选存在**；
  OC 类（PSLVERRCHK/PxUSERCHK）随对应信号；
* CT-2：*CHK 仅允许 APB5（`protocol_version==APB5`）；
* CT-3：V1.0 范围——*CHK 信号通道存在性、奇校验位级 checker、validity checker；
  **不含** parity generator 自动生成（LIM-001）；
* CT-4（CFG-008）：`check_type != NONE` 时 **PADDRCHK 宽度 = ceil(ADDR_WIDTH/8)**，
  按 IHI 0024E parity grouping 规则——地址按 8-bit group 分组，末尾不足 8-bit 的
  group 按（0 填充后）组内奇校验生成；参数化方式归 architecture（§6）。

## 2.4 位宽协议约束（CFG-003..005）

* CFG-003：`data_width ∈ {8, 16, 32}`（IHI 0024E DATA_WIDTH 限定）；
* CFG-004：`1 <= addr_width <= 32`；
* CFG-005：`PWDATA_WIDTH == PRDATA_WIDTH == data_width`（读写数据同宽）。

---

# 3. Protocol Rules（可检查）

| Rule ID | 规则 | 映射 | Severity |
|---|---|---|---|
| RUL-001 | 合法 SETUP phase 持续恰好 1 个 PCLK cycle，下一周期进入 ACCESS：该 transfer 的 PSEL 保持 asserted 且 PENABLE asserted（SETUP→IDLE 违规） | SVA-A1 | ERROR |
| RUL-002 | PENABLE=1 仅出现在 ACCESS；无前导 SETUP 的 PENABLE=1 违规 | SVA-A2 | ERROR |
| RUL-003 | ACCESS 延长期（PREADY=0）：**对该 transfer 有效的 request 字段保持稳定**——PADDR/PWRITE/PSEL 恒查；PWDATA/PSTRB（写）、PPROT、PNSE、PAUSER/PWUSER（启用时）条件查 | SVA-B1 | ERROR |
| RUL-004 | Transfer completion 仅由 `PSEL && PENABLE && PREADY` 定义；完成次拍 PENABLE 撤销（或立即下一笔 SETUP） | SVA-C1 | ERROR |
| RUL-005 | **PSLVERR 仅在 completion cycle（PSEL&&PENABLE&&PREADY）被采样并具有协议语义**；其他周期 PSLVERR 的值**不得判为协议错误**；非有效期 LOW 为 recommendation——VIP 提供可配置 recommendation checker（`check_pslverr_recommendation=1` 时 severity=INFO/WARN） | SVA-E1 | WARN/INFO |
| RUL-006 | 读传输 PSTRB 必须为 0（PSTRB 存在时） | SVA-F1 | ERROR |
| RUL-007 | PSTRB[i] 仅使能 PWDATA[8i+:8] 字节（partial write 语义由 completer 行为体现） | CHK-UVM | ERROR |
| RUL-008 | PRESETn 有效期间 PSEL/PENABLE 必须为 0；复位释放后总线进入 IDLE | SVA-G1 | ERROR |
| RUL-009 | ACCESS 挂起不得超过 timeout_cycles（0=禁用；防死锁静默）。**检测为 What；severity 由 `timeout_severity` 配置**（§14） | CHK-UVM | 可配 |
| RUL-010 | **Transfer completion 仅由 `PSEL && PENABLE && PREADY` 定义；SETUP phase（PENABLE=0）即使 PREADY=1 也不得视为 transfer completion**（PREADY 在 PENABLE=0 时取任意值合法——零等待 completer 常态） | SVA-C2/CHK-UVM | ERROR |
| RUL-011 | **Signal Validity**（IHI 0024E 语义——该周期该信号是否有协议意义）：PSEL/PWAKEUP（存在时）恒有效；PADDR/PPROT/PNSE/PENABLE/PWRITE/PAUSER/PSTRB/PWDATA 有效字节/PWUSER 在 PSEL=1 有效；PREADY 在 PSEL&&PENABLE 有效；PRDATA/PSLVERR/PRUSER/PBUSER 在 completion 有效 | CHK-UVM/SVA-H1 | ERROR |

RUL-003 注：`request fields that are valid for the transfer shall remain stable
while ACCESS is extended`——按能力开关条件展开，APB3/4/5 一致维护（架构 §16）。

**Protocol validity 与 X/Z checking 分离**（VER-013）：RUL-011 决定"什么时候采样"；
X/Z 检查决定"有效窗口内是否允许 X/Z 值"，见 §5 VER-013。

---

# 4. Transaction Model（What 级）

事务类 `apb_item` 三层语义：

```text
Request   : direction, addr, wdata, strb, prot, nse, auser, wuser, wakeup
Response  : rdata, slverr, buser, ruser
Timing    : requested_wait_cycles（激励侧）/ observed_wait_cycles（观察侧）
Status    : APB_OK / APB_ERROR / APB_ABORTED
```

约束：

* TRN-001：`direction==APB_READ` 时 `strb==0`（PSTRB 存在时）；
* TRN-002：`requested_wait_cycles ∈ [0, max_wait_cycles]`——**仅约束随机激励生成**；
  monitor 重建的 `observed_wait_cycles` 不受该约束（由 checker 按 timeout_cycles
  策略判断，不因 transaction 约束失败）；
* TRN-003：非负向模式（`allow_protocol_violation=0`）约束生成合法协议字段；
* TRN-004：**Default-safe 模式生成自然对齐地址**（data_width=32→4B、16→2B、8→byte）；
* TRN-005：UNPREDICTABLE ≠ 协议 ERROR——未对齐地址属 negative testing
  （ERR-006 门控），checker 不把 unaligned 判为 protocol ERROR；
* TRN-006：APB3 无 PSTRB——**semantic default：写按全部 DATA_WIDTH byte lanes 有效**
  （8-bit→1 lane、16-bit→2 lanes、32-bit→4 lanes，非固定 32 位）。

---

# 5. Verification Capability（组件需求）

| 组件 | 类型 | 需求 |
|---|---|---|
| apb_if | race-safe virtual interface：支持主动 Requester、主动 Completer、被动观察 | VER-001 |
| apb_monitor | uvm_monitor（统一单 monitor，完全被动） | VER-002 |
| apb_master_driver | uvm_driver（Requester 激励） | VER-003 |
| apb_slave_driver | uvm_driver（Completer 响应） | VER-004 |
| apb_master_sequencer / apb_slave_sequencer | uvm_sequencer | VER-005 |
| apb_master_agent / apb_slave_agent | uvm_agent | VER-006 |
| apb_protocol_checker | uvm_component（transaction 级） | VER-007 |
| apb_protocol_sva | SVA 集合（cycle 级，RUL-001..008/010/011） | VER-008 |
| apb_coverage | uvm_subscriber | VER-009 |
| apb_reg_adapter | uvm_reg_adapter（P0） | VER-010 |
| apb_reg_predictor | uvm_reg_predictor（P1） | VER-011 |
| apb_env | uvm_env（组装） | VER-012 |
| **X/Z checker** | **VER-013：VIP 可选对协议有效窗口内的信号执行 X/Z 检查（`enable_x_check`，默认开）；validity 窗口由 RUL-011 定义** | VER-013 |

## 5.1 Agent Modes

* `APB_ACTIVE_MASTER`（Requester）；`APB_ACTIVE_SLAVE`（Completer）；
* `APB_PASSIVE`（仅 monitor）；`APB_DISABLED`（不实例化）。

---

# 6. Stimulus / Sequence 需求

| Sequence | 内容 | 需求 |
|---|---|---|
| apb_base_sequence | 公共基类（virtual） | STM-001 |
| apb_write_sequence | N 笔写 | STM-002 |
| apb_read_sequence | N 笔读 | STM-003 |
| apb_random_sequence | addr/rw/data/strb/prot/nse 随机 | STM-004 |
| apb_incrementing_sequence | 递增地址（burst-like pattern） | STM-005 |
| apb_error_sequence | PSLVERR 场景（配合 Completer ADDRESS_RANGE） | STM-006 |

---

# 7. Configuration（配置空间；能力位正交化）

| 配置组 | 字段 | 说明 |
|---|---|---|
| Protocol | `protocol_version`（APB3/4/5）/ `addr_width` / `data_width` | CFG-003..005 |
| APB4 位 | `enable_strb` / `enable_prot` | O 信号存在性 |
| APB5 正交位 | `user_req_width` / `user_data_width` / `user_resp_width`（**0=对应 USER 信号不存在，>0=存在且为该宽度**；推荐上限 req≤128、data≤DATA_WIDTH/2、resp≤16）/ `enable_wakeup`（↔ Wakeup_Signal property：1→PWAKEUP 必选存在，0→不得存在）/ `rme_support` / `check_type` | §2.1；**去 `enable_user` 总开关——四 USER 信号独立 OC** |
| Agent | `agent_mode` / `role` | 四种模式 |
| Verification | `enable_checker` / `enable_coverage` / `check_pslverr_recommendation` / `enable_x_check` | §3 RUL-005；§5 VER-013 |
| DUT Optionality | `dut_pready_tied_high` / `dut_pslverr_tied_low` | §2.2 OO-2 |
| Timing | `default_wait_cycles` / `max_wait_cycles` / `timeout_cycles`（0=禁用） | 仅 Completer 行为 |
| Timeout policy | `timeout_severity`（UVM_WARNING/UVM_ERROR/UVM_FATAL，默认 UVM_ERROR） | §14：severity 是 policy/How |
| Safety | `allow_protocol_violation` | 默认 0；负向总门 |
| Completer | `slave_response_mode` / `slave_error_mode` / `slave_err_prob` / `slave_regions` | plan §8 |

一致性约束（CFG 派生，`apply_version_defaults()` 实现）：

* CFG-001：APB3 → strb/prot/user/wakeup/rme/check 全禁；APB4 → 仅 strb/prot；
  APB5 → 正交位自由叠加；
* CFG-002：`rme_support=1 → enable_prot=1`（IHI 0024E：RME 时 PPROT 必选）；
* CFG-003..005：§2.4 位宽；
* CFG-006：`check_type != NONE → protocol_version==APB5`；
* CFG-007：**不存在 `setup_to_access_gap`**——合法 APB SETUP 恰 1 拍，
  延长 SETUP 属负向（negative test 经 `allow_protocol_violation=1` + 注入字段）；
* CFG-008：`check_type != NONE` 时 PADDRCHK 宽度/分组符合 IHI 0024E
  parity grouping（§2.3 CT-4）；
* CFG-009：`check_type != NONE && enable_wakeup → PWAKEUPCHK 必选存在`。

---

# 8. External Interface（外部契约）

* **连接**：`apb_if` 直连 DUT/Env；virtual interface 经 config_db（`"*.vif"`）；
* **Config**：`uvm_config_db#(apb_config)`（`"*.config"`）；
* **Stimulus**：master sequencer seq_item_export；
* **Observation**：monitor `transaction_ap`（事务结果流：status = OK/ERROR/ABORTED
  一体表达，不设独立 error_ap——协议结果走 transaction 流、协议违规走 violation 流，
  两流语义不重叠）；
* **Violation**：checker `violation_ap`（结构化 apb_violation）；
* **RAL**：adapter 提供 `reg2bus`/`bus2reg`；predictor 订阅 monitor `transaction_ap`。

---

# 9. Default Completer Behavior Model

Completer 内置 **generic memory-backed responder**（default responder model，
**非 reference model**）：写按 PSTRB 合并入存储（APB3 semantic default 全 lanes）；
读返回存储值；未命中区域返回 0 且可配置 PSLVERR。

> 定位说明：Completer 不知道真实外设语义（UART FIFO/W1C/side-effect 寄存器等
> 无法由 generic memory 承载）——它是**通用 memory-backed APB responder**，
> 不是 CSR golden reference。真实外设行为建模属 IP 验证环境（用户替换 policy
> 或接自己的 scoreboard）。

---

# 10. Coverage 需求

| CP | Coverpoint | Bins |
|---|---|---|
| CP-01 | direction | READ / WRITE |
| CP-02 | addr region | low/mid/high |
| CP-03 | error | OK / SLVERR |
| CP-04 | observed wait bucket | 0 / 1 / 2-4 / 5-15 / 16+ |
| CP-05 | pprot | 8 值（enable_prot） |
| CP-06 | strb class | full/single/multi/sparse（enable_strb） |
| CP-07 | physical_address_space（RME）：PNSE × PPROT[1] → Secure/Non-secure/Root/Realm（rme_support） | 4 bins |
| CP-08 | transfer_phase_pattern | idle_to_transfer / back_to_back / wait_extended |
| CR-01 | direction × wait | |
| CR-02 | direction × error | |
| CR-03 | addr region × direction | |
| CR-04 | strb × alignment | |
| CR-05 | pprot × direction | |
| CR-06 | direction × phase_pattern | PRO-008 coverage evidence |

---

# 11. Error Injection

| 能力 | 提供方 | 需求 |
|---|---|---|
| wait-state 注入 | Completer（FIXED/RANDOM_WAIT + regions） | ERR-001 |
| PSLVERR 注入 | Completer（RANDOM/ADDRESS_RANGE） | ERR-002 |
| read-data override | Completer memory callback | ERR-003 |
| response delay | Completer SEQUENCE_CONTROLLED | ERR-004 |
| protocol negative（延长 SETUP / illegal PENABLE / unstable addr / illegal strb） | Requester + `allow_protocol_violation` | ERR-005 |
| unaligned address | Requester + `allow_protocol_violation`（TRN-005：UNPREDICTABLE 分层） | ERR-006 |

---

# 12. RAL（P0，plan §13）

* RAL-001：`apb_reg_adapter` 支持 `regmodel.xxx.write()/read()` → APB 读写；
* RAL-002：`provides_responses=1`；
* RAL-003：`supports_byte_enable = (protocol_version >= APB4) && enable_strb`
  （PSTRB 在 APB4/5 均为 O——仅当实际启用才置 1）；
* RAL-004：predictor 订阅 monitor，更新 mirror（P1）。

---

# 13. Debug-ability

* DBG-001：`apb_item::convert2string()` 全字段；
* DBG-002：violation 结构化输出（rule/req/severity/time/context）；
* DBG-003：`uvm_report` 分级（UVM_HIGH 逐拍、UVM_MEDIUM 逐事务）。

---

# 14. Timeout

* TIM-001：ACCESS 挂起超过 `timeout_cycles` 时产生 **timeout violation**
  （0=禁用）；violation severity 由 `timeout_severity` 配置（默认 UVM_ERROR，
  可 WARNING/ERROR/FATAL）。**检测是 What；检测后的 UVM 行为（是否立即停止）
  是 policy/How。**

---

# 15. Statistics（P2，本版 N/A）

---

# 16. Recording（P2，本版 N/A）

---

# 17. Metadata（Public Capability）

* MET-001：Gate 判定与证据索引由 `reports/gate_status.md` 承载（唯一 SSOT）；
  Limitations 在本规格 §23；执行证据在 `reports/run_log.md`。不设 metadata/ 独立目录。

---

# 18. Engineering Requirements

* ENG-001：仿真器 VCS（xrun 预留）；
* ENG-002：UVM 1.2；
* ENG-003：构建入口 `self_test/Makefile` + `unit_test/filelist.f`；
* ENG-004：回归分层 unit / smoke / feature / corner / error / random / full；
* ENG-005：run_log.md 记录所有执行证据。

---

# 19. Self-Test（UT01-UT22）

| UT | 名称 | 验证点 |
|---|---|---|
| UT01 | basic_write | PRO-005 |
| UT02 | basic_read | PRO-004 |
| UT03 | back_to_back | PRO-008 |
| UT04 | zero_wait | PRO-006(0) |
| UT05 | random_wait | PRO-006(r) |
| UT06 | long_wait | PRO-006(16+) |
| UT07 | slverr | PRO-007 |
| UT08 | reset_idle | PRO-015 |
| UT09 | reset_setup | PRO-015 |
| UT10 | reset_access | PRO-015/016 |
| UT11 | APB4_strb | PRO-009 |
| UT12 | APB4_prot | PRO-010 |
| UT13 | APB5_user | PRO-011（三宽度独立） |
| UT14 | APB5_wakeup | PRO-012 |
| UT15 | checker_negative | RUL-001..003 检出 |
| UT16 | RAL_read_write | RAL-001 |
| UT17 | pready_high_setup | **anti-overcheck**：PREADY=1 during SETUP 合法（RUL-010 反向） |
| UT18 | pslverr_outside_window | **anti-overcheck**：PSLVERR 非有效期非零不判 FAIL（RUL-005） |
| UT19 | data_width_legal | data_width 8/16/32 合法 + 非法值被 CFG 拒绝 |
| UT20 | APB5_pnse_rme | PRO-013（PNSE × PPROT 四物理地址空间） |
| UT21 | APB5_check_signals | PRO-014（*CHK C/OC 通道 + check_type） |
| UT22 | signal_validity | RUL-011 validity + VER-013 X-check |

> **anti-overcheck 测试类别**：UT17/UT18 定义为 VIP Repo 的固定测试类别
> （防 checker 误报合法 DUT——VIP 风险不仅是漏检，还包括误报）。

L1 Unit Test（无 UVM golden vector）覆盖：types/config/item 语义、版本派生、
位宽合法性（CFG-003..005）、strb 分类、wait bucket、对齐判定、
requested vs observed wait 分离、PADDRCHK 分组宽度（CFG-008）。

---

# 20. Compatibility

* COM-001：VLNV vendor 固定 `aixsilicon:`；
* COM-002：依赖 UVM 1.2；不依赖 dv_common 之外的私有仓；
* COM-003：FuseSoC core 可被 SoC/IP 回归以 `vip:apb` 依赖引用。

---

# 21. Deliverable（交付物）

* docs/：requirement / architecture / validation-plan（含 FI case 表）/ rtm / user-guide；
* src/：完整 VIP 源码；
* unit_test/：L1 golden vector；
* self_test/：smoke..full + mutation 回归；
* reports/：run_log / gate_status / mutation / coverage（唯一报告出口，含版本语义小节）；
* FuseSoC core、README（CHANGELOG 由 release 阶段从 run_log 汇出生成，开发区不维护）。

---

# 22. Qualification Requirements

* QLF-001：G2 = 编译通过 + L1 Unit Test 全绿；
* QLF-002：G3 = self_test 回归 tier 全绿 + checker 负向检出 + anti-overcheck 通过；
* QLF-003：G4 = 覆盖率模型完整 + smoke 基线；
* QLF-004：G5 = mutation 检出率报告；
* QLF-005：G6 = gate_status 判定齐备 + README + core（CHANGELOG 由 release 阶段生成）；
* QLF-006：**`aixsilicon:vip:apb:1.0.0` 发布前 APB3/APB4/APB5 三版本 conformance
  均须 qualification**（APB5 为 P0——metadata 声明的协议范围与 qualification
  范围一致，不允许"声明 APB5 但 1.0.0 未验证"）。

---

# 23. Limitations（已知限制）

* LIM-001：不提供独立 parity reference model / fault-correcting model；
  VIP driver 为自身输出驱动合法 *CHK 电平属 **BFM 协议驱动能力**（IHI 0024E
  要求 Check Enable 时 check signals 正确驱动），不构成 "parity generator" 限制冲突；
* LIM-002：Q-Channel/PChannel 不支持；
* LIM-003：多 slave decode/mux（interconnect）不在 VIP 范围；
* LIM-004：Statistics/Recording 延后 P2；
* LIM-005：Completer 为 generic memory-backed responder，不做外设语义
  （W1C/side-effect 等）golden reference（§9）。

---

# 24. Priority

**协议 conformance 分级（1.0.0 产品定义）**：

* **P0 / 1.0.0 mandatory：APB3 conformance、APB4 conformance、APB5 conformance**
  （USER 三宽度 / WAKEUP / RME / check_type 全部含入 1.0.0 qualification 范围）；
* P1：RAL predictor（RAL-004）、advanced negative test 扩展；
* P2：trace/JSON dump、多 slave monitor 观察增强、Statistics/Recording。

> 理由：APB 规模小、Requirement 已做到 APB5；把 APB5 提为 P0 使
> `aixsilicon:vip:apb:1.0.0` 成为完整 "APB3/4/5 VIP"，metadata 协议声明与
> qualification 范围一致（QLF-006）。

---

# 25. Requirement-to-Feature RTM（概览）

见 `docs/rtm.md`。

---

# 26. G0 Checklist

- [x] Feature List（PRO-001..016，含 RME/PNSE、check/parity）
- [x] Protocol Rules 可检查且协议准确（RUL-001..011）
- [x] Configuration Space（§7 正交能力位 + CFG-001..009）
- [x] Capability 矩阵对齐 IHI 0024E Appendix B（OO/C/OC 记号，§2.2；*CHK C 类修正）
- [x] 位宽约束（CFG-003..005）+ PADDRCHK 分组（CFG-008）
- [x] USER 三宽度独立属性（§7）
- [x] X/Z checking 与 validity 解耦（VER-013）
- [x] Timeout severity 解耦（§14 + timeout_severity）
- [x] Verification Components（§5，含 VER-013）
- [x] External Interface（§8）
- [x] Coverage Model（§10，含 CP-07/08）
- [x] Error Injection（§11，含 ERR-006）
- [x] RAL（§12）
- [x] Completer 定位澄清（§9 default responder）
- [x] Engineering/Qualification（§18/§22，含 QLF-006 conformance 一致性）
- [x] Limitations（§23）
- [x] Self-Test UT01-UT22（§19，anti-overcheck 类别）
- [x] 术语统一（Requester/Completer 文档层；master/slave 类名映射）
- [x] 1.0.0 产品定义（§24：APB5 conformance P0）

**G0 状态：PASS（Requirement Freeze 1.0.0-g0-baseline-r3.1）**

---

# 27. Completion

r3 后 Requirement 停止扩展（继续打磨将侵入 architecture）。进入 G1，
architecture 重点解决：① optional 信号/interface 承载（最关键决策）；
② Requester/Completer agent 组织与 monitor 防重复；③ SVA bind 架构与
config/severity 传递；④ APB3/4/5 能力归一化（physical signals → normalized
apb_item）；⑤ Completer responder（sequence response / memory responder /
error responder / wait policy）；⑥ RAL data path。

---

# 28. 修正记录

## r3（G0 审核第二轮）

| # | 反馈项 | 修正 |
|---|---|---|
| 1 | *CHK C/OC 矩阵不准确 | §2.2 重写：PADDRCHK/PCTRLCHK/PSELxCHK/PENABLECHK/PWDATACHK/PSTRBCHK/PREADYCHK/PRDATACHK=C；PSLVERRCHK/PxUSERCHK=OC；PWAKEUPCHK=C（Check_Type & Wakeup_Signal） |
| 2 | USER 三宽度 | §7：user_req_width/user_data_width/user_resp_width（0=absent）；去 enable_user |
| 3 | X/Z check 解耦 | VER-013 + `enable_x_check`（默认开） |
| 4 | timeout severity 固定 FATAL 过强 | §14/RUL-009：`timeout_severity` 可配（默认 ERROR），检测/policy 分离 |
| 5 | 1.0.0 是否完整 qualification APB5 | §24：APB5 conformance 升 P0 + QLF-006 |
| 6 | PADDRCHK 分组 | CFG-008 + CT-4（ceil(ADDR_WIDTH/8) 末组填充奇校验） |
| 7 | PWAKEUP 应为 C | §2.2 PWAKEUP=C（Wakeup_Signal property 映射，存在性语义） |
| 8 | Completer 定位 | §9 改 "Default Completer Behavior Model"（generic responder 非 reference model）+ LIM-005 |
| 9 | 术语统一 | 术语约定（Requester/Completer 文档层；master/slave 类名映射） |

## r3.1（G1 审核联动微调）

| # | 项 | 修正 |
|---|---|---|
| 1 | §8 观察流简化 | 删 monitor error_ap：事务结果（含 ABORTED）走 transaction_ap.status，违规走 violation_ap |
| 2 | LIM-001 表述冲突 | 改写：driver 驱动合法 *CHK 属 BFM 协议驱动能力，非 parity generator 限制 |

## r2（G0 审核第一轮）

| # | 反馈项 | 修正 |
|---|---|---|
| 1 | RUL-005 原文错误 | §3 重写：非有效期仅 recommendation checker |
| 2 | RUL-010 原文错误 | §3 重写：SETUP 拍 PREADY 任意值合法 |
| 3 | PREADY/PSLVERR optionality | §2.2 OO 记号 + OO-1/OO-2 |
| 4 | APB5 RME/PNSE 漏项 | PRO-013 + rme_support + CFG-002 + CP-07 + UT20 |
| 5 | APB5 parity 定义虚 | PRO-014 + check_type（CT-1..3）+ UT21 |
| 6 | DATA_WIDTH 无约束 | CFG-003/004/005 + UT19 |
| 7 | RUL-001 PSEL 保持歧义 | §3 重写：SETUP 恰 1 拍且次拍进 ACCESS |
| 8 | RUL-3 稳定性字段列表 | 改"对该 transfer 有效的 request 字段"条件化 |
| 9 | Signal Validity 缺失 | RUL-011 + UT22 |
| 10 | setup_to_access_gap 不合理 | CFG-007 删除 |
| 11 | wait_cycles 约束误伤 monitor | TRN-002：requested/observed 分离 |
| 12 | 对齐地址 | TRN-004/005 + ERR-006 |
| 13 | PSTRB semantic default | TRN-006：按 DATA_WIDTH 全 lanes |
| 14 | apb5_profile 互斥枚举 | §7 正交能力位 |
| 15 | VIP 命名 apb4→apb | 文档/VLNV/路径统一 `apb` |
| 16 | RAL supports_byte_enable | RAL-003 条件化 |
| 17 | UT 扩展 | UT17-UT22 |
| 18 | Coverage CP-07/08 | §10 |
