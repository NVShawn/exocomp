#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
#
# assemble-bundle.sh — Assemble a signed offline bundle for Exocomp.
#
# Produces:
#   dist/exocomp-complete-<version>-linux-<arch>.tar.gz   (with model)
#   dist/exocomp-runtime-<version>-linux-<arch>.tar.gz    (without model, if --kind runtime)
#
# Both kinds include:
#   manifest.sha256      — SHA-256 checksums for every nested file
#   manifest.json        — Structured bundle metadata
#   sbom.spdx.json       — SPDX 2.3 SBOM
#   provenance.json      — SLSA-style provenance
#   LICENSES/            — License texts for bundled components
#   THIRD_PARTY_NOTICES.md
#   releases/            — OTP release archives (node + coordinator)
#   llama-server         — relocatable llama.cpp launcher
#   llama-server.bin     — llama.cpp inference server executable
#   lib/llama/           — non-system llama.cpp shared-library closure
#   release/             — systemd units, config templates
#   scripts/             — install, uninstall, verification, and state utilities
#
# The complete bundle additionally includes:
#   models/              — Verified Qwen GGUF model
#
# USAGE
#   bash scripts/assemble-bundle.sh [OPTIONS]
#
# OPTIONS
#   --arch           amd64|arm64                      (required)
#   --version        VERSION                          (required)
#   --kind           complete|runtime                 (default: complete)
#   --node-archive   PATH                             node OTP release archive
#   --coord-archive  PATH                             coordinator OTP release archive
#   --profile-helper PATH                             profile-action-helper binary
#                                                     built for --arch (optional on native builds)
#   --llama-server   PATH                             llama-server binary
#   --llama-lib-dir  PATH                             directory containing its .so files
#                                                     (default: binary directory)
#   --model          PATH                             Qwen GGUF model file
#                                                     (required for --kind complete)
#   --model-sha256   SHA256                           expected SHA-256 of the model file
#   --source-commit  COMMIT                           source git commit SHA
#   --builder-image  IMAGE@DIGEST                     builder container image used
#   --sign-key       PATH                             minisign private key file
#                                                     (skip signing if absent)
#   --dist-dir       PATH                             output directory (default: dist)
#   --licenses-dir   PATH                             directory with license texts
#                                                     (default: LICENSES)
#   --notices-file   PATH                             third-party notices markdown
#                                                     (default: THIRD_PARTY_NOTICES.md)
#   --help                                            show this help

set -euo pipefail

# ── Defaults ──────────────────────────────────────────────────────────────────

ARCH=""
VERSION=""
KIND="complete"
NODE_ARCHIVE=""
COORD_ARCHIVE=""
PROFILE_HELPER_BIN=""
LLAMA_SERVER_BIN=""
LLAMA_LIB_DIR=""
MODEL_PATH=""
MODEL_SHA256=""
SOURCE_COMMIT=""
BUILDER_IMAGE=""
SIGN_KEY=""
DIST_DIR="dist"
LICENSES_DIR="LICENSES"
NOTICES_FILE="THIRD_PARTY_NOTICES.md"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "${SCRIPT_DIR}")"

# ── Reproducibility epoch ────────────────────────────────────────────────────
# Resolve SOURCE_DATE_EPOCH early so every timestamp in the bundle is derived
# from the same fixed origin.  This must happen before any metadata is written.
SOURCE_DATE_EPOCH="${SOURCE_DATE_EPOCH:-$(git -C "${REPO_ROOT}" log -1 --format='%ct' 2>/dev/null || date +%s)}"
export SOURCE_DATE_EPOCH

# ── Helpers ───────────────────────────────────────────────────────────────────

log()  { echo "[assemble-bundle] $*"; }
warn() { echo "[assemble-bundle] WARN: $*" >&2; }
die()  { echo "[assemble-bundle] ERROR: $*" >&2; exit 1; }

usage() {
    grep '^#' "$0" | grep -v '^#!/' | sed 's/^# \{0,2\}//' | head -60
    exit 0
}

