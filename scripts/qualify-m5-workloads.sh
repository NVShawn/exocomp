#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
#
# Qualify the remaining M5 workloads on a dedicated amd64 or arm64 guest.
# This is intentionally narrower than release publication qualification: it
# builds an untagged candidate, installs it through the signed offline bundle,
# and records the shipped-artifact restart, polling, recovery, and soak gate.

set -euo pipefail
umask 077

architecture="${M5_ARCH:?M5_ARCH is required (amd64 or arm64)}"
source_commit="${M5_SOURCE_COMMIT:?M5_SOURCE_COMMIT is required}"
source_dir="${M5_SOURCE_DIR:-$(git rev-parse --show-toplevel)}"
qualification_root="${M5_QUALIFICATION_ROOT:-/var/lib/exocomp-qualification/m5-${source_commit:0:12}-${architecture}}"
version="${M5_ARTIFACT_VERSION:-0.1.0}"
sign_key="${M5_SIGN_KEY:-/var/lib/exocomp-qualification/qualification.key}"
model="${M5_MODEL_PATH:-/var/lib/exocomp-qualification/inputs/qwen2.5-1.5b-instruct-q4_k_m.gguf}"
model_sha256="${M5_MODEL_SHA256:-6a1a2eb6d15622bf3c96857206351ba97e1af16c30d7a74ee38970e434e9407e}"
container_engine="${CONTAINER_ENGINE:-podman}"
evidence_dir="${qualification_root}/evidence/raw/${architecture}"
dist_dir="${qualification_root}/dist"
rollback_dir="${qualification_root}/rollback"

case "${architecture}" in
    amd64)
        llama_dir="${M5_LLAMA_LIB_DIR:-/var/lib/exocomp-qualification/inputs/llama-b10107-no-openmp/runtime}"
        ;;
    arm64)
        llama_dir="${M5_LLAMA_LIB_DIR:-/var/lib/exocomp-qualification/inputs/llama-b10107-no-openmp/build/bin}"
        ;;
    *)
        printf 'M5_ARCH must be amd64 or arm64, got %s\n' "${architecture}" >&2
        exit 2
        ;;
esac
llama_server="${M5_LLAMA_SERVER:-${llama_dir}/llama-server}"

if [[ "${M5_DEDICATED_GUEST:-}" != "1" ]]; then
    echo "M5_DEDICATED_GUEST=1 is required; preflight replaces Exocomp-owned guest state" >&2
    exit 2
fi
if [[ -e "${qualification_root}" ]]; then
    echo "refusing to reuse qualification root: ${qualification_root}" >&2
    exit 1
fi
if [[ "$(git -C "${source_dir}" rev-parse HEAD)" != "${source_commit}" ]]; then
    echo "source checkout does not match M5_SOURCE_COMMIT" >&2
    exit 1
fi
if [[ -n "$(git -C "${source_dir}" status --porcelain=v1 --untracked-files=all)" ]]; then
    echo "qualification requires a clean source checkout" >&2
    exit 1
fi

for required in "${sign_key}" "${model}" "${llama_server}"; do
    [[ -f "${required}" ]] || {
        echo "required qualification input is missing: ${required}" >&2
        exit 1
    }
done
[[ -d "${llama_dir}" ]] || {
    echo "llama library directory is missing: ${llama_dir}" >&2
    exit 1
}
printf '%s  %s\n' "${model_sha256}" "${model}" | sha256sum --check --status

mkdir -p "${evidence_dir}/repo-gates" "${rollback_dir}" "${dist_dir}"
ln -s "${source_dir}" "${qualification_root}/src-gates"
log="${qualification_root}/orchestration.log"
exec > >(tee -a "${log}") 2>&1

timestamp() { date -u +%Y-%m-%dT%H:%M:%SZ; }

echo "=== $(timestamp) M5 workload qualification ${architecture} ${source_commit} ==="

{
    printf 'artifact_version=%s\nsource_commit=%s\nsource_tag=untagged\n' \
        "${version}" "${source_commit}"
    printf 'architecture=%s\nhostname=%s\nkernel=%s\nvirtualization=%s\n' \
        "$(uname -m)" "$(hostname)" "$(uname -r)" "$(systemd-detect-virt || true)"
    grep '^PRETTY_NAME=' /etc/os-release
    nproc
    free -b
} > "${evidence_dir}/host-and-candidate.txt"

# Keep a local-only rollback archive before destructive preflight. It may
# contain credentials, so it is deliberately outside evidence collection.
rollback_paths=()
for path in \
    /opt/exocomp \
    /var/lib/exocomp-node \
    /var/lib/exocomp-coordinator \
    /etc/systemd/system/exocomp-node.service \
    /etc/systemd/system/exocomp-coordinator.service \
    /etc/sudoers.d/exocomp-node \
    /etc/sudoers.d/exocomp-coordinator; do
    [[ -e "${path}" ]] && rollback_paths+=("${path#/}")
