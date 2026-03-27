#!/usr/bin/env bash
# pre-tool-summary.sh
# Fires: PreToolUse (all tools)
# Forces Claude to state what/why/expected result before every tool use.
# Creates a breadcrumb log and slows down impulsive actions.

set -euo pipefail

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "unknown"')
TOOL_INPUT=$(echo "$INPUT" | jq -c '.tool_input // {}')

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
LOG_FILE="${CLAUDE_PROJECT_DIR:-$(pwd)}/.claude/logs/pre-tool.log"
mkdir -p "$(dirname "$LOG_FILE")"
echo "[$TIMESTAMP] PRE-TOOL: $TOOL_NAME | input: $TOOL_INPUT" >> "$LOG_FILE"

cat <<EOF
{
  "continue": true,
  "hookSpecificOutput": {
    "additionalContext": "BEFORE PROCEEDING with '$TOOL_NAME': confirm you have stated (1) what you are doing, (2) why this action is needed, (3) expected result. If not stated yet, do so now."
  }
}
EOF
