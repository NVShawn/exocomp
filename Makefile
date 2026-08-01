# BEGIN OOMPAH PROJECT BOOTSTRAP v:1
# Project Makefile.
#
# Targets are documented inline with `## ` comments so `make help` stays
# current as this file is customized.
# END OOMPAH PROJECT BOOTSTRAP

.DEFAULT_GOAL := help

PYTHON ?= python3

include release/builders.lock

CONTAINER_ENGINE ?= docker
HOST_MACHINE := $(shell uname -m)
DEV_ARCH := $(if $(filter x86_64,$(HOST_MACHINE)),amd64,$(if $(filter aarch64 arm64,$(HOST_MACHINE)),arm64,unsupported))
DEV_BUILDER_DIGEST := $(if $(filter amd64,$(DEV_ARCH)),$(BUILDER_AMD64_DIGEST),$(BUILDER_ARM64_DIGEST))
DEV_BUILDER_IMAGE := docker.io/hexpm/elixir:$(BUILDER_TAG)@$(DEV_BUILDER_DIGEST)

# In rootless Docker, the container root (uid=0) is remapped to the host
# user by the kernel's user namespace, so passing --user breaks volume
# permissions.  In standard (rootful) Docker, --user is needed so that files
# written to the mounted volume are owned by the host user rather than root.
_DOCKER_ROOTLESS := $(shell $(CONTAINER_ENGINE) info 2>/dev/null | grep -c 'rootless: true')
ifneq ($(_DOCKER_ROOTLESS),0)
  _CONTAINER_USER_FLAG :=
else
  _CONTAINER_USER_FLAG := --user "$$(id -u):$$(id -g)"
endif

# MIX_HOME and HEX_HOME are pinned inside /workspace so the container's
# unprivileged user can write package archives without needing $HOME access.
CONTAINER_RUN := $(CONTAINER_ENGINE) run --rm --init \
	$(_CONTAINER_USER_FLAG) \
	--platform linux/$(DEV_ARCH) \
	--pull always \
	--env ELIXIR_VERSION=$(ELIXIR_VERSION) \
	--env OTP_VERSION=$(OTP_VERSION) \
	--env GLIBC_BASELINE=$(GLIBC_BASELINE) \
	--env MIX_HOME=/workspace/.mix-home \
	--env HEX_HOME=/workspace/.hex-home \
	--volume "$(CURDIR):/workspace" \
	--workdir /workspace \
	$(DEV_BUILDER_IMAGE)

.PHONY: help init init-amd64 init-arm64 fmt fmt-check build build-amd64 \
	build-arm64 test test-builders test-deps test-release-matrix test-release-packaging \
	test-compliance \
	inspect-deps-amd64 inspect-deps-arm64 lint \
	compliance-check check-links check-licenses release-check clean \
	build-profile-action-helper test-profile-action-helper \
	gen-test-fixtures test-fixture-service fixture-install fixture-cleanup \
	test-integration bench-llama-short bench-harness bench-llama-short-shipped \
	bench-llama-full test-m5-qualification test-installer test-bundle \
	bundle-amd64 bundle-arm64 bundle-runtime-amd64 bundle-runtime-arm64 \
	verify-bundle

# Bundle assembly variables (override on command line as needed)
BUNDLE_VERSION ?= $(shell git describe --tags --exact-match 2>/dev/null | sed 's/^v//' || echo "dev")
BUNDLE_SOURCE_COMMIT ?= $(shell git rev-parse HEAD 2>/dev/null || echo "unknown")
BUNDLE_DIST ?= dist
# Release bundles must carry the immutable builder identity and a manifest
# signature.  Leave these empty only for local fixture/development assembly.
BUNDLE_BUILDER_IMAGE ?=
BUNDLE_SIGN_KEY ?=
# Paths to pre-built OTP archives (set these when calling bundle targets)
NODE_ARCHIVE_AMD64 ?= _build/release/amd64/rel/exocomp_node
NODE_ARCHIVE_ARM64 ?= _build/release/arm64/rel/exocomp_node
COORD_ARCHIVE_AMD64 ?= _build/release/amd64/rel/exocomp_coordinator
COORD_ARCHIVE_ARM64 ?= _build/release/arm64/rel/exocomp_coordinator
# Paths to the pinned llama-server executable and its companion shared libraries.
LLAMA_SERVER_AMD64 ?=
LLAMA_SERVER_ARM64 ?=
LLAMA_LIB_DIR_AMD64 ?=
LLAMA_LIB_DIR_ARM64 ?=
# Path to verified Qwen GGUF model and its SHA-256 (complete bundle only)
MODEL_PATH ?=
MODEL_SHA256 ?=
# Shipped-artifact M5 qualification inputs.
LLAMA_SERVER ?=
LLAMA_LIB_DIR ?=
NODE_RELEASE ?=
COORD_RELEASE ?=
BENCH_EVIDENCE_DIR ?=
BENCH_LLAMA_PORT ?=
BENCH_WARM_UP_SECONDS ?=
BENCH_RUN_SECONDS ?=
BENCH_SAMPLE_INTERVAL_MS ?=
BENCH_INFERENCE_TIMEOUT_MS ?=
BENCH_RESTART_TIMEOUT_MS ?=
BENCH_PROPOSAL_COUNT ?=
BENCH_SOAK_LOAD_INTERVAL_SECONDS ?=
BENCH_POLL_CYCLES ?=
BENCH_POLL_CONCURRENCY ?=
BENCH_HARNESS := _build/prod/rel/bench_harness/bin/bench_harness

