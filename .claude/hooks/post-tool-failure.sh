#!/usr/bin/env bash
# post-tool-failure.sh
# Fires: PostToolUseFailure on Bash|Edit|MultiEdit|Write|Task only
# Blocks blind retries — forces Claude to diagnose before trying again.
# Silent pass on read-only tool failures (Read, Glob, Grep etc).

set -euo pipefail

INPUT=$(cat)

if command -v jq &>/dev/null; then
  TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "unknown"')
  ERROR=$(echo "$INPUT" | jq -r '.tool_response.error // "unknown error"')
else
  TOOL_NAME=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_name','unknown'))" 2>/dev/null || echo "unknown")
  ERROR=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_response',{}).get('error','unknown error'))" 2>/dev/null || echo "unknown error")
fi

# Silent pass for read-only tool failures — not worth blocking on
case "$TOOL_NAME" in
  Read|Glob|Grep|LS|TodoRead|WebSearch|WebFetch)
    exit 0
    ;;
esac

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
LOG_DIR="$PROJECT_DIR/.claude/logs"
mkdir -p "$LOG_DIR"
TIMESTAMP=$(python3 -c "import datetime; print(datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))" 2>/dev/null || echo "unknown-time")
echo "[$TIMESTAMP] TOOL FAILURE: $TOOL_NAME | $ERROR" >> "$LOG_DIR/failures.log"

python3 -c "
import json, sys
reason = \"TOOL FAILURE: '\" + sys.argv[1] + \"' failed with: \" + sys.argv[2] + \"\n\nBefore retrying: (1) explain why this failed, (2) state your revised approach, (3) confirm it differs from what you just tried.\"
print(json.dumps({'decision': 'block', 'reason': reason}))
" "$TOOL_NAME" "$ERROR"
exit 1
