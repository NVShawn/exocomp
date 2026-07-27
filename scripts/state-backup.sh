#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
# Create or restore protected Exocomp configuration, PKI, audit, and state.

set -euo pipefail
umask 077

ACTION="${1:-}"
if [[ $# -gt 0 ]]; then shift; fi
COMPONENT=""
ARCHIVE=""
FORCE=0
EXOCOMP_ROOT="${EXOCOMP_ROOT:-}"
EXOCOMP_SKIP_SYSTEMD="${EXOCOMP_SKIP_SYSTEMD:-0}"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --component) COMPONENT="${2:-}"; shift 2 ;;
        --output|--archive) ARCHIVE="${2:-}"; shift 2 ;;
        --force) FORCE=1; shift ;;
        *)
            echo "ERROR: unknown option: $1" >&2
            exit 2
            ;;
    esac
done

die() { echo "[state-backup] ERROR: $*" >&2; exit 1; }
log() { echo "[state-backup] $*"; }

if [[ "${ACTION}" != "create" && "${ACTION}" != "restore" ]]; then
    die "usage: $0 create|restore --component node|coordinator --output|--archive PATH [--force]"
fi
if [[ "${COMPONENT}" != "node" && "${COMPONENT}" != "coordinator" ]]; then
    die "--component must be node or coordinator"
fi
if [[ -z "${ARCHIVE}" ]]; then
    die "an --output or --archive path is required"
fi
if [[ -z "${EXOCOMP_ROOT}" && "$(id -u)" -ne 0 ]]; then
    die "must run as root"
fi

install_dir="${EXOCOMP_ROOT}/opt/exocomp/${COMPONENT}"
state_dir="${EXOCOMP_ROOT}/var/lib/exocomp-${COMPONENT}"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT HUP INT TERM
stage="${tmp_dir}/exocomp-state"

create_backup() {
    mkdir -p "${stage}"
    printf 'schema_version=1\ncomponent=%s\n' "${COMPONENT}" > "${stage}/metadata"

    for category in config log; do
        if [[ -d "${install_dir}/${category}" ]]; then
            cp -a "${install_dir}/${category}" "${stage}/${category}"
        fi
    done
    if [[ -d "${state_dir}" ]]; then
        cp -a "${state_dir}" "${stage}/state"
    fi

    mkdir -p "$(dirname "${ARCHIVE}")"
    tar -czf "${ARCHIVE}" -C "${tmp_dir}" exocomp-state
    chmod 600 "${ARCHIVE}"
    sha256sum "${ARCHIVE}" > "${ARCHIVE}.sha256"
    chmod 600 "${ARCHIVE}.sha256"
    log "created protected state backup: ${ARCHIVE}"
    log "store this archive encrypted; it may contain private keys and release credentials"
}

validate_archive() {
    [[ -f "${ARCHIVE}" ]] || die "archive not found: ${ARCHIVE}"
    if [[ -f "${ARCHIVE}.sha256" ]]; then
        (cd "$(dirname "${ARCHIVE}")" && sha256sum -c "$(basename "${ARCHIVE}.sha256")")
    fi

    while IFS= read -r entry; do
        case "${entry}" in
            exocomp-state|exocomp-state/*) ;;
            *) die "unsafe archive entry: ${entry}" ;;
        esac
        case "/${entry}/" in
            */../*) die "archive contains path traversal: ${entry}" ;;
        esac
    done < <(tar -tzf "${ARCHIVE}")

    # Preserve original file ownership during extraction so that restore_category
    # (which uses cp -a) propagates correct ownership to the destination.
    # Path safety is enforced by the entry-validation loop above; symlink
    # escape is enforced by the loop below.  The script requires root, so
    # --same-owner is always effective when needed.
    tar -xzf "${ARCHIVE}" -C "${tmp_dir}" --same-owner
    [[ -f "${stage}/metadata" ]] || die "backup metadata is missing"
    grep -qFx "schema_version=1" "${stage}/metadata" ||
        die "unsupported backup schema"
    grep -qFx "component=${COMPONENT}" "${stage}/metadata" ||
        die "backup component does not match ${COMPONENT}"

    while IFS= read -r link; do
        target="$(readlink -f "${link}")"
        case "${target}" in
            "${stage}"/*) ;;
            *) die "archive symlink escapes the backup root: ${link}" ;;
        esac
    done < <(find "${stage}" -type l)
}

restore_category() {
    local source="$1"
    local destination="$2"

    [[ -d "${source}" ]] || return
    if [[ -d "${destination}" && -n "$(find "${destination}" -mindepth 1 -print -quit)" && \
          "${FORCE}" -ne 1 ]]; then
        die "refusing to overwrite non-empty ${destination}; inspect it and pass --force"
    fi
    mkdir -p "${destination}"
    cp -a "${source}/." "${destination}/"
}

restore_backup() {
    validate_archive

    if [[ "${EXOCOMP_SKIP_SYSTEMD}" != "1" ]] && command -v systemctl >/dev/null 2>&1; then
        systemctl stop "exocomp-${COMPONENT}.service" || true
    fi

    restore_category "${stage}/config" "${install_dir}/config"
    restore_category "${stage}/log" "${install_dir}/log"
    restore_category "${stage}/state" "${state_dir}"
    log "restored protected state from ${ARCHIVE}"
    log "validate permissions and service health before starting exocomp-${COMPONENT}"
}

case "${ACTION}" in
    create) create_backup ;;
    restore) restore_backup ;;
esac
