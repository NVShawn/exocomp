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

CONTAINER_RUN := $(CONTAINER_ENGINE) run --rm --init \
	$(_CONTAINER_USER_FLAG) \
	--env ELIXIR_VERSION=$(ELIXIR_VERSION) \
	--env OTP_VERSION=$(OTP_VERSION) \
	--volume "$(CURDIR):/workspace" \
	--workdir /workspace \
	$(BUILDER_IMAGE)

.PHONY: help init fmt fmt-check build test lint clean gen-test-fixtures test-fixture-service

help: ## Show this help.
	@awk 'BEGIN {FS = ":.*?## "; printf "Usage: make <target>\n\nTargets:\n"} \
		/^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}' \
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
		mix compile --warnings-as-errors && \
		MIX_ENV=prod mix release exocomp_node --overwrite && \
		MIX_ENV=prod mix release exocomp_coordinator --overwrite'

test: ## Run the test suite.
	$(CONTAINER_RUN) sh -c 'MIX_ENV=test mix test && \
		MIX_ENV=test mix release exocomp_node --overwrite && \
		MIX_ENV=test mix release exocomp_coordinator --overwrite && \
		scripts/smoke-releases.sh test'

lint: ## Run static analysis / linters.
	$(CONTAINER_RUN) sh -c 'mix format --check-formatted && \
		MIX_ENV=test mix compile --force --warnings-as-errors'

clean: ## Remove build artifacts.
	$(CONTAINER_RUN) rm -rf _build

gen-test-fixtures: ## Generate TLS test fixture certificates for apps/exocomp_node test suite.
	bash scripts/gen-test-certs.sh

test-fixture-service: ## Run exocomp-fixture daemon unit tests (requires Python 3.11+, no systemd needed).
	python3 -m pytest test/fixtures/exocomp_fixture/test/test_fixture.py -v
