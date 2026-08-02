# Service Management, Monitoring, and Ceph Integration

Exocomp manages systemd services through deterministic policy and allow-lists, monitors configured services automatically, and optionally integrates with Ceph clusters to validate storage infrastructure. This guide covers service configuration, monitoring modes, Ceph profile activation, credential bootstrap, troubleshooting coverage errors, and safe restart behavior.

## Overview

Exocomp operates through two modes:

1. **Manual Service Lists** — operators explicitly specify which systemd services Exocomp may monitor and recover
2. **Automatic Enabled-Service Monitoring** — Exocomp automatically monitors services known to be running and active in its configured topology

Both modes enforce least-privilege policy: only explicitly allow-listed services may be recovered without approval, and active/degraded services require fresh operator approval before any restart.

## Manual Service Lists

### Configuration

Specify an explicit allow-list of systemd service units in the node configuration file (`config.json`):

```json
{
  "version": 1,
  "node_id": "node-01",
  "actions": {
    "allow_list": [
      "etcd.service",
      "kubelet.service",
      "containerd.service"
    ],
    "health_checks": {
      "etcd.service": "http://127.0.0.1:2379/health",
      "kubelet.service": "http://127.0.0.1:10248/healthz",
      "containerd.service": "http://127.0.0.1:1338/v1/version"
    }
  }
}
```

### Rules for Manual Service Lists

1. **Exact Unit Names** — service identifiers must be exact systemd unit names (e.g., `sshd.service`, `nginx.service`). Wildcards (`*`), path patterns, or caller-supplied service names are rejected.

2. **Installation Time Validation** — the installer validates the allow-list and generates exact sudoers entries for the named services:
   ```bash
   sudo ./scripts/install.sh \
     --component node \
     --bundle ./releases/exocomp-node-0.1.0-linux-amd64.tar.gz \
     --checksums ./manifest.sha256 \
     --version 0.1.0 \
     --allow-list etcd.service,kubelet.service,containerd.service \
     --non-interactive
   ```

3. **Health Checks Required** — every service in the allow-list must have an associated application-level health check endpoint. The node refuses recovery success when systemd reports `active` but the health check fails.

   - Health endpoints must be HTTP on `127.0.0.1`, `localhost`, or `::1` only.
   - Timeouts and connection errors are treated as health check failures (no retry).
   - Example health checks:
     ```bash
     curl http://127.0.0.1:2379/health
     curl http://127.0.0.1:10248/healthz
     curl http://127.0.0.1:8080/ping
     ```

4. **No Arbitrary Privileges** — the node runs unprivileged and receives only exact sudoers entries for the configured allow-list. No shell, generic `systemctl`, arbitrary paths, or wildcard arguments are permitted.

5. **Sudoers Validation** — after installation, verify the generated sudoers policy:
   ```bash
   sudo visudo -c -f /etc/sudoers.d/exocomp-node
   sudo -l -U exocomp-node
   ```

### Configuration Update and Reload

To change the allow-list after installation:

1. Update the configuration file manually under `/opt/exocomp/node/config/node.json`.
2. **Restart the node service** to reload configuration:
   ```bash
   sudo systemctl restart exocomp-node.service
   ```

The node does not dynamically reload configuration; a restart is required for changes to take effect.

**Note:** Changing the allow-list does not automatically regenerate sudoers rules. Contact the system administrator to update `/etc/sudoers.d/exocomp-node` if you add or remove services.

## Automatic Enabled-Service Monitoring

Exocomp automatically monitors services declared in the Ceph cluster profile without requiring an explicit allow-list addition.

### Ceph Profile Expected Services

When a Ceph profile is configured and active, Exocomp automatically monitors the following systemd units for health state:

- `ceph-mon@*` — Ceph monitor daemons
- `ceph-osd@*` — Ceph object storage daemons
- `ceph-mgr@*` — Ceph manager daemons
- `ceph-mds@*` — Ceph metadata server daemons
- `ceph-radosgw@*` — Ceph RADOS gateway daemons
- `ceph-crash` — Ceph crash dump collector

These services are monitored **for diagnostics only** unless explicitly added to the manual allow-list. The Ceph profile is read-only and does not support automatic restart of Ceph daemons without operator approval.

### Discovery and Diagnostics

Diagnostics for Ceph services are collected through the `exocomp.profile.inspect` skill:

```bash
# Request Ceph profile inspection from the coordinator
exocomp-coordinator admin cluster-diagnose --profile ceph
```

The Ceph collector:

