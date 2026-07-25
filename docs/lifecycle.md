# Upgrade, Backup, Rollback, and Removal

The installer keeps releases side by side. It validates the new archive,
architecture, peer major-version compatibility, existing configuration, and
staged entrypoint before changing `current`. It then starts the candidate and
requires both systemd-active state and application health. Failure atomically
restores the prior link and restarts the prior version.

The first release has no irreversible schema migration. Coordinator and node
major versions must match; minor versions may roll independently. Do not
upgrade across a major boundary until release notes define a mixed-version
window and reversible migration.

## Upgrade

Create and verify a protected-state backup first. Install the candidate with
the same component and allow-list:

```sh
sudo ./scripts/state-backup.sh create \
  --component node \
  --output /secure/backups/exocomp-node-pre-upgrade.tar.gz
sudo ./scripts/install.sh \
  --component node \
  --bundle ./exocomp-node-0.2.0-linux-amd64.tar.gz \
  --checksums ./checksums.sha256 \
  --version 0.2.0 \
  --allow-list exocomp-fixture.service \
  --non-interactive
```

`--no-start` stages an upgrade without changing an existing `current` link.
Do not call a staged version delivered until a normal health-gated install has
activated it.

If extraction is interrupted, no partial directory becomes current. If config
validation or health fails, the command exits nonzero and restores the prior
healthy version. Preserve the staged candidate and logs for diagnosis.

## Manual rollback

The automatic rollback is preferred. For an operator-directed rollback, verify
the prior directory and manifest, stop the service, replace `current` with a
temporary symlink plus rename, then start and health-check it. Do not copy old
configuration over new configuration and do not reissue node identities.
Consumed-execution state remains under `/var/lib`, preventing action replay.

## Backup and restore

`scripts/state-backup.sh` includes configuration and PKI, audit logs, and
durable state such as enrollment and consumed-execution records. It does not
include versioned binaries. Backups may contain secrets; keep mode `0600`,
encrypt at rest, separate keys, test restore periodically, and retain the
adjacent checksum.

Restore onto an empty destination by default. `--force` merges the verified
backup over existing Exocomp state but does not delete unknown files. After
restore, validate permissions, identity fingerprint, audit continuity,
inventory, and health before enabling traffic.

## Safe removal

Preview removal, then run it non-interactively:

```sh
sudo ./scripts/uninstall.sh --component node --dry-run
sudo ./scripts/uninstall.sh --component node --non-interactive
```

Default removal deletes the recorded unit, exact sudoers file, current link,
selected version directory, and its manifest. It preserves config, PKI, logs,
`/var/lib` state, and all unrelated/user paths. To remove old Exocomp-owned
release caches, name the sole supported purge category:

```sh
sudo ./scripts/uninstall.sh \
  --component node \
  --purge system-cache \
  --non-interactive
```

There is deliberately no user-data purge. Archive protected state before any
operator-directed deletion outside these tools.
