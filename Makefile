# BEGIN OOMPAH PROJECT BOOTSTRAP v:1
# Project Makefile.
#
# Targets are documented inline with `## ` comments so `make help` stays
# current as this file is customized.
# END OOMPAH PROJECT BOOTSTRAP

.DEFAULT_GOAL := help

ELIXIR_VERSION := 1.20.2
OTP_VERSION := 28.5.0.3
ALPINE_VERSION := 3.24.1
BUILDER_IMAGE := docker.io/hexpm/elixir:$(ELIXIR_VERSION)-erlang-$(OTP_VERSION)-alpine-$(ALPINE_VERSION)@sha256:53d8a7a0caf2c4979041a8efe29a42567fe67dc0d6d982c9df00d67e7b37caa6
CONTAINER_ENGINE ?= docker

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
	--env ELIXIR_VERSION=$(ELIXIR_VERSION) \
	--env OTP_VERSION=$(OTP_VERSION) \
	--env MIX_HOME=/workspace/.mix-home \
	--env HEX_HOME=/workspace/.hex-home \
	--volume "$(CURDIR):/workspace" \
	--workdir /workspace \
	$(BUILDER_IMAGE)

.PHONY: help init fmt fmt-check build test lint clean gen-test-fixtures test-fixture-service fixture-install fixture-cleanup test-integration bench-llama-short test-installer test-bundle bundle-amd64 bundle-arm64 bundle-runtime-amd64 bundle-runtime-arm64 verify-bundle

# Bundle assembly variables (override on command line as needed)
BUNDLE_VERSION ?= $(shell git describe --tags --exact-match 2>/dev/null | sed 's/^v//' || echo "dev")
BUNDLE_SOURCE_COMMIT ?= $(shell git rev-parse HEAD 2>/dev/null || echo "unknown")
BUNDLE_DIST ?= dist
# Paths to pre-built OTP archives (set these when calling bundle targets)
NODE_ARCHIVE_AMD64 ?= _build/release/amd64/rel/exocomp_node
NODE_ARCHIVE_ARM64 ?= _build/release/arm64/rel/exocomp_node
COORD_ARCHIVE_AMD64 ?= _build/release/amd64/rel/exocomp_coordinator
COORD_ARCHIVE_ARM64 ?= _build/release/arm64/rel/exocomp_coordinator
# Path to llama-server binary (set to the pinned binary for the target arch)
LLAMA_SERVER_AMD64 ?=
LLAMA_SERVER_ARM64 ?=
# Path to verified Qwen GGUF model and its SHA-256 (complete bundle only)
MODEL_PATH ?=
MODEL_SHA256 ?=

help: ## Show this help.
	@awk 'BEGIN {FS = ":.*?## "; printf "Usage: make <target>\n\nTargets:\n"} \
		/^[a-zA-Z0-9_-]+:.*?## / {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}' \
		$(MAKEFILE_LIST)

init: ## Initialize local repo prerequisites.
	$(CONTAINER_ENGINE) pull $(BUILDER_IMAGE)
	$(CONTAINER_RUN) scripts/verify-toolchain.sh

fmt: ## Format all source files in place.
	$(CONTAINER_RUN) mix format

fmt-check: ## Check formatting without modifying files.
	$(CONTAINER_RUN) mix format --check-formatted

build: ## Build the project.
	$(CONTAINER_RUN) sh -c 'scripts/verify-toolchain.sh && \
		mix deps.get && \
		mix compile --warnings-as-errors && \
		MIX_ENV=prod mix release exocomp_node --overwrite && \
		MIX_ENV=prod mix release exocomp_coordinator --overwrite'

test: ## Run the test suite.
	$(CONTAINER_RUN) sh -c 'MIX_ENV=test mix deps.get && \
		MIX_ENV=test mix test && \
		MIX_ENV=test mix release exocomp_node --overwrite && \
		MIX_ENV=test mix release exocomp_coordinator --overwrite && \
		scripts/smoke-releases.sh test'

lint: ## Run static analysis / linters.
	$(CONTAINER_RUN) sh -c 'mix deps.get && \
		mix format --check-formatted && \
		MIX_ENV=test mix compile --force --warnings-as-errors'

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

test-installer: ## Run hardened installer/uninstaller tests (requires Python 3.11+, no systemd or root needed).
	python3 -m pytest test/installer/test_installer.py -v

test-bundle: ## Run offline bundle assembly, SBOM, provenance, and tamper-detection tests (requires Python 3.11+).
	python3 -m pytest tests/test_bundle.py -v

