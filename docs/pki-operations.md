# PKI Operations

Keep the root key offline. The coordinator online state contains only the
intermediate material required for enrollment and renewal. The offline backup
must be on separately controlled encrypted storage, mounted only for an
authorized ceremony.

## Initialize and distribute trust

Install the coordinator with `--no-start` before the first PKI ceremony. The
installer creates `/var/lib/exocomp-coordinator` for coordinator-owned durable
state. Do not pre-create the final
`/var/lib/exocomp-coordinator/pki` or `/secure/offline/exocomp-root`
directories: initialization creates both atomically and rejects an empty or
partial tree. Their parent directories must already exist and permit the
`exocomp-coordinator` service account to create the final directories.

Invoke the shipped coordinator release with a passphrase supplied through a
root-provisioned file that is readable only by the service account. Never put
the passphrase in an argument, shell variable assignment, transcript, or
service environment file:

```sh
sudo install \
  -o exocomp-coordinator \
  -g exocomp-coordinator \
  -m 0600 \
  /secure/input/root-passphrase \
  /run/exocomp-root-passphrase
sudo -u exocomp-coordinator \
  env EXOCOMP_ROOT_KEY_PASSPHRASE_FILE=/run/exocomp-root-passphrase \
  sh -c '
    cd /opt/exocomp/coordinator
    set -a
    . ./config/release-cookie.env
    set +a
    exec ./current/bin/exocomp_coordinator eval "$1"
  ' sh '
    passphrase =
      System.fetch_env!("EXOCOMP_ROOT_KEY_PASSPHRASE_FILE")
      |> File.read!()
      |> String.trim()
    case Exocomp.Coordinator.PKI.Bootstrap.initialize(
        online_state: "/var/lib/exocomp-coordinator/pki",
        offline_backup: "/secure/offline/exocomp-root",
        root_key_protection: {:passphrase, passphrase}
      ) do
      {:ok, metadata} ->
        IO.puts("disposition=#{metadata.disposition}")
        IO.puts("root_fingerprint=#{metadata.root_fingerprint}")
      {:error, error} ->
        IO.puts(:stderr, "PKI initialization failed: #{error.code}")
        System.halt(1)
    end
  '
sudo rm -f /run/exocomp-root-passphrase
```

Confirm that the temporary passphrase copy was removed and unmount the offline
backup. Record the returned root fingerprint in the change record. Distribute
it over an authenticated out-of-band channel and compare it character for
character at the node before enrollment. Never obtain both a certificate and
its trust fingerprint from the same unauthenticated channel.

Initialization is idempotent only when the online and offline trees are both
complete and agree. If either is missing, mismatched, too permissive, or cannot
decrypt, stop. Restore the matched pair from a verified backup; do not create a
new root under the old identity.

## Verify production readiness

Start the coordinator, then inspect health and the required production
processes through release RPC. The command reads the protected release cookie
without printing it:

```sh
sudo systemctl daemon-reload
sudo systemctl enable --now exocomp-coordinator.service
sudo bash -c '
  set -a
  . /opt/exocomp/coordinator/config/release-cookie.env
  set +a
  exec /opt/exocomp/coordinator/current/bin/exocomp_coordinator rpc "
    running = fn name ->
      case Process.whereis(name) do
        pid when is_pid(pid) -> Process.alive?(pid)
        _other -> false
      end
    end
    IO.inspect(%{
      health: Exocomp.Coordinator.Health.check(),
      listener: running.(Exocomp.Coordinator.Listener),
      pki: running.(Exocomp.Coordinator.PKI.State),
      enrollment: running.(Exocomp.Coordinator.EnrollmentToken)
    })
  "
'
```

A production candidate qualifies only when `health.status` is `:healthy` and
all three process values are `true`. Missing listener, PKI state, enrollment
token service, or audit must make health `:degraded`; a running systemd unit is
not sufficient. Do not issue a token while health is degraded.

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
sudo systemctl stop exocomp-coordinator.service
sudo /opt/exocomp/coordinator/current/bin/exocomp-state-backup create \
  --component coordinator \
  --output /secure/backups/exocomp-coordinator-state.tar.gz
sudo systemctl start exocomp-coordinator.service
```

The archive contains private material. Store it encrypted and separately from
its decryption credentials. Verify the adjacent SHA-256 file before restore.
The restore command refuses non-empty destinations unless `--force` is
explicit:

```sh
sudo /opt/exocomp/coordinator/current/bin/exocomp-state-backup restore \
  --component coordinator \
  --archive /secure/backups/exocomp-coordinator-state.tar.gz
```

After restore, validate ownership, key modes, fingerprint, CRL freshness,
inventory, audit continuity, and health before starting the service.
