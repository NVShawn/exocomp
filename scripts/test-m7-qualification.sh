#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
#
# Run one architecture of the M7 shipped-artifact qualification. This wrapper
# intentionally has no best-effort mode: a missing live scenario target or an
# identity mismatch is a failed candidate, not a skipped phase.

set -euo pipefail
umask 077

script_dir="$(cd -- "$(dirname -- "$0")" && pwd)"
repo_root="$(dirname -- "${script_dir}")"

required_variables=(
    ARCH M7_EVIDENCE_DIR M7_CANDIDATE_TAG M7_OPERATOR
    M7_NODE_ARCHIVE M7_NODE_MANIFEST
    M7_COORDINATOR_ARCHIVE M7_COORDINATOR_MANIFEST
    M7_MISSION_CONTROL_IMAGE M7_MISSION_CONTROL_MANIFEST M7_POSTGRES_IMAGE
    M7_MODEL_PATH M7_MODEL_SHA256 M7_MC_SERVICE_URL M7_REDACTED_CONFIG
)
for variable in "${required_variables[@]}"; do
    if [[ -z "${!variable:-}" ]]; then
        echo "M7 qualification requires ${variable}" >&2
        exit 2
    fi
done

case "${ARCH}" in
    amd64) expected_machine="x86_64" ;;
    arm64) expected_machine="aarch64|arm64" ;;
    *) echo "ARCH must be amd64 or arm64" >&2; exit 2 ;;
esac

if [[ -e "${M7_EVIDENCE_DIR}" ]]; then
    echo "refusing to reuse M7_EVIDENCE_DIR: ${M7_EVIDENCE_DIR}" >&2
    exit 1
fi

if ! git -C "${repo_root}" diff --quiet || ! git -C "${repo_root}" diff --cached --quiet || \
    [[ -n "$(git -C "${repo_root}" ls-files --others --exclude-standard)" ]]; then
    echo "M7 qualification requires a clean checkout" >&2
    exit 1
fi

candidate_commit="$(git -C "${repo_root}" rev-list -n 1 "${M7_CANDIDATE_TAG}")"
if [[ "$(git -C "${repo_root}" rev-parse HEAD)" != "${candidate_commit}" ]]; then
    echo "HEAD does not match signed M7 candidate tag ${M7_CANDIDATE_TAG}" >&2
    exit 1
fi

machine="$(uname -m)"
if ! [[ "${machine}" =~ ^(${expected_machine})$ ]]; then
    echo "qualification guest architecture ${machine} does not match ARCH=${ARCH}" >&2
    exit 1
fi
if [[ "$(ps -p 1 -o comm= | tr -d '[:space:]')" != "systemd" ]]; then
    echo "M7 qualification requires a full systemd guest, not a container-only runner" >&2
    exit 1
fi

mkdir -p \
    "${M7_EVIDENCE_DIR}/candidate" \
    "${M7_EVIDENCE_DIR}/host" \
    "${M7_EVIDENCE_DIR}/artifacts" \
    "${M7_EVIDENCE_DIR}/repo-gates" \
    "${M7_EVIDENCE_DIR}/install" \
    "${M7_EVIDENCE_DIR}/security" \
    "${M7_EVIDENCE_DIR}/two-cluster" \
    "${M7_EVIDENCE_DIR}/scale" \
    "${M7_EVIDENCE_DIR}/lifecycle" \
    "${M7_EVIDENCE_DIR}/docs" \
    "${M7_EVIDENCE_DIR}/overrides"

