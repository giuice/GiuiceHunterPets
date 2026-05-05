#!/bin/sh
# codewiki: post-verify hook
# Checks whether modified files appear related to wiki entities or new topic candidates.
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

if command -v jq >/dev/null 2>&1; then
    _cwiki_files=$(printf '%s' "$_cwiki_payload" | jq -r '.. | strings' 2>/dev/null) || _cwiki_files=""
else
    _cwiki_files=$(printf '%s' "$_cwiki_payload" | grep -oE '"[^"]+\.[a-zA-Z0-9]+"' | tr -d '"') || _cwiki_files=""
fi

[ -z "$_cwiki_files" ] && exit 0

_cwiki_matched=""
_cwiki_candidates=""

if [ -d "$_cwiki_entities" ]; then
    for _cwiki_entity_file in "$_cwiki_entities"/*.md; do
        [ -f "$_cwiki_entity_file" ] || continue
        _cwiki_entity_name=$(basename "$_cwiki_entity_file" .md)
        if printf '%s' "$_cwiki_files" | grep -Fqi "$_cwiki_entity_name"; then
            _cwiki_matched="${_cwiki_matched}${_cwiki_entity_name}\n"
        fi
    done
fi

_cwiki_candidates=$(printf '%s\n' "$_cwiki_files" |
    grep -E '(^|/)[A-Za-z0-9._-]+\.[A-Za-z0-9]+$' |
    sed 's#^.*/##; s#\.[^.]*$##; s#[_.]#-#g' |
    sort -u |
    sed -n '1,12p') || _cwiki_candidates=""

[ -z "$_cwiki_matched" ] && [ -z "$_cwiki_candidates" ] && exit 0

printf 'CODEWIKI_CHANGE_CONTEXT\n'
if [ -n "$_cwiki_matched" ]; then
    printf 'Affected wiki entities:\n'
    printf '%b' "$_cwiki_matched"
fi
if [ -n "$_cwiki_candidates" ]; then
    printf 'Potential new topic candidates:\n'
    printf '%s\n' "$_cwiki_candidates"
fi
printf 'Required next step for the host agent: invoke codewiki-wiki-updater now to propose approval-gated wiki updates, or explicitly defer this to codewiki-absorb at session end.\n'
printf 'Verification path: after a non-trivial wiki proposal, invoke codewiki-verifier for read-only review before applying approved wiki edits.\n'
printf 'END_CODEWIKI_CHANGE_CONTEXT\n'
