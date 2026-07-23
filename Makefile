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
# Detect rootless Docker.  In rootless mode container uid 0 already maps to
# the host user, so --user is not only unnecessary but actively breaks dep
# fetching because it maps to an in-container uid that does not own the
# workspace mount.  In rootful Docker the --user flag is required so that
# generated artifacts are owned by the real user rather than root.
DOCKER_ROOTLESS := $(shell $(CONTAINER_ENGINE) info 2>/dev/null | grep -c 'rootless: true')
ifeq ($(DOCKER_ROOTLESS),1)
CONTAINER_USER :=
else
CONTAINER_USER := --user "$$(id -u):$$(id -g)"
endif

# Give the process a writable home in /tmp so that `mix local.hex` and the
# Hex package cache can write there regardless of which uid is used inside
# the container.
CONTAINER_RUN := $(CONTAINER_ENGINE) run --rm --init \
	$(CONTAINER_USER) \
	--env HOME=/tmp \
	--env MIX_HOME=/tmp/.mix \
	--env HEX_HOME=/tmp/.hex \
	--env ELIXIR_VERSION=$(ELIXIR_VERSION) \
	--env OTP_VERSION=$(OTP_VERSION) \
	--volume "$(CURDIR):/workspace" \
	--workdir /workspace \
	$(BUILDER_IMAGE)
# Bootstrap snippet prepended to every shell target that needs Hex/deps.
DEPS_BOOTSTRAP := mix local.hex --force --quiet && mix local.rebar --force --quiet && mix deps.get --quiet &&

.PHONY: help init fmt fmt-check build test lint clean gen-test-fixtures test-fixture-service fixture-install fixture-cleanup test-integration

help: ## Show this help.
	@awk 'BEGIN {FS = ":.*?## "; printf "Usage: make <target>\n\nTargets:\n"} \
		/^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}' \
		$(MAKEFILE_LIST)

init: ## Initialize local repo prerequisites.
	$(CONTAINER_ENGINE) pull $(BUILDER_IMAGE)
	$(CONTAINER_RUN) scripts/verify-toolchain.sh

fmt: ## Format all source files in place.
	$(CONTAINER_RUN) sh -c '$(DEPS_BOOTSTRAP) mix format'

fmt-check: ## Check formatting without modifying files.
	$(CONTAINER_RUN) sh -c '$(DEPS_BOOTSTRAP) mix format --check-formatted'

build: ## Build the project.
	$(CONTAINER_RUN) sh -c '$(DEPS_BOOTSTRAP) scripts/verify-toolchain.sh && \
		mix compile --warnings-as-errors && \
		MIX_ENV=prod mix release exocomp_node --overwrite && \
		MIX_ENV=prod mix release exocomp_coordinator --overwrite'

test: ## Run the test suite.
	$(CONTAINER_RUN) sh -c '$(DEPS_BOOTSTRAP) MIX_ENV=test mix test && \
		MIX_ENV=test mix release exocomp_node --overwrite && \
		MIX_ENV=test mix release exocomp_coordinator --overwrite && \
		scripts/smoke-releases.sh test'

lint: ## Run static analysis / linters.
	$(CONTAINER_RUN) sh -c '$(DEPS_BOOTSTRAP) mix format --check-formatted && \
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
