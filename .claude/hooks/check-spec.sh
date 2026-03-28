#!/usr/bin/env bash
# check-spec.sh — PreToolUse on Edit|MultiEdit|Write
set -euo pipefail
PY=$(command -v python3 2>/dev/null || command -v python 2>/dev/null || echo "python")

INPUT=$(cat)
if command -v jq &>/dev/null; then
  FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')
else
  FILE_PATH=$(echo "$INPUT" | $PY -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('file_path',''))" 2>/dev/null || echo "")
fi

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
SPEC_FILE="$PROJECT_DIR/SPEC.md"

case "$FILE_PATH" in
  *SPEC.md*|*.claude/*|*GUARDRAILS.md*|*CLAUDE.md*|*BUILD.md*) exit 0 ;;
esac

deny() {
  $PY -c "import json,sys; print(json.dumps({'hookSpecificOutput':{'permissionDecision':'deny','permissionDecisionReason':sys.argv[1]}}))" "$1" >&2
  exit 2
}

[[ ! -f "$SPEC_FILE" ]] && deny "BLOCKED: No SPEC.md found. Run /meta/spec first."

PYCHECK=$(mktemp)
cat > "$PYCHECK" << 'PYEOF'
import sys, re
with open(sys.argv[1]) as f:
    lines = f.read().split('\n')
in_goal = False
goal_filled = False
for line in lines:
    if line.startswith('## Goal'): in_goal = True; continue
    if in_goal and line.startswith('##'): break
    if in_goal and line.strip() and not line.strip().startswith('<!--'): goal_filled = True; break
plan = [l for l in lines if re.match(r'^\s*[0-9]+\.', l)]
if not goal_filled: print("no_goal")
elif not plan: print("no_plan")
else: print("ok")
PYEOF

RESULT=$($PY "$PYCHECK" "$SPEC_FILE" 2>/dev/null || echo "error")
rm -f "$PYCHECK"

case "$RESULT" in
  ok) exit 0 ;;
  no_goal) deny "BLOCKED: SPEC.md Goal is empty. Fill it in first." ;;
  no_plan) deny "BLOCKED: SPEC.md has no Implementation Plan. Add numbered steps first." ;;
  *) exit 0 ;;
esac