sha256_file() {
    sha256sum "$1" | awk '{print $1}'
}

is_elf() {
    [[ "$(dd if="$1" bs=4 count=1 2>/dev/null | od -A n -t x1 | tr -d ' \n')" == "7f454c46" ]]
}

validate_llama_runtime() {
    local runtime_root="$1"
    local elf
    local needed
    local readelf_output
    local baseline="${REPO_ROOT}/release/runtime-baseline.lock"

    is_elf "${runtime_root}/llama-server.bin" || return 0
    command -v readelf >/dev/null 2>&1 ||
        die "readelf is required to validate the llama-server runtime closure"
    [[ -f "${baseline}" ]] || die "runtime baseline not found: ${baseline}"

    while IFS= read -r elf; do
        is_elf "${elf}" || continue
        if ! readelf_output="$(readelf -d "${elf}" 2>/dev/null)"; then
            die "could not inspect llama runtime ELF: ${elf}"
        fi
        while IFS= read -r needed; do
            [[ -n "${needed}" ]] || continue
            if [[ -e "${runtime_root}/lib/llama/${needed}" ]]; then
                continue
            fi
            if grep -qFx "${needed}" "${baseline}"; then
                continue
            fi
            die "llama runtime dependency '${needed}' required by $(basename "${elf}") is not bundled"
        done < <(
            printf '%s\n' "${readelf_output}" |
                sed -n '/(NEEDED)/s/.*Shared library: \[\([^]]*\)\].*/\1/p'
        )
    done < <(
        find "${runtime_root}" -type f \
            \( -name 'llama-server.bin' -o -name '*.so*' \) |
            sort
    )
}

# ── Argument parsing ───────────────────────────────────────────────────────────

while [[ $# -gt 0 ]]; do
    case "$1" in
        --arch)           ARCH="$2";             shift 2 ;;
        --version)        VERSION="$2";          shift 2 ;;
        --kind)           KIND="$2";             shift 2 ;;
        --node-archive)   NODE_ARCHIVE="$2";     shift 2 ;;
        --coord-archive)  COORD_ARCHIVE="$2";    shift 2 ;;
        --profile-helper) PROFILE_HELPER_BIN="$2"; shift 2 ;;
        --llama-server)   LLAMA_SERVER_BIN="$2"; shift 2 ;;
        --llama-lib-dir)  LLAMA_LIB_DIR="$2";    shift 2 ;;
        --model)          MODEL_PATH="$2";       shift 2 ;;
        --model-sha256)   MODEL_SHA256="$2";     shift 2 ;;
        --source-commit)  SOURCE_COMMIT="$2";    shift 2 ;;
        --builder-image)  BUILDER_IMAGE="$2";    shift 2 ;;
        --sign-key)       SIGN_KEY="$2";         shift 2 ;;
        --dist-dir)       DIST_DIR="$2";         shift 2 ;;
        --licenses-dir)   LICENSES_DIR="$2";     shift 2 ;;
        --notices-file)   NOTICES_FILE="$2";     shift 2 ;;
        --help|-h)        usage ;;
        *)
            die "unknown option: $1 (try --help)"
            ;;
    esac
done

# ── Validation ─────────────────────────────────────────────────────────────────

[[ -n "${ARCH}" ]]    || die "--arch amd64|arm64 is required"
[[ -n "${VERSION}" ]] || die "--version VERSION is required"

case "${ARCH}" in
    amd64|arm64) ;;
    *) die "--arch must be amd64 or arm64; got '${ARCH}'" ;;
esac

case "${KIND}" in
    complete|runtime) ;;
    *) die "--kind must be complete or runtime; got '${KIND}'" ;;
esac

# Validate semver-like version
echo "${VERSION}" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+' \
    || die "invalid version '${VERSION}'; expected semver (e.g. 1.2.3)"

