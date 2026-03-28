#!/usr/bin/env bash
# block-main.sh — PreToolUse on Edit|MultiEdit|Write|Bash
set -euo pipefail
PY=$(command -v python3 2>/dev/null || command -v python 2>/dev/null || echo "python")

INPUT=$(cat)
if command -v jq &>/dev/null; then
  TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "unknown"')
  COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""')
else
  TOOL_NAME=$(echo "$INPUT" | $PY -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_name','unknown'))" 2>/dev/null || echo "unknown")
  COMMAND=$(echo "$INPUT" | $PY -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('command',''))" 2>/dev/null || echo "")
fi

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
CURRENT_BRANCH=$(git -C "$PROJECT_DIR" branch --show-current 2>/dev/null || echo "")
[[ -z "$CURRENT_BRANCH" ]] && exit 0

deny() {
  $PY -c "import json,sys; print(json.dumps({'hookSpecificOutput':{'permissionDecision':'deny','permissionDecisionReason':sys.argv[1]}}))" "$1" >&2
  exit 2
}

case "$TOOL_NAME" in
  Edit|MultiEdit|Write)
    [[ "$CURRENT_BRANCH" == "main" || "$CURRENT_BRANCH" == "master" ]] && \
      deny "BLOCKED: On main branch. Run: git checkout -b feat/your-feature-name"
    ;;
  Bash)
    echo "$COMMAND" | grep -qE 'git push.*(origin[[:space:]]+)?(main|master)' && \
      deny "BLOCKED: No direct push to main. Open a PR."
    echo "$COMMAND" | grep -qE 'git push.*(--force|-f)([[:space:]]|$)' && \
      deny "BLOCKED: Force push is never allowed."
    ;;
esac

exit 0
