#!/usr/bin/env bash
#
# sync-tab-title.sh — keep the terminal tab title in sync with the current
# git branch (the worktree you are working in).
#
# Registered by the hane plugin (see hooks/hooks.json) on:
#   - SessionStart : set the title when a session begins / resumes
#   - CwdChanged   : update it the moment Claude `cd`s into a worktree
#
# Output uses the `terminalSequence` hook field (Claude Code >= 2.1.141).
# Hooks run without a controlling terminal, so we hand the OSC escape to
# Claude Code via JSON and it writes it to the real terminal for us.
#
# Title source, in priority order:
#   1. current git branch (the value that tracks "what am I working on")
#   2. an explicit session title, if one was set (SessionStart input only)
#   3. the basename of the working directory (last resort)
#
# To prefer the session name over the branch, swap steps 1 and 2 below.
#
set -euo pipefail

# jq is used to parse the hook payload; degrade silently if it is missing.
command -v jq >/dev/null 2>&1 || exit 0

input=$(cat)

cwd=$(printf '%s' "$input" | jq -r '.cwd // .new_cwd // empty' 2>/dev/null || true)
[ -n "$cwd" ] || cwd=$(pwd)

# 1. live git branch (empty when detached / not a repo)
title=$(git -C "$cwd" branch --show-current 2>/dev/null || true)

# 2. fall back to an explicit session title
if [ -z "$title" ]; then
  title=$(printf '%s' "$input" | jq -r '.session_title // empty' 2>/dev/null || true)
fi

# 3. fall back to the directory name
[ -n "$title" ] || title=$(basename "$cwd")
[ -n "$title" ] || exit 0

# Build OSC 0 (sets both window and icon/tab titles) for the widest terminal
# support: <ESC> ] 0 ; <title> <BEL>. ESC=codepoint 27, BEL=codepoint 7 are
# generated from their numbers so no escape sequences live in this script; jq
# JSON-encodes those control bytes safely on output. Use ]1; for icon-only or
# ]2; for window-only if your terminal maps those to the tab differently.
esc=$(awk 'BEGIN { printf "%c", 27 }')
bel=$(awk 'BEGIN { printf "%c", 7 }')
jq -nc --arg t "$title" --arg esc "$esc" --arg bel "$bel" \
  '{ terminalSequence: ($esc + "]0;" + $t + $bel) }'
