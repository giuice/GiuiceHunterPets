#!/bin/sh
# codewiki: session-end hook
# Outputs a lightweight summary of session changes for follow-up wiki absorption.
# Always exits 0 so it never blocks the agent.

trap 'exit 0' EXIT
set -e

_cwiki_diff_stat=""
_cwiki_changed_files=""

_cwiki_diff_stat=$(git diff --stat HEAD~1 2>/dev/null) || _cwiki_diff_stat=""
_cwiki_changed_files=$(git diff --name-only HEAD~1 2>/dev/null) || _cwiki_changed_files=""

if [ -z "$_cwiki_diff_stat" ]; then
    _cwiki_diff_stat=$(git diff --stat 2>/dev/null) || _cwiki_diff_stat=""
    _cwiki_changed_files=$(git diff --name-only 2>/dev/null) || _cwiki_changed_files=""
fi

if [ -z "$_cwiki_diff_stat" ]; then
    _cwiki_diff_stat=$(git diff --cached --stat 2>/dev/null) || _cwiki_diff_stat=""
    _cwiki_changed_files=$(git diff --cached --name-only 2>/dev/null) || _cwiki_changed_files=""
fi

[ -z "$_cwiki_diff_stat" ] && exit 0

printf 'CODEWIKI_SESSION_SUMMARY\n'
printf 'Changed files:\n%s\n' "$_cwiki_changed_files"
printf 'Diff summary:\n%s\n' "$_cwiki_diff_stat"
printf 'END_CODEWIKI_SESSION_SUMMARY\n'