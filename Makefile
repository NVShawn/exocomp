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
BUILDER_IMAGE := hexpm/elixir:$(ELIXIR_VERSION)-erlang-$(OTP_VERSION)-alpine-$(ALPINE_VERSION)@sha256:53d8a7a0caf2c4979041a8efe29a42567fe67dc0d6d982c9df00d67e7b37caa6
CONTAINER_ENGINE ?= docker
CONTAINER_RUN := $(CONTAINER_ENGINE) run --rm --init \
	--user "$$(id -u):$$(id -g)" \
	--env ELIXIR_VERSION=$(ELIXIR_VERSION) \
	--env OTP_VERSION=$(OTP_VERSION) \
	--volume "$(CURDIR):/workspace" \
	--workdir /workspace \
	$(BUILDER_IMAGE)

.PHONY: help init fmt fmt-check build test lint clean

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
