#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
#
# Complete rc.23 arm64 qualification script.
# Runs all phases from scratch on the arm64 qualification VM (full-system QEMU).
# Evidence written to /var/lib/exocomp-qualification/rc23/evidence/

set -euo pipefail

VERSION="0.1.0-rc.23"
ARCH="arm64"
SOURCE_COMMIT="902bee1a52bf037fdaab50bd0c71ba82fa51a8d6"
QUAL_ROOT="/var/lib/exocomp-qualification"
SRC_DIR="${QUAL_ROOT}/src"
RC_DIR="${QUAL_ROOT}/rc23"
SIGN_KEY="${QUAL_ROOT}/qualification.key"
LLAMA_INPUT_ROOT="${QUAL_ROOT}/inputs/llama-b10107-no-openmp"
LLAMA_DIR="${LLAMA_INPUT_ROOT}/build/bin"
MODEL="${QUAL_ROOT}/inputs/qwen2.5-1.5b-instruct-q4_k_m.gguf"
MODEL_SHA256="6a1a2eb6d15622bf3c96857206351ba97e1af16c30d7a74ee38970e434e9407e"
EVIDENCE_DIR="${RC_DIR}/evidence/raw/${ARCH}"
CONTAINER_ENGINE="podman"
BUNDLE_NAME="exocomp-complete-${VERSION}-linux-${ARCH}"
BUNDLE_DIR="${RC_DIR}/final-dist/${BUNDLE_NAME}"
PREFLIGHT_SOURCE="${SRC_DIR}/scripts/qualification-live-preflight.sh"
PREFLIGHT_SCRIPT="${QUAL_ROOT}/qualification-live-preflight-arm64-rc23.sh"
LIFECYCLE_SOURCE="${SRC_DIR}/scripts/qualification-live-lifecycle.sh"
LIFECYCLE_SCRIPT="${QUAL_ROOT}/qualification-live-lifecycle-arm64-rc23.sh"

if [ -e "${RC_DIR}" ]; then
    echo "[FAIL] Refusing to reuse qualification root: ${RC_DIR}" >&2
    exit 1
fi
mkdir -p \
    "${RC_DIR}" \
    "${EVIDENCE_DIR}/artifacts" \
    "${EVIDENCE_DIR}/repo-gates" \
    "${EVIDENCE_DIR}/lifecycle"
ln -s "${SRC_DIR}" "${RC_DIR}/src-gates"
LOG="${RC_DIR}/orchestration.log"
exec > >(tee -a "${LOG}") 2>&1

ts() { date -u +%Y-%m-%dT%H:%M:%SZ; }

echo "=== $(ts) START rc.23 arm64 qualification ==="

# Verify source
export HOME=/root
git config --global --add safe.directory "${SRC_DIR}" 2>/dev/null || true
CURRENT=$(git -c safe.directory='*' -C "${SRC_DIR}" rev-parse HEAD)
[ "${CURRENT}" = "${SOURCE_COMMIT}" ] || {
    echo "[FAIL] Source at ${CURRENT}, expected ${SOURCE_COMMIT}" >&2
    exit 1
}
echo "[PASS] Source at ${CURRENT}"

cd "${SRC_DIR}"

# Candidate tag verification
git -c safe.directory='*' -C "${SRC_DIR}" show "v${VERSION}" --format="%H %s" -s \
    > "${EVIDENCE_DIR}/candidate-tag-verification.txt"
git -c safe.directory='*' -C "${SRC_DIR}" verify-tag "v${VERSION}" \
    >> "${EVIDENCE_DIR}/candidate-tag-verification.txt" 2>&1
echo "[PASS] Candidate tag verified"

{
    printf 'candidate=%s\ncommit=%s\narchitecture=%s\n' \
        "${VERSION}" "${CURRENT}" "$(uname -m)"
    printf 'hostname=%s\nkernel=%s\nvirtualization=%s\n' \
        "$(hostname)" "$(uname -r)" "$(systemd-detect-virt || true)"
    grep '^PRETTY_NAME=' /etc/os-release
    nproc
    free -b
} > "${EVIDENCE_DIR}/host-and-candidate.txt"