# Derive bundle name
BUNDLE_NAME="exocomp-${KIND}-${VERSION}-linux-${ARCH}"
BUNDLE_ARCHIVE="${DIST_DIR}/${BUNDLE_NAME}.tar.gz"

log "Bundle: ${BUNDLE_NAME}"
log "Kind:   ${KIND}"

# ── Phase 1: Validate inputs ──────────────────────────────────────────────────

log "==> VALIDATING INPUTS"

if [[ -n "${NODE_ARCHIVE}" ]]; then
    [[ -f "${NODE_ARCHIVE}" ]] || die "node archive not found: ${NODE_ARCHIVE}"
    log "  node archive:        ${NODE_ARCHIVE}"
else
    warn "  --node-archive not set; node archive will be absent from bundle"
fi

if [[ -n "${COORD_ARCHIVE}" ]]; then
    [[ -f "${COORD_ARCHIVE}" ]] || die "coordinator archive not found: ${COORD_ARCHIVE}"
    log "  coord archive:       ${COORD_ARCHIVE}"
else
    warn "  --coord-archive not set; coordinator archive will be absent from bundle"
fi

if [[ -n "${LLAMA_SERVER_BIN}" ]]; then
    [[ -f "${LLAMA_SERVER_BIN}" ]] || die "llama-server binary not found: ${LLAMA_SERVER_BIN}"
    LLAMA_LIB_DIR="${LLAMA_LIB_DIR:-$(dirname "${LLAMA_SERVER_BIN}")}"
    [[ -d "${LLAMA_LIB_DIR}" ]] || die "llama library directory not found: ${LLAMA_LIB_DIR}"
    log "  llama-server:        ${LLAMA_SERVER_BIN}"
    log "  llama libraries:     ${LLAMA_LIB_DIR}"
else
    [[ -z "${LLAMA_LIB_DIR}" ]] ||
        die "--llama-lib-dir requires --llama-server"
    warn "  --llama-server not set; llama-server will be absent from bundle"
fi

if [[ "${KIND}" == "complete" ]]; then
    [[ -n "${MODEL_PATH}" ]] || die "--model is required for --kind complete"
    [[ -f "${MODEL_PATH}" ]] || die "model file not found: ${MODEL_PATH}"
    log "  model:               ${MODEL_PATH}"
    if [[ -n "${MODEL_SHA256}" ]]; then
        log "  verifying model SHA-256..."
        actual_model_sha256="$(sha256_file "${MODEL_PATH}")"
        if [[ "${actual_model_sha256}" != "${MODEL_SHA256}" ]]; then
            die "model SHA-256 MISMATCH
  expected: ${MODEL_SHA256}
  actual:   ${actual_model_sha256}"
        fi
        log "  model SHA-256 OK: ${actual_model_sha256}"
    else
        warn "  --model-sha256 not set; model integrity not pre-verified"
    fi
fi

if [[ -n "${SOURCE_COMMIT}" ]]; then
    log "  source commit:       ${SOURCE_COMMIT}"
else
    # Try to derive from git
    SOURCE_COMMIT="$(git -C "${REPO_ROOT}" rev-parse HEAD 2>/dev/null || echo "unknown")"
    log "  source commit:       ${SOURCE_COMMIT} (from git)"
fi

# ── Phase 2: Build staging directory ─────────────────────────────────────────

log "==> STAGING BUNDLE CONTENTS"

STAGING_DIR="$(mktemp -d)"
trap 'rm -rf "${STAGING_DIR}"' EXIT

BUNDLE_STAGE="${STAGING_DIR}/${BUNDLE_NAME}"
mkdir -p "${BUNDLE_STAGE}"

