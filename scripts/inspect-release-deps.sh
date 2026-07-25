#!/bin/sh
# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
# Inspect ELF runtime dependencies for an OTP release directory.
#
# Usage:
#   inspect-release-deps.sh <architecture> <release_dir> [baseline_file]
#
# Positional arguments:
#   architecture   amd64 or arm64
#   release_dir    Path to the unpacked OTP release root (must contain an
#                  erts-* subdirectory).
#   baseline_file  Optional path to the allowed-host-libraries file.
#                  Defaults to release/runtime-baseline.lock relative to the
#                  repository root (the directory containing this script's
#                  parent scripts/ directory).
#
# Environment variables:
#   READELF  Override the readelf binary (default: readelf from PATH).
#
# Exit codes:
#   0  All dynamic dependencies are declared in the baseline.
#   1  One or more undeclared or unresolved dynamic dependencies found.
#   2  Usage or setup error.
#
# Output:
#   Writes a JSON dependency report to <release_dir>/dep-report.json and
#   also prints a human-readable summary to stdout.

set -eu

architecture="${1:-}"
release_dir="${2:-}"
script_dir="$(cd "$(dirname "$0")" && pwd)"
repo_root="$(cd "${script_dir}/.." && pwd)"
baseline_file="${3:-${repo_root}/release/runtime-baseline.lock}"
lock_file="${repo_root}/release/builders.lock"

# ---------------------------------------------------------------------------
# Argument validation
# ---------------------------------------------------------------------------

if [ -z "${architecture}" ] || [ -z "${release_dir}" ]; then
  echo "Usage: $0 <architecture> <release_dir> [baseline_file]" >&2
  exit 2
fi

# shellcheck disable=SC1090
. "${lock_file}"

case "${architecture}" in
  amd64)
    ;;
  arm64)
    ;;
  *)
    echo "unsupported architecture '${architecture}'; expected one of: ${SUPPORTED_ARCHITECTURES}" >&2
    exit 2
    ;;
esac

if [ ! -d "${release_dir}" ]; then
  echo "release directory does not exist: ${release_dir}" >&2
  exit 2
fi

if [ ! -f "${baseline_file}" ]; then
  echo "baseline file not found: ${baseline_file}" >&2
  exit 2
fi

# Check for ERTS
erts_dir="$(find "${release_dir}" -maxdepth 1 -type d -name 'erts-*' -print -quit)"
if [ -z "${erts_dir}" ]; then
  echo "release directory does not contain an erts-* subdirectory: ${release_dir}" >&2
  exit 2
fi

# ---------------------------------------------------------------------------
# readelf selection
# ---------------------------------------------------------------------------

readelf_bin="${READELF:-readelf}"
if ! command -v "${readelf_bin}" >/dev/null 2>&1; then
  echo "readelf binary '${readelf_bin}' was not found; install binutils or set READELF" >&2
  exit 2
fi

run_readelf() {
  # run_readelf <elf_file>
  # Outputs dynamic and program-header metadata for the given ELF file.
  elf_file="$1"
  "${readelf_bin}" -d -l "${elf_file}"
}

# ---------------------------------------------------------------------------
# Load baseline: strip comments and blank lines
# ---------------------------------------------------------------------------

load_baseline() {
  grep -v '^\s*#' "${baseline_file}" | grep -v '^\s*$' || true
}

allowed_libs="$(load_baseline)"

# ---------------------------------------------------------------------------
# Find all ELF binaries in the release directory (no subshell)
# ---------------------------------------------------------------------------

elf_list_file="$(mktemp)"
trap 'rm -f "${elf_list_file}"' EXIT HUP INT TERM

find "${release_dir}" -type f | sort | while read -r f; do
  magic="$(dd if="${f}" bs=4 count=1 2>/dev/null | od -A n -t x1 | tr -d ' \n')"
  case "${magic}" in
    7f454c46*)
      echo "${f}" >> "${elf_list_file}"
      ;;
  esac
done

# ---------------------------------------------------------------------------
# Parse helpers
# ---------------------------------------------------------------------------

parse_needed() {
  # Prints one SONAME per line from readelf -d output on stdin.
  sed -n '/(NEEDED)/s/.*Shared library: \[\([^]]*\)\].*/\1/p'
}

parse_interp() {
  # Prints the ELF interpreter base name from readelf -d output on stdin,
  # or nothing if absent. We look for the INTERP tag or an Interpreter line.
  sed -n '/(INTERP)\|Interpreter:/s/.*\[\([^]]*\)\].*/\1/p' | head -1
}

# ---------------------------------------------------------------------------
# Check each ELF file — accumulate into temp files to avoid subshell scope loss
# ---------------------------------------------------------------------------

