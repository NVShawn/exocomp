#!/bin/sh
# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0

set -eu

repo_root="${1:-$(cd "$(dirname "$0")/.." && pwd)}"
bandit_source="${repo_root}/deps/bandit/lib/bandit.ex"
lock_file="${repo_root}/mix.lock"
locked_release='"bandit": {:hex, :bandit, "1.12.1", "ce002ed50689de7a7444340495d08ef44e883d211788691070d2ba71bba9f966"'
map_keys_line='                        |> Map.keys()'
sort_line='                        |> Enum.sort()'

fail() {
  echo "release dependency normalization failed: $*" >&2
  exit 1
}

[ -f "${lock_file}" ] || fail "mix.lock is missing"
[ -f "${bandit_source}" ] || fail "locked Bandit source is missing; run mix deps.get first"
grep -Fq "${locked_release}" "${lock_file}" ||
  fail "Bandit lock identity changed; review and update the deterministic-input normalization"

sort_count="$(grep -Fc "${sort_line}" "${bandit_source}" || true)"
if [ "${sort_count}" -eq 1 ]; then
  echo "Bandit release input already has deterministic Thousand Island key ordering"
  exit 0
fi
[ "${sort_count}" -eq 0 ] ||
  fail "unexpected repeated deterministic sort markers in Bandit source"

map_keys_count="$(grep -Fc "${map_keys_line}" "${bandit_source}" || true)"
[ "${map_keys_count}" -eq 1 ] ||
  fail "expected one exact Bandit Thousand Island Map.keys input"

# Bandit 1.12.1 captures Map.keys/1 at compile time. Large-map key iteration
# varies with the VM hash seed, which changes the module vsn and anonymous-fun
# identifiers even under deterministic compiler mode. Sorting this validation
# allow-list is semantics-preserving and makes the locked release input stable.
sed -i "/^${map_keys_line}$/a\\
${sort_line}" "${bandit_source}"

[ "$(grep -Fc "${sort_line}" "${bandit_source}")" -eq 1 ] ||
  fail "deterministic sort was not applied exactly once"

echo "Normalized locked Bandit 1.12.1 release input for deterministic compilation"
