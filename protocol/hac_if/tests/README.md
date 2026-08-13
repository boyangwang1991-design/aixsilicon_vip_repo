# HAC-IF VIP Tests

> 骨架目录。测试分级与目标：

| 目录 | 内容 |
|---|---|
| `tests/unit/` | unit_sim 级用例（单任务、单 Beat 读写等） |
| `tests/stress/` | 背压、Outstanding、乱序压力用例 |
| `tests/negative/` | checker 负向用例（非法状态、X/Z、超时） |
| `tests/mutation/` | mutation 用例（注入时序/握手缺陷验证 checker） |
| `tests/compatibility/` | Profile 兼容与跨版本用例 |

详细用例清单见 [`docs/testplan.md`](../docs/testplan.md:1)。
