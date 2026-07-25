#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
#
# verify-bundle.sh — Verify an extracted Exocomp offline bundle.
#
# Run from inside an extracted bundle directory:
#
#   bash scripts/verify-bundle.sh [OPTIONS]
#
# Checks performed (all run before any host mutation):
#   1. manifest.sha256 exists and is non-empty.
#   2. Every file listed in manifest.sha256 exists in the bundle.
#   3. SHA-256 of every listed file matches the manifest entry.
#   4. sbom.spdx.json exists and references expected package names.
#   5. provenance.json exists and references expected fields.
#   6. If bundle.minisig is present and --public-key is given, verify signature.
#
# OPTIONS
#   --bundle-dir   PATH     bundle root directory
#                           (default: directory containing this script's parent)
#   --public-key   PATH     minisign public key file for signature verification
#                           (optional; skips sig check if absent)
#   --strict       (flag)   fail if bundle.minisig is absent (requires signature)

set -euo pipefail

BUNDLE_DIR=""
PUBLIC_KEY=""
STRICT=0

# Locate bundle dir relative to script location if not provided
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_BUNDLE_DIR="$(dirname "${SCRIPT_DIR}")"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --bundle-dir)   BUNDLE_DIR="$2"; shift 2 ;;
        --public-key)   PUBLIC_KEY="$2"; shift 2 ;;
        --strict)       STRICT=1;        shift ;;
        *) echo "ERROR: unknown option: $1" >&2; exit 1 ;;
    esac
done

BUNDLE_DIR="${BUNDLE_DIR:-${DEFAULT_BUNDLE_DIR}}"

log()  { echo "[verify-bundle] $*"; }
warn() { echo "[verify-bundle] WARN: $*" >&2; }
die()  { echo "[verify-bundle] ERROR: $*" >&2; exit 1; }

log "Bundle dir: ${BUNDLE_DIR}"

# ── Check 1: manifest.sha256 must exist ───────────────────────────────────────

MANIFEST="${BUNDLE_DIR}/manifest.sha256"
[[ -f "${MANIFEST}" ]] || die "manifest.sha256 not found in bundle: ${MANIFEST}"
[[ -s "${MANIFEST}" ]] || die "manifest.sha256 is empty: ${MANIFEST}"

ENTRY_COUNT="$(wc -l < "${MANIFEST}")"
log "Manifest: ${ENTRY_COUNT} entries"

# ── Check 2 & 3: Every file exists and matches its SHA-256 ───────────────────

log "==> Verifying file checksums..."

FAIL_COUNT=0

while IFS= read -r line; do
    [[ -z "${line}" ]] && continue

    expected_hash="${line%% *}"
    # manifest entries use ./relative/path format
    rel_path="${line##* }"
    abs_path="${BUNDLE_DIR}/${rel_path#./}"

    if [[ ! -f "${abs_path}" ]]; then
        echo "[verify-bundle] MISSING: ${rel_path}" >&2
        FAIL_COUNT=$(( FAIL_COUNT + 1 ))
        continue
    fi

    actual_hash="$(sha256sum "${abs_path}" | awk '{print $1}')"
    if [[ "${actual_hash}" != "${expected_hash}" ]]; then
        echo "[verify-bundle] TAMPERED: ${rel_path}" >&2
        echo "  expected: ${expected_hash}" >&2
        echo "  actual:   ${actual_hash}" >&2
        FAIL_COUNT=$(( FAIL_COUNT + 1 ))
    fi
done < "${MANIFEST}"

if [[ "${FAIL_COUNT}" -gt 0 ]]; then
    die "${FAIL_COUNT} file(s) failed verification — bundle may be tampered or corrupted"
fi

log "  all ${ENTRY_COUNT} checksums OK"

# ── Check 4: sbom.spdx.json must exist and contain expected fields ────────────

log "==> Verifying SBOM..."

SBOM="${BUNDLE_DIR}/sbom.spdx.json"
[[ -f "${SBOM}" ]] || die "sbom.spdx.json not found in bundle"

# Check for required SPDX fields (grep is more portable than requiring jq)
grep -q '"spdxVersion"' "${SBOM}"       || die "sbom.spdx.json missing spdxVersion"
grep -q '"SPDX-2.3"' "${SBOM}"          || die "sbom.spdx.json must be SPDX-2.3"
grep -q '"DESCRIBES"' "${SBOM}"         || die "sbom.spdx.json missing DESCRIBES relationship"
grep -q '"Erlang/OTP"' "${SBOM}"        || die "sbom.spdx.json missing Erlang/OTP package"
grep -q '"llama.cpp"' "${SBOM}"         || die "sbom.spdx.json missing llama.cpp package"
grep -q '"Exocomp"' "${SBOM}"           || die "sbom.spdx.json missing Exocomp package"

log "  SBOM structure OK"

# ── Check 5: provenance.json must exist and contain expected fields ────────────

log "==> Verifying provenance..."

PROV="${BUNDLE_DIR}/provenance.json"
[[ -f "${PROV}" ]] || die "provenance.json not found in bundle"

grep -q '"predicateType"' "${PROV}"       || die "provenance.json missing predicateType"
grep -q 'slsa.dev/provenance' "${PROV}"   || die "provenance.json missing SLSA predicateType URL"
grep -q '"builder"' "${PROV}"             || die "provenance.json missing builder"
grep -q '"materials"' "${PROV}"           || die "provenance.json missing materials"
grep -q '"toolchain"' "${PROV}"           || die "provenance.json missing toolchain"

log "  provenance structure OK"

# ── Check 6: Signature verification (optional) ────────────────────────────────

SIGFILE="${BUNDLE_DIR}/bundle.minisig"

if [[ -f "${SIGFILE}" ]]; then
    if [[ -n "${PUBLIC_KEY}" ]]; then
        log "==> Verifying signature..."
        if ! command -v minisign >/dev/null 2>&1; then
            die "minisign not found; install minisign to verify bundle signature"
        fi
        minisign \
            -V \
            -p "${PUBLIC_KEY}" \
            -m "${MANIFEST}" \
            -x "${SIGFILE}" \
        || die "signature verification FAILED"
        log "  signature OK"
    else
        warn "bundle.minisig present but --public-key not given; skipping signature check"
    fi
elif [[ "${STRICT}" -eq 1 ]]; then
    die "--strict mode: bundle.minisig not found; this bundle has no signature"
else
    log "==> Signature: no bundle.minisig (unsigned bundle)"
fi

log ""
log "==> VERIFICATION PASSED"