# Repository gates
echo "=== $(ts) Repository gate: fmt-check ==="
env CONTAINER_ENGINE="${CONTAINER_ENGINE}" make fmt-check 2>&1 | \
    tee "${EVIDENCE_DIR}/repo-gates/fmt-check.txt"
echo "[PASS] fmt-check"

echo "=== $(ts) Repository gate: lint ==="
env CONTAINER_ENGINE="${CONTAINER_ENGINE}" make lint 2>&1 | \
    tee "${EVIDENCE_DIR}/repo-gates/lint.txt"
echo "[PASS] lint"

echo "=== $(ts) Repository gate: release-check ==="
make release-check 2>&1 | \
    tee "${EVIDENCE_DIR}/repo-gates/release-check.txt"
echo "[PASS] release-check"

echo "=== $(ts) Repository gate: test-release-packaging ==="
env CONTAINER_ENGINE="${CONTAINER_ENGINE}" make test-release-packaging 2>&1 | \
    tee "${EVIDENCE_DIR}/repo-gates/test-release-packaging.txt"
echo "[PASS] test-release-packaging"

echo "=== $(ts) Repository gate: test-installer ==="
make test-installer 2>&1 | \
    tee "${EVIDENCE_DIR}/repo-gates/test-installer.txt"
echo "[PASS] test-installer"

echo "=== $(ts) Repository gate: test-bundle ==="
env CONTAINER_ENGINE="${CONTAINER_ENGINE}" make test-bundle 2>&1 | \
    tee "${EVIDENCE_DIR}/repo-gates/test-bundle.txt"
echo "[PASS] test-bundle"

echo "=== $(ts) Repository gate: test ==="
env CONTAINER_ENGINE="${CONTAINER_ENGINE}" make test 2>&1 | \
    tee "${EVIDENCE_DIR}/repo-gates/test.txt"
echo "[PASS] test"

echo "=== $(ts) Repository gate: test-release-matrix ==="
env CONTAINER_ENGINE="${CONTAINER_ENGINE}" \
    make test-release-matrix ARCH="${ARCH}" 2>&1 | \
    tee "${EVIDENCE_DIR}/repo-gates/test-release-matrix.txt"
echo "[PASS] test-release-matrix"

echo "=== $(ts) Repository gate: test-m5-qualification ==="
env CONTAINER_ENGINE="${CONTAINER_ENGINE}" make test-m5-qualification 2>&1 | \
    tee "${EVIDENCE_DIR}/repo-gates/test-m5-qualification.txt"
echo "[PASS] test-m5-qualification"

# Phase 1: Build 1/2
echo "=== $(ts) Phase 1: Build 1/2 ==="
rm -rf _build/release/ "${RC_DIR}/artifacts-build1"
mkdir -p "${RC_DIR}/artifacts-build1"
RELEASE_VERSION="${VERSION}" \
RELEASE_OUTPUT_DIR="${RC_DIR}/artifacts-build1" \
CONTAINER_ENGINE="${CONTAINER_ENGINE}" make build-arm64
sha256sum "${RC_DIR}/artifacts-build1/"*.tar.gz | tee "${RC_DIR}/artifacts-build1/checksums.sha256"
echo "[PASS] Build 1 complete"

# Phase 2: Build 2/2
echo "=== $(ts) Phase 2: Build 2/2 ==="
rm -rf _build/release/ "${RC_DIR}/artifacts-build2"
mkdir -p "${RC_DIR}/artifacts-build2"
RELEASE_VERSION="${VERSION}" \
RELEASE_OUTPUT_DIR="${RC_DIR}/artifacts-build2" \
CONTAINER_ENGINE="${CONTAINER_ENGINE}" make build-arm64
sha256sum "${RC_DIR}/artifacts-build2/"*.tar.gz | tee "${RC_DIR}/artifacts-build2/checksums.sha256"
echo "[PASS] Build 2 complete"

