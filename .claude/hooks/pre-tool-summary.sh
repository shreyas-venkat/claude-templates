#!/usr/bin/env bash
# pre-tool-summary.sh
# Fires: PreToolUse (all tools)
# Forces Claude to state what/why/expected result before every tool use.

set -euo pipefail

INPUT=$(cat)

# jq is preferred but not required — fall back to plain parsing
if command -v jq &>/dev/null; then
  TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "unknown"')
  TOOL_INPUT=$(echo "$INPUT" | jq -c '.tool_input // {}')
else
  TOOL_NAME=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_name','unknown'))" 2>/dev/null || echo "unknown")
  TOOL_INPUT="{}"
fi

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
LOG_DIR="$PROJECT_DIR/.claude/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/pre-tool.log"

# Cross-platform timestamp
TIMESTAMP=$(python3 -c "import datetime; print(datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))" 2>/dev/null || echo "unknown-time")

echo "[$TIMESTAMP] PRE-TOOL: $TOOL_NAME | input: $TOOL_INPUT" >> "$LOG_FILE"

printf '%s\n' '{
  "continue": true,
  "hookSpecificOutput": {
    "additionalContext": "BEFORE PROCEEDING: confirm you have stated (1) what you are doing, (2) why this action is needed, (3) expected result. If not stated yet, do so now."
  }
}'
