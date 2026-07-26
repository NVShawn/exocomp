# Upgrade, Backup, Rollback, and Removal

The installer keeps releases side by side. It validates the new archive,
architecture, peer major-version compatibility, existing configuration, and
staged entrypoint before changing `current`. It then starts the candidate and
requires both systemd-active state and application health. Failure atomically
stops the rejected release, restores the prior link, clears systemd's failure
limit, and starts the prior version. The installer does not return until the
restored release passes both systemd and built-in application health checks.

The first release has no irreversible schema migration. Coordinator and node
major versions must match; minor versions may roll independently. Do not
upgrade across a major boundary until release notes define a mixed-version
window and reversible migration.

## Upgrade

Create and verify a protected-state backup first. Install the candidate with
the same component and allow-list:

```sh
sudo /opt/exocomp/node/current/bin/exocomp-state-backup create \
  --component node \
  --output /secure/backups/exocomp-node-pre-upgrade.tar.gz
sudo ./scripts/install.sh \
  --component node \
  --bundle ./releases/exocomp-node-0.2.0-linux-amd64.tar.gz \
  --checksums ./manifest.sha256 \
  --version 0.2.0 \
  --allow-list exocomp-fixture.service \
  --non-interactive
```

`--no-start` stages an upgrade without changing an existing `current` link.
Do not call a staged version delivered until a normal health-gated install has
activated it.

If extraction is interrupted, no partial directory becomes current. If config
validation or health fails, the command exits nonzero and restores the prior
healthy version. An `EXOCOMP_HEALTHCHECK_COMMAND` override may reject the
candidate, but automatic rollback always checks the restored release with the
shipped component-specific application probe. Preserve the staged candidate
and logs for diagnosis.

## Manual rollback

The automatic rollback is preferred. For an operator-directed rollback, verify
the prior directory and manifest, stop the service, replace `current` with a
temporary symlink plus rename, then start and health-check it. Do not copy old
configuration over new configuration and do not reissue node identities.
Consumed-execution state remains under `/var/lib`, preventing action replay.

## Backup and restore

The offline bundle ships `scripts/state-backup.sh`, and every installed release
exposes the same utility as
`/opt/exocomp/<component>/current/bin/exocomp-state-backup`.
It includes configuration and PKI, audit logs, and durable state such as
enrollment and consumed-execution records. It does not include versioned
binaries. Backups may contain secrets; keep mode `0600`, encrypt at rest,
separate keys, test restore periodically, and retain the adjacent checksum.

Restore onto an empty destination by default. `--force` merges the verified
backup over existing Exocomp state but does not delete unknown files. After
restore, validate permissions, identity fingerprint, audit continuity,
inventory, and health before enabling traffic.

Restore with the installed utility while the service is stopped:

```sh
sudo /opt/exocomp/node/current/bin/exocomp-state-backup restore \
  --component node \
  --archive /secure/backups/exocomp-node-pre-upgrade.tar.gz
```

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
