#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 AIXSILICON
#
# generate_vip.py — 基于 protocol/apb/ 模板生成新 VIP 骨架。
# 复制模板并全局重命名 apb_* → <vip>_*，重写 VLNV 与 metadata。
"""Usage:
    python3 generate_vip.py --name uart --dest peripheral/uart
        [--vlnv aix:vip:uart:1.0.0]
        [--family UART]
"""
import argparse
import os
import re
import shutil
import sys

TEMPLATE = os.path.join("protocol", "apb")


def _rewrite_text(text, name):
    # 全局重命名 apb_* / APB 标识符
    text = re.sub(r"\bapb_", name + "_", text)
    text = re.sub(r"\bAPB\b", name.upper(), text)
    text = re.sub(r"\bApb\b", name.capitalize(), text)
    return text


def main(argv):
    ap = argparse.ArgumentParser()
    ap.add_argument("--name", required=True, help="VIP 短名，如 uart")
    ap.add_argument("--dest", required=True, help="目标目录，如 peripheral/uart")
    ap.add_argument("--vlnv", default=None, help="VLNV，如 aix:vip:uart:1.0.0")
    ap.add_argument("--family", default=None, help="协议族，如 UART")
    args = ap.parse_args(argv)

    name = args.name
    if not re.match(r"^[a-z][a-z0-9_]*$", name):
        print("ERROR: name 必须为小写字母/数字/下划线")
        return 2

    dest = args.dest
    if os.path.exists(dest):
        print("ERROR: 目标目录已存在: %s" % dest)
        return 2

    if not os.path.isdir(TEMPLATE):
        print("ERROR: 模板目录不存在: %s" % TEMPLATE)
        return 2

    vlnv = args.vlnv or "aix:vip:%s:1.0.0" % name
    family = args.family or name.upper()

    # 拷贝模板
    shutil.copytree(TEMPLATE, dest)

    # 重命名文件与内容
    for root, _dirs, files in os.walk(dest):
        for fn in files:
            old = os.path.join(root, fn)
            newfn = fn.replace("apb", name).replace("APB", name.upper())
            new = os.path.join(root, newfn)
            if old != new:
                os.rename(old, new)
            if new.endswith((".sv", ".md", ".core", ".yaml")):
                with open(new, "r") as f:
                    text = f.read()
                text = _rewrite_text(text, name)
                text = text.replace("aix:vip:apb:1.0.0", vlnv)
                text = text.replace("aix_vip_apb_1.0.0", "aix_vip_%s_1.0.0" % name)
                text = text.replace("AMBA APB", family)
                with open(new, "w") as f:
                    f.write(text)

    print("OK: 已从 %s 生成 VIP 骨架 -> %s" % (TEMPLATE, dest))
    print("    VLNV: %s" % vlnv)
    print("    下一步：完善 docs/ 与 src/ 内容，并运行 metadata_check / testplan_check")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
