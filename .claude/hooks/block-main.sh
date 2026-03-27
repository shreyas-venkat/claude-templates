#!/usr/bin/env bash
# block-main.sh
# Fires: PreToolUse on Edit|MultiEdit|Write|Bash
# Hard blocks file edits on main branch, git push to main, and force pushes.

set -euo pipefail

INPUT=$(cat)

if command -v jq &>/dev/null; then
  TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "unknown"')
  COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""')
else
  TOOL_NAME=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_name','unknown'))" 2>/dev/null || echo "unknown")
  COMMAND=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('command',''))" 2>/dev/null || echo "")
fi

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
CURRENT_BRANCH=$(git -C "$PROJECT_DIR" branch --show-current 2>/dev/null || echo "")

if [[ -z "$CURRENT_BRANCH" ]]; then exit 0; fi

deny() {
  printf '%s\n' "{
    \"hookSpecificOutput\": {
      \"permissionDecision\": \"deny\",
      \"permissionDecisionReason\": \"$1\"
    }
  }" >&2
  exit 2
}

# Block file edits directly on main/master
case "$TOOL_NAME" in
  Edit|MultiEdit|Write)
    if [[ "$CURRENT_BRANCH" == "main" || "$CURRENT_BRANCH" == "master" ]]; then
      deny "BLOCKED: On main branch. Never edit files directly on main. Create a feature branch first: git checkout -b feat/your-feature-name"
    fi
    ;;
  Bash)
    # Block push to main/master
    if echo "$COMMAND" | grep -qE 'git push.*(origin[[:space:]]+)?(main|master)'; then
      deny "BLOCKED: Direct push to main is not allowed. Open a pull request instead."
    fi
    # Block force push
    if echo "$COMMAND" | grep -qE 'git push.*(--force|-f)([[:space:]]|$)'; then
      deny "BLOCKED: Force push is never allowed. No exceptions."
    fi
    ;;
esac

exit 0