help: ## Show this help.
	@awk 'BEGIN {FS = ":.*?## "; printf "Usage: make <target>\n\nTargets:\n"} \
		/^[a-zA-Z0-9_-]+:.*?## / {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}' \
		$(MAKEFILE_LIST)

init: ## Check the native development builder.
	./scripts/check-builder-capability.sh $(DEV_ARCH)

init-amd64: ## Check Linux amd64 builder capability.
	./scripts/check-builder-capability.sh amd64

init-arm64: ## Check Linux arm64 builder capability.
	./scripts/check-builder-capability.sh arm64

HEX_BOOTSTRAP := mix local.hex --force --quiet

fmt: ## Format all source files in place.
	$(CONTAINER_RUN) sh -c '$(HEX_BOOTSTRAP) && mix format'

fmt-check: ## Check formatting without modifying files.
	$(CONTAINER_RUN) sh -c '$(HEX_BOOTSTRAP) && mix format --check-formatted'

build: ## Build releases for ARCH=amd64 or ARCH=arm64.
	@test -n "$(ARCH)" || { echo "ARCH is required; use make build ARCH=amd64 or ARCH=arm64" >&2; exit 2; }
	./scripts/build-releases.sh "$(ARCH)"

build-amd64: ## Build clean Linux amd64 node and coordinator releases.
	./scripts/build-releases.sh amd64

build-arm64: ## Build clean Linux arm64 node and coordinator releases.
	./scripts/build-releases.sh arm64

inspect-deps-amd64: ## Inspect runtime deps for a built amd64 release. Set RELEASE=exocomp_node or exocomp_coordinator.
	@test -n "$(RELEASE)" || { echo "RELEASE is required; e.g. make inspect-deps-amd64 RELEASE=exocomp_node" >&2; exit 2; }
	./scripts/inspect-release-deps.sh amd64 _build/release/amd64/rel/$(RELEASE)

inspect-deps-arm64: ## Inspect runtime deps for a built arm64 release. Set RELEASE=exocomp_node or exocomp_coordinator.
	@test -n "$(RELEASE)" || { echo "RELEASE is required; e.g. make inspect-deps-arm64 RELEASE=exocomp_node" >&2; exit 2; }
	./scripts/inspect-release-deps.sh arm64 _build/release/arm64/rel/$(RELEASE)

test: test-builders ## Run the test suite.
	$(CONTAINER_RUN) sh -c '$(HEX_BOOTSTRAP) && MIX_ENV=test mix deps.get && \
		MIX_ENV=test mix test && \
		MIX_ENV=test mix release exocomp_node --overwrite && \
		MIX_ENV=test mix release exocomp_coordinator --overwrite && \
		scripts/smoke-releases.sh test'

test-builders: ## Validate immutable multi-architecture builder definitions and runtime dep inspection.
	./scripts/test-release-builders.sh

test-deps: ## Run runtime dependency inspection tests (no container required).
	./scripts/test-runtime-deps.sh

PROFILE_ACTION_HELPER_DIR := apps/exocomp_node/priv
PROFILE_ACTION_HELPER_BUILD_DIR := _build/profile-action-helper
PROFILE_ACTION_HELPER_CFLAGS := -std=c11 -O2 -g -Wall -Wextra -Wpedantic -Wconversion -Wshadow -Werror -D_FORTIFY_SOURCE=2 -fstack-protector-strong -fPIE
PROFILE_ACTION_HELPER_LDFLAGS := -Wl,-z,relro,-z,now -pie