# Phase 3: Verify reproducibility
echo "=== $(ts) Phase 3: Verify reproducibility ==="
{
    for f in "${RC_DIR}/artifacts-build1/"*.tar.gz; do
        fname="$(basename "${f}")"
        sha1=$(sha256sum "${f}" | cut -d' ' -f1)
        sha2=$(sha256sum "${RC_DIR}/artifacts-build2/${fname}" | cut -d' ' -f1)
        if [ "${sha1}" = "${sha2}" ]; then
            echo "[PASS] Reproducible: ${fname} sha256=${sha1}"
        else
            echo "[FAIL] NOT reproducible: ${fname}" >&2
            exit 1
        fi
    done
} | tee "${EVIDENCE_DIR}/artifacts/build-reproducibility.txt"
cp \
    "${RC_DIR}/artifacts-build1/checksums.sha256" \
    "${EVIDENCE_DIR}/artifacts/build1-checksums.sha256"
cp \
    "${RC_DIR}/artifacts-build2/checksums.sha256" \
    "${EVIDENCE_DIR}/artifacts/build2-checksums.sha256"
echo "[PASS] Both builds produce identical artifacts"

# Phase 4: Build bench_harness
echo "=== $(ts) Phase 4: Build bench_harness ==="
CONTAINER_ENGINE="${CONTAINER_ENGINE}" make bench-harness
BENCH_HARNESS="${SRC_DIR}/_build/prod/rel/bench_harness/bin/bench_harness"
[ -f "${BENCH_HARNESS}" ] || { echo "[FAIL] bench_harness not found"; exit 1; }
echo "[PASS] bench_harness: ${BENCH_HARNESS}"

# Phase 5: Assemble bundle (twice for reproducibility)
echo "=== $(ts) Phase 5: Assemble bundle ==="
rm -rf "${RC_DIR}/final-dist" "${RC_DIR}/bundle-build2"
mkdir -p "${RC_DIR}/final-dist" "${RC_DIR}/bundle-build2"
. "${SRC_DIR}/release/builders.lock"
BUILDER_IMAGE="docker.io/hexpm/elixir:${BUILDER_TAG}@${BUILDER_ARM64_DIGEST}"
NODE_ARC="${RC_DIR}/artifacts-build1/exocomp-node-${VERSION}-linux-${ARCH}.tar.gz"
COORD_ARC="${RC_DIR}/artifacts-build1/exocomp-coordinator-${VERSION}-linux-${ARCH}.tar.gz"
BUNDLE_VERSION="${VERSION}" \
NODE_ARCHIVE_ARM64="${NODE_ARC}" \
COORD_ARCHIVE_ARM64="${COORD_ARC}" \
LLAMA_SERVER_ARM64="${LLAMA_DIR}/llama-server" \
LLAMA_LIB_DIR_ARM64="${LLAMA_DIR}" \
MODEL_PATH="${MODEL}" \
MODEL_SHA256="${MODEL_SHA256}" \
BUNDLE_SIGN_KEY="${SIGN_KEY}" \
BUNDLE_SOURCE_COMMIT="${SOURCE_COMMIT}" \
BUNDLE_BUILDER_IMAGE="${BUILDER_IMAGE}" \
BUNDLE_DIST="${RC_DIR}/final-dist" \
CONTAINER_ENGINE="${CONTAINER_ENGINE}" \
make bundle-arm64
echo "[PASS] Bundle build 1 assembled"

