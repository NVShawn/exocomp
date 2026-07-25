#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
#
# sign-bundle.sh — Sign a bundle manifest with minisign.
#
# Produces a .minisig detached signature file for the given manifest.
# Requires minisign to be installed and a private key file.
#
# USAGE
#   bash scripts/sign-bundle.sh [OPTIONS]
#
# OPTIONS
#   --manifest    PATH     manifest.sha256 file to sign  (required)
#   --sign-key    PATH     minisign private key file      (required)
#   --output      PATH     output .minisig file
#                          (default: <manifest>.minisig)
#
# The signature covers manifest.sha256 which in turn covers every nested file
# in the bundle.  Verifiers should run verify-bundle.sh which checks both
# the signature and the individual file checksums.

set -euo pipefail

MANIFEST_PATH=""
SIGN_KEY=""
OUTPUT=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --manifest)   MANIFEST_PATH="$2"; shift 2 ;;
        --sign-key)   SIGN_KEY="$2";      shift 2 ;;
        --output)     OUTPUT="$2";        shift 2 ;;
        *) echo "ERROR: unknown option: $1" >&2; exit 1 ;;
    esac
done

[[ -n "${MANIFEST_PATH}" ]] || { echo "ERROR: --manifest is required" >&2; exit 1; }
[[ -n "${SIGN_KEY}" ]]      || { echo "ERROR: --sign-key is required" >&2; exit 1; }
[[ -f "${MANIFEST_PATH}" ]] || { echo "ERROR: manifest not found: ${MANIFEST_PATH}" >&2; exit 1; }
[[ -f "${SIGN_KEY}" ]]      || { echo "ERROR: sign-key not found: ${SIGN_KEY}" >&2; exit 1; }

OUTPUT="${OUTPUT:-${MANIFEST_PATH}.minisig}"

if ! command -v minisign >/dev/null 2>&1; then
    echo "ERROR: minisign not found in PATH; install minisign to enable bundle signing" >&2
    exit 1
fi

minisign \
    -S \
    -s "${SIGN_KEY}" \
    -m "${MANIFEST_PATH}" \
    -x "${OUTPUT}" \
    -t "exocomp bundle manifest signature"

echo "Signed: ${OUTPUT}"