git -C "${repo_root}" verify-tag "${M7_CANDIDATE_TAG}" \
    > "${M7_EVIDENCE_DIR}/candidate/tag-verification.txt" 2>&1
{
    printf 'tag=%s\ncommit=%s\noperator=%s\n' \
        "${M7_CANDIDATE_TAG}" "${candidate_commit}" "${M7_OPERATOR}"
    git -C "${repo_root}" status --porcelain=v1 --untracked-files=all
} > "${M7_EVIDENCE_DIR}/candidate/identity.txt"
{
    date -u +%Y-%m-%dT%H:%M:%SZ
    uname -a
    uname -m
    systemd-detect-virt || true
    systemctl --version
    systemctl is-system-running || true
    lscpu
    free -b
    df -B1 .
    "${CONTAINER_ENGINE%% *}" --version
} > "${M7_EVIDENCE_DIR}/host/guest-runtime.txt"

overrides_args=()
if [[ -n "${M7_OVERRIDES_FILE:-}" ]]; then
    overrides_args=(--overrides-file "${M7_OVERRIDES_FILE}")
fi

python3 "${script_dir}/m7_qualification.py" verify-inputs \
    --architecture "${ARCH}" \
    --candidate-tag "${M7_CANDIDATE_TAG}" \
    --candidate-commit "${candidate_commit}" \
    --operator "${M7_OPERATOR}" \
    --node-archive "${M7_NODE_ARCHIVE}" --node-manifest "${M7_NODE_MANIFEST}" \
    --coordinator-archive "${M7_COORDINATOR_ARCHIVE}" \
    --coordinator-manifest "${M7_COORDINATOR_MANIFEST}" \
    --mission-control-image "${M7_MISSION_CONTROL_IMAGE}" \
    --mission-control-manifest "${M7_MISSION_CONTROL_MANIFEST}" \
    --postgres-image "${M7_POSTGRES_IMAGE}" \
    --model-path "${M7_MODEL_PATH}" --model-sha256 "${M7_MODEL_SHA256}" \
    --mission-control-service-url "${M7_MC_SERVICE_URL}" \
    --redacted-config "${M7_REDACTED_CONFIG}" \
    "${overrides_args[@]}" \
    --output "${M7_EVIDENCE_DIR}/artifacts/identity.json"

if [[ -n "${M7_OVERRIDES_FILE:-}" ]]; then
    cp -- "${M7_OVERRIDES_FILE}" "${M7_EVIDENCE_DIR}/overrides/record.json"
else
    printf '{"overrides": []}\n' > "${M7_EVIDENCE_DIR}/overrides/record.json"
fi

for path in \
    "${M7_NODE_MANIFEST}" \
    "${M7_COORDINATOR_MANIFEST}" \
    "${M7_MISSION_CONTROL_MANIFEST}"; do
    cp -- "${path}" "${M7_EVIDENCE_DIR}/artifacts/"
done
sha256sum \
    "${M7_NODE_ARCHIVE}" \
    "${M7_COORDINATOR_ARCHIVE}" \
    "${M7_MODEL_PATH}" \
    "${M7_REDACTED_CONFIG}" \
    "${M7_NODE_MANIFEST}" \
    "${M7_COORDINATOR_MANIFEST}" \
    "${M7_MISSION_CONTROL_MANIFEST}" \
    > "${M7_EVIDENCE_DIR}/artifacts/checksums.sha256"
cp -- "${repo_root}/mix.lock" "${M7_EVIDENCE_DIR}/artifacts/mix.lock"
sha256sum "${repo_root}/mix.lock" > "${M7_EVIDENCE_DIR}/artifacts/dependency-lock.sha256"
cp -- "${M7_REDACTED_CONFIG}" "${M7_EVIDENCE_DIR}/artifacts/redacted-config.json"
migration_directory="${repo_root}/apps/exocomp_mission_control/priv/repo/migrations"
if [[ ! -d "${migration_directory}" ]]; then
    echo "M7 qualification requires the shipped Mission Control migration directory" >&2
    exit 1
fi
find "${migration_directory}" -maxdepth 1 -type f -name '*.exs' -print0 |
    sort -z | xargs -0r sha256sum > "${M7_EVIDENCE_DIR}/install/migrations.sha256"
if [[ ! -s "${M7_EVIDENCE_DIR}/install/migrations.sha256" ]]; then
    echo "M7 qualification requires at least one Mission Control migration" >&2
    exit 1
