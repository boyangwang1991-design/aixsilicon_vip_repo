# Schema

本目录存放 VIP Repository 的元数据 JSON Schema（以 YAML 表达的 JSON Schema，草案 2020-12 / draft-07 兼容）。

| Schema | 文件 | 用途 |
|---|---|---|
| VIP Metadata | [`vip_metadata.schema.yaml`](vip_metadata.schema.yaml) | 校验 `*/metadata/vip.yaml` |
| Testplan | [`testplan.schema.yaml`](testplan.schema.yaml) | 校验 `docs/testplan.md` 对应的 YAML 侧载数据 / test 定义 |
| Coverage | [`coverage.schema.yaml`](coverage.schema.yaml) | 校验 coverage 计划与覆盖点定义 |
| Release Manifest | [`release_manifest.schema.yaml`](release_manifest.schema.yaml) | 校验 `*/metadata/release_manifest.yaml` |

## 校验方式

CI 与本地均使用 `vip-repo-maintainer` 套件统一入口校验（Schema 语义见
[`vip-repo-maintainer/references/metadata-schema.md`](../../../aixsilicon_skill_repo/skills/vip-repo-maintainer/references/metadata-schema.md)）：

```bash
SUITE_DIR="${SUITE_DIR:-.roo/skills/vip-repo-maintainer}"
uv run python ${SUITE_DIR}/scripts/vip_tool.py metadata-check --root .. --vip apb
```

## 约定

- `schema_version`：Schema 自身版本，当前为 `1.0`；
- 协议规范版本不能写成模糊的“latest”，必须记录受控环境中的实际规范标识；
- `quality.gate` 取值：`V0_PROTOTYPE` / `V1_ALPHA` / `V2_BETA` / `V3_QUALIFIED` / `V4_PROVEN`；
- `tools.<tool>` 取值：`qualified` / `beta` / `unsupported`。
