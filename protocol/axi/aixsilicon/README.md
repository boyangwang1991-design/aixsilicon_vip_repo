# AIXSILICON AXI Adapter

本目录包含 AIXSILICON 对 TVIP-AXI 的本地适配、扩展与补丁。

## 设计原则

- **不修改 upstream/**：所有本地修改隔离在本目录
- **Adapter 模式**：通过包装器适配 AIXSILICON VIP 统一接口
- **增量扩展**：仅添加 AIXSILICON 特有功能，不重复上游已有能力

## 计划组件

| 组件 | 状态 | 说明 |
|---|---|---|
| `aix_axi_adapter.sv` | planned | 统一接口适配层 |
| `aix_axi_checker.sv` | planned | 增强型协议检查器 |
| `aix_axi_coverage.sv` | planned | 功能覆盖率扩展 |
| `aix_axi_scoreboard.sv` | planned | 事务级 scoreboard |

## 与 upstream 的关系

```
upstream/src/          → 原始 TVIP-AXI 代码（只读）
aixsilicon/            → 本地适配与扩展（可修改）
```
