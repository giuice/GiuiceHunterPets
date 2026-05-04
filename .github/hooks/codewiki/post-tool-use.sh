#!/bin/sh
# codewiki: Copilot postToolUse wrapper.
# Translates shared post-verify output into Copilot additionalContext JSON.

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

if [ -f "$ROOT/.codewiki/hooks/post-verify.sh" ]; then
    OUTPUT=$(printf '%s' "$PAYLOAD" | sh "$ROOT/.codewiki/hooks/post-verify.sh" 2>/dev/null) || OUTPUT=""
fi

if [ -n "$OUTPUT" ]; then
    ESCAPED=$(printf '%s' "$OUTPUT" | json_escape)
    printf '{"additionalContext":%s}\n' "$ESCAPED"
else
    printf '{}\n'
fi

exit 0
