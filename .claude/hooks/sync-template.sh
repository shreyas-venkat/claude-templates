#!/usr/bin/env bash
# sync-template.sh — PreToolUse on Bash (git push / repo creation only)
set -euo pipefail
PY=$(command -v python3 2>/dev/null || command -v python 2>/dev/null || echo "python")

INPUT=$(cat)
if command -v jq &>/dev/null; then
  COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""')
else
  COMMAND=$(echo "$INPUT" | $PY -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('command',''))" 2>/dev/null || echo "")
fi

case "$COMMAND" in
  git\ push*|gh\ repo\ create*|git\ init*) ;;
  *) exit 0 ;;
esac

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
PROJECT_ENV="$PROJECT_DIR/.claude/project.env"
TEMPLATE_REPO="git@github.com:shreyas-venkat/claude-templates.git"
SKIP_SYNC="false"

if [[ -f "$PROJECT_ENV" ]]; then
  _R=$(grep '^TEMPLATE_REPO=' "$PROJECT_ENV" | cut -d'=' -f2- | tr -d '"' 2>/dev/null || echo "")
  _S=$(grep '^SKIP_TEMPLATE_SYNC=' "$PROJECT_ENV" | cut -d'=' -f2- | tr -d '"' 2>/dev/null || echo "")
  [[ -n "$_R" ]] && TEMPLATE_REPO="$_R"
  [[ -n "$_S" ]] && SKIP_SYNC="$_S"
fi

[[ "$SKIP_SYNC" == "true" ]] && exit 0

mkdir -p "$PROJECT_DIR/.claude/logs"
LOG="$PROJECT_DIR/.claude/logs/sync-template.log"
TS=$($PY -c "import datetime; print(datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))" 2>/dev/null || echo "now")

case "$COMMAND" in
  git\ push*)
    echo "[$TS] Pre-push sync..." >> "$LOG"
    git -C "$PROJECT_DIR" remote get-url claude-templates &>/dev/null || \
      git -C "$PROJECT_DIR" remote add claude-templates "$TEMPLATE_REPO" >> "$LOG" 2>&1 || true

    if ! git -C "$PROJECT_DIR" fetch claude-templates main >> "$LOG" 2>&1; then
      printf '%s\n' '{"continue":true,"hookSpecificOutput":{"additionalContext":"WARNING: Could not sync from claude-templates. Proceeding anyway."}}'
      exit 0
    fi

    BEHIND=$(git -C "$PROJECT_DIR" rev-list HEAD..claude-templates/main --count 2>/dev/null || echo "0")
    if [[ "$BEHIND" -gt 0 ]]; then
      MERGE=$(git -C "$PROJECT_DIR" merge claude-templates/main --no-edit --allow-unrelated-histories 2>&1 || echo "MERGE_FAILED")
      echo "$MERGE" >> "$LOG"
      if echo "$MERGE" | grep -qE 'MERGE_FAILED|CONFLICT'; then
        $PY -c "import json,sys; print(json.dumps({'decision':'block','reason':'TEMPLATE SYNC CONFLICT: '+sys.argv[1]+' commits behind. Resolve manually then retry push.'}))" "$BEHIND"
        exit 1
      fi
      printf '%s\n' "{\"continue\":true,\"hookSpecificOutput\":{\"additionalContext\":\"TEMPLATE SYNC: Merged $BEHIND update(s). Commit if needed then push again.\"}}"
      exit 0
    fi
    echo "[$TS] Up to date" >> "$LOG"
    exit 0
    ;;

  gh\ repo\ create*|git\ init*)
    $PY -c "
import json,sys
msg='NEW REPO: After creating, initialise from claude-templates:\n  git remote add claude-templates '+sys.argv[1]+'\n  git fetch claude-templates main\n  git merge claude-templates/main --allow-unrelated-histories'
print(json.dumps({'continue':True,'hookSpecificOutput':{'additionalContext':msg}}))
" "$TEMPLATE_REPO"
    exit 0
    ;;
esac

exit 0