build-profile-action-helper: ## Compile the fixed-argv Ceph profile-action helper.
	mkdir -p "$(PROFILE_ACTION_HELPER_BUILD_DIR)"
	$(CC) $(PROFILE_ACTION_HELPER_CFLAGS) $(PROFILE_ACTION_HELPER_LDFLAGS) \
		-I"$(PROFILE_ACTION_HELPER_DIR)" \
		"$(PROFILE_ACTION_HELPER_DIR)/profile_action_helper.c" \
		-o "$(PROFILE_ACTION_HELPER_BUILD_DIR)/profile_action_helper"

test-profile-action-helper: build-profile-action-helper ## Run parser, validator, and subprocess-failure tests for the helper.
	mkdir -p "$(PROFILE_ACTION_HELPER_BUILD_DIR)"
	$(CC) $(PROFILE_ACTION_HELPER_CFLAGS) $(PROFILE_ACTION_HELPER_LDFLAGS) \
		-DPROFILE_ACTION_HELPER_NO_MAIN -I"$(PROFILE_ACTION_HELPER_DIR)" \
		"$(PROFILE_ACTION_HELPER_DIR)/profile_action_helper.c" \
		"apps/exocomp_node/test/native/profile_action_helper_test.c" \
		-o "$(PROFILE_ACTION_HELPER_BUILD_DIR)/profile_action_helper_test"
	"$(PROFILE_ACTION_HELPER_BUILD_DIR)/profile_action_helper_test"
	@set +e; "$(PROFILE_ACTION_HELPER_BUILD_DIR)/profile_action_helper" --unexpected >/dev/null 2>&1; status=$$?; test "$$status" -eq 2

test-release-matrix: ## Run OTP release qualification matrix (requires Docker and real builds). Pass ARCH=amd64|arm64 to test one arch; SKIP_BUILD=1 to skip rebuild.
	./scripts/test-release-matrix.sh \
		$(if $(ARCH),--arch $(ARCH)) \
		$(if $(filter 1,$(SKIP_BUILD)),--skip-build)

test-release-packaging: ## Test deterministic archives, secret omission, manifests, and operator commands.
	$(PYTHON) -m unittest discover -s tests -p 'test_package_release.py' -v
	$(PYTHON) -m unittest discover -s tests -p 'test_release_input_normalizer.py' -v
	$(PYTHON) -m unittest discover -s tests -p 'test_operator_docs.py' -v

lint: test-builders ## Run static analysis / linters.
	$(CONTAINER_RUN) sh -c '$(HEX_BOOTSTRAP) && mix deps.get && \
		mix format --check-formatted && \
		MIX_ENV=test mix compile --force --warnings-as-errors'
	@$(PYTHON) -m py_compile scripts/check_compliance.py \
		tests/test_check_compliance.py
	@$(MAKE) compliance-check

test-compliance: ## Run open-source governance and license tests.
	@$(PYTHON) -m unittest discover -s tests -v

compliance-check: ## Validate governance, links, headers, and license inventory.
	@$(PYTHON) scripts/check_compliance.py

check-links: ## Validate local documentation links and external URL forms.
	@$(PYTHON) scripts/check_compliance.py --check links

check-licenses: ## Validate license text, headers, dependencies, and notices.
	@$(PYTHON) scripts/check_compliance.py --check licenses

release-check: ## Run governance checks required before a release.
	@$(MAKE) compliance-check
	@$(MAKE) test-compliance

clean: ## Remove build artifacts.
	$(CONTAINER_RUN) rm -rf _build

gen-test-fixtures: ## Generate TLS test fixture certificates for apps/exocomp_node test suite.
	bash scripts/gen-test-certs.sh

test-fixture-service: ## Run exocomp-fixture daemon unit tests (requires Python 3.11+, no systemd needed).
	python3 -m pytest test/fixtures/exocomp_fixture/test/test_fixture.py -v

fixture-install: ## Install the exocomp-fixture systemd service (requires root; run inside a VM or privileged container with systemd).
	bash test/fixtures/exocomp_fixture/install.sh

fixture-cleanup: ## Remove the exocomp-fixture systemd service (requires root; idempotent, no-op if not installed).
	bash test/fixtures/exocomp_fixture/cleanup.sh

test-integration: ## Run ExUnit systemd integration tests (requires root + systemd; do NOT run via the standard builder container).
	@echo "NOTE: Run this target directly inside a privileged container or VM with systemd as PID 1."
	@echo "Do NOT invoke via 'make test' — that target runs in an unprivileged Alpine container without systemd."
	MIX_ENV=test mix test --only integration apps/exocomp_node/test/integration/

