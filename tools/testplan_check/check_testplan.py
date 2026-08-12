#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 AIXSILICON
#
# check_testplan.py — 检查 testplan / coverage / requirements 的 ID 与 RTM 一致性。
# 轻量自包含实现，确定性任务，以 exit code 表达结果。
"""Usage:
    python3 check_testplan.py <vip-dir>    # 例如 protocol/apb
    python3 check_testplan.py --all
"""
import sys
import re
import glob
import os

REQ_RE = re.compile(r"\bREQ-[A-Z0-9]+-[0-9]+\b")
TEST_RE = re.compile(r"\bTEST-[A-Z0-9]+-[0-9]+\b")
COV_RE = re.compile(r"\bCOV-[A-Z0-9]+-[0-9]+\b")

ERRORS = []


def read_text(path):
    with open(path, "r", encoding="utf-8", errors="ignore") as f:
        return f.read()


def check_vip_dir(vip_dir):
    docs = os.path.join(vip_dir, "docs")
    req_path = os.path.join(docs, "requirements.md")
    tp_path = os.path.join(docs, "testplan.md")
    cp_path = os.path.join(docs, "coverage_plan.md")

    for name, p in (("requirements", req_path), ("testplan", tp_path), ("coverage_plan", cp_path)):
        if not os.path.isfile(p):
            ERRORS.append("%s: 缺少 docs/%s.md" % (vip_dir, name))
            return False

    req_text = read_text(req_path)
    tp_text = read_text(tp_path)
    cp_text = read_text(cp_path)

    # 收集 ID
    req_ids = set(REQ_RE.findall(req_text))
    test_ids = set(TEST_RE.findall(tp_text))
    cov_ids = set(COV_RE.findall(cp_text))
    req_in_tp = set(REQ_RE.findall(tp_text))
    req_in_cp = set(REQ_RE.findall(cp_text))

    # 所有 Test 引用的 Requirement 必须存在
    for r in req_in_tp - req_ids:
        ERRORS.append("%s: testplan 引用未定义的 Requirement %s" % (vip_dir, r))
    # 所有 Coverage 引用的 Requirement 必须存在
    for r in req_in_cp - req_ids:
        ERRORS.append("%s: coverage_plan 引用未定义的 Requirement %s" % (vip_dir, r))

    # Coverage 引用的 Test 必须存在
    tests_in_cp = set(TEST_RE.findall(cp_text))
    for t in tests_in_cp - test_ids:
        ERRORS.append("%s: coverage_plan 引用未定义的 Test %s" % (vip_dir, t))

    if not req_ids:
        ERRORS.append("%s: requirements.md 未定义任何 Requirement" % vip_dir)
    if not test_ids:
        ERRORS.append("%s: testplan.md 未定义任何 Test" % vip_dir)
    if not cov_ids:
        ERRORS.append("%s: coverage_plan.md 未定义任何 Coverage" % vip_dir)

    return not ERRORS


def discover_all():
    roots = ["protocol", "peripheral", "system", "safety", "common"]
    dirs = []
    for r in roots:
        for md in glob.glob(os.path.join(r, "*", "docs", "requirements.md")):
            d = os.path.dirname(os.path.dirname(md))
            if d not in dirs:
                dirs.append(d)
    return sorted(dirs)


def main(argv):
    args = argv[1:]
    targets = args if not (len(args) == 1 and args[0] == "--all") else discover_all()
    if not targets:
        targets = discover_all()
    if not targets:
        print("用法: check_testplan.py <vip-dir> 或 --all")
        return 2

    rc = 0
    for t in targets:
        ERRORS.clear()
        if not os.path.isdir(t):
            print("FAIL %s: 不是目录" % t)
            rc = 1
            continue
        check_vip_dir(t)
        if ERRORS:
            rc = 1
            print("FAIL %s" % t)
            for e in ERRORS:
                print("  - %s" % e)
        else:
            print("PASS %s" % t)
    return rc


if __name__ == "__main__":
    sys.exit(main(sys.argv))
