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
    OUTPUT=$(printf '%s' "$PAYLOAD" | sh "$ROOT/.codewiki/hooks/session-end.sh" 2>/dev/null) || OUTPUT=""
fi

if [ -n "$OUTPUT" ]; then
    ESCAPED=$(printf 'CODEWIKI_TRIGGERED_FOLLOWUP\n%s' "$OUTPUT" | json_escape)
    printf '{"decision":"block","reason":%s}\n' "$ESCAPED"
else
    printf '{"decision":"allow"}\n'
fi

exit 0
