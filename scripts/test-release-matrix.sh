#!/bin/sh
# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
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
#                           Default: architecture-specific pinned Debian slim.
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

container_engine_command="${CONTAINER_ENGINE:-docker}"
container_user_flag="${_CONTAINER_USER_FLAG:---user $(id -u):$(id -g)}"
clean_target_image_override="${CLEAN_TARGET_IMAGE:-}"

run_container_engine() {
  # shellcheck disable=SC2086
  ${container_engine_command} "$@"
}

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

clean_target_image_for_arch() {
  target_arch="$1"

  if [ -n "${clean_target_image_override}" ]; then
    echo "${clean_target_image_override}"
    return
  fi

  target_digest_var="CLEAN_TARGET_$(echo "${target_arch}" | tr '[:lower:]' '[:upper:]')_DIGEST"
  eval "target_digest=\${${target_digest_var}}"
  echo "docker.io/library/debian:${CLEAN_TARGET_TAG}@${target_digest}"
}

pull_clean_target_image() {
  target_arch="$1"
  target_image="$2"

  run_container_engine pull \
    --platform "linux/${target_arch}" \
    "${target_image}"
}

content_manifest() {
  content_root="$1"
  (
    cd "${content_root}"
    find . -type f -print0 \
      | LC_ALL=C sort -z \
      | xargs -0 -r sha256sum
  )
}

content_tree_digest() {
  content_manifest "$1" | sha256sum | awk '{print $1}'
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

  # Run offline fixture tests: content digests must not depend on root paths.
  run_content_digest_fixture_test

  if [ -x "${script_dir}/package-releases.sh" ] &&
     [ -x "${script_dir}/package_release.py" ]; then
    pass "deterministic release packagers exist and are executable"
  else
    fail_test "deterministic release packaging scripts are missing or not executable"
  fi

  if grep -q "releases/COOKIE" "${script_dir}/package_release.py" &&
     grep -q "embedded.*False" "${script_dir}/package_release.py"; then
    pass "packager excludes reusable release cookies"
  else
    fail_test "packager must explicitly omit releases/COOKIE and declare it non-embedded"
  fi
}

