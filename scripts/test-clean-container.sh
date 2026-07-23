#!/bin/sh
# Clean-container OTP release startup test.
#
# Extracts an OTP release into a minimal target container that has no Elixir,
# Erlang, compiler, or package manager tooling and verifies that:
#   1. The release starts using the bundled ERTS (not a system Erlang).
#   2. The `erl` binary in use is the one inside the release, not on the
#      host image's PATH.
#
# Also supports an architecture check mode (--check-arch) for offline use
# by test-release-matrix.sh without requiring a real container run.
#
# Usage:
#   test-clean-container.sh [OPTIONS] [RELEASE_DIR]
#
# Modes:
#   Default (no --check-arch):
#     Tests the given release directory in a clean target container.
#
#   --check-arch ARCH RELEASE_DIR:
#     Reads the ELF machine type from ERTS binaries in RELEASE_DIR and
#     verifies they match ARCH (amd64 → e_machine 0x3e, arm64 → 0xb7).
#     Exits non-zero with an actionable diagnostic if they do not match.
#     No container engine required.
#
# Options:
#   --arch ARCH              Target architecture (amd64 or arm64).
#   --product PRODUCT        Release name (e.g. exocomp_node).
#   --release-dir DIR        Path to the OTP release directory.
#   --container-engine BIN   Container engine binary (default: docker).
#   --target-image IMAGE     Minimal base image (default: debian:bookworm-slim).
#   --check-arch ARCH        Offline arch-check mode; RELEASE_DIR is positional.
#   --help                   Show this message.
#
# Exit codes:
#   0  Test passed.
#   1  Test failed with actionable diagnostic.
#   2  Usage error.

set -eu

script_dir="$(cd "$(dirname "$0")" && pwd)"
repo_root="$(cd "${script_dir}/.." && pwd)"
lock_file="${repo_root}/release/builders.lock"

# shellcheck disable=SC1090
. "${lock_file}"

arch=""
product=""
release_dir=""
container_engine="${CONTAINER_ENGINE:-docker}"
target_image="${CLEAN_TARGET_IMAGE:-debian:bookworm-slim}"
check_arch_mode=""

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
while [ "$#" -gt 0 ]; do
  case "$1" in
    --arch)
      arch="${2:-}"
      shift 2
      ;;
    --product)
      product="${2:-}"
      shift 2
      ;;
    --release-dir)
      release_dir="${2:-}"
      shift 2
      ;;
    --container-engine)
      container_engine="${2:-}"
      shift 2
      ;;
    --target-image)
      target_image="${2:-}"
      shift 2
      ;;
    --check-arch)
      check_arch_mode="${2:-}"
      shift 2
      ;;
    --help)
      sed -n '/^# /{ s/^# //; p }' "$0"
      exit 0
      ;;
    -*)
      echo "unknown option: $1" >&2
      echo "Usage: $0 [--arch ARCH] [--product PRODUCT] [--release-dir DIR] [--check-arch ARCH]" >&2
      exit 2
      ;;
    *)
      # Positional: release dir (used in --check-arch mode)
      release_dir="$1"
      shift
      ;;
  esac
done

# ---------------------------------------------------------------------------
# ELF machine type constants (e_machine field, little-endian 2 bytes at offset 18)
# ---------------------------------------------------------------------------
# 0x3e (62) = EM_X86_64 (amd64)
# 0xb7 (183) = EM_AARCH64 (arm64)
elf_machine_amd64=62   # 0x3e
elf_machine_arm64=183  # 0xb7

arch_to_machine() {
  case "$1" in
    amd64) echo "${elf_machine_amd64}" ;;
    arm64) echo "${elf_machine_arm64}" ;;
    *)
      echo "unsupported architecture: $1" >&2
      exit 2
      ;;
  esac
}

# Read the e_machine field (bytes 18-19) from an ELF file.
# Returns the decimal value of the low byte (little-endian). This is
# sufficient for amd64 (0x3e) vs arm64 (0xb7) since they differ in the low
# byte.
#
# ELF header layout (bytes 0-19, little-endian):
#   0-3:  magic \x7fELF
#   4:    EI_CLASS
#   5:    EI_DATA
#   6:    EI_VERSION
#   7:    EI_OSABI
#   8-15: ABI version + padding
#   16-17: e_type
#   18-19: e_machine  ← the field we need
#
# od -A n -t u1 outputs unsigned decimal bytes preceded by a leading space.
# After tr -s, fields are 1-indexed with field 1 being the empty token before
# the leading space, so field 2 = byte[0] and field 20 = byte[18].
read_elf_machine() {
  elf_file="$1"
  byte18="$(dd if="${elf_file}" bs=1 count=20 2>/dev/null \
    | od -A n -t u1 | tr -s ' \n' ' ' | cut -d' ' -f20)"
  echo "${byte18}"
}

