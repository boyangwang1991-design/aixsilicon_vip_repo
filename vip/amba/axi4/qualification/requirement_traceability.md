# AXI4 VIP 需求追溯（RTM 摘要，G5 证据）

> 完整追溯矩阵见 `docs/rtm.md`。此处为 Qualification 证据级别的 Requirement→Impl→Checker→Test→Coverage 摘要，
> 覆盖 G2/G3/S10 已验证的需求族（诚实标注 NOT_RUN/PARTIAL）。

## 已验证需求追溯

| Requirement | 实现（Impl） | Checker/SVA | Test | Coverage | 结果 |
| --- | --- | --- | --- | --- | --- |
| PRO-007 outstanding 写 | driver `write_response_thread` | — | concurrent C2 | cp_outstanding | PASS |
| PRO-008 多 ID 交替 | multi-id seq | — | concurrent C1 | cp_multi_id | PASS |
| PRO-009 背压 | slave `backpressure_proc` | — | error E4 | cp_backpressure | PASS |
| PRO-010 burst 长度合法 | monitor 重建 | PRO-010 | negative | cp_burst | PASS（负向检出） |
| PRO-012 WRAP 对齐 | semantic helper | PRO-012 | negative | cp_wrap | PASS |
| PRO-019 AW/W 解耦 | driver `decouple_w_before_aw` + slave 预收 | — | C3 seq | cp_decouple | NOT_RUN（#2） |
| RUL-003 4KB 边界 | `is_crossing_4kb` | RUL-003 | corner/negative | cp_4kb | PASS |
| RUL-005 WLAST 握手 | driver WLAST | SVA `a_wlast_handshake` | smoke/error | SVA cover | PASS（合法侧） |
| RUL-007 响应 beat 数 | checker `check_transaction_rules` | — | feature/error | — | PASS |
| RUL-010 响应编码 | checker `check_response_rules` | — | negative | cp_resp | PASS |
| RUL-011 payload 稳定 | driver stall 翻转注入 | SVA `a_wdata/a_wstrb_stable` | error E2 | SVA cover | **NOT_RUN（#1）** |
| RUL-016 exclusive 语义 | memory exclusive 状态机 | — | unit_memory | cp_exclusive | PASS（unit） |
| RUL-017 burst 完整性 | monitor beats + checker 对账 | — | error E1 | — | **PASS（VALIDATED）** |
| VER-014 RAL | adapter + predictor | — | ral tier | — | PASS |
| TRN-001 item 语义 | axi4_item | — | unit_transaction | — | PASS |

## 状态说明

- 上图 14 项中 **12 项 PASS**（已验证），**2 项 NOT_RUN**（E2=RUL-011、C3=PRO-019 decouple 验证），
  与 `known_limitations.md` #1/#2 一致；
- rtm.md（docs/）为完整逐条矩阵（含全部 REQ-xxx），本文件是 G5 证据摘要；
- Requirement Traceability 100% 目标在 G4 收尾（补 E2/C3 后）达成。