#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
#
# generate-sbom.sh — Generate an SPDX 2.3 JSON Software Bill of Materials.
#
# Reads bundle contents and produces sbom.spdx.json conforming to SPDX 2.3.
#
# USAGE
#   bash scripts/generate-sbom.sh [OPTIONS]
#
# OPTIONS
#   --arch           amd64|arm64              (required)
#   --version        VERSION                  (required)
#   --kind           complete|runtime         (required)
#   --source-commit  COMMIT                   source git commit SHA
#   --builder-image  IMAGE@DIGEST             builder container image
#   --bundle-dir     PATH                     staged bundle directory
#   --output         PATH                     output SBOM file (default: sbom.spdx.json)

set -euo pipefail

ARCH=""
VERSION=""
KIND=""
SOURCE_COMMIT=""
BUILDER_IMAGE=""
BUNDLE_DIR=""
OUTPUT="sbom.spdx.json"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --arch)           ARCH="$2";           shift 2 ;;
        --version)        VERSION="$2";        shift 2 ;;
        --kind)           KIND="$2";           shift 2 ;;
        --source-commit)  SOURCE_COMMIT="$2";  shift 2 ;;
        --builder-image)  BUILDER_IMAGE="$2";  shift 2 ;;
        --bundle-dir)     BUNDLE_DIR="$2";     shift 2 ;;
        --output)         OUTPUT="$2";         shift 2 ;;
        *) echo "ERROR: unknown option: $1" >&2; exit 1 ;;
    esac
done

[[ -n "${ARCH}" ]]    || { echo "ERROR: --arch is required" >&2; exit 1; }
[[ -n "${VERSION}" ]] || { echo "ERROR: --version is required" >&2; exit 1; }
[[ -n "${KIND}" ]]    || { echo "ERROR: --kind is required" >&2; exit 1; }

TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
DOC_NAMESPACE="https://github.com/NVShawn/exocomp/sbom/exocomp-${KIND}-${VERSION}-linux-${ARCH}-${TIMESTAMP}"
BUNDLE_NAME="exocomp-${KIND}-${VERSION}-linux-${ARCH}"

# ── Compute SHA-256 of the bundle's manifest.sha256 for SBOM reference ────────

MANIFEST_SHA256=""
if [[ -n "${BUNDLE_DIR}" && -f "${BUNDLE_DIR}/manifest.sha256" ]]; then
    MANIFEST_SHA256="$(sha256sum "${BUNDLE_DIR}/manifest.sha256" | awk '{print $1}')"
fi

# ── Build SPDX packages ────────────────────────────────────────────────────────

# Exocomp project package
EXOCOMP_PACKAGE_SHA=""
if [[ -n "${BUNDLE_DIR}" ]]; then
    # Use checksum of the manifest as a proxy for the bundle's contents fingerprint
    if [[ -n "${MANIFEST_SHA256}" ]]; then
        EXOCOMP_PACKAGE_SHA="SHA256: ${MANIFEST_SHA256}"
    fi
fi

# Determine included model package
MODEL_PACKAGE=""
if [[ "${KIND}" == "complete" ]]; then
    MODEL_PACKAGE=',
    {
      "SPDXID": "SPDXRef-Package-Qwen2-5-1-5B-Instruct-Q4-K-M",
      "name": "Qwen2.5 1.5B Instruct Q4_K_M GGUF",
      "versionInfo": "repository revision and artifact SHA-256 pinned by each release",
      "downloadLocation": "https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF",
      "filesAnalyzed": false,
      "licenseConcluded": "Apache-2.0",
      "licenseDeclared": "Apache-2.0",
      "copyrightText": "Copyright 2024 Qwen Team, Alibaba Cloud",
      "comment": "Qwen2.5 1.5B Instruct quantized model in GGUF format for llama.cpp inference."
    }'
fi

