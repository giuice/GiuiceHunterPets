#!/usr/bin/env bash
set -euo pipefail

ADDON_NAME="GiuiceHunterPets"
DEFAULT_ADDONS_DIR="/mnt/M2Flash/Games/World of Warcraft/_retail_/Interface/AddOns"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

usage() {
  cat <<EOF
Usage:
  scripts/stage-addon.sh [wow-addons-dir-or-addon-dir]
  scripts/stage-addon.sh --stage [stage-dir-or-parent]

Examples:
  scripts/stage-addon.sh
  scripts/stage-addon.sh "/mnt/games/World of Warcraft/_retail_/Interface/AddOns"
  scripts/stage-addon.sh "admin:///mnt/M2Flash/Games/World of Warcraft/_retail_/Interface/AddOns/"
  scripts/stage-addon.sh --stage ~/Downloads

The default target is:
  ${DEFAULT_ADDONS_DIR}/${ADDON_NAME}

If a provided path does not end with ${ADDON_NAME}, the script creates/syncs a
${ADDON_NAME} subdirectory there.
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

require_rsync() {
  if ! command -v rsync >/dev/null 2>&1; then
    echo "Error: rsync is required but was not found in PATH." >&2
    exit 1
  fi
}

addon_dir_for() {
  local path="${1%/}"

  path="${path#admin://}"

  if [[ "$(basename -- "${path}")" == "${ADDON_NAME}" ]]; then
    printf '%s\n' "${path}"
  else
    printf '%s/%s\n' "${path}" "${ADDON_NAME}"
  fi
}

refuse_unsafe_existing_dir() {
  local path="$1"
  local label="$2"

  if [[ -d "${path}" && ! -f "${path}/${ADDON_NAME}.toc" ]]; then
    if [[ -n "$(find "${path}" -mindepth 1 -maxdepth 1 -print -quit)" ]]; then
      echo "Error: ${label} exists and is not a ${ADDON_NAME} addon folder: ${path}" >&2
      echo "Pass an empty directory, a parent directory, or an existing ${ADDON_NAME} folder." >&2
      exit 1
    fi
  fi
}

sync_runtime_files() {
  local source_dir="$1"
  local dest_dir="$2"

  mkdir -p "${dest_dir}"

  rsync -rt --delete \
    --no-perms --no-owner --no-group --omit-dir-times --modify-window=2 \
    --filter='+ /GiuiceHunterPets.toc' \
    --filter='+ /huntericon.blp' \
    --filter='+ /*.lua' \
    --filter='+ /*.xml' \
    --filter='+ /locales/***' \
    --filter='+ /icons/***' \
    --filter='+ /Libs/' \
    --filter='- /Libs/**/tests/***' \
    --filter='- /Libs/**/*.md' \
    --filter='- /Libs/**/*.txt' \
    --filter='- /Libs/**/*.toc' \
    --filter='+ /Libs/***' \
    --filter='- *' \
    "${source_dir}/" "${dest_dir}/"
}

ensure_writable_destination_parent() {
  local dest_dir="$1"
  local probe_dir
  local test_file
  local mount_options

  probe_dir="$(dirname -- "${dest_dir}")"
  while [[ ! -d "${probe_dir}" && "${probe_dir}" != "/" ]]; do
    probe_dir="$(dirname -- "${probe_dir}")"
  done

  test_file="$(mktemp "${probe_dir}/.${ADDON_NAME}.write-test.XXXXXX" 2>/dev/null || true)"
  if [[ -z "${test_file}" ]]; then
    mount_options="$(findmnt -n -T "${probe_dir}" -o OPTIONS 2>/dev/null || true)"
    echo "Error: cannot write to destination parent: ${probe_dir}" >&2
    if [[ -n "${mount_options}" ]]; then
      echo "Mount options: ${mount_options}" >&2
    fi
    echo "Remount the filesystem as read-write before syncing to WoW." >&2
    exit 1
  fi

  rm -f -- "${test_file}"
}

require_rsync

MODE="sync"
DEST_BASE="${1:-${DEFAULT_ADDONS_DIR}}"

if [[ "${1:-}" == "--stage" ]]; then
  MODE="stage"
  DEST_BASE="${2:-${HOME}/Downloads}"
  if [[ "$#" -gt 2 ]]; then
    usage >&2
    exit 1
  fi
elif [[ "$#" -gt 1 ]]; then
  usage >&2
  exit 1
fi

DEST_DIR="$(addon_dir_for "${DEST_BASE}")"

ensure_writable_destination_parent "${DEST_DIR}"
refuse_unsafe_existing_dir "${DEST_DIR}" "Destination directory"
sync_runtime_files "${ROOT_DIR}" "${DEST_DIR}"

if [[ "${MODE}" == "stage" ]]; then
  echo "Staged clean addon at: ${DEST_DIR}"
else
  echo "Synced addon to WoW: ${DEST_DIR}"
fi
