#!/usr/bin/env bash
# PreCompact 훅 — 컨텍스트 압축 직전에 작업 트리를 스냅샷 브랜치에 저장한다.
#
# 압축 과정에서 무언가 꼬여도 작업 중이던 변경을 잃지 않기 위한 안전망이다.
# 되돌릴 일이 없으면 스냅샷은 그대로 버려진다.
#
# settings.json 등록 예:
#   { "hooks": { "PreCompact": [{ "hooks": [
#       { "type": "command", "command": ".claude/hooks/precompact-snapshot.sh" } ] }] } }

set -uo pipefail

SNAPSHOT_BRANCH="${SNAPSHOT_BRANCH:-wip-snapshot}"

cd "$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0

# 변경이 없으면 할 일이 없다.
if git diff --quiet && git diff --cached --quiet; then
  exit 0
fi

CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
STAMP="$(date +%Y%m%d-%H%M%S)"

# 작업 트리를 건드리지 않고 스냅샷만 만든다.
# stash 를 쓰면 사용자의 작업 상태가 바뀌므로 commit-tree 로 직접 만든다.
TREE="$(git stash create 2>/dev/null)"
[ -z "$TREE" ] && exit 0

COMMIT="$(git commit-tree "$TREE^{tree}" -p HEAD \
  -m "snapshot: ${CURRENT_BRANCH} @ ${STAMP} (pre-compact)")"

git update-ref "refs/heads/${SNAPSHOT_BRANCH}" "$COMMIT"

echo "[precompact] 스냅샷 저장: ${SNAPSHOT_BRANCH} <- ${COMMIT:0:8} (${CURRENT_BRANCH})"
exit 0
