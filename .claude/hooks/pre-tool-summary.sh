#!/usr/bin/env bash
# pre-tool-summary.sh
# Fires: PreToolUse on write/execute tools only
# Forces Claude to state what/why/expected result before acting.
# Silent pass on read-only tools — no errors, no noise.

set -euo pipefail

INPUT=$(cat)

if command -v jq &>/dev/null; then
  TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "unknown"')
  TOOL_INPUT=$(echo "$INPUT" | jq -c '.tool_input // {}')
else
  TOOL_NAME=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_name','unknown'))" 2>/dev/null || echo "unknown")
  TOOL_INPUT="{}"
fi

# Silent pass for read-only tools — no summary needed, no noise
case "$TOOL_NAME" in
  Read|Glob|Grep|LS|TodoRead|WebSearch|WebFetch)
    exit 0
    ;;
esac

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
LOG_DIR="$PROJECT_DIR/.claude/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/pre-tool.log"

TIMESTAMP=$(python3 -c "import datetime; print(datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))" 2>/dev/null || echo "unknown-time")
echo "[$TIMESTAMP] PRE-TOOL: $TOOL_NAME | input: $TOOL_INPUT" >> "$LOG_FILE"

printf '%s\n' '{
  "continue": true,
  "hookSpecificOutput": {
    "additionalContext": "BEFORE PROCEEDING: confirm you have stated (1) what you are doing, (2) why this action is needed, (3) expected result. If not stated yet, do so now."
  }
}'