bench-llama-short: ## Run focused llama.cpp inference benchmark tests (CI short run; no real llama-server required).
	$(CONTAINER_RUN) sh -c 'MIX_ENV=test mix deps.get && \
		MIX_ENV=test mix test --only bench_llama apps/bench/test/bench/workload/llama_inference_test.exs'

bench-harness: ## Build the standalone M5 harness with the pinned native-architecture builder.
	$(CONTAINER_RUN) sh -c '$(HEX_BOOTSTRAP) && MIX_ENV=prod mix deps.get && \
		MIX_ENV=prod mix do --app bench cmd mix release bench_harness --overwrite'

bench-llama-short-shipped: bench-harness ## Run the short M5 gate against real shipped node, coordinator, and llama-server artifacts.
	env \
		BENCH_MODE=short \
		LLAMA_SERVER="$(LLAMA_SERVER)" \
		LLAMA_LIB_DIR="$(LLAMA_LIB_DIR)" \
		NODE_RELEASE="$(NODE_RELEASE)" \
		COORD_RELEASE="$(COORD_RELEASE)" \
		MODEL_PATH="$(MODEL_PATH)" \
		MODEL_SHA256="$(MODEL_SHA256)" \
		$(if $(BENCH_EVIDENCE_DIR),BENCH_EVIDENCE_DIR="$(BENCH_EVIDENCE_DIR)") \
		$(if $(BENCH_LLAMA_PORT),BENCH_LLAMA_PORT="$(BENCH_LLAMA_PORT)") \
		$(if $(BENCH_WARM_UP_SECONDS),BENCH_WARM_UP_SECONDS="$(BENCH_WARM_UP_SECONDS)") \
		$(if $(BENCH_RUN_SECONDS),BENCH_RUN_SECONDS="$(BENCH_RUN_SECONDS)") \
		$(if $(BENCH_SAMPLE_INTERVAL_MS),BENCH_SAMPLE_INTERVAL_MS="$(BENCH_SAMPLE_INTERVAL_MS)") \
		$(if $(BENCH_INFERENCE_TIMEOUT_MS),BENCH_INFERENCE_TIMEOUT_MS="$(BENCH_INFERENCE_TIMEOUT_MS)") \
		$(if $(BENCH_RESTART_TIMEOUT_MS),BENCH_RESTART_TIMEOUT_MS="$(BENCH_RESTART_TIMEOUT_MS)") \
		$(if $(BENCH_PROPOSAL_COUNT),BENCH_PROPOSAL_COUNT="$(BENCH_PROPOSAL_COUNT)") \
		$(if $(BENCH_SOAK_LOAD_INTERVAL_SECONDS),BENCH_SOAK_LOAD_INTERVAL_SECONDS="$(BENCH_SOAK_LOAD_INTERVAL_SECONDS)") \
		$(if $(BENCH_POLL_CYCLES),BENCH_POLL_CYCLES="$(BENCH_POLL_CYCLES)") \
		$(if $(BENCH_POLL_CONCURRENCY),BENCH_POLL_CONCURRENCY="$(BENCH_POLL_CONCURRENCY)") \
		"$(BENCH_HARNESS)" eval 'System.halt(Bench.Qualification.CLI.main())'

