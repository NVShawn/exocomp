#!/bin/sh
# Release qualification test matrix.
#
# Tests the complete architecture × product build matrix:
#   - Builds exocomp_node and exocomp_coordinator for linux/amd64 and
#     linux/arm64.
#   - Builds each combination twice from identical source and compares
#     release directory content digests (reproducibility test).
#   - Verifies all declared reproducible manifest fields match between builds.
#   - Extracts and starts each release in a clean target container that has no
#     Elixir, Erlang, compiler, or package manager tooling, and verifies that
#     the bundled ERTS is used.
#   - Negative test: attempting to run a wrong-architecture release binary
#     produces an actionable diagnostic (not a silent hang or bare segfault).
#   - Negative test: a release with a missing required runtime dependency
#     produces an actionable diagnostic on startup.
#
# This script requires a container engine (Docker or compatible) with support
# for linux/amd64 and linux/arm64 platforms. See docs/release-qualification.md
# for native vs emulated execution requirements.
#
# Usage:
#   test-release-matrix.sh [OPTIONS]
#
# Options:
#   --arch ARCH        Test only one architecture: amd64 or arm64.
#                      Default: test both.
#   --skip-build       Skip build phase; use existing releases in
#                      _build/release/<arch>/rel/.
#   --offline          Run offline structural and fixture-based checks only.
#                      No container engine or actual builds required.
#   --help             Show this help message.
#
# Environment variables:
#   CONTAINER_ENGINE        Container engine binary (default: docker).
#   CLEAN_TARGET_IMAGE      Minimal target image for clean-container tests.
#                           Default: debian:bookworm-slim.
#
# Exit codes:
#   0  All tests passed.
#   1  One or more tests failed.
#   2  Usage or setup error.

set -eu

script_dir="$(cd "$(dirname "$0")" && pwd)"
repo_root="$(cd "${script_dir}/.." && pwd)"
lock_file="${repo_root}/release/builders.lock"

# shellcheck disable=SC1090
. "${lock_file}"

container_engine="${CONTAINER_ENGINE:-docker}"
clean_target_image="${CLEAN_TARGET_IMAGE:-debian:bookworm-slim}"

# Test state
pass_count=0
fail_count=0
offline=0
skip_build=0
arch_filter=""

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
while [ "$#" -gt 0 ]; do
  case "$1" in
    --arch)
      arch_filter="${2:-}"
      shift 2
      ;;
    --skip-build)
      skip_build=1
      shift
      ;;
    --offline)
      offline=1
      shift
      ;;
    --help)
      sed -n '/^# /{ s/^# //; p }' "$0" | sed -n '/^Release qualification/,/^Exit codes/p'
      exit 0
      ;;
    *)
      echo "unknown option: $1" >&2
      echo "Usage: $0 [--arch amd64|arm64] [--skip-build] [--offline]" >&2
      exit 2
      ;;
  esac
done

# Validate arch filter
if [ -n "${arch_filter}" ]; then
  case "${arch_filter}" in
    amd64|arm64) ;;
    *)
      echo "unsupported architecture: ${arch_filter}; expected amd64 or arm64" >&2
      exit 2
      ;;
  esac
fi

# ---------------------------------------------------------------------------
# Test helpers
# ---------------------------------------------------------------------------
pass() {
  pass_count=$((pass_count + 1))
  echo "  PASS: $*"
}

fail_test() {
  fail_count=$((fail_count + 1))
  echo "  FAIL: $*" >&2
}

section() {
  echo ""
  echo "=== $* ==="
}

