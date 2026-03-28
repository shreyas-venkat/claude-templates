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

# Allow edits to SPEC.md itself and hook/config files — silent pass
case "$FILE_PATH" in
  *SPEC.md*|*.claude/*|*GUARDRAILS.md*|*CLAUDE.md*) exit 0 ;;
esac

deny() {
  python3 -c "
import json, sys
print(json.dumps({
  'hookSpecificOutput': {
    'permissionDecision': 'deny',
    'permissionDecisionReason': sys.argv[1]
  }
}))
" "$1" >&2
  exit 2
}

if [[ ! -f "$SPEC_FILE" ]]; then
  deny "BLOCKED: No SPEC.md found. Run /meta/spec to create one before writing any code."
fi

# Use a temp file to avoid heredoc + argv issues
PYCHECK=$(mktemp /tmp/checkspec_XXXXXX.py)
cat > "$PYCHECK" << 'PYEOF'
import sys

with open(sys.argv[1]) as f:
    content = f.read()

lines = content.split('\n')

# Check Goal section has real content
in_goal = False
goal_filled = False
for line in lines:
    if line.startswith('## Goal'):
        in_goal = True
        continue
    if in_goal and line.startswith('##'):
        break
    if in_goal and line.strip() and not line.strip().startswith('<!--'):
        goal_filled = True
        break

# Check numbered plan exists
import re
plan_lines = [l for l in lines if re.match(r'^\s*[0-9]+\.', l)]

if not goal_filled:
    print("no_goal")
elif len(plan_lines) == 0:
    print("no_plan")
else:
    print("ok")
PYEOF

RESULT=$(python3 "$PYCHECK" "$SPEC_FILE" 2>/dev/null || echo "error")
rm -f "$PYCHECK"

case "$RESULT" in
  ok) exit 0 ;;
  no_goal) deny "BLOCKED: SPEC.md Goal section is empty. Fill it in before writing any code." ;;
  no_plan) deny "BLOCKED: SPEC.md has no numbered Implementation Plan. Add steps before writing any code." ;;
  *) exit 0 ;;  # On error, fail open — don't block Claude on a hook bug
esac
