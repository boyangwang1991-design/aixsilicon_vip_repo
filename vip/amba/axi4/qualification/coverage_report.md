# AXI4 VIP 覆盖率报告（G4 前置）

> 覆盖率模型（四层）定义见 `docs/architecture.md §18` 与 `docs/validation-plan.md`。
> 状态：**功能覆盖骨架就绪 + 基线运行（smoke 60 事务）**；四层闭合（Requirement/Feature/Cross/Assertion）待 G4。

## 覆盖率模型（axi4_coverage.sv）

| 层 | 覆盖对象 | 状态 |
| --- | --- | --- |
| L1 Requirement | 每 REQ 至少被一个测试覆盖（追溯见 rtm.md） | ✅ 骨架（rtm 映射） |
| L2 Feature | burst type × length、narrow/unaligned、4KB、exclusive、outstanding、backpressure | ✅ covergroup 已定义 |
| L3 Cross | Burst × Size × Response × Outstanding × ID | ⚠️ 骨架（闭合待 G4） |
| L4 Assertion | 握手/valid 稳定/WLAST/RLAST/payload 稳定/复位（SVA cover） | ✅ 断言 cover 全部命中（smoke） |

## 基线运行（`make cov`，smoke 60 事务）

### 断言覆盖（SVA cover，VCS 报告摘要）

| cover property | attempts | match |
| --- | --- | --- |
| cover_aw_handshake | 60 | 8 |
| cover_w_handshake | 60 | 8 |
| cover_ar_handshake | 60 | 8 |
| cover_b_handshake | 60 | 8 |
| cover_r_handshake | 60 | 8 |
| cover_wlast_seen | 60 | 8 |
| cover_rlast_seen | 60 | 8 |
| cover_reset_seen | 60 | 3 |
| cover_aw_transfer / ar_transfer / w_transfer / b_transfer / r_transfer | 60 | 8 各 |

→ **断言层握手/传输覆盖 100% 命中（smoke 场景内）**。

### 数据/配置覆盖（功能 covergroup）

功能 covergroup 已实例化（`axi4_coverage` 构造于 env），smoke 触发基础 bins
（INCR 写读、单拍/突发、OKAY 响应）。完整四层闭合与 hole 分析需 G4 专项
（多 tier 合并覆盖率 + `coverage-check` 脚本统计阈值）。

## 指标对照（vip-quality 目标）

| 指标 | 目标 | 当前 | 状态 |
| --- | --- | --- | --- |
| Mandatory Feature Coverage | 100% | ⚠️ 骨架 | G4 |
| Functional Coverage | ≥95% | ⚠️ 骨架 | G4 |
| Cross Coverage | ≥90% | ⚠️ 骨架 | G4 |
| Assertion Coverage | ≥95% | ✅ smoke 内 100% 命中 | 基线 |
| Requirement Traceability | 100% | ⚠️ 见 rtm.md | 待 G4 |

## 建议下一步（G4）

1. 全 9 tier 合并覆盖率（`-cm line+cond+tgl+assert` 跨 test merge）；
2. `vip_tool.py coverage-check --report <merged>` 统计四层阈值与 hole；
3. 补齐未命中 bins（outstanding 读、多 ID 交织、exclusive）→ 确定性序列。