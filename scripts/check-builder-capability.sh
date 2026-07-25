#!/bin/sh
# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0

set -eu

architecture="${1:-}"
container_engine_command="${CONTAINER_ENGINE:-docker}"
lock_file="$(dirname "$0")/../release/builders.lock"

run_container_engine() {
  # shellcheck disable=SC2086
  ${container_engine_command} "$@"
}

# shellcheck disable=SC1090
. "${lock_file}"

case "${architecture}" in
  amd64)
    expected_machine="x86_64"
    builder_digest="${BUILDER_AMD64_DIGEST}"
    ;;
  arm64)
    expected_machine="aarch64"
    builder_digest="${BUILDER_ARM64_DIGEST}"
    ;;
  *)
    echo "unsupported or missing architecture '${architecture}'; expected one of: ${SUPPORTED_ARCHITECTURES}" >&2
    exit 2
    ;;
esac

container_engine_binary="${container_engine_command%% *}"
if ! command -v "${container_engine_binary}" >/dev/null 2>&1; then
  echo "container engine '${container_engine_binary}' was not found; install Docker or set CONTAINER_ENGINE" >&2
  exit 1
fi

if ! run_container_engine info >/dev/null 2>&1; then
  echo "container engine '${container_engine_command}' is unavailable; check that its daemon is running and accessible" >&2
  exit 1
fi

builder_image="docker.io/hexpm/elixir:${BUILDER_TAG}@${builder_digest}"
target_platform="linux/${architecture}"

echo "Pulling pinned ${target_platform} builder ${builder_image}"
if ! run_container_engine pull --platform "${target_platform}" "${builder_image}"; then
  echo "failed to pull the pinned ${target_platform} builder with ${container_engine_command}" >&2
  exit 1
fi

error_file="$(mktemp)"
trap 'rm -f "${error_file}"' EXIT HUP INT TERM

if ! actual_machine="$(
  run_container_engine run \
    --rm \
    --platform "${target_platform}" \
    --pull never \
    "${builder_image}" \
    uname -m 2>"${error_file}"
)"; then
  cat "${error_file}" >&2
  echo "cannot execute ${target_platform} containers with ${container_engine_command}; enable native support or binfmt/QEMU emulation" >&2
  exit 1
fi

if [ "${actual_machine}" != "${expected_machine}" ]; then
  echo "container capability mismatch: ${target_platform} reported '${actual_machine}', expected '${expected_machine}'" >&2
  exit 1
fi

echo "${container_engine_command} can execute ${target_platform} (${actual_machine})"
