# Installation and First Host

Exocomp supports glibc-based Linux with systemd on amd64 (`x86_64`) and arm64
(`aarch64`). Releases include ERTS; target hosts do not need Erlang, Elixir,
Mix, a compiler, or a package manager. The glibc and OpenSSL contract is listed
in [Runtime dependencies](runtime-dependencies.md).

Use a dedicated clean host or VM with at least 2 GiB free under `/opt`. The
default node model needs roughly 4 GiB RAM; allow 8 GiB when inference and a
large diagnostic workload overlap. Set `resources.inference.threads` no higher
than the CPUs allocated to the service. Model paths must refer to an
operator-verified GGUF file; the installer never downloads a model.

## Verify and install

Copy the release bundle and its adjacent `.sha256` file to the target. For an
offline install, transfer them on controlled media and disable network access
before verification. The following commands match the delivered archive layout:
verify the outer archive, extract its single top-level directory, verify the
nested manifest, confirm the bundled inference runtime loads, and install from
the embedded `releases/` directory:

```sh
sha256sum -c exocomp-complete-0.1.0-linux-amd64.tar.gz.sha256
tar -xzf exocomp-complete-0.1.0-linux-amd64.tar.gz
cd exocomp-complete-0.1.0-linux-amd64
./scripts/verify-bundle.sh --bundle-dir .
./llama-server --version
sudo ./scripts/install.sh \
  --component coordinator \
  --bundle ./releases/exocomp-coordinator-0.1.0-linux-amd64.tar.gz \
  --checksums ./manifest.sha256 \
  --version 0.1.0 \
  --no-start \
  --non-interactive
```

Use `--no-start` for the first coordinator install so the service cannot
accept traffic before its PKI ceremony. Initialize the PKI, verify the root
fingerprint, and start the coordinator by following
[PKI operations](pki-operations.md). A later upgrade should omit
`--no-start`; the installer then health-gates the candidate and rolls back on
failure.

Install a node with `--component node`. Supply an exact
comma-separated action allow-list only when recovery actions are intended:

```sh
sudo ./scripts/install.sh \
  --component node \
  --bundle ./releases/exocomp-node-0.1.0-linux-amd64.tar.gz \
  --checksums ./manifest.sha256 \
  --version 0.1.0 \
  --allow-list exocomp-fixture.service \
  --non-interactive
```

The installer validates architecture, checksum, disk, peer major-version
compatibility, and configuration before changing `current`. It installs
versions side by side and health-gates an upgrade. It also creates
`config/release-cookie.env` with a unique cryptographically random
`RELEASE_COOKIE`, mode `0600`. Published archives contain no reusable Erlang
cookie.

Configuration is under `/opt/exocomp/<component>/config`; logs are under the
adjacent `log` directory; durable state is under
`/var/lib/exocomp-<component>`. Replace template node identity, coordinator
address, TLS paths, model path, and resource values before production use.
Never make a key or cookie group/world-readable.

The node replay ledger is `/var/lib/exocomp-node/replay_ledger.dets`. Both the
installer and systemd assign `/var/lib/exocomp-node` to the `exocomp-node`
service account, and the service unit grants no other durable write path.
The installed inference launcher is
`/opt/exocomp/node/current/bin/llama-server`; it resolves only the companion
libraries shipped in `/opt/exocomp/node/current/lib/llama`.

## First-node sequence

1. Install the coordinator with `--no-start`, initialize its PKI, and verify
   production readiness as described in
   [PKI operations](pki-operations.md).
2. Distribute the root fingerprint over a separate authenticated channel.
3. Add the node ID/DNS identity to the coordinator inventory.
4. Issue a short-lived, node-bound, single-use enrollment token through the
   coordinator integration.
5. Install the node and submit its locally generated CSR. The private key must
   never leave the node.
6. Confirm certificate SAN, pinned root, node inventory status, and health.

The current release exposes enrollment domain APIs but no standalone
token-issuance command. An operator integration must call those APIs and retain
the audit result; do not pass enrollment tokens through shell history. Treat a
candidate without this integration as not qualified, rather than improvising
an unaudited certificate workflow.

## Diagnostics

Check systemd, then query the running release. The RPC command uses the
protected cookie environment without printing it:

```sh
systemctl status exocomp-node.service --no-pager
journalctl -u exocomp-node.service --since today --no-pager
sudo bash -c '
  set -a
  . /opt/exocomp/node/config/release-cookie.env
  set +a
  exec /opt/exocomp/node/current/bin/exocomp_node rpc \
    "IO.inspect(Process.whereis(Exocomp.Node.Listener))"
'
```

The result must be a PID, not `nil`. For a coordinator, use
`exocomp-coordinator.service` and call
`Exocomp.Coordinator.Health.check/0` through the coordinator release RPC.
If startup reports unsafe permissions, restore config to `0750`, the PKI
directory to `0700`, private files and the release cookie to `0600`, then
restart. Do not weaken identity validation to get a service running.

Continue with [Policy and operations](policy-operations.md) and
[Upgrade, backup, rollback, and removal](lifecycle.md).
