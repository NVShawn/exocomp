#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
# install.sh — Hardened exocomp node/coordinator installer.
#
# Run from inside an extracted exocomp release bundle as root:
#
#   sudo bash scripts/install.sh --component node [OPTIONS]
#
# OPTIONS
#   --component  node|coordinator         (required)
#   --bundle     PATH                     release archive (.tar.gz)
#                                         default: auto-detect from bundle directory
#   --checksums  PATH                     SHA-256 checksums file
#                                         default: <bundle-dir>/manifest.sha256
#   --version    VERSION                  override version detected from archive
#   --allow-list SVC1,SVC2,...            comma-separated systemd service names
#                                         granted in the sudoers policy
#                                         (empty = no privileged service entries)
#   --no-start                            install but do not start the service
#   --non-interactive                     never prompt; fail on ambiguity
#   --dry-run                             validate only, no host mutation
#
# ENVIRONMENT OVERRIDES (for testing without root or systemd)
#   EXOCOMP_ROOT         Prefix prepended to /opt, /etc, /var paths (default: "")
#   EXOCOMP_SYSTEMD_DIR  Full path to systemd unit directory
#                        (default: ${EXOCOMP_ROOT}/etc/systemd/system)
#   EXOCOMP_SUDOERS_DIR  Full path to sudoers drop-in directory
#                        (default: ${EXOCOMP_ROOT}/etc/sudoers.d)
#   EXOCOMP_SKIP_SYSTEMD Set to "1" to skip all systemctl calls
#   EXOCOMP_SKIP_VISUDO  Set to "1" to skip visudo validation
#   EXOCOMP_HEALTHCHECK_COMMAND
#                        Optional operator health command. It must exit zero
#                        only when application health is ready.
#   EXOCOMP_ROLLBACK_HEALTHCHECK_ATTEMPTS
#                        Restored-release probe attempts (default: 10).
#   EXOCOMP_ROLLBACK_HEALTHCHECK_INTERVAL
#                        Seconds between restored-release probes (default: 2).
#   EXOCOMP_CONFIG_VALIDATOR_COMMAND
#                        Optional config validator used by qualification tests.

set -euo pipefail

# ── Defaults ──────────────────────────────────────────────────────────────────

COMPONENT=""
BUNDLE=""
CHECKSUMS_FILE=""
VERSION=""
ALLOW_LIST=""
NO_START=0
NON_INTERACTIVE=0
DRY_RUN=0

EXOCOMP_ROOT="${EXOCOMP_ROOT:-}"
EXOCOMP_SKIP_SYSTEMD="${EXOCOMP_SKIP_SYSTEMD:-0}"
EXOCOMP_SKIP_VISUDO="${EXOCOMP_SKIP_VISUDO:-0}"
EXOCOMP_HEALTHCHECK_COMMAND="${EXOCOMP_HEALTHCHECK_COMMAND:-}"
EXOCOMP_CONFIG_VALIDATOR_COMMAND="${EXOCOMP_CONFIG_VALIDATOR_COMMAND:-}"
EXOCOMP_HEALTHCHECK_ATTEMPTS="${EXOCOMP_HEALTHCHECK_ATTEMPTS:-10}"
EXOCOMP_HEALTHCHECK_INTERVAL="${EXOCOMP_HEALTHCHECK_INTERVAL:-2}"
EXOCOMP_ROLLBACK_HEALTHCHECK_ATTEMPTS="${EXOCOMP_ROLLBACK_HEALTHCHECK_ATTEMPTS:-10}"
EXOCOMP_ROLLBACK_HEALTHCHECK_INTERVAL="${EXOCOMP_ROLLBACK_HEALTHCHECK_INTERVAL:-2}"
# When EXOCOMP_ROOT is non-empty we are in a test/sandbox environment; skip
# operations that require real root: useradd, chown.
EXOCOMP_SKIP_USERADD="${EXOCOMP_SKIP_USERADD:-${EXOCOMP_ROOT:+1}}"
EXOCOMP_SKIP_CHOWN="${EXOCOMP_SKIP_CHOWN:-${EXOCOMP_ROOT:+1}}"

# Resolve script and bundle directories.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUNDLE_ROOT="$(dirname "${SCRIPT_DIR}")"

# ── Argument parsing ───────────────────────────────────────────────────────────

while [[ $# -gt 0 ]]; do
    case "$1" in
        --component)      COMPONENT="$2";      shift 2 ;;
        --bundle)         BUNDLE="$2";         shift 2 ;;
        --checksums)      CHECKSUMS_FILE="$2"; shift 2 ;;
        --version)        VERSION="$2";        shift 2 ;;
        --allow-list)     ALLOW_LIST="$2";     shift 2 ;;
        --no-start)       NO_START=1;          shift   ;;
        --non-interactive) NON_INTERACTIVE=1;  shift   ;;
        --dry-run)        DRY_RUN=1;           shift   ;;
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
PREVIOUS_TARGET=""
UPGRADE_SWITCHED=0

# ── Helpers ───────────────────────────────────────────────────────────────────

