# I2C VIP（P1）

I2C UVM VIP，VLNV（规划）：`aix:vip:i2c:1.0.0`。

- 优先级：**P1**
- 状态：规划中

## 计划能力

- Controller / Target 角色；
- ACK/NACK、clock stretch、arbitration、repeated start；
- 7/10-bit 地址、地址与数据阶段检查；
- 错误注入（仲裁失败、NACK、时钟拉伸超时）；
- 参考 OpenTitan `i2c_agent`。