report_json="${release_dir}/dep-report.json"
undeclared_file="$(mktemp)"
json_entries_file="$(mktemp)"
trap 'rm -f "${elf_list_file}" "${undeclared_file}" "${json_entries_file}"' EXIT HUP INT TERM

echo "Inspecting ELF dependencies in ${release_dir} (${architecture})"
echo "Baseline: ${baseline_file}"
echo ""

while IFS= read -r elf; do
  rel="$(realpath --relative-to="${release_dir}" "${elf}")"
  readelf_out=""
  if ! readelf_out="$(run_readelf "${elf}" 2>/dev/null)"; then
    echo "readelf failed for ELF file: ${rel}" >&2
    exit 2
  fi

  needed_list="$(echo "${readelf_out}" | parse_needed)"
  interp="$(echo "${readelf_out}" | parse_interp)"

  elf_undeclared_list=""
  elf_needed_json="["
  first_n=1

  # Check each NEEDED entry
  while IFS= read -r lib; do
    [ -z "${lib}" ] && continue

    if [ "${first_n}" = "1" ]; then first_n=0; else elf_needed_json="${elf_needed_json}, "; fi
    elf_needed_json="${elf_needed_json}\"${lib}\""

    # Check if this lib is shipped inside the release directory
    shipped="$(find "${release_dir}" -name "${lib}" -type f 2>/dev/null | head -1)"
    if [ -n "${shipped}" ]; then
      continue  # bundled — ok
    fi

    # Check if declared in the host baseline
    if echo "${allowed_libs}" | grep -qFx "${lib}"; then
      continue  # declared host dependency — ok
    fi

    # Undeclared host dependency!
    elf_undeclared_list="${elf_undeclared_list} ${lib}"
    echo "${lib}" >> "${undeclared_file}"
    echo "  UNDECLARED: ${rel} requires ${lib} (not in baseline)" >&2
  done << NEEDED_EOF
${needed_list}
NEEDED_EOF
  elf_needed_json="${elf_needed_json}]"

  # Check the ELF interpreter
  interp_json="null"
  if [ -n "${interp}" ]; then
    interp_json="\"${interp}\""
    interp_base="$(basename "${interp}")"
    if ! echo "${allowed_libs}" | grep -qFx "${interp_base}"; then
      elf_undeclared_list="${elf_undeclared_list} INTERP:${interp_base}"
      echo "${interp_base}" >> "${undeclared_file}"
      echo "  UNDECLARED INTERP: ${rel} uses interpreter ${interp}" >&2
    fi
  fi

  # Build JSON for undeclared entries
  elf_undeclared_json="["
  first_u=1
  for u in ${elf_undeclared_list}; do
    if [ "${first_u}" = "1" ]; then first_u=0; else elf_undeclared_json="${elf_undeclared_json}, "; fi
    elf_undeclared_json="${elf_undeclared_json}\"${u}\""
  done
  elf_undeclared_json="${elf_undeclared_json}]"

  printf '{"path": "%s", "interpreter": %s, "needed": %s, "undeclared": %s}\n' \
    "${rel}" "${interp_json}" "${elf_needed_json}" "${elf_undeclared_json}" >> "${json_entries_file}"

done < "${elf_list_file}"

# ---------------------------------------------------------------------------
# Write JSON report
# ---------------------------------------------------------------------------

{
  printf '{\n'
  printf '  "architecture": "%s",\n' "${architecture}"
  printf '  "release_dir": "%s",\n' "${release_dir}"
  printf '  "glibc_baseline": "%s",\n' "${GLIBC_BASELINE}"
  printf '  "baseline_file": "%s",\n' "${baseline_file}"
  printf '  "erts_dir": "%s",\n' "$(basename "${erts_dir}")"
  printf '  "elfs": [\n'
  first_entry=1
  while IFS= read -r entry; do
    if [ "${first_entry}" = "1" ]; then first_entry=0; else printf ',\n'; fi
    printf '    %s' "${entry}"
  done < "${json_entries_file}"
  printf '\n  ]\n}\n'
} > "${report_json}"

echo ""
echo "Dependency report: ${report_json}"

# ---------------------------------------------------------------------------
# Exit status
# ---------------------------------------------------------------------------

undeclared_count="$(wc -l < "${undeclared_file}" | tr -d ' ')"
if [ "${undeclared_count}" -gt 0 ]; then
  echo ""
  echo "FAIL: ${undeclared_count} undeclared host library dependency(ies) found." >&2
  echo "Add them to ${baseline_file} if they are intentional host dependencies," >&2
  echo "or bundle them inside the release if they should be self-contained." >&2
  exit 1
fi

echo "PASS: all dynamic dependencies are declared."
exit 0
