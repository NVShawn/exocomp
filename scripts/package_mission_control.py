#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
"""Emit deterministic OCI image release metadata for Mission Control."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import tomllib
from datetime import datetime, timezone
from pathlib import Path


HEX_LOCK_ENTRY = re.compile(r'^\s*"([a-zA-Z0-9_]+)":\s*\{:[a-zA-Z0-9_]+,\s*:[a-zA-Z0-9_]+,\s*"([^"]+)"')
SHA256 = re.compile(r"^sha256:[0-9a-f]{64}$")


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def write_json(path: Path, value: object) -> None:
    path.write_text(json.dumps(value, indent=2, sort_keys=True) + "\n")


def locked_dependencies(path: Path) -> dict[str, str]:
    dependencies: dict[str, str] = {}
    for line in path.read_text().splitlines():
        match = HEX_LOCK_ENTRY.match(line)
        if match:
            dependencies[match.group(1)] = match.group(2)
    return dependencies


def license_components(path: Path) -> dict[str, dict[str, object]]:
    document = tomllib.loads(path.read_text())
    components = {}
    for component in document.get("components", []):
        package = component.get("package")
        if package:
            components[str(package)] = component
    return components


def timestamp(epoch: int) -> str:
    return datetime.fromtimestamp(epoch, tz=timezone.utc).isoformat().replace("+00:00", "Z")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--image-ref", required=True)
    parser.add_argument("--image-digest", required=True)
    parser.add_argument("--version", required=True)
    parser.add_argument("--arch", choices=("amd64", "arm64"), required=True)
    parser.add_argument("--source-commit", required=True)
    parser.add_argument("--source-epoch", type=int, required=True)
    parser.add_argument("--builder-image", required=True)
    parser.add_argument("--containerfile", type=Path, required=True)
    parser.add_argument("--dependency-lock", type=Path, required=True)
    parser.add_argument("--license-registry", type=Path, required=True)
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument("--build-command", required=True)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if args.source_epoch < 0:
        raise SystemExit("source epoch must be non-negative")
    if not SHA256.fullmatch(args.image_digest):
        raise SystemExit("--image-digest must be a complete sha256 digest")
    if "@sha256:" not in args.builder_image or not SHA256.fullmatch(
        "sha256:" + args.builder_image.rsplit("@sha256:", 1)[-1]
    ):
        raise SystemExit("--builder-image must include a complete @sha256 digest")
    for path in (args.containerfile, args.dependency_lock, args.license_registry):
        if not path.is_file():
            raise SystemExit(f"required metadata input is missing: {path}")

    dependencies = locked_dependencies(args.dependency_lock)
    components = license_components(args.license_registry)
    missing = sorted(set(dependencies) - set(components))
    if missing:
        raise SystemExit(
            "license registry has no coverage for locked dependencies: "
            + ", ".join(missing)
        )

    args.output_dir.mkdir(parents=True, exist_ok=True)
    slug = f"mission-control-{args.version}-linux-{args.arch}"
    created = timestamp(args.source_epoch)
    lock_digest = sha256(args.dependency_lock)
    containerfile_digest = sha256(args.containerfile)

    covered = []
    for package in sorted(dependencies):
        component = components[package]
        covered.append(
            {
                "package": package,
                "version": dependencies[package],
                "license": component["license"],
                "scope": component["scope"],
                "notice_file": component["notice_file"],
            }
        )

    license_path = args.output_dir / f"{slug}.licenses.json"
    write_json(
        license_path,
        {
            "schema_version": 1,
            "project_license": "Apache-2.0",
            "registry": "licenses/components.toml",
            "dependency_lock_sha256": lock_digest,
            "covered_dependencies": covered,
            "uncovered_dependencies": [],
            "required_notice_files": ["LICENSE", "NOTICE", "THIRD_PARTY_NOTICES.md"],
        },
    )

    sbom_path = args.output_dir / f"{slug}.sbom.spdx.json"
    packages = [
        {
            "SPDXID": "SPDXRef-ExocompMissionControl",
            "name": "exocomp-mission-control",
            "versionInfo": args.version,
            "downloadLocation": "NOASSERTION",
            "licenseConcluded": "Apache-2.0",
            "licenseDeclared": "Apache-2.0",
        },
        {
            "SPDXID": "SPDXRef-ErlangOTP",
            "name": "Erlang/OTP",
            "versionInfo": "28.5.0.3",
            "downloadLocation": "NOASSERTION",
            "licenseConcluded": "Apache-2.0",
            "licenseDeclared": "Apache-2.0",
        },
    ]
    packages.extend(
        {
            "SPDXID": "SPDXRef-Hex-" + package.replace("_", "-"),
            "name": package,
            "versionInfo": dependencies[package],
            "downloadLocation": component.get("source_url", "NOASSERTION"),
            "licenseConcluded": component["license"],
            "licenseDeclared": component["license"],
        }
        for package, component in sorted(components.items())
        if package in dependencies
    )
    write_json(
        sbom_path,
        {
            "SPDXID": "SPDXRef-DOCUMENT",
            "spdxVersion": "SPDX-2.3",
            "creationInfo": {
                "created": created,
                "creators": ["Tool: exocomp-mission-control-packager/1"],
            },
            "name": slug,
            "documentNamespace": f"https://exocomp.invalid/sbom/{slug}",
            "dataLicense": "CC0-1.0",
            "packages": packages,
            "externalDocumentRefs": [],
            "image": {
                "reference": args.image_ref,
                "digest": args.image_digest,
                "architecture": args.arch,
            },
        },
    )

    provenance_path = args.output_dir / f"{slug}.provenance.json"
    write_json(
        provenance_path,
        {
            "_type": "https://in-toto.io/Statement/v1",
            "subject": [{"name": args.image_ref, "digest": {"sha256": args.image_digest[7:]}}],
            "predicateType": "https://slsa.dev/provenance/v1",
            "predicate": {
                "buildDefinition": {
                    "buildType": "https://exocomp.invalid/build/mission-control-oci/v1",
                    "externalParameters": {
                        "architecture": args.arch,
                        "version": args.version,
                        "build_command": args.build_command,
                    },
                    "internalParameters": {
                        "builder_image": args.builder_image,
                        "containerfile_sha256": containerfile_digest,
                        "dependency_lock_sha256": lock_digest,
                    },
                    "resolvedDependencies": [
                        {
                            "uri": "git+https://github.com/NVShawn/exocomp.git",
                            "digest": {"sha1": args.source_commit},
                        },
                        {
                            "uri": args.builder_image,
                            "digest": {"sha256": args.builder_image.rsplit("@sha256:", 1)[-1]},
                        },
                    ],
                },
                "runDetails": {
                    "builder": {"id": args.builder_image},
                    "metadata": {
                        "invocationId": f"{args.source_commit}-{args.arch}-{args.source_epoch}",
                        "startedOn": created,
                        "finishedOn": created,
                    },
                },
            },
        },
    )

    supply_chain = {
        "sbom": {
            "file": sbom_path.name,
            "sha256": sha256(sbom_path),
        },
        "provenance": {
            "file": provenance_path.name,
            "sha256": sha256(provenance_path),
        },
        "license_coverage": {
            "file": license_path.name,
            "sha256": sha256(license_path),
        },
    }
    metadata = {
        "schema_version": 1,
        "artifact": {
            "type": "oci-image",
            "reference": args.image_ref,
            "digest": args.image_digest,
            "architecture": args.arch,
        },
        "identity": {
            "version": args.version,
            "source_commit": args.source_commit,
            "source_epoch": args.source_epoch,
            "builder_image": args.builder_image,
            "containerfile_sha256": containerfile_digest,
            "dependency_lock_sha256": lock_digest,
            "build_command": args.build_command,
        },
        "runtime": {
            "user": "10001:10001",
            "read_only_rootfs": True,
            "writable_paths": [
                "/tmp (tmpfs)",
                "/var/lib/exocomp/mission-control",
                "/var/log/exocomp/mission-control",
            ],
            "commands": {
                "migrate": "bin/mission_control eval Exocomp.MissionControl.Release.migrate()",
                "server": "bin/mission_control start",
            },
        },
        "supply_chain": supply_chain,
    }
    manifest_path = args.output_dir / f"{slug}.manifest.json"
    write_json(manifest_path, metadata)

    checksum_path = args.output_dir / f"{slug}.sha256"
    checksum_path.write_text(
        "\n".join(
            f"{sha256(path)}  {path.name}"
            for path in (manifest_path, sbom_path, provenance_path, license_path)
        )
        + "\n"
    )
    print(manifest_path)
    print(sbom_path)
    print(provenance_path)
    print(license_path)
    print(checksum_path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