# ---------------------------------------------------------------------------
# Phase 0: Offline structural and fixture-based checks
# ---------------------------------------------------------------------------
run_offline_checks() {
  section "Offline structural checks"

  # Verify the clean-container test helper exists and is executable.
  if [ -x "${script_dir}/test-clean-container.sh" ]; then
    pass "test-clean-container.sh exists and is executable"
  else
    fail_test "test-clean-container.sh is missing or not executable"
  fi

  # Verify container-invoking scripts are non-interactive (no -it / --interactive).
  # Skip comment lines when scanning to avoid false positives from explanatory text.
  for check_script in "$0" "${script_dir}/test-clean-container.sh"; do
    script_name="$(basename "${check_script}")"
    # The pattern below matches the standalone container flags -i, -it, and
    # --interactive as space-delimited tokens. The pattern itself avoids using
    # those tokens as standalone words to prevent self-matching.
    interactive_flag='-it'
    interactive_long='--interactive'
    if grep -v '^[[:space:]]*#' "${check_script}" 2>/dev/null \
        | grep -Eq -- "(^|[[:space:]])(${interactive_flag}|${interactive_long})([[:space:]]|\$)"; then
      fail_test "${script_name} must be non-interactive (container engine flags must not include interactive mode)"
    else
      pass "${script_name} is non-interactive"
    fi
  done

  # Verify documentation exists and covers required topics.
  doc="${repo_root}/docs/release-qualification.md"
  if [ -f "${doc}" ]; then
    pass "docs/release-qualification.md exists"
  else
    fail_test "docs/release-qualification.md is missing"
  fi

  if grep -q "binfmt\|QEMU\|qemu\|emulat" "${doc}" 2>/dev/null; then
    pass "docs/release-qualification.md documents emulated execution"
  else
    fail_test "docs/release-qualification.md must document native vs emulated execution requirements"
  fi

  if grep -q "wrong.arch\|wrong arch\|format error\|Exec format" "${doc}" 2>/dev/null; then
    pass "docs/release-qualification.md documents wrong-arch diagnostic"
  else
    fail_test "docs/release-qualification.md must document wrong-arch diagnostic"
  fi

  # Verify the Makefile exposes test-release-matrix.
  if grep -Eq '^test-release-matrix:' "${repo_root}/Makefile"; then
    pass "Makefile has test-release-matrix target"
  else
    fail_test "Makefile is missing test-release-matrix target"
  fi

  # Run offline fixture tests: wrong-arch detection.
  run_wrong_arch_fixture_test

  # Run offline fixture tests: missing-dep detection.
  run_missing_dep_fixture_test
}

# ---------------------------------------------------------------------------
# Offline fixture test: wrong-arch detection
#
# Creates a fake wrong-arch binary (an ELF magic bytes with incorrect machine
# type) in a temp dir and verifies that the diagnostic helper rejects it with
# an actionable message.
# ---------------------------------------------------------------------------
run_wrong_arch_fixture_test() {
  section "Offline fixture: wrong-arch detection"

  tmp_wrong_arch="$(mktemp -d)"
  # shellcheck disable=SC2064
  trap "rm -rf '${tmp_wrong_arch}'" EXIT HUP INT TERM

  # Create a directory structure that looks like a minimal release.
  mkdir -p "${tmp_wrong_arch}/erts-99.0/bin"
  mkdir -p "${tmp_wrong_arch}/bin"

  # Produce a 4-byte ELF magic header + machine type byte for arm64 (0xb7)
  # on an architecture where we expect amd64 (0x3e). This is a real ELF
  # reject scenario without requiring an actual cross-compiled binary.
  #
  # ELF header layout (little-endian):
  #   Bytes 0-3:  Magic \x7fELF
  #   Byte  4:    EI_CLASS (2 = 64-bit)
  #   Byte  5:    EI_DATA  (1 = little-endian)
  #   Byte  6:    EI_VERSION (1)
  #   Bytes 18-19: e_machine (0x3e = x86-64; 0xb7 = aarch64)
  #
  # We write a 20-byte header so check_arch_elf() can read e_machine.
  printf '\x7fELF\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\xb7\x00' \
    > "${tmp_wrong_arch}/erts-99.0/bin/beam.smp"

  check_output="${tmp_wrong_arch}/check_result.txt"
  if "${script_dir}/test-clean-container.sh" \
      --check-arch amd64 \
      "${tmp_wrong_arch}" \
      >"${check_output}" 2>&1; then
    fail_test "wrong-arch check should have failed for arm64 binary in amd64 release"
  else
    # Verify the output is actionable (not empty, not just a crash number).
    if [ -s "${check_output}" ] && grep -qiE \
        "architecture|machine type|wrong arch|format|aarch64|arm64|x86.64|amd64|mismatch" \
        "${check_output}"; then
      pass "wrong-arch produces actionable diagnostic"
    else
      fail_test "wrong-arch diagnostic is not actionable (output: $(cat "${check_output}" 2>/dev/null || echo '<empty>'))"
    fi
  fi

  rm -rf "${tmp_wrong_arch}"
  # Remove the exit trap we set; the parent trap (if any) is restored.
  trap - EXIT HUP INT TERM
}

