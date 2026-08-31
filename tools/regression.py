#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
regression.py — VIP 回归入口（G7 Regression 的自含编排）

职责：
1. 从 `registry.yaml`（SSOT）读取 `qualified` / `developing` VIP；
2. 按目标（target）调用 FuseSoC 运行指定 VIP 的回归（smoke / regression / negative / example）；
3. 汇总 PASS / FAIL / NOT_RUN / BLOCKED 结果并给出退出码。

说明：
- 本脚本仅编排"跑什么、怎么跑"，确定性编译/仿真由 FuseSoC 与仿真器完成；
- 未安装 FuseSoC 时状态为 BLOCKED，不伪报通过；
- 目标 `--target` 与 `.core` target 对齐（default/lint/unit_sim/smoke/regression/negative/example/formal/package）。

用法：
  uv run python tools/regression.py --root . --target smoke
  uv run python tools/regression.py --root . --vip axi4 --target regression
  uv run python tools/regression.py --root . --list

退出码：0=全部通过；1=存在失败；10=环境阻塞（无 fusesoc）。
"""
import argparse
import os
import shutil
import subprocess
import sys

VALID_TARGETS = ["default", "lint", "unit_sim", "smoke", "regression", "negative", "example", "formal", "package"]


def _load_registry(root):
    path = os.path.join(root, "registry.yaml")
    if not os.path.exists(path):
        return None, "未找到 registry.yaml"
    try:
        import yaml
    except ImportError:  # pragma: no cover
        return None, "缺少 pyyaml"
    with open(path, encoding="utf-8") as f:
        return yaml.safe_load(f), None


def _qualified_vips(reg):
    return [e for e in reg.get("vips", []) if e.get("status") in ("qualified", "developing")]


def main(argv=None):
    ap = argparse.ArgumentParser(prog="regression.py", description="VIP 回归入口（G7）")
    ap.add_argument("--root", default=".", help="aixsilicon-vip-repo 根目录")
    ap.add_argument("--vip", default=None, help="目标 VIP 名（默认全部）")
    ap.add_argument("--target", default="smoke", choices=VALID_TARGETS, help="回归 target")
    ap.add_argument("--list", action="store_true", help="列出可回归 VIP 与 VLNV")
    ap.add_argument("--dry-run", action="store_true", help="只打印将执行的命令，不实际运行")
    args = ap.parse_args(argv)

    root = os.path.abspath(args.root)
    reg, err = _load_registry(root)
    if err:
        print("BLOCKED: %s" % err, file=sys.stderr)
        return 10
    vips = _qualified_vips(reg)
    if args.vip:
        vips = [e for e in vips if e.get("name") == args.vip]

    if args.list:
        if not vips:
            print("（无 qualified/developing VIP）")
            return 0
        for e in sorted(vips, key=lambda x: x.get("id", "")):
            vlnv = "aixsilicon:vip:%s:%s" % (e.get("name", ""), e.get("version", "0.0.0"))
            print("%-10s %-24s %s" % (e.get("id", ""), e.get("name", ""), vlnv))
        return 0

    if not vips:
        print("INFO: 无 qualified/developing VIP 可回归（registry 中均为 planned）")
        return 0

    fusesoc = shutil.which("fusesoc")
    if not fusesoc:
        print("BLOCKED: 未找到 fusesoc，无法执行回归", file=sys.stderr)
        return 10

    results = []
    for e in sorted(vips, key=lambda x: x.get("id", "")):
        name = e.get("name", "")
        version = e.get("version", "0.0.0")
        if version == "-":
            version = "0.0.0"
        vlnv = "aixsilicon:vip:%s:%s" % (name, version)
        cmd = [fusesoc, "--cores-root=" + root, "run", "--target", args.target, vlnv]
        print("RUN  %s  %s" % (vlnv, " ".join(cmd)))
        if args.dry_run:
            results.append((name, "NOT_RUN", "dry-run"))
            continue
        r = subprocess.run(cmd, cwd=root, capture_output=True, text=True, timeout=3600)
        if r.returncode == 0:
            results.append((name, "PASS", ""))
        else:
            tail = (r.stderr or r.stdout or "").strip().splitlines()
            detail = tail[-3:] if tail else ["no output"]
            results.append((name, "FAIL", "; ".join(detail)))
            print("  -> FAIL %s" % vlnv)

    print("")
    print("=== 回归汇总（target=%s）===" % args.target)
    rc = 0
    for name, status, detail in results:
        print("%-8s %s" % (status, name))
        if status == "FAIL":
            rc = 1
            for line in detail:
                print("    %s" % line)
    print("")
    print("PASS=%d FAIL=%d NOT_RUN=%d" % (
        sum(1 for _, s, _ in results if s == "PASS"),
        sum(1 for _, s, _ in results if s == "FAIL"),
        sum(1 for _, s, _ in results if s == "NOT_RUN"),
    ))
    return rc


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
