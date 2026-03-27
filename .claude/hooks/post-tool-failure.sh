#!/usr/bin/env bash
# post-tool-failure.sh
# Fires: PostToolUseFailure (any tool that errors)
# Blocks blind retries — forces Claude to diagnose before trying again.

set -euo pipefail

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "unknown"')
ERROR=$(echo "$INPUT" | jq -r '.tool_response.error // "unknown error"')

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
LOG_FILE="$PROJECT_DIR/.claude/logs/failures.log"
mkdir -p "$(dirname "$LOG_FILE")"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
echo "[$TIMESTAMP] TOOL FAILURE: $TOOL_NAME | $ERROR" >> "$LOG_FILE"

cat <<EOF
{
  "decision": "block",
  "reason": "TOOL FAILURE: '$TOOL_NAME' failed with: $ERROR\n\nBefore retrying: (1) explain why this failed, (2) state your revised approach, (3) confirm it differs from what you just tried."
}
EOF
exit 1
