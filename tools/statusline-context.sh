#!/usr/bin/env bash
# 상태줄 — 컨텍스트 사용률과 현재 브랜치를 표시한다.
#
# 임계치를 넘으면 신호 파일을 남긴다. 별도 감시 스크립트가 이 파일을 보고
# 압축을 유도하거나 사람에게 알린다. 모델 토큰을 쓰지 않는다.
#
# settings.json 등록 예:
#   { "statusLine": { "type": "command", "command": "tools/statusline-context.sh" } }
#
# 입력은 stdin 으로 들어오는 세션 JSON이다.

set -uo pipefail

THRESHOLD="${CONTEXT_THRESHOLD:-80}"
SIGNAL_FILE="${CONTEXT_SIGNAL_FILE:-/tmp/claude-context-high}"

INPUT="$(cat)"

# jq 없이 동작하도록 최소 파싱만 한다.
extract() { echo "$INPUT" | sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\([0-9]*\).*/\1/p" | head -1; }

USED="$(extract 'used_tokens')"
LIMIT="$(extract 'context_limit')"

BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo '-')"

if [ -n "$USED" ] && [ -n "$LIMIT" ] && [ "$LIMIT" -gt 0 ]; then
  PCT=$(( USED * 100 / LIMIT ))

  if [ "$PCT" -ge "$THRESHOLD" ]; then
    MARK="!"
    date -u +%Y-%m-%dT%H:%M:%SZ > "$SIGNAL_FILE"
  else
    MARK=""
    [ -f "$SIGNAL_FILE" ] && rm -f "$SIGNAL_FILE"
  fi

  printf '%s | ctx %d%%%s' "$BRANCH" "$PCT" "$MARK"
else
  printf '%s' "$BRANCH"
fi
