#!/bin/sh

set -eu

release_env="${1:-test}"

for release in exocomp_node exocomp_coordinator; do
  release_dir="_build/${release_env}/rel/${release}"
  erts_dir="$(find "${release_dir}" -maxdepth 1 -type d -name 'erts-*' -print -quit)"

  if [ -z "${erts_dir}" ]; then
    echo "${release}: release does not contain ERTS" >&2
    exit 1
  fi

  "${release_dir}/bin/${release}" eval "
    case Application.ensure_all_started(:${release}) do
      {:ok, _applications} ->
        IO.puts(\"${release}: started with bundled ERTS\")

      {:error, reason} ->
        IO.inspect(reason, label: \"${release}: failed to start\")
        System.halt(1)
    end
  "
done