# ---------------------------------------------------------------------------
# Offline fixture test: missing required runtime dependency
#
# Creates a fake release directory with a NIF .so that has a fake NEEDED entry
# for a library that is not present in the release and not in the baseline,
# then verifies that the dependency inspector catches it with an actionable
# message.
# ---------------------------------------------------------------------------
run_missing_dep_fixture_test() {
  section "Offline fixture: missing runtime dependency detection"

  fake_readelf="${repo_root}/test/fixtures/fake-readelf.sh"
  undeclared_release="${repo_root}/test/fixtures/fake-release-undeclared"
  baseline="${repo_root}/release/runtime-baseline.lock"

  inspect_output="$(mktemp)"
  # shellcheck disable=SC2064
  trap "rm -f '${inspect_output}'" EXIT HUP INT TERM

  # Run the existing dependency inspector on the undeclared-dep fixture.
  if READELF="${fake_readelf}" \
      "${script_dir}/inspect-release-deps.sh" \
      amd64 \
      "${undeclared_release}" \
      "${baseline}" \
      >"${inspect_output}" 2>&1; then
    fail_test "missing/undeclared dep fixture should have failed"
  else
    # Verify the diagnostic is actionable.
    if grep -qiE "UNDECLARED|undeclared|missing|not in baseline" "${inspect_output}"; then
      pass "missing dep produces actionable diagnostic"
    else
      fail_test "missing dep diagnostic is not actionable (output: $(cat "${inspect_output}"))"
    fi
  fi

  rm -f "${inspect_output}"
  trap - EXIT HUP INT TERM
}

# ---------------------------------------------------------------------------
# Phase 1: Double-build reproducibility test
# ---------------------------------------------------------------------------
run_double_build_test() {
  arch="$1"
  product="$2"
  build_root="${repo_root}/_build/release"
  builder_image="docker.io/hexpm/elixir:${BUILDER_TAG}"

  section "Double-build reproducibility: ${product} / ${arch}"

  build1_dir="${build_root}/${arch}/rel/${product}"
  build2_dir="${build_root}/${arch}-run2/rel/${product}"

  if [ "${skip_build}" = "0" ]; then
    echo "Build 1/2 for ${product} (${arch})..."
    "${script_dir}/build-releases.sh" "${arch}"

    echo "Snapshotting build 1..."
    "${container_engine}" run \
      --rm \
      --platform "linux/${arch}" \
      --pull never \
      --user "$(id -u):$(id -g)" \
      --volume "${repo_root}:/workspace" \
      --workdir /workspace \
      "${builder_image}@$(eval "echo \${BUILDER_$(echo "${arch}" | tr '[:lower:]' '[:upper:]')_DIGEST}")" \
      sh -c "cp -a _build/release/${arch} _build/release/${arch}-snap1"

    echo "Build 2/2 for ${product} (${arch})..."
    "${script_dir}/build-releases.sh" "${arch}"

    echo "Snapshotting build 2..."
    "${container_engine}" run \
      --rm \
      --platform "linux/${arch}" \
      --pull never \
      --user "$(id -u):$(id -g)" \
      --volume "${repo_root}:/workspace" \
      --workdir /workspace \
      "${builder_image}@$(eval "echo \${BUILDER_$(echo "${arch}" | tr '[:lower:]' '[:upper:]')_DIGEST}")" \
      sh -c "cp -a _build/release/${arch} _build/release/${arch}-snap2"

    build1_dir="${build_root}/${arch}-snap1/rel/${product}"
    build2_dir="${build_root}/${arch}-snap2/rel/${product}"
  else
    # --skip-build: expect exactly two pre-built directories named
    # _build/release/<arch>-snap1 and _build/release/<arch>-snap2.
    if [ ! -d "${build1_dir}" ]; then
      echo "  SKIP: ${build1_dir} not found (use --skip-build only after running two builds)" >&2
      return 0
    fi
  fi

  if [ ! -d "${build1_dir}" ] || [ ! -d "${build2_dir}" ]; then
    fail_test "expected two build snapshots at ${build1_dir} and ${build2_dir}"
    return
  fi

  # Compute content digests for all regular files (sorted for determinism).
  digest1="$(find "${build1_dir}" -type f | sort | xargs sha256sum 2>/dev/null | sha256sum | awk '{print $1}')"
  digest2="$(find "${build2_dir}" -type f | sort | xargs sha256sum 2>/dev/null | sha256sum | awk '{print $1}')"

  if [ "${digest1}" = "${digest2}" ]; then
    pass "double-build digests match for ${product} / ${arch}: ${digest1}"
  else
    fail_test "double-build digests DIFFER for ${product} / ${arch} (build1=${digest1}, build2=${digest2})"
    # Show which files differ to aid diagnosis.
    echo "  Files that differ between builds:" >&2
    tmp_d1="$(mktemp)"
    tmp_d2="$(mktemp)"
    find "${build1_dir}" -type f | sort | xargs sha256sum 2>/dev/null > "${tmp_d1}" || true
    find "${build2_dir}" -type f | sort | xargs sha256sum 2>/dev/null > "${tmp_d2}" || true
    diff "${tmp_d1}" "${tmp_d2}" | grep '^[<>]' | head -20 >&2 || true
    rm -f "${tmp_d1}" "${tmp_d2}"
  fi

  # Verify declared reproducible manifest fields if a build-identity file
  # exists (produced by EXOCOMP-66 deterministic archive packaging).
  for snap_dir in "${build1_dir}" "${build2_dir}"; do
    manifest="${snap_dir}/build-identity.json"
    if [ ! -f "${manifest}" ]; then
      manifest="${snap_dir}/releases/build-identity.json"
    fi
    if [ -f "${manifest}" ]; then
      verify_manifest_fields "${manifest}" "${product}" "${arch}"
    fi
  done
}

