#!/usr/bin/env bash
# sync-template.sh
# Fires: PreToolUse on Bash
# Before git push: syncs from claude-templates/main.
# On git init / gh repo create: injects new-repo setup reminder.

set -euo pipefail

INPUT=$(cat)

if command -v jq &>/dev/null; then
  COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""')
else
  COMMAND=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('command',''))" 2>/dev/null || echo "")
fi

# Fast exit — only care about git push and repo creation commands
# Avoids running on every single Bash call
case "$COMMAND" in
  git\ push*|gh\ repo\ create*|git\ init*)
    ;;  # fall through to handle below
  *)
    exit 0
    ;;
esac

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
PROJECT_ENV="$PROJECT_DIR/.claude/project.env"

TEMPLATE_REPO="git@github.com:shreyas-venkat/claude-templates.git"
SKIP_SYNC="false"

if [[ -f "$PROJECT_ENV" ]]; then
  _REPO=$(grep '^TEMPLATE_REPO=' "$PROJECT_ENV" | cut -d'=' -f2- | tr -d '"' 2>/dev/null || echo "")
  _SKIP=$(grep '^SKIP_TEMPLATE_SYNC=' "$PROJECT_ENV" | cut -d'=' -f2- | tr -d '"' 2>/dev/null || echo "")
  [[ -n "$_REPO" ]] && TEMPLATE_REPO="$_REPO"
  [[ -n "$_SKIP" ]] && SKIP_SYNC="$_SKIP"
fi

if [[ "$SKIP_SYNC" == "true" ]]; then exit 0; fi

LOG_DIR="$PROJECT_DIR/.claude/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/sync-template.log"
TIMESTAMP=$(python3 -c "import datetime; print(datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))" 2>/dev/null || echo "unknown-time")

# ── git push: sync before allowing ───────────────────────────────────────────
case "$COMMAND" in
  git\ push*)
    echo "[$TIMESTAMP] Pre-push: syncing from claude-templates..." >> "$LOG_FILE"

    # Check if claude-templates remote already exists — portable check
    if ! git -C "$PROJECT_DIR" remote get-url claude-templates &>/dev/null; then
      git -C "$PROJECT_DIR" remote add claude-templates "$TEMPLATE_REPO" >> "$LOG_FILE" 2>&1 || true
    fi

    FETCH_OUTPUT=$(git -C "$PROJECT_DIR" fetch claude-templates main 2>&1)
    FETCH_EXIT=$?
    echo "$FETCH_OUTPUT" >> "$LOG_FILE"

    if [[ $FETCH_EXIT -ne 0 ]]; then
      # Fail open — warn but don't block if we can't reach the template repo
      printf '%s\n' '{
  "continue": true,
  "hookSpecificOutput": {
    "additionalContext": "WARNING: Could not fetch from claude-templates. Proceeding without sync — check your remote config."
  }
}'
      exit 0
    fi

    BEHIND=$(git -C "$PROJECT_DIR" rev-list HEAD..claude-templates/main --count 2>/dev/null || echo "0")

    if [[ "$BEHIND" -gt 0 ]]; then
      MERGE_OUTPUT=$(git -C "$PROJECT_DIR" merge claude-templates/main --no-edit --allow-unrelated-histories 2>&1 || echo "MERGE_FAILED")
      echo "$MERGE_OUTPUT" >> "$LOG_FILE"

      if echo "$MERGE_OUTPUT" | grep -qE 'MERGE_FAILED|CONFLICT'; then
        python3 -c "
import json, sys
reason = 'TEMPLATE SYNC: This repo is ' + sys.argv[1] + ' commit(s) behind claude-templates/main and has a merge conflict.\n\nResolve manually:\n  git fetch claude-templates main\n  git merge claude-templates/main\n  # fix conflicts\n  git add . && git commit\n\nThen retry the push.'
print(json.dumps({'decision': 'block', 'reason': reason}))
" "$BEHIND"
        exit 1
      fi

      printf '%s\n' "{
  \"continue\": true,
  \"hookSpecificOutput\": {
    \"additionalContext\": \"TEMPLATE SYNC: Merged $BEHIND update(s) from claude-templates/main. Commit the merge if needed, then push again.\"
  }
}"
      exit 0
    fi

    echo "[$TIMESTAMP] Already up to date with claude-templates/main" >> "$LOG_FILE"
    exit 0
    ;;

  # ── new repo: inject setup reminder ────────────────────────────────────────
  gh\ repo\ create*|git\ init*)
    python3 -c "
import json, sys
msg = 'NEW REPO REMINDER: After creating this repo, initialise from claude-templates before writing any code:\n  git remote add claude-templates ' + sys.argv[1] + '\n  git fetch claude-templates main\n  git merge claude-templates/main --allow-unrelated-histories\nThis brings in CLAUDE.md, GUARDRAILS.md, hooks, and settings.'
print(json.dumps({'continue': True, 'hookSpecificOutput': {'additionalContext': msg}}))
" "$TEMPLATE_REPO"
    exit 0
    ;;
esac

exit 0
