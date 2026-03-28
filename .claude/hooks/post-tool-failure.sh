#!/usr/bin/env bash
# post-tool-failure.sh — PostToolUseFailure on Bash|Edit|MultiEdit|Write
set -euo pipefail
PY=$(command -v python3 2>/dev/null || command -v python 2>/dev/null || echo "python")

INPUT=$(cat)
if command -v jq &>/dev/null; then
  TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "unknown"')
  ERROR=$(echo "$INPUT" | jq -r '.tool_response.error // "unknown error"')
else
  TOOL_NAME=$(echo "$INPUT" | $PY -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_name','unknown'))" 2>/dev/null || echo "unknown")
  ERROR=$(echo "$INPUT" | $PY -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_response',{}).get('error','unknown error'))" 2>/dev/null || echo "unknown error")
fi

case "$TOOL_NAME" in
  Read|Glob|Grep|LS|TodoRead|WebSearch|WebFetch) exit 0 ;;
esac

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
mkdir -p "$PROJECT_DIR/.claude/logs"
TS=$($PY -c "import datetime; print(datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))" 2>/dev/null || echo "now")
echo "[$TS] FAILURE: $TOOL_NAME | $ERROR" >> "$PROJECT_DIR/.claude/logs/failures.log"

$PY -c "
import json,sys
print(json.dumps({'decision':'block','reason':\"TOOL FAILURE: '\"+sys.argv[1]+\"' failed: \"+sys.argv[2]+\"\n\nBefore retrying: (1) why did this fail, (2) revised approach, (3) confirm it's different.\"}))
" "$TOOL_NAME" "$ERROR"
exit 1
