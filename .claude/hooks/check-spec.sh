#!/usr/bin/env bash
# check-spec.sh
# Fires: PreToolUse on Edit|MultiEdit|Write
# Blocks all file writes unless SPEC.md exists and has Goal + numbered plan filled out.

set -euo pipefail

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
SPEC_FILE="$PROJECT_DIR/SPEC.md"

# Allow edits to SPEC.md itself and hook/config files
if [[ "$FILE_PATH" == *"SPEC.md"* ]]; then exit 0; fi
if [[ "$FILE_PATH" == *".claude/"* ]]; then exit 0; fi

if [[ ! -f "$SPEC_FILE" ]]; then
  echo '{
    "hookSpecificOutput": {
      "permissionDecision": "deny",
      "permissionDecisionReason": "BLOCKED: No SPEC.md found. Create SPEC.md and fill out Goal, Implementation Plan, and Tests Required before writing any code."
    }
  }' >&2
  exit 2
fi

# Check it has been filled out (not just the blank template)
GOAL_LINE=$(grep -A2 "^## Goal" "$SPEC_FILE" | tail -1 | tr -d '[:space:]')
PLAN_CHECK=$(grep -c "^[0-9]\+\." "$SPEC_FILE" 2>/dev/null || echo "0")

if [[ -z "$GOAL_LINE" || "$GOAL_LINE" == "<!--"* || "$PLAN_CHECK" -eq 0 ]]; then
  echo '{
    "hookSpecificOutput": {
      "permissionDecision": "deny",
      "permissionDecisionReason": "BLOCKED: SPEC.md exists but is unfilled. Complete the Goal, Implementation Plan, and Tests Required sections first."
    }
  }' >&2
  exit 2
fi

exit 0
