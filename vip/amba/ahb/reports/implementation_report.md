# AHB VIP implementation report

版本：0.1.0 development candidate。开发目录：`repos/aixsilicon_vip_repo/vip/amba/ahb`。
依据：原始 `../ahb_contract.md`，169条需求原文保持不变。使用 canonical vip-development-suite；本次仅记录Skill反馈，没有修改Skill仓库或发布registry。

## 当前结果

已落地可编译运行的UVM VIP开发工程：参数化接口、Manager/Subordinate/Passive组件、独立monitor/checker、流水与burst、AHB5扩展、经典仲裁/RETRY/SPLIT、memory/reservation、设备模型、RAL、scoreboard、FuseSoC工程和回归工具。

**完整合同尚未实现并验收完成，不能作为已认证V1.0发布。** RTM保留全部169个ID。已实现但缺少完整验收证据的复合条目标NOT_RUN；缺失实现标FAIL；不能根据开发用例通过推断整条复合需求通过。

## 实测证据

| 检查 | 结果 | 证据 |
| --- | --- | --- |
| VCS W-2024.09-SP1 / UVM1.2 开发回归 | 13/13 PASS，编译警告0 | regression/full_s1_w0.yaml、compile_warning_review.yaml |
| 连续256写及256读回 | PASS；逐完成周期断言零等待无气泡 | smoke用例日志 |
| Lite32 / AHB5_128 / Classic32 各100固定seed | 300/300 PASS；是三个配置代表用例，并非全部功能交叉闭合 | regression/seed_matrix.yaml |
| 百万有效beat | PASS；93.24s，峰值RSS 176388 KiB | regression/stress_s1_w0.yaml |
| 六类真实源码变异 | 6/6精确检出；编译失败不计检出 | mutation/mutation_summary.yaml |
| FuseSoC新导出目录smoke | PASS；UVM_ERROR/FATAL均0 | fusesoc_smoke_final.log |
| Suite结构检查 / 配置schema / 169 ID集合 | PASS | vip_check.log、config_check.yaml |
| workflow make check / pre-commit | PASS；范围为workflow工具/已跟踪文件，不能代替SV lint | workflow_check_escalated.log、pre_commit.log |

百万beat用例循环访问固定256个word；RSS是单次峰值测量，尚不构成泄漏排除或各运行模式性能基线。相同最终源码指纹：`dfd100e7b01591b9fbe7cc3a250a4682314d77fd63f36748d184c9a44dfc9682`。变异报告另用生产src内容指纹，已核对与当前生产源码一致。

## 已修复的问题

- 四态字段默认值、read()参数方向、流水地址/写数据关联和两周期ERROR检查。
- 经典grant/数据所有权区分、RETRY/SPLIT重试与释放、成功提交一次。
- interface使用net连接，消除外部连线与clocking输出的非法变量驱动警告。
- monitor对周期、完成和诊断事件发布深拷贝；恶意订阅者篡改测试不再污染内部状态。
- build后结构配置变更检测；运行策略仍可调整。
- FuseSoC显式编译顺序与include文件清单；公共单元测试runner实际参与编译。

## 未闭合范围

完整回调和故障注入API、BUSY/IDLE计划与大块访问拆分、全部ERROR策略、HPROT语义、同址共享模型确定性仲裁、系统原子性/可见性检查、全部强制覆盖及跨工具/UVM兼容性仍有缺口。详见docs/rtm.md逐项状态与docs/requirement.md限制；第二商业工具和IEEE1800.2未运行，旧版/经典规范全文差异审查未完成。

G5由Suite `qualify --write`单独生成真实FAIL结论；未创建Qualified/Released版本，未提交或推送。

## Skill改进反馈

见[skill-improvement-report.md](skill-improvement-report.md)，共13项。**SK-009专门记录用户要求：开发工作区应位于VIP repo的对应文件夹；用生命周期状态区分开发/认证/发布，不应依赖临时目录与物理迁移。**
