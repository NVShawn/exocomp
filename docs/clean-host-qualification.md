# Clean-Host Release Qualification

Qualification starts from a signed candidate tag and immutable artifacts on
fresh amd64 and arm64 systemd hosts. Offline structural checks or emulation are
useful evidence but do not count as a native architecture pass.

## Evidence record

Create a write-once directory containing the candidate tag/commit, host
architecture and OS, builder and clean-target digests, command transcript,
artifact checksums/signatures/manifests/SBOM/provenance/licenses, individual
M6-CRIT results, failures, and operator identity. Hash the completed evidence
index and sign that hash with the release qualification key.

Run repository gates from the clean tagged checkout:

```sh
make fmt-check
make lint
make test
make test-installer
make test-bundle
make release-check
make build-amd64
make test-release-matrix ARCH=amd64 SKIP_BUILD=1
```

On a native arm64 host, replace `amd64` with `arm64`. Do not relabel an amd64
QEMU run as a live arm64 pass.

## M6-CRIT evidence

| Criterion | Required evidence |
|---|---|
| M6-CRIT-1 | Governance/license gate transcript and inventory |
| M6-CRIT-2 | Both native archives contain ERTS and start without system Erlang |
| M6-CRIT-3 | Network-disabled bundle verification and install on both hosts |
| M6-CRIT-4 | service user, unit hardening, permissions, and exact sudoers |
| M6-CRIT-5 | forced candidate-health failure, prior-version recovery, protected-state hashes |
| M6-CRIT-6 | default/purge uninstall inventory and unrelated user-data sentinel |
| M6-CRIT-7 | validated guide commands: first node, renewal failure, approval, cleanup, unsafe modes |
| M6-CRIT-8 | signatures, SBOM, provenance, licenses, build identity, double-build byte equality |
| M6-CRIT-9 | signed amd64 and arm64 host summaries with no unresolved failure |

The clean-host scenario must also initialize PKI, enroll and renew a node,
run multi-node diagnostics, recover the shipped failed fixture exactly once,
run M5 performance gates, exercise upgrade/automatic rollback/backup restore,
inspect hardening, and uninstall while protected-state/user-data hashes remain
unchanged.

Publication is blocked by any missing architecture, skipped live scenario,
manifest mismatch, nondeterministic archive, embedded reusable cookie,
unverified command, or unsigned evidence record.
