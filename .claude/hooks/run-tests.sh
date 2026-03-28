#!/usr/bin/env bash
# run-tests.sh
# Fires: PostToolUse on Edit|MultiEdit|Write
# Runs project test suite after every source file change.
# Set TEST_CMD in .claude/project.env — falls back to auto-detection.

set -euo pipefail

INPUT=$(cat)

if command -v jq &>/dev/null; then
  FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')
else
  FILE_PATH=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('file_path',''))" 2>/dev/null || echo "")
fi

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"

if [[ -z "$FILE_PATH" ]]; then exit 0; fi

SKIP=$(python3 -c "
import sys, os
p = sys.argv[1]
skip_exts = {'.md','.json','.yaml','.yml','.sh','.toml','.lock','.env'}
skip_dirs = ['.claude/']
ext = os.path.splitext(p)[1].lower()
if ext in skip_exts: print('yes')
elif any(d in p for d in skip_dirs): print('yes')
else: print('no')
" "$FILE_PATH" 2>/dev/null || echo "no")

if [[ "$SKIP" == "yes" ]]; then exit 0; fi

LOG_DIR="$PROJECT_DIR/.claude/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/test-results.log"
TIMESTAMP=$(python3 -c "import datetime; print(datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))" 2>/dev/null || echo "unknown-time")
echo "[$TIMESTAMP] Running tests after edit to: $FILE_PATH" >> "$LOG_FILE"

PROJECT_ENV="$PROJECT_DIR/.claude/project.env"
TEST_CMD=""
if [[ -f "$PROJECT_ENV" ]]; then
  TEST_CMD=$(grep '^TEST_CMD=' "$PROJECT_ENV" | cut -d'=' -f2- | tr -d '"' 2>/dev/null || echo "")
fi

if [[ -z "$TEST_CMD" ]]; then
  if [[ -f "$PROJECT_DIR/pyproject.toml" || -f "$PROJECT_DIR/setup.py" ]]; then
    TEST_CMD="python -m pytest tests/ -v"
  elif [[ -f "$PROJECT_DIR/package.json" ]]; then
    TEST_CMD="npm test"
  elif [[ -f "$PROJECT_DIR/go.mod" ]]; then
    TEST_CMD="go test ./... -v"
  elif [[ -f "$PROJECT_DIR/Cargo.toml" ]]; then
    TEST_CMD="cargo test"
  else
    # No test runner — warn but don't block, project may not have tests yet
    echo "[$TIMESTAMP] No test runner detected — skipping" >> "$LOG_FILE"
    exit 0
  fi
fi

cd "$PROJECT_DIR"
# || true so set -e doesn't kill the script before we can report the failure
TEST_OUTPUT=$(eval "$TEST_CMD" 2>&1) || true
TEST_EXIT=$?
echo "$TEST_OUTPUT" >> "$LOG_FILE"

if [[ $TEST_EXIT -ne 0 ]]; then
  TRIMMED=$(echo "$TEST_OUTPUT" | tail -40)
  python3 -c "
import json, sys
reason = 'TESTS FAILED after editing ' + repr(sys.argv[1]) + '. Fix all failures before continuing.\n\n' + sys.argv[2]
print(json.dumps({'decision': 'block', 'reason': reason}))
" "$FILE_PATH" "$TRIMMED"
  exit 1
fi

echo "[$TIMESTAMP] Tests PASSED" >> "$LOG_FILE"
exit 0