fi

has_target() {
    make -C "${repo_root}" -n "$1" >/dev/null 2>&1
}
for required_target in security test-mission-control-scenario mc-scale-full test-mission-control-lifecycle; do
    if ! has_target "${required_target}"; then
        echo "required M7 live target is unavailable: make ${required_target}" >&2
        exit 1
    fi
done

run_target() {
    local destination="$1"
    local name="$2"
    shift 2
    local started finished status log metadata
    log="${destination}/${name}.log"
    metadata="${destination}/${name}.json"
    started="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    if "$@" >"${log}" 2>&1; then
        status=pass
    else
        status=fail
    fi
    finished="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    python3 - "${metadata}" "${name}" "${status}" "${started}" "${finished}" "$@" <<'PY'
import json
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
path.write_text(json.dumps({
    "name": sys.argv[2],
    "status": sys.argv[3],
    "started_at": sys.argv[4],
    "finished_at": sys.argv[5],
    "command": sys.argv[6:],
}, indent=2, sort_keys=True) + "\n", encoding="utf-8")
PY
    if [[ "${status}" != pass ]]; then
        cat "${log}" >&2
        echo "M7 phase failed: ${name}" >&2
        exit 1
    fi
}

run_target "${M7_EVIDENCE_DIR}/repo-gates" fmt-check make -C "${repo_root}" fmt-check
run_target "${M7_EVIDENCE_DIR}/repo-gates" lint make -C "${repo_root}" lint
run_target "${M7_EVIDENCE_DIR}/repo-gates" test make -C "${repo_root}" test
run_target "${M7_EVIDENCE_DIR}/repo-gates" test-release-packaging make -C "${repo_root}" test-release-packaging
run_target "${M7_EVIDENCE_DIR}/repo-gates" test-mission-control-packaging make -C "${repo_root}" test-mission-control-packaging
run_target "${M7_EVIDENCE_DIR}/repo-gates" test-installer make -C "${repo_root}" test-installer
run_target "${M7_EVIDENCE_DIR}/repo-gates" test-bundle make -C "${repo_root}" test-bundle
run_target "${M7_EVIDENCE_DIR}/repo-gates" release-check make -C "${repo_root}" release-check
run_target "${M7_EVIDENCE_DIR}/repo-gates" test-release-matrix make -C "${repo_root}" test-release-matrix ARCH="${ARCH}" SKIP_BUILD=1
run_target "${M7_EVIDENCE_DIR}/install" migration-image make -C "${repo_root}" test-mission-control-image IMAGE="${M7_MISSION_CONTROL_IMAGE}" POSTGRES_IMAGE="${M7_POSTGRES_IMAGE}"
run_target "${M7_EVIDENCE_DIR}/security" security make -C "${repo_root}" security
run_target "${M7_EVIDENCE_DIR}/two-cluster" two-cluster make -C "${repo_root}" test-mission-control-scenario
run_target "${M7_EVIDENCE_DIR}/scale" scale env MC_SERVICE_URL="${M7_MC_SERVICE_URL}" make -C "${repo_root}" mc-scale-full
run_target "${M7_EVIDENCE_DIR}/lifecycle" lifecycle make -C "${repo_root}" test-mission-control-lifecycle
run_target "${M7_EVIDENCE_DIR}/docs" check-links make -C "${repo_root}" check-links

python3 "${script_dir}/m7_qualification.py" write-result \
    --evidence-dir "${M7_EVIDENCE_DIR}" \
    --candidate-tag "${M7_CANDIDATE_TAG}" \
    --candidate-commit "${candidate_commit}" \
    --architecture "${ARCH}" --operator "${M7_OPERATOR}"

printf 'QUALIFICATION_STATUS=pass\n' > "${M7_EVIDENCE_DIR}/qualification-status.txt"
echo "M7 qualification passed for ${ARCH}; finalize the two architecture directories before publication."
