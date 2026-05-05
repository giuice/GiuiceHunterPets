#!/bin/sh
# codewiki: pre-wiki-context hook
# Emits short wiki context only when the prompt indicates wiki-relevant intent.
# Always exits 0 so it never blocks the agent.

trap 'exit 0' EXIT
set -e

_cwiki_index="wiki/index.md"
_cwiki_input=""
_cwiki_state_dir=".codewiki/state"
_cwiki_debug_file="$_cwiki_state_dir/hooks-debug.jsonl"
_cwiki_host="${CODEWIKI_HOOK_HOST:-unknown}"
_cwiki_event="${CODEWIKI_HOOK_EVENT:-pre-wiki-context}"

_cwiki_json_escape() {
    sed 's/\\/\\\\/g; s/"/\\"/g; s/	/\\t/g; s/\r/\\r/g' | awk 'BEGIN { ORS = "" } { if (NR > 1) printf "\\n"; printf "%s", $0 }'
}

_cwiki_log_debug() {
    [ "${CODEWIKI_HOOK_DEBUG:-}" = "1" ] || return 0
    mkdir -p "$_cwiki_state_dir" 2>/dev/null || return 0
    _cwiki_debug_stage=$(printf '%s' "$1" | _cwiki_json_escape)
    _cwiki_debug_stdin="${2:-unknown}"
    _cwiki_debug_stdout="${3:-false}"
    _cwiki_debug_wrapper_json="${4:-unknown}"
    _cwiki_debug_observable="${5:-unknown}"
    _cwiki_debug_message=$(printf '%s' "$6" | _cwiki_json_escape)
    _cwiki_debug_ts=$(date -u '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date '+%Y-%m-%dT%H:%M:%S%z')
    printf '{"timestamp":"%s","host":"%s","event":"%s","stage":"%s","stdin_payload":"%s","stdout_produced":%s,"wrapper_json":"%s","observable_context":"%s","message":"%s"}\n' \
        "$_cwiki_debug_ts" "$_cwiki_host" "$_cwiki_event" "$_cwiki_debug_stage" "$_cwiki_debug_stdin" "$_cwiki_debug_stdout" "$_cwiki_debug_wrapper_json" "$_cwiki_debug_observable" "$_cwiki_debug_message" >>"$_cwiki_debug_file" 2>/dev/null || true
}

if [ ! -f "$_cwiki_index" ]; then
    _cwiki_log_debug "called" unknown false unknown none "wiki index missing"
    exit 0
fi

if [ ! -t 0 ]; then
    _cwiki_has_stdin="true"
    _cwiki_input=$(cat 2>/dev/null) || _cwiki_input=""
else
    _cwiki_has_stdin="false"
fi

if [ -z "$_cwiki_input" ]; then
    _cwiki_log_debug "called" "$_cwiki_has_stdin" false unknown none "called without prompt payload"
    exit 0
fi

if ! printf '%s' "$_cwiki_input" | grep -Eiq 'codewiki|wiki|decision|decisão|architecture|arquitetura|history|histórico|historico|ingest|query|lint|absorb|absorver|source|fonte|schema'; then
    _cwiki_log_debug "filtered" "$_cwiki_has_stdin" false unknown none "prompt did not request wiki context"
    exit 0
fi

printf '## CodeWiki Context\n\n'
printf 'Relevant wiki index entries only; hooks are advisory and may not be delivered by every host.\n\n'

_cwiki_terms=$(printf '%s' "$_cwiki_input" | grep -oE '[A-Za-z][A-Za-z0-9_-]+' | sort -u | head -20) || _cwiki_terms=""
_cwiki_emitted=0

for _cwiki_term in $_cwiki_terms; do
    if grep -Fqi "$_cwiki_term" "$_cwiki_index" 2>/dev/null; then
        grep -Fi "$_cwiki_term" "$_cwiki_index" | sed -n '1,3p'
        _cwiki_emitted=$((_cwiki_emitted + 1))
    fi
    [ "$_cwiki_emitted" -ge 5 ] && break
done

if [ -f "$_cwiki_state_dir/pending-absorb.jsonl" ]; then
    _cwiki_pending_count=$(wc -l <"$_cwiki_state_dir/pending-absorb.jsonl" 2>/dev/null | tr -d ' ') || _cwiki_pending_count="0"
    if [ "$_cwiki_pending_count" != "0" ]; then
        printf '\nPending CodeWiki absorb signals: %s. Read .codewiki/state/pending-absorb.jsonl before absorb.\n' "$_cwiki_pending_count"
    fi
fi

_cwiki_log_debug "emitted" "$_cwiki_has_stdin" true unknown advisory "emitted short wiki context"
