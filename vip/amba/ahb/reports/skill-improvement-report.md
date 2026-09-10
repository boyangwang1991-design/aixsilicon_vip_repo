# VIP Development Suite 实施反馈

来源：canonical `repos/aixsilicon_skill_repo/skills/vip-development-suite`，2026-09-10。仅记录问题，不修改技能。

| ID | 严重度 | 来源 | 问题与复现 | 本次处理 / 建议 |
| --- | --- | --- | --- | --- |
| SK-001 | P0 | skills/vip-coverage/SKILL.md §4.1 | 两次分别命中 bins {A}、{B}，各50%，max=50%，并集=100%；max 不等价 urg union | 导出 bin IDs/hit counts，按配置合并；百分比不能重建并集 |
| SK-002 | P0 | skills/vip-test/SKILL.md §4.2 | virtual ahb_if 默认32位与 ahb_if#(32,128) 是不同类型，分开 tb 不会修复类型不匹配；也违背同仿真混合实例需求 | 参数贯穿 cfg/driver/monitor/agent/config_db，加入混合实例编译测试 |
| SK-003 | P1 | SKILL.md partial-task/G0与 requirement §6 | 全范围 G0 要求旧规范全文审查，但实施里程碑允许先做Lite；没有局部事实ready与产品gate分离模型 | 明确阶段输入可用范围，全产品gate不伪PASS；不能因未取到旧规范阻止独立组件开发 |
| SK-004 | P1 | rules/coding-rules.md §5 与主SKILL SSOT | coding-rules要求vip.yaml，主SKILL禁止metadata/vip.yaml；两套SSOT冲突 | 遵循主SKILL，capability YAML与证据分开，删除旧规范 |
| SK-005 | P1 | scripts/impl/gen_core.py | 文件按路径排序，类include又当编译单元，pkg依赖可能反序 | 接收显式编译清单，include文件标is_include_file，必须运行生成core |
| SK-006 | P1 | references/template-applicability 与 vip_check.py | 工具只识别 `# 1`，常用 `## 1` 全被视为章节缺失；章节数量无法证明内容质量 | 用Markdown AST和语义字段校验，允许等效短文档 |
| SK-007 | P1 | 主SKILL工作区布局 与 workflow AGENT.md | suite给独立.venv，workflow禁止子虚拟环境；正式VIP允许路径也未匹配vip/amba | 使用workflow根uv环境，开发目录按用户纠正迁入VIP repo（见SK-009）；补充宿主集成优先规则 |
| SK-008 | P1 | HWIF前置门禁 | 现有Lite HWIF缺HSEL/HMASTLOCK，hready_in方向也不足以描述本规格；强制只消费现有HWIF会删需求 | 声明development binding与映射差异，后续HWIF专门演进；不冒充完全兼容 |
| SK-009 | P0（用户纠正） | 主 SKILL.md「统一 VIP 开发工作区布局」要求 developing 阶段不进入正式 VIP REPO | 用户明确要求：开发工作区应放在 vip-repo 对应文件夹。本次临时目录 tmp/vip_ahb 不符合实际仓库协作需求，增加迁移、源码定位和构建路径失效成本 | 已按用户要求迁移到 repos/aixsilicon_vip_repo/vip/amba/ahb/。建议默认在 VIP repo 的 vip/<category>/<name>/ 开发，以 registry lifecycle 和 Gate 区分 Developing/Qualified/Released；发布状态不应由物理目录决定。仅跨仓临时验证场地使用 tmp。 |
| SK-010 | P0 | scripts/impl/qualify.py + coverage_check.py TARGETS | Qualification 固定使用95%等通用阈值，不能直接表达本合同关键 bins/交叉100%的更严格门槛 | 把阈值写入需求/验证计划机器输入，取合同要求；本次不以通用门禁代替全规格验收 |
| SK-011 | P0 | qualify.py `_rtm_unresolved` | 只扫现有Markdown表的失败词；若删掉未实现需求整行，没有对照原始需求ID集合就无法发现缺项 | 独立校验169个ID集合、唯一性、父项责任和逐项证据；建议门禁强制集合相等 |
| SK-012 | P1 | templates/vip/examples/smoke 与 templates unit | scaffold 中存在以保留字 `checker` 命名对象，unit引用通用cfg.DATA_WIDTH/tr_id；自动实例化不代表能编译，也留下未被filelist编译的坏文件 | 删除或替换所有未适配模板，必须对发布文件清单全部进行编译/包含可达性检查 |
| SK-013 | P1 | scripts/impl/vip_check.py 的 unit 文件与 Makefile 检查 | 本次 ahb_unit_tb.sv 已实现 check、失败计数和 UNIT_TEST_PASS，工具仍因没有固定文件名 unit_test_runner.sv 判 FAIL；合法多目标 Make rule `unit compile smoke: ...` 被误判没有 unit target | 本次显式展开 unit target，并把真实公共断言计数器提取为工具指定文件名，重跑 vip-check 已通过。建议允许声明 runner 路径并解析 filelist / 执行 make unit 的真实结果，避免文件名代替行为证据。 |

## 后续修复 — 2026-09-10

用户本轮授权修改Skill后，SK-001至SK-013已在canonical vip-development-suite完成对应修复。25项回归（含三个实际VCS/FuseSoC编译目标）、Suite自校验及workflow检查通过。原表为上一轮实施记录，详细修复及验证范围见[Skill修复报告](../../../../../aixsilicon_skill_repo/reports/vip-development-suite/2026-09-10-ahb-fixes.md)。这些修复不代表AHB完整规格G5已通过。
