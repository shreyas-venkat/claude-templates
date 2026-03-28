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

# Allow edits to SPEC.md itself, config files, and template files
case "$FILE_PATH" in
  *SPEC.md*|*.claude/*|*CLAUDE.md*|*GUARDRAILS.md*) exit 0 ;;
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
  deny "BLOCKED: No SPEC.md found. Run /meta/spec to create one before writing any code."
fi

# Inline python3 heredoc — reliable cross-platform, no temp file needed
RESULT=$(python3 - "$SPEC_FILE" << 'PYEOF'
import sys, re

try:
    with open(sys.argv[1], encoding='utf-8') as f:
        content = f.read()
except Exception:
    print("ok")  # can't read file — don't block
    sys.exit(0)

lines = content.split('\n')
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

plan_filled = bool(re.search(r'^\s*[0-9]+\.', content, re.MULTILINE))
print("ok" if (goal_filled and plan_filled) else "empty")
PYEOF
)

if [[ "$RESULT" != "ok" ]]; then
  deny "BLOCKED: SPEC.md Goal and/or Implementation Plan are not filled out. Complete them or run /meta/spec."
fi

exit 0