bundle-amd64: ## Assemble complete offline bundle for amd64. Set NODE_ARCHIVE_AMD64, COORD_ARCHIVE_AMD64, LLAMA_SERVER_AMD64, MODEL_PATH, MODEL_SHA256.
	bash scripts/assemble-bundle.sh \
		--arch amd64 \
		--version "$(BUNDLE_VERSION)" \
		--kind complete \
		$(if $(NODE_ARCHIVE_AMD64),--node-archive "$(NODE_ARCHIVE_AMD64)") \
		$(if $(COORD_ARCHIVE_AMD64),--coord-archive "$(COORD_ARCHIVE_AMD64)") \
		$(if $(LLAMA_SERVER_AMD64),--llama-server "$(LLAMA_SERVER_AMD64)") \
		$(if $(MODEL_PATH),--model "$(MODEL_PATH)") \
		$(if $(MODEL_SHA256),--model-sha256 "$(MODEL_SHA256)") \
		--source-commit "$(BUNDLE_SOURCE_COMMIT)" \
		--dist-dir "$(BUNDLE_DIST)"

bundle-arm64: ## Assemble complete offline bundle for arm64. Set NODE_ARCHIVE_ARM64, COORD_ARCHIVE_ARM64, LLAMA_SERVER_ARM64, MODEL_PATH, MODEL_SHA256.
	bash scripts/assemble-bundle.sh \
		--arch arm64 \
		--version "$(BUNDLE_VERSION)" \
		--kind complete \
		$(if $(NODE_ARCHIVE_ARM64),--node-archive "$(NODE_ARCHIVE_ARM64)") \
		$(if $(COORD_ARCHIVE_ARM64),--coord-archive "$(COORD_ARCHIVE_ARM64)") \
		$(if $(LLAMA_SERVER_ARM64),--llama-server "$(LLAMA_SERVER_ARM64)") \
		$(if $(MODEL_PATH),--model "$(MODEL_PATH)") \
		$(if $(MODEL_SHA256),--model-sha256 "$(MODEL_SHA256)") \
		--source-commit "$(BUNDLE_SOURCE_COMMIT)" \
		--dist-dir "$(BUNDLE_DIST)"

bundle-runtime-amd64: ## Assemble runtime-only bundle for amd64 (no model). Set NODE_ARCHIVE_AMD64, COORD_ARCHIVE_AMD64, LLAMA_SERVER_AMD64.
	bash scripts/assemble-bundle.sh \
		--arch amd64 \
		--version "$(BUNDLE_VERSION)" \
		--kind runtime \
		$(if $(NODE_ARCHIVE_AMD64),--node-archive "$(NODE_ARCHIVE_AMD64)") \
		$(if $(COORD_ARCHIVE_AMD64),--coord-archive "$(COORD_ARCHIVE_AMD64)") \
		$(if $(LLAMA_SERVER_AMD64),--llama-server "$(LLAMA_SERVER_AMD64)") \
		--source-commit "$(BUNDLE_SOURCE_COMMIT)" \
		--dist-dir "$(BUNDLE_DIST)"

bundle-runtime-arm64: ## Assemble runtime-only bundle for arm64 (no model). Set NODE_ARCHIVE_ARM64, COORD_ARCHIVE_ARM64, LLAMA_SERVER_ARM64.
	bash scripts/assemble-bundle.sh \
		--arch arm64 \
		--version "$(BUNDLE_VERSION)" \
		--kind runtime \
		$(if $(NODE_ARCHIVE_ARM64),--node-archive "$(NODE_ARCHIVE_ARM64)") \
		$(if $(COORD_ARCHIVE_ARM64),--coord-archive "$(COORD_ARCHIVE_ARM64)") \
		$(if $(LLAMA_SERVER_ARM64),--llama-server "$(LLAMA_SERVER_ARM64)") \
		--source-commit "$(BUNDLE_SOURCE_COMMIT)" \
		--dist-dir "$(BUNDLE_DIST)"

verify-bundle: ## Verify an extracted bundle. Set BUNDLE_DIR=<path> and optionally PUBLIC_KEY=<path>.
	@test -n "$(BUNDLE_DIR)" || (echo "ERROR: BUNDLE_DIR is required (e.g. make verify-bundle BUNDLE_DIR=./dist/exocomp-complete-1.0.0-linux-amd64)" && exit 1)
	bash scripts/verify-bundle.sh \
		--bundle-dir "$(BUNDLE_DIR)" \
		$(if $(PUBLIC_KEY),--public-key "$(PUBLIC_KEY)") \
		$(if $(BUNDLE_STRICT),--strict)
