#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
#
# Background finalization script for rc.23 qualification.
# Polls arm64 VM until qualification completes, then collects evidence,
# commits, and pushes. The task closure is left to a subsequent agent run
# which will find the READY_TO_CLOSE marker.
#
# Run detached: (setsid bash -c 'bash scripts/rc23-background-finalize.sh >> rc23-finalize.log 2>&1 &' &)

set -uo pipefail

VERSION="0.1.0-rc.23"
SOURCE_COMMIT="902bee1a52bf037fdaab50bd0c71ba82fa51a8d6"
ARM64_IP="192.168.122.171"
AMD64_IP="192.168.122.136"
RC_DIR="/var/lib/exocomp-qualification/rc23"
REPO_EVIDENCE_DIR="docs/release-evidence/v${VERSION}"
SSH_OPTS="-F /dev/null -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10"
READY_MARKER="${REPO_EVIDENCE_DIR}/READY_TO_CLOSE"
FAIL_MARKER="${REPO_EVIDENCE_DIR}/FINALIZATION_FAILED"

ts() { date -u +%Y-%m-%dT%H:%M:%SZ; }

# Change to repo root
cd "$(git rev-parse --show-toplevel)"

# Trap to write FAIL_MARKER if we exit unexpectedly
cleanup() {
    local exit_code=$?
    if [ "${exit_code}" -ne 0 ]; then
        echo "$(ts) FINALIZATION FAILED with exit code ${exit_code}"
        mkdir -p "${REPO_EVIDENCE_DIR}"
        if [ ! -f "${READY_MARKER}" ]; then
            {
                echo "FINALIZATION_FAILED=true"
                echo "EXIT_CODE=${exit_code}"
                echo "TIMESTAMP=$(ts)"
                echo "See rc23-finalize.log for details"
            } > "${FAIL_MARKER}"
        fi
    fi
}
trap cleanup EXIT

echo "=== $(ts) rc.23 background finalizer started ==="
echo "Watching for arm64 qualification completion on ${ARM64_IP}..."

# Check if READY_TO_CLOSE already exists (idempotent restart)
if [ -f "${READY_MARKER}" ]; then
    echo "$(ts) READY_TO_CLOSE already exists — finalization was already done"
    exit 0
fi

# Remove stale FAIL_MARKER if we're restarting
rm -f "${FAIL_MARKER}"

# Wait for arm64 qualification to complete (poll every 5 minutes)
while true; do
    STATUS=$(ssh ${SSH_OPTS} "root@${ARM64_IP}" \
        "cat ${RC_DIR}/qualification-status.txt 2>/dev/null || echo PENDING" 2>/dev/null || echo "SSH_ERROR")

    echo "$(ts) arm64 status: ${STATUS}"

    if echo "${STATUS}" | grep -qxF 'QUALIFICATION_STATUS=pass'; then
        echo "$(ts) arm64 qualification COMPLETE"
        break
    fi

    if echo "${STATUS}" | grep -qE 'FAIL|ERROR'; then
        echo "$(ts) arm64 qualification FAILED: ${STATUS}"
        mkdir -p "${REPO_EVIDENCE_DIR}"
        {
            echo "arm64 qualification FAILED at $(ts)"
            echo "Status: ${STATUS}"
        } > "${FAIL_MARKER}"
        ssh ${SSH_OPTS} "root@${ARM64_IP}" \
            "tail -50 ${RC_DIR}/orchestration.log 2>/dev/null || true" \
            >> "${FAIL_MARKER}" 2>/dev/null || true
        exit 1
    fi

    # Check if the process is still running
    PROC_RUNNING=$(ssh ${SSH_OPTS} "root@${ARM64_IP}" \
        "pgrep -f qualify-arm64-rc23.sh >/dev/null 2>&1 && echo RUNNING || echo STOPPED" \
        2>/dev/null || echo "UNKNOWN")
    echo "$(ts) arm64 qualify process: ${PROC_RUNNING}"

    if [ "${PROC_RUNNING}" = "STOPPED" ] && ! echo "${STATUS}" | grep -q 'pass'; then
        echo "$(ts) arm64 qualify process stopped without passing — checking log..."
        ssh ${SSH_OPTS} "root@${ARM64_IP}" \
            "tail -30 ${RC_DIR}/orchestration.log 2>/dev/null || true"
        mkdir -p "${REPO_EVIDENCE_DIR}"
        echo "arm64 qualify process stopped without passing at $(ts)" > "${FAIL_MARKER}"
        exit 1
    fi

    echo "$(ts) Sleeping 5 minutes before next check..."
    sleep 300
done

echo "=== $(ts) Starting evidence collection ==="

# Run the evidence collector
if ! bash scripts/qualify-rc23-evidence.sh; then
    echo "$(ts) Evidence collector FAILED"
    mkdir -p "${REPO_EVIDENCE_DIR}"
    echo "Evidence collector failed at $(ts)" > "${FAIL_MARKER}"
    exit 1
fi

echo "=== $(ts) Evidence collection complete ==="

# Pull before push to avoid conflicts
git pull --rebase --autostash

# Commit and push
git add docs/release-evidence/
git commit -m "EXOCOMP-123: commit signed rc.23 qualification evidence

Both amd64 (KVM) and arm64 (full-system QEMU) qualification records pass.
All M6-CRIT items recorded. Complete signed indexed evidence assembled.

Generated with https://github.com/lesserevil/oompah

Co-authored-by: oompah <lesserevil@users.noreply.github.com>"
git push -u origin HEAD

echo "=== $(ts) Evidence committed and pushed ==="

# Write the ready-to-close marker so the next agent can close the task
mkdir -p "${REPO_EVIDENCE_DIR}"
{
    echo "READY_TO_CLOSE=true"
    echo "VERSION=${VERSION}"
    echo "COMMIT=${SOURCE_COMMIT}"
    echo "FINALIZATION_TIMESTAMP=$(ts)"
    echo "EVIDENCE_DIR=${REPO_EVIDENCE_DIR}"
} > "${READY_MARKER}"

echo "=== $(ts) READY_TO_CLOSE marker written at ${READY_MARKER} ==="
echo "=== $(ts) rc.23 background finalization COMPLETE. Next agent should close EXOCOMP-123. ==="