cat > "${OUTPUT}" <<SBOM_END
{
  "SPDXID": "SPDXRef-DOCUMENT",
  "spdxVersion": "SPDX-2.3",
  "creationInfo": {
    "created": "${TIMESTAMP}",
    "creators": [
      "Tool: exocomp assemble-bundle.sh",
      "Organization: Exocomp contributors"
    ],
    "licenseListVersion": "3.23"
  },
  "name": "${BUNDLE_NAME}-sbom",
  "dataLicense": "CC0-1.0",
  "documentNamespace": "${DOC_NAMESPACE}",
  "documentDescribes": ["SPDXRef-Package-Bundle"],
  "packages": [
    {
      "SPDXID": "SPDXRef-Package-Bundle",
      "name": "${BUNDLE_NAME}",
      "versionInfo": "${VERSION}",
      "downloadLocation": "https://github.com/NVShawn/exocomp/releases/tag/v${VERSION}",
      "filesAnalyzed": false,
      "licenseConcluded": "Apache-2.0",
      "licenseDeclared": "Apache-2.0",
      "copyrightText": "Copyright 2026 Exocomp contributors",
      "externalRefs": [
        {
          "referenceCategory": "PACKAGE-MANAGER",
          "referenceType": "purl",
          "referenceLocator": "pkg:github/NVShawn/exocomp@${SOURCE_COMMIT}#${BUNDLE_NAME}"
        }
      ],
      "comment": "Exocomp ${KIND} offline bundle for linux/${ARCH}, version ${VERSION}, source commit ${SOURCE_COMMIT}."
    },
    {
      "SPDXID": "SPDXRef-Package-Exocomp",
      "name": "Exocomp",
      "versionInfo": "${VERSION}",
      "downloadLocation": "https://github.com/NVShawn/exocomp/archive/${SOURCE_COMMIT}.tar.gz",
      "filesAnalyzed": false,
      "licenseConcluded": "Apache-2.0",
      "licenseDeclared": "Apache-2.0",
      "copyrightText": "Copyright 2026 Exocomp contributors",
      "externalRefs": [
        {
          "referenceCategory": "PACKAGE-MANAGER",
          "referenceType": "purl",
          "referenceLocator": "pkg:github/NVShawn/exocomp@${SOURCE_COMMIT}"
        }
      ]
    },
    {
      "SPDXID": "SPDXRef-Package-ErlangOTP",
      "name": "Erlang/OTP",
      "versionInfo": "28.5.0.3",
      "downloadLocation": "https://github.com/erlang/otp/releases/tag/OTP-28.5.0.3",
      "filesAnalyzed": false,
      "licenseConcluded": "Apache-2.0",
      "licenseDeclared": "Apache-2.0",
      "copyrightText": "Copyright Ericsson AB 1996-2026",
      "externalRefs": [
        {
          "referenceCategory": "PACKAGE-MANAGER",
          "referenceType": "purl",
          "referenceLocator": "pkg:github/erlang/otp@OTP-28.5.0.3"
        }
      ],
      "comment": "Erlang/OTP runtime shipped as ERTS inside OTP release archives."
    },
    {
      "SPDXID": "SPDXRef-Package-LlamaCpp",
      "name": "llama.cpp",
      "versionInfo": "pinned commit; see provenance.json",
      "downloadLocation": "https://github.com/ggml-org/llama.cpp",
      "filesAnalyzed": false,
      "licenseConcluded": "MIT",
      "licenseDeclared": "MIT",
      "copyrightText": "Copyright 2023-2026 The llama.cpp Authors",
      "externalRefs": [
        {
          "referenceCategory": "PACKAGE-MANAGER",
          "referenceType": "purl",
          "referenceLocator": "pkg:github/ggml-org/llama.cpp"
        }
      ],
      "comment": "llama-server binary compiled for linux/${ARCH} from pinned llama.cpp commit."
    }${MODEL_PACKAGE}
  ],
  "relationships": [
    {
      "spdxElementId": "SPDXRef-DOCUMENT",
      "relationshipType": "DESCRIBES",
      "relatedSpdxElement": "SPDXRef-Package-Bundle"
    },
    {
      "spdxElementId": "SPDXRef-Package-Bundle",
      "relationshipType": "CONTAINS",
      "relatedSpdxElement": "SPDXRef-Package-Exocomp"
    },
    {
      "spdxElementId": "SPDXRef-Package-Bundle",
      "relationshipType": "CONTAINS",
      "relatedSpdxElement": "SPDXRef-Package-ErlangOTP"
    },
    {
      "spdxElementId": "SPDXRef-Package-Bundle",
      "relationshipType": "CONTAINS",
      "relatedSpdxElement": "SPDXRef-Package-LlamaCpp"
    }$(
    [[ "${KIND}" == "complete" ]] && echo ',
    {
      "spdxElementId": "SPDXRef-Package-Bundle",
      "relationshipType": "CONTAINS",
      "relatedSpdxElement": "SPDXRef-Package-Qwen2-5-1-5B-Instruct-Q4-K-M"
    }')
  ]
}
SBOM_END
