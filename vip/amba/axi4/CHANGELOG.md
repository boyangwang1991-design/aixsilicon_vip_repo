# Changelog — aixsilicon:vip:axi4

所有显著变更记录于此。格式参考 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)，
版本遵循 SemVer。

## [Unreleased] — 1.0.0（developing，G3 主体完成）

### Added（本轮 2026-09-01 S07）

* `docs/validation-plan.md`：按评审 8 点修正后 Freeze——RUL-001~017 负向映射与
  requirement 严格对齐；新增 §13.4/13.5 Write/Read Association 一等验证、§13.6
  Protocol Event 独立验证、§6.5 组件级独立参考（golden vectors）、§52 G3~G6 分层
  Exit Criteria；RUL-002 改 directed semantic、RUL-003 以 CHK 为主；RAL 定为
  G3 非 blocker / G6 blocker。
* `self_test/tb/axi4_corner_test.sv`：VAL-005~009（4KB 合法+负向、WRAP 回环、
  unaligned、zero-strobe）。
* `self_test/tb/axi4_negative_test.sv`：RUL 负向注入 → checker 检测率（4/4=100%）。
* `self_test/tb/axi4_random_test.sv` / `axi4_stress_test.sv`：随机 baseline（100 事务）
  与 stress（300 事务）。
* `Makefile`：6 tier 分层回归 + `ALLOW_ERRORS` 预期违规判定。
* `docs/rtm.md`、`docs/user-guide.md` 首版。

### Fixed（G2/G3 缺陷，8 处）

* `axi4_driver.sv`：3 处编译错误（block 内声明 / clocking output 采样）；
* `axi4_driver.sv`：slave 普通写从未更新 memory（只走 exclusive 分支）；
* `axi4_driver.sv`：B/R 接收 `join_any` 在 `enable_timeout=0` 时立即返回导致响应丢失；
* `axi4_driver.sv`：master/slave clocking skew（output #1 vs input #1step）握手错位；
* `axi4_types_pkg.sv`：`is_crossing_4kb` 掩码随 burst_size 变化导致单拍误报；
* `axi4_sequences.sv`：随机约束允许非法 WRAP（len∉{2,4,8,16}）/FIXED（>16）；
* `axi4_sequences.sv`：4KB 约束公式对 unaligned 起始不充分（漏检跨界）；
* `self_test/tb/axi4_smoke_env.sv`：checker request/response 流未接通（负向无法检出）。

### 已知限制（诚实标注）

* 12 条 RUL 专项负向注入、PRO-009/010/012 背压/延迟/交织、AW/W 解耦驱动形态、
  protocol_event 独立验证、RAL（G6 blocker）、FuseSoC/gen-core、coverage 闭合（G4）未完成。
