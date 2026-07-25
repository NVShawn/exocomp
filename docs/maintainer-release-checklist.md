# Maintainer Release Checklist

Use this checklist for every public release. Evidence belongs in the release
record or CI system, not only in a local shell history.

## Prepare

- [ ] Confirm the milestone scope, supported platforms, version, and release
      commit.
- [ ] Start from a clean checkout and pinned builder images.
- [ ] Run `make release-check` and every application, installer, packaging,
      documentation, and qualification gate affected by the release.
- [ ] Resolve every `Unreleased` changelog entry and prepare release notes from
      the [template](release-notes-template.md).

## License and supply chain

- [ ] Verify every `mix.lock`, OTP, `llama.cpp`, model, optional backend, and
      vendored-library entry against `licenses/components.toml`.
- [ ] Confirm the exact pinned sources permit redistribution and no component
      uses an unapproved or unrecorded license.
- [ ] Include `LICENSE`, `NOTICE`, `THIRD_PARTY_NOTICES.md`, upstream notices,
      and the build-specific license inventory in every applicable artifact.
- [ ] Produce artifact manifests, SHA-256 checksums, signatures, SBOMs, and
      provenance from the final bits.
- [ ] Verify nested checksums and signatures before upload.

## Qualify

- [ ] Install complete bundles with networking disabled on clean amd64 and
      arm64 hosts.
- [ ] Exercise bootstrap, enrollment, diagnostics, controlled recovery,
      upgrade, rollback, and safe uninstall.
- [ ] Confirm systemd hardening, ownership, permissions, privilege policy, and
      protected-state retention.
- [ ] Verify user-facing commands against the final artifacts.

## Publish and follow up

- [ ] Create and verify the signed tag from the qualified commit.
- [ ] Upload the exact qualified artifacts and metadata without rebuilding.
- [ ] Publish changelog, release notes, documentation, and any coordinated
      security advisory.
- [ ] Independently download and verify public artifacts.
- [ ] Record qualification evidence and announce support or rollback guidance.
