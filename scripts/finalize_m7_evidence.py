#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
"""Validate two M7 qualification runs and sign their deterministic evidence index."""

from __future__ import annotations

import hashlib
import json
import os
import re
import subprocess
from pathlib import Path

from m7_qualification import (
    ALL_REQUIRED_EVIDENCE,
    ARCHITECTURES,
    CRITERIA,
    REQUIRED_EVIDENCE,
    load_json,
    require_mapping,
    require_string,
)


COMMIT = re.compile(r"[0-9a-f]{40,64}")


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for block in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def require_env(name: str) -> str:
    value = os.environ.get(name, "")
    if not value:
        raise ValueError(f"{name} is required")
    return value


def reject_symbolic_links(root: Path) -> None:
    if root.is_symlink() or any(path.is_symlink() for path in root.rglob("*")):
        raise ValueError("M7 evidence does not permit symbolic links")


def validate_candidate(candidate: dict[str, object], description: str) -> None:
    require_string(candidate.get("tag"), f"{description} tag")
    commit = require_string(candidate.get("commit"), f"{description} commit")
    if not COMMIT.fullmatch(commit):
        raise ValueError(f"{description} commit must be a full hexadecimal object ID")


def validate_evidence_root(root: Path) -> dict[str, object]:
    reject_symbolic_links(root)
    candidates: list[dict[str, object]] = []
    architectures: dict[str, dict[str, object]] = {}
    criteria_index: dict[str, dict[str, object]] = {criterion: {} for criterion in CRITERIA}
    for architecture in ARCHITECTURES:
        result_path = root / "raw" / architecture / "qualification-result.json"
        result = load_json(result_path)
        if (
            result.get("architecture") != architecture
            or result.get("decision") != "pass"
            or result.get("tag_signature_verified") is not True
        ):
            raise ValueError(f"{result_path} is not a passing {architecture} result")
        candidate = require_mapping(result.get("candidate"), f"{result_path} candidate")
        validate_candidate(candidate, f"{result_path} candidate")
        require_string(result.get("operator"), f"{result_path} operator")
        criteria = require_mapping(result.get("criteria"), f"{result_path} criteria")
        if set(criteria) != set(CRITERIA):
            raise ValueError(f"{result_path} does not index every M7 criterion")
        for criterion in CRITERIA:
            value = require_mapping(criteria[criterion], f"{result_path} {criterion}")
            if value.get("status") != "pass":
                raise ValueError(f"{result_path} reports a non-passing {criterion}")
            if value.get("evidence") != list(REQUIRED_EVIDENCE[criterion]):
                raise ValueError(f"{result_path} has unexpected {criterion} evidence")
            criteria_index[criterion][architecture] = {
                "status": "pass",
                "evidence": list(REQUIRED_EVIDENCE[criterion]),
            }
        required = result.get("required_evidence")
        if not isinstance(required, list) or not required:
            raise ValueError(f"{result_path} has no required evidence list")
        if not all(isinstance(relative, str) for relative in required):
            raise ValueError(f"{result_path} has an unsafe evidence path")
        if len(required) != len(set(required)) or set(required) != ALL_REQUIRED_EVIDENCE:
            raise ValueError(f"{result_path} does not declare the complete M7 evidence set")
        architecture_root = result_path.parent
        for relative in required:
            if relative.startswith("/") or ".." in Path(relative).parts:
                raise ValueError(f"{result_path} has an unsafe evidence path")
            if not (architecture_root / relative).is_file():
                raise ValueError(f"{result_path} references missing evidence {relative}")
        for relative in {path for paths in REQUIRED_EVIDENCE.values() for path in paths}:
            if load_json(architecture_root / relative).get("status") != "pass":
                raise ValueError(f"{result_path} references a non-passing phase {relative}")
        candidates.append(candidate)
        architectures[architecture] = {"result": str(result_path.relative_to(root)), "operator": result.get("operator")}
    if candidates[0] != candidates[1]:
        raise ValueError("amd64 and arm64 evidence do not identify the same signed candidate")
    return {
        "schema_version": 1,
        "candidate": candidates[0],
        "decision": "pass",
        "architectures": architectures,
        "criteria": criteria_index,
    }


def write_index(root: Path) -> Path:
    index = root / "evidence-index.sha256"
    signature = root / "evidence-index.sha256.sig"
    reject_symbolic_links(root)
    files = sorted(
        path for path in root.rglob("*")
        if path.is_file() and path not in {index, signature}
    )
    lines = [f"{sha256_file(path)}  ./{path.relative_to(root).as_posix()}" for path in files]
    index.write_text("\n".join(lines) + "\n", encoding="utf-8")
    return index


def main() -> int:
    created: tuple[Path, ...] = ()
    try:
        root = Path(require_env("M7_EVIDENCE_ROOT"))
        signing_key = require_env("M7_EVIDENCE_SIGNING_KEY")
        signer = require_env("M7_QUALIFICATION_SIGNER")
        if not root.is_dir():
            raise ValueError(f"M7_EVIDENCE_ROOT does not exist: {root}")
        result_path = root / "qualification-results.json"
        index = root / "evidence-index.sha256"
        signature = root / "evidence-index.sha256.sig"
        if any(path.exists() for path in (result_path, index, signature)):
            raise ValueError("refusing to replace an existing M7 evidence result or index")
        allowed_signers = root / "allowed-signers"
        if not allowed_signers.is_file():
            raise ValueError("M7_EVIDENCE_ROOT must contain allowed-signers")
        result = validate_evidence_root(root)
        created = (result_path, index, signature)
        result_path.write_text(
            json.dumps(result, indent=2, sort_keys=True) + "\n", encoding="utf-8"
        )
        index = write_index(root)
        subprocess.run(
            ["ssh-keygen", "-Y", "sign", "-f", signing_key, "-n", "exocomp-release-qualification", str(index)],
            check=True,
        )
        subprocess.run(["sha256sum", "-c", str(index)], cwd=root, check=True)
        with index.open("rb") as source:
            subprocess.run(
                [
                    "ssh-keygen", "-Y", "verify", "-f", str(allowed_signers), "-I", signer,
                    "-n", "exocomp-release-qualification", "-s", str(index) + ".sig",
                ],
                stdin=source,
                check=True,
            )
    except (ValueError, subprocess.CalledProcessError) as error:
        for path in created:
            path.unlink(missing_ok=True)
        raise SystemExit(f"M7 evidence finalization failed: {error}") from error
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
