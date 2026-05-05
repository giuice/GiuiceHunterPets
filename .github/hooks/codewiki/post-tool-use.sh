#!/bin/sh
# codewiki: Copilot postToolUse wrapper.
# Records shared post-verify state. Copilot runtimes differ on whether hook
# context reaches the agent, so this wrapper stays silent by default.

json_escape() {
    if command -v jq >/dev/null 2>&1; then
        jq -Rs .
        return
    fi

    awk 'BEGIN { ORS = "" }
        {
            gsub(/\\/, "\\\\")
            gsub(/"/, "\\\"")
            gsub(/\t/, "\\t")
            gsub(/\r/, "\\r")
            if (NR > 1) {
                printf "\\n"
            }
            printf "%s", $0
        }
        END { printf "" }' | sed '1s/^/"/;$s/$/"/'
}

log_wrapper_debug() {
    [ "${CODEWIKI_HOOK_DEBUG:-}" = "1" ] || return 0
    mkdir -p "$ROOT/.codewiki/state" 2>/dev/null || return 0
    printf '{"timestamp":"%s","host":"copilot","event":"postToolUse","stage":"wrapper","stdin_payload":"true","stdout_produced":%s,"wrapper_json":"%s","observable_context":"%s","message":"%s"}\n' \
        "$(date -u '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date '+%Y-%m-%dT%H:%M:%S%z')" "$1" "$2" "$3" "$4" >>"$ROOT/.codewiki/state/hooks-debug.jsonl" 2>/dev/null || true
}

PAYLOAD=""
ROOT=""
OUTPUT=""
ESCAPED=""

if [ ! -t 0 ]; then
    PAYLOAD=$(cat 2>/dev/null) || PAYLOAD=""
fi

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)

if [ -f "$ROOT/.codewiki/hooks/post-verify.sh" ]; then
    OUTPUT=$(printf '%s' "$PAYLOAD" | CODEWIKI_HOOK_HOST=copilot CODEWIKI_HOOK_EVENT=postToolUse sh "$ROOT/.codewiki/hooks/post-verify.sh" 2>/dev/null) || OUTPUT=""
fi

if [ "${CODEWIKI_HOOK_DEBUG:-}" = "1" ] && [ -n "$OUTPUT" ]; then
    ESCAPED=$(printf '%s' "$OUTPUT" | json_escape)
    log_wrapper_debug true true advisory "wrapped hook stdout as Copilot additionalContext JSON"
    printf '{"additionalContext":%s}\n' "$ESCAPED"
else
    log_wrapper_debug false false none "returned empty Copilot postToolUse JSON"
    printf '{}\n'
fi

exit 0
