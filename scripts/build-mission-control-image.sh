#!/bin/sh
# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0

set -eu

architecture="${1:-}"
script_dir="$(cd -- "$(dirname -- "$0")" && pwd)"
repo_root="$(dirname -- "${script_dir}")"
container_engine_command="${CONTAINER_ENGINE:-docker}"

# shellcheck disable=SC1090,SC1091
. "${repo_root}/release/builders.lock"

case "${architecture}" in
  amd64) builder_digest="${BUILDER_AMD64_DIGEST}"; target_digest="${CLEAN_TARGET_AMD64_DIGEST}" ;;
  arm64) builder_digest="${BUILDER_ARM64_DIGEST}"; target_digest="${CLEAN_TARGET_ARM64_DIGEST}" ;;
  *)
    echo "unsupported or missing architecture '${architecture}'; expected amd64 or arm64" >&2
    exit 2
    ;;
esac

container_engine_binary="${container_engine_command%% *}"
if ! command -v "${container_engine_binary}" >/dev/null 2>&1; then
  echo "container engine '${container_engine_binary}' was not found" >&2
  exit 1
fi

version="${MISSION_CONTROL_VERSION:-$(sed -n 's/^[[:space:]]*version: "\([^"]*\)",$/\1/p' "${repo_root}/mix.exs" | head -1)}"
source_commit="$(git -C "${repo_root}" rev-parse HEAD)"
source_epoch="${SOURCE_DATE_EPOCH:-$(git -C "${repo_root}" show -s --format=%ct HEAD)}"
release_name="${MISSION_CONTROL_RELEASE_NAME:-mission_control}"
image_ref="${MISSION_CONTROL_IMAGE:-exocomp/mission-control:${version}-${architecture}}"
output_dir="${MISSION_CONTROL_OUTPUT_DIR:-${repo_root}/dist/mission-control}"
builder_image="docker.io/hexpm/elixir:${BUILDER_TAG}@${builder_digest}"
target_image="docker.io/library/debian:${CLEAN_TARGET_TAG}@${target_digest}"

if [ -n "$(git -C "${repo_root}" status --porcelain=v1 --untracked-files=all)" ]; then
  echo "Mission Control image builds require a clean checkout" >&2
  exit 1
fi

echo "Building ${image_ref} for linux/${architecture}"
# shellcheck disable=SC2086
${container_engine_command} build \
  --platform "linux/${architecture}" \
  --pull=never \
  --file "${repo_root}/release/mission_control/Containerfile" \
  --tag "${image_ref}" \
  --build-arg "BUILDER_IMAGE=${builder_image}" \
  --build-arg "TARGET_IMAGE=${target_image}" \
  --build-arg "RELEASE_NAME=${release_name}" \
  --build-arg "RELEASE_ARCH=${architecture}" \
  --build-arg "VERSION=${version}" \
  --build-arg "SOURCE_COMMIT=${source_commit}" \
  --build-arg "SOURCE_EPOCH=${source_epoch}" \
  --build-arg "BUILDER_DIGEST=${builder_digest}" \
  "${repo_root}"

image_id="$(${container_engine_command} image inspect --format '{{.Id}}' "${image_ref}")"
case "${image_id}" in
  sha256:[0-9a-fA-F]*) image_digest="$(printf '%s' "${image_id}" | tr '[:upper:]' '[:lower:]')" ;;
  *) echo "container engine returned an invalid image identity: ${image_id}" >&2; exit 1 ;;
esac

"${script_dir}/package-mission-control.sh" \
  --image-ref "${image_ref}" \
  --image-digest "${image_digest}" \
  --version "${version}" \
  --arch "${architecture}" \
  --source-commit "${source_commit}" \
  --source-epoch "${source_epoch}" \
  --builder-image "${builder_image}" \
  --output-dir "${output_dir}" \
  --build-command "scripts/build-mission-control-image.sh ${architecture}"

echo "Built ${image_ref} (${image_digest})"
