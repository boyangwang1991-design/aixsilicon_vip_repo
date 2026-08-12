# APB 规范受控记录

依据 `plan.md` 第 12 节：协议规范版本不能写成模糊的 “latest”，必须在受控环境中记录实际使用的规范标识。

| 项 | 值 |
|---|---|
| 协议名称 | ARM AMBA APB |
| 规范版本 | IHI 0024H（AMBA 3 APB / APB4） |
| 规范正文位置 | 内部受控位置（不随仓库分发） |
| 引用记录 | `metadata/vip.yaml → protocol.revision` |
| 审计记录 | `metadata/compatibility.yaml → declared_limitations` |

## 变更控制

- 任何升级到 APB5 / PPROT / PSTRB 扩展必须同步更新本记录与 `metadata/compatibility.yaml`；
- 规范引用更新需走 PR 评审，并触发对应 requirement / test / coverage 的重新映射。
