#!/usr/bin/env bash
# run-tests.sh
# Fires: PostToolUse on Edit|MultiEdit|Write
# Runs the project's test command after every source file change.
# Configure the test command in .claude/project.env: TEST_CMD="pytest tests/ -v"
# Falls back to auto-detection if not set.

set -euo pipefail

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"

# Skip non-source files
if [[ -z "$FILE_PATH" ]]; then exit 0; fi
if [[ "$FILE_PATH" =~ \.(md|json|yaml|yml|sh|toml|lock|env)$ ]]; then exit 0; fi
if [[ "$FILE_PATH" == *".claude/"* ]]; then exit 0; fi

LOG_FILE="$PROJECT_DIR/.claude/logs/test-results.log"
mkdir -p "$(dirname "$LOG_FILE")"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
echo "[$TIMESTAMP] Running tests after edit to: $FILE_PATH" >> "$LOG_FILE"

# Load project-specific config if it exists
PROJECT_ENV="$PROJECT_DIR/.claude/project.env"
TEST_CMD=""
if [[ -f "$PROJECT_ENV" ]]; then
  TEST_CMD=$(grep '^TEST_CMD=' "$PROJECT_ENV" | cut -d'=' -f2- | tr -d '"' || echo "")
fi

# Auto-detect if not configured
if [[ -z "$TEST_CMD" ]]; then
  if [[ -f "$PROJECT_DIR/pyproject.toml" ]] || [[ -f "$PROJECT_DIR/setup.py" ]]; then
    TEST_CMD="python -m pytest tests/ -v"
  elif [[ -f "$PROJECT_DIR/package.json" ]]; then
    TEST_CMD="npm test"
  elif [[ -f "$PROJECT_DIR/go.mod" ]]; then
    TEST_CMD="go test ./... -v"
  elif [[ -f "$PROJECT_DIR/Cargo.toml" ]]; then
    TEST_CMD="cargo test"
  else
    # No test runner found — warn Claude but don't hard block (project may not have tests yet)
    cat <<EOF
{
  "decision": "block",
  "reason": "No test runner detected and TEST_CMD not set in .claude/project.env. Set up a test framework and add TEST_CMD to .claude/project.env before writing code."
}
EOF
    exit 1
  fi
fi

cd "$PROJECT_DIR"
TEST_OUTPUT=$(eval "$TEST_CMD" 2>&1)
TEST_EXIT=$?
echo "$TEST_OUTPUT" >> "$LOG_FILE"

if [[ $TEST_EXIT -ne 0 ]]; then
  TRIMMED=$(echo "$TEST_OUTPUT" | tail -40)
  cat <<EOF
{
  "decision": "block",
  "reason": "TESTS FAILED after editing '$FILE_PATH'. Fix all failures before continuing.\n\n$TRIMMED"
}
EOF
  exit 1
fi

echo "[$TIMESTAMP] Tests PASSED" >> "$LOG_FILE"
exit 0