1. Executes the Ceph command-line tool using the configured `client.exocomp` credentials.
2. Collects cluster health, OSD status, monitor quorum, replication status, and daemon state.
3. Returns structured health observations: `healthy`, `degraded`, `stale`, or `unreachable`.
4. Does not modify cluster state or create/delete resources.

### Health Reduction

Ceph observations are reduced to a single cluster health status:

| Status | Meaning |
|--------|---------|
| `healthy` | All monitored services are active and Ceph reports normal status |
| `degraded` | One or more services or Ceph components report reduced capacity or replication issues |
| `stale` | Ceph command execution timed out or returned incomplete results (possible service disruption) |
| `unreachable` | The Ceph cluster is not reachable or the node cannot authenticate (check credentials and network) |
| `unknown` | Ceph profile is not configured or profile validation failed (see Coverage Errors) |

## Ceph Profile Activation

### Prerequisites

Before activating the Ceph profile, ensure:

1. The Ceph cluster is operational and reachable from the node.
2. A `client.exocomp` Ceph user exists with read-only capabilities.
3. The Ceph binary, configuration file, and keyring are installed on the node.
4. Paths are absolute and do not use symlinks with relative targets.

### Profile Configuration

Add the Ceph profile configuration to the coordinator's `config.json`:

```json
{
  "cluster_profiles": {
    "ceph": {
      "enabled": true,
      "version": 1,
      "ceph_binary_path": "/usr/bin/ceph",
      "ceph_conf_path": "/etc/ceph/ceph.conf",
      "keyring_path": "/etc/ceph/ceph.client.exocomp.keyring"
    }
  }
}
```

Alternatively, use environment variables:

```bash
export EXOCOMP_CEPH_ENABLED=true
export EXOCOMP_CEPH_BINARY_PATH="/usr/bin/ceph"
export EXOCOMP_CEPH_CONF_PATH="/etc/ceph/ceph.conf"
export EXOCOMP_CEPH_KEYRING_PATH="/etc/ceph/ceph.client.exocomp.keyring"

sudo systemctl restart exocomp-coordinator.service
```

### Startup Validation

During coordinator startup, the Ceph profile is validated:

1. **File Existence** — all three files (binary, config, keyring) must exist and be readable.
2. **Executable Identity** — the Ceph binary must be a regular file with the execute bit set.
3. **Ownership** — files should be owned by non-root accounts (typically `ceph` or `exocomp-coordinator`).
4. **Keyring Permissions** — must be mode `0600` (or `0640` if group is `exocomp-coordinator`).
5. **Connectivity** — the coordinator attempts to authenticate with the Ceph cluster.

If validation fails, the Ceph profile coverage is **degraded** — the coordinator remains available but Ceph diagnostics are unavailable.

## Credential Bootstrap for Ceph

### Create the `client.exocomp` User

On a Ceph cluster administrator node, create a read-only Ceph user:

```bash
ceph auth get-or-create client.exocomp \
  mon 'allow r' \
  mgr 'allow r' \
  osd 'allow r' \
  mds 'allow r'

# Extract the keyring and distribute it securely
ceph auth get client.exocomp > /tmp/ceph.client.exocomp.keyring
```

### Least-Privilege Cephx Capabilities

The `client.exocomp` user must have **read-only access only**:

| Daemon | Capability | Purpose |
|--------|-----------|---------|
| **mon** | `allow r` | Read-only monitor access (cluster status, health, quorum) |
| **mgr** | `allow r` | Read-only manager access (performance metrics, capacity) |
| **osd** | `allow r` | Read-only object storage daemon access (disk usage, rebalancing) |
| **mds** | `allow r` | Read-only metadata server access (filesystem status) |

**Do not grant:**
- Write capabilities (`allow w`, `allow rwx`)
- Administrator capabilities (`allow *`, `allow admin`)
- Service-specific modifications (`osd blacklist`, `mds standby`)

### Install the Keyring on the Node

Transfer the keyring securely to the coordinator/node:

```bash
# Option 1: Group-readable keyring (if coordinator account is in ceph group)
sudo install \
  -o ceph \
  -g exocomp-coordinator \
  -m 0640 \
  /tmp/ceph.client.exocomp.keyring \
  /etc/ceph/ceph.client.exocomp.keyring

# Option 2: Coordinator-owned copy
sudo install \
  -o exocomp-coordinator \
  -g exocomp-coordinator \
  -m 0600 \
  /tmp/ceph.client.exocomp.keyring \
  /var/lib/exocomp-coordinator/ceph.keyring
```

### Verify Credential Access

