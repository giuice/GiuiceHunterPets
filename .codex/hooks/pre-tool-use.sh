#!/bin/sh
# codewiki: Codex PreToolUse wrapper
# Codex ignores plain stdout for PreToolUse, so this wrapper emits no shared
# hook context and only returns JSON allow output for future guardrail checks.

PAYLOAD=$(cat 2>/dev/null) || PAYLOAD=""
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)

_codewiki_unused_payload=$PAYLOAD
_codewiki_unused_root=$ROOT

printf '{}\n'
exit 0
