# AHB 源码组织

编译顺序为 ahb_types_pkg.sv、ahb_if.sv、ahb_pkg.sv，再编译独立断言、仲裁模块和测试顶层。transaction、agent、checker、model、coverage、sequences、scoreboard、ral、env 下的类文件由 package include，不应独立重复编译。

接口和 API 见 [使用指南](../docs/user-guide.md)。静态需求映射见 [RTM](../docs/rtm.md)，执行结论见 [最新报告](../reports/latest.md)。文件存在不代表验收通过。