# ---------------------------------------------------------------------------
# Mode: --check-arch ARCH
# Verify that ELF binaries in the release match the expected architecture.
# ---------------------------------------------------------------------------
if [ -n "${check_arch_mode}" ]; then
  if [ -z "${release_dir}" ]; then
    echo "Usage: $0 --check-arch ARCH RELEASE_DIR" >&2
    exit 2
  fi

  expected_machine="$(arch_to_machine "${check_arch_mode}")"
  found_arch_mismatch=0

  # Find the ERTS beam.smp binary as the authoritative ELF to check.
  erts_beam="$(find "${release_dir}" -maxdepth 4 -name "beam.smp" -type f 2>/dev/null | head -1)"

  if [ -z "${erts_beam}" ]; then
    echo "no beam.smp found in ${release_dir}" >&2
    echo "Cannot verify architecture: release may be incomplete." >&2
    exit 1
  fi

  # Verify ELF magic (first 4 bytes must be \x7fELF)
  magic="$(dd if="${erts_beam}" bs=4 count=1 2>/dev/null | od -A n -t x1 | tr -d ' \n')"
  case "${magic}" in
    7f454c46*)
      : # valid ELF
      ;;
    *)
      echo "not an ELF file: ${erts_beam}" >&2
      echo "Cannot verify architecture." >&2
      exit 1
      ;;
  esac

  actual_machine="$(read_elf_machine "${erts_beam}")"

  if [ "${actual_machine}" != "${expected_machine}" ]; then
    found_arch_mismatch=1
    # Provide an actionable diagnostic.
    case "${actual_machine}" in
      "${elf_machine_amd64}") actual_name="amd64 (x86-64, e_machine=0x3e)" ;;
      "${elf_machine_arm64}") actual_name="arm64 (aarch64, e_machine=0xb7)" ;;
      *) actual_name="unknown (e_machine=${actual_machine})" ;;
    esac
    case "${expected_machine}" in
      "${elf_machine_amd64}") expected_name="amd64 (x86-64, e_machine=0x3e)" ;;
      "${elf_machine_arm64}") expected_name="arm64 (aarch64, e_machine=0xb7)" ;;
      *) expected_name="unknown (e_machine=${expected_machine})" ;;
    esac

    echo "ERROR: Architecture mismatch in release directory." >&2
    echo "" >&2
    echo "  Expected architecture : ${expected_name}" >&2
    echo "  Found architecture    : ${actual_name}" >&2
    echo "  ELF binary            : ${erts_beam}" >&2
    echo "" >&2
    echo "This release was built for ${actual_name} and cannot run on a" >&2
    echo "${expected_name} host. Use the correct release archive for your" >&2
    echo "target platform." >&2
    exit 1
  fi

  echo "Architecture check passed: ${erts_beam} is ${check_arch_mode} (e_machine=${actual_machine})"
  exit 0
fi

# ---------------------------------------------------------------------------
# Default mode: clean-container startup test
# ---------------------------------------------------------------------------

if [ -z "${arch}" ] || [ -z "${product}" ] || [ -z "${release_dir}" ]; then
  echo "Usage: $0 --arch ARCH --product PRODUCT --release-dir DIR" >&2
  echo "       $0 --check-arch ARCH RELEASE_DIR" >&2
  exit 2
fi

case "${arch}" in
  amd64|arm64) ;;
  *)
    echo "unsupported architecture: ${arch}; expected amd64 or arm64" >&2
    exit 2
    ;;
esac

if [ ! -d "${release_dir}" ]; then
  echo "release directory not found: ${release_dir}" >&2
  exit 2
fi

# Verify the release contains ERTS.
erts_dir="$(find "${release_dir}" -maxdepth 1 -type d -name 'erts-*' -print -quit)"
if [ -z "${erts_dir}" ]; then
  echo "release does not contain an erts-* directory: ${release_dir}" >&2
  echo "ERTS must be bundled in the release (include_erts: true in mix.exs)." >&2
  exit 1
fi

echo "Testing clean-container startup: ${product} / ${arch}"
echo "  Release : ${release_dir}"
echo "  ERTS    : $(basename "${erts_dir}")"
echo "  Image   : ${target_image}"

# Build the container engine arguments for the target platform.
builder_digest_var="BUILDER_$(echo "${arch}" | tr '[:lower:]' '[:upper:]')_DIGEST"
eval "builder_digest=\${${builder_digest_var}}"

target_platform="linux/${arch}"
abs_release_dir="$(cd "${release_dir}" && pwd)"

# The inline evaluation script:
#   1. Verifies that no system `erl` is on PATH inside the container.
#   2. Verifies that the release binary is the only Erlang runtime.
#   3. Starts the application and confirms a clean startup.
eval_script="
set -eu

# Confirm no system Erlang is present.
if command -v erl 2>/dev/null; then
  erl_path=\"\$(command -v erl)\"
  # Accept erl only if it lives inside our release mount.
  if echo \"\${erl_path}\" | grep -q '/release/'; then
    echo 'ERTS source: bundled (inside release)'
  else
    echo 'ERROR: system erl found on PATH: ' \${erl_path} >&2
    echo 'The target container must not have Elixir or Erlang installed.' >&2
    exit 1
  fi
else
  echo 'ERTS source: bundled (no system erl on PATH — correct)'
fi

# Verify the release binary exists and is executable.
release_bin='/release/bin/${product}'
if [ ! -x \"\${release_bin}\" ]; then
  echo 'ERROR: release binary not found or not executable: ' \${release_bin} >&2
  exit 1
fi

# Start the release and confirm it reports bundled ERTS usage.
\"\${release_bin}\" eval \"
  case Application.ensure_all_started(:${product}) do
    {:ok, _apps} ->
      IO.puts('Release started with bundled ERTS')
    {:error, reason} ->
      IO.inspect(reason, label: 'start failed')
      System.halt(1)
  end
\"
"

"${container_engine}" run \
  --rm \
  --init \
  --platform "${target_platform}" \
  --pull never \
  --volume "${abs_release_dir}:/release:ro" \
  "${target_image}" \
  sh -c "${eval_script}"

echo "PASS: ${product} / ${arch} started in clean container using bundled ERTS"
exit 0
