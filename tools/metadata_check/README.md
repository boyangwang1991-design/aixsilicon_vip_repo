# metadata_check — Metadata 校验

校验 VIP `metadata/vip.yaml` 等文件符合 [`schema/vip_metadata.schema.yaml`](../../schema/vip_metadata.schema.yaml)。

## 用法

```bash
python3 tools/metadata_check/check_metadata.py protocol/apb/metadata/vip.yaml
python3 tools/metadata_check/check_metadata.py --all
```

## 校验项

- `schema_version`；
- `vip.id` / `vip.vlnv` / `vip.lifecycle` / `vip.license`；
- `protocol.family/name/revision/modes`；
- `dependencies` VLNV 格式；
- `tools` 枚举（qualified / beta / unsupported）；
- `quality.gate` 枚举（V0_PROTOTYPE … V4_PROVEN）。

> 脚本为确定性任务，输出结构化日志并以 exit code 表达结果。
