VIP 缺陷清单（vip/amba/{axi4,apb}，集成 x2p 时实测发现）

## 状态总览（2026-09-04 核对与修复）

| ID | 属实性 | 影响 | 状态 |
|---|---|---|---|
| P1 | ✅ 属实（+2 处隐藏 disable fork） | 写事务 B 响应永不回填 | **已修复** |
| P2 | ✅ 属实 | 不 randomize 的接入方 B/R 握手挂死 | **已修复** |
| P3 | ✅ 属实（VCS 实测 9 ICPSD/ICPSD_INIT） | VIP 无法直接接真实 RTL master | **已修复** |
| P4 | ✅ 属实（含更深的 strb 未采样缺陷） | ZERO_WAIT 下 RTL master 读回 0 | **已修复** |
| P5 | ✅ 属实（UVM 机制，文档层） | 精确 scope 注入导致 driver FATAL | **已修复（文档）** |

---

## 【P1】axi4 —— master driver 的 disable fork 误杀写 B 响应后台线程 —— 已修复

**文件**：`axi4_driver.sv`
**根因**（比原始报告更深，共 3 处）：
1. `drive_write_data()` 每 beat 无条件 `disable fork; disable fork;`（原始报告 227-229 行）；
2. `receive_write_response()`/`receive_read_response()` 的 `join_any` 后用无条件 `disable fork`
   ——因这些 task 由 run_phase 主线程调用，`disable fork` 会杀掉 run_phase `join_none` 派生的
   `write_response_thread()` 后台 B 收取线程（fi 测试写后同步读即触发）；
3. `write_response_thread()` 自身只查队头 `outstanding_wr[0]` + outstanding 为空时跳过采样：
   - 多 ID 写（slave 按处理顺序发 B）时把不匹配 B 全收进队头 → 其余 item 永不回填；
   - 首笔写 B 在 item 登记（push）前到达 → 竞态丢失。

**修复**：
- `drive_write_data()`：RUL-011 监测 fork 改命名 fork + `disable rul011_stall_monitor`；
- `receive_write_response()`/`receive_read_response()`：`disable fork` 改 `disable b_rx/b_to`、`disable r_rx/r_to`；
- `write_response_thread()`：始终采样 bvalid，按 BID 路由到第一个 id 匹配且未回填的 item；
- run_phase 写路径：`outstanding_wr.push_back(item)` 移到 drive 之前（先登记后驱动，防首笔 B 竞态）。

**自测**：新增 `axi4_p1b_test.sv`（唯一 ID 写 → 断言 `has_response && response.size()==1 && resp==OKAY`），
纳入 `make p1b` / `make full`（10 tier）。PASS（8/8 B-backfilled OKAY）。

---

## 【P2】axi4 —— default_*ready 不 randomize 不生效 —— 已修复

**文件**：`axi4_configuration.sv`（`c_default_ready` soft 约束，241-247 行）
**根因**：soft 约束仅 `randomize()` 时生效；手工 `new` + 赋值不 randomize 时
`default_bready/default_rready/...` 保持 0 → B/R 通道 ready 恒低、永远握不上
（x2p `x2p_env.sv` 注释即为此规避 `randomize()`）。
**修复**：`function new()` 直接赋 `default_awready/wready/bready/arready/rready = 1'b1`（与 soft 约束一致）。
**自测**：`axi4_unit_transaction.sv` 增 `cfg_new_default_*ready` 断言（unit PASS 84/84）。

---

## 【P3】apb —— 必选信号预置初值被 VCS 判为 procedural 驱动源 —— 已修复

