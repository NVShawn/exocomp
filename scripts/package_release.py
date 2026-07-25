#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
"""Create a normalized, secret-free OTP release archive and identity manifest."""

from __future__ import annotations

import argparse
import gzip
import hashlib
import io
import json
import os
import stat
import tarfile
from pathlib import Path


def sha256_bytes(content: bytes) -> str:
    return hashlib.sha256(content).hexdigest()


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def normalized_mode(path: Path) -> int:
    if path.is_dir():
        return 0o755
    if path.is_symlink():
        return 0o777
    return 0o755 if path.stat().st_mode & stat.S_IXUSR else 0o644


def payload_entries(release_dir: Path) -> list[Path]:
    entries = []
    for path in release_dir.rglob("*"):
        relative = path.relative_to(release_dir)
        if relative.as_posix() in {"releases/COOKIE", "build-identity.json"}:
            continue
        entries.append(path)
    return sorted(entries, key=lambda item: item.relative_to(release_dir).as_posix())


def inventory_entry(path: Path, relative: str) -> dict[str, object]:
    mode = normalized_mode(path)
    if path.is_symlink():
        target = os.readlink(path)
        return {
            "path": relative,
            "type": "symlink",
            "mode": f"{mode:04o}",
            "size": len(target.encode()),
            "sha256": sha256_bytes(target.encode()),
            "target": target,
        }
    if path.is_dir():
        return {"path": relative, "type": "directory", "mode": f"{mode:04o}", "size": 0}
    return {
        "path": relative,
        "type": "file",
        "mode": f"{mode:04o}",
        "size": path.stat().st_size,
        "sha256": sha256_file(path),
    }


def json_content(value: object) -> bytes:
    return (json.dumps(value, indent=2, sort_keys=True) + "\n").encode()


def identity(args: argparse.Namespace, release_dir: Path, entries: list[Path]) -> dict:
    erts_dirs = sorted(path.name for path in release_dir.glob("erts-*") if path.is_dir())
    if len(erts_dirs) != 1:
        raise ValueError(f"expected exactly one erts-* directory in {release_dir}")

    payload_inventory = [
        inventory_entry(path, path.relative_to(release_dir).as_posix()) for path in entries
    ]
    return {
        "schema_version": 1,
        "product": args.product,
        "version": args.version,
        "architecture": args.arch,
        "platform": f"linux-{args.arch}",
        "source_commit": args.source_commit,
        "source_tag": args.source_tag,
        "source_epoch": args.source_epoch,
        "builder_digest": args.builder_digest,
        "elixir_version": args.elixir_version,
        "otp_version": args.otp_version,
        "erts_version": erts_dirs[0].removeprefix("erts-"),
        "dependency_lock_sha256": sha256_file(args.dependency_lock),
        "build_command": args.build_command,
        "cookie_policy": {
            "embedded": False,
            "provisioning": "installer-generated RELEASE_COOKIE",
        },
        "payload_file_inventory": payload_inventory,
    }


def tar_info(name: str, mode: int, epoch: int, kind: bytes, size: int = 0) -> tarfile.TarInfo:
    info = tarfile.TarInfo(name)
    info.mode = mode
    info.mtime = epoch
    info.uid = 0
    info.gid = 0
    info.uname = "root"
    info.gname = "root"
    info.type = kind
    info.size = size
    return info


def create_archive(
    archive: Path,
    release_dir: Path,
    root_name: str,
    epoch: int,
    entries: list[Path],
    identity_bytes: bytes,
) -> list[dict[str, object]]:
    archive.parent.mkdir(parents=True, exist_ok=True)
    archive_inventory: list[dict[str, object]] = []

    with archive.open("wb") as raw:
        with gzip.GzipFile(filename="", mode="wb", fileobj=raw, mtime=epoch) as compressed:
            with tarfile.open(fileobj=compressed, mode="w", format=tarfile.GNU_FORMAT) as tar:
                tar.addfile(tar_info(root_name, 0o755, epoch, tarfile.DIRTYPE))

                for path in entries:
                    relative = path.relative_to(release_dir).as_posix()
                    archive_path = f"{root_name}/{relative}"
                    mode = normalized_mode(path)
                    item = inventory_entry(path, relative)
                    archive_inventory.append(item)

                    if path.is_symlink():
                        info = tar_info(archive_path, mode, epoch, tarfile.SYMTYPE)
                        info.linkname = os.readlink(path)
                        tar.addfile(info)
                    elif path.is_dir():
                        tar.addfile(tar_info(archive_path, mode, epoch, tarfile.DIRTYPE))
                    else:
                        info = tar_info(
                            archive_path, mode, epoch, tarfile.REGTYPE, path.stat().st_size
                        )
                        with path.open("rb") as source:
                            tar.addfile(info, source)

                identity_path = "build-identity.json"
                info = tar_info(
                    f"{root_name}/{identity_path}",
                    0o644,
                    epoch,
                    tarfile.REGTYPE,
                    len(identity_bytes),
                )
                tar.addfile(info, io.BytesIO(identity_bytes))
                archive_inventory.append(
                    {
                        "path": identity_path,
                        "type": "file",
                        "mode": "0644",
                        "size": len(identity_bytes),
                        "sha256": sha256_bytes(identity_bytes),
                    }
                )

    return sorted(archive_inventory, key=lambda item: str(item["path"]))


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--release-dir", type=Path, required=True)
    parser.add_argument("--product", required=True)
    parser.add_argument("--version", required=True)
    parser.add_argument("--arch", choices=("amd64", "arm64"), required=True)
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument("--source-commit", required=True)
    parser.add_argument("--source-tag", required=True)
    parser.add_argument("--source-epoch", type=int, required=True)
    parser.add_argument("--builder-digest", required=True)
    parser.add_argument("--elixir-version", required=True)
    parser.add_argument("--otp-version", required=True)
    parser.add_argument("--dependency-lock", type=Path, required=True)
    parser.add_argument("--build-command", required=True)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if not args.release_dir.is_dir():
        raise ValueError(f"release directory not found: {args.release_dir}")
    if args.source_epoch < 0:
        raise ValueError("source epoch must be non-negative")

    entries = payload_entries(args.release_dir)
    build_identity = identity(args, args.release_dir, entries)
    identity_bytes = json_content(build_identity)
    slug = args.product.replace("_", "-")
    base_name = f"{slug}-{args.version}-linux-{args.arch}"
    archive = args.output_dir / f"{base_name}.tar.gz"

    archive_inventory = create_archive(
        archive, args.release_dir, base_name, args.source_epoch, entries, identity_bytes
    )
    (args.release_dir / "build-identity.json").write_bytes(identity_bytes)

    manifest = {
        "schema_version": 1,
        "artifact": {
            "filename": archive.name,
            "size": archive.stat().st_size,
            "sha256": sha256_file(archive),
        },
        "identity": build_identity,
        "file_inventory": archive_inventory,
    }
    manifest_path = args.output_dir / f"{base_name}.manifest.json"
    manifest_path.write_bytes(json_content(manifest))
    print(f"{archive}  sha256:{manifest['artifact']['sha256']}")
    print(manifest_path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
