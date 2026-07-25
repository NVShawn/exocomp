#!/bin/sh
# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0

set -eu

lock_file="release/builders.lock"

# shellcheck disable=SC1090
. "${lock_file}"

fail() {
  echo "builder validation failed: $*" >&2
  exit 1
}

[ "${SUPPORTED_ARCHITECTURES}" = "amd64,arm64" ] ||
  fail "supported architectures must be exactly amd64,arm64"
[ "${ELIXIR_VERSION}" = "1.20.2" ] || fail "unexpected Elixir version"
[ "${OTP_VERSION}" = "28.5.0.3" ] || fail "unexpected OTP version"
[ "${BUILDER_DISTRIBUTION}" = "debian" ] || fail "builder must use a glibc distribution"
[ "${BUILDER_DISTRIBUTION_VERSION}" = "12" ] || fail "unexpected Debian baseline"
[ "${GLIBC_BASELINE}" = "2.36" ] || fail "unexpected glibc baseline"

expected_tag="${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-bookworm-20260713-slim"
[ "${BUILDER_TAG}" = "${expected_tag}" ] || fail "builder tag does not pin the locked toolchain and OS snapshot"

for digest in "${BUILDER_AMD64_DIGEST}" "${BUILDER_ARM64_DIGEST}"; do
  echo "${digest}" | grep -Eq '^sha256:[0-9a-f]{64}$' ||
    fail "builder digest is not a complete sha256 digest: ${digest}"
done

[ "${BUILDER_AMD64_DIGEST}" != "${BUILDER_ARM64_DIGEST}" ] ||
  fail "architecture-specific image digests must differ"

[ "${CLEAN_TARGET_TAG}" = "bookworm-slim" ] ||
  fail "clean target must use Debian bookworm slim"
for digest in "${CLEAN_TARGET_AMD64_DIGEST}" "${CLEAN_TARGET_ARM64_DIGEST}"; do
  echo "${digest}" | grep -Eq '^sha256:[0-9a-f]{64}$' ||
    fail "clean target digest is not a complete sha256 digest: ${digest}"
done
[ "${CLEAN_TARGET_AMD64_DIGEST}" != "${CLEAN_TARGET_ARM64_DIGEST}" ] ||
  fail "architecture-specific clean target digests must differ"

for architecture in amd64 arm64; do
  grep -Eq "^build-${architecture}:" Makefile ||
    fail "Makefile is missing build-${architecture}"
done

grep -Fq -- "--platform \"\${target_platform}\"" scripts/check-builder-capability.sh ||
  fail "capability check does not select an explicit platform"
grep -Fq -- "--platform \"\${target_platform}\"" scripts/build-releases.sh ||
  fail "release build does not select an explicit platform"
grep -Fq -- "--pull never" scripts/build-releases.sh ||
  fail "release build may pull an unverified image"
grep -Fq "git status --porcelain=v1 --untracked-files=all" scripts/build-releases.sh ||
  fail "release build does not require a clean checkout"
# shellcheck disable=SC2016 # The literal command substitution is the validation target.
grep -Fq 'actual_glibc="$(getconf GNU_LIBC_VERSION' scripts/verify-toolchain.sh ||
  fail "builder does not validate the glibc baseline"
grep -Fq "mix release exocomp_node --overwrite" scripts/build-releases.sh ||
  fail "node release is not built"
grep -Fq "mix release exocomp_coordinator --overwrite" scripts/build-releases.sh ||
  fail "coordinator release is not built"
grep -Fq "mix local.hex --force --quiet" scripts/build-releases.sh ||
  fail "release build does not bootstrap the pinned Hex client"
grep -Fq "mix deps.get" scripts/build-releases.sh ||
  fail "release build does not fetch locked dependencies"
grep -Fq '"ERL_COMPILER_OPTIONS=deterministic"' scripts/build-releases.sh ||
  fail "release build does not enable deterministic BEAM compilation"
grep -Fq '_CONTAINER_USER_FLAG' scripts/build-releases.sh ||
  fail "release build does not support rootless keep-id volume ownership"
if grep -Eq '^[[:space:]]+--user([=[:space:]]|\\)' scripts/build-releases.sh; then
  fail "release build must not add a hardcoded --user flag after _CONTAINER_USER_FLAG"
fi
grep -Fq "scripts/smoke-releases.sh prod" scripts/build-releases.sh ||
  fail "built releases are not checked for bundled ERTS"
grep -Fq "replay_ledger_path" scripts/smoke-releases.sh ||
  fail "production smoke test does not isolate replay ledger state"
grep -Fq "inspect-release-deps.sh" scripts/build-releases.sh ||
  fail "build script does not invoke dependency inspection"

