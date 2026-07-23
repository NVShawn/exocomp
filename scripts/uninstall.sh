#!/usr/bin/env bash
# uninstall.sh — Hardened exocomp node/coordinator uninstaller.
#
# The uninstaller removes only exocomp-owned system resources recorded in
# the installed-file manifest.  Operator data is NEVER removed by default.
#
# Usage (run as root):
#   sudo bash scripts/uninstall.sh --component node [OPTIONS]
#
# OPTIONS
#   --component  node|coordinator     (required)
#   --version    VERSION              specific version to uninstall
#                                     (default: current installed version)
#   --purge      CATEGORY             remove extra data (may be repeated)
#                                     system-cache: old release dirs, downloaded files
#   --force                           skip confirmation prompts
#   --non-interactive                 never prompt (same as --force)
#   --dry-run                         show what would be removed; no host mutation
#
# PURGE CATEGORIES
#   system-cache   Removes versioned release directories other than the active
#                  version and any system-level download cache.
#                  Config, PKI, audit logs, and user data are NEVER touched.
#
# ALWAYS PRESERVED (regardless of --purge flags)
#   /opt/exocomp/<component>/config/  — operator configuration and PKI
#   /opt/exocomp/<component>/log/     — audit and service logs
#   /var/lib/exocomp-<component>/     — persistent operator state
#   User home directories and any files not listed in the manifest
#
# ENVIRONMENT OVERRIDES (for testing without root or systemd)
#   EXOCOMP_ROOT         Prefix prepended to /opt, /etc, /var paths (default: "")
#   EXOCOMP_SYSTEMD_DIR  Full path to systemd unit directory
#   EXOCOMP_SUDOERS_DIR  Full path to sudoers drop-in directory
#   EXOCOMP_SKIP_SYSTEMD Set to "1" to skip all systemctl calls

set -euo pipefail

# ── Defaults ──────────────────────────────────────────────────────────────────

COMPONENT=""
VERSION=""
PURGE_CATEGORIES=()
FORCE=0
NON_INTERACTIVE=0
DRY_RUN=0

EXOCOMP_ROOT="${EXOCOMP_ROOT:-}"
EXOCOMP_SKIP_SYSTEMD="${EXOCOMP_SKIP_SYSTEMD:-0}"
# When EXOCOMP_ROOT is non-empty we are in a test/sandbox environment.
EXOCOMP_SKIP_USERDEL="${EXOCOMP_SKIP_USERDEL:-${EXOCOMP_ROOT:+1}}"

# ── Argument parsing ───────────────────────────────────────────────────────────

while [[ $# -gt 0 ]]; do
    case "$1" in
        --component)      COMPONENT="$2";                 shift 2 ;;
        --version)        VERSION="$2";                   shift 2 ;;
        --purge)          PURGE_CATEGORIES+=("$2");       shift 2 ;;
        --force)          FORCE=1;                        shift   ;;
        --non-interactive) NON_INTERACTIVE=1; FORCE=1;   shift   ;;
        --dry-run)        DRY_RUN=1;                      shift   ;;
        *)
            echo "ERROR: Unknown option: $1" >&2
            echo "Usage: sudo bash $0 --component node|coordinator [OPTIONS]" >&2
            exit 1
            ;;
    esac
done

# ── Derived paths ──────────────────────────────────────────────────────────────

EXOCOMP_SYSTEMD_DIR="${EXOCOMP_SYSTEMD_DIR:-${EXOCOMP_ROOT}/etc/systemd/system}"
EXOCOMP_SUDOERS_DIR="${EXOCOMP_SUDOERS_DIR:-${EXOCOMP_ROOT}/etc/sudoers.d}"
INSTALL_BASE="${EXOCOMP_ROOT}/opt/exocomp"

# ── Helpers ───────────────────────────────────────────────────────────────────

log()  { echo "[uninstall] $*"; }
warn() { echo "[uninstall] WARN: $*" >&2; }
die()  { echo "[uninstall] ERROR: $*" >&2; exit 1; }

require_root() {
    # Skip root check when running in sandbox/test mode
    if [[ -n "${EXOCOMP_ROOT}" || "${EXOCOMP_SKIP_SYSTEMD}" == "1" ]]; then
        return
    fi
    if [[ "$(id -u)" -ne 0 ]]; then
        die "must be run as root (try: sudo $0)"
    fi
}

has_purge() {
    local category="$1"
    local c
    for c in "${PURGE_CATEGORIES[@]+${PURGE_CATEGORIES[@]}}"; do
        if [[ "${c}" == "${category}" ]]; then
            return 0
        fi
    done
    return 1
}

