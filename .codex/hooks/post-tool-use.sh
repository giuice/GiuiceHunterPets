#!/bin/sh
# codewiki: Codex PostToolUse wrapper
# Translates shared post-verify output into Codex hookSpecificOutput JSON.

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
HOOK="$ROOT/.codewiki/hooks/post-verify.sh"

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
printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"%s"}}\n' "$ESCAPED_OUTPUT"
exit 0
