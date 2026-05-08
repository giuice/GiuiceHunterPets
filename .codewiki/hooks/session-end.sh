#!/bin/sh
# codewiki: session-end hook
# Records a lightweight pending-absorb signal for current uncommitted changes.
# Always exits 0 so it never blocks the agent.

trap 'exit 0' EXIT
set -e

_cwiki_diff_stat=""
_cwiki_changed_files=""
_cwiki_state_dir=".codewiki/state"
_cwiki_pending_file="$_cwiki_state_dir/pending-absorb.jsonl"
_cwiki_dedupe_file="$_cwiki_state_dir/pending-absorb-dedupe.txt"
_cwiki_debug_file="$_cwiki_state_dir/hooks-debug.jsonl"
_cwiki_host="${CODEWIKI_HOOK_HOST:-unknown}"
_cwiki_event="${CODEWIKI_HOOK_EVENT:-session-end}"
_cwiki_state_exclude=":(exclude).codewiki/state/**"

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
    _cwiki_has_stdin="false"
else
    _cwiki_has_stdin="true"
fi

_cwiki_worktree_stat=$(git diff --stat -- . "$_cwiki_state_exclude" 2>/dev/null) || _cwiki_worktree_stat=""
_cwiki_worktree_files=$(git diff --name-only -- . "$_cwiki_state_exclude" 2>/dev/null) || _cwiki_worktree_files=""
_cwiki_cached_stat=$(git diff --cached --stat -- . "$_cwiki_state_exclude" 2>/dev/null) || _cwiki_cached_stat=""
_cwiki_cached_files=$(git diff --cached --name-only -- . "$_cwiki_state_exclude" 2>/dev/null) || _cwiki_cached_files=""

_cwiki_diff_stat=$(printf '%s\n%s\n' "$_cwiki_worktree_stat" "$_cwiki_cached_stat" | sed '/^$/d') || _cwiki_diff_stat=""
_cwiki_changed_files=$(printf '%s\n%s\n' "$_cwiki_worktree_files" "$_cwiki_cached_files" | sed '/^$/d' | sort -u) || _cwiki_changed_files=""
_cwiki_candidates=$(printf '%s\n' "$_cwiki_changed_files" |
    grep -E '(^|/)[A-Za-z0-9._-]+\.[A-Za-z0-9]+$' |
    sed 's#^.*/##; s#\.[^.]*$##; s#[_.]#-#g' |
    sort -u |
    sed -n '1,12p') || _cwiki_candidates=""

[ -z "$_cwiki_diff_stat" ] && {
    _cwiki_log_debug "called" "$_cwiki_has_stdin" false unknown none "no working tree or cached diff"
    exit 0
}

mkdir -p "$_cwiki_state_dir" 2>/dev/null || exit 0

_cwiki_ts=$(date -u '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date '+%Y-%m-%dT%H:%M:%S%z')
_cwiki_diff_hash=$(
    {
        git diff --no-ext-diff -- . "$_cwiki_state_exclude" 2>/dev/null || true
        git diff --cached --no-ext-diff -- . "$_cwiki_state_exclude" 2>/dev/null || true
    } | _cwiki_hash_stdin
) || _cwiki_diff_hash="unknown"
_cwiki_files_json=$(printf '%s\n' "$_cwiki_changed_files" | sed '/^$/d; 20q' | _cwiki_json_escape)
_cwiki_candidates_json=$(printf '%s\n' "$_cwiki_candidates" | sed '/^$/d' | _cwiki_json_escape)
_cwiki_stat_json=$(printf '%s\n' "$_cwiki_diff_stat" | sed '20q' | _cwiki_json_escape)
_cwiki_files_hash=$(printf '%s\n' "$_cwiki_changed_files" | sed '/^$/d; 20q' | _cwiki_hash_stdin) || _cwiki_files_hash="unknown"
_cwiki_dedupe_key=$(printf '%s\n%s\n%s\n%s\n' "$_cwiki_host" "$_cwiki_event" "$_cwiki_files_hash" "$_cwiki_diff_hash" | _cwiki_hash_stdin) || _cwiki_dedupe_key="unknown"

if [ -f "$_cwiki_dedupe_file" ] && grep -Fqx "$_cwiki_dedupe_key" "$_cwiki_dedupe_file" 2>/dev/null; then
    _cwiki_log_debug "deduped" "$_cwiki_has_stdin" false unknown state "duplicate session pending absorb signal suppressed"
    exit 0
fi

if printf '{"timestamp":"%s","source":"hook","host":"%s","event":"%s","reason":"session ended with uncommitted changes","files":"%s","topic_candidates":"%s","diff_stat":"%s","diff_hash":"%s"}\n' \
    "$_cwiki_ts" "$_cwiki_host" "$_cwiki_event" "$_cwiki_files_json" "$_cwiki_candidates_json" "$_cwiki_stat_json" "$_cwiki_diff_hash" >>"$_cwiki_pending_file" 2>/dev/null; then
    printf '%s\n' "$_cwiki_dedupe_key" >>"$_cwiki_dedupe_file" 2>/dev/null || true
fi

_cwiki_log_debug "recorded" "$_cwiki_has_stdin" false unknown state "recorded session pending absorb signal"