remove_if_exists() {
    local path="$1"
    if [[ "${DRY_RUN}" -eq 1 ]]; then
        if [[ -e "${path}" || -L "${path}" ]]; then
            log "  [dry-run] would remove: ${path}"
        fi
        return
    fi
    if [[ -L "${path}" ]]; then
        log "  rm -f ${path}  (symlink)"
        rm -f "${path}"
    elif [[ -f "${path}" ]]; then
        log "  rm -f ${path}"
        rm -f "${path}"
    elif [[ -d "${path}" ]]; then
        log "  rm -rf ${path}"
        rm -rf "${path}"
    fi
}

# ── Validation ────────────────────────────────────────────────────────────────

validate() {
    log "==> VALIDATION"

    if [[ -z "${COMPONENT}" ]]; then
        die "--component node|coordinator is required"
    fi
    if [[ "${COMPONENT}" != "node" && "${COMPONENT}" != "coordinator" ]]; then
        die "--component must be 'node' or 'coordinator'; got '${COMPONENT}'"
    fi

    local cat
    for cat in "${PURGE_CATEGORIES[@]+${PURGE_CATEGORIES[@]}}"; do
        if [[ "${cat}" != "system-cache" ]]; then
            die "unknown --purge category '${cat}'; supported: system-cache"
        fi
    done

    log "  component: ${COMPONENT}"
    log "  purge:     ${PURGE_CATEGORIES[*]:-none}"
    log "  dry-run:   ${DRY_RUN}"
}

# ── Discover installed version ────────────────────────────────────────────────

discover_version() {
    log "==> DISCOVER VERSION"

    local install_dir="${INSTALL_BASE}/${COMPONENT}"
    local current_link="${install_dir}/current"

    if [[ -n "${VERSION}" ]]; then
        log "  using specified version: ${VERSION}"
        return
    fi

    if [[ -L "${current_link}" ]]; then
        local target
        target="$(readlink "${current_link}")"
        VERSION="$(basename "${target}")"
        log "  current version: ${VERSION}"
    else
        # Try to find the newest manifest file
        local manifest_glob
        manifest_glob="${install_dir}/manifest-*.txt"
        local latest_manifest=""
        for f in ${manifest_glob}; do
            if [[ -f "${f}" ]]; then
                latest_manifest="${f}"
            fi
        done
        if [[ -n "${latest_manifest}" ]]; then
            VERSION="$(basename "${latest_manifest}" | sed 's/^manifest-//; s/\.txt$//')"
            log "  detected from manifest: ${VERSION}"
        else
            warn "cannot determine installed version; proceeding with partial uninstall"
        fi
    fi
}

# ── Phase 1: STOP SERVICE ────────────────────────────────────────────────────

stop_service() {
    log "==> STOP SERVICE"

    local unit_name="exocomp-${COMPONENT}"

    if [[ "${EXOCOMP_SKIP_SYSTEMD}" == "1" ]]; then
        log "  [skip-systemd] skipping service stop"
        return
    fi

    if [[ "${DRY_RUN}" -eq 1 ]]; then
        log "  [dry-run] would stop and disable ${unit_name}.service"
        return
    fi

    if ! command -v systemctl >/dev/null 2>&1; then
        warn "systemctl not found; skipping service stop"
        return
    fi

    if systemctl is-active --quiet "${unit_name}" 2>/dev/null; then
        log "  systemctl stop ${unit_name}"
        systemctl stop "${unit_name}" || true
    else
        log "  ${unit_name} is not running (skip stop)"
    fi

    if systemctl is-enabled --quiet "${unit_name}" 2>/dev/null; then
        log "  systemctl disable ${unit_name}"
        systemctl disable "${unit_name}" || true
    else
        log "  ${unit_name} is not enabled (skip disable)"
    fi
}

# ── Phase 2: REMOVE MANIFEST-LISTED FILES ────────────────────────────────────

remove_manifest_files() {
    log "==> REMOVE INSTALLED FILES"

    local install_dir="${INSTALL_BASE}/${COMPONENT}"
    local unit_name="exocomp-${COMPONENT}"
    local account="exocomp-${COMPONENT}"
    local manifest_file=""

    # Find manifest for the target version
    if [[ -n "${VERSION}" ]]; then
        manifest_file="${install_dir}/manifest-${VERSION}.txt"
    fi

    # Remove systemd unit
    remove_if_exists "${EXOCOMP_SYSTEMD_DIR}/${unit_name}.service"

    # Remove sudoers entry
    remove_if_exists "${EXOCOMP_SUDOERS_DIR}/${account}"

    # Remove current version symlink
    remove_if_exists "${install_dir}/current"

    # Remove versioned release directory (may be read-only from install)
    if [[ -n "${VERSION}" ]]; then
        local rel_dir="${install_dir}/releases/${VERSION}"
        if [[ -d "${rel_dir}" ]]; then
            chmod -R u+w "${rel_dir}" 2>/dev/null || true
        fi
        remove_if_exists "${rel_dir}"
    fi

    # Remove manifest file itself
    if [[ -n "${manifest_file}" && -f "${manifest_file}" ]]; then
        remove_if_exists "${manifest_file}"
    fi
}

