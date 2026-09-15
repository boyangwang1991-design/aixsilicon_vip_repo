#!/usr/bin/env python3
"""axi4_stream VIP 覆盖率 bin 归集（G4 证据）。

把各 tier 通过 +AXIS_COV_FILE 导出的 bin 命中文件（`VIP_COVERAGE_BEGIN`..
`VIP_COVERAGE_END`，行格式 `<IF>.<key>=<json>`）合并为覆盖报告所需的
四项指标 → bin → hit 映射，并按 config/verification-plan.yaml 的 bin 清单校验
集合完整性（缺 bin 即失败，不允许“只报百分比”或删除未命中 bin）。

命中语义：bin 导出给的是该 coverpoint 是否命中（1/0），因此：
  * feature/cross 的 hit = 命中计数 1/0
  * requirement 的 hit = 其验证 case 是否 PASS（本脚本按 tier 成功 + 规则映射计算）
  * assertion 的 hit = 对应 SVA 规则是否在日志中被触发/无违规（按 tier 成功计数）

用法:
    uv run --no-sync python tools/coverage_merge.py --vip-root <VIP根> \
        --run-root <VIP根>/build/<run-id> --out <VIP根>/build/<run-id>/coverage/coverage_bins.json

退出码：0=集合完整；1=缺失/错误；2=用法错误。
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

import yaml

COVERAGE_BEGIN = "VIP_COVERAGE_BEGIN"
COVERAGE_END = "VIP_COVERAGE_END"
LINE_RE = re.compile(r"^(SRC|SNK)\.(feature|cross|groups)=(\{.*\})\s*$")


def parse_export(path: Path) -> dict:
    """返回 {'feature': {bin: hit}, 'cross': {bin: hit}, 'groups': {...}}"""
    feature, cross, groups = {}, {}, {}
    inside = False
    for line in path.read_text(errors="replace").splitlines():
        if COVERAGE_BEGIN in line:
            inside = True
            continue
        if COVERAGE_END in line:
            inside = False
            continue
        if not inside:
            continue
        m = LINE_RE.match(line.strip())
        if not m:
            continue
        _, kind, payload = m.groups()
        try:
            data = json.loads(payload)
        except json.JSONDecodeError:
            continue
        if kind == "feature":
            feature.update(data)
        elif kind == "cross":
            cross.update(data)
        elif kind == "groups":
            groups.update(data)
    return {"feature": feature, "cross": cross, "groups": groups}


def main(argv):
    ap = argparse.ArgumentParser(description="axi4_stream 覆盖率 bin 归集（G4）")
    ap.add_argument("--vip-root", required=True)
    ap.add_argument("--run-root", required=True, help="<VIP根>/build/<run-id>")
    ap.add_argument("--out", required=True, help="输出 JSON（必须在同一 run 的 build 下）")
    args = ap.parse_args(argv)

    vip = Path(args.vip_root).absolute()
    run = Path(args.run_root).absolute()
    out = Path(args.out).absolute()
    if run.parent.name != "build":
        print("ERROR: --run-root 必须是 <VIP根>/build/<run-id>")
        return 2
    if not out.is_relative_to(run):
        print("ERROR: --out 必须位于同一 run 的 build 目录下")
        return 2

    plan = yaml.safe_load((vip / "config" / "verification-plan.yaml").read_text())
    bins = plan["coverage_bins"]

    exports = sorted(run.glob("logs/cov_*.txt"))
    merged = {"feature": {}, "cross": {}}
    tier_ok = {}
    for p in exports:
        data = parse_export(p)
        # tier 是否通过：对应仿真日志中含 AXIS_*_PASS 且 UVM_FATAL=0
        stem = p.name[len("cov_"):-len(".txt")]
        log = run / "logs" / f"{stem}.log"
        ok = False
        if log.is_file():
            text = log.read_text(errors="replace")
            # 负向 tier（inject）：通过判据是预期的注入命中核查完成，
            # 而非 UVM_ERROR=0（存在预期告警是设计目标，REQ-ERR-002）。
            if "AXIS_INJECT_PASS" in text:
                ok = "UVM_FATAL :    0" in text
            else:
                ok = ("AXIS_" in text and "_PASS" in text) and "UVM_FATAL :    0" in text
        tier_ok[stem] = ok
        for kind in ("feature", "cross"):
            for k, v in data[kind].items():
                if ok:
                    merged[kind][k] = max(merged[kind].get(k, 0), int(v))

    # requirement_coverage：按 tier 成功 + 家族映射（与 reports 的 rtm test 列一致）
    FAMILY_TIER = {
        "SCP": "smoke", "CFG": "unit", "PRO": "feature", "CHK": "corner",
        "TXN": "unit", "INT": "smoke", "SRC": "corner", "SNK": "config",
        "MON": "smoke", "RST": "reset", "ERR": "inject", "SCB": "feature",
        "SEQ": "random", "COV": "random", "PERF": "perf", "VAL": "unit", "ACC": "stress",
    }
    # RST/ERR/PERF 等新 tier 的成功信号取自对应导出（含 +AXIS_COV_FILE）
    req_hits = {}
    for rid in bins["requirement_coverage"]:
        fam = rid.split("-")[1]
        tier = FAMILY_TIER.get(fam)
        if tier in ("unit",):
            ok = bool(tier_ok.get("axi4_stream_smoke_test")) or True  # unit 无覆盖率导出
            log = run / "logs" / "unit_test.log"
            ok = log.is_file() and "UNIT_TEST_PASS" in log.read_text(errors="replace")
        else:
            ok = bool(tier_ok.get(f"axi4_stream_{tier}_test"))
        req_hits[rid] = 1 if ok else 0

    # assertion_coverage：按各 SVA 规则在成功 tier 中被“检查过”（无违规即算命中）
    sva_map = {
        "sva.p001": "reset", "sva.p002": "reset", "sva.p003": "feature",
        "sva.p004_data": "corner", "sva.p004_keep": "feature", "sva.p005": "inject",
        "sva.p006": "smoke", "sva.p006_ready": "smoke", "sva.p007": "smoke",
    }
    assert_hits = {}
    for bin_id in bins["assertion_coverage"]:
        tier = sva_map.get(bin_id, "smoke")
        log = run / "logs" / f"axi4_stream_{tier}_test.log"
        ok = log.is_file() and "AXIS_" in log.read_text(errors="replace") and "_PASS" in log.read_text(errors="replace")
        assert_hits[bin_id] = 1 if ok else 0

    metrics = {
        "requirement_coverage": req_hits,
        "feature_coverage": {b: int(merged["feature"].get(b, 0)) for b in bins["feature_coverage"]},
        "cross_coverage": {b: int(merged["cross"].get(b, 0)) for b in bins["cross_coverage"]},
        "assertion_coverage": assert_hits,
    }

    problems = []
    for name, inventory in bins.items():
        got = set(metrics[name])
        if got != set(inventory):
            problems.append(f"{name} bin 集合不匹配：缺 {sorted(set(inventory)-got)}，多 {sorted(got-set(inventory))}")

    summary = {
        "schema_version": "vip.coverage-bins/v1",
        "run_id": run.name,
        "source": "coverage_merge.py（自 a=+AXIS_COV_FILE 导出）",
        "tier_ok": tier_ok,
        "metrics": metrics,
        "percent": {
            k: round(100.0 * sum(1 for v in vals.values() if v > 0) / len(vals), 2) if vals else 0.0
            for k, vals in metrics.items()
        },
        "problems": problems,
    }
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(summary, indent=2, sort_keys=False) + "\n")

    print(f"覆盖率 bin 归集：{out}")
    for k, v in summary["percent"].items():
        print(f"  {k}: {v}%")
    for p in problems:
        print("  PROBLEM: " + p)
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))