bench-llama-full: bench-harness ## Run the full M5 release gate against installed shipped processes (minimum two-hour soak).
	env \
		BENCH_MODE=full \
		LLAMA_SERVER="$(LLAMA_SERVER)" \
		LLAMA_LIB_DIR="$(LLAMA_LIB_DIR)" \
		NODE_RELEASE="$(NODE_RELEASE)" \
		COORD_RELEASE="$(COORD_RELEASE)" \
		MODEL_PATH="$(MODEL_PATH)" \
		MODEL_SHA256="$(MODEL_SHA256)" \
		$(if $(BENCH_EVIDENCE_DIR),BENCH_EVIDENCE_DIR="$(BENCH_EVIDENCE_DIR)") \
		$(if $(BENCH_LLAMA_PORT),BENCH_LLAMA_PORT="$(BENCH_LLAMA_PORT)") \
		$(if $(BENCH_WARM_UP_SECONDS),BENCH_WARM_UP_SECONDS="$(BENCH_WARM_UP_SECONDS)") \
		$(if $(BENCH_RUN_SECONDS),BENCH_RUN_SECONDS="$(BENCH_RUN_SECONDS)") \
		$(if $(BENCH_SAMPLE_INTERVAL_MS),BENCH_SAMPLE_INTERVAL_MS="$(BENCH_SAMPLE_INTERVAL_MS)") \
		$(if $(BENCH_INFERENCE_TIMEOUT_MS),BENCH_INFERENCE_TIMEOUT_MS="$(BENCH_INFERENCE_TIMEOUT_MS)") \
		$(if $(BENCH_RESTART_TIMEOUT_MS),BENCH_RESTART_TIMEOUT_MS="$(BENCH_RESTART_TIMEOUT_MS)") \
		$(if $(BENCH_PROPOSAL_COUNT),BENCH_PROPOSAL_COUNT="$(BENCH_PROPOSAL_COUNT)") \
		$(if $(BENCH_SOAK_LOAD_INTERVAL_SECONDS),BENCH_SOAK_LOAD_INTERVAL_SECONDS="$(BENCH_SOAK_LOAD_INTERVAL_SECONDS)") \
		$(if $(BENCH_POLL_CYCLES),BENCH_POLL_CYCLES="$(BENCH_POLL_CYCLES)") \
		$(if $(BENCH_POLL_CONCURRENCY),BENCH_POLL_CONCURRENCY="$(BENCH_POLL_CONCURRENCY)") \
		"$(BENCH_HARNESS)" eval 'System.halt(Bench.Qualification.CLI.main())'

test-m5-qualification: ## Run focused M5 shipped-artifact configuration, identity, baseline, gate, and evidence tests.
	$(PYTHON) -m unittest discover -s tests -p 'test_m5_qualification.py' -v
	$(CONTAINER_RUN) sh -c '$(HEX_BOOTSTRAP) && MIX_ENV=test mix deps.get && \
		MIX_ENV=test mix do --app bench cmd mix test \
		test/bench/analysis/soak_test.exs \
		test/bench/artifact_identity_test.exs \
		test/bench/baseline_test.exs \
		test/bench/qualification/config_test.exs \
		test/bench/qualification/rpc_test.exs \
		test/bench/qualification_test.exs \
		test/bench/report/summary_test.exs \
		test/bench/workload/soak_test.exs && \
		MIX_ENV=test mix do --app exocomp_core cmd mix test \
		test/exocomp/qualification_probe_test.exs && \
		MIX_ENV=test mix do --app exocomp_coordinator cmd mix test \
		test/exocomp/coordinator/qualification_probe_test.exs'

test-installer: ## Run hardened installer/uninstaller tests (requires Python 3.11+, no systemd or root needed).
	python3 -m pytest test/installer/test_installer.py -v

test-bundle: ## Run offline bundle assembly, SBOM, provenance, and tamper-detection tests (requires Python 3.11+).
	python3 -m pytest tests/test_bundle.py -v

bundle-amd64: ## Assemble complete offline bundle for amd64. Set release archives, LLAMA_SERVER_AMD64, LLAMA_LIB_DIR_AMD64, MODEL_PATH, MODEL_SHA256.
	bash scripts/assemble-bundle.sh \
		--arch amd64 \
		--version "$(BUNDLE_VERSION)" \
		--kind complete \
		$(if $(NODE_ARCHIVE_AMD64),--node-archive "$(NODE_ARCHIVE_AMD64)") \
		$(if $(COORD_ARCHIVE_AMD64),--coord-archive "$(COORD_ARCHIVE_AMD64)") \
		$(if $(LLAMA_SERVER_AMD64),--llama-server "$(LLAMA_SERVER_AMD64)") \
		$(if $(LLAMA_LIB_DIR_AMD64),--llama-lib-dir "$(LLAMA_LIB_DIR_AMD64)") \
		$(if $(MODEL_PATH),--model "$(MODEL_PATH)") \
		$(if $(MODEL_SHA256),--model-sha256 "$(MODEL_SHA256)") \
		$(if $(BUNDLE_BUILDER_IMAGE),--builder-image "$(BUNDLE_BUILDER_IMAGE)") \
		$(if $(BUNDLE_SIGN_KEY),--sign-key "$(BUNDLE_SIGN_KEY)") \
		--source-commit "$(BUNDLE_SOURCE_COMMIT)" \
		--dist-dir "$(BUNDLE_DIST)"

