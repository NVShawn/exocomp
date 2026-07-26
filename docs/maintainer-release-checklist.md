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
- [ ] Point `LLAMA_SERVER_<ARCH>` at the pinned executable and
      `LLAMA_LIB_DIR_<ARCH>` at its matching companion libraries. Bundle
      assembly must reject any non-baseline ELF dependency missing from that
      directory.

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
- [ ] Start both the extracted and installed `llama-server` launchers, then
      complete backup and restore with the installed `exocomp-state-backup`.
- [ ] Verify user-facing commands against the final artifacts.

## M5 performance gate

Run the full shipped-artifact performance qualification on clean amd64 and
arm64 guests independently. Both architecture runs must pass before
publication.

```sh
# On each qualification guest (amd64 and arm64):
make bench-llama-full \
  LLAMA_SERVER=/path/to/llama-server \
  LLAMA_LIB_DIR=/path/to/llama-libs \
  NODE_RELEASE=/opt/exocomp/node/current \
  COORD_RELEASE=/opt/exocomp/coordinator/current \
  MODEL_PATH=/path/to/model.gguf \
  MODEL_SHA256=<sha256>
```

- [ ] `bench-llama-full` exits zero on the clean amd64 qualification guest.
- [ ] `bench-llama-full` exits zero on the clean arm64 qualification guest.
- [ ] Evidence files from both runs are copied into
      `docs/release-evidence/<tag>/raw/amd64/bench/` and
      `docs/release-evidence/<tag>/raw/arm64/bench/` and included in the
      signed `evidence-index.sha256`.

For baseline management, gate failure interpretation, and evidence collection
details, see [Performance Qualification](performance-qualification.md).

## Publish and follow up

- [ ] Create and verify the signed tag from the qualified commit.
- [ ] Upload the exact qualified artifacts and metadata without rebuilding.
- [ ] Publish changelog, release notes, documentation, and any coordinated
      security advisory.
- [ ] Independently download and verify public artifacts.
- [ ] Record qualification evidence and announce support or rollback guidance.
