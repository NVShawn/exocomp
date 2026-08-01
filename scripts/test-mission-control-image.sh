#!/bin/sh
# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0

set -eu

image="${IMAGE:-}"
postgres_image="${POSTGRES_IMAGE:-}"
engine_command="${CONTAINER_ENGINE:-docker}"
network="exocomp-mission-control-test-$$"
database_container="${network}-postgres"
state_volume="${network}-state"
log_volume="${network}-logs"

die() {
  echo "Mission Control image test failed: $*" >&2
  exit 1
}

cleanup() {
  # These are disposable, uniquely named resources; cleanup is deliberately
  # narrow so an interrupted test cannot touch an operator's containers.
  ${engine_command} rm --force "${database_container}" "${network}-app" >/dev/null 2>&1 || true
  ${engine_command} volume rm "${state_volume}" "${log_volume}" >/dev/null 2>&1 || true
  ${engine_command} network rm "${network}" >/dev/null 2>&1 || true
}
trap cleanup EXIT HUP INT TERM

[ -n "${image}" ] || die "IMAGE is required"
[ -n "${postgres_image}" ] || die "POSTGRES_IMAGE is required and must be digest-pinned"
echo "${postgres_image}" | grep -Eq '@sha256:[0-9a-f]{64}$' ||
  die "POSTGRES_IMAGE must include a complete @sha256 digest"

engine_binary="${engine_command%% *}"
command -v "${engine_binary}" >/dev/null 2>&1 || die "container engine not found: ${engine_binary}"

${engine_command} network create "${network}" >/dev/null
${engine_command} volume create "${state_volume}" >/dev/null
${engine_command} volume create "${log_volume}" >/dev/null

database_password="$(dd if=/dev/urandom bs=18 count=1 2>/dev/null | od -An -tx1 | tr -d ' \n')"
secret_key_base="$(dd if=/dev/urandom bs=48 count=1 2>/dev/null | od -An -tx1 | tr -d ' \n')"
release_cookie="$(dd if=/dev/urandom bs=24 count=1 2>/dev/null | od -An -tx1 | tr -d ' \n')"
database_url="ecto://mission_control:${database_password}@${database_container}:5432/mission_control_test"

${engine_command} run --detach --name "${database_container}" --network "${network}" \
  --env POSTGRES_DB=mission_control_test \
  --env POSTGRES_USER=mission_control \
  --env "POSTGRES_PASSWORD=${database_password}" \
  "${postgres_image}" >/dev/null

ready=0
attempt=0
while [ "${attempt}" -lt 60 ]; do
  if ${engine_command} exec "${database_container}" pg_isready \
      --username mission_control --dbname mission_control_test >/dev/null 2>&1; then
    ready=1
    break
  fi
  attempt=$((attempt + 1))
  sleep 1
done
[ "${ready}" -eq 1 ] || die "PostgreSQL did not become ready"

common_args="--network ${network} --read-only --tmpfs /tmp:rw,nosuid,nodev \
  --mount type=volume,source=${state_volume},target=/var/lib/exocomp/mission-control \
  --mount type=volume,source=${log_volume},target=/var/log/exocomp/mission-control \
  --env DATABASE_URL=${database_url} \
  --env SECRET_KEY_BASE=${secret_key_base} \
  --env RELEASE_COOKIE=${release_cookie}"

# shellcheck disable=SC2086
${engine_command} run --rm ${common_args} "${image}" migrate >/dev/null

# Missing secrets must fail before the release starts. Keep this invocation
# free of the real secret values so a diagnostic cannot leak them.
if ${engine_command} run --rm --network "${network}" --read-only --tmpfs /tmp:rw,nosuid,nodev \
    "${image}" server >/dev/null 2>&1; then
  die "server accepted missing runtime secrets"
fi

# shellcheck disable=SC2086
${engine_command} run --detach --name "${network}-app" ${common_args} "${image}" server >/dev/null

attempt=0
while [ "${attempt}" -lt 60 ]; do
  health="$(${engine_command} inspect --format '{{.State.Health.Status}}' "${network}-app" 2>/dev/null || true)"
  if [ "${health}" = "healthy" ]; then
    break
  fi
  [ "${health}" = "unhealthy" ] && die "Mission Control healthcheck reported unhealthy"
  attempt=$((attempt + 1))
  sleep 1
done
[ "${health}" = "healthy" ] || die "Mission Control did not become ready"

user="$(${engine_command} inspect --format '{{.Config.User}}' "${network}-app")"
[ "${user}" = "10001:10001" ] || die "image did not run as UID 10001:10001"
readonly_root="$(${engine_command} inspect --format '{{.HostConfig.ReadonlyRootfs}}' "${network}-app")"
[ "${readonly_root}" = "true" ] || die "test container root filesystem is not read-only"

${engine_command} restart "${network}-app" >/dev/null
attempt=0
while [ "${attempt}" -lt 60 ]; do
  health="$(${engine_command} inspect --format '{{.State.Health.Status}}' "${network}-app" 2>/dev/null || true)"
  [ "${health}" = "healthy" ] && break
  [ "${health}" = "unhealthy" ] && die "Mission Control was unhealthy after restart"
  attempt=$((attempt + 1))
  sleep 1
done
[ "${health}" = "healthy" ] || die "Mission Control did not recover after restart"

echo "Mission Control image migration, secret rejection, readiness, and restart checks passed"
