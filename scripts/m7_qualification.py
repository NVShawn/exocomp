#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
"""Validate frozen M7 inputs and write a deterministic per-architecture result."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
from pathlib import Path
from urllib.parse import urlsplit


ARCHITECTURES = ("amd64", "arm64")
SHA256 = re.compile(r"^[0-9a-f]{64}$")
IMAGE_DIGEST = re.compile(r"@sha256:([0-9a-f]{64})$")
CRITERIA = tuple(f"M7-CRIT-{number}" for number in range(1, 13))
REQUIRED_EVIDENCE = {
    "M7-CRIT-1": ("install/migration-image.json",),
    "M7-CRIT-2": ("security/security.json",),
    "M7-CRIT-3": ("two-cluster/two-cluster.json",),
    "M7-CRIT-4": ("scale/scale.json",),
    "M7-CRIT-5": ("two-cluster/two-cluster.json",),
    "M7-CRIT-6": ("two-cluster/two-cluster.json",),
    "M7-CRIT-7": ("two-cluster/two-cluster.json", "security/security.json"),
    "M7-CRIT-8": ("two-cluster/two-cluster.json",),
    "M7-CRIT-9": ("security/security.json",),
    "M7-CRIT-10": ("scale/scale.json",),
    "M7-CRIT-11": ("two-cluster/two-cluster.json",),
    "M7-CRIT-12": ("repo-gates/release-check.json", "docs/check-links.json"),
}
BASE_REQUIRED_EVIDENCE = frozenset(
    ("candidate/tag-verification.txt", "host/guest-runtime.txt", "artifacts/identity.json")
)
ALL_REQUIRED_EVIDENCE = frozenset(
    path for paths in REQUIRED_EVIDENCE.values() for path in paths
) | BASE_REQUIRED_EVIDENCE
SENSITIVE_CONFIG_KEY_MARKERS = (
    "password",
    "secret",
    "token",
    "cookie",
    "privatekey",
    "databaseurl",
    "authorization",
    "credential",
    "apikey",
    "accesskey",
    "signingkey",
    "webhookkey",
    "passphrase",
)


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for block in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def load_json(path: Path) -> dict[str, object]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise ValueError(f"invalid JSON evidence: {path}: {error}") from error
    if not isinstance(value, dict):
        raise ValueError(f"JSON evidence must be an object: {path}")
    return value


def require_string(value: object, description: str) -> str:
    if not isinstance(value, str) or not value:
        raise ValueError(f"{description} must be a non-empty string")
    return value


def require_mapping(value: object, description: str) -> dict[str, object]:
    if not isinstance(value, dict):
        raise ValueError(f"{description} must be an object")
    return value


def has_sensitive_marker(value: str) -> bool:
    normalized = "".join(character for character in value.lower() if character.isalnum())
    return any(marker in normalized for marker in SENSITIVE_CONFIG_KEY_MARKERS)


def image_digest(image: str, description: str) -> str:
    matched = IMAGE_DIGEST.search(image)
    if not matched:
        raise ValueError(f"{description} must end with a complete @sha256 digest")
    return matched.group(1)


def verify_release_manifest(
    manifest_path: Path,
    archive_path: Path,
    architecture: str,
    candidate_tag: str,
    candidate_commit: str,
    product: str,
) -> dict[str, object]:
    manifest = load_json(manifest_path)
    artifact = require_mapping(manifest.get("artifact"), f"{manifest_path} artifact")
    identity = require_mapping(manifest.get("identity"), f"{manifest_path} identity")
    expected_product = require_string(identity.get("product"), f"{manifest_path} identity product")
    if expected_product != product:
        raise ValueError(f"{manifest_path} product is {expected_product!r}, expected {product!r}")
    if identity.get("architecture") != architecture:
        raise ValueError(f"{manifest_path} architecture does not match {architecture}")
    if identity.get("source_tag") != candidate_tag:
        raise ValueError(f"{manifest_path} source tag does not match the signed candidate")
    if identity.get("source_commit") != candidate_commit:
        raise ValueError(f"{manifest_path} source commit does not match the signed candidate")
    expected_hash = require_string(artifact.get("sha256"), f"{manifest_path} artifact sha256")
    if not SHA256.fullmatch(expected_hash):
        raise ValueError(f"{manifest_path} has an invalid archive sha256")
    actual_hash = sha256_file(archive_path)
    if actual_hash != expected_hash:
        raise ValueError(f"{archive_path} sha256 does not match {manifest_path}")
    return {"archive": archive_path.name, "sha256": actual_hash, "manifest": manifest}


def verify_mission_control_manifest(
    manifest_path: Path,
    image: str,
    architecture: str,
    candidate_commit: str,
) -> dict[str, object]:
    manifest = load_json(manifest_path)
    artifact = require_mapping(manifest.get("artifact"), f"{manifest_path} artifact")
    identity = require_mapping(manifest.get("identity"), f"{manifest_path} identity")
    expected_digest = image_digest(image, "M7_MISSION_CONTROL_IMAGE")
    if artifact.get("type") != "oci-image":
        raise ValueError(f"{manifest_path} is not Mission Control OCI metadata")
    if artifact.get("architecture") != architecture:
        raise ValueError(f"{manifest_path} architecture does not match {architecture}")
    if artifact.get("digest") != f"sha256:{expected_digest}":
        raise ValueError(f"{manifest_path} digest does not match M7_MISSION_CONTROL_IMAGE")
    if identity.get("source_commit") != candidate_commit:
        raise ValueError(f"{manifest_path} source commit does not match the signed candidate")
    return {"image": image, "digest": f"sha256:{expected_digest}", "manifest": manifest}


def validate_overrides(
    path: Path | None, architecture: str, operator: str
) -> list[dict[str, object]]:
    if path is None:
        return []
    value = load_json(path)
    entries = value.get("overrides")
    if not isinstance(entries, list):
        raise ValueError("override record must contain an overrides list")
    permitted = {"endpoint", "port", "path", "orchestration_timeout"}
    result: list[dict[str, object]] = []
    for entry in entries:
        item = require_mapping(entry, "override entry")
        for key in ("name", "default", "effective", "timestamp", "reason", "diff"):
            require_string(item.get(key), f"override {key}")
        if any(
            has_sensitive_marker(item[key])
            for key in ("name", "default", "effective", "reason", "diff")
        ):
            raise ValueError("override evidence must not contain sensitive configuration")
        if item.get("architecture") != architecture:
            raise ValueError("override architecture does not match qualification architecture")
        if item.get("operator") != operator:
            raise ValueError("override operator does not match qualification operator")
        if item.get("scope") not in permitted:
            raise ValueError("override scope is not permitted for qualification")
        if item["scope"] == "endpoint":
            validate_service_url(item["default"])
            validate_service_url(item["effective"])
        if item.get("requirements_relaxed") is not False:
            raise ValueError("override must explicitly state requirements_relaxed=false")
        result.append(item)
    return result


def validate_redacted_config(path: Path) -> dict[str, object]:
    document = load_json(path)

    def validate(value: object, location: str = "") -> None:
        if isinstance(value, dict):
            for key, nested in value.items():
                if not isinstance(key, str):
                    raise ValueError("redacted configuration keys must be strings")
                nested_location = f"{location}.{key}" if location else key
                if has_sensitive_marker(key):
                    if nested != "[REDACTED]":
                        raise ValueError(f"redacted configuration exposes sensitive value at {nested_location}")
                else:
                    validate(nested, nested_location)
        elif isinstance(value, list):
            for index, nested in enumerate(value):
                validate(nested, f"{location}[{index}]")

    validate(document)
    return document


def validate_service_url(value: str) -> str:
    if any(character.isspace() for character in value):
        raise ValueError("M7_MC_SERVICE_URL must not contain whitespace")
    parsed = urlsplit(value)
    if parsed.scheme not in {"http", "https"} or not parsed.hostname:
        raise ValueError("M7_MC_SERVICE_URL must be an absolute HTTP(S) endpoint")
    if parsed.username is not None or parsed.password is not None:
        raise ValueError("M7_MC_SERVICE_URL must not contain credentials")
    if parsed.query or parsed.fragment:
        raise ValueError("M7_MC_SERVICE_URL must not contain a query or fragment")
    return value


def verify_inputs(args: argparse.Namespace) -> None:
    paths = (
        args.node_archive,
        args.node_manifest,
        args.coordinator_archive,
        args.coordinator_manifest,
        args.mission_control_manifest,
        args.model_path,
        args.redacted_config,
    )
    for path in paths:
        if not path.is_file():
            raise ValueError(f"required qualification input is missing: {path}")
    if args.architecture not in ARCHITECTURES:
        raise ValueError("architecture must be amd64 or arm64")
    if not re.fullmatch(r"[0-9a-f]{40,64}", args.candidate_commit):
        raise ValueError("candidate commit must be a full hexadecimal object ID")
    if not SHA256.fullmatch(args.model_sha256):
        raise ValueError("M7_MODEL_SHA256 must be a complete sha256")
    if sha256_file(args.model_path) != args.model_sha256:
        raise ValueError("M7_MODEL_PATH does not match M7_MODEL_SHA256")
    image_digest(args.postgres_image, "M7_POSTGRES_IMAGE")
    service_url = validate_service_url(args.mission_control_service_url)
    node = verify_release_manifest(
        args.node_manifest,
        args.node_archive,
        args.architecture,
        args.candidate_tag,
        args.candidate_commit,
        "exocomp_node",
    )
    coordinator = verify_release_manifest(
        args.coordinator_manifest,
        args.coordinator_archive,
        args.architecture,
        args.candidate_tag,
        args.candidate_commit,
        "exocomp_coordinator",
    )
    mission_control = verify_mission_control_manifest(
        args.mission_control_manifest,
        args.mission_control_image,
        args.architecture,
        args.candidate_commit,
    )
    overrides = validate_overrides(args.overrides_file, args.architecture, args.operator)
    redacted_config = validate_redacted_config(args.redacted_config)
    result = {
        "schema_version": 1,
        "candidate": {"tag": args.candidate_tag, "commit": args.candidate_commit},
        "architecture": args.architecture,
        "operator": args.operator,
        "artifacts": {"node": node, "coordinator": coordinator, "mission_control": mission_control},
        "postgres_image": args.postgres_image,
        "model": {"path": args.model_path.name, "sha256": args.model_sha256},
        "configuration": {
            "service_endpoint": service_url,
            "redacted_config_sha256": sha256_file(args.redacted_config),
            "effective": redacted_config,
        },
        "overrides": overrides,
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def write_result(args: argparse.Namespace) -> None:
    root = args.evidence_dir
    identity = load_json(root / "artifacts" / "identity.json")
    phase_records = {path for paths in REQUIRED_EVIDENCE.values() for path in paths}
    required = set(ALL_REQUIRED_EVIDENCE)
    missing = sorted(path for path in required if not (root / path).is_file())
    if missing:
        raise ValueError("qualification evidence is incomplete: " + ", ".join(missing))
    for relative in phase_records:
        status = load_json(root / relative).get("status")
        if status != "pass":
            raise ValueError(f"qualification phase did not pass: {relative}")
    candidate = require_mapping(identity.get("candidate"), "artifact identity candidate")
    if candidate.get("tag") != args.candidate_tag or candidate.get("commit") != args.candidate_commit:
        raise ValueError("artifact identity does not match candidate result")
    result = {
        "schema_version": 1,
        "candidate": {"tag": args.candidate_tag, "commit": args.candidate_commit},
        "architecture": args.architecture,
        "operator": args.operator,
        "decision": "pass",
        "tag_signature_verified": True,
        "criteria": {
            criterion: {"status": "pass", "evidence": list(REQUIRED_EVIDENCE[criterion])}
            for criterion in CRITERIA
        },
        "required_evidence": sorted(required),
    }
    (root / "qualification-result.json").write_text(
        json.dumps(result, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )


def parser() -> argparse.ArgumentParser:
    argument_parser = argparse.ArgumentParser()
    subcommands = argument_parser.add_subparsers(dest="command", required=True)
    verify = subcommands.add_parser("verify-inputs")
    verify.add_argument("--architecture", choices=ARCHITECTURES, required=True)
    verify.add_argument("--candidate-tag", required=True)
    verify.add_argument("--candidate-commit", required=True)
    verify.add_argument("--operator", required=True)
    verify.add_argument("--node-archive", type=Path, required=True)
    verify.add_argument("--node-manifest", type=Path, required=True)
    verify.add_argument("--coordinator-archive", type=Path, required=True)
    verify.add_argument("--coordinator-manifest", type=Path, required=True)
    verify.add_argument("--mission-control-image", required=True)
    verify.add_argument("--mission-control-manifest", type=Path, required=True)
    verify.add_argument("--postgres-image", required=True)
    verify.add_argument("--model-path", type=Path, required=True)
    verify.add_argument("--model-sha256", required=True)
    verify.add_argument("--mission-control-service-url", required=True)
    verify.add_argument("--redacted-config", type=Path, required=True)
    verify.add_argument("--overrides-file", type=Path)
    verify.add_argument("--output", type=Path, required=True)
    result = subcommands.add_parser("write-result")
    result.add_argument("--evidence-dir", type=Path, required=True)
    result.add_argument("--candidate-tag", required=True)
    result.add_argument("--candidate-commit", required=True)
    result.add_argument("--architecture", choices=ARCHITECTURES, required=True)
    result.add_argument("--operator", required=True)
    return argument_parser


def main() -> int:
    args = parser().parse_args()
    try:
        if args.command == "verify-inputs":
            verify_inputs(args)
        else:
            write_result(args)
    except ValueError as error:
        raise SystemExit(f"M7 qualification input error: {error}") from error
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
