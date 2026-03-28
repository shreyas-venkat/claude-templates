#!/usr/bin/env bash
# stop-check.sh — Stop hook
set -euo pipefail
PY=$(command -v python3 2>/dev/null || command -v python 2>/dev/null || echo "python")

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
LOG_DIR="$PROJECT_DIR/.claude/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/stop-check.log"
TS=$($PY -c "import datetime; print(datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))" 2>/dev/null || echo "now")
echo "[$TS] Stop hook fired" >> "$LOG_FILE"

FAILURES=()

PROJECT_ENV="$PROJECT_DIR/.claude/project.env"
TEST_CMD=""
[[ -f "$PROJECT_ENV" ]] && TEST_CMD=$(grep '^TEST_CMD=' "$PROJECT_ENV" | cut -d'=' -f2- | tr -d '"' 2>/dev/null || echo "")

if [[ -z "$TEST_CMD" ]]; then
  [[ -f "$PROJECT_DIR/pyproject.toml" || -f "$PROJECT_DIR/setup.py" ]] && TEST_CMD="python -m pytest tests/ -v"
  [[ -f "$PROJECT_DIR/package.json" ]] && TEST_CMD="npm test"
  [[ -f "$PROJECT_DIR/go.mod" ]] && TEST_CMD="go test ./..."
  [[ -f "$PROJECT_DIR/Cargo.toml" ]] && TEST_CMD="cargo test"
fi

# 1. Tests
if [[ -n "$TEST_CMD" ]]; then
  cd "$PROJECT_DIR"
  TEST_OUTPUT=$(eval "$TEST_CMD" 2>&1) || true
  [[ $? -ne 0 ]] && FAILURES+=("TEST SUITE FAILED:\n$(echo "$TEST_OUTPUT" | tail -30)")
fi

# 2. Debug markers
MODIFIED=$(git -C "$PROJECT_DIR" diff --name-only HEAD 2>/dev/null || echo "")
if [[ -n "$MODIFIED" ]]; then
  PYCHECK=$(mktemp)
  cat > "$PYCHECK" << 'PYEOF'
import sys,os,re
lines=open(sys.argv[1]).read().strip()
proj=sys.argv[2]
if not lines: sys.exit(0)
pat=re.compile(r'(console\.log|print\(|debugger|TODO|FIXME|HACK|XXX)')
hits=[]
for rel in lines.splitlines():
    try:
        with open(os.path.join(proj,rel),encoding='utf-8',errors='ignore') as f:
            if pat.search(f.read()): hits.append(rel)
    except: pass
if hits: print('\n'.join(hits))
PYEOF
  MOD=$(mktemp); echo "$MODIFIED" > "$MOD"
  DEBUG_HITS=$($PY "$PYCHECK" "$MOD" "$PROJECT_DIR" 2>/dev/null || echo "")
  rm -f "$PYCHECK" "$MOD"
  [[ -n "$DEBUG_HITS" ]] && FAILURES+=("DEBUG/TODO MARKERS in:\n$DEBUG_HITS")
fi

# 3. Test file coverage
NEW_SRC=$(git -C "$PROJECT_DIR" diff --name-only HEAD 2>/dev/null || echo "")
if [[ -n "$NEW_SRC" ]]; then
  PYCHECK2=$(mktemp)
  cat > "$PYCHECK2" << 'PYEOF'
import sys,os,re
lines=open(sys.argv[1]).read().strip()
proj=sys.argv[2]
if not lines: sys.exit(0)
skip=re.compile(r'(test|spec|\.(md|json|sh|yaml|toml|env|lock))$',re.I)
missing=[]
for rel in lines.splitlines():
    if skip.search(rel): continue
    base=os.path.splitext(os.path.basename(rel))[0]
    found=False
    for root,dirs,files in os.walk(proj):
        dirs[:]=[d for d in dirs if not d.startswith('.')]
        for f in files:
            if base in f and re.search(r'(test|spec)',f,re.I): found=True; break
        if found: break
    if not found: missing.append(rel)
if missing: print('\n'.join(missing))
PYEOF
  SRC=$(mktemp); echo "$NEW_SRC" > "$SRC"
  MISSING=$($PY "$PYCHECK2" "$SRC" "$PROJECT_DIR" 2>/dev/null || echo "")
  rm -f "$PYCHECK2" "$SRC"
  [[ -n "$MISSING" ]] && FAILURES+=("NO TEST FILE for:\n$MISSING")
fi

if [[ ${#FAILURES[@]} -gt 0 ]]; then
  MSG=$(printf '%s\n---\n' "${FAILURES[@]}")
  echo "[$TS] BLOCKED: ${#FAILURES[@]} issue(s)" >> "$LOG_FILE"
  $PY -c "import json,sys; print(json.dumps({'decision':'block','reason':'TASK NOT DONE:\n\n'+sys.argv[1]}))" "$MSG"
  exit 1
fi

echo "[$TS] All checks PASSED" >> "$LOG_FILE"
exit 0
