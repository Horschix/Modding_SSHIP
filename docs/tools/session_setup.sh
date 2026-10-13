#!/usr/bin/env bash
# Start-of-session setup for the modding repos (Modding_DAC-EUR and Modding_SSHIP).
# Run ONCE per session from the repo root:  bash docs/tools/session_setup.sh
# 1. builds a Lua 5.1 interpreter (/home/claude/.tools/lua51) if it is missing
# 2. prints the handover's "START HERE" section
# 3. prints the open issues as one line each (number, labels, title)
# Output is kept short on purpose: everything printed here lands in the conversation.

set -u
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
TOOLS=/home/claude/.tools
LUA="$TOOLS/lua51"

# --- 1. Lua 5.1 ------------------------------------------------------------
if [ ! -x "$LUA" ]; then
  mkdir -p "$TOOLS"
  SRC="$TOOLS/lua-src"
  rm -rf "$SRC"
  if git clone -q --depth 1 -b v5.1 https://github.com/lua/lua "$SRC" 2>/dev/null; then
    ( cd "$SRC" && gcc -O2 -DLUA_USE_POSIX -o "$LUA" \
        $(ls *.c | grep -v -e '^luac\.c$' -e '^print\.c$' -e '^ltests\.c$') -lm 2>/dev/null )
  fi
fi
if [ -x "$LUA" ]; then
  echo "Lua: $LUA ready  (syntax check: $LUA -e 'assert(loadfile(arg[1]))' file.lua)"
else
  echo "Lua: build FAILED - Lua files cannot be checked this session"
fi

# --- 2. Handover: START HERE ---------------------------------------------
H="$ROOT/docs/HANDOVER.md"
if [ -f "$H" ]; then
  echo
  awk '/^## Where things stand/{on=1} on && /^## / && !/^## Where things stand/{exit} on' "$H"
fi

# --- 3. Open issues ---------------------------------------------------------
REPO="$(git -C "$ROOT" remote get-url origin 2>/dev/null | sed -E 's#.*github\.com[/:]##; s#\.git$##')"
if [ -n "$REPO" ] && command -v gh >/dev/null; then
  echo
  echo "Open issues ($REPO):"
  gh api "repos/$REPO/issues?state=open&per_page=100" \
    --jq '.[] | select(.pull_request|not) | "#\(.number) [\([.labels[].name]|join(","))] \(.title)"' 2>/dev/null \
    || echo "  (could not read the issue board)"
fi
