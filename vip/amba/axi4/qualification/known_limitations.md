# AXI4 VIP 已知限制（known limitations）

> 状态：`WAIVED`（发布期评审）或 `NOT_RUN`（待验证）。所有限制如实登记，不隐藏。

## 功能/验证限制

| # | 限制 | 影响 | 状态 | 计划 |
| --- | --- | --- | --- | --- |
| 1 | **E2 unstable payload（RUL-011 SVA）未检出**：注入翻转发生在 W stalled 期，但 master/slave clocking 沿错位使 SVA 窗口未命中 | negative 覆盖率缺口（1 条注入未闭环） | `NOT_RUN` | G4 统一采样沿（`@(posedge vif.aclk)` + 顶层信号）后确定性 stall |
| 2 | **C3 W-before-AW 解耦（PRO-019）回环断言未接入**：slave 预收线程 `slave_cb(input#1step)` 与 master `master_cb(output#1)` 采样错位 → 预收漏采 | 解耦形态仅驱动实现，验证 NOT_RUN | `NOT_RUN` | G4 采样沿统一 + per-beat 所有权仲裁 |
| 3 | **outstanding 读异步化未做**：master 读为同步（sequence 依赖 rdata），多 ID 乱序/交织完整并发未验证 | PRO-008 完整并发能力缺验证 | `NOT_RUN` | 独立 PR（读路径异步化 + 多 ID sequence） |
| 4 | **四层覆盖闭合未完成**：功能 covergroup 骨架就绪，cross/feature 全覆盖阈值未达 | G4 未闭合（当前 NOT_RUN） | `NOT_RUN` | 多 tier 合并 + coverage-check 统计 + 补 bins |
| 5 | **error/E2 的 stall 窗口依赖 slave delay_configuration**：当前固定 FIXED=2 未保证触发 | 时序敏感性 | 已知 | 见 #1 |

## 架构边界（设计决策，非缺陷）

| 项 | 说明 |
| --- | --- |
| Monitor 不直接更新 memory | 由 slave driver / data monitor 更新（architecture §14 冻结） |
| W 无 ID：monitor 依到达顺序归属 | 已实现逐笔归属（write_data_ended 切换）；交织多笔 W 需 G4 深化 |
| RAL adapter 单拍（burst_length=1） | 寄存器式访问按单拍映射（符合 VER-014） |

## 评审要求

以上 1–4 项在 G4/G5 评审时按 `WAIVED`（附影响与计划）或验证后移除处理。