BUNDLE_VERSION="${VERSION}" \
NODE_ARCHIVE_ARM64="${NODE_ARC}" \
COORD_ARCHIVE_ARM64="${COORD_ARC}" \
LLAMA_SERVER_ARM64="${LLAMA_DIR}/llama-server" \
LLAMA_LIB_DIR_ARM64="${LLAMA_DIR}" \
MODEL_PATH="${MODEL}" \
MODEL_SHA256="${MODEL_SHA256}" \
BUNDLE_SIGN_KEY="${SIGN_KEY}" \
BUNDLE_SOURCE_COMMIT="${SOURCE_COMMIT}" \
BUNDLE_BUILDER_IMAGE="${BUILDER_IMAGE}" \
BUNDLE_DIST="${RC_DIR}/bundle-build2" \
CONTAINER_ENGINE="${CONTAINER_ENGINE}" \
make bundle-arm64
cmp \
    "${RC_DIR}/final-dist/${BUNDLE_NAME}.tar.gz" \
    "${RC_DIR}/bundle-build2/${BUNDLE_NAME}.tar.gz"
{
    sha256sum "${RC_DIR}/final-dist/${BUNDLE_NAME}.tar.gz"
    sha256sum "${RC_DIR}/bundle-build2/${BUNDLE_NAME}.tar.gz"
} > "${EVIDENCE_DIR}/artifacts/bundle-reproducibility.sha256"
echo "[PASS] Two complete signed bundle assemblies are byte-identical"

cp \
    "${RC_DIR}/final-dist/${BUNDLE_NAME}.tar.gz.sha256" \
    "${EVIDENCE_DIR}/artifacts/bundle-archive.sha256"
{
    sha256sum "${MODEL}"
    git -c safe.directory='*' -C "${LLAMA_INPUT_ROOT}/source" rev-parse HEAD
    git -c safe.directory='*' -C "${LLAMA_INPUT_ROOT}/source" \
        describe --tags --exact-match HEAD
    grep -E '^(CMAKE_BUILD_TYPE|GGML_OPENMP|LLAMA_BUILD_SERVER):' \
        "${LLAMA_INPUT_ROOT}/build/CMakeCache.txt"
    find "${LLAMA_DIR}" -maxdepth 1 -type f -print0 |
        sort -z | xargs -0 sha256sum
    ldd "${LLAMA_DIR}/llama-server"
} > "${EVIDENCE_DIR}/artifacts/runtime-inputs.txt"

# Phase 6: Live preflight
echo "=== $(ts) Phase 6: Preflight ==="
# Adapt sleep durations for QEMU emulation latency
sed 's/^sleep 5$/sleep 30/' "${PREFLIGHT_SOURCE}" > "${PREFLIGHT_SCRIPT}"
chmod 0755 "${PREFLIGHT_SCRIPT}"
test "$(grep -c '^sleep 30$' "${PREFLIGHT_SCRIPT}")" -eq 2
test "$(grep -c '^sleep 5$' "${PREFLIGHT_SCRIPT}")" -eq 0
diff -u "${PREFLIGHT_SOURCE}" "${PREFLIGHT_SCRIPT}" \
    > "${EVIDENCE_DIR}/orchestration-readiness-override.diff" || true
for svc in exocomp-coordinator exocomp-node; do
    systemctl stop "${svc}" 2>/dev/null || true
    systemctl disable "${svc}" 2>/dev/null || true
done
QUALIFICATION_VERSION="${VERSION}" \
QUALIFICATION_ARCH="${ARCH}" \
QUALIFICATION_ROOT="${RC_DIR}" \
QUALIFICATION_DIST="${RC_DIR}/final-dist" \
bash "${PREFLIGHT_SCRIPT}"
echo "[PASS] Preflight complete"

cp \
    "${BUNDLE_DIR}/bundle.minisig" \
    "${BUNDLE_DIR}/manifest.json" \
    "${BUNDLE_DIR}/manifest.sha256" \
    "${BUNDLE_DIR}/provenance.json" \
    "${BUNDLE_DIR}/sbom.spdx.json" \
    "${EVIDENCE_DIR}/artifacts/"
(
    cd "${BUNDLE_DIR}"
    find LICENSES -type f -print0 | sort -z | xargs -0 sha256sum
) > "${EVIDENCE_DIR}/artifacts/licenses.sha256"

