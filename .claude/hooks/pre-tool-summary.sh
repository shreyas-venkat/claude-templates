#!/usr/bin/env bash
# pre-tool-summary.sh — PreToolUse on Bash|Edit|MultiEdit|Write|Task
set -euo pipefail
PY=$(command -v python3 2>/dev/null || command -v python 2>/dev/null || echo "python")

INPUT=$(cat)
if command -v jq &>/dev/null; then
  TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "unknown"')
  TOOL_INPUT=$(echo "$INPUT" | jq -c '.tool_input // {}')
else
  TOOL_NAME=$(echo "$INPUT" | $PY -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_name','unknown'))" 2>/dev/null || echo "unknown")
  TOOL_INPUT="{}"
fi

case "$TOOL_NAME" in
  Read|Glob|Grep|LS|TodoRead|WebSearch|WebFetch) exit 0 ;;
esac

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
mkdir -p "$PROJECT_DIR/.claude/logs"
TIMESTAMP=$($PY -c "import datetime; print(datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))" 2>/dev/null || echo "unknown-time")
echo "[$TIMESTAMP] PRE-TOOL: $TOOL_NAME" >> "$PROJECT_DIR/.claude/logs/pre-tool.log"

printf '%s\n' '{"continue": true, "hookSpecificOutput": {"additionalContext": "BEFORE PROCEEDING: confirm (1) what you are doing, (2) why, (3) expected result."}}'
