#!/usr/bin/env bash
# run-tests.sh — PostToolUse on Edit|MultiEdit|Write
set -euo pipefail
PY=$(command -v python3 2>/dev/null || command -v python 2>/dev/null || echo "python")

INPUT=$(cat)
if command -v jq &>/dev/null; then
  FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')
else
  FILE_PATH=$(echo "$INPUT" | $PY -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('file_path',''))" 2>/dev/null || echo "")
fi

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
[[ -z "$FILE_PATH" ]] && exit 0

SKIP=$($PY -c "
import sys,os
p=sys.argv[1]
skip_exts={'.md','.json','.yaml','.yml','.sh','.toml','.lock','.env','.txt','.cfg','.ini'}
skip_dirs=['.claude/','node_modules/','__pycache__/']
ext=os.path.splitext(p)[1].lower()
print('yes' if ext in skip_exts or any(d in p for d in skip_dirs) else 'no')
" "$FILE_PATH" 2>/dev/null || echo "no")
[[ "$SKIP" == "yes" ]] && exit 0

LOG_DIR="$PROJECT_DIR/.claude/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/test-results.log"
TS=$($PY -c "import datetime; print(datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))" 2>/dev/null || echo "now")
echo "[$TS] Testing after edit: $FILE_PATH" >> "$LOG_FILE"

PROJECT_ENV="$PROJECT_DIR/.claude/project.env"
TEST_CMD=""
[[ -f "$PROJECT_ENV" ]] && TEST_CMD=$(grep '^TEST_CMD=' "$PROJECT_ENV" | cut -d'=' -f2- | tr -d '"' 2>/dev/null || echo "")

if [[ -z "$TEST_CMD" ]]; then
  [[ -f "$PROJECT_DIR/pyproject.toml" || -f "$PROJECT_DIR/setup.py" ]] && TEST_CMD="python -m pytest tests/ -v"
  [[ -f "$PROJECT_DIR/package.json" ]] && TEST_CMD="npm test"
  [[ -f "$PROJECT_DIR/go.mod" ]] && TEST_CMD="go test ./... -v"
  [[ -f "$PROJECT_DIR/Cargo.toml" ]] && TEST_CMD="cargo test"
fi

[[ -z "$TEST_CMD" ]] && { echo "[$TS] No test runner — skipping" >> "$LOG_FILE"; exit 0; }

cd "$PROJECT_DIR"
TEST_OUTPUT=$(eval "$TEST_CMD" 2>&1) || true
TEST_EXIT=$?
echo "$TEST_OUTPUT" >> "$LOG_FILE"

if [[ $TEST_EXIT -ne 0 ]]; then
  TRIMMED=$(echo "$TEST_OUTPUT" | tail -40)
  $PY -c "
import json,sys
print(json.dumps({'decision':'block','reason':'TESTS FAILED after editing '+repr(sys.argv[1])+'. Fix before continuing.\n\n'+sys.argv[2]}))
" "$FILE_PATH" "$TRIMMED"
  exit 1
fi

echo "[$TS] Tests PASSED" >> "$LOG_FILE"
exit 0
