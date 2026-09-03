# AXI4 VIP 失败注入 / Mutation 报告（G5 前置）

> Mutation Detection Rate = Detected / Injected。状态如实标注（禁止伪报）。

## 1. 负向注入（RUL 专项，negative + error tier）

### negative tier（`axi4_negative_test`，自研 4 条非法事务）

| 注入 | 预期规则 | 实际检出 | 结果 |
| --- | --- | --- | --- |
| WRAP 突发长度非法（len=3） | PRO-010 | 1 | ✅ |
| WRAP 起始地址未对齐 | PRO-012 | 1 | ✅ |
| FIXED 突发长度非法（len=20） | PRO-010 | 1 | ✅ |
| 4KB 跨界 | RUL-003 | 1 | ✅ |
| **检测率** | — | **4/4 = 100%** | ✅ |

### error tier（`axi4_error_test`，时序注入）

| 注入 | 预期规则 | 实际检出 | 结果 |
| --- | --- | --- | --- |
| E1 early-WLAST（burst 缩短，复用 addr=0xc000） | RUL-017（monitor beat 对账） | 2（两侧 monitor） | ✅ VALIDATED |
| E2 unstable payload（stall 期间翻转） | RUL-011（SVA payload stability） | 0 | ⚠️ **NOT_RUN**（stall 窗口时序，待 G4） |

→ **E1 VALIDATED（100% 该类注入检出）；E2 NOT_RUN 如实登记，不并入通过率。**

## 2. Checker Mutation 检测率

| 场景 | 注入策略 | 检出数/注入数 | 检测率 |
| --- | --- | --- | --- |
| 负向违规事务（4 类） | driver/violation injector | 4/4 | **100%** |
| early-WLAST（RUL-017） | item 级 `inject_early_wlast` | 2/2 | **100%** |
| unstable payload（RUL-011） | item 级 `inject_unstable_payload` | 0/1 | NOT_RUN |

## 3. 结论

- 已闭环注入的 mutation 检测率 **100%**（negative 4/4 + error E1 2/2）；
- E2（RUL-011）未闭环，诚实 NOT_RUN；建议 G4 统一采样沿后实现确定性 stall 窗口再验证。