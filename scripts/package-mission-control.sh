#!/bin/sh
# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0

set -eu

script_dir="$(cd -- "$(dirname -- "$0")" && pwd)"
repo_root="$(dirname -- "${script_dir}")"

exec "${PYTHON:-python3}" "${script_dir}/package_mission_control.py" \
  --containerfile "${repo_root}/release/mission_control/Containerfile" \
  --dependency-lock "${repo_root}/mix.lock" \
  --license-registry "${repo_root}/licenses/components.toml" \
  "$@"
