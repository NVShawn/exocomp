#!/usr/bin/env bash
# cleanup.sh — Idempotent cleanup for the exocomp-fixture systemd service.
#
# Usage (must be run as root or via sudo):
#   sudo bash test/fixtures/exocomp_fixture/cleanup.sh
#
# What this script does:
#   1. Stops  exocomp-fixture.service  (no-op if not running)
#   2. Disables exocomp-fixture.service (no-op if not enabled)
#   3. Removes /etc/systemd/system/exocomp-fixture.service
#   4. Removes /usr/local/bin/exocomp-fixture
#   5. Removes /run/exocomp-fixture/ (runtime state directory)
#   6. Runs systemctl daemon-reload
#
# The script ONLY removes resources with the "exocomp-fixture" prefix.  It
# never touches any other systemd unit, binary, or directory.
#
# The script is safe to run on a clean system — every step is a no-op when
# the fixture was never installed (or has already been cleaned up).
#
# NOTE: These fixture resources are ONLY for integration testing.  Run this
# script inside a disposable VM or privileged container — never on a shared
# or production host.  See test/fixtures/exocomp_fixture/README.md and
# docs/testing-systemd-fixture.md for environment requirements.

set -euo pipefail

# ── Constants ──────────────────────────────────────────────────────────────

SERVICE_NAME="exocomp-fixture"
UNIT_FILE="/etc/systemd/system/${SERVICE_NAME}.service"
BIN_DEST="/usr/local/bin/${SERVICE_NAME}"
RUNTIME_DIR="/run/${SERVICE_NAME}"

# ── Preflight ──────────────────────────────────────────────────────────────

if [[ "$(id -u)" -ne 0 ]]; then
    echo "ERROR: ${0} must be run as root (try: sudo ${0})" >&2
    exit 1
fi

# ── Cleanup ────────────────────────────────────────────────────────────────

echo "Removing ${SERVICE_NAME} fixture service..."

# 1. Stop the service (no-op when not running; ignore unknown-unit error).
if command -v systemctl >/dev/null 2>&1; then
    if systemctl is-active --quiet "${SERVICE_NAME}" 2>/dev/null; then
        echo "  → systemctl stop ${SERVICE_NAME}"
        systemctl stop "${SERVICE_NAME}" || true
    else
        echo "  → ${SERVICE_NAME} is not running (skip stop)"
    fi

    # 2. Disable the service (no-op when not enabled; ignore unknown-unit error).
    if systemctl is-enabled --quiet "${SERVICE_NAME}" 2>/dev/null; then
        echo "  → systemctl disable ${SERVICE_NAME}"
        systemctl disable "${SERVICE_NAME}" || true
    else
        echo "  → ${SERVICE_NAME} is not enabled (skip disable)"
    fi
else
    echo "  → systemctl not found, skipping stop/disable"
fi

# 3. Remove the unit file.
if [[ -f "${UNIT_FILE}" ]]; then
    echo "  → rm -f ${UNIT_FILE}"
    rm -f "${UNIT_FILE}"
else
    echo "  → ${UNIT_FILE} not present (skip)"
fi

# 4. Remove the installed binary.
if [[ -f "${BIN_DEST}" ]]; then
    echo "  → rm -f ${BIN_DEST}"
    rm -f "${BIN_DEST}"
else
    echo "  → ${BIN_DEST} not present (skip)"
fi

# 5. Remove the runtime state directory.
if [[ -d "${RUNTIME_DIR}" ]]; then
    echo "  → rm -rf ${RUNTIME_DIR}"
    rm -rf "${RUNTIME_DIR}"
else
    echo "  → ${RUNTIME_DIR} not present (skip)"
fi

# 6. Reload systemd so it forgets the removed unit.
if command -v systemctl >/dev/null 2>&1; then
    echo "  → systemctl daemon-reload"
    systemctl daemon-reload || true
fi

echo ""
echo "${SERVICE_NAME} fixture service removed."
