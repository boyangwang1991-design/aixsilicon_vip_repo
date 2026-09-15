"""隔离重跑的输出路径约束。"""
import os
from pathlib import Path

def run_root():
    value = os.environ.get("AHB_RUN_ROOT") or str(Path(os.environ["LOG_DIR"]).absolute().parent)
    path = Path(value).absolute()
    if "build" not in path.parts or ".." in path.parts or any(p.is_symlink() for p in (path,*path.parents)):
        raise ValueError("运行根必须位于 build 且不能经过符号链接")
    for child in ("logs", "evidence/raw", "work/build"):
        (path/child).mkdir(parents=True,exist_ok=True)
    return path
