# AHB development run log

## 2026-09-10 — Input and setup
- User authorized autonomous full implementation and skill feedback; no workflow confirmation required.
- Loaded canonical vip-development-suite and requirement/architecture/development/test/coverage/qualification instructions.
- `uv run python bootstrap.py --ensure`; `uv run aix wf status`: completed; existing untracked AHB contract preserved. Other repositories have unrelated changes and are untouched.
- uv default cache was read-only in sandbox; initialization was rerun through execution permission mechanism. Subsequent invocations use writable task cache /tmp/ahb-uv-cache.
- `vip_tool.py scaffold --name ahb --category amba --profile FULL_UVM --version 0.1.0 --output tmp/vip_ahb`: completed.
- G0/G1 inputs captured before source implementation. Full-profile source review unresolved; user-authorized development proceeds without inventing READY/PASS.
- Read local HWIF Lite interface: missing lock/select and distinct ready-out signals; explicit development binding required.

## Version 0.1.0
Added: AHB development candidate based on supplied complete contract. Gate status remains evidence-driven; no remote publication.

## 2026-09-10 — 用户纠正开发目录
- 用户要求开发工作区放在 VIP repo 对应目录，并记录到技能优化 report。
- 将完整开发树 tmp/vip_ahb 迁至 repos/aixsilicon_vip_repo/vip/amba/ahb/；原始 ahb_contract.md 保持原位不变。
- Skill 建议被用户明确覆盖；SK-009 记录原因和建议。
- 迁移前日志属于历史证据，含旧目录；后续构建重新执行，不能假定含绝对路径的仿真二进制可迁移。
- 最新源码已通过 unit/vectors/smoke/negative/extensions；新增 scenario 编译发现 read() 参数方向继承错误，正在修复并重跑。

## 2026-09-10T12:51:08.257006+00:00 — Final development evidence
- Production source and all13 development tiers validated with fingerprint dfd100e7b01591b9fbe7cc3a250a4682314d77fd63f36748d184c9a44dfc9682. 256 consecutive-write throughput assertion and 256 readback passed.
- unit/vectors/negative use independent semantic/cycle/parity oracles; added hostile analysis subscribers and structural-freeze tests.
- Million-beat final stress PASS: 93.24s, max RSS 176388 KiB. It is not a leakage proof.
- Three profile witnesses each ran100 fixed seeds on final binaries:300/300 PASS. Earlier seed manifests/logs refer to superseded source and are retained as history, not final evidence.
- Six real source mutations detected by expected semantic failures; all compile successfully. Production src fingerprint matches mutation baseline.
- Fixed net/clocking driver declarations; final VCS warning scan has zero warnings. Regenerated explicit-order FuseSoC core and ran smoke in self_test/build/fusesoc_final.
- Suite vip-check and config schema/169-ID validation PASS; extracted real unit runner to satisfy Suite filename requirement. SK-013 records its overly rigid recognition.
- Workspace make check (124 tests plus lint/schema) and pre-commit passed. These workflow checks do not imply a dedicated SV lint pass. Repository state inspected through bootstrap.py --skip-materialize aix repo status vip; no commit/push.
- Full product G0/G1 review, full requirement acceptance and coverage remain unclosed. qualify --write is the only G5 writer; no release performed.
- Input contract byte-for-byte unchanged. Implementation and Skill improvement reports are inside the VIP repo development directory.
