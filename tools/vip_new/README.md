# vip_new — 新 VIP 骨架生成

基于 `protocol/apb/` 标准模板生成新 VIP 骨架并全局重命名 `apb_*` → `<vip>_*`。

## 用法

```bash
python3 tools/vip_new/generate_vip.py --name uart --dest peripheral/uart \
    --vlnv aix:vip:uart:1.0.0 --protocol-family UART
```

## 生成内容

- 完整目录结构（docs / metadata / src / sva / seq / tb / tests / examples）；
- 全部源码/文档重命名为 `<vip>_*`；
- FuseSoC Core：`aix_vip_<vip>_1.0.0.core`；
- 预填充的 metadata（VLNV、license、gate 等）。

> 生成后仍需按 `docs/development-guide/README.md` 的步骤完善内容并跑通 smoke。