Test that the coordinator can authenticate with Ceph:

```bash
# As the coordinator service account
sudo -u exocomp-coordinator /usr/bin/ceph \
  -c /etc/ceph/ceph.conf \
  --name client.exocomp \
  --keyring /etc/ceph/ceph.client.exocomp.keyring \
  status
```

Expected output:
```
  cluster:
    id:     xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
    health: HEALTH_OK
  ...
```

If authentication fails, verify:
- Keyring file exists and is readable by the coordinator account
- Keyring mode is `0600` or `0640` (not world-readable)
- Ceph cluster is reachable from the node
- Network connectivity and firewall rules allow Ceph monitor access

## Coverage Errors and Troubleshooting

Coverage errors occur when Exocomp cannot validate a profile or collect diagnostics. These are **not failures** — the coordinator remains operational and local diagnostics continue. However, profile-specific features become unavailable.

### Common Coverage Errors

#### 1. Ceph Profile Validation Failed

**Audit Event:**
```json
{
  "event": "cluster_profile_validation_failed",
  "profile_id": "ceph",
  "failure_code": "keyring_unsafe_permissions",
  "failure_reason": "ceph.client.exocomp.keyring has insecure mode 0644",
  "severity": "warning"
}
```

**Solutions:**

- **Keyring permissions too open:** Fix mode to `0600`:
  ```bash
  sudo chmod 0600 /etc/ceph/ceph.client.exocomp.keyring
  sudo systemctl restart exocomp-coordinator.service
  ```

- **Keyring file not found:** Ensure the keyring exists and is readable:
  ```bash
  test -r /etc/ceph/ceph.client.exocomp.keyring && echo "Found"
  ```

- **Ceph binary not found:** Check the binary path:
  ```bash
  test -x /usr/bin/ceph && echo "Executable"
  ```

- **Path not absolute:** Update configuration to use absolute paths:
  ```bash
  # Bad: ~/ceph.conf, ./config, $CEPH_CONFIG/ceph.conf
  # Good: /etc/ceph/ceph.conf, /usr/bin/ceph
  ```

#### 2. Ceph Cluster Unreachable

**Audit Event:**
```json
{
  "event": "ceph_profile_inspect_failed",
  "failure_code": "cluster_unreachable",
  "failure_reason": "Ceph cluster connection timeout or authentication failed"
}
```

**Solutions:**

- **Network connectivity:** Verify the node can reach Ceph monitors:
  ```bash
  ping ceph-monitor.example.internal
  telnet ceph-monitor.example.internal 6789
  ```

- **Credentials invalid:** Test authentication directly:
  ```bash
  sudo -u exocomp-coordinator /usr/bin/ceph \
    --keyring /etc/ceph/ceph.client.exocomp.keyring \
    --name client.exocomp \
    status
  ```

- **Firewall rules:** Ensure traffic to Ceph monitors (port 6789) and OSDs (6800-7300) is not blocked.

#### 3. Stale or Partial Observations

**Audit Event:**
```json
{
  "event": "ceph_profile_inspect_timeout",
  "failure_code": "collection_timeout",
  "failure_reason": "Ceph command execution exceeded 10000ms"
}
```

**Solutions:**

- **Cluster overload:** High Ceph activity can cause timeouts. Check cluster health and load.
- **Network latency:** Retry the diagnostic collection:
  ```bash
  exocomp-coordinator admin cluster-diagnose --profile ceph
  ```

#### 4. Unsupported Nodes and Topology Mismatches

**Error:** "Node not in Ceph topology" or "Coverage degraded — node not found in inventory"

**Cause:** The node is not listed in the coordinator's expected nodes or topology mismatch between configured inventory and actual cluster membership.

**Solutions:**

- **Verify inventory:** Check the coordinator's static inventory (typically under `/opt/exocomp-coordinator/config/inventory.json`):
  ```json
  {
    "nodes": [
      { "id": "node-01", "dns": "node-01.example.internal" },
      { "id": "node-02", "dns": "node-02.example.internal" }
    ]
  }
  ```

- **Update inventory:** Add the missing node and restart the coordinator:
  ```bash
  sudo systemctl restart exocomp-coordinator.service
  ```

- **Verify DNS:** Ensure node DNS names are resolvable:
  ```bash
  nslookup node-01.example.internal
  ```

#### 5. Helper Denial and Permission Errors

**Error:** "Helper denied" or "Insufficient privileges"

**Cause:** The `profile_action_helper` binary does not have proper permissions or sudoers rules.

**Solutions:**

