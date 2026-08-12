# package_release — 发布打包

为指定 VIP 生成正式发布包：校验 metadata、生成 tarball、Release Manifest 与 SBOM 占位。

## 用法

```bash
python3 tools/package_release/package_release.py --vip protocol/apb --version 1.0.0
```

## 输出

- `<dest>/<name>-<version>.tar.gz` 源码发布包；
- 校验 `metadata/vip.yaml` 与 `metadata/release_manifest.yaml`；
- 生成 SBOM 占位文件（实际 SBOM 由开源合规流程生成）。

> 只允许从受保护 Release 分支或 tag 触发正式发布。
