# catalog — 统一 Release Catalog 索引

汇总所有已登记 VIP 的能力、版本、质量等级、工具支持与兼容关系，供
UVM Verification Skill Suite 与项目自动选型/装配。

| 文件 | 内容 |
|---|---|
| [`vip_index.yaml`](vip_index.yaml) | 全部登记 VIP 的索引（VLNV、能力、gate、工具） |
| [`compatibility_matrix.yaml`](compatibility_matrix.yaml) | 兼容矩阵与依赖关系 |

## 更新方式

```bash
python3 tools/catalog_export/export_catalog.py
```

> 正式 Catalog 默认只显示 `Qualified` 与 `Proven` 版本；骨架阶段会列出所有登记项并标注 gate。
