#!/usr/bin/env bash
# =============================================================================
# pre-commit-registry-readme.sh
#
# 目的：确保 registry.yaml（SSOT）与 README.md 状态总览始终一致。
# 当 registry.yaml 发生变更（VIP 列表/状态/质量变化）时，自动运行
#   tools/gen_catalog.py 刷新 README.md 的「当前已准入 VIP」状态总览，
# 并将刷新后的 README.md 纳入本次提交，避免"改了 registry 忘了刷 README"。
#
# 安装为 git pre-commit hook（可选，团队共享）：
#   ln -sf ../../scripts/pre-commit-registry-readme.sh .git/hooks/pre-commit
#   chmod +x scripts/pre-commit-registry-readme.sh
#
# 也可在提交前手动运行：
#   ./scripts/pre-commit-registry-readme.sh --check-only
# =============================================================================
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

GEN_CATALOG="uv run python tools/gen_catalog.py"
MODE="${1:-}"

# 仅当 registry.yaml 在暂存区/工作区有变更时才刷新
has_registry_change() {
  git diff --cached --name-only -- registry.yaml | grep -q registry.yaml || \
    git diff --name-only -- registry.yaml | grep -q registry.yaml
}

if ! has_registry_change; then
  echo "pre-commit: registry.yaml 无变更，跳过 README 刷新"
  exit 0
fi

echo "pre-commit: registry.yaml 有变更，刷新 README 状态总览..."
if ! command -v uv >/dev/null 2>&1; then
  echo "ERROR: pre-commit 需要 uv（运行 gen_catalog.py）" >&2
  exit 1
fi

# 刷新并校验
if ! $GEN_CATALOG --root .; then
  echo "ERROR: gen_catalog 刷新失败（registry.yaml 可能不合法）" >&2
  exit 1
fi

if ! $GEN_CATALOG --root . --check; then
  echo "ERROR: README 状态总览与 registry.yaml 仍不一致" >&2
  exit 1
fi

# 将刷新后的 README 纳入暂存区，保证提交内容一致
git add README.md
echo "pre-commit: README.md 已刷新并暂存"
exit 0
