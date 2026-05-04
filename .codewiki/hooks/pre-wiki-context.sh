#!/bin/sh
# codewiki: pre-wiki-context hook
# Reads wiki/index.md and emits relevant wiki context to stdout.
# Always exits 0 so it never blocks the agent.

trap 'exit 0' EXIT
set -e

_cwiki_index="wiki/index.md"
_cwiki_input=""

if [ ! -f "$_cwiki_index" ]; then
    exit 0
fi

printf '## CodeWiki Context\n\n'
cat "$_cwiki_index"
printf '\n'

if [ ! -t 0 ]; then
    _cwiki_input=$(cat 2>/dev/null) || _cwiki_input=""
fi

if [ -z "$_cwiki_input" ]; then
    exit 0
fi

_cwiki_terms=$(printf '%s' "$_cwiki_input" | grep -oE '[A-Za-z][A-Za-z0-9_-]+' | sort -u | head -20) || _cwiki_terms=""

for _cwiki_term in $_cwiki_terms; do
    if grep -Fqi "$_cwiki_term" "$_cwiki_index" 2>/dev/null; then
        _cwiki_page=$(grep -Fi "$_cwiki_term" "$_cwiki_index" | grep -oE 'wiki/[^ )]+\.md' | head -1) || _cwiki_page=""
        if [ -n "$_cwiki_page" ] && [ -f "$_cwiki_page" ]; then
            printf '\n### Related: %s\n' "$_cwiki_term"
            head -20 "$_cwiki_page"
            printf '\n'
        fi
    fi
done
