# AXI4 VIP Fault Injection 案例集

> 注入框架：`src/env/axi4_violation_injector.sv`（master 注入钩子 + violation 通道）。
> 每个案例：注入方式 → 预期检出（Checker/SVA）→ 当前状态（禁止伪报）。

## 案例索引

| 案例 | 注入 | 预期检出 | 实现 | 状态 |
| --- | --- | --- | --- | --- |
| FI-001 | WRAP 长度非法（len=3） | PRO-010 | negative tier 序列 | ✅ VALIDATED（negative 4/4） |
| FI-002 | WRAP 地址未对齐 | PRO-012 | negative tier 序列 | ✅ VALIDATED |
| FI-003 | FIXED 长度非法（len=20） | PRO-010 | negative tier 序列 | ✅ VALIDATED |
| FI-004 | 4KB 跨界 | RUL-003 | negative/corner | ✅ VALIDATED |
| FI-005 | early-WLAST（burst 缩短） | RUL-017（monitor beat 对账） | error E1（item `inject_early_wlast`） | ✅ VALIDATED（×2） |
| FI-006 | unstable payload（stall 翻转） | RUL-011（SVA payload stability） | error E2（item `inject_unstable_payload`） | ✅ VALIDATED（×4） |
| FI-007 | missing-WLAST | RUL-005（checker `wlast_seen` 检测器） | rul M2（item `inject_missing_wlast`） | ✅ VALIDATED（×2） |
| FI-008 | VALID 提前撤销 | RUL-001（SVA `a_arvalid_stable`） | rul M1（item `inject_valid_drop`） | ✅ VALIDATED（×1） |
| FI-009 | 同 ID 响应乱序 | RUL-006 | 未实现 | ⬜ G4 |
| FI-010 | 响应先于请求完成 | RUL-007 | 未实现 | ⬜ G4 |
| FI-011 | R 数据乱序/交织越界 | RUL-008 | 未实现 | ⬜ G4 |
| FI-012 | 复位中 traffic | RUL-009 | 未实现 | ⬜ G4 |
| FI-013 | 非法响应编码 | RUL-010 | 未实现 | ⬜ G4 |
| FI-014 | WSTRB 越界 lane | RUL-013 | 未实现 | ⬜ G4 |
| FI-015 | exclusive 双 master 冲突 | RUL-016 | 未实现 | ⬜ G4 |

## 检测率（已闭环注入）

**FI-001~008 共 8 类注入，全部检出（含两侧 monitor/断言计数），检测率 100%；**
合法对照（同地址同参数合法事务）0 误报。

## 注入使用方式（item 级，per-transaction）

```systemverilog
item.inject_early_wlast      = 1;  // FI-005
item.inject_unstable_payload = 1;  // FI-006（需 slave wready_delay 制造 stall）
item.inject_missing_wlast    = 1;  // FI-007
item.inject_valid_drop       = 1;  // FI-008（需 slave arready_delay 制造 stall）
```

详细判据见 `qualification/fault_injection.md`；运行入口见 `self_test/Makefile`
（`make negative` / `make error` / `make rul`）。
