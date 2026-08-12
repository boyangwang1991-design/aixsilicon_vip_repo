# tests — APB 测试用例

- `unit/`：事务 / 配置 / 序列单元测试；
- `smoke/`：最小 Master—Slave 闭环；
- `negative/`：协议异常与错误响应；
- `stress/`：随机 wait、地址扫描；
- `mutation/`：注入时序缺陷，验证 checker 检测能力。

> 测试用例只覆盖 VIP 自身能力；项目专用 Testcase 应放在项目仓库。
