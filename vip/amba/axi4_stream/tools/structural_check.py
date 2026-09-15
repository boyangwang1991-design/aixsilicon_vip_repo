#!/usr/bin/env python3
"""axi4_stream VIP 静态结构检查（补充 REQ-CHK-004）。

REQ-CHK-004 明确：纯黑盒 Checker/SVA 不能证明
  (a) source 没有等待 ready 才产生 valid；
  (b) 接口不存在组合路径。
这两点必须由结构检查/设计约束补充，不能伪装成完整 SVA 证明。本脚本因此对源码
做确定性静态检查（不替代编译，也不替代仿真），逐项给出证据并打印
AXIS_STRUCTURAL_PASS / AXIS_STRUCTURAL_FAIL。

检查项：
  S1  source 依赖方向：driver 内不得以 monitor 的 analysis port / 完成信息作为
      断言 TVALID 的前提；driver 不得读 monitor 的握手计数器。
  S2  接口组合路径：axi4_stream_if 本体不得含 assign/always（纯信号容器），
      且 driver/sink 对总线的驱动必须经 clocking block（无裸连续赋值）。
  S3  PASSIVE 不驱动：monitor 与 checker 不得对 vif 赋驱动值。
  S4  单一语义模型：byte 分类/归一化/token 化只允许出现在 types_pkg 与
      stream_model 中（组件不得复刻实现）。
  S5  无层次路径引用：源码不得出现 `tb.` / `dut.` 形式的跨层次引用。

用法:
    uv run --no-sync python tools/structural_check.py --log-dir <build>/<run>/logs

退出码：0=全部通过；1=存在结构违规；2=用法错误。
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "src"

FINDINGS: list[str] = []


def read(p: Path) -> str:
    return p.read_text(encoding="utf-8", errors="replace")


def strip_comments(text: str) -> str:
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.S)
    return re.sub(r"//[^\n]*", "", text)


def check_source_dependency() -> None:
    """S1：driver 不得依赖 monitor/观测信息决定是否拉高 TVALID。"""
    drv = SRC / "agent" / "axi4_stream_driver.sv"
    body = strip_comments(read(drv))
    # driver 中不得引用 monitor / observed_beat / beat_ap 等观测侧标识
    forbidden = ["monitor", "beat_ap", "packet_ap", "observed_beat", "observed_packet"]
    for token in forbidden:
        if re.search(r"\b" + token + r"\b", body):
            FINDINGS.append(
                f"S1 {drv.relative_to(ROOT)} 出现观测侧标识 '{token}'："
                "driver 不得以观测信息作为断言 TVALID 的前提（REQ-SRC-005/CHK-004）"
            )
    # TVALID 断言点不得被有效的 tready 条件包住
    m = re.search(r"if\s*\([^)]*effective_ready\(\)[^)]*\)\s*[^\n]*tvalid\s*<=\s*1'b1", body)
    if m:
        FINDINGS.append(
            f"S1 {drv.relative_to(ROOT)} 中 TVALID 断言被 ready 条件包裹："
            "违反 REQ-PRO-002（不得以 TREADY 为拉高 TVALID 的前提）"
        )


def check_interface_combinational() -> None:
    """S2：接口本体必须是被动信号容器；driver 侧必须经 clocking block 驱动。"""
    iface = SRC / "axi4_stream_if.sv"
    body = strip_comments(read(iface))
    if re.search(r"\bassign\b", body):
        FINDINGS.append(
            f"S2 {iface.relative_to(ROOT)} 含 assign：接口应为被动信号容器，"
            "接口内组合路径无法由黑盒 SVA 证明（REQ-CHK-004）"
        )
    if re.search(r"\balways(_ff|_comb|_latch)?\b", body):
        FINDINGS.append(
            f"S2 {iface.relative_to(ROOT)} 含 always：接口不应含时序逻辑"
        )
    for rel in ("agent/axi4_stream_driver.sv", "agent/axi4_stream_sink_driver.sv"):
        p = SRC / rel
        body = strip_comments(read(p))
        # 白名单：reset_response 是复位安全路径，允许直接赋值立即撤销 TVALID
        scan = re.sub(r"task reset_response\(\).*?endtask", "", body, flags=re.S)
        # 驱动必须使用 clocking block（drv_cb / ready_cb 的 <=）
        bare = re.findall(r"vif\.(tdata|tkeep|tstrb|tlast|tvalid|tid|tdest|tuser|tready)\s*<=", scan)
        if bare:
            FINDINGS.append(
                f"S2 {p.relative_to(ROOT)} 存在未经 clocking block 的裸驱动 "
                f"{sorted(set(bare))}：应通过 drv_cb/ready_cb 驱动（REQ-INT-001）"
            )


def check_passive_no_drive() -> None:
    """S3：monitor/checker 必须完全被动。"""
    for rel in ("agent/axi4_stream_monitor.sv", "checker/axi4_stream_checker.sv"):
        p = SRC / rel
        body = strip_comments(read(p))
        if re.search(r"vif\.[A-Za-z_0-9\[\]]+\s*<=", body):
            FINDINGS.append(
                f"S3 {p.relative_to(ROOT)} 对接口赋驱动值：PASSIVE 不得改变总线（REQ-MON-001）"
            )
        if re.search(r"\.drv_cb\b|\.ready_cb\b", body):
            FINDINGS.append(
                f"S3 {p.relative_to(ROOT)} 使用 driver clocking block：观测组件不得驱动（REQ-MON-001）"
            )


def check_single_semantic_model() -> None:
    """S4：语义实现只允许在 types_pkg / stream_model 中。"""
    owners = {"axi4_stream_types_pkg.sv", "axi4_stream_stream_model.sv"}
    patterns = [
        ("axis_classify_byte", "byte 分类"),
        ("tsval", ""),
    ]
    for p in sorted(SRC.rglob("*.sv")):
        if p.name in owners:
            continue
        body = strip_comments(read(p))
        # 其它文件不得重写分类/归一化/token 化逻辑
        for pat, what in patterns:
            if pat and re.search(r"function[^\n]*\b" + pat, body):
                FINDINGS.append(
                    f"S4 {p.relative_to(ROOT)} 复刻了 {what or pat} 实现："
                    "语义必须集中在 types_pkg/stream_model（REQ-INT-002、ADR2）"
                )
        if re.search(r"function[^\n]*(tokenize|effective_keep|effective_strb|byte_mask)\s*\(", body):
            FINDINGS.append(
                f"S4 {p.relative_to(ROOT)} 复刻了归一化/token 化实现：应调用 "
                "axi4_stream_types_pkg（REQ-INT-002、ADR2）"
            )


def check_no_hierarchy_ref() -> None:
    """S5：不得依赖 DUT 内部层次路径。"""
    for p in sorted(SRC.rglob("*.sv")):
        body = strip_comments(read(p))
        m = re.findall(r"\b(tb|dut|uvm_test_top)\.[A-Za-z_][A-Za-z_0-9]*", body)
        if m:
            FINDINGS.append(
                f"S5 {p.relative_to(ROOT)} 出现跨层次引用 {sorted(set(m))}："
                "VIP 不得依赖 DUT/测试平台层次路径（REQ-INT-002）"
            )


def main(argv):
    ap = argparse.ArgumentParser(description="axi4_stream 静态结构检查（REQ-CHK-004）")
    ap.add_argument("--log-dir", required=True, help="日志目录（必须在 build 下）")
    args = ap.parse_args(argv)

    log_dir = Path(args.log_dir).absolute()
    if log_dir.name != "logs" or log_dir.parent.parent.name != "build":
        print("ERROR: --log-dir 必须是 <VIP根>/build/<run-id>/logs")
        return 2
    log_dir.mkdir(parents=True, exist_ok=True)

    check_source_dependency()
    check_interface_combinational()
    check_passive_no_drive()
    check_single_semantic_model()
    check_no_hierarchy_ref()

    lines = ["VIP_RUN_SEED=1",
             "axi4_stream 静态结构检查（REQ-CHK-004 补充证据）",
             "检查文件：src/**/*.sv",
             ""]
    lines += ["PASS: " + c for c in [
        "S1 source 不依赖观测信息、TVALID 不被 ready 条件包裹",
        "S2 接口为被动信号容器、总线驱动经 clocking block",
        "S3 monitor/checker 完全被动、不驱动总线",
        "S4 语义实现在 types_pkg/stream_model 单点",
        "S5 无 DUT/测试平台跨层次引用",
    ]] if not FINDINGS else []
    if FINDINGS:
        lines += ["FAIL: " + f for f in FINDINGS]
        lines.append("AXIS_STRUCTURAL_FAIL")
    else:
        lines += ["", "S1..S5 全部通过（REQ-CHK-004 的结构性补充证据；"
                      "不替代仿真，也不表示协议认证）", "AXIS_STRUCTURAL_PASS"]

    out = log_dir / "structural_check.log"
    out.write_text("\n".join(lines) + "\n")
    print("\n".join(lines))
    return 0 if not FINDINGS else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))