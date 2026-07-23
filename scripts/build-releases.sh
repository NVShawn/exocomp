#!/bin/sh

set -eu

architecture="${1:-}"
container_engine="${CONTAINER_ENGINE:-docker}"
lock_file="$(dirname "$0")/../release/builders.lock"

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

"$(dirname "$0")/check-builder-capability.sh" "${architecture}"
require_clean_checkout

builder_image="docker.io/hexpm/elixir:${BUILDER_TAG}@${builder_digest}"
target_platform="linux/${architecture}"
build_path="_build/release/${architecture}"

echo "Building node and coordinator releases for ${target_platform}"
# shellcheck disable=SC2016 # MIX_BUILD_PATH is intentionally expanded inside the container.
"${container_engine}" run \
  --rm \
  --init \
  --platform "${target_platform}" \
  --pull never \
  --user "$(id -u):$(id -g)" \
  --env "ELIXIR_VERSION=${ELIXIR_VERSION}" \
  --env "OTP_VERSION=${OTP_VERSION}" \
  --env "GLIBC_BASELINE=${GLIBC_BASELINE}" \
  --env "MIX_ENV=prod" \
  --env "MIX_BUILD_PATH=${build_path}" \
  --volume "$(pwd):/workspace" \
  --workdir /workspace \
  "${builder_image}" \
  sh -c 'scripts/verify-toolchain.sh &&
    rm -rf "${MIX_BUILD_PATH}" &&
    mix compile --warnings-as-errors &&
    mix release exocomp_node --overwrite &&
    mix release exocomp_coordinator --overwrite &&
    scripts/smoke-releases.sh prod "${MIX_BUILD_PATH}"'

echo "Built ${target_platform} releases under ${build_path}/rel"