if grep -Eq -- '(^|[[:space:]])(-i|-it|--interactive)([[:space:]]|$)' \
  scripts/build-releases.sh scripts/check-builder-capability.sh; then
  fail "builder invocation must be non-interactive"
fi

fake_engine="./test/fixtures/fake-container-engine.sh"
CONTAINER_ENGINE="${fake_engine}" ./scripts/check-builder-capability.sh amd64 >/dev/null ||
  fail "amd64 capability mapping failed"
CONTAINER_ENGINE="${fake_engine}" ./scripts/check-builder-capability.sh arm64 >/dev/null ||
  fail "arm64 capability mapping failed"
CONTAINER_ENGINE="${fake_engine} --remote --url fake.sock" \
  ./scripts/check-builder-capability.sh amd64 >/dev/null ||
  fail "container engine commands with connection arguments are not supported"

if CONTAINER_ENGINE="${fake_engine}" ./scripts/check-builder-capability.sh riscv64 >/dev/null 2>&1; then
  fail "unsupported architectures must fail"
fi

if grep -Eq '(^|[-_])(latest|edge)([-_@]|$)' "${lock_file}"; then
  fail "floating image input found in ${lock_file}"
fi

# Validate the runtime baseline file exists and has required content.
baseline="release/runtime-baseline.lock"
[ -f "${baseline}" ] ||
  fail "release/runtime-baseline.lock is missing"
grep -qFx "libc.so.6" "${baseline}" ||
  fail "runtime-baseline.lock must declare libc.so.6"
grep -qFx "libm.so.6" "${baseline}" ||
  fail "runtime-baseline.lock must declare libm.so.6"
grep -qFx "libtinfo.so.6" "${baseline}" ||
  fail "runtime-baseline.lock must declare the ERTS terminal dependency"
grep -qFx "libcrypto.so.3" "${baseline}" ||
  fail "runtime-baseline.lock must declare the OTP crypto dependency"

# Validate the dependency inspection script exists and is executable.
[ -x "scripts/inspect-release-deps.sh" ] ||
  fail "scripts/inspect-release-deps.sh is missing or not executable"

# Run the runtime dependency tests (uses fake-readelf fixtures; no container needed).
./scripts/test-runtime-deps.sh ||
  fail "runtime dependency inspection tests failed"

# Validate that the runtime-dependencies documentation exists.
[ -f "docs/runtime-dependencies.md" ] ||
  fail "docs/runtime-dependencies.md is missing"
grep -q "glibc" "docs/runtime-dependencies.md" ||
  fail "docs/runtime-dependencies.md must document the glibc baseline"
grep -q "inspect-release-deps.sh" "docs/runtime-dependencies.md" ||
  fail "docs/runtime-dependencies.md must reference the inspection command"

# ---------------------------------------------------------------------------
# Validate release qualification matrix scripts (EXOCOMP-68).
# ---------------------------------------------------------------------------

# Verify the matrix test script exists and is executable.
[ -x "scripts/test-release-matrix.sh" ] ||
  fail "scripts/test-release-matrix.sh is missing or not executable"

# Verify the clean-container test helper exists and is executable.
[ -x "scripts/test-clean-container.sh" ] ||
  fail "scripts/test-clean-container.sh is missing or not executable"
grep -Fq 'target_digest_var="CLEAN_TARGET_$(echo "${target_arch}"' scripts/test-release-matrix.sh ||
  fail "qualification matrix does not select clean target digest by architecture"
grep -Fq 'run_container_engine pull --platform' scripts/test-clean-container.sh ||
  fail "clean-container test does not fetch its pinned target image"
[ -f "release/Containerfile.clean-target" ] ||
  fail "clean target Containerfile is missing"
grep -Fq 'COPY --from=builder /usr/lib/${LIB_ARCH}/libcrypto.so.3' \
  release/Containerfile.clean-target ||
  fail "clean target does not provide the declared OpenSSL runtime dependency"

# Verify the Makefile exposes the test-release-matrix target.
grep -Eq '^test-release-matrix:' Makefile ||
  fail "Makefile is missing test-release-matrix target"

# Verify the release qualification documentation exists and covers required topics.
[ -f "docs/release-qualification.md" ] ||
  fail "docs/release-qualification.md is missing"
grep -q "binfmt\|QEMU\|qemu\|emulat" "docs/release-qualification.md" ||
  fail "docs/release-qualification.md must document native vs emulated execution requirements"
grep -q "wrong.arch\|wrong arch\|format error\|Exec format" "docs/release-qualification.md" ||
  fail "docs/release-qualification.md must document wrong-arch diagnostic"

# Run the full offline qualification matrix checks (uses fake fixtures, no Docker).
./scripts/test-release-matrix.sh --offline ||
  fail "offline release qualification matrix checks failed"

echo "release builder definitions are pinned and valid"
