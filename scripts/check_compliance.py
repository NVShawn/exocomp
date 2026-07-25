#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
"""Offline governance, notice, dependency-license, and documentation checks."""

from __future__ import annotations

import argparse
import hashlib
import re
import sys
import tomllib
from pathlib import Path
from urllib.parse import unquote, urlparse


REQUIRED_FILES = (
    "LICENSE",
    "NOTICE",
    "THIRD_PARTY_NOTICES.md",
    "CONTRIBUTING.md",
    "CODE_OF_CONDUCT.md",
    "SECURITY.md",
    "CHANGELOG.md",
    "docs/changelog-policy.md",
    "docs/release-notes-template.md",
    "docs/maintainer-release-checklist.md",
    "licenses/components.toml",
)
COMPONENT_FIELDS = (
    "id",
    "name",
    "version",
    "scope",
    "distribution",
    "license",
    "redistribution",
    "source_url",
    "license_url",
    "notice_file",
    "notice_heading",
)
SOURCE_SUFFIXES = {".c", ".cc", ".ex", ".exs", ".h", ".hpp", ".py", ".sh"}
SKIP_DIRECTORIES = {
    ".git",
    ".oompah-no-hooks",
    "__pycache__",
    "_build",
    "deps",
    "node_modules",
    "vendor",
}
MARKDOWN_LINK = re.compile(r"(?<!!)\[[^\]]+\]\(([^)]+)\)")
HEX_PACKAGE = re.compile(r'\{:hex,\s*:(?:"([^"]+)"|([a-zA-Z0-9_]+))')
SPDX_HEADER = "SPDX-License-Identifier: Apache-2.0"
APACHE_LICENSE_SHA256 = (
    "cfc7749b96f63bd31c3c42b5c471bf756814053e847c10f3eb003417bc523d30"
)


def check_required_files(root: Path) -> list[str]:
    """Return errors for required governance files that are absent."""
    return [
        f"missing required file: {relative}"
        for relative in REQUIRED_FILES
        if not (root / relative).is_file()
    ]


def load_manifest(root: Path) -> tuple[dict, list[str]]:
    """Load the component inventory, returning parse errors without raising."""
    path = root / "licenses/components.toml"
    if not path.is_file():
        return {}, ["cannot inspect notices: licenses/components.toml is missing"]
    try:
        with path.open("rb") as stream:
            return tomllib.load(stream), []
    except (OSError, tomllib.TOMLDecodeError) as error:
        return {}, [f"invalid licenses/components.toml: {error}"]


def check_apache_license(root: Path) -> list[str]:
    """Verify that LICENSE is the canonical Apache-2.0 text."""
    path = root / "LICENSE"
    if not path.is_file():
        return []
    digest = hashlib.sha256(path.read_bytes()).hexdigest()
    if digest != APACHE_LICENSE_SHA256:
        return ["LICENSE is not the complete canonical Apache-2.0 text"]
    return []


def check_notice_inventory(root: Path) -> list[str]:
    """Validate component terms and their human-readable notice entries."""
    manifest, errors = load_manifest(root)
    if errors:
        return errors

    if manifest.get("schema_version") != 1:
        errors.append("licenses/components.toml: schema_version must be 1")

    policy = manifest.get("policy", {})
    approved = set(policy.get("compatible_licenses", []))
    required = set(policy.get("required_components", []))
    components = manifest.get("components", [])
    seen: set[str] = set()

    for index, component in enumerate(components, start=1):
        label = component.get("id", f"entry {index}")
        missing = [field for field in COMPONENT_FIELDS if not component.get(field)]
        if missing:
            errors.append(f"{label}: missing fields: {', '.join(missing)}")
            continue

        component_id = component["id"]
        if component_id in seen:
            errors.append(f"duplicate component id: {component_id}")
        seen.add(component_id)

        license_id = component["license"]
        if license_id not in approved:
            errors.append(
                f"{component_id}: incompatible or unapproved license: {license_id}"
            )
        if component["redistribution"] != "permitted":
            errors.append(f"{component_id}: redistribution is not recorded as permitted")

        for field in ("source_url", "license_url"):
            parsed = urlparse(component[field])
            if parsed.scheme != "https" or not parsed.netloc:
                errors.append(f"{component_id}: {field} must be an absolute HTTPS URL")

        notice_path = root / component["notice_file"]
        if not notice_path.is_file():
            errors.append(
                f"{component_id}: notice file is missing: {component['notice_file']}"
            )
        elif component["notice_heading"] not in notice_path.read_text(
            encoding="utf-8"
        ):
            errors.append(
                f"{component_id}: notice heading missing from "
                f"{component['notice_file']}: {component['notice_heading']}"
            )

    for component_id in sorted(required - seen):
        errors.append(f"missing required notice inventory entry: {component_id}")
    return errors


def locked_hex_packages(root: Path) -> set[str]:
    """Return Hex package names from mix.lock without evaluating Elixir terms."""
    lock_path = root / "mix.lock"
    if not lock_path.is_file():
        return set()
    text = lock_path.read_text(encoding="utf-8")
    return {first or second for first, second in HEX_PACKAGE.findall(text)}


