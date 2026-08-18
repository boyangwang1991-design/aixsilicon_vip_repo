# AXI VIP 测试计划

## 测试策略

基于 TVIP-AXI 上游 sample 用例，验证基本 AXI4 协议功能。

## 测试矩阵

| 用例 | 覆盖场景 | 状态 |
|---|---|---|
| default | 基本读写、burst、ID | PASS |
| request_delay | 延迟请求、间隙写数据 | PASS |
| response_delay | 延迟响应、间隙读响应 | PASS |
| ready_delay | Ready 信号延迟、反压 | PASS |
| out_of_order_response | 乱序响应 | PASS |
| read_interleave | 读交织 | PASS |
| wvalid_preceding_awvalid | WVALID 先于 AWVALID | PASS（编译通过） |

## 固定种子验证

- Seed: 42
- Run 1: simulation time 10877500 ps, 0 errors
- Run 2: simulation time 10877500 ps, 0 errors
- 结论：可复现 ✅

## 待补充

- [ ] 协议错误注入测试（Protocol Checker 验证）
- [ ] 与 PULP AXI 交叉验证
- [ ] 与内部 Master/Slave 对拍
- [ ] 负向测试（SLVERR、DECERR）
- [ ] Exclusive/Atomic 事务测试
- [ ] 4KB 边界测试
- [ ] 窄传输与非对齐传输测试
