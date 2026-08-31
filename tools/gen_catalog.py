#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
gen_catalog.py — 将 registry.yaml（SSOT）中的 VIP 状态可视化刷新到 README.md 与 vip_catalog.md

职责：
1. 加载并校验 registry.yaml（id 唯一 / 必填字段 / status / profile / priority / path-group 一致性）；
2. 生成「状态总览」 Markdown 区块（已准入 VIP 表 + 类别/Profile/优先级统计）；
3. 就地替换 README.md 中 `<!-- REGISTRY-STATUS:BEGIN -->` 与 `<!-- REGISTRY-STATUS:END -->`
   之间的内容（无 marker 时退出并提示，避免破坏其它手工内容）；
4. 生成 vip_catalog.md（完整 VIP 明细索引）。

用法：
  uv run python tools/gen_catalog.py --root .            # 校验并就地刷新 README.md / vip_catalog.md
  uv run python tools/gen_catalog.py --root . --dry-run  # 仅打印将写入的区块，不写文件
  uv run python tools/gen_catalog.py --root . --check    # 只读检查一致性（退出码 1=不一致）

退出码：0=通过/已刷新；10=校验失败；20=用法错误；40=内部错误。
"""
import argparse
import os
import sys

try:
    import yaml
except ImportError:  # pragma: no cover
    print("错误: 未找到 pyyaml —— 请用含 pyyaml 依赖的工作区执行（uv run python tools/gen_catalog.py）。")
    raise SystemExit(3)

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REGISTRY_PATH = os.path.join(ROOT, "registry.yaml")
README_PATH = os.path.join(ROOT, "README.md")
CATALOG_PATH = os.path.join(ROOT, "vip_catalog.md")

BEGIN_MARKER = "<!-- REGISTRY-STATUS:BEGIN -->"
END_MARKER = "<!-- REGISTRY-STATUS:END -->"

VALID_PROFILE = {"FULL_UVM", "LIGHTWEIGHT", "PASSIVE", "CHECKER_ONLY", "MODEL"}
VALID_PRIORITY = {"P0", "P1", "P2", "P3"}
VALID_STATUS = {"planned", "developing", "qualified", "deprecated"}
VALID_GROUP_TOPS = {"vip"}
VALID_CATEGORIES = {"amba", "peripheral", "memory", "chip", "debug", "io", "storage", "safety", "common"}
REQUIRED_FIELDS = ["id", "name", "family", "group", "profile",
                   "priority", "hwif", "description", "status", "version", "path"]


def _disp_width(s: str) -> int:
    """估算字符串显示宽度（中日韩全角按 2 计），用于 Markdown 表格源码对齐。"""
    width = 0
    for ch in str(s):
        if ord(ch) > 0x2E7F:  # CJK 等全角区
            width += 2
        else:
            width += 1
    return width


def _pad(s, width: int) -> str:
    """按显示宽度右补空格。"""
    return str(s) + " " * max(0, width - _disp_width(str(s)))


def _md_table(headers, rows):
    """生成 Markdown 表格源码（按显示宽度对齐）。"""
    cols = list(zip(headers, *rows))
    widths = [max(_disp_width(str(c)) for c in col) for col in cols]
    sep = "|" + "|".join("-" * (w + 2) for w in widths) + "|"
    lines = ["|" + "|".join(" %s " % _pad(c, w) for c, w in zip(headers, widths)) + "|",
             sep]
    for r in rows:
        lines.append("|" + "|".join(" %s " % _pad(c, w) for c, w in zip(r, widths)) + "|")
    return "\n".join(lines)


def load_registry(path=REGISTRY_PATH):
    with open(path, encoding="utf-8") as f:
        data = yaml.safe_load(f)
    if not isinstance(data, dict) or not isinstance(data.get("vips"), list):
        raise ValueError("registry.yaml 为空或缺少 vips 列表（文件可能损坏或未正确加载）")
    return data


def validate(reg):
    """轻量一致性校验，返回 (errors, warnings)。"""
    errors, warnings = [], []
    vips = reg.get("vips", [])
    if not isinstance(vips, list):
        errors.append("vips 必须是列表")
        return errors, warnings
    ids = set()
    for i, e in enumerate(vips):
        if not isinstance(e, dict):
            errors.append("[%d] 条目不是 object" % i)
            continue
        cid = e.get("id")
        if not cid:
            errors.append("[%d] 缺 id" % i)
        elif cid in ids:
            errors.append("id 重复: %s" % cid)
        else:
            ids.add(cid)
        for field in REQUIRED_FIELDS:
            v = e.get(field)
            if v is None or (isinstance(v, str) and not v.strip()):
                errors.append("[%s] 缺必填字段: %s" % (cid or "?", field))
        pr = e.get("profile")
        if pr and pr not in VALID_PROFILE:
            errors.append("[%s] profile 非法: %s（应为 FULL_UVM/LIGHTWEIGHT/PASSIVE/CHECKER_ONLY/MODEL）" % (cid, pr))
        pr = e.get("priority")
        if pr and pr not in VALID_PRIORITY:
            errors.append("[%s] priority 非法: %s" % (cid, pr))
        st = e.get("status")
        if st and st not in VALID_STATUS:
            errors.append("[%s] status 非法: %s（应为 planned/developing/qualified/deprecated）" % (cid, st))
        gp = e.get("group", "")
        gp_parts = gp.split("/") if gp else []
        if not gp_parts or gp_parts[0] not in VALID_GROUP_TOPS:
            errors.append("[%s] group 顶层非法: %s（应为 vip/<category>）" % (cid, gp))
        elif len(gp_parts) < 2 or gp_parts[1] not in VALID_CATEGORIES:
            errors.append("[%s] group 分类非法: %s（应为 amba/peripheral/memory/chip/debug/io/storage/safety/common）" % (cid, gp))
        p = e.get("path", "")
        if p:
            parts = p.split("/")
            if len(parts) < 3 or parts[0] != "vip" or parts[1] not in VALID_CATEGORIES or p == gp or not p.startswith(gp + "/"):
                errors.append("[%s] path(%s) 与 group(%s) 不一致" % (cid, p, gp))
        if st == "qualified" and not os.path.isdir(os.path.join(ROOT, p)):
            errors.append("[%s] status=qualified 但目录不存在: %s" % (cid, p))
        if st != "qualified" and os.path.isdir(os.path.join(ROOT, p)):
            warnings.append("[%s] 目录存在但 status=%s（应更新为 qualified 或移除目录）" % (cid, st))
    return errors, warnings


def _status_link(e):
    rel = e.get("path", "")
    name = e.get("name", "")
    if rel and os.path.isdir(os.path.join(ROOT, rel)):
        return "[%s](%s/README.md)" % (name, rel)
    return name


def build_status_section(reg):
    """从 registry 生成状态总览 Markdown 区块（不含 BEGIN/END marker）。"""
    vips = reg.get("vips", [])
    total = len(vips)
    by_status = {s: [e for e in vips if e.get("status") == s] for s in VALID_STATUS}
    updated = reg.get("updated", "未知")

    lines = []
    lines.append("> 本节由 `tools/gen_catalog.py` 依据 `registry.yaml`（SSOT）自动生成。")
    lines.append("> 修改 `registry.yaml` 后必须运行 `uv run python tools/gen_catalog.py --root .` 刷新本节；勿手工编辑。")
    lines.append("> 最后更新：`%s`" % updated)
    lines.append("")
    lines.append("### 总览")
    lines.append("")
    rows = [["总条目（vips）", str(total)]]
    for s in ("qualified", "developing", "planned", "deprecated"):
        rows.append(["%s" % s, str(len(by_status.get(s, [])))])
    rows.append(["准入率", "%.1f%%" % (100.0 * len(by_status.get("qualified", [])) / total if total else 0.0)])
    lines.append(_md_table(["指标", "数量"], rows))
    lines.append("")

    qualified = sorted(by_status.get("qualified", []), key=lambda e: e.get("id", ""))
    lines.append("### 已准入 VIP（%d）" % len(qualified))
    lines.append("")
    if qualified:
        qrows = []
        for e in qualified:
            qrows.append([e.get("id", ""), _status_link(e), e.get("family", ""),
                          e.get("profile", ""), e.get("priority", ""),
                          e.get("version", ""), e.get("group", "")])
        lines.append(_md_table(["ID", "VIP", "名称", "Profile", "优先级", "版本", "类别"], qrows))
    else:
        lines.append("（当前无已准入 VIP）")
    lines.append("")

    # 按类别统计
    lines.append("### 按类别分布（qualified / developing / planned）")
    lines.append("")
    cats = {}
    for e in vips:
        cat = e.get("group", "(未分类)")
        cats.setdefault(cat, [0, 0, 0])
        if e.get("status") == "qualified":
            cats[cat][0] += 1
        elif e.get("status") == "developing":
            cats[cat][1] += 1
        else:
            cats[cat][2] += 1
    cat_rows = []
    for cat in sorted(cats):
        q, d, p = cats[cat]
        cat_rows.append([cat, str(q), str(d), str(p), str(q + d + p)])
    lines.append(_md_table(["类别", "qualified", "developing", "planned", "合计"], cat_rows))
    lines.append("")

    # 按 Profile 统计
    lines.append("### 按 Profile 分布")
    lines.append("")
    prof_map = {}
    for e in vips:
        pr = e.get("profile", "?")
        prof_map.setdefault(pr, 0)
        prof_map[pr] += 1
    lines.append(_md_table(["Profile", "数量"],
                           [[pr, str(n)] for pr, n in sorted(prof_map.items())]))
    lines.append("")

    # 按优先级统计
    lines.append("### 按优先级分布")
    lines.append("")
    pri_map = {}
    for e in vips:
        pr = e.get("priority", "?")
        pri_map.setdefault(pr, [0, 0])
        if e.get("status") == "qualified":
            pri_map[pr][0] += 1
        else:
            pri_map[pr][1] += 1
    lines.append(_md_table(["优先级", "qualified", "其他", "合计"],
                           [[pr, str(q), str(o), str(q + o)] for pr, (q, o) in sorted(pri_map.items())]))
    lines.append("")

    # 按分类分章节明细：每个分类一个小节，列出每个 VIP 的状态/功能/质量
    lines.append("### VIP 明细（按分类）")
    lines.append("")
    groups = {}
    for e in vips:
        groups.setdefault(e.get("group", "(未分类)"), []).append(e)
    for group in sorted(groups):
        entries = sorted(groups[group], key=lambda e: e.get("id", ""))
        lines.append("#### %s（%d）" % (group, len(entries)))
        lines.append("")
        rows = []
        for e in entries:
            quality = e.get("quality") or {}
            maturity = quality.get("maturity", "-")
            qualif = quality.get("qualification", "-")
            rows.append([
                e.get("id", ""),
                _status_link(e),
                e.get("status", ""),
                e.get("profile", ""),
                e.get("priority", ""),
                "%s / %s" % (maturity, qualif),
                e.get("version", "-"),
                e.get("description", ""),
            ])
        lines.append(_md_table(["ID", "VIP", "状态", "Profile", "优先级", "质量(M/Qual)", "版本", "功能"], rows))
        lines.append("")
    return "\n".join(lines)


def build_catalog_doc(reg):
    """生成 vip_catalog.md 完整明细。"""
    vips = reg.get("vips", [])
    lines = ["# AIXSILICON VIP Catalog",
             "",
             "> 由 `tools/gen_catalog.py` 依据 `registry.yaml`（SSOT）自动生成；勿手工编辑。",
             "> 最后更新：`%s`" % reg.get("updated", "未知"),
             "",
             "完整 VIP 明细（%d 条），按类别分组。" % len(vips),
             ""]
    groups = {}
    for e in vips:
        groups.setdefault(e.get("group", "(未分类)"), []).append(e)
    for group in sorted(groups):
        entries = sorted(groups[group], key=lambda e: e.get("id", ""))
        lines.append("## %s（%d）" % (group, len(entries)))
        lines.append("")
        rows = []
        for e in entries:
            quality = e.get("quality") or {}
            maturity = quality.get("maturity", "-")
            qualif = quality.get("qualification", "-")
            rows.append([e.get("id", ""), _status_link(e), e.get("family", ""),
                         e.get("profile", ""), e.get("priority", ""),
                         e.get("hwif", "-"), e.get("status", ""),
                         "%s / %s" % (maturity, qualif),
                         e.get("version", "-"), e.get("description", "")])
        lines.append(_md_table(["ID", "VIP", "名称", "Profile", "优先级", "HWIF", "状态", "质量(M/Qual)", "版本", "描述"], rows))
        lines.append("")
    return "\n".join(lines)


def replace_between(text, begin, end, replacement):
    if begin not in text or end not in text:
        return None
    head = text.split(begin, 1)[0]
    tail = text.split(end, 1)[1]
    return head + begin + "\n" + replacement + "\n" + end + tail


def main(argv=None):
    ap = argparse.ArgumentParser(prog="gen_catalog.py", description="VIP Catalog / README 状态总览生成")
    ap.add_argument("--root", default=".", help="aixsilicon-vip-repo 根目录")
    ap.add_argument("--dry-run", action="store_true", help="仅打印将写入的区块，不写文件")
    ap.add_argument("--check", action="store_true", help="只读检查一致性（不写文件）")
    args = ap.parse_args(argv)

    root = os.path.abspath(args.root)
    registry_path = os.path.join(root, "registry.yaml")
    readme_path = os.path.join(root, "README.md")
    catalog_path = os.path.join(root, "vip_catalog.md")

    if not os.path.exists(registry_path):
        print("FAIL: 未找到 %s" % registry_path, file=sys.stderr)
        return 10

    try:
        reg = load_registry(registry_path)
    except Exception as e:  # noqa: BLE001
        print("FAIL: 加载 registry.yaml 失败: %s" % e, file=sys.stderr)
        return 10

    errors, warnings = validate(reg)
    for w in warnings:
        print("WARN: %s" % w)
    if errors:
        for err in errors:
            print("FAIL: %s" % err, file=sys.stderr)
        print("校验失败：%d 个错误" % len(errors), file=sys.stderr)
        return 10

    status_section = build_status_section(reg)
    catalog_doc = build_catalog_doc(reg)

    if not os.path.exists(readme_path):
        print("FAIL: 未找到 %s（README 缺少状态总览 marker）" % readme_path, file=sys.stderr)
        return 10
    with open(readme_path, encoding="utf-8") as f:
        readme_text = f.read()
    new_readme = replace_between(readme_text, BEGIN_MARKER, END_MARKER, status_section)
    if new_readme is None:
        print("FAIL: README.md 缺少 %s 与 %s marker" % (BEGIN_MARKER, END_MARKER), file=sys.stderr)
        return 10

    if args.check:
        outdated = new_readme != readme_text
        if outdated:
            print("FAIL: README.md 状态总览与 registry.yaml 不一致（请运行 gen_catalog.py 刷新）")
            return 1
        print("OK: README 与 registry 一致（%d 个 VIP）" % len(reg.get("vips", [])))
        return 0

    if args.dry_run:
        print("=== README 状态总览（待写入）===")
        print(status_section)
        print("=== vip_catalog.md（待写入）===")
        print(catalog_doc[:2000])
        print("...(dry-run 不写盘)")
        return 0

    with open(readme_path, "w", encoding="utf-8") as f:
        f.write(new_readme)
    with open(catalog_path, "w", encoding="utf-8") as f:
        f.write(catalog_doc)
    print("OK: 已刷新 README.md 状态总览与 vip_catalog.md（%d 个 VIP）" % len(reg.get("vips", [])))
    print("    %s" % readme_path)
    print("    %s" % catalog_path)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
