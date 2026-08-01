# Ceph Cluster Profile Configuration

The Ceph cluster profile enables Exocomp coordinators to discover, query, and manage node state in Ceph storage clusters. This profile requires protected configuration for fixed binary paths, the Ceph configuration file, and read-only cluster credentials.

## Overview

A Ceph profile is a collection of Ceph integration settings compiled into an Exocomp release. The profile declares:

- A fixed absolute path to the Ceph command-line utility
- An absolute path to the `ceph.conf` configuration file
- An absolute path to the `client.exocomp` keyring file
- A supported profile version (currently `1`)

Profiles are release code, not configuration files. The registry only exposes modules compiled into the release, so a profile cannot be added via environment variables, local files, or caller-supplied commands. This fail-closed design prevents configuration injection and ensures every deployment uses audited integration code.

## Configuration Requirements

### File Paths Must Be Absolute

All paths in the Ceph profile configuration must be exact absolute paths. Relative paths, symbolic links that resolve to relative targets, and paths containing variable expansion are rejected during startup validation.

**Valid paths:**
```
/usr/bin/ceph
/etc/ceph/ceph.conf
/etc/ceph/ceph.client.exocomp.keyring
```

**Invalid paths (all rejected):**
```
~/ceph.conf                          (home directory expansion)
${CEPH_CONFIG}/ceph.conf             (variable expansion)
../config/ceph.conf                  (relative path)
/etc/ceph/link-to-ceph.conf          (symlink to relative target)
ceph                                 (relative binary path)
./etc/ceph/ceph.conf                 (relative path)
```

### Profile Version

The Ceph profile implementation specifies an exact version number. Configuration and coordinator behavior must match the implemented version. Requesting an unsupported version returns a structured coverage error and degrades profile coverage.

Current supported version: **1**

When deploying a new Exocomp release with an updated Ceph profile, verify that existing coordinator configurations specify the correct profile version.

## Startup Validation

During coordinator startup, the following validation is performed **without logging key material**:

1. **File Existence** — All three files must exist and be readable by the `exocomp-coordinator` service account.

2. **Executable Identity** — The Ceph binary must be a regular file (not a directory, device, or socket) and must have the execute bit set for the owner.

3. **Ownership** — All three files must be owned by a non-root account (typically `ceph`) or the `exocomp-coordinator` account itself. Files owned by `root` are permitted only if explicitly documented and justified.

4. **Keyring Permissions** — The keyring file must have mode `0600` (readable and writable by owner only). Mode `0640` is acceptable if the group is `exocomp-coordinator`. Modes `0644`, `0664`, or world-readable are rejected.

5. **Configuration File Permissions** — The `ceph.conf` file should have mode `0644` (world-readable). Restrictive modes (e.g., `0600` or `0640`) are permitted but are not required; validation succeeds for either.

If any validation check fails:

- The startup process does **not crash** or make unrelated monitoring unavailable.
- An actionable audit event is emitted with the specific validation failure.
- The Ceph profile coverage is **degraded** — the coordinator remains available but the Ceph profile features are unavailable.
- The audit entry records the failure reason without including key material, file content, or plaintext secrets.

Example validation failure audit entry (redacted):

```json
{
  "timestamp": "2026-02-15T10:23:45Z",
  "component": "cluster_profile",
  "event": "ceph_profile_validation_failed",
  "profile_id": "ceph",
  "profile_version": 1,
  "failure_code": "keyring_unsafe_permissions",
  "failure_reason": "ceph.client.exocomp.keyring has insecure mode 0644; expected 0600 or 0640",
  "keyring_path": "/etc/ceph/ceph.client.exocomp.keyring",
  "severity": "warning",
  "action_required": "Verify Ceph keyring permissions: chmod 0600 /etc/ceph/ceph.client.exocomp.keyring"
}
```

## Cephx Capabilities

The `client.exocomp` keyring must contain a Ceph user with read-only access to cluster and object storage daemon (OSD) state. The keyring is issued by a Ceph cluster administrator and defines the exact capabilities that Exocomp can exercise.

### Recommended Capabilities

Create the Ceph user with the following capabilities. Restrict capabilities to the minimum necessary for health monitoring and diagnostic collection:

```bash
ceph auth get-or-create client.exocomp \
  mon 'allow r' \
  mgr 'allow r' \
  osd 'allow r' \
  mds 'allow r'
```

**Capability breakdown:**

| Daemon | Capability | Purpose |
|--------|-----------|---------|
| **mon** | `allow r` | Read monitor state (cluster health, quorum status, version) |
| **mgr** | `allow r` | Read manager state (pool capacity, performance metrics, leader status) |
| **osd** | `allow r` | Read OSD state (disk usage, health, rebalancing progress) |
| **mds** | `allow r` | Read Metadata Server state (filesystem status, client connections) |

### What the Ceph Profile Does NOT Do

Exocomp's Ceph profile is **read-only**. It does **not**:

- Create, delete, or modify Ceph users or pools
- Execute remediation commands (e.g., `ceph osd out`, `ceph health mute`)
- Parse Ceph command output or infer state from raw data
- Modify `ceph.conf` or keyring files

State changes in Ceph are operator-driven through explicit approval workflows, not automated by Exocomp.

### Access Control

Store the keyring file securely:

```bash
install \
  -o ceph \
  -g ceph \
  -m 0600 \
  /path/to/ceph.client.exocomp.keyring \
  /etc/ceph/ceph.client.exocomp.keyring
```

The `exocomp-coordinator` process runs as the `exocomp-coordinator` service account. Ensure it can read the keyring:

