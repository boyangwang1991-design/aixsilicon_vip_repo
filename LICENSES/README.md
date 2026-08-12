# Licenses

本仓库默认采用 **Apache License 2.0**。许可证全文见 [`Apache-2.0.txt`](Apache-2.0.txt)。

## 使用约定

- 本仓库原创代码默认 Apache-2.0；
- 第三方参考代码**不复制进本仓库源码目录**，仅在 `reference/` 中保留其原始克隆，
  并在 [`reference/REFERENCE_MANIFEST.md`](../reference/REFERENCE_MANIFEST.md) 记录来源、
  锁定 commit 与许可证；
- `vendor/` 只保存来源 Manifest、补丁与 SBOM 信息，若必须引入第三方源码，
  必须保留原始版权与许可证文件头；
- 每个 VIP 的 `metadata/vip.yaml` 中的 `vip.license` 字段记录该 VIP 实际采用的许可证。

## SPDX 标识

- 本仓库代码：`SPDX-License-Identifier: Apache-2.0`
