# AXI4 VIP 覆盖率报告（G4 量化，S16）

> 数据来源：`make cov_full`（6 tier 功能覆盖采样，VCS `-cm line+cond+tgl+assert`，
> vdb 保留于 `self_test/build/cov/axi4_cov_*.vdb`；urg merge 需 license，G4 复跑）。
> 功能覆盖百分比来自 `axi4_coverage` report（covergroup get_coverage()，0-100）。

## 各 covergroup 覆盖率（stress tier，最高基线；S16 实测）

| covergroup | 层 | 覆盖率 | 未命中 bins / 缺口 |
| --- | --- | --- | --- |
| cg_scenario | Feature/Scenario | **100%** | — |
| cg_burst | Feature | **83%** | len256/size64 等（需 256-beat 专项） |
| cg_access_type | Field | 50% | read/write 仅一侧被采样（monitor 通道不均衡） |
| cg_exclusive | Field | 50% | exclusive 事务未跑（缺 exclusive 专项激励） |
| cg_boundary | Feature | 50% | cross_4kb bins（负向仅 corner 有，coverage 通道未接） |
| cg_type_response | Cross | 29% | resp 类型仅 OKAY/SLVERR（EXOKAY/DECODE 未激励） |
| cg_size_bus_burst | Cross | 30% | size×bus×burst 组合稀疏 |
| cg_length_size | Cross | 1% | len×size 巨型 cross，bins 极稀疏 |
| cg_strobe | Field | **0%** | partial/sparse strobe 模式未生成（全 full strobe） |

## 断言覆盖（SVA cover，全 tier 汇总）

握手/传输/WLAST/RLAST/payload 稳定/复位 cover **全部命中**（各 tier 日志
`cover_*_transfer` match>0；error tier 含 RUL-011/RUL-005 违约检出）。

## G4 缺口清单（→ 专项激励计划）

| # | 缺口 | 闭环手段 |
| --- | --- | --- |
| 1 | cg_strobe 0%（partial/sparse） | feature 增 partial/sparse strobe 序列 |
| 2 | cg_exclusive 50% | exclusive 读-写对序列（EXOKAY/OKAY 双路径） |
| 3 | cg_access 50% | monitor 采样通道均衡（read/write 双侧接入） |
| 4 | cg_boundary 50% | corner 负向 4KB 接入 coverage 通道 |
| 5 | cg_type_response 29% | EXOKAY（exclusive）/DECODE（地址越界）激励 |
| 6 | cg_length_size 1% | 专项 len×size 矩阵遍历序列（确定性 sweep） |
| 7 | urg merge | license 可用时复跑（vdb 已保留） |

## 指标对照（vip-quality 目标）

| 指标 | 目标 | 当前 | 判定 |
| --- | --- | --- | --- |
| scenario（Feature） | ≥95% | 100% | ✅ |
| burst（Feature） | ≥95% | 83% | ⚠️（差 len256/size64） |
| Assertion Coverage | ≥95% | 全命中（smoke~stress） | ✅ |
| Cross（type_resp/size_bus_burst/len_size） | ≥90% | 29/30/1% | ❌ G4 专项 |
| Field（access/exclusive/strobe） | 100% | 50/50/0% | ❌ G4 专项 |
| Requirement Traceability | 100% | rtm 1.1.0（14 项中 12 PASS） | ⚠️ |

## 结论

**G4 量化画像建立**：scenario/burst/assertion 已达或接近目标；**Cross 与 Field
三类（strobe/exclusive/len×size）为 G4 闭合的主要缺口**，需专项激励序列
（确定性 sweep + exclusive 对 + partial strobe），不含 monitor 结构性改动。
