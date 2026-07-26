# Policy and Operations

Exocomp policy is fail-closed. Diagnostic collection is read-only. A state
change must use a typed action, fresh target-bound evidence, deterministic
policy, durable audit-before-action, and the exact executor command.

## Service allow-lists and sudoers

Keep `actions.allow_list` in node configuration identical to the installer
allow-list. Each entry is an exact systemd unit name; wildcards and
caller-supplied commands are invalid. Re-run the installer to regenerate the
sudoers file and validate it:

```sh
sudo visudo -c -f /etc/sudoers.d/exocomp-node
sudo -l -U exocomp-node
```

An empty recovery allow-list must contain no `systemctl restart` privilege.
The only cleanup privilege is the installed, size-bounded journal vacuum
command. Never grant a shell, arbitrary path deletion, generic `systemctl`, or
wildcard arguments.

The node unit deliberately retains only `CAP_SETUID` and `CAP_SETGID` in its
capability bounding set and sets `NoNewPrivileges=false` so `/usr/bin/sudo` can
enter the exact root commands above. It grants no ambient capabilities. The
account-scoped `Defaults:exocomp-node !pam_session` avoids opening a PAM login
session from the systemd sandbox; sudo command authorization and auditing stay
enabled. Do not broaden the capability set or remove the argument-exact
sudoers entries.

## Approval

An already inactive/failed allow-listed service may restart once automatically
after a fresh check proves there is no live workload. Active or degraded
services require a signed, unexpired approval bound to task, action, target,
evidence, operator, and nonce. State drift, expiry, replay, audit failure, or
operator mismatch invalidates approval. Denial and timeout are terminal; gather
new evidence before creating another task.

When approving, record the expected disruption, evidence ID, exact service,
expiry, and rollback. If the service becomes failed while approval is pending,
discard the approval and start a new automatic-recovery episode. If it becomes
healthy, perform no action.

## Data classification and cleanup

User data is never an eligible deletion target, even with approval. Unknown
paths and caller-provided paths are protected as user data. Exocomp may remove
only recorded Exocomp-owned release files, or bounded system logs through the
fixed catalog action. A failed-service restart never performs cleanup.

Default uninstall preserves configuration, PKI, audit logs, consumed-execution
records, durable state, and every unrelated path. `--purge system-cache`
removes only Exocomp release cache. There is no purge category for user data.

## Inventory, diagnostics, and audit

Inventory updates must be atomic, schema-valid, and unique by node ID and
identity. A rejected replacement leaves the prior inventory active. Use
cluster health before diagnosis; partial and unreachable results remain
explicit rather than disappearing.

Audit must reconstruct observation, proposal, validation, approval state,
execution intent/result, verification, and terminal outcome under one
correlation ID. Retain audit at least as long as the organization's incident,
approval, and change-control retention requirement. Capacity alerts must fire
before the sink fills: an unavailable sink blocks future mutation.

Useful host evidence:

```sh
journalctl -u exocomp-node.service --since today --output json
systemctl show exocomp-node.service \
  --property ActiveState,SubState,NRestarts,ExecMainStatus
```

See [Coordinator restart recovery](coordinator-restart-recovery.md) for
inventory and audit reconstruction details.
