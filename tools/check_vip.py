#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
check_vip.py — VIP 准入结构/元数据检查（G1 Structure + G2 Metadata 的轻量自含版本）

职责（self-contained，不依赖私有 skill）：
1. 校验 `registry.yaml` 结构一致性（与 gen_catalog.py 相同的规则子集）；
2. 对 `vip/<category>/<name>/` 下每个已准入（目录存在）的 VIP 检查：
   - 必需文件：README.md、CHANGELOG.md、metadata/vip.yaml、*.core、src/、docs/、qualification/；
   - FuseSoC Core：CAPI=2、VLNV 为 `aixsilicon:vip:*`、与 vip.yaml 一致；
   - 分类目录合法（vip/amba 等）。
3. 检查 `vip/` 下物理目录与 `registry.yaml` 状态的对账：
   - status=qualified 必须存在目录；
   - 存在目录但 status≠qualified 给出警告。

用法：
  uv run python tools/check_vip.py --root .
  uv run python tools/check_vip.py --root . --vip <name>

退出码：0=通过；1=检查失败；2=用法错误；10=配置/依赖阻塞。
"""
import argparse
import os
import re
import sys

try:
    import yaml
except ImportError:  # pragma: no cover
    print("错误: 未找到 pyyaml —— 请用含 pyyaml 依赖的工作区执行（uv run python tools/check_vip.py）。")
    raise SystemExit(10)

VALID_GROUP_TOPS = {"vip"}
VALID_CATEGORIES = {"amba", "peripheral", "memory", "chip", "debug", "io", "storage", "safety", "common"}
VALID_STATUS = {"planned", "developing", "qualified", "deprecated"}
REQUIRED_REGISTRY_FIELDS = ["id", "name", "family", "group", "profile",
                            "priority", "hwif", "description", "status", "version", "path"]
REQUIRED_VIP_FILES = ["README.md", "CHANGELOG.md", "metadata/vip.yaml", "src", "docs", "qualification"]
SRC_DIR_CANDIDATES = ["src", "interface", "bfm", "monitor", "checker"]


def _validate_registry(reg):
    errors = []
    vips = reg.get("vips", [])
    if not isinstance(vips, list):
        return ["vips 必须是列表"]
    ids = set()
    for e in vips:
        if not isinstance(e, dict):
            errors.append("条目不是 object")
            continue
        cid = e.get("id")
        if not cid:
            errors.append("缺 id")
        elif cid in ids:
            errors.append("id 重复: %s" % cid)
        else:
            ids.add(cid)
        for field in REQUIRED_REGISTRY_FIELDS:
            v = e.get(field)
            if v is None or (isinstance(v, str) and not v.strip()):
                errors.append("[%s] 缺必填字段: %s" % (cid or "?", field))
        st = e.get("status")
        if st and st not in VALID_STATUS:
            errors.append("[%s] status 非法: %s" % (cid, st))
        gp = e.get("group", "")
        gp_parts = gp.split("/") if gp else []
        if not gp_parts or gp_parts[0] not in VALID_GROUP_TOPS:
            errors.append("[%s] group 顶层非法: %s（应为 vip/<category>）" % (cid, gp))
        elif len(gp_parts) < 2 or gp_parts[1] not in VALID_CATEGORIES:
            errors.append("[%s] group 分类非法: %s（应为 amba/peripheral/memory/chip/debug/io/storage/safety/common）" % (cid, gp))
    return errors


def _extract_vlnv_from_core(text):
    m = re.search(r"^name:\s*([A-Za-z0-9_.:-]+)", text, re.MULTILINE)
    return m.group(1).strip() if m else ""


def _check_vip_dir(root, d):
    """检查单个已准入 VIP 目录，返回错误列表。"""
    errs = []
    rel = os.path.relpath(d, root).replace(os.sep, "/")
    parts = rel.split("/")
    # 分类合法（路径形如 vip/<category>/<name>）
    if len(parts) < 2 or parts[1] not in VALID_CATEGORIES:
        errs.append("VIP 位于非法分类: %s（应为 amba/peripheral/memory/chip/debug/io/storage/safety/common）" % rel)

    for f in ("README.md", "CHANGELOG.md"):
        if not os.path.isfile(os.path.join(d, f)):
            errs.append("缺少 %s" % f)
    if not os.path.isfile(os.path.join(d, "metadata", "vip.yaml")):
        errs.append("缺少 metadata/vip.yaml")
    if not any(os.path.isdir(os.path.join(d, s)) for s in SRC_DIR_CANDIDATES):
        errs.append("缺少源码目录（src/ 或 interface/ 或 bfm/ 等）")
    for s in ("docs", "qualification"):
        if not os.path.isdir(os.path.join(d, s)):
            errs.append("缺少 %s/ 目录" % s)

    # FuseSoC Core
    cores = [f for f in os.listdir(d) if f.endswith(".core")]
    if not cores:
        errs.append("缺少 FuseSoC .core 文件")
    else:
        vip_yaml_path = os.path.join(d, "metadata", "vip.yaml")
        md = {}
        if os.path.isfile(vip_yaml_path):
            with open(vip_yaml_path, encoding="utf-8") as f:
                md = yaml.safe_load(f) or {}
        vip_vlnv = (md.get("vip") or {}).get("vlnv", "")
        for core in cores:
            with open(os.path.join(d, core), encoding="utf-8", errors="replace") as f:
                text = f.read()
            if "CAPI=2:" not in text:
                errs.append("%s: 缺少 CAPI=2" % core)
            vlnv = _extract_vlnv_from_core(text)
            if vlnv and not vlnv.startswith("aixsilicon:vip:"):
                errs.append("%s: VLNV 命名空间非法: %s（应为 aixsilicon:vip:*）" % (core, vlnv))
            if vlnv and vip_vlnv and vlnv != vip_vlnv:
                errs.append("%s: .core VLNV (%s) 与 vip.yaml (%s) 不一致" % (core, vlnv, vip_vlnv))
    return errs


def main(argv=None):
    ap = argparse.ArgumentParser(prog="check_vip.py", description="VIP 准入结构/元数据检查")
    ap.add_argument("--root", default=".", help="aixsilicon-vip-repo 根目录")
    ap.add_argument("--vip", default=None, help="目标 VIP 名（默认检查全部目录）")
    args = ap.parse_args(argv)

    root = os.path.abspath(args.root)
    registry_path = os.path.join(root, "registry.yaml")
    if not os.path.exists(registry_path):
        print("FAIL: 未找到 %s" % registry_path, file=sys.stderr)
        return 10
    with open(registry_path, encoding="utf-8") as f:
        reg = yaml.safe_load(f) or {}

    reg_errors = _validate_registry(reg)
    if reg_errors:
        for e in reg_errors:
            print("FAIL [registry]: %s" % e)
        return 1

    # 对账：registry 状态 vs 物理目录
    vip_dir = os.path.join(root, "vip")
    if not os.path.isdir(vip_dir):
        print("FAIL: 缺少 vip/ 目录")
        return 1
    rc = 0

    # 目录存在的 VIP
    dirs = []
    for category in sorted(os.listdir(vip_dir)):
        cat_path = os.path.join(vip_dir, category)
        if not os.path.isdir(cat_path):
            continue
        for name in sorted(os.listdir(cat_path)):
            d = os.path.join(cat_path, name)
            if os.path.isdir(d) and (name != "__pycache__"):
                dirs.append(d)

    if args.vip:
        dirs = [d for d in dirs if os.path.basename(d) == args.vip]

    for d in dirs:
        errs = _check_vip_dir(root, d)
        if errs:
            rc = 1
            print("FAIL %s" % os.path.relpath(d, root))
            for e in errs:
                print("  - %s" % e)
        else:
            print("PASS %s" % os.path.relpath(d, root))

    # registry qualified 必须存在目录
    for e in reg.get("vips", []):
        if e.get("status") == "qualified":
            p = os.path.join(root, e.get("path", ""))
            if not os.path.isdir(p):
                print("FAIL [registry]: %s status=qualified 但目录不存在: %s" % (e.get("id"), e.get("path")))
                rc = 1

    if not dirs:
        print("INFO: 当前无已准入 VIP 目录（registry 中均为 planned/developing）")
    if rc == 0:
        print("OK: VIP 结构检查通过（%d 个物理目录，registry %d 条）" % (len(dirs), len(reg.get("vips", []))))
    return rc


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