# Phase 7: Operational scenarios
echo "=== $(ts) Phase 7: Operational ==="
mkdir -p "${EVIDENCE_DIR}/operational"
QUALIFICATION_VERSION="${VERSION}" \
QUALIFICATION_ARCH="${ARCH}" \
QUALIFICATION_ROOT="${RC_DIR}" \
QUALIFICATION_EVIDENCE="${EVIDENCE_DIR}/operational" \
bash "${SRC_DIR}/scripts/qualification-live-operational.sh"
echo "[PASS] Operational complete"

# Phase 8: M5 bench short gate (with extended timeout for QEMU)
echo "=== $(ts) Phase 8: M5 bench short ==="
BENCH_HARNESS="${BENCH_HARNESS}" \
BENCH_MODE=short \
LLAMA_SERVER="${LLAMA_DIR}/llama-server" \
LLAMA_LIB_DIR="${LLAMA_DIR}" \
NODE_RELEASE="/opt/exocomp/node/current" \
COORD_RELEASE="/opt/exocomp/coordinator/current" \
MODEL_PATH="${MODEL}" \
MODEL_SHA256="${MODEL_SHA256}" \
BENCH_EVIDENCE_DIR="${EVIDENCE_DIR}/bench-short" \
BENCH_INFERENCE_TIMEOUT_MS=600000 \
CONTAINER_ENGINE="${CONTAINER_ENGINE}" \
make bench-llama-short-shipped
echo "[PASS] M5 bench short gate complete"

# Phase 9: M5 bench full gate (with extended timeout for QEMU)
echo "=== $(ts) Phase 9: M5 bench full ==="
BENCH_HARNESS="${BENCH_HARNESS}" \
LLAMA_SERVER="${LLAMA_DIR}/llama-server" \
LLAMA_LIB_DIR="${LLAMA_DIR}" \
NODE_RELEASE="/opt/exocomp/node/current" \
COORD_RELEASE="/opt/exocomp/coordinator/current" \
MODEL_PATH="${MODEL}" \
MODEL_SHA256="${MODEL_SHA256}" \
BENCH_EVIDENCE_DIR="${EVIDENCE_DIR}/bench" \
BENCH_INFERENCE_TIMEOUT_MS=600000 \
CONTAINER_ENGINE="${CONTAINER_ENGINE}" \
make bench-llama-full
echo "[PASS] M5 bench full gate complete"

# Phase 10: Lifecycle (upgrade + automatic rollback + backup + restore + uninstall)
echo "=== $(ts) Phase 10: Lifecycle ==="
sed 's/^sleep 5$/sleep 30/' "${LIFECYCLE_SOURCE}" > "${LIFECYCLE_SCRIPT}"
chmod 0755 "${LIFECYCLE_SCRIPT}"
test "$(grep -c '^sleep 30$' "${LIFECYCLE_SCRIPT}")" -eq 1
test "$(grep -c '^sleep 5$' "${LIFECYCLE_SCRIPT}")" -eq 0
diff -u "${LIFECYCLE_SOURCE}" "${LIFECYCLE_SCRIPT}" \
    > "${EVIDENCE_DIR}/orchestration-lifecycle-readiness-override.diff" || true
QUALIFICATION_VERSION="${VERSION}" \
QUALIFICATION_ARCH="${ARCH}" \
QUALIFICATION_ROOT="${RC_DIR}" \
QUALIFICATION_DIST="${RC_DIR}/final-dist" \
QUALIFICATION_EVIDENCE="${EVIDENCE_DIR}/lifecycle" \
bash "${LIFECYCLE_SCRIPT}"
echo "[PASS] Lifecycle complete"

echo "=== $(ts) ALL arm64 PHASES COMPLETE ==="
echo "QUALIFICATION_STATUS=pass" > "${RC_DIR}/qualification-status.txt"
echo "STATUS=PASS"
