#!/usr/bin/env bash
# setup-agent-teams.sh
# Run ONCE per machine to enable Claude Code Agent Teams.
# Works on macOS, Linux, and Windows (WSL or Git Bash).
#
# For Windows native PowerShell — see the manual steps printed at the end.

set -euo pipefail

# ── Colours (disabled if not a terminal) ─────────────────────────────────────
if [[ -t 1 ]]; then
  RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
else
  RED=''; GREEN=''; YELLOW=''; NC=''
fi

ok()   { echo -e "${GREEN}[ok]${NC} $1"; }
warn() { echo -e "${YELLOW}[!!]${NC} $1"; }
fail() { echo -e "${RED}[xx]${NC} $1"; }

# ── OS detection ──────────────────────────────────────────────────────────────
OS="unknown"
IS_WSL=false
case "$(uname -s 2>/dev/null || echo 'Windows')" in
  Darwin)  OS="macos" ;;
  Linux)
    OS="linux"
    if grep -qi microsoft /proc/version 2>/dev/null; then IS_WSL=true; fi
    ;;
  MINGW*|MSYS*|CYGWIN*) OS="windows-bash" ;;  # Git Bash / MSYS2
  Windows*|"")           OS="windows-native" ;;
esac

echo ""
echo "Claude Code Agent Teams — one-time machine setup"
echo "================================================="
echo "Detected OS: $OS${IS_WSL:+ (WSL)}"
echo ""

# ── 1. Check Claude Code ──────────────────────────────────────────────────────
if ! command -v claude &>/dev/null; then
  fail "Claude Code not found."
  echo "   Install: npm install -g @anthropic-ai/claude-code"
  echo ""
  echo "   Windows (PowerShell): npm install -g @anthropic-ai/claude-code"
  echo "   macOS/Linux:          npm install -g @anthropic-ai/claude-code"
  exit 1
fi

VERSION=$(claude --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "0.0.0")
MAJOR=$(echo "$VERSION" | cut -d. -f1)
MINOR=$(echo "$VERSION" | cut -d. -f2)
PATCH=$(echo "$VERSION" | cut -d. -f3)

if [[ "$MAJOR" -lt 2 ]] || \
   [[ "$MAJOR" -eq 2 && "$MINOR" -lt 1 ]] || \
   [[ "$MAJOR" -eq 2 && "$MINOR" -eq 1 && "$PATCH" -lt 32 ]]; then
  fail "Claude Code $VERSION is too old — Agent Teams requires 2.1.32+."
  echo "   Update: npm update -g @anthropic-ai/claude-code"
  exit 1
fi
ok "Claude Code $VERSION (>= 2.1.32)"

# ── 2. Enable feature flag via ~/.claude/settings.json ───────────────────────
# This is the most reliable cross-platform method — Claude Code reads this file
# on every platform including Windows native.

CLAUDE_DIR="$HOME/.claude"
CLAUDE_SETTINGS="$CLAUDE_DIR/settings.json"
mkdir -p "$CLAUDE_DIR"

python3 - "$CLAUDE_SETTINGS" <<'PYEOF'
import json, sys, os

path = sys.argv[1]
try:
    with open(path) as f:
        data = json.load(f)
except Exception:
    data = {}

already = data.get("env", {}).get("CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS") == "1"
if not already:
    data.setdefault("env", {})["CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS"] = "1"
    with open(path, "w") as f:
        json.dump(data, f, indent=2)
    print("updated")
else:
    print("already_set")
PYEOF

FLAG_RESULT=$(python3 - "$CLAUDE_SETTINGS" <<'PYEOF'
import json, sys
try:
    with open(sys.argv[1]) as f:
        data = json.load(f)
    print("ok" if data.get("env", {}).get("CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS") == "1" else "missing")
except:
    print("missing")
PYEOF
)

if [[ "$FLAG_RESULT" == "ok" ]]; then
  ok "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 set in $CLAUDE_SETTINGS"
else
  warn "Could not verify flag in $CLAUDE_SETTINGS — set it manually (see below)"
fi

# ── 3. Shell profile (macOS / Linux / WSL / Git Bash) ────────────────────────
PROFILE=""
if [[ "$OS" != "windows-native" ]]; then
  if [[ -f "$HOME/.zshrc" ]];        then PROFILE="$HOME/.zshrc"
  elif [[ -f "$HOME/.bashrc" ]];     then PROFILE="$HOME/.bashrc"
  elif [[ -f "$HOME/.bash_profile" ]]; then PROFILE="$HOME/.bash_profile"
  fi

  if [[ -n "$PROFILE" ]]; then
    if ! grep -q "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS" "$PROFILE" 2>/dev/null; then
      printf '\n# Claude Code Agent Teams\nexport CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1\n' >> "$PROFILE"
      ok "Added export to $PROFILE (restart shell or: source $PROFILE)"
    else
      ok "Already exported in $PROFILE"
    fi
  fi
fi

# ── 4. tmux check ─────────────────────────────────────────────────────────────
echo ""
if command -v tmux &>/dev/null; then
  TMUX_VER=$(tmux -V 2>/dev/null | grep -oE '[0-9]+\.[0-9]+' | head -1 || echo "?")
  ok "tmux $TMUX_VER — each agent gets its own terminal panel"
else
  warn "tmux not found — agents still work, output just merges into one thread"
  echo ""
  echo "   Install tmux:"
  case "$OS" in
    macos)          echo "     brew install tmux" ;;
    linux)
      if $IS_WSL; then echo "     sudo apt install tmux   (WSL)"
      else             echo "     sudo apt install tmux   # or your distro's equivalent"
      fi ;;
    windows-bash)   echo "     Install via WSL: sudo apt install tmux" ;;
    windows-native) echo "     Use WSL (recommended): wsl --install, then sudo apt install tmux" ;;
  esac
  echo ""
fi

# ── 5. .gitignore for this repo ───────────────────────────────────────────────
GITIGNORE=".gitignore"
PATTERNS=(".agent-tasks.md" ".agent-mailbox/")
ADDED=()
for P in "${PATTERNS[@]}"; do
  if ! grep -qF "$P" "$GITIGNORE" 2>/dev/null; then
    echo "$P" >> "$GITIGNORE"
    ADDED+=("$P")
  fi
done
if [[ ${#ADDED[@]} -gt 0 ]]; then
  ok "Added to .gitignore: ${ADDED[*]}"
else
  ok ".gitignore already has agent coordination patterns"
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " Setup complete. Restart Claude Code to pick up the flag."
echo ""
echo " Usage in any Claude Code session:"
echo "   /build/start <describe what to build>"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Windows native manual steps
if [[ "$OS" == "windows-native" || "$OS" == "windows-bash" ]]; then
  echo ""
  echo " Windows native (PowerShell) — if the script didn't fully apply:"
  echo ""
  echo "   Option A: Set permanently via User environment variables"
  echo "     [System.Environment]::SetEnvironmentVariable("
  echo "       'CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS', '1', 'User')"
  echo ""
  echo "   Option B: Add to your PowerShell profile (\$PROFILE):"
  echo "     \$env:CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = '1'"
  echo ""
  echo "   Option C: Already handled via ~/.claude/settings.json above (recommended)"
fi
echo ""