- **Verify helper binary:** Check that the helper exists and has execute permissions:
  ```bash
  ls -la /usr/libexec/exocomp-profile-action-helper
  ```

- **Verify sudoers:** Check that exact sudoers rules exist:
  ```bash
  sudo visudo -c -f /etc/sudoers.d/exocomp-node
  ```

- **Reinstall:** If permissions are lost, reinstall with the correct allow-list:
  ```bash
  sudo ./scripts/install.sh \
    --component node \
    --bundle ./releases/exocomp-node-0.1.0-linux-amd64.tar.gz \
    --checksums ./manifest.sha256 \
    --version 0.1.0 \
    --allow-list ceph-osd@1.service \
    --non-interactive
  ```

#### 6. Stale Evidence

**Error:** "Evidence too old" or "Precondition changed since approval"

**Cause:** The evidence collected during decision-making became stale before execution (e.g., a service became healthy while approval was pending).

**Solutions:**

- **Retry diagnostics:** Collect fresh evidence:
  ```bash
  exocomp-coordinator admin cluster-diagnose
  ```

- **Resubmit task:** Create a new recovery task with fresh evidence:
  ```bash
  exocomp-coordinator admin task-create \
    --node node-01 \
    --action diagnose \
    --target service \
    --params '{"services": ["etcd.service"]}'
  ```

#### 7. Cooldown and Retry Limits

**Error:** "Service on cooldown" or "Retry limit exceeded"

**Cause:** The service was restarted recently or exceeded the maximum restart attempts without successful recovery.

**Solutions:**

- **Investigate failures:** Review audit logs to understand why the service keeps failing:
  ```bash
  journalctl -u exocomp-node.service --since "1 hour ago" --output json
  ```

- **Wait for cooldown:** Automatic recovery is blocked for a cooldown period after a failed restart (default 5-10 minutes). Manual approval-based recovery can bypass this.

- **Manual verification:** Log into the node and verify service state:
  ```bash
  systemctl status etcd.service
  journalctl -u etcd.service --since today
  ```

## Safe Restart Behavior

Exocomp enforces strict safety rules for service restarts. The policy is fail-closed: any doubt results in escalation to an operator rather than taking action.

### Automatic Restart (No Approval Required)

An **already failed** allow-listed service may be restarted automatically **once** if:

1. The service is in state `inactive` or `failed` (not `active` or `degraded`).
2. The service is on the explicit allow-list.
3. Fresh evidence proves **no live workload** is being interrupted.
4. The service is not on cooldown after a recent restart failure.
5. The restart attempt limit has not been exceeded for this episode.
6. The health check (if configured) passes after restart.

**Process:**

1. Coordinator diagnoses the failed service.
2. Node collects fresh evidence: systemd state, application health check, workload marker.
3. Policy engine determines: "Failed service + no live workload = automatic restart allowed".
4. Node audits the decision before execution.
5. Node invokes systemd restart via exact sudoers entry.
6. Node verifies systemd reports `active` and health check succeeds.
7. Node records successful recovery and end-to-end audit trail.

**Example:**

```
Failed service observed: etcd.service
├─ Collect fresh evidence (≤ 10 seconds old)
├─ Systemd state: inactive
├─ Health check GET http://127.0.0.1:2379/health: still failing
├─ Workload marker: HTTP port closed (no clients)
├─ Policy decision: "Automatic restart allowed"
├─ Audit event recorded: action_start
├─ Execute: systemctl restart etcd.service
├─ Verify: systemd reports active, health check succeeds
├─ Audit event recorded: action_completed
└─ Recovery successful
```

### Approval-Required Restart

An **active or degraded** service requires a signed, task-bound operator approval before restart:

1. The service is in state `active` or `degraded` (live workload running).
2. Policy engine determines: "Active service + risk of disruption = approval required".
3. Coordinator creates a task with the proposed action, evidence, risk assessment.
4. Operator reviews evidence, risk, and explicitly approves or denies the action.
5. Node verifies approval signature, bindings, and freshness.
6. On approval, node re-collects evidence and policy-checks again (state may have changed).
7. If preconditions changed (service became healthy), action is cancelled.
8. If preconditions hold, node executes and verifies.

**Approval Constraints:**

- **Single-use:** Each approval token can be used exactly once.
- **Expiry:** Approvals expire if not used within the configured window (default: 1 hour).
- **Binding:** The approval token binds to:
  - Task and correlation ID
  - Node identity
  - Service name
  - Evidence hash
  - Operator identity and timestamp

