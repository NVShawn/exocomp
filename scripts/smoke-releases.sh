#!/bin/sh
# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0

set -eu

release_env="${1:-test}"
build_root="${2:-_build/${release_env}}"

for release in exocomp_node exocomp_coordinator; do
  release_dir="${build_root}/rel/${release}"
  erts_dir="$(find "${release_dir}" -maxdepth 1 -type d -name 'erts-*' -print -quit)"

  if [ -z "${erts_dir}" ]; then
    echo "${release}: release does not contain ERTS" >&2
    exit 1
  fi

  "${release_dir}/bin/${release}" eval "
    smoke_ledger =
      Path.join(
        System.tmp_dir!(),
        \"exocomp-smoke-\#{System.unique_integer([:positive])}.dets\"
      )

    Application.put_env(:exocomp_node, :replay_ledger_path, smoke_ledger)
    result = Application.ensure_all_started(:${release})

    case result do
      {:ok, _applications} ->
        IO.puts(\"${release}: started with bundled ERTS\")
        Application.stop(:${release})
        File.rm(smoke_ledger)

      {:error, reason} ->
        IO.inspect(reason, label: \"${release}: failed to start\")
        System.halt(1)
    end
  "
done
