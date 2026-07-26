# Clean-Host Release Qualification

Qualification starts from a signed candidate tag and immutable artifacts on
fresh amd64 and arm64 systemd hosts or full-system virtual machines. Bare metal
is not required. A VM qualifies for its guest architecture when `uname -m`
reports the target architecture and all live scenarios execute inside that
guest. This includes an arm64 VM using QEMU CPU emulation on an amd64
hypervisor; container-only user-mode emulation is useful matrix evidence but
does not provide the systemd host lifecycle required here.

## Evidence record

Create a write-once directory containing the candidate tag/commit, host
architecture and OS, builder and clean-target digests, command transcript,
artifact checksums/signatures/manifests/SBOM/provenance/licenses, individual
M6-CRIT results, failures, and operator identity. Hash the completed evidence
index and sign that hash with the release qualification key.

For a VM, also record the hypervisor, guest machine and CPU model, whether the
CPU is virtualized or emulated, and the output of `uname -m`. Emulation must be
disclosed; it is acceptable evidence, not a reason to relabel the underlying
host hardware.

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

In an arm64 guest, replace `amd64` with `arm64`. Run the live matrix inside the
guest rather than merely launching an arm64 container on the amd64 host.

## M6-CRIT evidence

| Criterion | Required evidence |
|---|---|
| M6-CRIT-1 | Governance/license gate transcript and inventory |
| M6-CRIT-2 | Both architecture archives contain ERTS and start without system Erlang |
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

For the enrollment record, install the coordinator with `--no-start`, perform
the PKI ceremony, remove the passphrase input and offline-root mount, then
start it. Capture coordinator health and required-process presence without
capturing a plaintext token. Issue a short-lived token bound to the test node,
enroll once, and record only the token's redacted audit result. Prove that the
same token and a different node identity are rejected, that an untrusted root
cannot establish TLS, and that renewal succeeds only over the enrolled mTLS
identity. Restart both services and repeat the health and renewal checks;
hashes of the PKI state and consumed-token store must show durable recovery.
An unavailable audit sink must block issuance and enrollment and make
coordinator health degraded.

An M5 performance pass under CPU emulation is conservative and counts. A
performance-only failure under emulation is inconclusive: record it as such and
rerun that gate on an arm64-virtualized or bare-metal host. Functional, safety,
artifact, lifecycle, or reproducibility failures remain failures regardless of
the VM execution mode.

Publication is blocked by any missing architecture, skipped live scenario,
manifest mismatch, nondeterministic archive, embedded reusable cookie,
unverified command, or unsigned evidence record.
