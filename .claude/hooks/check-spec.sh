#!/usr/bin/env bash
# check-spec.sh
# Fires: PreToolUse on Edit|MultiEdit|Write
# Blocks all file writes unless SPEC.md exists and has Goal + numbered plan filled out.

set -euo pipefail

INPUT=$(cat)

if command -v jq &>/dev/null; then
  FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')
else
  FILE_PATH=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('file_path',''))" 2>/dev/null || echo "")
fi

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
SPEC_FILE="$PROJECT_DIR/SPEC.md"

# Allow edits to SPEC.md itself and hook/config files
case "$FILE_PATH" in
  *SPEC.md*|*.claude/*) exit 0 ;;
esac

deny() {
  printf '%s\n' "{
    \"hookSpecificOutput\": {
      \"permissionDecision\": \"deny\",
      \"permissionDecisionReason\": \"$1\"
    }
  }" >&2
  exit 2
}

if [[ ! -f "$SPEC_FILE" ]]; then
  deny "BLOCKED: No SPEC.md found. Create SPEC.md and fill out Goal, Implementation Plan, and Tests Required before writing any code."
fi

# Check Goal is filled (not just the comment placeholder)
GOAL_FILLED=$(python3 - <<'PYEOF'
import sys
with open(sys.argv[1]) as f:
    content = f.read()
lines = content.split('\n')
in_goal = False
for line in lines:
    if line.startswith('## Goal'):
        in_goal = True
        continue
    if in_goal and line.startswith('##'):
        break
    if in_goal and line.strip() and not line.strip().startswith('<!--'):
        print("filled")
        sys.exit(0)
print("empty")
PYEOF
"$SPEC_FILE")

# Check numbered plan exists (1. 2. etc)
PLAN_CHECK=$(grep -c "^[[:space:]]*[0-9][0-9]*\." "$SPEC_FILE" 2>/dev/null || echo "0")

if [[ "$GOAL_FILLED" != "filled" || "$PLAN_CHECK" -eq 0 ]]; then
  deny "BLOCKED: SPEC.md exists but is unfilled. Complete the Goal, Implementation Plan, and Tests Required sections first."
fi

exit 0
