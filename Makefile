# BEGIN OOMPAH PROJECT BOOTSTRAP v:1
# Project Makefile.
#
# Targets are documented inline with `## ` comments so `make help` stays
# current as this file is customized.
# END OOMPAH PROJECT BOOTSTRAP

.DEFAULT_GOAL := help

PYTHON ?= python3

.PHONY: help init fmt fmt-check build test test-compliance lint \
	compliance-check check-links check-licenses release-check clean

help: ## Show this help.
	@awk 'BEGIN {FS = ":.*?## "; printf "Usage: make <target>\n\nTargets:\n"} \
		/^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}' \
		$(MAKEFILE_LIST)

init: ## Initialize local repo prerequisites.
	@set -e; \
	if [ ! -d .git ]; then \
		echo "[init] git init"; \
		git init; \
	else \
		echo "[init] git: already initialized"; \
	fi; \
	if command -v oompah >/dev/null 2>&1; then \
		echo "[init] oompah: $$(oompah --help >/dev/null 2>&1 && echo installed)"; \
	else \
		echo "[init] oompah CLI not found. Install with:"; \
		echo "       uv tool install git+https://github.com/lesserevil/oompah"; \
	fi

fmt: ## Format all source files in place.
	@echo "fmt: not yet configured - edit Makefile" && exit 1

fmt-check: ## Check formatting without modifying files.
	@$(PYTHON) scripts/check_compliance.py --check format

build: ## Build the project.
	@echo "build: not yet configured - edit Makefile" && exit 1

test: ## Run the test suite.
	@$(MAKE) test-compliance

test-compliance: ## Run open-source governance and license tests.
	@$(PYTHON) -m unittest discover -s tests -v

lint: ## Run static analysis / linters.
	@$(PYTHON) -m py_compile scripts/check_compliance.py \
		tests/test_check_compliance.py
	@$(MAKE) compliance-check

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
	@echo "clean: not yet configured - edit Makefile" && exit 1