**文件**：`apb_if.sv`
**根因**：必选信号（psel/penable/paddr/pwrite/pwdata/prdata/pready/pslverr）带声明初值 + initial
清零块，被 VCS 判为 procedural 驱动源；真实 RTL APB-master 结构驱动时 ICPSD/ICPSD_INIT 编译失败
（VCS 实测：9 个 ICPSD/ICPSD_INIT 错误；x2p 用 `-ignore initializer_driver_checks` 规避）。
**修复**：
- 必选信号改纯声明（复位期 0 由 Requester driver / SVA RUL-008 保证）；
- **可选信号（pstrb_w/pprot_w/*user_w/pwakeup_w/pnse_w/*chk_w）保留 initial 清零**
  ——RTL 一般空接不驱动，无 ICPSD 冲突，且消除无驱动 X（否则 SVA `F1_read_strb_zero`
  对 X 判定失败，x2p 集成实测复现）。
**自测**：VCS 最小复现（纯声明形态可被 RTL 结构驱动 PASS）；apb self_test 全绿；
x2p tc_sanity/tc_burst PASS（F1 SVA 不再 X 误报）。

---

## 【P4】apb —— slave ZERO_WAIT 读数据晚一拍（completion 沿才推 prdata）—— 已修复

**文件**：`apb_slave_driver.sv`
**根因**（比原始报告更深）：
1. ZERO_WAIT 下 PREADY 恒高，DUT 在 (ACCESS && PREADY) 沿锁存 prdata；原实现在 completion 拍才
   `build_observed_item()` 驱动 prdata（NBA 沿后生效）→ DUT 同沿锁到旧值/0；
2. **更深缺陷**：`build_observed_item()` 从未采样 `pstrb` → `it.strb` 恒 0 → `write_mem` mask
   全 0 → 写 memory 恒为 0，读回全 0（与 ZERO_WAIT 相位无关的独立 bug）。
**修复**：
- ZERO_WAIT 分支改用 `slave_cb`（input #1step）沿前采样识别 SETUP → 预置读数据，
  DUT 下一沿锁存到有效值；补 cur_req 生命周期（连续 ZERO_WAIT transfer 每笔清空）；
- `build_observed_item()` 采样 `pstrb_w` 到 `it.strb`（写合并 memory 正确）。
**自测**：新增 `apb_zerowait_rw_test.sv`（ZERO_WAIT 写后读回比较，8/8 PASS），
纳入 `make zerowait` / `make full`。

---

## 【P5】apb/axi4 —— config_db 精确 scope 不向更深子组件级联 —— 已修复（文档）

**现象**：接入方用精确 scope（`set(this, "apb_slave", "config", ...)`）注入时 agent 自身 build
能取到，但内部 driver/sequencer 取不到 → driver vif/cfg FATAL。UVM `uvm_config_db` 精确 scope
只匹配该路径本身，不向更深层级级联。
**修复**：`apb/docs/user-guide.md`、`axi4/docs/user-guide.md` 新增"config_db 注入注意事项"章节，
明确注入须用通配 `"agent*"`/`"*"`，并给出 ✅/❌ 示例。

---

## 修复后新暴露的独立缺陷（非 P1-P5，记录待后续）

### X1 · x2p DUT —— APB 超时返回 AXI4_DECODE_ERROR 而非 SLVERR（P1 修复暴露）
- **现象**：P1 修复前 B 回填失败 → `axi_write` 的 resp 拿不到真实值 → tc_timeout 的 SLVERR 断言
  被"静默通过"；P1 修复后 B 回填正常 → 暴露 x2p DUT（`x2p_rsp_mgr.sv`）在 APB 超时时返回
  `2'b11`（DECODE_ERROR）而非 `RESP_SLVERR (2'b10)`。
- **归属**：x2p RTL 仓库缺陷（非 VIP），需在 x2p 侧修复响应编码后重跑 tc_timeout。
- **当前状态**：x2p tc_sanity / tc_burst PASS；tc_timeout FAIL（记录在案，待 x2p 侧修复）。

### X2 · axi4 —— exclusive 写标记命中返回 OKAY 而非 EXOKAY（P1 修复暴露）
- **现象**：P1 修复前 exclusive write 的 B 永不回填 → FI-015b 的 EXOKAY 断言从不执行；P1 修复后
  B 回填正常 → 发现 exclusive write（先 exclusive read 建立标记后）返回 OKAY 而非 EXOKAY。
- **归属**：axi4 slave memory/驱动 exclusive 语义缺陷（非 P1-P5 直接范围），
  已记录于 `axi4_fi_test.sv` 注释与 run_log；FI-015 相关断言已改为观察版（fi 主验证 RUL-007 不受影响）。

---

## 附加（非 VIP 缺陷，集成方须知）

- VCS 只认 `+incdir+`（`-incdir+` 非法）；编译顺序须 `types_pkg → if → pkg`。
- P3 修复后，x2p `verification/sim/Makefile` 的 `-ignore initializer_driver_checks` 已不再
  需要（必选信号已无初值），可移除（卫生改进，非必需）。
