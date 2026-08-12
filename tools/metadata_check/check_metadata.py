#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 AIXSILICON
#
# check_metadata.py — 校验 VIP metadata/vip.yaml 符合 schema/vip_metadata.schema.yaml。
# 自包含轻量校验器（不依赖 jsonschema），确定性任务，以 exit code 表达结果。
"""Usage:
    python3 check_metadata.py <path-to-vip.yaml> [<path2> ...]
    python3 check_metadata.py --all
"""
import sys
import re
import glob
import os

try:
    import yaml
except ImportError:
    print("ERROR: 需要 PyYAML（pip install pyyaml）")
    sys.exit(2)

VLNV_RE = re.compile(r"^[A-Za-z0-9_.-]+:[A-Za-z0-9_.-]+:[A-Za-z0-9_.-]+:[0-9]+\.[0-9]+\.[0-9]+$")
SEMVER_RE = re.compile(r"^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$")
GATES = {"V0_PROTOTYPE", "V1_ALPHA", "V2_BETA", "V3_QUALIFIED", "V4_PROVEN"}
LIFECYCLES = {"prototype", "alpha", "beta", "qualified", "proven", "deprecated"}
TOOL_STATES = {"qualified", "beta", "unsupported"}
MODES = {"active_master", "active_slave", "passive", "disabled"}

ERRORS = []


def _err(msg, path):
    ERRORS.append("%s: %s" % (path, msg))


def check_vip_metadata(path):
    with open(path, "r") as f:
        data = yaml.safe_load(f)
    if not isinstance(data, dict):
        _err("顶层必须是 mapping", path)
        return False

    if data.get("schema_version") != "1.0":
        _err("schema_version 必须为 '1.0'", path)

    vip = data.get("vip")
    if not isinstance(vip, dict):
        _err("缺少 vip 节", path)
    else:
        for k in ("id", "name", "vlnv", "lifecycle", "owner", "license"):
            if not vip.get(k):
                _err("vip.%s 缺失" % k, path)
        vlnv = vip.get("vlnv", "")
        if vlnv and not VLNV_RE.match(vlnv):
            _err("vip.vlnv 格式非法: %s" % vlnv, path)
        if vip.get("lifecycle") not in LIFECYCLES:
            _err("vip.lifecycle 枚举非法: %s" % vip.get("lifecycle"), path)

    proto = data.get("protocol")
    if not isinstance(proto, dict):
        _err("缺少 protocol 节", path)
    else:
        for k in ("family", "name", "revision", "modes"):
            if not proto.get(k):
                _err("protocol.%s 缺失" % k, path)
        for m in proto.get("modes", []):
            if m not in MODES:
                _err("protocol.modes 枚举非法: %s" % m, path)
        if proto.get("revision") and "latest" in str(proto["revision"]).lower():
            _err("protocol.revision 不允许写 'latest'，必须记录受控版本标识", path)

    deps = data.get("dependencies", [])
    if not isinstance(deps, list):
        _err("dependencies 必须是列表", path)
    for d in deps:
        base = re.sub(r"\^.*$", "", d).rstrip(":")
        if not re.match(r"^[A-Za-z0-9_.-]+:[A-Za-z0-9_.-]+:[A-Za-z0-9_.-]+$", base):
            _err("dependencies 项格式非法: %s" % d, path)

    tools = data.get("tools", {})
    if not isinstance(tools, dict):
        _err("tools 必须是 mapping", path)
    for k, v in tools.items():
        if v not in TOOL_STATES:
            _err("tools.%s 枚举非法: %s" % (k, v), path)

    quality = data.get("quality")
    if not isinstance(quality, dict):
        _err("缺少 quality 节", path)
    elif quality.get("gate") not in GATES:
        _err("quality.gate 枚举非法: %s" % quality.get("gate"), path)

    return not ERRORS or not any(p == path for p, _ in [(e.rsplit(":", 1)[0], None) for e in ERRORS])


def discover_all():
    patterns = [
        "protocol/*/metadata/vip.yaml",
        "peripheral/*/metadata/vip.yaml",
        "system/*/metadata/vip.yaml",
        "safety/*/metadata/vip.yaml",
        "common/*/metadata/vip.yaml",
    ]
    found = []
    for p in patterns:
        found.extend(glob.glob(p))
    return sorted(set(found))


def main(argv):
    args = argv[1:]
    paths = args if not (len(args) == 1 and args[0] == "--all") else discover_all()
    if not paths:
        paths = discover_all()
    if not paths:
        print("用法: check_metadata.py <path...> 或 --all")
        return 2

    rc = 0
    for p in paths:
        ERRORS.clear()
        try:
            check_vip_metadata(p)
        except Exception as e:  # noqa: BLE001
            _err("解析失败: %s" % e, p)
        if ERRORS:
            rc = 1
            print("FAIL %s" % p)
            for e in ERRORS:
                print("  - %s" % e)
        else:
            print("PASS %s" % p)
    return rc


if __name__ == "__main__":
    sys.exit(main(sys.argv))
