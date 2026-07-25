#!/bin/sh
# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0

set -eu

architecture="${1:-}"
script_dir="$(cd "$(dirname "$0")" && pwd)"
repo_root="$(cd "${script_dir}/.." && pwd)"

# shellcheck disable=SC1091
. "${repo_root}/release/builders.lock"

case "${architecture}" in
  amd64) builder_digest="${BUILDER_AMD64_DIGEST}" ;;
  arm64) builder_digest="${BUILDER_ARM64_DIGEST}" ;;
  *)
    echo "unsupported or missing architecture '${architecture}'; expected amd64 or arm64" >&2
    exit 2
    ;;
esac

version="${RELEASE_VERSION:-$(sed -n 's/^[[:space:]]*version: "\([^"]*\)",$/\1/p' "${repo_root}/mix.exs" | head -1)}"
source_commit="$(git -C "${repo_root}" rev-parse HEAD)"
source_tag="$(git -C "${repo_root}" describe --tags --exact-match 2>/dev/null || echo untagged)"
source_epoch="${SOURCE_DATE_EPOCH:-$(git -C "${repo_root}" show -s --format=%ct "${source_tag}" 2>/dev/null || git -C "${repo_root}" show -s --format=%ct HEAD)}"
output_dir="${RELEASE_OUTPUT_DIR:-${repo_root}/dist/releases}"
build_command="make build-${architecture}"

for product in exocomp_node exocomp_coordinator; do
  release_dir="${repo_root}/_build/release/${architecture}/rel/${product}"
  # Mix assembles a random development cookie so the just-built release can
  # be smoke-tested. It is not part of the published artifact: installations
  # provision a unique protected RELEASE_COOKIE after extraction.
  rm -f "${release_dir}/releases/COOKIE"

  "${script_dir}/package_release.py" \
    --release-dir "${release_dir}" \
    --product "${product}" \
    --version "${version}" \
    --arch "${architecture}" \
    --output-dir "${output_dir}" \
    --source-commit "${source_commit}" \
    --source-tag "${source_tag}" \
    --source-epoch "${source_epoch}" \
    --builder-digest "${builder_digest}" \
    --elixir-version "${ELIXIR_VERSION}" \
    --otp-version "${OTP_VERSION}" \
    --dependency-lock "${repo_root}/mix.lock" \
    --release-input-normalizer "${repo_root}/scripts/prepare-release-deps.sh" \
    --build-command "${build_command}"
done

echo "Packaged linux/${architecture} releases under ${output_dir}"
