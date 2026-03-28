#!/usr/bin/env bash
# stop-check.sh
# Fires: Stop (when Claude thinks it's finished)
# Final gate: tests must pass, no debug markers, every source file needs a test file.

set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
LOG_DIR="$PROJECT_DIR/.claude/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/stop-check.log"
TIMESTAMP=$(python3 -c "import datetime; print(datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))" 2>/dev/null || echo "unknown-time")
echo "[$TIMESTAMP] Stop hook fired" >> "$LOG_FILE"

FAILURES=()

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
    TEST_CMD="go test ./..."
  elif [[ -f "$PROJECT_DIR/Cargo.toml" ]]; then
    TEST_CMD="cargo test"
  fi
fi

# 1. Run full test suite — || true so set -e doesn't kill us before we report
if [[ -n "$TEST_CMD" ]]; then
  cd "$PROJECT_DIR"
  TEST_OUTPUT=$(eval "$TEST_CMD" 2>&1) || true
  TEST_EXIT=$?
  if [[ $TEST_EXIT -ne 0 ]]; then
    TAIL=$(echo "$TEST_OUTPUT" | tail -30)
    FAILURES+=("TEST SUITE FAILED:\n$TAIL")
  fi
fi
# No test runner = no block (template repo has no tests by design)

# 2. Check for debug/todo markers — inline python heredoc, no temp files needed
MODIFIED=$(git -C "$PROJECT_DIR" diff --name-only HEAD 2>/dev/null || echo "")
if [[ -n "$MODIFIED" ]]; then
  DEBUG_HITS=$(python3 - "$PROJECT_DIR" << PYEOF
import sys, os, re

project_dir = sys.argv[1]
modified_lines = """$MODIFIED""".strip().splitlines()

pattern = re.compile(r'(console\.log|print\(|debugger|TODO|FIXME|HACK|XXX)')
hits = []
for rel in modified_lines:
    if not rel.strip():
        continue
    path = os.path.join(project_dir, rel)
    try:
        with open(path, encoding='utf-8', errors='ignore') as f:
            if pattern.search(f.read()):
                hits.append(rel)
    except Exception:
        pass
print('\n'.join(hits))
PYEOF
  )
  if [[ -n "$DEBUG_HITS" ]]; then
    FAILURES+=("DEBUG/TODO MARKERS in:\n$DEBUG_HITS\nClean these up before finishing.")
  fi
fi

# 3. Check test files exist for every new source file
NEW_SRC=$(git -C "$PROJECT_DIR" diff --name-only HEAD 2>/dev/null || echo "")
if [[ -n "$NEW_SRC" ]]; then
  MISSING=$(python3 - "$PROJECT_DIR" << PYEOF
import sys, os, re

project_dir = sys.argv[1]
new_src_lines = """$NEW_SRC""".strip().splitlines()

skip_pattern = re.compile(r'(test|spec|\.(md|json|sh|yaml|toml|env|lock))$', re.IGNORECASE)
missing = []

for rel in new_src_lines:
    if not rel.strip() or skip_pattern.search(rel):
        continue
    basename = os.path.splitext(os.path.basename(rel))[0]
    found = False
    for root, dirs, files in os.walk(project_dir):
        dirs[:] = [d for d in dirs if not d.startswith('.')]
        for f in files:
            if (basename in f) and re.search(r'(test|spec)', f, re.IGNORECASE):
                found = True
                break
        if found:
            break
    if not found:
        missing.append(rel)

print('\n'.join(missing))
PYEOF
  )
  if [[ -n "$MISSING" ]]; then
    FAILURES+=("NO TEST FILE for:\n$MISSING\nEvery source file needs a test.")
  fi
fi

if [[ ${#FAILURES[@]} -gt 0 ]]; then
  FAILURE_MSG=$(printf '%s\n---\n' "${FAILURES[@]}")
  echo "[$TIMESTAMP] BLOCKED: ${#FAILURES[@]} issue(s)" >> "$LOG_FILE"
  python3 -c "
import json, sys
msg = sys.argv[1]
print(json.dumps({'decision': 'block', 'reason': 'TASK NOT DONE - issues must be resolved:\n\n' + msg}))
" "$FAILURE_MSG"
  exit 1
fi

echo "[$TIMESTAMP] All checks PASSED" >> "$LOG_FILE"
exit 0
