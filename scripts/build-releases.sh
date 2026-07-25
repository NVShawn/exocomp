#!/bin/sh
# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0

set -eu

architecture="${1:-}"
container_engine_command="${CONTAINER_ENGINE:-docker}"
container_user_flag="${_CONTAINER_USER_FLAG:---user $(id -u):$(id -g)}"
script_dir="$(cd "$(dirname "$0")" && pwd)"
lock_file="${script_dir}/../release/builders.lock"

run_container_engine() {
  # CONTAINER_ENGINE may include connection arguments, such as
  # "podman --remote --url unix:///run/user/1000/podman/podman.sock".
  # shellcheck disable=SC2086
  ${container_engine_command} "$@"
}

# shellcheck disable=SC1090
. "${lock_file}"

case "${architecture}" in
  amd64)
    builder_digest="${BUILDER_AMD64_DIGEST}"
    ;;
  arm64)
    builder_digest="${BUILDER_ARM64_DIGEST}"
    ;;
  *)
    echo "unsupported or missing architecture '${architecture}'; expected one of: ${SUPPORTED_ARCHITECTURES}" >&2
    exit 2
    ;;
esac

require_clean_checkout() {
  if [ -n "$(git status --porcelain=v1 --untracked-files=all)" ]; then
    echo "release builds require a clean checkout; commit or remove all tracked and untracked changes" >&2
    exit 1
  fi
}

require_clean_checkout

"${script_dir}/check-builder-capability.sh" "${architecture}"
require_clean_checkout

builder_image="docker.io/hexpm/elixir:${BUILDER_TAG}@${builder_digest}"
target_platform="linux/${architecture}"
build_path="_build/release/${architecture}"

echo "Building node and coordinator releases for ${target_platform}"
# shellcheck disable=SC2016 # MIX_BUILD_PATH is intentionally expanded inside the container.
# shellcheck disable=SC2086 # User flag may intentionally contain an option and value.
run_container_engine run \
  --rm \
  --init \
  ${container_user_flag} \
  --platform "${target_platform}" \
  --pull never \
  --env "ELIXIR_VERSION=${ELIXIR_VERSION}" \
  --env "OTP_VERSION=${OTP_VERSION}" \
  --env "GLIBC_BASELINE=${GLIBC_BASELINE}" \
  --env "MIX_ENV=prod" \
  --env "ERL_COMPILER_OPTIONS=deterministic" \
  --env "MIX_BUILD_PATH=${build_path}" \
  --env "MIX_HOME=/workspace/.mix-home" \
  --env "HEX_HOME=/workspace/.hex-home" \
  --volume "$(pwd):/workspace" \
  --workdir /workspace \
  "${builder_image}" \
  sh -c 'mix local.hex --force --quiet &&
    scripts/verify-toolchain.sh &&
    mix deps.get &&
    scripts/prepare-release-deps.sh &&
    rm -rf "${MIX_BUILD_PATH}" &&
    mix compile --warnings-as-errors &&
    mix release exocomp_node --overwrite &&
    mix release exocomp_coordinator --overwrite &&
    scripts/smoke-releases.sh prod "${MIX_BUILD_PATH}"'

echo "Built ${target_platform} releases under ${build_path}/rel"

# Inspect runtime dependencies for each release with the host readelf. ELF
# metadata inspection does not execute the target and works across architectures.
echo ""
echo "Inspecting runtime dependencies for ${target_platform} releases"
for release in exocomp_node exocomp_coordinator; do
  release_dir="${build_path}/rel/${release}"
  echo "  ${release}: ${release_dir}"
  READELF="${READELF:-readelf}" \
    "${script_dir}/inspect-release-deps.sh" "${architecture}" "${release_dir}"
done

echo ""
echo "All runtime dependency checks passed for ${target_platform}."

echo ""
echo "Packaging deterministic, secret-free release archives"
"${script_dir}/package-releases.sh" "${architecture}"