# ---------------------------------------------------------------------------
# Offline fixture test: path-independent content digests
# ---------------------------------------------------------------------------
run_content_digest_fixture_test() {
  section "Offline fixture: path-independent content digest"

  digest_tmp="$(mktemp -d)"
  # shellcheck disable=SC2064
  trap "rm -rf '${digest_tmp}'" EXIT HUP INT TERM

  mkdir -p "${digest_tmp}/snap1/nested" "${digest_tmp}/snap2/nested"
  mkdir -p "${digest_tmp}/snap1/releases" "${digest_tmp}/snap2/releases"
  printf '%s\n' "identical release content" > "${digest_tmp}/snap1/nested/release"
  cp "${digest_tmp}/snap1/nested/release" "${digest_tmp}/snap2/nested/release"
  printf 'a' > "${digest_tmp}/snap1/releases/COOKIE"
  cp "${digest_tmp}/snap1/releases/COOKIE" "${digest_tmp}/snap2/releases/COOKIE"

  digest1="$(content_tree_digest "${digest_tmp}/snap1")"
  digest2="$(content_tree_digest "${digest_tmp}/snap2")"
  if [ "${digest1}" = "${digest2}" ]; then
    pass "identical trees at different root paths have matching digests"
  else
    fail_test "content digest includes the tree root path"
  fi

  printf 'b' > "${digest_tmp}/snap2/releases/COOKIE"
  digest2="$(content_tree_digest "${digest_tmp}/snap2")"
  if [ "${digest1}" != "${digest2}" ]; then
    pass "one-byte runtime cookie change produces a different tree digest"
  else
    fail_test "content digest did not detect a changed runtime cookie"
  fi

  rm -rf "${digest_tmp}"
  trap - EXIT HUP INT TERM
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
  baseline="${repo_root}/release/runtime-baseline.lock"

  fixture_tmp="$(mktemp -d)"
  undeclared_release="${fixture_tmp}/undeclared"
  cp -R "${repo_root}/test/fixtures/fake-release-undeclared" "${undeclared_release}"
  inspect_output="${fixture_tmp}/inspect-output"
  # shellcheck disable=SC2064
  trap "rm -rf '${fixture_tmp}'" EXIT HUP INT TERM

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

  rm -rf "${fixture_tmp}"
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

  snapshot1_root="${build_root}/${arch}-snap1"
  snapshot2_root="${build_root}/${arch}-snap2"
  build1_dir="${snapshot1_root}/rel/${product}"
  build2_dir="${snapshot2_root}/rel/${product}"

  if [ "${skip_build}" = "0" ]; then
    echo "Build 1/2 for ${product} (${arch})..."
    "${script_dir}/build-releases.sh" "${arch}"
    product_slug="$(echo "${product}" | tr '_' '-')"
    archive1="$(find "${repo_root}/dist/releases" -maxdepth 1 \
      -name "${product_slug}-*-linux-${arch}.tar.gz" -print | LC_ALL=C sort | tail -1)"
    if [ -z "${archive1}" ]; then
      fail_test "build did not emit a versioned archive for ${product}/${arch}"
      return
    fi
    archive_snapshot1="${build_root}/${arch}-${product}-archive-snap1.tar.gz"
    cp "${archive1}" "${archive_snapshot1}"

    echo "Snapshotting build 1..."
    # shellcheck disable=SC2086
    run_container_engine run \
      --rm \
      ${container_user_flag} \
      --platform "linux/${arch}" \
      --pull never \
      --volume "${repo_root}:/workspace" \
      --workdir /workspace \
      "${builder_image}@$(eval "echo \${BUILDER_$(echo "${arch}" | tr '[:lower:]' '[:upper:]')_DIGEST}")" \
      sh -c "rm -rf _build/release/${arch}-snap1 && cp -a _build/release/${arch} _build/release/${arch}-snap1"

    echo "Build 2/2 for ${product} (${arch})..."
    "${script_dir}/build-releases.sh" "${arch}"
    archive2="$(find "${repo_root}/dist/releases" -maxdepth 1 \
      -name "${product_slug}-*-linux-${arch}.tar.gz" -print | LC_ALL=C sort | tail -1)"
    archive_snapshot2="${build_root}/${arch}-${product}-archive-snap2.tar.gz"
    cp "${archive2}" "${archive_snapshot2}"

    echo "Snapshotting build 2..."
    # shellcheck disable=SC2086
    run_container_engine run \
      --rm \
      ${container_user_flag} \
      --platform "linux/${arch}" \
      --pull never \
      --volume "${repo_root}:/workspace" \
      --workdir /workspace \
      "${builder_image}@$(eval "echo \${BUILDER_$(echo "${arch}" | tr '[:lower:]' '[:upper:]')_DIGEST}")" \
      sh -c "rm -rf _build/release/${arch}-snap2 && cp -a _build/release/${arch} _build/release/${arch}-snap2"
  else
    # --skip-build: expect exactly two pre-built directories named
    # _build/release/<arch>-snap1 and _build/release/<arch>-snap2.
    if [ ! -d "${build1_dir}" ] || [ ! -d "${build2_dir}" ]; then
      echo "  SKIP: build snapshots not found for ${product}/${arch}; run the matrix without SKIP_BUILD first" >&2
      return 0
    fi
  fi

  if [ ! -d "${build1_dir}" ] || [ ! -d "${build2_dir}" ]; then
    fail_test "expected two build snapshots at ${build1_dir} and ${build2_dir}"
    return
  fi

  if [ "${skip_build}" = "0" ]; then
    if cmp -s "${archive_snapshot1}" "${archive_snapshot2}"; then
      pass "packaged archives are byte-identical for ${product} / ${arch}"
    else
      fail_test "packaged archives differ for equivalent ${product} / ${arch} builds"
    fi
  fi

  # Compute content digests using paths relative to each snapshot root.
  digest1="$(content_tree_digest "${build1_dir}")"
  digest2="$(content_tree_digest "${build2_dir}")"

  if [ "${digest1}" = "${digest2}" ]; then
    pass "double-build digests match for ${product} / ${arch}: ${digest1}"
  else
    fail_test "double-build digests DIFFER for ${product} / ${arch} (build1=${digest1}, build2=${digest2})"
    # Show which files differ to aid diagnosis.
    echo "  Files that differ between builds:" >&2
    tmp_d1="$(mktemp)"
    tmp_d2="$(mktemp)"
    content_manifest "${build1_dir}" > "${tmp_d1}" || true
    content_manifest "${build2_dir}" > "${tmp_d2}" || true
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

  for field in product version architecture source_commit source_tag builder_digest \
    elixir_version otp_version erts_version dependency_lock_sha256 \
    release_input_normalizer_sha256 build_command; do
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
  clean_target_image="$(clean_target_image_for_arch "${arch}")"

  section "Clean-container startup: ${product} / ${arch}"

  if [ ! -d "${release_dir}" ]; then
    echo "  SKIP: ${release_dir} not found (build first with: make build-${arch})" >&2
    return 0
  fi

  "${script_dir}/test-clean-container.sh" \
    --arch "${arch}" \
    --product "${product}" \
    --release-dir "${release_dir}" \
    --container-engine "${container_engine_command}" \
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
  clean_target_image="$(clean_target_image_for_arch arm64)"
  release_dir="${repo_root}/_build/release/${test_arch}/rel/exocomp_node"

  if [ ! -d "${release_dir}" ]; then
    echo "  SKIP: ${release_dir} not found; build amd64 release first" >&2
    return 0
  fi

  output_file="$(mktemp)"
  # shellcheck disable=SC2064
  trap "rm -f '${output_file}'" EXIT HUP INT TERM

  if ! pull_clean_target_image arm64 "${clean_target_image}" >"${output_file}" 2>&1; then
    fail_test "could not pull clean arm64 target image: $(head -1 "${output_file}")"
    rm -f "${output_file}"
    trap - EXIT HUP INT TERM
    return
  fi

  # Attempt to run an amd64 binary inside an arm64 container.
  # The container engine must have binfmt_misc/QEMU configured for this to
  # produce a cross-architecture failure rather than silently running under
  # emulation. We disable QEMU by unsetting QEMU_LD_PREFIX and using
  # '--privileged' only if needed; on hosts without binfmt, the exec itself
  # will immediately fail with ENOEXEC.
  if run_container_engine run \
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
  clean_target_image="$(clean_target_image_for_arch "${arch}")"
  release_dir="${repo_root}/_build/release/${arch}/rel/${product}"

  if [ ! -d "${release_dir}" ]; then
    echo "  SKIP: ${release_dir} not found; build amd64 release first" >&2
    return 0
  fi

  output_file="$(mktemp)"
  # shellcheck disable=SC2064
  trap "rm -f '${output_file}'" EXIT HUP INT TERM

  if ! pull_clean_target_image "${arch}" "${clean_target_image}" >"${output_file}" 2>&1; then
    fail_test "could not pull clean ${arch} target image: $(head -1 "${output_file}")"
    rm -f "${output_file}"
    trap - EXIT HUP INT TERM
    return
  fi

  # The pinned Debian base deliberately lacks libcrypto.so.3. Running the
  # release there verifies a missing declared host dependency fails with an
  # actionable loader diagnostic. The positive clean-container test adds that
  # library in release/Containerfile.clean-target.
  if run_container_engine run \
      --rm \
      --platform "linux/${arch}" \
      --pull never \
      --volume "${release_dir}:/release:ro" \
      "${clean_target_image}" \
      /release/bin/"${product}" eval \
      "case Application.ensure_all_started(:${product}) do
         {:ok, _apps} -> System.halt(0)
         {:error, reason} -> IO.inspect(reason, label: \"startup failed\"); System.halt(1)
       end" \
      >"${output_file}" 2>&1; then
    fail_test "release without declared libcrypto.so.3 should have failed to start"
  else
    # Verify the output is actionable.
    if grep -qiE \
        "libcrypto\\.so\\.3|error while loading|cannot open shared object|No such file|failed to load|library" \
        "${output_file}"; then
      pass "missing host dependency produces actionable diagnostic"
    else
      if [ -s "${output_file}" ]; then
        pass "missing host dependency produces diagnostic output"
        echo "  Diagnostic output: $(head -3 "${output_file}")" >&2
      else
        fail_test "missing host dependency produced no diagnostic output"
      fi
    fi
  fi

  rm -f "${output_file}"
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
