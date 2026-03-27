#!/usr/bin/env bash
# sync-template.sh
# Fires: PreToolUse on Bash (git push / git pull / new repo commands)
# Purpose:
#   - Before any git push: pull latest from claude-templates/main and merge
#     so every repo always has up-to-date base config before pushing.
#   - When creating a new repo: remind Claude to initialise from claude-templates.
#
# Configure in .claude/project.env:
#   TEMPLATE_REPO="git@github.com:shreyas-venkat/claude-templates.git"  # or HTTPS
#   SKIP_TEMPLATE_SYNC="true"  # set to skip for claude-templates itself

set -euo pipefail

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "unknown"')
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""')

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"

# Load project config
PROJECT_ENV="$PROJECT_DIR/.claude/project.env"
TEMPLATE_REPO="git@github.com:shreyas-venkat/claude-templates.git"
SKIP_SYNC="false"

if [[ -f "$PROJECT_ENV" ]]; then
  _REPO=$(grep '^TEMPLATE_REPO=' "$PROJECT_ENV" | cut -d'=' -f2- | tr -d '"' || echo "")
  _SKIP=$(grep '^SKIP_TEMPLATE_SYNC=' "$PROJECT_ENV" | cut -d'=' -f2- | tr -d '"' || echo "")
  [[ -n "$_REPO" ]] && TEMPLATE_REPO="$_REPO"
  [[ -n "$_SKIP" ]] && SKIP_SYNC="$_SKIP"
fi

# Skip sync for the template repo itself
if [[ "$SKIP_SYNC" == "true" ]]; then exit 0; fi

LOG_FILE="$PROJECT_DIR/.claude/logs/sync-template.log"
mkdir -p "$(dirname "$LOG_FILE")"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# ── Handle: git push ──────────────────────────────────────────────────────────
if echo "$COMMAND" | grep -qE '^git push'; then

  echo "[$TIMESTAMP] Pre-push: syncing from claude-templates..." >> "$LOG_FILE"

  # Check if claude-templates remote already exists
  REMOTES=$(git -C "$PROJECT_DIR" remote 2>/dev/null || echo "")

  if ! echo "$REMOTES" | grep -q "^claude-templates$"; then
    git -C "$PROJECT_DIR" remote add claude-templates "$TEMPLATE_REPO" >> "$LOG_FILE" 2>&1 || true
  fi

  # Fetch latest
  FETCH_OUTPUT=$(git -C "$PROJECT_DIR" fetch claude-templates main 2>&1)
  FETCH_EXIT=$?
  echo "$FETCH_OUTPUT" >> "$LOG_FILE"

  if [[ $FETCH_EXIT -ne 0 ]]; then
    # Fetch failed — warn but don't hard block (could be offline, CI, etc.)
    cat <<EOF
{
  "continue": true,
  "hookSpecificOutput": {
    "additionalContext": "WARNING: Could not fetch from claude-templates ($TEMPLATE_REPO). Proceeding without sync — check your remote config if this persists."
  }
}
EOF
    exit 0
  fi

  # Check if we're behind
  BEHIND=$(git -C "$PROJECT_DIR" rev-list HEAD..claude-templates/main --count 2>/dev/null || echo "0")

  if [[ "$BEHIND" -gt 0 ]]; then
    # Try to merge — non-destructive (no force)
    MERGE_OUTPUT=$(git -C "$PROJECT_DIR" merge claude-templates/main --no-edit --allow-unrelated-histories 2>&1 || echo "MERGE_FAILED")
    echo "$MERGE_OUTPUT" >> "$LOG_FILE"

    if echo "$MERGE_OUTPUT" | grep -q "MERGE_FAILED\|CONFLICT"; then
      cat <<EOF
{
  "decision": "block",
  "reason": "TEMPLATE SYNC REQUIRED: This repo is $BEHIND commit(s) behind claude-templates/main and a merge conflict was detected.\n\nResolve manually:\n  git fetch claude-templates main\n  git merge claude-templates/main\n  # fix conflicts\n  git add . && git commit\n\nThen retry the push."
}
EOF
      exit 1
    fi

    echo "[$TIMESTAMP] Merged $BEHIND commit(s) from claude-templates/main" >> "$LOG_FILE"
    cat <<EOF
{
  "continue": true,
  "hookSpecificOutput": {
    "additionalContext": "TEMPLATE SYNC: Merged $BEHIND update(s) from claude-templates/main before pushing. Commit the merge if needed, then push again."
  }
}
EOF
    exit 0
  fi

  echo "[$TIMESTAMP] Already up to date with claude-templates/main" >> "$LOG_FILE"
  exit 0
fi

# ── Handle: new repo creation hint ────────────────────────────────────────────
if echo "$COMMAND" | grep -qE '(gh repo create|git init)'; then
  cat <<EOF
{
  "continue": true,
  "hookSpecificOutput": {
    "additionalContext": "NEW REPO REMINDER: After creating this repo, initialise it from claude-templates before writing any code:\n  git remote add claude-templates $TEMPLATE_REPO\n  git fetch claude-templates main\n  git merge claude-templates/main --allow-unrelated-histories\nThis ensures the repo has the latest CLAUDE.md, GUARDRAILS.md, hooks, and settings."
  }
}
EOF
  exit 0
fi

exit 0
