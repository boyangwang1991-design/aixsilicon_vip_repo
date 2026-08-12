# negative — 负向测试

协议异常与错误响应测试：每一类协议错误都必须能被 Checker 检测。

- 非法时序（setup/access 违反）；
- 错误响应注入（slave error、burst 错误）；
- X/Z 传播；
- timeout；
- 覆盖 `docs/qualification/README.md` 的指标：P0/P1 负向用例 100% 检测。