# 2a. OTP release archives
if [[ -n "${NODE_ARCHIVE}" || -n "${COORD_ARCHIVE}" ]]; then
    mkdir -p "${BUNDLE_STAGE}/releases"
    if [[ -n "${NODE_ARCHIVE}" ]]; then
        cp -f "${NODE_ARCHIVE}" "${BUNDLE_STAGE}/releases/"
        log "  staged: releases/$(basename "${NODE_ARCHIVE}")"
    fi
    if [[ -n "${COORD_ARCHIVE}" ]]; then
        cp -f "${COORD_ARCHIVE}" "${BUNDLE_STAGE}/releases/"
        log "  staged: releases/$(basename "${COORD_ARCHIVE}")"
    fi
fi

# 2b. llama-server and its non-system runtime dependency closure
if [[ -n "${LLAMA_SERVER_BIN}" ]]; then
    mkdir -p "${BUNDLE_STAGE}/lib/llama"
    cp -f "${LLAMA_SERVER_BIN}" "${BUNDLE_STAGE}/llama-server.bin"
    chmod 755 "${BUNDLE_STAGE}/llama-server.bin"

    while IFS= read -r llama_lib; do
        # Dereference input symlinks so the offline payload cannot retain a
        # build-host path while still providing every SONAME alias.
        cp -fL "${llama_lib}" "${BUNDLE_STAGE}/lib/llama/$(basename "${llama_lib}")"
    done < <(
        find "${LLAMA_LIB_DIR}" -maxdepth 1 \
            \( -type f -o -type l \) -name '*.so*' |
            sort
    )

    cat > "${BUNDLE_STAGE}/llama-server" <<'LLAMA_LAUNCHER'
#!/bin/sh
set -eu

server_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
if [ -d "${server_dir}/lib/llama" ]; then
    llama_lib_dir="${server_dir}/lib/llama"
else
    llama_lib_dir="${server_dir}/../lib/llama"
fi

if [ -n "${LD_LIBRARY_PATH:-}" ]; then
    LD_LIBRARY_PATH="${llama_lib_dir}:${LD_LIBRARY_PATH}"
else
    LD_LIBRARY_PATH="${llama_lib_dir}"
fi
export LD_LIBRARY_PATH
exec "${server_dir}/llama-server.bin" "$@"
LLAMA_LAUNCHER
    chmod 755 "${BUNDLE_STAGE}/llama-server"

    validate_llama_runtime "${BUNDLE_STAGE}"
    log "  staged: llama-server runtime"
fi

# 2c. GGUF model (complete bundle only)
if [[ "${KIND}" == "complete" && -n "${MODEL_PATH}" ]]; then
    mkdir -p "${BUNDLE_STAGE}/models"
    cp -f "${MODEL_PATH}" "${BUNDLE_STAGE}/models/"
    log "  staged: models/$(basename "${MODEL_PATH}")"
fi

# 2d. systemd units and config templates (from release/ directory)
cp -rf "${REPO_ROOT}/release" "${BUNDLE_STAGE}/release"
log "  staged: release/"

# 2e. Profile-action helper (Ceph profile execution)
# The helper is separately compiled for each architecture and used by the node
# to execute profile-based actions (like restart_failed_daemon) without shell.
# A native build may use the default build output.  Cross-architecture builds
# must pass --profile-helper from the corresponding native builder so a host
# helper can never be silently shipped for the wrong target.
PROFILE_HELPER_PATH="${PROFILE_HELPER_BIN}"
if [[ -z "${PROFILE_HELPER_PATH}" ]]; then
    PROFILE_HELPER_PATH="${REPO_ROOT}/_build/profile-action-helper/profile_action_helper"
    native_arch="$(uname -m)"
    case "${ARCH}:${native_arch}" in
        amd64:x86_64|arm64:aarch64) ;;
        *)
            die "profile-action-helper for ${ARCH} is required; build it on a ${ARCH} native builder and pass --profile-helper PATH"
            ;;
    esac
    if [[ ! -f "${PROFILE_HELPER_PATH}" ]]; then
        log "  profile-action-helper not found; building for ${ARCH}..."
        if command -v make >/dev/null 2>&1; then
            if make -C "${REPO_ROOT}" build-profile-action-helper >/dev/null 2>&1; then
                log "  profile-action-helper built successfully"
            else
                die "failed to build profile-action-helper; check compiler setup"
            fi
        else
            die "make is required to build profile-action-helper"
        fi
    fi
