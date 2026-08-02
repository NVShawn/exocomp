# Service Management, Monitoring, and Ceph Integration

Exocomp describes desired services with inventory v2 and reports health to
Mission Control. This guide covers all three monitoring paths, optional Ceph
bootstrap, coverage diagnostics, and the boundary between monitoring and
recovery. It applies to installed coordinator and node releases; it does not
require a source checkout.

## Inventory v2 and monitoring paths

A desired-service record contains a node ID, exact systemd unit, sorted source
set, health depth, recovery authority, observation timestamp, optional profile
context, and bounded evidence references. Unknown fields, future versions,
conflicting identities, and unbounded evidence are rejected. Mission Control
treats duplicate event IDs as no-ops and does not derive authority from an event
label.

| Path | Source of desired state | Purpose | Recovery authority |
|---|---|---|---|
| Manual service list | Exact installed allow-list | Monitors named units and health checks. | Existing local allow-list policy. |
| Enabled-service discovery | Supported enabled units from installed inventory/profile | Reports current service state and coverage. | Observation only unless local policy independently authorizes action. |
| Ceph profile | Fixed, versioned Ceph topology | Collects Ceph daemon and cluster health. | Diagnostics do not authorize broad Ceph repair. |

Monitoring is not recovery. A monitoring record never grants a shell, wildcard
systemctl permission, arbitrary unit name, or broader sudoers rule. Mission
Control can display evidence and a proposal, but cluster-local policy
rechecks every action with fresh evidence.

## Manual service lists

Use exact systemd names and loopback application health checks in the installed
node configuration. Wildcards, path patterns, caller-supplied units, and
non-loopback health endpoints are invalid. The installer generates narrow
sudoers rules from the allow-list; adding a unit later requires a reviewed
policy update that regenerates the rules.

```sh
set -eu
sudo visudo -c -f /etc/sudoers.d/exocomp-node
sudo -l -U exocomp-node
systemctl status exocomp-node.service --no-pager
```

A systemd active state is not success: the application health check must pass.
Timeouts, connection errors, malformed responses, and stale evidence fail
closed.

## Enabled-service discovery

Enabled-service discovery reports configured topology; it does not silently
expand the recovery allow-list. Compare a service summary snapshot with
individual desired-state events before deciding coverage is complete. A missing
event, sequence gap, or conflicting source set is a coverage error, not a
restart instruction.

After an installed inventory configuration change, restart the coordinator in a
maintenance window and verify its audit record and next snapshot:

```sh
set -eu
sudo systemctl restart exocomp-coordinator.service
sudo systemctl status exocomp-coordinator.service --no-pager
sudo journalctl -u exocomp-coordinator.service --since -10m --no-pager
```

The coordinator reconnects to Mission Control after restart. Local node safety
boundaries remain in force while it is disconnected.

## Ceph credential bootstrap

The Ceph profile needs a fixed absolute ceph binary path, an absolute ceph.conf
path, and the client.exocomp keyring. On a Ceph administrator host create a
read-only identity, then distribute the keyring through the organization secret
mechanism. Never place a Ceph key in Git, inventory events, a webhook, or shell
history.

```sh
set -eu
ceph auth get-or-create client.exocomp \
  mon 'allow r' \
  mgr 'allow r' \
  osd 'allow r' \
  mds 'allow r'
```

Install the supplied keyring at its configured absolute path with the service
account as owner and mode 0600, or mode 0640 only when group access is
exocomp-coordinator. Verify readability without printing its contents:

```sh
set -eu
sudo install -d -o exocomp-coordinator -g exocomp-coordinator -m 0750 /etc/exocomp/ceph
sudo install -o exocomp-coordinator -g exocomp-coordinator -m 0600 \
  /secure/input/ceph.client.exocomp.keyring \
  /etc/exocomp/ceph/ceph.client.exocomp.keyring
sudo -u exocomp-coordinator test -r /etc/exocomp/ceph/ceph.client.exocomp.keyring
```

The profile is read-only by default. It collects health and daemon state but
does not create, delete, reweight, rebalance, or broadly repair Ceph resources.

## Profile coverage troubleshooting

Coverage is degraded, not bypassed, when a profile version is unsupported; a
required file is missing, relative, unsafe through a symlink, unreadable, or
overly permissive; the binary is not an executable regular file; credentials
fail; topology does not match; or a collector times out. The coordinator stays
available for unrelated work and emits an audit event without key material.

Check the configured paths and connection in order:

```sh
set -eu
test -x /usr/bin/ceph
test -f /etc/ceph/ceph.conf
test -f /etc/exocomp/ceph/ceph.client.exocomp.keyring
stat -c '%a %U %G %n' /etc/exocomp/ceph/ceph.client.exocomp.keyring
sudo -u exocomp-coordinator /usr/bin/ceph \
  -c /etc/ceph/ceph.conf --name client.exocomp status
```

Correct the path, ownership, mode, credential, network, or topology problem,
restart the coordinator once, then inspect the audit record and next
desired-service snapshot. Do not make the keyring world-readable, add write
caps to overcome a read failure, or treat unknown, stale, or unreachable as
healthy coverage.

## Safe restart and recovery authority

An already-failed, exact allow-listed service may restart automatically only
when fresh evidence proves no live workload and existing local policy allows
it. Active or degraded services require the approval flow. Immediately before
action, the coordinator recollects evidence and reevaluates local policy. A
Mission Control approval is not an execution credential and is never queued
for an offline cluster.

Ceph daemon recovery is a typed action with a per-daemon cooldown and
verification. It remains constrained by local policy and exact profile
topology. Never restart a monitor, OSD, manager, MDS, or gateway solely because
a dashboard shows degraded. Investigate quorum, replication, active clients,
and linked evidence first. Broad Ceph repair remains unavailable through
Exocomp.

When a restart is denied, retain its correlation ID, evidence timestamp, policy
decision, and audit record. Fix the reported condition or obtain a new approved
proposal. Do not bypass the helper, edit sudoers, or issue raw systemctl
commands as the Exocomp service account.
