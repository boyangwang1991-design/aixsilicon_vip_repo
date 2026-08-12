# catalog_export — Catalog 导出

汇总各 VIP 的 `metadata/vip.yaml` 到 `catalog/vip_index.yaml` 与 `catalog/compatibility_matrix.yaml`。

## 用法

```bash
python3 tools/catalog_export/export_catalog.py
```

## 输出

- `catalog/vip_index.yaml`：全部登记 VIP 的 VLNV、能力、质量等级、工具支持；
- `catalog/compatibility_matrix.yaml`：VIP 间兼容与依赖关系。

> 正式 Catalog 默认只显示 Qualified 与 Proven 版本（当前骨架阶段会列出所有登记项，标注 gate）。
