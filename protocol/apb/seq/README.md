# seq — APB 序列

按用途分四类，均继承 `apb_base_seq`：

| 子目录 | 内容 |
|---|---|
| `base/` | 公共基类（默认约束、打印、握手） |
| `normal/` | 正常读写序列 |
| `stress/` | 随机 wait、burst 高频、backpressure |
| `negative/` | 错误响应注入、协议异常 |

## 规划文件

- `apb_base_seq.sv` — 基类
- `apb_read_seq.sv` / `apb_write_seq.sv` — 正常序列
- `apb_stress_seq.sv` — 压力序列
- `apb_error_seq.sv` — 负向序列