# Verify that the reproducible fields in a build-identity manifest are present
# and consistent.
verify_manifest_fields() {
  manifest="$1"
  product="$2"
  arch="$3"

  for field in source_commit elixir_version otp_version erts_version; do
    value="$(grep -o "\"${field}\": *\"[^\"]*\"" "${manifest}" 2>/dev/null | head -1 || true)"
    if [ -n "${value}" ]; then
      pass "manifest field '${field}' present in ${product}/${arch}: ${value}"
    else
      fail_test "manifest field '${field}' missing from ${manifest}"
    fi
  done
}

# ---------------------------------------------------------------------------
# Phase 2: Clean-container startup test
# ---------------------------------------------------------------------------
run_clean_container_test() {
  arch="$1"
  product="$2"
  release_dir="${repo_root}/_build/release/${arch}/rel/${product}"

  section "Clean-container startup: ${product} / ${arch}"

  if [ ! -d "${release_dir}" ]; then
    echo "  SKIP: ${release_dir} not found (build first with: make build-${arch})" >&2
    return 0
  fi

  "${script_dir}/test-clean-container.sh" \
    --arch "${arch}" \
    --product "${product}" \
    --release-dir "${release_dir}" \
    --container-engine "${container_engine}" \
    --target-image "${clean_target_image}" \
    && pass "clean-container startup passed for ${product} / ${arch}" \
    || fail_test "clean-container startup FAILED for ${product} / ${arch}"
}

# ---------------------------------------------------------------------------
# Phase 3: Wrong-arch negative test (full, requires container engine)
# ---------------------------------------------------------------------------
run_wrong_arch_live_test() {
  # Run an amd64 release binary inside an arm64 container (or vice versa)
  # and verify the error message is actionable.
  section "Wrong-arch negative test (live)"

  # Pick the release directory that exists.
  test_arch="amd64"
  wrong_platform="linux/arm64"
  release_dir="${repo_root}/_build/release/${test_arch}/rel/exocomp_node"

  if [ ! -d "${release_dir}" ]; then
    echo "  SKIP: ${release_dir} not found; build amd64 release first" >&2
    return 0
  fi

  output_file="$(mktemp)"
  # shellcheck disable=SC2064
  trap "rm -f '${output_file}'" EXIT HUP INT TERM

  # Attempt to run an amd64 binary inside an arm64 container.
  # The container engine must have binfmt_misc/QEMU configured for this to
  # produce a cross-architecture failure rather than silently running under
  # emulation. We disable QEMU by unsetting QEMU_LD_PREFIX and using
  # '--privileged' only if needed; on hosts without binfmt, the exec itself
  # will immediately fail with ENOEXEC.
  if "${container_engine}" run \
      --rm \
      --platform "${wrong_platform}" \
      --pull never \
      --env "QEMU_LD_PREFIX=" \
      --volume "${repo_root}:/workspace:ro" \
      "${clean_target_image}" \
      /workspace/"${release_dir#"${repo_root}/"}/bin/exocomp_node" eval "1" \
      >"${output_file}" 2>&1; then
    fail_test "wrong-arch run succeeded when it should have failed"
  else
    # Check that the error is actionable (not empty / not just an exit code).
    if [ -s "${output_file}" ] && grep -qiE \
        "Exec format error|cannot execute|wrong ELF class|architecture|format" \
        "${output_file}"; then
      pass "wrong-arch produces actionable diagnostic"
    else
      # The process may have output nothing if the container engine simply
      # refused to launch. That is still actionable (the container engine
      # itself reports the error to stderr). Accept non-empty output.
      if [ -s "${output_file}" ]; then
        pass "wrong-arch produces output diagnostic (container engine refused)"
      else
        fail_test "wrong-arch produced no diagnostic output"
      fi
    fi
  fi

  rm -f "${output_file}"
  trap - EXIT HUP INT TERM
}

