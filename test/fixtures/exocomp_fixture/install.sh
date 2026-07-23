#!/usr/bin/env bash
# install.sh — Idempotent installer for the exocomp-fixture systemd service.
#
# Usage (must be run as root or via sudo):
#   sudo bash test/fixtures/exocomp_fixture/install.sh
#
# What this script does:
#   1. Copies bin/exocomp-fixture  →  /usr/local/bin/exocomp-fixture
#   2. Copies exocomp-fixture.service → /etc/systemd/system/exocomp-fixture.service
#   3. Runs systemctl daemon-reload
#   4. Enables and starts exocomp-fixture.service
#
# The script is safe to run repeatedly (idempotent).  Running it again after
# the service is already installed will update the binary and unit file and
# restart the service so the new version takes effect.
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

# Resolve script directory so the installer works regardless of CWD.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UNIT_SRC="${SCRIPT_DIR}/${SERVICE_NAME}.service"
BIN_SRC="${SCRIPT_DIR}/bin/${SERVICE_NAME}"

# ── Preflight ──────────────────────────────────────────────────────────────

if [[ "$(id -u)" -ne 0 ]]; then
    echo "ERROR: ${0} must be run as root (try: sudo ${0})" >&2
    exit 1
fi

if [[ ! -f "${UNIT_SRC}" ]]; then
    echo "ERROR: unit file not found: ${UNIT_SRC}" >&2
    exit 1
fi

if [[ ! -f "${BIN_SRC}" ]]; then
    echo "ERROR: service binary not found: ${BIN_SRC}" >&2
    exit 1
fi

if ! command -v systemctl >/dev/null 2>&1; then
    echo "ERROR: systemctl not found — install this script inside a VM or privileged container" >&2
    exit 1
fi

# ── Install ────────────────────────────────────────────────────────────────

echo "Installing ${SERVICE_NAME} fixture service..."

# 1. Install the binary.
echo "  → ${BIN_DEST}"
cp -f "${BIN_SRC}" "${BIN_DEST}"
chmod 755 "${BIN_DEST}"

# 2. Install the unit file.
echo "  → ${UNIT_FILE}"
cp -f "${UNIT_SRC}" "${UNIT_FILE}"
chmod 644 "${UNIT_FILE}"

# 3. Reload systemd so it picks up the new/updated unit.
echo "  → systemctl daemon-reload"
systemctl daemon-reload

# 4. Enable the service so it starts on boot (idempotent).
echo "  → systemctl enable ${SERVICE_NAME}"
systemctl enable "${SERVICE_NAME}"

# 5. Start (or restart if already running) the service.
if systemctl is-active --quiet "${SERVICE_NAME}"; then
    echo "  → systemctl restart ${SERVICE_NAME}  (was already running)"
    systemctl restart "${SERVICE_NAME}"
else
    echo "  → systemctl start ${SERVICE_NAME}"
    systemctl start "${SERVICE_NAME}"
fi

# 6. Report final status.
echo ""
echo "${SERVICE_NAME} fixture service installed and started successfully."
systemctl status "${SERVICE_NAME}" --no-pager --lines=5 || true
