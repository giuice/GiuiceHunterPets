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

OUTPUT=$(printf '%s' "$PAYLOAD" | bash "$HOOK" 2>/dev/null) || OUTPUT=""

if [ -z "$OUTPUT" ]; then
    printf '{}\n'
    exit 0
fi

ESCAPED_OUTPUT=$(printf '%s' "$OUTPUT" | json_escape)
printf '{"decision":"block","reason":"%s"}\n' "$ESCAPED_OUTPUT"
exit 0
