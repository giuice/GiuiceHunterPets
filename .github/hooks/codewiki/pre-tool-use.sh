#!/bin/sh
# codewiki: Copilot preToolUse wrapper.
# Calls shared wiki-context logic but never denies tools by default.

PAYLOAD=""
ROOT=""

if [ ! -t 0 ]; then
    PAYLOAD=$(cat 2>/dev/null) || PAYLOAD=""
fi

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)

if [ -f "$ROOT/.codewiki/hooks/pre-wiki-context.sh" ]; then
    printf '%s' "$PAYLOAD" | sh "$ROOT/.codewiki/hooks/pre-wiki-context.sh" >/dev/null 2>&1 || true
fi

printf '{}\n'
exit 0