done
if ((${#rollback_paths[@]} > 0)); then
    tar --acls --xattrs -C / -czf "${rollback_dir}/exocomp-state.tar.gz" "${rollback_paths[@]}"
fi
cat > "${rollback_dir}/README.txt" <<EOF
This archive is local-only because it may contain protected release state.
Stop Exocomp services, remove the replacement paths, extract from /, run
systemctl daemon-reload, and start the restored services to roll back.
EOF

cd "${source_dir}"

echo "=== $(timestamp) focused repository gates ==="
env CONTAINER_ENGINE="${container_engine}" make fmt-check \
    > "${evidence_dir}/repo-gates/fmt-check.txt" 2>&1
env CONTAINER_ENGINE="${container_engine}" make lint \
    > "${evidence_dir}/repo-gates/lint.txt" 2>&1
env CONTAINER_ENGINE="${container_engine}" make test-m5-qualification \
    > "${evidence_dir}/repo-gates/test-m5-qualification.txt" 2>&1

echo "=== $(timestamp) build shipped ${architecture} artifacts ==="
RELEASE_VERSION="${version}" \
RELEASE_OUTPUT_DIR="${qualification_root}/releases" \
CONTAINER_ENGINE="${container_engine}" \
make "build-${architecture}" \
    > "${evidence_dir}/build.txt" 2>&1

echo "=== $(timestamp) build standalone benchmark harness ==="
CONTAINER_ENGINE="${container_engine}" make bench-harness \
    > "${evidence_dir}/bench-harness-build.txt" 2>&1
bench_harness="${source_dir}/_build/prod/rel/bench_harness/bin/bench_harness"
[[ -x "${bench_harness}" ]]

# shellcheck disable=SC1091
. "${source_dir}/release/builders.lock"
if [[ "${architecture}" == "amd64" ]]; then
    builder_image="docker.io/hexpm/elixir:${BUILDER_TAG}@${BUILDER_AMD64_DIGEST}"
    NODE_ARCHIVE_AMD64="${qualification_root}/releases/exocomp-node-${version}-linux-amd64.tar.gz" \
    COORD_ARCHIVE_AMD64="${qualification_root}/releases/exocomp-coordinator-${version}-linux-amd64.tar.gz" \
    LLAMA_SERVER_AMD64="${llama_server}" \
    LLAMA_LIB_DIR_AMD64="${llama_dir}" \
    MODEL_PATH="${model}" \
    MODEL_SHA256="${model_sha256}" \
    BUNDLE_VERSION="${version}" \
    BUNDLE_SOURCE_COMMIT="${source_commit}" \
    BUNDLE_BUILDER_IMAGE="${builder_image}" \
    BUNDLE_SIGN_KEY="${sign_key}" \
    BUNDLE_DIST="${dist_dir}" \
    CONTAINER_ENGINE="${container_engine}" \
    make bundle-amd64 > "${evidence_dir}/bundle-build.txt" 2>&1
else
    builder_image="docker.io/hexpm/elixir:${BUILDER_TAG}@${BUILDER_ARM64_DIGEST}"
    NODE_ARCHIVE_ARM64="${qualification_root}/releases/exocomp-node-${version}-linux-arm64.tar.gz" \
    COORD_ARCHIVE_ARM64="${qualification_root}/releases/exocomp-coordinator-${version}-linux-arm64.tar.gz" \
    LLAMA_SERVER_ARM64="${llama_server}" \
    LLAMA_LIB_DIR_ARM64="${llama_dir}" \
    MODEL_PATH="${model}" \
    MODEL_SHA256="${model_sha256}" \
    BUNDLE_VERSION="${version}" \
    BUNDLE_SOURCE_COMMIT="${source_commit}" \
    BUNDLE_BUILDER_IMAGE="${builder_image}" \
    BUNDLE_SIGN_KEY="${sign_key}" \
    BUNDLE_DIST="${dist_dir}" \
    CONTAINER_ENGINE="${container_engine}" \
    make bundle-arm64 > "${evidence_dir}/bundle-build.txt" 2>&1
fi

echo "=== $(timestamp) offline install and readiness preflight ==="
QUALIFICATION_VERSION="${version}" \
QUALIFICATION_ARCH="${architecture}" \
QUALIFICATION_ROOT="${qualification_root}" \
QUALIFICATION_DIST="${dist_dir}" \
QUALIFICATION_EVIDENCE="${evidence_dir}/preflight" \
bash "${source_dir}/scripts/qualification-live-preflight.sh"

echo "=== $(timestamp) two-hour shipped-artifact workload and soak gate ==="
BENCH_HARNESS="${bench_harness}" \
LLAMA_SERVER="${llama_server}" \
LLAMA_LIB_DIR="${llama_dir}" \
NODE_RELEASE="/opt/exocomp/node/current" \
COORD_RELEASE="/opt/exocomp/coordinator/current" \
MODEL_PATH="${model}" \
MODEL_SHA256="${model_sha256}" \
BENCH_EVIDENCE_DIR="${evidence_dir}/bench" \
BENCH_INFERENCE_TIMEOUT_MS="${M5_INFERENCE_TIMEOUT_MS:-120000}" \
BENCH_RESTART_TIMEOUT_MS="${M5_RESTART_TIMEOUT_MS:-120000}" \
CONTAINER_ENGINE="${container_engine}" \
make bench-llama-full

python3 - "${evidence_dir}/bench/summary.json" "${source_commit}" "${architecture}" <<'PY'
import json
import pathlib
import sys

summary_path = pathlib.Path(sys.argv[1])
commit = sys.argv[2]
architecture = sys.argv[3]
summary = json.loads(summary_path.read_text(encoding="utf-8"))
assert summary["artifact_identity"]["source_commit"] == commit
assert summary["artifact_identity"]["architecture"] == architecture
assert summary["config"]["mode"] == "full"
assert summary["config"]["run_seconds"] >= 7200

required = {
    "llama.restart.total_ms",
    "coordinator.poll.cycle_ms.p95",
    "recovery.observation_to_verification_ms",
    "recovery.safety_pass",
    "soak.required_metrics_present",
    "soak.pass",
}
assert required <= summary["metrics"].keys(), required - summary["metrics"].keys()
failed = [gate for gate in summary["gate_results"] if gate["status"] != "pass"]
assert not failed, failed
PY

xz -T0 -6 "${evidence_dir}/bench/samples.jsonl"
printf 'QUALIFICATION_STATUS=pass\n' > "${qualification_root}/qualification-status.txt"
echo "=== $(timestamp) M5 workload qualification PASS (${architecture}) ==="
