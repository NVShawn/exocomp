# M6 release qualification: v0.1.0-rc.23

## Decision

**PASS — publication-ready.**

Both clean systemd guests passed all M6-CRIT criteria and documented live
scenarios using only artifacts built from the exact signed tag.

## Qualification identity

- **Tag:** `v0.1.0-rc.23`
- **Commit:** `902bee1a52bf037fdaab50bd0c71ba82fa51a8d6`
- **Architectures:** Linux amd64 (KVM) and Linux arm64 (full-system QEMU)
- **Qualification date:** 2026-07-27

The candidate preserves protected-state ownership during both backup/restore
and upgrade. Automatic rollback terminates the rejected BEAM directly with
SIGTERM, restores the prior link in a defined order, and waits for the restored
application health probe. It replaces rejected candidates v0.1.0-rc.3 through
v0.1.0-rc.22; none of their results are reused here.

The arm64 orchestration transcript records longer startup waits and a
600-second per-inference deadline for full-system CPU emulation. Both
orchestration values are included in the signed evidence. They do not alter
functional success requirements or M5 CPU/RAM ceilings. Release builds and
complete bundles were each built twice and compared before live qualification.

## M6 criteria

| Criterion | amd64 | arm64 | Evidence |
|---|---:|---:|---|
| M6-CRIT-1 | PASS | PASS | Governance, licenses, SBOM, and provenance gates |
| M6-CRIT-2 | PASS | PASS | Two byte-identical release builds and release matrix |
| M6-CRIT-3 | PASS | PASS | Strict no-network verification and offline installation |
| M6-CRIT-4 | PASS | PASS | Live systemd hardening, ownership, and exact privilege policy |
| M6-CRIT-5 | PASS | PASS | Shipped-artifact backup, restore, upgrade, and automatic rollback |
| M6-CRIT-6 | PASS | PASS | Default and system-cache purge uninstall preserve protected state |
| M6-CRIT-7 | PASS | PASS | Shipped guide commands for PKI, enrollment, renewal, approval, cleanup, and diagnostics |
| M6-CRIT-8 | PASS | PASS | Reproducible signed bundle and tamper-detecting metadata |
| M6-CRIT-9 | PASS | PASS | Indexed evidence and host identities recorded for both guests; authoritative full M5 passed |

## Evidence layout

- `raw/{amd64,arm64}/repo-gates/`: required Make gates.
- `raw/{amd64,arm64}/artifacts/`: reproducibility, checksums, signatures,
  licenses, SBOM, provenance, and runtime input identities.
- `raw/{amd64,arm64}/prelive/live/`: no-network verification, install,
  production PKI initialization, enrollment, and systemd startup.
- `raw/{amd64,arm64}/operational/`: renewal, multi-node diagnostics,
  approval/replay behavior, failed-service recovery, and hardening.
- `raw/{amd64,arm64}/bench-short/` and `bench/`: passing shipped M5 short
  and full-gate results. Sample streams are losslessly stored as
  `samples.jsonl.xz`.
- `raw/{amd64,arm64}/lifecycle/`: backup/restore, rollback, default
  uninstall, purge uninstall, and protected-state preservation.

## Evidence integrity

```sh
sha256sum -c evidence-index.sha256
ssh-keygen -Y verify \
  -f allowed-signers \
  -I shedwards@nvidia.com \
  -n exocomp-release-qualification \
  -s evidence-index.sha256.sig \
  < evidence-index.sha256
```
