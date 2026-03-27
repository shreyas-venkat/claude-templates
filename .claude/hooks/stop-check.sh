#!/usr/bin/env bash
# stop-check.sh
# Fires: Stop (when Claude thinks it's finished)
# Final gate: test suite must pass, no debug markers, every source file needs a test.
# Configure test command in .claude/project.env: TEST_CMD="pytest tests/ -v"

set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
LOG_FILE="$PROJECT_DIR/.claude/logs/stop-check.log"
mkdir -p "$(dirname "$LOG_FILE")"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
echo "[$TIMESTAMP] Stop hook fired" >> "$LOG_FILE"

FAILURES=()

# Load project-specific config
PROJECT_ENV="$PROJECT_DIR/.claude/project.env"
TEST_CMD=""
if [[ -f "$PROJECT_ENV" ]]; then
  TEST_CMD=$(grep '^TEST_CMD=' "$PROJECT_ENV" | cut -d'=' -f2- | tr -d '"' || echo "")
fi

# Auto-detect test command
if [[ -z "$TEST_CMD" ]]; then
  if [[ -f "$PROJECT_DIR/pyproject.toml" ]] || [[ -f "$PROJECT_DIR/setup.py" ]]; then
    TEST_CMD="python -m pytest tests/ -v"
  elif [[ -f "$PROJECT_DIR/package.json" ]]; then
    TEST_CMD="npm test"
  elif [[ -f "$PROJECT_DIR/go.mod" ]]; then
    TEST_CMD="go test ./..."
  elif [[ -f "$PROJECT_DIR/Cargo.toml" ]]; then
    TEST_CMD="cargo test"
  fi
fi

# 1. Run full test suite
if [[ -n "$TEST_CMD" ]]; then
  cd "$PROJECT_DIR"
  TEST_OUTPUT=$(eval "$TEST_CMD" 2>&1)
  if [[ $? -ne 0 ]]; then
    FAILURES+=("TEST SUITE FAILED:\n$(echo "$TEST_OUTPUT" | tail -30)")
  fi
else
  FAILURES+=("No test runner configured. Set TEST_CMD in .claude/project.env.")
fi

# 2. Check for debug/todo markers in modified files
MODIFIED=$(git -C "$PROJECT_DIR" diff --name-only HEAD 2>/dev/null || echo "")
if [[ -n "$MODIFIED" ]]; then
  DEBUG_HITS=$(echo "$MODIFIED" | xargs grep -lnE '(console\.log|print\(|debugger|TODO|FIXME|HACK|XXX)' 2>/dev/null || true)
  if [[ -n "$DEBUG_HITS" ]]; then
    FAILURES+=("DEBUG/TODO MARKERS in: $DEBUG_HITS — clean up before finishing.")
  fi
fi

# 3. Check test files exist for every new source file
NEW_SRC=$(git -C "$PROJECT_DIR" diff --name-only HEAD 2>/dev/null | grep -vE '(test|spec|\.md|\.json|\.sh|\.yaml|\.toml|\.env)' || true)
for SRC in $NEW_SRC; do
  BASENAME=$(basename "$SRC" | sed 's/\.[^.]*$//')
  TEST_EXISTS=$(find "$PROJECT_DIR" -name "*${BASENAME}*test*" -o -name "*${BASENAME}*spec*" -o -name "test_${BASENAME}*" 2>/dev/null | head -1)
  if [[ -z "$TEST_EXISTS" ]]; then
    FAILURES+=("NO TEST FILE for: $SRC — every source file needs a test.")
  fi
done

if [[ ${#FAILURES[@]} -gt 0 ]]; then
  FAILURE_MSG=$(printf '%s\n---\n' "${FAILURES[@]}")
  echo "[$TIMESTAMP] BLOCKED: ${#FAILURES[@]} issue(s)" >> "$LOG_FILE"
  cat <<EOF
{
  "decision": "block",
  "reason": "TASK NOT DONE — ${#FAILURES[@]} issue(s) must be resolved:\n\n$FAILURE_MSG"
}
EOF
  exit 1
fi

echo "[$TIMESTAMP] All checks PASSED" >> "$LOG_FILE"
exit 0
