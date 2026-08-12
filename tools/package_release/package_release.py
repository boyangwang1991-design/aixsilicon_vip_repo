#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 AIXSILICON
#
# package_release.py — 生成 VIP 发布包（tarball + Release Manifest 校验 + SBOM 占位）。
"""Usage:
    python3 package_release.py --vip protocol/apb --version 1.0.0 [--out dist]
"""
import argparse
import glob
import os
import re
import shutil
import sys
import tarfile
import tempfile

try:
    import yaml
except ImportError:
    yaml = None

SEMVER_RE = re.compile(r"^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$")


def _read(path):
    with open(path, "r") as f:
        return f.read()


def main(argv):
    ap = argparse.ArgumentParser()
    ap.add_argument("--vip", required=True, help="VIP 目录，如 protocol/apb")
    ap.add_argument("--version", required=True, help="SemVer，如 1.0.0")
    ap.add_argument("--out", default="dist", help="输出目录")
    args = ap.parse_args(argv)

    if not SEMVER_RE.match(args.version):
        print("ERROR: 版本号不是合法 SemVer: %s" % args.version)
        return 2

    vip = args.vip.rstrip("/")
    name = os.path.basename(vip)
    meta = os.path.join(vip, "metadata", "vip.yaml")
    if not os.path.isfile(meta):
        print("ERROR: 缺少 metadata/vip.yaml: %s" % meta)
        return 2

    if yaml:
        data = yaml.safe_load(_read(meta))
        vlnv = data.get("vip", {}).get("vlnv", "unknown")
        print("INFO: 打包 %s (%s) version=%s" % (name, vlnv, args.version))
    else:
        print("WARN: 无 PyYAML，跳过 metadata 解析")

    outdir = os.path.join(args.out, name + "-" + args.version)
    shutil.rmtree(outdir, ignore_errors=True)
    os.makedirs(outdir)

    # 拷贝关键文件（排除 tb 缓存 / 大目录）
    for item in os.listdir(vip):
        p = os.path.join(vip, item)
        if item in ("__pycache__", ".pytest_cache"):
            continue
        shutil.copytree(p, os.path.join(outdir, item)) if os.path.isdir(p) else shutil.copy2(p, outdir)

    # Release Manifest
    manifest = {
        "schema_version": "1.0",
        "release": {"vlnv": vlnv if yaml else "unknown", "version": args.version},
        "artifacts": [],
    }
    with open(os.path.join(outdir, "metadata", "release_manifest.yaml"), "w") as f:
        yaml.safe_dump(manifest, f) if yaml else f.write(str(manifest))

    # SBOM 占位
    sbom = os.path.join(outdir, "metadata", "sbom.spdx.json")
    if not os.path.exists(sbom):
        with open(sbom, "w") as f:
            f.write('{"spdxVersion": "SPDX-2.3", "name": "%s-%s", "SPDXID": "SPDXRef-DOCUMENT", "packages": []}\n' % (name, args.version))

    tarball = os.path.join(args.out, "%s-%s.tar.gz" % (name, args.version))
    os.makedirs(args.out, exist_ok=True)
    with tarfile.open(tarball, "w:gz") as tar:
        tar.add(outdir, arcname="%s-%s" % (name, args.version))

    print("OK: %s" % tarball)
    print("    校验 Release Manifest: %s" % os.path.join(outdir, "metadata", "release_manifest.yaml"))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
