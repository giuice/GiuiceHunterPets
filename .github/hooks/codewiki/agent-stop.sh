#!/bin/sh
# codewiki: Copilot agentStop wrapper.
# agentStop is the meaningful post-turn hook for CodeWiki follow-up.
# sessionEnd is cleanup-only; this wrapper may read its summary but does not
# rely on sessionEnd hook output to reach the agent directly.

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
    printf '{"timestamp":"%s","host":"copilot","event":"agentStop","stage":"wrapper","stdin_payload":"true","stdout_produced":%s,"wrapper_json":"%s","observable_context":"%s","message":"%s"}\n' \
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

case "$PAYLOAD" in
    *CODEWIKI_FOLLOWUP_ACTIVE*|*CODEWIKI_TRIGGERED_FOLLOWUP*|*codewiki-triggered-followup*)
        printf '{"decision":"allow"}\n'
        exit 0
        ;;
esac

if [ "${CODEWIKI_FOLLOWUP_ACTIVE:-}" = "1" ] || [ "${CODEWIKI_TRIGGERED_FOLLOWUP:-}" = "1" ]; then
    printf '{"decision":"allow"}\n'
    exit 0
fi

if [ -f "$ROOT/.codewiki/hooks/session-end.sh" ]; then
    OUTPUT=$(printf '%s' "$PAYLOAD" | CODEWIKI_HOOK_HOST=copilot CODEWIKI_HOOK_EVENT=agentStop sh "$ROOT/.codewiki/hooks/session-end.sh" 2>/dev/null) || OUTPUT=""
fi

if [ "${CODEWIKI_HOOK_DEBUG:-}" = "1" ] && [ -n "$OUTPUT" ]; then
    ESCAPED=$(printf 'CODEWIKI_TRIGGERED_FOLLOWUP\n%s' "$OUTPUT" | json_escape)
    log_wrapper_debug true true continuation "wrapped hook stdout as Copilot agentStop block JSON"
    printf '{"decision":"block","reason":%s}\n' "$ESCAPED"
else
    log_wrapper_debug false false none "returned allow decision for Copilot agentStop"
    printf '{"decision":"allow"}\n'
fi

exit 0
