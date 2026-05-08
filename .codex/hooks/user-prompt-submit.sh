#!/bin/sh
# codewiki: Codex UserPromptSubmit wrapper
# Plain stdout is developer context for this Codex event.

PAYLOAD=$(cat 2>/dev/null) || PAYLOAD=""
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
HOOK="$ROOT/.codewiki/hooks/pre-wiki-context.sh"

if [ -x "$HOOK" ] || [ -r "$HOOK" ]; then
    printf '%s' "$PAYLOAD" | CODEWIKI_HOOK_HOST=codex CODEWIKI_HOOK_EVENT=UserPromptSubmit sh "$HOOK" 2>/dev/null || true
fi

exit 0
