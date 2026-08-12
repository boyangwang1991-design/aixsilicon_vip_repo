#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 AIXSILICON
#
# export_catalog.py — 汇总各 VIP metadata 生成 catalog/vip_index.yaml 与
# catalog/compatibility_matrix.yaml。
"""Usage:
    python3 export_catalog.py [--out catalog]
"""
import argparse
import glob
import os
import sys

try:
    import yaml
except ImportError:
    print("ERROR: 需要 PyYAML")
    sys.exit(2)

SEARCH = [
    "protocol/*/metadata/vip.yaml",
    "peripheral/*/metadata/vip.yaml",
    "system/*/metadata/vip.yaml",
    "safety/*/metadata/vip.yaml",
    "common/*/metadata/vip.yaml",
]


def discover():
    found = []
    for p in SEARCH:
        found.extend(glob.glob(p))
    return sorted(set(found))


def main(argv):
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default="catalog")
    args = ap.parse_args(argv)

    entries = []
    for path in discover():
        try:
            with open(path) as f:
                data = yaml.safe_load(f)
        except Exception as e:  # noqa: BLE001
            print("WARN: 解析失败 %s: %s" % (path, e))
            continue
        if not data:
            continue
        vip = data.get("vip", {})
        quality = data.get("quality", {})
        tools = data.get("tools", {})
        entries.append({
            "id": vip.get("id"),
            "name": vip.get("name"),
            "vlnv": vip.get("vlnv"),
            "lifecycle": vip.get("lifecycle"),
            "gate": quality.get("gate"),
            "protocol": data.get("protocol", {}).get("name"),
            "modes": data.get("protocol", {}).get("modes", []),
            "tools": tools,
            "path": os.path.dirname(os.path.dirname(path)),
        })

    os.makedirs(args.out, exist_ok=True)

    index = {"schema_version": "1.0", "generated_by": "tools/catalog_export/export_catalog.py", "vips": entries}
    with open(os.path.join(args.out, "vip_index.yaml"), "w") as f:
        yaml.safe_dump(index, f, allow_unicode=True)

    matrix = {
        "schema_version": "1.0",
        "compatibilities": [],
    }
    for e in entries:
        for dep in []:  # 依赖关系可从 vip.yaml dependencies 提取（骨架阶段占位）
            pass
        matrix["compatibilities"].append({"vlnv": e["vlnv"], "gate": e["gate"]})

    with open(os.path.join(args.out, "compatibility_matrix.yaml"), "w") as f:
        yaml.safe_dump(matrix, f, allow_unicode=True)

    print("OK: 导出 %d 个 VIP" % len(entries))
    print("    %s" % os.path.join(args.out, "vip_index.yaml"))
    print("    %s" % os.path.join(args.out, "compatibility_matrix.yaml"))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