def check_dependency_inventory(root: Path) -> list[str]:
    """Require each direct or transitive Hex lock entry in the license inventory."""
    packages = locked_hex_packages(root)
    if not packages:
        return []
    manifest, errors = load_manifest(root)
    if errors:
        return errors
    recorded = {
        component.get("package")
        for component in manifest.get("components", [])
        if component.get("package")
    }
    return [
        f"mix.lock dependency missing from license inventory: {package}"
        for package in sorted(packages - recorded)
    ]


def repository_files(root: Path):
    """Yield repository files while excluding generated and third-party trees."""
    for path in root.rglob("*"):
        if path.is_file() and not any(part in SKIP_DIRECTORIES for part in path.parts):
            yield path


def is_owned_source(path: Path, root: Path) -> bool:
    """Return whether a file should carry an Exocomp SPDX source header."""
    if path.suffix.lower() in SOURCE_SUFFIXES:
        return True
    relative = path.relative_to(root)
    if relative.parts and relative.parts[0] == "scripts":
        try:
            return path.read_text(encoding="utf-8").startswith("#!")
        except UnicodeDecodeError:
            return False
    return False


def check_license_headers(root: Path) -> list[str]:
    """Require SPDX Apache-2.0 identifiers on repository-owned source."""
    errors = []
    for path in repository_files(root):
        if not is_owned_source(path, root):
            continue
        try:
            header = "\n".join(path.read_text(encoding="utf-8").splitlines()[:8])
        except UnicodeDecodeError:
            continue
        if SPDX_HEADER not in header:
            errors.append(
                f"missing Apache-2.0 SPDX header: {path.relative_to(root)}"
            )
    return errors


def markdown_files(root: Path):
    """Yield Markdown files owned by the repository."""
    for path in repository_files(root):
        if path.suffix.lower() == ".md":
            yield path


def check_links(root: Path) -> list[str]:
    """Check local Markdown targets and require well-formed HTTPS web links."""
    errors = []
    for path in markdown_files(root):
        text = path.read_text(encoding="utf-8")
        for raw_target in MARKDOWN_LINK.findall(text):
            target = raw_target.strip().split(maxsplit=1)[0].strip("<>")
            if not target or target.startswith("#"):
                continue
            parsed = urlparse(target)
            if parsed.scheme:
                if parsed.scheme == "mailto":
                    continue
                if parsed.scheme != "https" or not parsed.netloc:
                    errors.append(
                        f"{path.relative_to(root)}: external link must use HTTPS: "
                        f"{target}"
                    )
                continue
            relative_target = unquote(target.split("#", 1)[0])
            if not relative_target:
                continue
            resolved = (path.parent / relative_target).resolve()
            try:
                resolved.relative_to(root.resolve())
            except ValueError:
                errors.append(
                    f"{path.relative_to(root)}: link escapes repository: {target}"
                )
                continue
            if not resolved.exists():
                errors.append(
                    f"{path.relative_to(root)}: broken local link: {target}"
                )
    return errors


def check_text_format(root: Path) -> list[str]:
    """Detect trailing whitespace and missing final newlines in text files."""
    errors = []
    text_suffixes = SOURCE_SUFFIXES | {".md", ".toml"}
    exact_names = {"LICENSE", "NOTICE", "Makefile"}
    for path in repository_files(root):
        if path.suffix.lower() not in text_suffixes and path.name not in exact_names:
            continue
        try:
            text = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue
        relative = path.relative_to(root)
        if text and not text.endswith("\n"):
            errors.append(f"{relative}: missing final newline")
        for line_number, line in enumerate(text.splitlines(), start=1):
            if line != line.rstrip():
                errors.append(f"{relative}:{line_number}: trailing whitespace")
    return errors


def run_checks(root: Path, selection: str = "all") -> list[str]:
    """Run a named compliance check set and return all findings."""
    checks = {
        "files": [check_required_files],
        "format": [check_text_format],
        "headers": [check_license_headers],
        "links": [check_links],
        "licenses": [
            check_required_files,
            check_apache_license,
            check_notice_inventory,
            check_dependency_inventory,
            check_license_headers,
        ],
        "all": [
            check_required_files,
            check_apache_license,
            check_notice_inventory,
            check_dependency_inventory,
            check_license_headers,
            check_links,
            check_text_format,
        ],
    }
    errors = []
    for check in checks[selection]:
        errors.extend(check(root))
    return errors


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    """Parse command-line arguments."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--root",
        type=Path,
        default=Path(__file__).resolve().parents[1],
        help="repository root (defaults to the script's parent repository)",
    )
    parser.add_argument(
        "--check",
        choices=("all", "files", "format", "headers", "links", "licenses"),
        default="all",
        help="check set to run",
    )
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    """Run compliance checks and print actionable findings."""
    args = parse_args(argv)
    errors = run_checks(args.root.resolve(), args.check)
    if errors:
        for error in errors:
            print(f"compliance: error: {error}", file=sys.stderr)
        print(f"compliance: {len(errors)} error(s)", file=sys.stderr)
        return 1
    print(f"compliance: {args.check} checks passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