# ── Phase 3: PURGE SYSTEM CACHE ──────────────────────────────────────────────

purge_system_cache() {
    if ! has_purge "system-cache"; then
        return
    fi

    log "==> PURGE SYSTEM CACHE"

    local install_dir="${INSTALL_BASE}/${COMPONENT}"
    local releases_dir="${install_dir}/releases"

    if [[ "${DRY_RUN}" -eq 1 ]]; then
        log "  [dry-run] would remove all release versions in ${releases_dir}"
        if [[ -d "${releases_dir}" ]]; then
            for d in "${releases_dir}"/*/; do
                log "  [dry-run] would remove: ${d}"
            done
        fi
        return
    fi

    # Remove all versioned release directories
    if [[ -d "${releases_dir}" ]]; then
        for d in "${releases_dir}"/*/; do
            if [[ -d "${d}" ]]; then
                # Make writable before removal (install sets a-w on release files)
                chmod -R u+w "${d}" 2>/dev/null || true
                log "  rm -rf ${d}"
                rm -rf "${d}"
            fi
        done
        # Remove now-empty releases dir
        rmdir "${releases_dir}" 2>/dev/null || true
    fi

    # Remove remaining manifests for old versions
    for f in "${install_dir}"/manifest-*.txt; do
        if [[ -f "${f}" ]]; then
            log "  rm -f ${f}"
            rm -f "${f}"
        fi
    done

    log "  system cache purged"
}

# ── Phase 4: RELOAD SYSTEMD ──────────────────────────────────────────────────

reload_systemd() {
    log "==> RELOAD SYSTEMD"

    if [[ "${EXOCOMP_SKIP_SYSTEMD}" == "1" ]]; then
        log "  [skip-systemd] skipping daemon-reload"
        return
    fi

    if [[ "${DRY_RUN}" -eq 1 ]]; then
        log "  [dry-run] would run systemctl daemon-reload"
        return
    fi

    if command -v systemctl >/dev/null 2>&1; then
        log "  systemctl daemon-reload"
        systemctl daemon-reload || true
    fi
}

# ── Phase 5: REPORT PRESERVED PATHS ─────────────────────────────────────────

report_preserved() {
    log "==> PRESERVED (operator state — NOT removed)"

    local install_dir="${INSTALL_BASE}/${COMPONENT}"
    local var_dir="${EXOCOMP_ROOT}/var/lib/exocomp-${COMPONENT}"

    for path in \
        "${install_dir}/config" \
        "${install_dir}/log" \
        "${var_dir}"
    do
        if [[ -d "${path}" ]]; then
            log "  ${path}"
        fi
    done

    if [[ ${#PURGE_CATEGORIES[@]} -eq 0 ]]; then
        log "  (use --purge categories to remove specific data classes)"
    fi
}

# ── Confirmation prompt ───────────────────────────────────────────────────────

confirm() {
    if [[ "${FORCE}" -eq 1 || "${DRY_RUN}" -eq 1 ]]; then
        return
    fi

    local account="exocomp-${COMPONENT}"
    local install_dir="${INSTALL_BASE}/${COMPONENT}"

    echo ""
    echo "About to uninstall exocomp-${COMPONENT}:"
    echo "  - Stop and disable ${account}.service"
    echo "  - Remove /etc/systemd/system/exocomp-${COMPONENT}.service"
    if [[ -n "${ALLOW_LIST:-}" ]]; then
        echo "  - Remove ${EXOCOMP_SUDOERS_DIR}/${account}"
    fi
    echo "  - Remove release files from ${install_dir}/releases/"
    echo ""
    echo "PRESERVED (not removed):"
    echo "  - ${install_dir}/config/  (PKI and configuration)"
    echo "  - ${install_dir}/log/     (audit logs)"
    echo ""

    if [[ "${NON_INTERACTIVE}" -eq 0 ]]; then
        read -r -p "Continue? [y/N] " answer
        case "${answer}" in
            [yY][eE][sS]|[yY]) ;;
            *) die "aborted by user" ;;
        esac
    fi
}

# ── Main ──────────────────────────────────────────────────────────────────────

main() {
    require_root
    validate
    discover_version
    confirm
    stop_service
    remove_manifest_files
    purge_system_cache
    reload_systemd
    report_preserved

    echo ""
    if [[ "${DRY_RUN}" -eq 1 ]]; then
        log "==> DRY RUN COMPLETE — no host mutations were made"
    else
        log "==> exocomp-${COMPONENT} uninstalled"
        log "    operator state preserved in ${INSTALL_BASE}/${COMPONENT}/config/"
    fi
}

main