fi

[[ -f "${PROFILE_HELPER_PATH}" ]] ||
    die "profile-action-helper not found: ${PROFILE_HELPER_PATH}"
[[ -x "${PROFILE_HELPER_PATH}" ]] ||
    die "profile-action-helper is not executable: ${PROFILE_HELPER_PATH}"
command -v readelf >/dev/null 2>&1 || die "readelf is required to validate profile-action-helper architecture"
helper_machine="$(readelf -h "${PROFILE_HELPER_PATH}" 2>/dev/null |
    sed -n 's/^[[:space:]]*Machine:[[:space:]]*//p')"
case "${ARCH}:${helper_machine}" in
    amd64:*"Advanced Micro Devices X86-64"*|amd64:*"x86-64"*) ;;
    arm64:*"AArch64"*) ;;
    *)
        die "profile-action-helper architecture mismatch: bundle=${ARCH}, ELF machine=${helper_machine:-unknown}"
        ;;
esac

if [[ -f "${PROFILE_HELPER_PATH}" ]]; then
    mkdir -p "${BUNDLE_STAGE}/bin"
    cp -f "${PROFILE_HELPER_PATH}" "${BUNDLE_STAGE}/bin/profile-action-helper"
    chmod 755 "${BUNDLE_STAGE}/bin/profile-action-helper"
    log "  staged: bin/profile-action-helper"
else
    die "profile-action-helper could not be staged; binary not found at ${PROFILE_HELPER_PATH}"
fi

# 2f. Installer scripts
mkdir -p "${BUNDLE_STAGE}/scripts"
cp -f "${SCRIPT_DIR}/install.sh"     "${BUNDLE_STAGE}/scripts/"
cp -f "${SCRIPT_DIR}/uninstall.sh"   "${BUNDLE_STAGE}/scripts/"
cp -f "${SCRIPT_DIR}/state-backup.sh" "${BUNDLE_STAGE}/scripts/"
cp -f "${SCRIPT_DIR}/verify-bundle.sh" "${BUNDLE_STAGE}/scripts/"
chmod 755 "${BUNDLE_STAGE}/scripts/"*.sh
log "  staged: scripts/"

# 2g. License texts
# Assembly fails closed when the required LICENSES directory is absent or empty.
# Every governed component that ships in the bundle must have its license text present.
LICENSES_SRC="${REPO_ROOT}/${LICENSES_DIR}"
if [[ ! -d "${LICENSES_SRC}" ]]; then
    die "LICENSES directory not found at ${LICENSES_SRC}; populate it before assembling a bundle"
fi

# Verify required SPDX license files are present.
REQUIRED_LICENSES=("Apache-2.0.txt" "MIT.txt" "BSD-3-Clause.txt")
for req_lic in "${REQUIRED_LICENSES[@]}"; do
    [[ -f "${LICENSES_SRC}/${req_lic}" ]] \
        || die "Required license text missing: ${LICENSES_SRC}/${req_lic}"
done

cp -rf "${LICENSES_SRC}" "${BUNDLE_STAGE}/LICENSES"
log "  staged: LICENSES/ ($(find "${BUNDLE_STAGE}/LICENSES" -type f | wc -l) files)"

# 2g. Third-party notices
if [[ -f "${REPO_ROOT}/${NOTICES_FILE}" ]]; then
    cp -f "${REPO_ROOT}/${NOTICES_FILE}" "${BUNDLE_STAGE}/"
    log "  staged: ${NOTICES_FILE}"
else
    warn "  ${NOTICES_FILE} not found; skipping"
fi

# 2h. Apache-2.0 LICENSE at bundle root (project license)
if [[ -f "${REPO_ROOT}/LICENSE" ]]; then
    cp -f "${REPO_ROOT}/LICENSE" "${BUNDLE_STAGE}/"
    log "  staged: LICENSE"