log()  { echo "[install] $*"; }
warn() { echo "[install] WARN: $*" >&2; }
die()  { echo "[install] ERROR: $*" >&2; exit 1; }

require_root() {
    # Skip root check when running in sandbox/test mode
    if [[ -n "${EXOCOMP_ROOT}" || "${EXOCOMP_SKIP_SYSTEMD}" == "1" ]]; then
        return
    fi
    if [[ "$(id -u)" -ne 0 ]]; then
        die "must be run as root (try: sudo $0)"
    fi
}

# Wrapper for chown: no-op in test/sandbox mode
do_chown() {
    if [[ "${EXOCOMP_SKIP_CHOWN}" == "1" ]]; then
        return
    fi
    chown "$@"
}

# Wrapper for chmod: always runs (no privilege required)
do_chmod() {
    chmod "$@"
}

# Render exact sudoers policy for the given account and allow-list.
# Matches the format generated by Exocomp.Node.SudoersPolicy.
render_sudoers() {
    local account="$1"
    local allow_list="$2"  # comma-separated service names
    local vacuum_size="${3:-100M}"
    local profile_helper_path="${4:-}"  # optional path to profile-action-helper

    # Validate account: alphanumeric + underscore + hyphen, starting with letter/underscore
    if ! echo "${account}" | grep -qE '^[a-zA-Z_][a-zA-Z0-9_-]*$'; then
        die "invalid account name for sudoers: '${account}'"
    fi

    local entries=()

    # Add exact entry for profile-action-helper if provided
    # This grants ONLY the exact helper path with no arguments
    if [[ -n "${profile_helper_path}" ]]; then
        entries+=("${profile_helper_path}")
    fi

    # Add restart entries for each allow-listed service
    if [[ -n "${allow_list}" ]]; then
        IFS=',' read -ra services <<< "${allow_list}"
        for svc in "${services[@]}"; do
            svc="$(echo "${svc}" | tr -d '[:space:]')"
            # Validate service name: alphanumeric + hyphen + underscore + dot + @ only
            # Must start with alphanumeric; optional .service suffix
            if ! echo "${svc}" | grep -qE '^[a-zA-Z0-9][a-zA-Z0-9._@-]*(.service)?$'; then
                die "invalid service name for sudoers: '${svc}'"
            fi
            entries+=("/usr/bin/systemctl restart ${svc}")
        done
    fi

    # Add vacuum entry
    entries+=("/usr/bin/journalctl --vacuum-size=${vacuum_size}")

    if [[ ${#entries[@]} -eq 0 ]]; then
        echo ""
        return
    fi

    cat <<SUDOERS_HEADER
# Exocomp node sudoers policy
# Generated for account: ${account}
# DO NOT EDIT — regenerate from the installed action catalog.
# Validate with: visudo -c -f ${EXOCOMP_SUDOERS_DIR}/${account}
# The hardened service has no login session.  Keep command authorization and
# sudo auditing enabled while avoiding PAM session setup from that sandbox.
Defaults:${account} !pam_session
SUDOERS_HEADER

    for entry in "${entries[@]}"; do
        echo "${account} ALL=(root) NOPASSWD: ${entry}"
    done
}

# Write file contents only if in non-dry-run mode.
install_file() {
    local content="$1"
    local dest="$2"
    local mode="${3:-644}"
    if [[ "${DRY_RUN}" -eq 1 ]]; then
        log "  [dry-run] would write ${dest} (mode ${mode})"
        return
    fi
    mkdir -p "$(dirname "${dest}")"
    printf '%s' "${content}" > "${dest}"
    chmod "${mode}" "${dest}"
}

# ── Phase 1: PREFLIGHT (no host mutation) ────────────────────────────────────

preflight() {
    log "==> PREFLIGHT"

    # 1a. Validate required --component flag
    if [[ -z "${COMPONENT}" ]]; then
        die "--component node|coordinator is required"
    fi
    if [[ "${COMPONENT}" != "node" && "${COMPONENT}" != "coordinator" ]]; then
        die "--component must be 'node' or 'coordinator'; got '${COMPONENT}'"
    fi

    # 1b. Determine release archive
    if [[ -z "${BUNDLE}" ]]; then
        # Auto-detect: look in the delivered releases/ directory first, then
        # retain compatibility with older development bundle roots.
        local matches
        matches=("${BUNDLE_ROOT}"/releases/exocomp-"${COMPONENT}"-*.tar.gz)
        if [[ ${#matches[@]} -eq 0 ]] || [[ ! -f "${matches[0]}" ]]; then
            matches=("${BUNDLE_ROOT}"/exocomp-"${COMPONENT}"-*.tar.gz)
        fi
        if [[ ${#matches[@]} -eq 0 ]] || [[ ! -f "${matches[0]}" ]]; then
            die "no release archive found in ${BUNDLE_ROOT}; pass --bundle PATH"
        fi
        if [[ ${#matches[@]} -gt 1 ]]; then
            die "multiple release archives found; pass --bundle PATH to choose one"
        fi
        BUNDLE="${matches[0]}"
    fi
    if [[ ! -f "${BUNDLE}" ]]; then
        die "bundle not found: ${BUNDLE}"
    fi
    log "  bundle:    ${BUNDLE}"

    # 1c. Determine version from archive name if not given
    if [[ -z "${VERSION}" ]]; then
        VERSION="$(basename "${BUNDLE}" | sed -E 's/^exocomp-[^-]+-(.+)-linux-(amd64|arm64)\.tar\.gz$/\1/' 2>/dev/null || true)"
        if [[ -z "${VERSION}" ]]; then
            die "cannot determine version from archive name; pass --version VERSION"
        fi
    fi
    # Validate the complete value before using it as a directory name.
    if ! echo "${VERSION}" |
        grep -qE '^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?(\+[0-9A-Za-z.-]+)?$'; then
        die "invalid version '${VERSION}'; expected semver (e.g. 1.2.3)"
    fi
    log "  version:   ${VERSION}"
    log "  component: ${COMPONENT}"
    check_peer_compatibility

    # 1d. Validate host architecture
    local arch
    arch="$(uname -m)"
    if [[ "${arch}" != "x86_64" && "${arch}" != "aarch64" ]]; then
        die "unsupported architecture '${arch}'; supported: x86_64, aarch64"
    fi
    log "  arch:      ${arch}"

    # 1e. Validate checksums
    if [[ -z "${CHECKSUMS_FILE}" ]]; then
        CHECKSUMS_FILE="${BUNDLE_ROOT}/manifest.sha256"
    fi
    if [[ ! -f "${CHECKSUMS_FILE}" ]]; then
        # Warn but allow if no checksums file (e.g. dev install)
        warn "checksums file not found: ${CHECKSUMS_FILE} (skipping verification)"
    else
        log "  checksums: ${CHECKSUMS_FILE}"
        verify_checksums
    fi

    # 1f. Check available disk space (require 2 GiB free in install base)
    local install_dir
    install_dir="$(dirname "${INSTALL_BASE}")"
    if ! check_disk_space "${install_dir}" 2147483648; then
        die "insufficient disk space; need at least 2 GiB free in ${install_dir}"
    fi

    # 1g. Check systemd availability
    if [[ "${EXOCOMP_SKIP_SYSTEMD}" != "1" ]]; then
        if ! command -v systemctl >/dev/null 2>&1; then
            die "systemctl not found; run inside a system with systemd as PID 1"
        fi
        if ! systemctl is-system-running --quiet 2>/dev/null && \
           ! systemctl status --quiet 2>/dev/null; then
            warn "systemd may not be fully running (booting or degraded)"
        fi
    fi

    # 1h. Verify systemd unit template exists in bundle
    local unit_template="${BUNDLE_ROOT}/release/${COMPONENT}/exocomp-${COMPONENT}.service"
    if [[ ! -f "${unit_template}" ]]; then
        die "systemd unit template not found in bundle: ${unit_template}"
    fi
    [[ -x "${BUNDLE_ROOT}/scripts/state-backup.sh" ]] ||
        die "state backup utility not found in bundle: ${BUNDLE_ROOT}/scripts/state-backup.sh"

    # 1i. A delivered node llama runtime is an atomic payload: the relocatable
    # launcher and its executable must both be present before host mutation.
    if [[ "${COMPONENT}" == "node" && -e "${BUNDLE_ROOT}/llama-server" ]]; then
        [[ -x "${BUNDLE_ROOT}/llama-server" ]] ||
            die "bundled llama-server launcher is not executable"
        [[ -x "${BUNDLE_ROOT}/llama-server.bin" ]] ||
            die "bundled llama-server executable is missing: ${BUNDLE_ROOT}/llama-server.bin"
    fi

    log "  preflight passed"
}

check_peer_compatibility() {
    local peer
    if [[ "${COMPONENT}" == "node" ]]; then
        peer="coordinator"
    else
        peer="node"
    fi

    local peer_current="${INSTALL_BASE}/${peer}/current"
    if [[ ! -L "${peer_current}" ]]; then
        return
    fi

    local peer_version
    peer_version="$(basename "$(readlink "${peer_current}")")"
    local requested_major="${VERSION%%.*}"
    local peer_major="${peer_version%%.*}"

    if [[ "${requested_major}" != "${peer_major}" ]]; then
        die "incompatible ${COMPONENT} ${VERSION}: installed ${peer} ${peer_version} uses a different major protocol version"
    fi
    log "  peer:      ${peer} ${peer_version} (compatible major version)"
}

verify_checksums() {
    log "  verifying checksums..."
    local bundle_basename
    bundle_basename="$(basename "${BUNDLE}")"

    # Extract relevant line from checksums file
    local expected_line
    expected_line="$(grep -F "${bundle_basename}" "${CHECKSUMS_FILE}" 2>/dev/null || true)"
    if [[ -z "${expected_line}" ]]; then
        die "no checksum entry for '${bundle_basename}' in ${CHECKSUMS_FILE}"
    fi

    # Compute actual checksum
    local actual_hash
    actual_hash="$(sha256sum "${BUNDLE}" | awk '{print $1}')"
    local expected_hash
    expected_hash="$(echo "${expected_line}" | awk '{print $1}')"

    if [[ "${actual_hash}" != "${expected_hash}" ]]; then
        die "checksum MISMATCH for ${bundle_basename}
         expected: ${expected_hash}
         actual:   ${actual_hash}"
    fi
    log "  checksum OK: ${actual_hash}"
}

check_disk_space() {
    local dir="$1"
    local required_bytes="$2"

    # Create dir if it doesn't exist yet (for check purposes only)
    local check_dir="${dir}"
    while [[ ! -d "${check_dir}" ]]; do
        check_dir="$(dirname "${check_dir}")"
    done

    local available_bytes
    available_bytes="$(df --output=avail -B1 "${check_dir}" 2>/dev/null | tail -1 | tr -d '[:space:]' || echo "0")"
    if [[ "${available_bytes}" -ge "${required_bytes}" ]]; then
        return 0
    else
        return 1
    fi
}

# ── Phase 2: USER AND DIRECTORY SETUP ─────────────────────────────────────────

setup_users_and_dirs() {
    log "==> USERS AND DIRECTORIES"

    local account="exocomp-${COMPONENT}"
    local install_dir="${INSTALL_BASE}/${COMPONENT}"
    local releases_dir="${install_dir}/releases"
    local config_dir="${install_dir}/config"
    local log_dir="${install_dir}/log"
    local pki_dir="${config_dir}/pki"
    local var_dir="${EXOCOMP_ROOT}/var/lib/exocomp-${COMPONENT}"

    if [[ "${DRY_RUN}" -eq 1 ]]; then
        log "  [dry-run] would create user ${account} and directories"
        return
    fi

    # Create dedicated system user if not exists
    if [[ "${EXOCOMP_SKIP_USERADD}" == "1" ]]; then
        log "  [skip-useradd] skipping system user creation (test/sandbox mode)"
    elif ! id "${account}" >/dev/null 2>&1; then
        log "  creating system user: ${account}"
        useradd \
            --system \
            --no-create-home \
            --shell /usr/sbin/nologin \
            --comment "exocomp ${COMPONENT} service account" \
            "${account}"
    else
        log "  user exists: ${account}"
    fi

    # Create directory structure
    log "  creating directories"
    mkdir -p "${releases_dir}"
    mkdir -p "${config_dir}"
    mkdir -p "${log_dir}"
    mkdir -p "${pki_dir}"
    mkdir -p "${var_dir}"

    # Set ownership and permissions. Do not recursively chown install_dir:
    # config/ and log/ contain protected service-owned state that must retain
    # its ownership across upgrades.
    do_chown root:root "${install_dir}"
    do_chown root:root "${releases_dir}"
    do_chown "${account}:${account}" "${config_dir}"
    do_chown "${account}:${account}" "${log_dir}"
    do_chown "${account}:${account}" "${pki_dir}"
    do_chown "${account}:${account}" "${var_dir}"

    # Strict permissions
    do_chmod 755  "${install_dir}"
    do_chmod 755  "${releases_dir}"
    do_chmod 750  "${config_dir}"
    do_chmod 750  "${log_dir}"
    do_chmod 700  "${pki_dir}"
    do_chmod 750  "${var_dir}"

    log "  directories configured"
}

# ── Phase 3: INSTALL RELEASE ──────────────────────────────────────────────────

install_release() {
    log "==> INSTALL RELEASE"

    local account="exocomp-${COMPONENT}"
    local install_dir="${INSTALL_BASE}/${COMPONENT}"
    local versioned_dir="${install_dir}/releases/${VERSION}"
    local current_link="${install_dir}/current"
    local staging_dir="${install_dir}/releases/.staging-${VERSION}.$$"

    if [[ "${DRY_RUN}" -eq 1 ]]; then
        log "  [dry-run] would extract ${BUNDLE} to ${versioned_dir}"
        return
    fi

    if [[ -L "${current_link}" ]]; then
        PREVIOUS_TARGET="$(readlink "${current_link}")"
        log "  previous current target: ${PREVIOUS_TARGET}"
    fi

    # Check for existing version (idempotent: overwrite if same version)
    if [[ -d "${versioned_dir}" ]]; then
        log "  version ${VERSION} already installed; overwriting"
        # Make writable before removal (previous install set a-w on contents)
        chmod -R u+w "${versioned_dir}" 2>/dev/null || true
        rm -rf "${versioned_dir}"
    fi

    # Extract into a private staging path, then rename only after tar succeeds.
    # An interrupted or malformed extraction can never become current.
    log "  extracting ${BUNDLE}"
    rm -rf "${staging_dir}"
    mkdir -p "${staging_dir}"
    if ! tar -xzf "${BUNDLE}" -C "${staging_dir}" --strip-components=1; then
        rm -rf "${staging_dir}"
        die "release extraction failed; current version was not changed"
    fi

    # The llama runtime is delivered alongside the OTP archives because it is
    # shared release input, but a node must receive it in the same versioned
    # directory as the release. Keeping this copy in staging preserves the
    # installer's atomic rollback boundary.
    if [[ "${COMPONENT}" == "node" && -x "${BUNDLE_ROOT}/llama-server" ]]; then
        mkdir -p "${staging_dir}/bin" "${staging_dir}/lib/llama"
        cp -f "${BUNDLE_ROOT}/llama-server" "${staging_dir}/bin/llama-server"
        cp -f "${BUNDLE_ROOT}/llama-server.bin" "${staging_dir}/bin/llama-server.bin"
        if [[ -d "${BUNDLE_ROOT}/lib/llama" ]]; then
            cp -a "${BUNDLE_ROOT}/lib/llama/." "${staging_dir}/lib/llama/"
        fi
        chmod 755 \
            "${staging_dir}/bin/llama-server" \
            "${staging_dir}/bin/llama-server.bin"
        log "  staged bundled llama-server runtime"
    fi

    cp -f \
        "${BUNDLE_ROOT}/scripts/state-backup.sh" \
        "${staging_dir}/bin/exocomp-state-backup"
    chmod 755 "${staging_dir}/bin/exocomp-state-backup"
    log "  staged protected-state backup utility"

    mv -f "${staging_dir}" "${versioned_dir}"

    # Set ownership: root owns the release; service account has read access
    do_chown -R root:root "${versioned_dir}"
    # Lock down release files: no write access except to root owner.
    # chmod does not require root so we always apply it.
    chmod -R a-w "${versioned_dir}"   # No write access to release files
    chmod -R o+rX "${versioned_dir}"  # Others can read/traverse

    # Make release entrypoints executable
    if [[ -d "${versioned_dir}/bin" ]]; then
        chmod -R a+rX "${versioned_dir}/bin"
    fi

    log "  release ${VERSION} staged"
}

# ── Phase 3b: INSTALL PROFILE-ACTION HELPER ──────────────────────────────────

install_profile_action_helper() {
    log "==> PROFILE-ACTION HELPER"

    local account="exocomp-${COMPONENT}"
    local install_dir="${INSTALL_BASE}/${COMPONENT}"
    local bin_dir="${install_dir}/bin"
    local helper_dest="${bin_dir}/profile-action-helper"
    local helper_src="${BUNDLE_ROOT}/bin/profile-action-helper"

    if [[ ! -f "${helper_src}" ]]; then
        log "  profile-action-helper not found in bundle; skipping"
        return
    fi

    if [[ "${DRY_RUN}" -eq 1 ]]; then
        log "  [dry-run] would install helper to ${helper_dest}"
        return
    fi

    mkdir -p "${bin_dir}"
    cp -f "${helper_src}" "${helper_dest}"
    chmod 755 "${helper_dest}"
    do_chown root:root "${helper_dest}"

    log "  helper installed: ${helper_dest}"
}

# ── Phase 4: CONFIGURATION TEMPLATE ──────────────────────────────────────────

install_config() {
    log "==> CONFIGURATION"

    local install_dir="${INSTALL_BASE}/${COMPONENT}"
    local config_dir="${install_dir}/config"
    local config_file="${config_dir}/${COMPONENT}.json"
    local template_src="${BUNDLE_ROOT}/release/templates/${COMPONENT}.json"

    if [[ ! -f "${template_src}" ]]; then
        die "config template not found in bundle: ${template_src}"
    fi

    if [[ "${DRY_RUN}" -eq 1 ]]; then
        log "  [dry-run] would install config template to ${config_file}"
        return
    fi

    if [[ -f "${config_file}" ]]; then
        log "  config exists; preserving (not overwriting): ${config_file}"
    else
        log "  installing config template: ${config_file}"
        sed -e "s|@INSTALL_DIR@|${install_dir}|g" "${template_src}" > "${config_file}"
        do_chown "exocomp-${COMPONENT}:exocomp-${COMPONENT}" "${config_file}"
        do_chmod 640 "${config_file}"
    fi
}

install_release_cookie() {
    log "==> RELEASE COOKIE"

    local install_dir="${INSTALL_BASE}/${COMPONENT}"
    local cookie_file="${install_dir}/config/release-cookie.env"

    if [[ "${DRY_RUN}" -eq 1 ]]; then
        log "  [dry-run] would provision protected RELEASE_COOKIE environment"
        return
    fi

    if [[ -f "${cookie_file}" ]]; then
        log "  release cookie exists; preserving across upgrade"
        return
    fi

    local cookie
    if command -v openssl >/dev/null 2>&1; then
        cookie="$(openssl rand -hex 32)"
    else
        cookie="$(od -An -N32 -tx1 /dev/urandom | tr -d ' \n')"
    fi

    if ! echo "${cookie}" | grep -Eq '^[0-9a-f]{64}$'; then
        die "failed to generate cryptographically random release cookie"
    fi

    printf 'RELEASE_COOKIE=%s\n' "${cookie}" > "${cookie_file}"
    do_chmod 600 "${cookie_file}"
    do_chown "exocomp-${COMPONENT}:exocomp-${COMPONENT}" "${cookie_file}"
    log "  protected release cookie provisioned"
}

validate_config() {
    log "==> CONFIG VALIDATION"

    if [[ "${DRY_RUN}" -eq 1 ]]; then
        log "  [dry-run] would validate configuration with staged release"
        return
    fi

    local install_dir="${INSTALL_BASE}/${COMPONENT}"
    local config_file="${install_dir}/config/${COMPONENT}.json"
    local release_bin="${install_dir}/releases/${VERSION}/bin/exocomp_${COMPONENT}"

    if [[ -n "${EXOCOMP_CONFIG_VALIDATOR_COMMAND}" ]]; then
        if EXOCOMP_CONFIG_FILE="${config_file}" bash -c "${EXOCOMP_CONFIG_VALIDATOR_COMMAND}"; then
            log "  operator config validator passed"
            return
        fi
        die "configuration validation failed; current version was not changed"
    fi

    if [[ ! -x "${release_bin}" ]]; then
        die "staged release entrypoint is missing: ${release_bin}"
    fi

    local config_module
    if [[ "${COMPONENT}" == "node" ]]; then
        config_module="Exocomp.Node.Config"
    else
        config_module="Exocomp.Coordinator.Config"
    fi

    if EXOCOMP_VALIDATE_CONFIG="${config_file}" \
       RELEASE_COOKIE="install-validation-only-cookie" \
       "${release_bin}" eval "
         path = System.fetch_env!(\"EXOCOMP_VALIDATE_CONFIG\")
         case ${config_module}.load(path) do
           {:ok, _config} -> System.halt(0)
           {:error, _reason} -> System.halt(1)
         end
       "; then
        log "  staged release accepted configuration"
    else
        die "configuration validation failed; current version was not changed"
    fi
}

switch_current() {
    log "==> CURRENT VERSION SWITCH"

    local install_dir="${INSTALL_BASE}/${COMPONENT}"
    local current_link="${install_dir}/current"

    if [[ "${DRY_RUN}" -eq 1 ]]; then
        log "  [dry-run] would switch current -> releases/${VERSION}"
        return
    fi

    if [[ "${NO_START}" -eq 1 && -n "${PREVIOUS_TARGET}" ]]; then
        log "  --no-start stages upgrades without changing current"
        return
    fi

    local tmp_link="${current_link}.new.$$"
    ln -sf "releases/${VERSION}" "${tmp_link}"
    # GNU mv's no-target-directory replacement is one rename(2), so readers
    # see either the old or new symlink and never a missing current path.
    mv -Tf "${tmp_link}" "${current_link}"
    UPGRADE_SWITCHED=1
    log "  current -> releases/${VERSION}"
}

# ── Phase 5: SUDOERS POLICY ───────────────────────────────────────────────────

install_sudoers() {
    log "==> SUDOERS POLICY"

    local account="exocomp-${COMPONENT}"
    local install_dir="${INSTALL_BASE}/${COMPONENT}"
    local helper_path="${install_dir}/bin/profile-action-helper"
    local sudoers_dest="${EXOCOMP_SUDOERS_DIR}/${account}"
    local policy
    
    # Only include profile-action-helper path in sudoers for node component
    if [[ "${COMPONENT}" == "node" && -f "${install_dir}/bin/profile-action-helper" ]]; then
        policy="$(render_sudoers "${account}" "${ALLOW_LIST}" "100M" "${helper_path}")"
    else
        policy="$(render_sudoers "${account}" "${ALLOW_LIST}")"
    fi

    if [[ -z "${policy}" ]]; then
        log "  allow-list is empty; no sudoers entries installed"
        # Remove any existing stale policy file
        if [[ "${DRY_RUN}" -ne 1 ]] && [[ -f "${sudoers_dest}" ]]; then
            log "  removing stale sudoers file: ${sudoers_dest}"
            rm -f "${sudoers_dest}"
        fi
        return
    fi

    if [[ "${DRY_RUN}" -eq 1 ]]; then
        log "  [dry-run] would write sudoers policy:"
        echo "${policy}" | sed 's/^/    /'
        return
    fi

    mkdir -p "${EXOCOMP_SUDOERS_DIR}"
    # Remove existing file first (it may be read-only from a prior install)
    rm -f "${sudoers_dest}"
    echo "${policy}" > "${sudoers_dest}"
    do_chmod 440 "${sudoers_dest}"
    do_chown root:root "${sudoers_dest}"

    # Validate with visudo if available and not skipped
    if [[ "${EXOCOMP_SKIP_VISUDO}" != "1" ]] && command -v visudo >/dev/null 2>&1; then
        log "  validating with visudo..."
        if ! visudo -c -f "${sudoers_dest}" 2>&1; then
            rm -f "${sudoers_dest}"
            die "sudoers validation failed; policy file removed"
        fi
        log "  visudo check passed"
    fi

    log "  sudoers policy installed: ${sudoers_dest}"
}

# ── Phase 6: SYSTEMD UNIT ────────────────────────────────────────────────────

install_systemd_unit() {
    log "==> SYSTEMD UNIT"

    local unit_name="exocomp-${COMPONENT}"
    local unit_src="${BUNDLE_ROOT}/release/${COMPONENT}/${unit_name}.service"
    local unit_dest="${EXOCOMP_SYSTEMD_DIR}/${unit_name}.service"

    if [[ ! -f "${unit_src}" ]]; then
        die "systemd unit not found: ${unit_src}"
    fi

    if [[ "${DRY_RUN}" -eq 1 ]]; then
        log "  [dry-run] would install unit file: ${unit_dest}"
        return
    fi

    mkdir -p "${EXOCOMP_SYSTEMD_DIR}"

    # Substitute install path in unit file
    local install_dir="${INSTALL_BASE}/${COMPONENT}"
    local state_dir="${EXOCOMP_ROOT}/var/lib/exocomp-${COMPONENT}"
    sed \
        -e "s|@INSTALL_DIR@|${install_dir}|g" \
        -e "s|@STATE_DIR@|${state_dir}|g" \
        -e "s|@COMPONENT@|${COMPONENT}|g" \
        -e "s|@ACCOUNT@|exocomp-${COMPONENT}|g" \
        -e "s|@VERSION@|${VERSION}|g" \
        "${unit_src}" > "${unit_dest}"

    do_chmod 644 "${unit_dest}"
    do_chown root:root "${unit_dest}"

    log "  unit installed: ${unit_dest}"
}

# ── Phase 7: ACTIVATE SERVICE ─────────────────────────────────────────────────

activate_service() {
    log "==> ACTIVATE"

    local unit_name="exocomp-${COMPONENT}"

    if [[ "${DRY_RUN}" -eq 1 ]]; then
        log "  [dry-run] would enable and start ${unit_name}.service"
        return
    fi

    if [[ "${NO_START}" -eq 1 ]]; then
        log "  --no-start set; skipping service start"
        return
    fi

    if [[ "${EXOCOMP_SKIP_SYSTEMD}" == "1" ]]; then
        log "  [skip-systemd] skipping daemon-reload and service start"
    else
        log "  systemctl daemon-reload"
        systemctl daemon-reload

        log "  systemctl enable ${unit_name}"
        systemctl enable "${unit_name}"

        if systemctl is-active --quiet "${unit_name}" 2>/dev/null; then
            log "  systemctl restart ${unit_name}  (already running)"
            systemctl restart "${unit_name}"
        else
            log "  systemctl start ${unit_name}"
            systemctl start "${unit_name}"
        fi
    fi

    if verify_health_gate; then
        log "  service passed systemd and application health gate"
        if [[ "${EXOCOMP_SKIP_SYSTEMD}" != "1" ]]; then
            systemctl status "${unit_name}" --no-pager --lines=5 || true
        fi
    else
        rollback_upgrade
        die "new release failed health gate; prior current version restored"
    fi
}

verify_health_gate() {
    local unit_name="exocomp-${COMPONENT}"
    local attempt=1

    while [[ "${attempt}" -le "${EXOCOMP_HEALTHCHECK_ATTEMPTS}" ]]; do
        local systemd_ok=1
        if [[ "${EXOCOMP_SKIP_SYSTEMD}" != "1" ]] && \
           ! systemctl is-active --quiet "${unit_name}" 2>/dev/null; then
            systemd_ok=0
        fi

        if [[ "${systemd_ok}" -eq 1 ]] && application_healthcheck; then
            return 0
        fi

        if [[ "${attempt}" -lt "${EXOCOMP_HEALTHCHECK_ATTEMPTS}" ]]; then
            sleep "${EXOCOMP_HEALTHCHECK_INTERVAL}"
        fi
        attempt=$((attempt + 1))
    done

    return 1
}

application_healthcheck() {
    if [[ -n "${EXOCOMP_HEALTHCHECK_COMMAND}" ]]; then
        EXOCOMP_CURRENT="${INSTALL_BASE}/${COMPONENT}/current" \
            bash -c "${EXOCOMP_HEALTHCHECK_COMMAND}"
        return
    fi

    # Sandbox tests do not start a service. They may supply the explicit
    # health command above when exercising rollback behavior.
    if [[ "${EXOCOMP_SKIP_SYSTEMD}" == "1" ]]; then
        return 0
    fi

    local install_dir="${INSTALL_BASE}/${COMPONENT}"
    local cookie_file="${install_dir}/config/release-cookie.env"
    local release_bin="${install_dir}/current/bin/exocomp_${COMPONENT}"

    # shellcheck disable=SC1090
    . "${cookie_file}"
    export RELEASE_COOKIE
    if [[ "${COMPONENT}" == "node" ]]; then
        "${release_bin}" rpc '
          case Process.whereis(Exocomp.Node.Listener) do
            pid when is_pid(pid) ->
              if Process.alive?(pid) do
                :ok
              else
                raise "node listener is not alive"
              end
            _other ->
              raise "node listener is not running"
          end
        '
    else
        "${release_bin}" rpc '
          case Exocomp.Coordinator.Health.check() do
            %{status: :healthy} -> :ok
            other -> raise "coordinator is unhealthy: #{inspect(other)}"
          end
        '
    fi
}

rollback_upgrade() {
    local install_dir="${INSTALL_BASE}/${COMPONENT}"
    local current_link="${install_dir}/current"
    local unit_name="exocomp-${COMPONENT}"

    if [[ "${UPGRADE_SWITCHED}" -ne 1 ]]; then
        return
    fi

    # Stop the failed release while current still points to its own control
    # script. Switching the link first makes systemd run the prior release's
    # ExecStop against the failed node, which can block until TimeoutStopSec.
    if [[ "${EXOCOMP_SKIP_SYSTEMD}" != "1" ]]; then
        log "  stopping failed ${unit_name} before rollback"
        if ! systemctl stop "${unit_name}"; then
            warn "systemctl stop reported failure during rollback"
        fi
        if systemctl is-active --quiet "${unit_name}" 2>/dev/null; then
            die "automatic rollback could not stop failed ${unit_name}"
        fi
    fi

    if [[ -n "${PREVIOUS_TARGET}" ]]; then
        local tmp_link="${current_link}.rollback.$$"
        ln -sf "${PREVIOUS_TARGET}" "${tmp_link}"
        mv -Tf "${tmp_link}" "${current_link}"
        log "  rollback restored current -> ${PREVIOUS_TARGET}"

        if [[ "${EXOCOMP_SKIP_SYSTEMD}" != "1" ]]; then
            systemctl daemon-reload
            systemctl reset-failed "${unit_name}"
            systemctl start "${unit_name}"

            # A deliberately failing operator health command may have
            # triggered this rollback. Validate the restored release with the
            # built-in application probe so the installer cannot return while
            # the prior release is merely starting.
            if EXOCOMP_HEALTHCHECK_COMMAND="" \
                EXOCOMP_HEALTHCHECK_ATTEMPTS="${EXOCOMP_ROLLBACK_HEALTHCHECK_ATTEMPTS}" \
                EXOCOMP_HEALTHCHECK_INTERVAL="${EXOCOMP_ROLLBACK_HEALTHCHECK_INTERVAL}" \
                verify_health_gate; then
                log "  prior release passed systemd and application health gate"
            else
                die "prior release failed health gate after automatic rollback"
            fi
        fi
    else
        rm -f "${current_link}"
        log "  failed first install left no current version"
    fi
}

# ── Phase 8: WRITE MANIFEST ───────────────────────────────────────────────────

write_manifest() {
    log "==> MANIFEST"

    local install_dir="${INSTALL_BASE}/${COMPONENT}"
    local unit_name="exocomp-${COMPONENT}"
    local account="exocomp-${COMPONENT}"
    local manifest_file="${install_dir}/manifest-${VERSION}.txt"
    local var_dir="${EXOCOMP_ROOT}/var/lib/${account}"

    if [[ "${DRY_RUN}" -eq 1 ]]; then
        log "  [dry-run] would write manifest: ${manifest_file}"
        return
    fi

    cat > "${manifest_file}" <<MANIFEST
# Exocomp installed-file manifest
# Component: ${COMPONENT}
# Version: ${VERSION}
# Installed: $(date -u +%Y-%m-%dT%H:%M:%SZ)
# Account: ${account}
#
# Files and directories managed by this installation.
# The uninstaller reads this manifest to identify exocomp-owned resources.
#
# PROTECTED paths (never removed by default uninstall):
#   ${install_dir}/config/
#   ${install_dir}/log/
#   ${var_dir}/
#
# Remove only if --purge category is specified.

# Profile-action helper (if installed)
$(if [[ -f "${install_dir}/bin/profile-action-helper" ]]; then echo "${install_dir}/bin/profile-action-helper"; fi)

# Systemd unit
${EXOCOMP_SYSTEMD_DIR}/${unit_name}.service

# Sudoers policy (if installed)
$(if [[ -n "${ALLOW_LIST}" ]] || [[ -f "${install_dir}/bin/profile-action-helper" ]]; then echo "${EXOCOMP_SUDOERS_DIR}/${account}"; fi)

# Current version symlink
${install_dir}/current

# Versioned release directory
${install_dir}/releases/${VERSION}/

# Manifest (this file — removed by uninstaller)
${manifest_file}
MANIFEST

    do_chmod 644 "${manifest_file}"
    do_chown root:root "${manifest_file}"

    log "  manifest written: ${manifest_file}"
}

# ── Main ──────────────────────────────────────────────────────────────────────

main() {
    require_root
    preflight
    setup_users_and_dirs
    install_release
    install_profile_action_helper
    install_config
    install_release_cookie
    validate_config
    switch_current
    install_sudoers
    install_systemd_unit
    activate_service
    write_manifest

    echo ""
    if [[ "${DRY_RUN}" -eq 1 ]]; then
        log "==> DRY RUN COMPLETE — no host mutations were made"
    else
        log "==> exocomp-${COMPONENT} ${VERSION} installed successfully"
        if [[ "${NO_START}" -eq 0 && "${EXOCOMP_SKIP_SYSTEMD}" != "1" ]]; then
            log "    service: exocomp-${COMPONENT}.service (active)"
        fi
        log "    install: ${INSTALL_BASE}/${COMPONENT}"
        log "    config:  ${INSTALL_BASE}/${COMPONENT}/config/${COMPONENT}.json"
        log "    log:     ${INSTALL_BASE}/${COMPONENT}/log/"
    fi
}

main
