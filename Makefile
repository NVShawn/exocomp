# BEGIN OOMPAH PROJECT BOOTSTRAP v:1
# Project Makefile.
#
# Targets are documented inline with `## ` comments so `make help` stays
# current as this file is customized.
# END OOMPAH PROJECT BOOTSTRAP

.DEFAULT_GOAL := help

include release/builders.lock

CONTAINER_ENGINE ?= docker
HOST_MACHINE := $(shell uname -m)
DEV_ARCH := $(if $(filter x86_64,$(HOST_MACHINE)),amd64,$(if $(filter aarch64 arm64,$(HOST_MACHINE)),arm64,unsupported))
DEV_BUILDER_DIGEST := $(if $(filter amd64,$(DEV_ARCH)),$(BUILDER_AMD64_DIGEST),$(BUILDER_ARM64_DIGEST))
DEV_BUILDER_IMAGE := docker.io/hexpm/elixir:$(BUILDER_TAG)@$(DEV_BUILDER_DIGEST)
CONTAINER_RUN := $(CONTAINER_ENGINE) run --rm --init \
	--platform linux/$(DEV_ARCH) \
	--pull always \
	--user "$$(id -u):$$(id -g)" \
	--env ELIXIR_VERSION=$(ELIXIR_VERSION) \
	--env OTP_VERSION=$(OTP_VERSION) \
	--env GLIBC_BASELINE=$(GLIBC_BASELINE) \
	--volume "$(CURDIR):/workspace" \
	--workdir /workspace \
	$(DEV_BUILDER_IMAGE)

.PHONY: help init init-amd64 init-arm64 fmt fmt-check build build-amd64 \
	build-arm64 test test-builders test-deps inspect-deps-amd64 \
	inspect-deps-arm64 lint clean

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

fmt: ## Format all source files in place.
	$(CONTAINER_RUN) mix format

fmt-check: ## Check formatting without modifying files.
	$(CONTAINER_RUN) mix format --check-formatted

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
	$(CONTAINER_RUN) sh -c 'MIX_ENV=test mix test && \
		MIX_ENV=test mix release exocomp_node --overwrite && \
		MIX_ENV=test mix release exocomp_coordinator --overwrite && \
		scripts/smoke-releases.sh test'

test-builders: ## Validate immutable multi-architecture builder definitions and runtime dep inspection.
	./scripts/test-release-builders.sh

test-deps: ## Run runtime dependency inspection tests (no container required).
	./scripts/test-runtime-deps.sh

lint: test-builders ## Run static analysis / linters.
	$(CONTAINER_RUN) sh -c 'mix format --check-formatted && \
		MIX_ENV=test mix compile --force --warnings-as-errors'

clean: ## Remove build artifacts.
	$(CONTAINER_RUN) rm -rf _build