- **Precondition re-check:** Before execution, the node re-collects evidence and verifies that:
  - The service is still in the same health state
  - The underlying cause has not been fixed
  - No new conflicts have appeared

If preconditions changed, the approval is voided and the operator is notified to review the new evidence.

### Verification and Health Checks

After restart, Exocomp verifies both **systemd state** and **application health**:

1. **Systemd State:** `systemctl show <service> --property=ActiveState,SubState`
   - Must report: `active` and a healthy sub-state (e.g., `running`)
   - Rejects: `inactive`, `failed`, `restarting`, `dead`, etc.

2. **Application Health:** HTTP GET to the configured health endpoint
   - Must return HTTP 200-299
   - Timeouts and non-2xx responses are treated as failures
   - No retries on health check failure

3. **Stability Window:** The node waits for a configurable stability period (default: 30 seconds) and verifies the service remains healthy
   - If the service crashes during this window, verification fails
   - Service enters cooldown and escalates to operator

**Example health check failure:**

```
Restart completed: etcd.service
├─ Systemd state: active ✓
├─ Health check GET http://127.0.0.1:2379/health: timeout
└─ Verification FAILED → Cooldown + Escalation
```

### Cooldown and Retry Limits

After a failed restart or verification failure:

1. **Cooldown Period:** Automatic recovery is blocked for 5-10 minutes (configurable).
   - Purpose: Prevent restart loops and give the system time to stabilize
   - Manual approval-based recovery can override cooldown

2. **Retry Limit:** Only one automatic restart attempt per recovery episode.
   - If the first restart fails or verification fails, the issue escalates to the operator
   - The operator must gather new evidence and decide on next steps
   - No autonomous retry loop

3. **Escalation:** Failed recovery generates an incident with:
   - Complete audit trail
   - Collected evidence
   - Failure reason and diagnostics
   - Recommended operator next steps

**Example escalation:**

```
Recovery episode for etcd.service
├─ Attempt 1: Restart failed (service became inactive again)
├─ Verification failure recorded
├─ Cooldown activated (10 minutes)
├─ Escalation to operator: Investigation required
└─ Operator must review logs and resubmit with new evidence
```

### Policy Decision Logic

The node's policy engine applies this decision tree:

```
Service observation
├─ Is service allow-listed? NO → Abort (not eligible for recovery)
├─ Is service unhealthy (failed/degraded)? NO → No action needed
├─ Collect fresh evidence (≤ 10 seconds old)
├─ Is evidence recent and complete? NO → Escalate (incomplete data)
├─ Is service currently FAILED (inactive)? YES
│  ├─ Does no live workload marker exist? YES
│  └─ Is service not on cooldown? YES
│     ├─ Has restart not been attempted this episode? YES
│     └─ Approve automatic restart
├─ Is service currently ACTIVE or DEGRADED? YES
│  └─ Require operator approval
└─ Default: Escalate to operator
```

## Migration Guide: v1 to v2

### Configuration Schema Changes

If upgrading from an earlier Exocomp version, review configuration compatibility:

1. **Manual allow-lists:** Version 1 uses exact service names in `actions.allow_list`. No migration needed if you are already using the structured format.

2. **Health checks:** Version 1 requires explicit health check endpoints in `actions.health_checks`. Ensure all allow-listed services have a corresponding health check.

3. **Ceph profile:** If Ceph is used, ensure the profile is configured in the coordinator's `cluster_profiles.ceph` section (not a node-level setting).

### Testing After Upgrade

After upgrading:

1. **Verify configuration:**
   ```bash
   sudo systemctl status exocomp-node.service
   sudo systemctl status exocomp-coordinator.service
   ```

2. **Test manual allow-list:**
   ```bash
   exocomp-coordinator admin cluster-diagnose --services etcd.service
   ```

3. **Test Ceph profile (if configured):**
   ```bash
   exocomp-coordinator admin cluster-diagnose --profile ceph
   ```

4. **Test approval workflow:**
   ```bash
   # Create a task that requires approval
   exocomp-coordinator admin task-create \
     --node node-01 \
     --action recover \
     --service etcd.service \
     --require-approval
   ```

## See Also

- [Installation and First Host](installation.md) — Deployment and systemd hardening
- [Policy and Operations](policy-operations.md) — Approval and audit configuration
- [Ceph Profile Configuration](ceph-profile-configuration.md) — Ceph-specific setup and troubleshooting
- [Coordinator Restart Recovery](coordinator-restart-recovery.md) — Handling coordinator restarts
- [Upgrade, Backup, Rollback, and Removal](lifecycle.md) — Version management
