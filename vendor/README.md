# vendor — 第三方来源管理

只保存第三方来源的 Manifest、锁定 commit、许可证、补丁与 SBOM 信息。

> 依据 `plan.md`：优先通过 FuseSoC 依赖外部已发布 Core，而不是复制源码。
> 若直接引入第三方源码，必须保留原始版权与许可证。

| 子目录 | 内容 |
|---|---|
| [`manifests/`](manifests/) | 第三方仓库来源 Manifest（URL、commit、tag、许可证、NOTICE） |
| [`patches/`](patches/) | 针对第三方的本地补丁（含补丁说明与原始引用） |

## 约定

- 每个第三方来源一个 YAML Manifest（参考 [`manifests/_template.yaml`](manifests/_template.yaml)）；
- 锁定 commit，不追踪浮动分支；
- GPL/AGPL 或未知许可证默认不进入正式库。