fi

# ── Phase 3: Generate SHA-256 manifest ────────────────────────────────────────

log "==> GENERATING MANIFEST"

MANIFEST_SHA256="${BUNDLE_STAGE}/manifest.sha256"

# Generate checksums for every file in the bundle staging directory,
# using paths relative to the bundle root.
(
    cd "${BUNDLE_STAGE}"
    find . -type f \
        ! -name "manifest.sha256" \
        ! -name "manifest.json" \
        ! -name "sbom.spdx.json" \
        ! -name "provenance.json" \
        | sort \
        | xargs -d '\n' sha256sum \
        > "${MANIFEST_SHA256}"
)
log "  manifest.sha256: $(wc -l < "${MANIFEST_SHA256}") entries"

# ── Phase 4: Generate structured manifest ─────────────────────────────────────

log "==> GENERATING STRUCTURED MANIFEST"

# Derive a deterministic ISO-8601 timestamp from SOURCE_DATE_EPOCH.
BUILD_TIMESTAMP="$(date -u -d "@${SOURCE_DATE_EPOCH}" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null \
    || date -u -r "${SOURCE_DATE_EPOCH}" +%Y-%m-%dT%H:%M:%SZ)"

MANIFEST_JSON="${BUNDLE_STAGE}/manifest.json"

