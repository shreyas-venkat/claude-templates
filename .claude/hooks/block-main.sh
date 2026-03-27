#!/usr/bin/env bash
# block-main.sh
# Fires: PreToolUse on Edit|MultiEdit|Write|Bash
# Hard blocks file edits on main branch, git push to main, and force pushes.

set -euo pipefail

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "unknown"')
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
CURRENT_BRANCH=$(git -C "$PROJECT_DIR" branch --show-current 2>/dev/null || echo "")

if [[ -z "$CURRENT_BRANCH" ]]; then exit 0; fi

if [[ "$TOOL_NAME" =~ ^(Edit|MultiEdit|Write)$ ]]; then
  if [[ "$CURRENT_BRANCH" == "main" || "$CURRENT_BRANCH" == "master" ]]; then
    echo '{
      "hookSpecificOutput": {
        "permissionDecision": "deny",
        "permissionDecisionReason": "BLOCKED: On main branch. Never edit files directly on main. Create a feature branch first: git checkout -b feat/your-feature-name"
      }
    }' >&2
    exit 2
  fi
fi

if [[ "$TOOL_NAME" == "Bash" ]]; then
  COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""')

  if echo "$COMMAND" | grep -qE 'git push.*(origin\s+)?(main|master)'; then
    echo '{
      "hookSpecificOutput": {
        "permissionDecision": "deny",
        "permissionDecisionReason": "BLOCKED: Direct push to main is not allowed. Open a pull request instead."
      }
    }' >&2
    exit 2
  fi

  if echo "$COMMAND" | grep -qE 'git push.*(--force|-f)'; then
    echo '{
      "hookSpecificOutput": {
        "permissionDecision": "deny",
        "permissionDecisionReason": "BLOCKED: Force push is never allowed. No exceptions."
      }
    }' >&2
    exit 2
  fi
fi

exit 0
