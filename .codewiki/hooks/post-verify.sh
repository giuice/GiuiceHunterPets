#!/bin/sh
# codewiki: post-verify hook
# Checks whether modified files appear related to wiki entities.
# Always exits 0 so it never blocks the agent.

trap 'exit 0' EXIT
set -e

_cwiki_entities="wiki/entities"
_cwiki_payload=""

if [ -t 0 ]; then
    exit 0
fi

_cwiki_payload=$(cat 2>/dev/null) || _cwiki_payload=""

[ -z "$_cwiki_payload" ] && exit 0
[ ! -d "$_cwiki_entities" ] && exit 0

if command -v jq >/dev/null 2>&1; then
    _cwiki_files=$(printf '%s' "$_cwiki_payload" | jq -r '.. | strings' 2>/dev/null) || _cwiki_files=""
else
    _cwiki_files=$(printf '%s' "$_cwiki_payload" | grep -oE '"[^"]+\.[a-zA-Z0-9]+"' | tr -d '"') || _cwiki_files=""
fi

[ -z "$_cwiki_files" ] && exit 0

_cwiki_matched=""

for _cwiki_entity_file in "$_cwiki_entities"/*.md; do
    [ -f "$_cwiki_entity_file" ] || continue
    _cwiki_entity_name=$(basename "$_cwiki_entity_file" .md)
    if printf '%s' "$_cwiki_files" | grep -Fqi "$_cwiki_entity_name"; then
        _cwiki_matched="${_cwiki_matched}${_cwiki_entity_name}\n"
    fi
done

[ -z "$_cwiki_matched" ] && exit 0

printf 'CODEWIKI_CHANGE_CONTEXT\n'
printf 'Affected wiki entities:\n'
printf '%b' "$_cwiki_matched"
printf 'Action: Run /codewiki-absorb to extract knowledge from these changes\n'
printf 'END_CODEWIKI_CHANGE_CONTEXT\n'
