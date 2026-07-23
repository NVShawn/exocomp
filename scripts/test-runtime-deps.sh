#!/bin/sh
# Test script for scripts/inspect-release-deps.sh.
#
# Validates that the inspector:
#   - Passes on a release with only declared host dependencies.
#   - Fails on a release with an undeclared dependency.
#   - Fails on a release without an ERTS directory.
#   - Produces a dep-report.json in the release directory.
#   - Correctly handles both amd64 and arm64 architecture arguments.
#
# Uses fake-readelf.sh as the READELF override so no real ELF files or
# container engine are required.

set -eu

script_dir="$(cd "$(dirname "$0")" && pwd)"
repo_root="$(cd "${script_dir}/.." && pwd)"

inspect="${repo_root}/scripts/inspect-release-deps.sh"
fake_readelf="${repo_root}/test/fixtures/fake-readelf.sh"
baseline="${repo_root}/release/runtime-baseline.lock"

valid_release="${repo_root}/test/fixtures/fake-release-valid"
undeclared_release="${repo_root}/test/fixtures/fake-release-undeclared"

pass_count=0
fail_count=0

pass() {
  pass_count=$((pass_count + 1))
  echo "  PASS: $*"
}

fail_test() {
  fail_count=$((fail_count + 1))
  echo "  FAIL: $*" >&2
}

run_inspector() {
  # run_inspector <arch> <release_dir> [baseline]
  READELF="${fake_readelf}" \
    "${inspect}" "$@"
}

# ---------------------------------------------------------------------------
# Test 1: valid release passes for amd64
# ---------------------------------------------------------------------------
echo "Test 1: valid release (amd64) — expect PASS"
if run_inspector amd64 "${valid_release}" "${baseline}" >/dev/null 2>&1; then
  pass "valid amd64 release accepted"
else
  fail_test "valid amd64 release unexpectedly rejected"
fi

# ---------------------------------------------------------------------------
# Test 2: valid release passes for arm64
# ---------------------------------------------------------------------------
echo "Test 2: valid release (arm64) — expect PASS"
if run_inspector arm64 "${valid_release}" "${baseline}" >/dev/null 2>&1; then
  pass "valid arm64 release accepted"
else
  fail_test "valid arm64 release unexpectedly rejected"
fi

# ---------------------------------------------------------------------------
# Test 3: release with undeclared dependency fails
# ---------------------------------------------------------------------------
echo "Test 3: release with undeclared dependency — expect FAIL"
if run_inspector amd64 "${undeclared_release}" "${baseline}" >/dev/null 2>&1; then
  fail_test "release with undeclared dependency should have been rejected"
else
  pass "release with undeclared dependency correctly rejected"
fi

# ---------------------------------------------------------------------------
# Test 4: dep-report.json is produced after a passing run
# ---------------------------------------------------------------------------
echo "Test 4: dep-report.json produced after valid run"
report="${valid_release}/dep-report.json"
rm -f "${report}"
run_inspector amd64 "${valid_release}" "${baseline}" >/dev/null 2>&1 || true
if [ -f "${report}" ]; then
  # Basic sanity: the file must be non-empty JSON starting with '{'
  first_char="$(head -c1 "${report}")"
  if [ "${first_char}" = "{" ]; then
    pass "dep-report.json produced and starts with '{'"
  else
    fail_test "dep-report.json exists but does not look like JSON"
  fi
else
  fail_test "dep-report.json not produced"
fi

# ---------------------------------------------------------------------------
# Test 5: dep-report.json is produced even when inspection fails
# ---------------------------------------------------------------------------
echo "Test 5: dep-report.json produced after failing run"
report="${undeclared_release}/dep-report.json"
rm -f "${report}"
run_inspector amd64 "${undeclared_release}" "${baseline}" >/dev/null 2>&1 || true
if [ -f "${report}" ]; then
  first_char="$(head -c1 "${report}")"
  if [ "${first_char}" = "{" ]; then
    pass "dep-report.json produced on failure and starts with '{'"
  else
    fail_test "dep-report.json on failure does not look like JSON"
  fi
else
  fail_test "dep-report.json not produced after failing run"
fi

# ---------------------------------------------------------------------------
# Test 6: missing ERTS directory rejected with exit code 2
# ---------------------------------------------------------------------------
echo "Test 6: release without ERTS directory — expect exit 2"
tmp_no_erts="$(mktemp -d)"
trap 'rm -rf "${tmp_no_erts}"' EXIT HUP INT TERM
if READELF="${fake_readelf}" "${inspect}" amd64 "${tmp_no_erts}" "${baseline}" >/dev/null 2>&1; then
  fail_test "release without ERTS should have been rejected"
else
  exit_code=$?
  if [ "${exit_code}" -eq 2 ]; then
    pass "missing ERTS directory correctly rejected with exit code 2"
  else
    fail_test "missing ERTS rejected but with wrong exit code ${exit_code} (expected 2)"
  fi
fi

# ---------------------------------------------------------------------------
# Test 7: unsupported architecture rejected
# ---------------------------------------------------------------------------
echo "Test 7: unsupported architecture — expect exit 2"
if READELF="${fake_readelf}" "${inspect}" riscv64 "${valid_release}" "${baseline}" >/dev/null 2>&1; then
  fail_test "unsupported architecture should have been rejected"
else
  pass "unsupported architecture correctly rejected"
fi

# ---------------------------------------------------------------------------
# Test 8: missing baseline file rejected
# ---------------------------------------------------------------------------
echo "Test 8: missing baseline file — expect exit 2"
if READELF="${fake_readelf}" "${inspect}" amd64 "${valid_release}" /nonexistent/baseline.lock >/dev/null 2>&1; then
  fail_test "missing baseline file should have been rejected"
else
  pass "missing baseline file correctly rejected"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
echo "Results: ${pass_count} passed, ${fail_count} failed"
if [ "${fail_count}" -gt 0 ]; then
  exit 1
fi
exit 0