```bash
# Option 1: Group-readable keyring
sudo chown ceph:exocomp-coordinator /etc/ceph/ceph.client.exocomp.keyring
sudo chmod 0640 /etc/ceph/ceph.client.exocomp.keyring

# Option 2: Coordinator copy
sudo install \
  -o exocomp-coordinator \
  -g exocomp-coordinator \
  -m 0600 \
  /etc/ceph/ceph.client.exocomp.keyring \
  /var/lib/exocomp-coordinator/ceph.keyring
```

Do not make the keyring world-readable. Do not include keyring content in logs, configurations, or audit trails.

## Configuration Example

Add Ceph profile configuration to the coordinator's `config.json` file or via environment variables. The following example shows a complete configuration:

```json
{
  "version": 1,
  "coordinator_id": "exocomp-coordinator",
  "cluster_profiles": {
    "ceph": {
      "enabled": true,
      "version": 1,
      "ceph_binary_path": "/usr/bin/ceph",
      "ceph_conf_path": "/etc/ceph/ceph.conf",
      "keyring_path": "/etc/ceph/ceph.client.exocomp.keyring"
    }
  },
  "tls": {
    "ca_cert": "/var/lib/exocomp-coordinator/pki/ca.crt",
    "coord_cert": "/var/lib/exocomp-coordinator/pki/coordinator.crt",
    "coord_key": "/var/lib/exocomp-coordinator/pki/coordinator.key"
  },
  "listen": {
    "host": "0.0.0.0",
    "port": 4443
  }
}
```

Alternatively, set environment variables to override configuration values:

| Environment Variable | Overrides |
|----------------------|-----------|
| `EXOCOMP_CEPH_BINARY_PATH` | `cluster_profiles.ceph.ceph_binary_path` |
| `EXOCOMP_CEPH_CONF_PATH` | `cluster_profiles.ceph.ceph_conf_path` |
| `EXOCOMP_CEPH_KEYRING_PATH` | `cluster_profiles.ceph.keyring_path` |

Example:

```bash
export EXOCOMP_CEPH_BINARY_PATH="/usr/bin/ceph"
export EXOCOMP_CEPH_CONF_PATH="/etc/ceph/ceph.conf"
export EXOCOMP_CEPH_KEYRING_PATH="/etc/ceph/ceph.client.exocomp.keyring"

systemctl restart exocomp-coordinator.service
```

## Validation Checklist

Before starting the coordinator with Ceph profile enabled, verify:

**Paths and Binaries:**
- [ ] Ceph binary exists and is executable: `test -x /usr/bin/ceph`
- [ ] `ceph.conf` exists and is readable: `test -r /etc/ceph/ceph.conf`
- [ ] Keyring exists and is readable: `test -r /etc/ceph/ceph.client.exocomp.keyring`

**Ownership:**
- [ ] Ceph binary owner is not `root` (or is explicitly trusted)
- [ ] `ceph.conf` owner is `ceph` or `exocomp-coordinator`
- [ ] Keyring owner is `ceph` or `exocomp-coordinator`

**Permissions:**
- [ ] Ceph binary has owner execute bit: `[[ -x /usr/bin/ceph ]]`
- [ ] Keyring mode is `0600` or `0640`: `stat -c %a /etc/ceph/ceph.client.exocomp.keyring`

**Connectivity:**
- [ ] Coordinator service account can read all files: `sudo -u exocomp-coordinator cat /etc/ceph/ceph.client.exocomp.keyring > /dev/null`
- [ ] Ceph cluster is reachable and credentials are valid: `sudo -u exocomp-coordinator /usr/bin/ceph -c /etc/ceph/ceph.conf --name client.exocomp status`

## Troubleshooting

### "ceph_profile_validation_failed" Audit Event

If validation fails during startup, check the audit log for the specific failure reason.

**Keyring permissions too open:**
```bash
sudo chmod 0600 /etc/ceph/ceph.client.exocomp.keyring
sudo systemctl restart exocomp-coordinator.service
```

**File ownership issue:**
```bash
# Verify current ownership
ls -la /usr/bin/ceph /etc/ceph/ceph.conf /etc/ceph/ceph.client.exocomp.keyring

# Grant group read access to keyring (if coordinator account is in ceph group)
sudo chown ceph:exocomp-coordinator /etc/ceph/ceph.client.exocomp.keyring
sudo chmod 0640 /etc/ceph/ceph.client.exocomp.keyring
```

**Path not absolute:**
```bash
# Check configuration for relative paths
grep -r "ceph_binary_path\|ceph_conf_path\|keyring_path" /opt/exocomp/coordinator/config/

# Update with absolute paths
# Then restart coordinator
sudo systemctl restart exocomp-coordinator.service
```

### "Ceph Profile Coverage Degraded"

If the Ceph profile is unavailable but the coordinator is still running, audit events and logs will show why. Diagnostics that rely on Ceph integration will return a coverage error instead of cluster state.

To restore coverage:

1. Review the audit event for the validation failure reason.
2. Correct the file path, ownership, or permissions.
3. Restart the coordinator: `sudo systemctl restart exocomp-coordinator.service`
4. Verify health: `sudo systemctl status exocomp-coordinator.service`

## See Also

- [PKI Operations](pki-operations.md) — Secure credential setup
- [Policy and Operations](policy-operations.md) — Approval and audit
- Ceph documentation: [Authentication and Authorization](https://docs.ceph.com/en/latest/rados/operations/authentication-n-authorization/)
