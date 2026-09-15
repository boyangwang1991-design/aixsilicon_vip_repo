# self_test/tests/ — 回归测试套件（分 tier）

VIP Self Test 的测试用例按 tier 分层，供回归套件自动运行：

| tier | 目录 | 内容 | 触发 |
| --- | --- | --- | --- |
| `smoke` | `smoke/` | 最小正向事务 | 每次改动 |
| `feature` | `feature/` | 每个 feature 定向测试 | R2 以上 |
| `corner` | `corner/` | 边界值/最大最小配置 | 发布 |
| `error` | `error/` | 非法行为必须被捕获 | 发布 |
| `random` | `random/` | 随机激励 + 固定种子 | 发布 |
| `stress` | `stress/` | outstanding/backpressure/高吞吐 | 发布 |
| `config` | `config/` | 参数/配置组合 | 发布 |

## 测试命名

```text
axi4_stream_test_<分类>_<场景>.sv
例如：axi4_stream_test_smoke.sv、axi4_stream_test_burst.sv、axi4_stream_test_illegal_burst.sv
```

每个测试继承 `axi4_stream_base_test`，通过 `+UVM_TESTNAME=axi4_stream_test_xxx` 选择。

## 运行

```bash
# 由 Makefile / vip_tool regression 驱动
make -C self_test smoke      # smoke tier
make -C self_test feature    # feature tier
make -C self_test full       # full tier（全部）
```

## 结果记录

日志写入本 VIP 的 build 的 RUN_ROOT/logs；regression 只执行并记录命令。AI 阅读日志后写固定 metadata 报告，由 report-check 校验并计算 Gate；执行退出码 0 本身不代表 Gate PASS。
