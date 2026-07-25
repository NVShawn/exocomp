# PKI Operations

Keep the root key offline. The coordinator online state contains only the
intermediate material required for enrollment and renewal. The offline backup
must be on separately controlled encrypted storage, mounted only for an
authorized ceremony.

## Initialize and distribute trust

Before the first start, invoke the shipped coordinator release with a
passphrase supplied through a protected environment, never a command-line
argument:

```sh
sudo -u exocomp-coordinator \
  env EXOCOMP_ROOT_KEY_PASSPHRASE_FILE=/secure/input/root-passphrase \
  /opt/exocomp/coordinator/current/bin/exocomp_coordinator eval '
    passphrase =
      System.fetch_env!("EXOCOMP_ROOT_KEY_PASSPHRASE_FILE")
      |> File.read!()
      |> String.trim()
    result =
      Exocomp.Coordinator.PKI.Bootstrap.initialize(
        online_state: "/var/lib/exocomp-coordinator/pki",
        offline_backup: "/secure/offline/exocomp-root",
        root_key_protection: {:passphrase, passphrase}
      )
    IO.inspect(result)
  '
```

Record the returned root fingerprint in the change record. Distribute it over
an authenticated out-of-band channel and compare it character for character
at the node before enrollment. Never obtain both a certificate and its trust
fingerprint from the same unauthenticated channel.

Initialization is idempotent only when the online and offline trees are both
complete and agree. If either is missing, mismatched, too permissive, or cannot
decrypt, stop. Restore the matched pair from a verified backup; do not create a
new root under the old identity.

## Enrollment and renewal

Enrollment tokens are node-bound, single-use, short-lived, returned once, and
stored only as a digest. A node creates its key and CSR locally. Enrollment
must verify inventory membership, token binding, the pinned root, CSR SAN, and
the returned chain before atomically installing credentials.

Renewal uses the same local key ownership and authenticated coordinator path.
The scheduler renews before expiry and retries with bounded backoff; a failed
renewal retains the current valid identity. Alert before the remaining
validity reaches the maximum retry window. If the certificate expires, block
mutating work, issue a fresh enrollment token after operator verification, and
repeat enrollment.

## Revocation and rotation

For a compromised node:

1. Remove or disable its inventory authorization.
2. Revoke its leaf serial in the coordinator CRL and publish the updated CRL.
3. Confirm new mTLS sessions are rejected.
4. Preserve the audit trail and compromised material for incident handling.
5. Re-enroll only after rebuilding the node with a new local key.

Intermediate rotation is overlap-based: create the replacement under the
offline root, distribute a chain that trusts both intermediates, renew leaves,
verify the inventory has no old leaves, then retire the old intermediate. Root
rotation requires an out-of-band redistribution ceremony and cannot be made
transparent by the online coordinator.

The 0.1 release does not ship standalone revocation or CA-rotation commands.
Perform these steps only through a reviewed integration that updates the CRL,
state, and audit atomically. Absence of that integration is a qualification
failure, not permission to edit PKI files manually.

## Backup and recovery

Use the protected-state tool while the service is stopped or quiesced:

```sh
sudo ./scripts/state-backup.sh create \
  --component coordinator \
  --output /secure/backups/exocomp-coordinator-state.tar.gz
```

The archive contains private material. Store it encrypted and separately from
its decryption credentials. Verify the adjacent SHA-256 file before restore.
The restore command refuses non-empty destinations unless `--force` is
explicit:

```sh
sudo ./scripts/state-backup.sh restore \
  --component coordinator \
  --archive /secure/backups/exocomp-coordinator-state.tar.gz
```

After restore, validate ownership, key modes, fingerprint, CRL freshness,
inventory, audit continuity, and health before starting the service.
