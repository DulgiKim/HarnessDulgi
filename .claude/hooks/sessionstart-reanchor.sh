#!/usr/bin/env bash
# SessionStart 훅 — 압축·재시작 후 역할과 현황을 다시 주입한다.
#
# 압축을 거치면 에이전트는 자기가 어떤 역할인지부터 흐려진다.
# "작업 세션인데 머지를 시도하는" 상황을 막기 위한 재정박(re-anchor)이다.
#
# 출력은 세션 컨텍스트에 그대로 들어가므로 짧게 유지한다.
#
# settings.json 등록 예:
#   { "hooks": { "SessionStart": [{ "hooks": [
#       { "type": "command", "command": ".claude/hooks/sessionstart-reanchor.sh" } ] }] } }

set -uo pipefail

cd "$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0

echo "=== 세션 재정박 ==="
echo

# 1. 역할 — CLAUDE.md §0 머리만
if [ -f CLAUDE.md ]; then
  sed -n '/^## 0\./,/^## 1\./p' CLAUDE.md | sed '$d'
fi

# 2. 현재 위치
echo "## 현재 상태"
echo
echo "- 브랜치: $(git rev-parse --abbrev-ref HEAD)"
echo "- 최신 커밋: $(git log -1 --format='%h %s' 2>/dev/null)"

CHANGED="$(git status --porcelain | wc -l | tr -d ' ')"
echo "- 로컬 변경: ${CHANGED}건 (내 것이 아닌 변경이 섞여 있을 수 있음)"

# 3. 작업 일지 맨 위 블록 — 최신 재개 지점만
LOG="memory/session-log.md"
if [ -f "$LOG" ]; then
  echo
  echo "## 마지막 재개 블록"
  echo
  # 두 번째 '## ' 헤딩 직전까지만 출력한다.
  awk '/^## /{n++} n==1{print} n==2{exit}' "$LOG"
fi

echo
echo "전체 맥락은 memory/MEMORY.md 색인에서 필요한 것만 펼쳐 읽을 것."
exit 0
