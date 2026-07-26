# M6 release qualification: v0.1.0-rc.2

## Decision

**FAIL — publication blocked.**

Candidate `v0.1.0-rc.2` resolves the signed annotated-tag packaging failure
found in `v0.1.0-rc.1`, and its OTP archives pass the release matrix on both
architectures. The complete release is not publication-ready: live
shipped-artifact qualification found functional, lifecycle, documentation,
licensing, and supply-chain failures.

The candidate is the SSH-signed tag at
`581128d6680ec921b140d97d5018139582a5dd66` and contains required main merge
`2085e44152f03ffd41f35cbfeee89a0da53b8bce`. The tag signer is
`shedwards@nvidia.com`, ED25519 fingerprint
`SHA256:0bWhwCA3OnB/mfvIjgfx1Gvyu7Gaki2rrWNf1BUD5Zw`.

## Hosts

| Guest | Execution | Guest result |
|---|---|---|
| Ubuntu 24.04 amd64, 8 vCPU, 8 GiB, systemd | KVM, host CPU passthrough | Repository and OTP release-matrix gates pass; complete shipped bundle fails live qualification |
| Ubuntu 24.04 arm64, 8 vCPU, 8 GiB, systemd | QEMU full-system CPU emulation, `cortex-a57`; `uname -m` reports `aarch64` | Release, packaging, installer, bundle, format, and lint gates pass; repository test and complete shipped bundle fail |

The arm64 performance-timing test failure is inconclusive under emulation. A
separate functional health-poller test failure and every shipped-artifact
failure remain failures, as required by the qualification policy.

## M6 criteria

| Criterion | amd64 | arm64 | Evidence and finding |
|---|---:|---:|---|
| M6-CRIT-1 | FAIL | FAIL | Repository governance checks pass, but the shipped `LICENSES/` directory has zero files and the bundle omits the required upstream license inventory. |
| M6-CRIT-2 | PASS | PASS | Both release matrices build byte-identical OTP archives with ERTS and start node and coordinator in clean containers without host Erlang. |
| M6-CRIT-3 | FAIL | FAIL | Network-disabled strict bundle verification passes, but the documented install paths do not exist, bundled `llama-server` lacks required shared libraries, and the installed node cannot start. |
| M6-CRIT-4 | PASS | PASS | Live installs create dedicated users, protected paths, exact sudoers entries, and hardened units. `systemd-analyze security` reports exposure 1.7 (`OK`) on the native amd64 guest; the directives and live inventory match on arm64. |
| M6-CRIT-5 | FAIL | FAIL | A healthy shipped node cannot be established for live upgrade rollback. The documented `state-backup.sh` is also absent from the bundle, so protected-state backup/restore cannot run from shipped artifacts. |
| M6-CRIT-6 | PASS | PASS | Default and `system-cache` purge uninstall remove the owned units, sudoers, links, and releases while protected-state hashes and an unrelated `/srv` sentinel remain unchanged. |
| M6-CRIT-7 | FAIL | FAIL | Published checksum/archive paths are wrong; the release explicitly lacks the token-issuance integration required for qualification; production coordinator startup has no listener, PKI state, or enrollment service. |
| M6-CRIT-8 | FAIL | FAIL | OTP archives are reproducible and have build identities, but identical complete-bundle assemblies differ. The signed manifest excludes the SBOM, provenance, and structured manifest; tampering those files still passes strict signature verification. Shipped third-party licenses are absent. |
| M6-CRIT-9 | FAIL | FAIL | Both host summaries are recorded, but unresolved functional and release-artifact failures block publication. |

## Required scenario outcome

| Scenario | Result | Reason |
|---|---:|---|
| Artifact verification and offline/no-network install | FAIL | Structural verification passes; documented commands and runtime payload fail |
| PKI initialization, enrollment, and renewal | FAIL | Production integration is not shipped or started |
| Multi-node diagnostics | FAIL | No qualified enrolled nodes can be brought up from the artifacts |
| M4 failed-service recovery | FAIL | The shipped node crashes before the live recovery scenario |
| M5 performance gate | FAIL | No shipped-artifact M5 Make gate or baseline exists; the short benchmark uses a fake server |
| Unit hardening and exact privilege policy | PASS | Live service/user/permission/sudoers inspection passes |
| Upgrade and automatic rollback | FAIL | No healthy shipped node baseline; fixture-only rollback is insufficient |
| Backup and restore | FAIL | Documented script is absent from the bundle |
| Default and purge uninstall | PASS | Protected and unrelated data remain unchanged |

## Principal failure evidence

- `raw/amd64/live/llama-server-version.log`: bundled runtime exits 127 because
  `libllama-server-impl.so` is absent.
- `raw/amd64/live/docs-command-results.txt`: both documented checksum and node
  install commands exit 1 because their paths are not in the extracted bundle.
- `raw/amd64/live/node-service-journal.txt`: the installed node crashes because
  it opens `/var/lib/exocomp/replay_ledger.dets`, while the installer creates
  `/var/lib/exocomp-node`.
- `raw/amd64/live/coordinator-runtime-processes.txt`: the production
  coordinator reports healthy while listener, PKI state, and enrollment
  processes are all `nil`.
- `raw/amd64/live/bundle-reproducibility.sha256`: two identical complete-bundle
  assemblies have different SHA-256 values.
- `raw/amd64/live/unsigned-metadata-tamper-verify.log`: strict verification
  succeeds after the structured manifest and provenance are changed.
- `raw/amd64/live/backup-create.log`: the documented backup command fails
  because `scripts/state-backup.sh` is not shipped.
- `raw/arm64/container-gates/test.log`: exact-candidate arm64 `make test`
  records the emulation-sensitive performance failure and an unwaived
  functional health-poller failure.

## Evidence integrity

`evidence-index.sha256` covers every evidence file in this directory except
itself and its detached signature. Verify it from this directory:

```sh
sha256sum -c evidence-index.sha256
ssh-keygen -Y verify \
  -f allowed-signers \
  -I shedwards@nvidia.com \
  -n exocomp-release-qualification \
  -s evidence-index.sha256.sig \
  < evidence-index.sha256
```

Raw multi-gigabyte model and release archives are intentionally not committed.
Their checksums, manifests, signatures, build identities, command transcripts,
and failure logs are retained here. The persistent qualification guests retain
the original archives under `/var/lib/exocomp-qualification/evidence`.
