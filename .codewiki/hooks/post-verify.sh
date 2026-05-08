#!/bin/sh
# codewiki: post-verify hook
# Records a small pending-absorb signal when modified files appear wiki-relevant.
# Always exits 0 so it never blocks the agent.

trap 'exit 0' EXIT
set -e

_cwiki_entities="wiki/entities"
_cwiki_payload=""
_cwiki_state_dir=".codewiki/state"
_cwiki_pending_file="$_cwiki_state_dir/pending-absorb.jsonl"
_cwiki_dedupe_file="$_cwiki_state_dir/pending-absorb-dedupe.txt"
_cwiki_debug_file="$_cwiki_state_dir/hooks-debug.jsonl"
_cwiki_host="${CODEWIKI_HOOK_HOST:-unknown}"
_cwiki_event="${CODEWIKI_HOOK_EVENT:-post-verify}"

_cwiki_json_escape() {
    sed 's/\\/\\\\/g; s/"/\\"/g; s/	/\\t/g; s/\r/\\r/g' | awk 'BEGIN { ORS = "" } { if (NR > 1) printf "\\n"; printf "%s", $0 }'
}

_cwiki_hash_stdin() {
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum | awk '{ print $1 }'
    elif command -v shasum >/dev/null 2>&1; then
        shasum -a 256 | awk '{ print $1 }'
    else
        cksum | awk '{ print $1 "-" $2 }'
    fi
}

_cwiki_material_payload() {
    if command -v jq >/dev/null 2>&1; then
        printf '%s' "$_cwiki_payload" | jq -cS '
            def scrub:
                if type == "object" then
                    with_entries(
                        select((.key | test("^(callId|call_id|toolCallId|tool_call_id|requestId|request_id|invocationId|invocation_id|sessionId|session_id|timestamp|durationMs|duration_ms)$"; "i")) | not)
                        | .value |= scrub
                    )
                elif type == "array" then
                    map(scrub)
                else
                    .
                end;
            scrub
        ' 2>/dev/null
        return
    fi

    printf '%s' "$_cwiki_payload" |
        grep -oE '"(diff|patch|changes|content|oldString|newString|old_string|new_string|before|after|output|result)"[ 	]*:[ 	]*"([^"\\]|\\.)*"' 2>/dev/null |
        sort
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

if [ -t 0 ]; then
    _cwiki_log_debug "called" false false unknown none "called without stdin payload"
    exit 0
fi

_cwiki_payload=$(cat 2>/dev/null) || _cwiki_payload=""

if [ -z "$_cwiki_payload" ]; then
    _cwiki_log_debug "called" true false unknown none "called with empty stdin payload"
    exit 0
fi

if command -v jq >/dev/null 2>&1; then
    _cwiki_files=$(printf '%s' "$_cwiki_payload" | jq -r '.. | strings' 2>/dev/null) || _cwiki_files=""
else
    _cwiki_files=$(printf '%s' "$_cwiki_payload" | grep -oE '"[^"]+\.[a-zA-Z0-9]+"' | tr -d '"') || _cwiki_files=""
fi

if [ -z "$_cwiki_files" ]; then
    _cwiki_log_debug "parsed" true false unknown none "payload contained no file-like strings"
    exit 0
fi

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

if [ -z "$_cwiki_matched" ] && [ -z "$_cwiki_candidates" ]; then
    _cwiki_log_debug "parsed" true false unknown none "no wiki-relevant file signal"
    exit 0
fi

mkdir -p "$_cwiki_state_dir" 2>/dev/null || exit 0

_cwiki_ts=$(date -u '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date '+%Y-%m-%dT%H:%M:%S%z')
_cwiki_normalized_files=$(printf '%s\n' "$_cwiki_files" | grep -E '(^|/)[A-Za-z0-9._/-]+\.[A-Za-z0-9]+$' | sort -u | sed -n '1,20p') || _cwiki_normalized_files=""
_cwiki_material=$(_cwiki_material_payload) || _cwiki_material=""
[ -n "$_cwiki_material" ] || _cwiki_material="$_cwiki_normalized_files"
_cwiki_payload_hash=$(printf '%s\n' "$_cwiki_material" | _cwiki_hash_stdin) || _cwiki_payload_hash="unknown"
_cwiki_files_json=$(printf '%s\n' "$_cwiki_normalized_files" | sed '/^$/d' | _cwiki_json_escape)
_cwiki_matched_json=$(printf '%b' "$_cwiki_matched" | sed '/^$/d' | _cwiki_json_escape)
_cwiki_candidates_json=$(printf '%s\n' "$_cwiki_candidates" | sed '/^$/d' | _cwiki_json_escape)
_cwiki_files_hash=$(printf '%s\n' "$_cwiki_normalized_files" | _cwiki_hash_stdin) || _cwiki_files_hash="unknown"
_cwiki_dedupe_key=$(printf '%s\n%s\n%s\n%s\n' "$_cwiki_host" "$_cwiki_event" "$_cwiki_files_hash" "$_cwiki_payload_hash" | _cwiki_hash_stdin) || _cwiki_dedupe_key="unknown"

if [ -f "$_cwiki_dedupe_file" ] && grep -Fqx "$_cwiki_dedupe_key" "$_cwiki_dedupe_file" 2>/dev/null; then
    _cwiki_log_debug "deduped" true false unknown state "duplicate pending absorb signal suppressed"
    exit 0
fi

if printf '{"timestamp":"%s","source":"hook","host":"%s","event":"%s","reason":"wiki-relevant file change","files":"%s","matched_entities":"%s","topic_candidates":"%s","payload_hash":"%s"}\n' \
    "$_cwiki_ts" "$_cwiki_host" "$_cwiki_event" "$_cwiki_files_json" "$_cwiki_matched_json" "$_cwiki_candidates_json" "$_cwiki_payload_hash" >>"$_cwiki_pending_file" 2>/dev/null; then
    printf '%s\n' "$_cwiki_dedupe_key" >>"$_cwiki_dedupe_file" 2>/dev/null || true
fi

_cwiki_log_debug "recorded" true false unknown state "recorded pending absorb signal"
