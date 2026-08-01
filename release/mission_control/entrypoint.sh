#!/bin/sh
# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0

set -eu

release_root="${MISSION_CONTROL_RELEASE_DIR:-/opt/mission-control}"
release_bin="${release_root}/bin/mission_control"
release_module="${MISSION_CONTROL_RELEASE_MODULE:-Exocomp.MissionControl.Release}"

if [ ! -x "${release_bin}" ]; then
  echo "Mission Control release is missing or not executable: ${release_bin}" >&2
  exit 78
fi

required_secret() {
  variable="$1"
  case "${variable}" in
    DATABASE_URL) value="${DATABASE_URL:-}" ;;
    SECRET_KEY_BASE) value="${SECRET_KEY_BASE:-}" ;;
    RELEASE_COOKIE) value="${RELEASE_COOKIE:-}" ;;
    *)
      echo "unsupported secret name in Mission Control entrypoint" >&2
      exit 78
      ;;
  esac
  if [ -z "${value}" ]; then
    echo "required Mission Control secret is missing: ${variable}" >&2
    exit 78
  fi
}

require_runtime_secrets() {
  required_secret DATABASE_URL
  required_secret SECRET_KEY_BASE
  required_secret RELEASE_COOKIE
}

case "${1:-server}" in
  migrate)
    require_runtime_secrets
    exec "${release_bin}" eval "${release_module}.migrate()"
    ;;
  server)
    require_runtime_secrets
    exec "${release_bin}" start
    ;;
  healthcheck)
    require_runtime_secrets
    exec "${release_bin}" rpc "${release_module}.healthcheck()"
    ;;
  *)
    echo "usage: $0 {migrate|server|healthcheck}" >&2
    exit 64
    ;;
esac
