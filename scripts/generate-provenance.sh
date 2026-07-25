#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
#
# generate-provenance.sh — Generate SLSA-conformant build provenance.
#
# Outputs provenance.json describing the source, builder, toolchain,
# and dependency lock for a given bundle.
#
# USAGE
#   bash scripts/generate-provenance.sh [OPTIONS]
#
# OPTIONS
#   --arch             amd64|arm64              (required)
#   --version          VERSION                  (required)
#   --kind             complete|runtime         (required)
#   --source-commit    COMMIT                   source git commit SHA
#   --builder-image    IMAGE@DIGEST             builder container image
#   --build-timestamp  ISO8601                  build timestamp
#   --manifest         PATH                     manifest.json file path
#   --output           PATH                     output file (default: provenance.json)

set -euo pipefail

ARCH=""
VERSION=""
KIND=""
SOURCE_COMMIT=""
BUILDER_IMAGE=""
BUILD_TIMESTAMP=""
MANIFEST_PATH=""
OUTPUT="provenance.json"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "${SCRIPT_DIR}")"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --arch)             ARCH="$2";             shift 2 ;;
        --version)          VERSION="$2";          shift 2 ;;
        --kind)             KIND="$2";             shift 2 ;;
        --source-commit)    SOURCE_COMMIT="$2";    shift 2 ;;
        --builder-image)    BUILDER_IMAGE="$2";    shift 2 ;;
        --build-timestamp)  BUILD_TIMESTAMP="$2";  shift 2 ;;
        --manifest)         MANIFEST_PATH="$2";    shift 2 ;;
        --output)           OUTPUT="$2";           shift 2 ;;
        *) echo "ERROR: unknown option: $1" >&2; exit 1 ;;
    esac
done

[[ -n "${ARCH}" ]]    || { echo "ERROR: --arch is required" >&2; exit 1; }
[[ -n "${VERSION}" ]] || { echo "ERROR: --version is required" >&2; exit 1; }
[[ -n "${KIND}" ]]    || { echo "ERROR: --kind is required" >&2; exit 1; }

[[ -n "${BUILD_TIMESTAMP}" ]] || BUILD_TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

BUNDLE_NAME="exocomp-${KIND}-${VERSION}-linux-${ARCH}"

# ── Read builders.lock for toolchain information ───────────────────────────────

BUILDERS_LOCK="${REPO_ROOT}/release/builders.lock"

ELIXIR_VERSION=""
OTP_VERSION=""
BUILDER_TAG=""
BUILDER_DIGEST=""
GLIBC_BASELINE=""

if [[ -f "${BUILDERS_LOCK}" ]]; then
    # Source the lock file (it's a shell-compatible key=value file)
    # shellcheck disable=SC1090
    . "${BUILDERS_LOCK}"
    ELIXIR_VERSION="${ELIXIR_VERSION:-}"
    OTP_VERSION="${OTP_VERSION:-}"
    BUILDER_TAG="${BUILDER_TAG:-}"
    GLIBC_BASELINE="${GLIBC_BASELINE:-}"
    if [[ "${ARCH}" == "amd64" ]]; then
        BUILDER_DIGEST="${BUILDER_AMD64_DIGEST:-}"
    else
        BUILDER_DIGEST="${BUILDER_ARM64_DIGEST:-}"
    fi
fi

# Allow override via --builder-image flag
if [[ -n "${BUILDER_IMAGE}" ]]; then
    # Extract digest from image reference if it contains @sha256:
    if echo "${BUILDER_IMAGE}" | grep -q "@sha256:"; then
        BUILDER_DIGEST="${BUILDER_IMAGE##*@}"
        BUILDER_TAG="${BUILDER_IMAGE%%@*}"
    fi
fi

# ── Compute manifest digest for subject ───────────────────────────────────────

MANIFEST_DIGEST=""
if [[ -n "${MANIFEST_PATH}" && -f "${MANIFEST_PATH}" ]]; then
    MANIFEST_DIGEST="sha256:$(sha256sum "${MANIFEST_PATH}" | awk '{print $1}')"
fi

# ── Read mix.lock for dependency fingerprint ──────────────────────────────────

MIX_LOCK_DIGEST=""
if [[ -f "${REPO_ROOT}/mix.lock" ]]; then
    MIX_LOCK_DIGEST="sha256:$(sha256sum "${REPO_ROOT}/mix.lock" | awk '{print $1}')"
fi

cat > "${OUTPUT}" <<PROVENANCE_END
{
  "_type": "https://in-toto.io/Statement/v0.1",
  "subject": [
    {
      "name": "${BUNDLE_NAME}",
      "digest": {
        "sha256": "${MANIFEST_DIGEST#sha256:}"
      }
    }
  ],
  "predicateType": "https://slsa.dev/provenance/v0.2",
  "predicate": {
    "builder": {
      "id": "https://github.com/NVShawn/exocomp/blob/main/scripts/assemble-bundle.sh"
    },
    "buildType": "https://github.com/NVShawn/exocomp/buildType/offline-bundle/v1",
    "invocation": {
      "configSource": {
        "uri": "git+https://github.com/NVShawn/exocomp.git",
        "digest": {
          "sha1": "${SOURCE_COMMIT}"
        },
        "entryPoint": "scripts/assemble-bundle.sh"
      },
      "parameters": {
        "arch": "${ARCH}",
        "version": "${VERSION}",
        "kind": "${KIND}"
      },
      "environment": {
        "builder_image": "${BUILDER_IMAGE}",
        "builder_image_digest": "${BUILDER_DIGEST}"
      }
    },
    "buildConfig": {
      "steps": [
        {
          "id": "build-otp-releases",
          "command": "scripts/build-releases.sh ${ARCH}",
          "inputs": {
            "builder_image": "${BUILDER_TAG}@${BUILDER_DIGEST}",
            "mix_lock_digest": "${MIX_LOCK_DIGEST}"
          }
        },
        {
          "id": "assemble-bundle",
          "command": "scripts/assemble-bundle.sh --arch ${ARCH} --version ${VERSION} --kind ${KIND}",
          "inputs": {
            "otp_releases": "_build/release/${ARCH}/rel/",
            "installer_scripts": "scripts/install.sh, scripts/uninstall.sh",
            "systemd_units": "release/node/, release/coordinator/"
          }
        }
      ]
    },
    "metadata": {
      "buildInvocationId": "${SOURCE_COMMIT}-${ARCH}-${KIND}-${BUILD_TIMESTAMP}",
      "buildStartedOn": "${BUILD_TIMESTAMP}",
      "buildFinishedOn": "${BUILD_TIMESTAMP}",
      "completeness": {
        "parameters": true,
        "environment": true,
        "materials": false
      },
      "reproducible": false
    },
    "materials": [
      {
        "uri": "git+https://github.com/NVShawn/exocomp.git",
        "digest": {
          "sha1": "${SOURCE_COMMIT}"
        }
      },
      {
        "uri": "https://hub.docker.com/r/hexpm/elixir",
        "digest": {
          "sha256": "${BUILDER_DIGEST#sha256:}"
        }
      }
    ],
    "toolchain": {
      "elixir_version": "${ELIXIR_VERSION}",
      "otp_version": "${OTP_VERSION}",
      "glibc_baseline": "${GLIBC_BASELINE}",
      "builder_image_tag": "${BUILDER_TAG}",
      "builder_image_digest": "${BUILDER_DIGEST}"
    },
    "dependency_locks": {
      "mix_lock": "${MIX_LOCK_DIGEST}",
      "builders_lock": "release/builders.lock"
    }
  }
}
PROVENANCE_END
