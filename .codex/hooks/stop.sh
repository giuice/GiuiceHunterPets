#!/bin/sh
# codewiki: Codex Stop wrapper
# Stop must emit JSON only and must respect stop_hook_active to avoid loops.

json_escape() {
    awk '
        BEGIN {
            ORS = "";
            tab = sprintf("%c", 9);
            cr = sprintf("%c", 13);
        }
        {
            gsub(/\\/, "\\\\");
            gsub(/"/, "\\\"");
            gsub(tab, "\\t");
            gsub(cr, "\\r");
            if (NR > 1) {
                printf "\\n";
            }
            printf "%s", $0;
        }
    '
}

log_wrapper_debug() {
    [ "${CODEWIKI_HOOK_DEBUG:-}" = "1" ] || return 0
    mkdir -p "$ROOT/.codewiki/state" 2>/dev/null || return 0
    printf '{"timestamp":"%s","host":"codex","event":"Stop","stage":"wrapper","stdin_payload":"true","stdout_produced":%s,"wrapper_json":"%s","observable_context":"%s","message":"%s"}\n' \
        "$(date -u '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date '+%Y-%m-%dT%H:%M:%S%z')" "$1" "$2" "$3" "$4" >>"$ROOT/.codewiki/state/hooks-debug.jsonl" 2>/dev/null || true
}

PAYLOAD=$(cat 2>/dev/null) || PAYLOAD=""
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
HOOK="$ROOT/.codewiki/hooks/session-end.sh"

if printf '%s' "$PAYLOAD" | grep -Eq '"stop_hook_active":[[:space:]]*true'; then
    printf '{}\n'
    exit 0
fi

if [ ! -x "$HOOK" ] && [ ! -r "$HOOK" ]; then
    printf '{}\n'
    exit 0
fi

OUTPUT=$(printf '%s' "$PAYLOAD" | CODEWIKI_HOOK_HOST=codex CODEWIKI_HOOK_EVENT=Stop bash "$HOOK" 2>/dev/null) || OUTPUT=""

if [ -z "$OUTPUT" ]; then
    log_wrapper_debug false false none "returned empty Codex Stop JSON"
    printf '{}\n'
    exit 0
fi

if [ "${CODEWIKI_HOOK_DEBUG:-}" = "1" ]; then
    ESCAPED_OUTPUT=$(printf '%s' "$OUTPUT" | json_escape)
    log_wrapper_debug true true continuation "wrapped hook stdout as Codex Stop block JSON"
    printf '{"decision":"block","reason":"%s"}\n' "$ESCAPED_OUTPUT"
    exit 0
fi

log_wrapper_debug false false none "returned empty Codex Stop JSON"
printf '{}\n'
exit 0
