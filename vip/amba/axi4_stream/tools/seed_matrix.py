#!/usr/bin/env python3
"""axi4_stream VIP 多 seed 矩阵（REQ-ACC-005）。

需求：每个核心合法场景至少 20 个固定 seed；失败必须输出可重放配置与
最小相关窗口。本脚本对指定 tier 依次以固定 seed 运行 Makefile 目标，
逐 seed 记录结果与日志，并打印 AXIS_SEED_MATRIX_PASS / FAIL。

纪律：
  * 所有日志与中间产物写入 --log-dir（必须为 <VIP根>/build/<run-id>/logs）。
  * 每个 seed 的编译产物放在 build 内的独立目录，源仓不被写入。
  * 失败时保留该 seed 的日志并在报告中指出可重放命令。

用法:
    uv run --no-sync python tools/seed_matrix.py --vip-root <VIP根> \
        --build-dir <VIP根>/build/<run-id> --log-dir <VIP根>/build/<run-id>/logs \
        --tiers "smoke feature corner" --seeds 20 --seed-start 1

退出码：0=全部 seed 通过；1=存在失败；2=用法错误。
"""

from __future__ import annotations

import argparse
import os
import subprocess
import sys
from pathlib import Path


def main(argv):
    ap = argparse.ArgumentParser(description="axi4_stream 多 seed 矩阵（REQ-ACC-005）")
    ap.add_argument("--vip-root", required=True)
    ap.add_argument("--build-dir", required=True, help="<VIP根>/build/<run-id>")
    ap.add_argument("--log-dir", required=True, help="<VIP根>/build/<run-id>/logs")
    ap.add_argument("--tiers", default="smoke feature corner")
    ap.add_argument("--seeds", type=int, default=20)
    ap.add_argument("--seed-start", type=int, default=1)
    args = ap.parse_args(argv)

    vip = Path(args.vip_root).absolute()
    build = Path(args.build_dir).resolve()
    log_dir = Path(args.log_dir).resolve()
    if build.parent.name != "build":
        print("ERROR: --build-dir 必须是 <VIP根>/build/<run-id>")
        return 2
    if log_dir != build / "logs":
        print("ERROR: --log-dir 必须是 <build-dir>/logs")
        return 2
    if args.seeds < 1:
        print("ERROR: --seeds 必须 >= 1")
        return 2

    log_dir.mkdir(parents=True, exist_ok=True)
    tiers = args.tiers.split()
    env = {**os.environ, "PYTHONDONTWRITEBYTECODE": "1"}
    results = []

    for tier in tiers:
        # 每个 tier 只编译一次（编译与 seed 无关），随后以不同 seed 重复运行。
        cell = build / "work" / "seed" / tier
        cell.mkdir(parents=True, exist_ok=True)
        compile_log = log_dir / f"seed_{tier}_compile.log"
        compile_cmd = ["make", "-C", str(vip / "self_test"), "compile",
                       f"BUILD_DIR={cell}", f"LOG_DIR={log_dir}", f"SEED={args.seed_start}"]
        with compile_log.open("w") as stream:
            stream.write(f"VIP_RUN_SEED={args.seed_start}\n")
            stream.write(" ".join(compile_cmd) + "\n")
            stream.flush()
            proc = subprocess.run(compile_cmd, cwd=build, stdout=stream,
                                  stderr=subprocess.STDOUT, env=env, timeout=3600)
        if proc.returncode != 0:
            print(f"{tier} COMPILE FAILED；见 {compile_log}")
            return 1

        simv = cell / "smoke" / "simv"
        for k in range(args.seeds):
            seed = args.seed_start + k
            log = log_dir / f"seed_{tier}_s{seed}.log"
            run_cmd = [str(simv), "-no_save",
                       f"+UVM_TESTNAME=axi4_stream_{tier}_test",
                       f"+ntb_random_seed={seed}", f"+AXIS_SEED={seed}",
                       f"+AXIS_COV_FILE={log_dir}/cov_seed_{tier}_s{seed}.txt"]
            with log.open("w") as stream:
                stream.write(f"VIP_RUN_SEED={seed}\n")
                stream.write(" ".join(run_cmd) + "\n")
                stream.flush()
                proc = subprocess.run(run_cmd, cwd=cell / "smoke", stdout=stream,
                                      stderr=subprocess.STDOUT, env=env, timeout=3600)
            text = log.read_text(errors="replace")
            ok = (proc.returncode == 0
                  and f"VIP_RUN_SEED={seed}" in text
                  and "AXIS_" in text and "_PASS" in text
                  and "UVM_ERROR :    0" in text and "UVM_FATAL :    0" in text)
            results.append({"tier": tier, "seed": seed,
                            "status": "PASS" if ok else "FAIL",
                            "log": f"logs/{log.name}"})
            print(f"{tier} seed={seed} {'PASS' if ok else 'FAIL'}", flush=True)

    failed = [r for r in results if r["status"] != "PASS"]
    summary = log_dir / "seed_matrix.log"
    lines = ["VIP_RUN_SEED=%d" % args.seed_start,
             f"多 seed 矩阵（REQ-ACC-005）：tiers={tiers} seeds={args.seeds} "
             f"seed_start={args.seed_start}",
             f"总计 {len(results)} 次，失败 {len(failed)} 次", ""]
    for r in results:
        lines.append(f"{r['tier']:<8} seed={r['seed']:<3} {r['status']}  {r['log']}")
    if failed:
        lines += ["", "失败用例（可重放命令）："]
        for r in failed:
            cell_build = build / "work" / "seed" / f"{r['tier']}_s{r['seed']}"
            lines.append(
                f"  make -C {vip/'self_test'} {r['tier']} "
                f"BUILD_DIR={cell_build} LOG_DIR={log_dir} SEED={r['seed']}")
        lines.append("AXIS_SEED_MATRIX_FAIL")
    else:
        lines += ["", f"全部 {len(results)} 次通过（每 tier {args.seeds} 个固定 seed）",
                  "AXIS_SEED_MATRIX_PASS"]
    summary.write_text("\n".join(lines) + "\n")
    print(f"seed matrix: {len(results) - len(failed)}/{len(results)} PASS; 见 {summary}")
    return 0 if not failed else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))