bundle-arm64: ## Assemble complete offline bundle for arm64. Set release archives, LLAMA_SERVER_ARM64, LLAMA_LIB_DIR_ARM64, MODEL_PATH, MODEL_SHA256.
	bash scripts/assemble-bundle.sh \
		--arch arm64 \
		--version "$(BUNDLE_VERSION)" \
		--kind complete \
		$(if $(NODE_ARCHIVE_ARM64),--node-archive "$(NODE_ARCHIVE_ARM64)") \
		$(if $(COORD_ARCHIVE_ARM64),--coord-archive "$(COORD_ARCHIVE_ARM64)") \
		$(if $(LLAMA_SERVER_ARM64),--llama-server "$(LLAMA_SERVER_ARM64)") \
		$(if $(LLAMA_LIB_DIR_ARM64),--llama-lib-dir "$(LLAMA_LIB_DIR_ARM64)") \
		$(if $(MODEL_PATH),--model "$(MODEL_PATH)") \
		$(if $(MODEL_SHA256),--model-sha256 "$(MODEL_SHA256)") \
		$(if $(BUNDLE_BUILDER_IMAGE),--builder-image "$(BUNDLE_BUILDER_IMAGE)") \
		$(if $(BUNDLE_SIGN_KEY),--sign-key "$(BUNDLE_SIGN_KEY)") \
		--source-commit "$(BUNDLE_SOURCE_COMMIT)" \
		--dist-dir "$(BUNDLE_DIST)"

bundle-runtime-amd64: ## Assemble runtime-only bundle for amd64. Set release archives, LLAMA_SERVER_AMD64, LLAMA_LIB_DIR_AMD64.
	bash scripts/assemble-bundle.sh \
		--arch amd64 \
		--version "$(BUNDLE_VERSION)" \
		--kind runtime \
		$(if $(NODE_ARCHIVE_AMD64),--node-archive "$(NODE_ARCHIVE_AMD64)") \
		$(if $(COORD_ARCHIVE_AMD64),--coord-archive "$(COORD_ARCHIVE_AMD64)") \
		$(if $(LLAMA_SERVER_AMD64),--llama-server "$(LLAMA_SERVER_AMD64)") \
		$(if $(LLAMA_LIB_DIR_AMD64),--llama-lib-dir "$(LLAMA_LIB_DIR_AMD64)") \
		$(if $(BUNDLE_BUILDER_IMAGE),--builder-image "$(BUNDLE_BUILDER_IMAGE)") \
		$(if $(BUNDLE_SIGN_KEY),--sign-key "$(BUNDLE_SIGN_KEY)") \
		--source-commit "$(BUNDLE_SOURCE_COMMIT)" \
		--dist-dir "$(BUNDLE_DIST)"

bundle-runtime-arm64: ## Assemble runtime-only bundle for arm64. Set release archives, LLAMA_SERVER_ARM64, LLAMA_LIB_DIR_ARM64.
	bash scripts/assemble-bundle.sh \
		--arch arm64 \
		--version "$(BUNDLE_VERSION)" \
		--kind runtime \
		$(if $(NODE_ARCHIVE_ARM64),--node-archive "$(NODE_ARCHIVE_ARM64)") \
		$(if $(COORD_ARCHIVE_ARM64),--coord-archive "$(COORD_ARCHIVE_ARM64)") \
		$(if $(LLAMA_SERVER_ARM64),--llama-server "$(LLAMA_SERVER_ARM64)") \
		$(if $(LLAMA_LIB_DIR_ARM64),--llama-lib-dir "$(LLAMA_LIB_DIR_ARM64)") \
		$(if $(BUNDLE_BUILDER_IMAGE),--builder-image "$(BUNDLE_BUILDER_IMAGE)") \
		$(if $(BUNDLE_SIGN_KEY),--sign-key "$(BUNDLE_SIGN_KEY)") \
		--source-commit "$(BUNDLE_SOURCE_COMMIT)" \
		--dist-dir "$(BUNDLE_DIST)"

verify-bundle: ## Verify an extracted bundle. Set BUNDLE_DIR=<path> and optionally PUBLIC_KEY=<path>.
	@test -n "$(BUNDLE_DIR)" || (echo "ERROR: BUNDLE_DIR is required (e.g. make verify-bundle BUNDLE_DIR=./dist/exocomp-complete-1.0.0-linux-amd64)" && exit 1)
	bash scripts/verify-bundle.sh \
		--bundle-dir "$(BUNDLE_DIR)" \
		$(if $(PUBLIC_KEY),--public-key "$(PUBLIC_KEY)") \
		$(if $(BUNDLE_STRICT),--strict)