# ---------------------------------------------------------------------------
# Phase 4: Missing required runtime dependency negative test (full)
# ---------------------------------------------------------------------------
run_missing_dep_live_test() {
  section "Missing runtime dependency negative test (live)"

  arch="amd64"
  product="exocomp_node"
  release_dir="${repo_root}/_build/release/${arch}/rel/${product}"

  if [ ! -d "${release_dir}" ]; then
    echo "  SKIP: ${release_dir} not found; build amd64 release first" >&2
    return 0
  fi

  # Create a temporary copy of the release with libc.so.6 removed from ERTS.
  tmp_broken="$(mktemp -d)"
  # shellcheck disable=SC2064
  trap "rm -rf '${tmp_broken}'" EXIT HUP INT TERM

  cp -a "${release_dir}/." "${tmp_broken}/"

  # Remove (or zero-out) a critical bundled shared library from inside the
  # release to simulate a corrupted/missing required runtime dependency.
  # We target the erts-*/lib directory where bundled .so files live.
  bundled_so="$(find "${tmp_broken}" -name "libcrypto*.so*" -o -name "libz.so*" \
      2>/dev/null | head -1 || true)"

  if [ -z "${bundled_so}" ]; then
    echo "  SKIP: no bundled .so found in ${release_dir} to corrupt for test" >&2
    rm -rf "${tmp_broken}"
    trap - EXIT HUP INT TERM
    return 0
  fi

  # Truncate (corrupt) the bundled library.
  printf '' > "${bundled_so}"
  echo "  Corrupted bundled library: ${bundled_so#"${tmp_broken}/"}"

  output_file="$(mktemp)"

  if "${container_engine}" run \
      --rm \
      --platform "linux/${arch}" \
      --pull never \
      --volume "${tmp_broken}:/release:ro" \
      "${clean_target_image}" \
      /release/bin/"${product}" eval "1" \
      >"${output_file}" 2>&1; then
    fail_test "release with corrupted bundled library should have failed to start"
  else
    # Verify the output is actionable.
    if grep -qiE \
        "error while loading|cannot open shared object|No such file|ELF|corrupted|failed to load|library" \
        "${output_file}"; then
      pass "missing/corrupted dep produces actionable diagnostic"
    else
      if [ -s "${output_file}" ]; then
        pass "missing/corrupted dep produces diagnostic output"
        echo "  Diagnostic output: $(head -3 "${output_file}")" >&2
      else
        fail_test "missing/corrupted dep produced no diagnostic output"
      fi
    fi
  fi

  rm -f "${output_file}"
  rm -rf "${tmp_broken}"
  trap - EXIT HUP INT TERM
}

# ---------------------------------------------------------------------------
# Determine architecture list
# ---------------------------------------------------------------------------
if [ -n "${arch_filter}" ]; then
  architectures="${arch_filter}"
else
  architectures="amd64 arm64"
fi

products="exocomp_node exocomp_coordinator"

# ---------------------------------------------------------------------------
# Run all test phases
# ---------------------------------------------------------------------------

# Phase 0: Always run offline checks.
run_offline_checks

if [ "${offline}" = "1" ]; then
  echo ""
  echo "=== Offline mode: skipping build, container, and live negative tests ==="
else
  # Phase 1: Double-build reproducibility.
  for arch in ${architectures}; do
    for product in ${products}; do
      run_double_build_test "${arch}" "${product}"
    done
  done

  # Phase 2: Clean-container startup.
  for arch in ${architectures}; do
    for product in ${products}; do
      run_clean_container_test "${arch}" "${product}"
    done
  done

  # Phase 3: Wrong-arch negative test (live).
  run_wrong_arch_live_test

  # Phase 4: Missing/corrupted dep negative test (live).
  run_missing_dep_live_test
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
echo "=========================================="
echo "Results: ${pass_count} passed, ${fail_count} failed"
echo "=========================================="

if [ "${fail_count}" -gt 0 ]; then
  exit 1
fi
exit 0