# Build file list JSON array
FILES_JSON=""
while IFS= read -r line; do
    hash="${line%% *}"
    filepath="${line##* }"
    filepath="${filepath#./}"
    FILES_JSON="${FILES_JSON}
    {\"path\": \"${filepath}\", \"sha256\": \"${hash}\"},"
done < "${MANIFEST_SHA256}"
FILES_JSON="${FILES_JSON%,}"  # remove trailing comma

# Determine node archive name
NODE_ARCHIVE_NAME=""
if [[ -n "${NODE_ARCHIVE}" ]]; then
    NODE_ARCHIVE_NAME="releases/$(basename "${NODE_ARCHIVE}")"
fi
COORD_ARCHIVE_NAME=""
if [[ -n "${COORD_ARCHIVE}" ]]; then
    COORD_ARCHIVE_NAME="releases/$(basename "${COORD_ARCHIVE}")"
fi
MODEL_ARCHIVE_NAME=""
if [[ "${KIND}" == "complete" && -n "${MODEL_PATH}" ]]; then
    MODEL_ARCHIVE_NAME="models/$(basename "${MODEL_PATH}")"
fi
LLAMA_SERVER_NAME=""
if [[ -n "${LLAMA_SERVER_BIN}" ]]; then
    LLAMA_SERVER_NAME="llama-server"
fi
PROFILE_HELPER_NAME="bin/profile-action-helper"

cat > "${MANIFEST_JSON}" <<MANIFEST_JSON_END
{
  "schema_version": "1",
  "bundle": {
    "name": "${BUNDLE_NAME}",
    "version": "${VERSION}",
    "architecture": "${ARCH}",
    "kind": "${KIND}",
    "build_timestamp": "${BUILD_TIMESTAMP}"
  },
  "source": {
    "commit": "${SOURCE_COMMIT}",
    "repository": "https://github.com/NVShawn/exocomp"
  },
  "builder": {
    "image": "${BUILDER_IMAGE}"
  },
  "components": {
    "node_archive": "${NODE_ARCHIVE_NAME}",
    "coordinator_archive": "${COORD_ARCHIVE_NAME}",
    "profile_action_helper": "${PROFILE_HELPER_NAME}",
    "llama_server": "${LLAMA_SERVER_NAME}",
    "model": "${MODEL_ARCHIVE_NAME}"
  },
  "files": [${FILES_JSON}
  ]
}
MANIFEST_JSON_END

log "  manifest.json written"

# ── Phase 5: Generate SPDX SBOM ───────────────────────────────────────────────

log "==> GENERATING SPDX SBOM"

SBOM_PATH="${BUNDLE_STAGE}/sbom.spdx.json"
bash "${SCRIPT_DIR}/generate-sbom.sh" \
    --arch "${ARCH}" \
    --version "${VERSION}" \
    --kind "${KIND}" \
    --source-commit "${SOURCE_COMMIT}" \
    --builder-image "${BUILDER_IMAGE}" \
    --bundle-dir "${BUNDLE_STAGE}" \
    --timestamp "${BUILD_TIMESTAMP}" \
    --output "${SBOM_PATH}"

log "  sbom.spdx.json written"

# ── Phase 6: Generate Provenance ──────────────────────────────────────────────

log "==> GENERATING PROVENANCE"

PROVENANCE_PATH="${BUNDLE_STAGE}/provenance.json"
bash "${SCRIPT_DIR}/generate-provenance.sh" \
    --arch "${ARCH}" \
    --version "${VERSION}" \
    --kind "${KIND}" \
    --source-commit "${SOURCE_COMMIT}" \
    --builder-image "${BUILDER_IMAGE}" \
    --build-timestamp "${BUILD_TIMESTAMP}" \
    --manifest "${MANIFEST_JSON}" \
    --output "${PROVENANCE_PATH}"

log "  provenance.json written"

# ── Phase 7: Extend manifest to cover all metadata files ──────────────────────
#
# manifest.sha256 was generated in Phase 3 covering only the payload files
# (OTP archives, binaries, installer scripts, release configs, license texts).
# Now that manifest.json, sbom.spdx.json, and provenance.json exist we append
# their checksums so the signature (Phase 8) transitively authenticates every
# file in the bundle.  Verifiers using verify-bundle.sh already check every
# entry in manifest.sha256, so no verifier changes are needed for the hash
# coverage — only the strict-mode sentinel check is updated.

log "==> EXTENDING MANIFEST TO COVER METADATA FILES"

(
    cd "${BUNDLE_STAGE}"
    for meta_file in manifest.json sbom.spdx.json provenance.json; do
        if [[ -f "${meta_file}" ]]; then
            sha256sum "${meta_file}" >> "${MANIFEST_SHA256}"
            log "  manifest.sha256 += ${meta_file}"
        fi
    done
)

# ── Phase 8: Sign the manifest ────────────────────────────────────────────────

if [[ -n "${SIGN_KEY}" ]]; then
    log "==> SIGNING"
    bash "${SCRIPT_DIR}/sign-bundle.sh" \
        --manifest "${MANIFEST_SHA256}" \
        --sign-key "${SIGN_KEY}" \
        --output "${BUNDLE_STAGE}/bundle.minisig"
    log "  bundle.minisig written"
else
    log "==> SIGNING (skipped — no --sign-key provided)"
fi

# ── Phase 8: Create archive ───────────────────────────────────────────────────

log "==> CREATING ARCHIVE"

mkdir -p "${DIST_DIR}"

# SOURCE_DATE_EPOCH was set at script startup; it controls all timestamps
# (metadata files and the archive mtime) for byte-identical reproducibility.

tar \
    --create \
    --gzip \
    --file "${BUNDLE_ARCHIVE}" \
    --directory "${STAGING_DIR}" \
    --sort=name \
    --mtime="@${SOURCE_DATE_EPOCH}" \
    --owner=0 \
    --group=0 \
    --numeric-owner \
    "${BUNDLE_NAME}"

log "  created: ${BUNDLE_ARCHIVE}"

# Generate top-level checksum for the bundle archive itself
(
    cd "${DIST_DIR}"
    sha256sum "$(basename "${BUNDLE_ARCHIVE}")" > "$(basename "${BUNDLE_ARCHIVE}").sha256"
)
log "  created: ${BUNDLE_ARCHIVE}.sha256"

log ""
log "==> DONE"
log "    archive:  ${BUNDLE_ARCHIVE}"
log "    checksum: ${BUNDLE_ARCHIVE}.sha256"
