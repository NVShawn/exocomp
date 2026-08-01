# Mission Control Security Boundaries and Audit Events

This document describes the security boundaries of Mission Control and the audit events that are emitted when each boundary is enforced.

## Overview

Mission Control enforces multiple failed-closed security boundaries to ensure that:

1. **Every listed attack is rejected before mutation or execution**
2. **Security failures are bounded, correlated, and do not expose secrets**
3. **Comprehensive audit trails enable forensic analysis and compliance**

## Boundary Categories

### 1. Cross-Organization Isolation

**Threat Model**: An operator in organization A attempts to access, manipulate, or approve resources belonging to organization B.

**Boundary**: All authorization checks verify that the requesting operator's organization matches the target resource's organization before any other authorization check.

**Enforcement Points**:
- `Approvals.approve/4`: Authorization check in `authorize/2` verifies operator org against proposal org
- `Approvals.deny/4`: Same check as approve
- `OIDCResolver.resolve/4`: Organization parameter is never overridable by OIDC claims
- Database queries: All context functions scope through `organization_id` in WHERE clauses

**Audit Event**: `mission_control_operation_rejected`
```json
{
  "failure_reason": "cross_organization",
  "resource_org": "org-beta",
  "operator_org": "org-alpha",
  "operator_sub": "user-001",
  "resource_type": "proposal",
  "resource_id": "prop-123"
}
```

**Test Coverage**:
- `Exocomp.MissionControl.Security.ApprovalsSecurityTest`: "cross-organization isolation"
- `Exocomp.MissionControl.Security.OIDCSecurityTest`: "cross-organization tampering"
- `Exocomp.MissionControl.AuthorizationTest`: "cross-organization isolation"

---

### 2. OIDC Authentication Boundaries

**Threat Model**: An attacker forges, replays, or tampers with OIDC identity claims to assume unauthorized roles or access.

**Boundaries**:
- Required claims are present and non-empty
- Group claims only map to preconfigured roles; unknown groups are rejected
- Organization parameter cannot be overridden by claims
- Subject (sub) is immutably recorded from the OIDC provider
- Display name is extracted from configured claim or falls back to sub (never generated)

**Enforcement Points**:
- `OIDCResolver.resolve/4`: Validates all claim prerequisites before returning operator
- Group role mapping: Only groups in `group_role_map` are accepted; unmapped groups are ignored
- Subject override map (`subject_role_map`): Exists only for administrative delegation, cannot escalate beyond configured maximum

**Audit Event**: `oidc_resolution_failed`
```json
{
  "failure_reason": "no_role",
  "organization_id": "org-test",
  "sub": "user-unknown",
  "provided_groups": ["unmapped-group"],
  "configured_role_map": ["admin-group", "ops-group", "viewer-group"]
}
```

**Test Coverage**:
- `Exocomp.MissionControl.Security.OIDCSecurityTest`: "forged claims", "invalid subject", "role injection"
- `Exocomp.MissionControl.Auth.OIDCResolverTest`: All scenarios including missing claims, invalid subjects, group tampering

---

### 3. Cluster Certificate Validation

**Threat Model**: An attacker attempts to enroll a cluster with a revoked, expired, or forged certificate, or attempts to approve actions on a disconnected cluster.

**Boundaries**:
- Cluster certificates are issued by the Mission Control PKI (separate from node PKI)
- Certificate revocation is enforced: revoked serials cannot establish new sessions
- Certificate renewal is windowed: too-early or expired renewals are rejected
- Approvals are only allowed when the cluster is connected and reachable
- Each cluster can have only one active session at a time

**Enforcement Points**:
- `Coordinator.PKI.CertificateRegistry`: Tracks certificate serials, revocation, and renewal state
- `Approvals.approve/4`: Checks `connected_if_required/3` before enqueuing approval commands
- `SessionRegistry`: Validates cluster ownership before allowing command delivery

**Audit Event**: `cluster_certificate_rejected`
```json
{
  "failure_reason": "certificate_revoked",
  "cluster_id": "cluster-001",
  "certificate_serial": "serial-abc123",
  "organization_id": "org-alpha"
}
```

**Audit Event**: `approval_rejected_cluster_disconnected`
```json
{
  "failure_reason": "cluster_disconnected",
  "proposal_id": "prop-001",
  "cluster_id": "cluster-001",
  "operator_sub": "user-001",
  "organization_id": "org-alpha"
}
```

**Test Coverage**:
- `Exocomp.Coordinator.Security.EnrollmentTokenSecurityTest`: "node binding"
- `Exocomp.Coordinator.Integration.CoordinatorPKIRenewalTest`: Certificate validation
- `Exocomp.MissionControl.Security.ApprovalsSecurityTest`: "cluster disconnection"

---

### 4. Invitation Replay Prevention

**Threat Model**: An attacker captures a single-use enrollment token and replays it multiple times to enroll multiple nodes or re-enroll the same node after compromise.

**Boundary**: Each enrollment token can be consumed exactly once. Replayed consumption is rejected even across service restarts.

**Enforcement Points**:
- `EnrollmentToken.consume/3`: Atomically validates token format, binding, expiry, and consumed flag in a single database/registry transaction
- Persistent state: Consumed tokens are marked durably; state survives process and host restarts
- Constant-time comparison: Invalid and replayed tokens return the same error code to prevent timing-based oracles

**Audit Event**: `enrollment_token_consumed`
```json
{
  "result": "ok",
  "node_id": "node-001",
  "correlation_id": "corr-abc123"
}
```

**Audit Event**: `enrollment_token_consume_failed`
```json
{
  "result": "token_already_consumed",
  "node_id": "node-001",
  "correlation_id": "corr-abc123"
}
```

**Test Coverage**:
- `Exocomp.Coordinator.Security.EnrollmentTokenSecurityTest`: "single-use", "expiry", "format validation"
- `Exocomp.Coordinator.Integration.CoordinatorPKIRenewalTest`: Enrollment flow with token replay

---

### 5. Proposal Identity Boundaries

**Threat Model**: An attacker attempts to override proposal identity fields (cluster, node, target, organization) via malicious payload, or attempts to approve a proposal belonging to a different organization.

**Boundary**: All proposal identity fields are immutable from the perspective of the approval decision. Organization, cluster, node, and target are validated against the persisted proposal before mutation.

**Enforcement Points**:
- `Approvals.approve/4`: Organization scoping check validates proposal org before proceeding
- Proposal locking: Proposals are locked with `FOR UPDATE` before any state changes
- Transactional isolation: The entire approve/deny transaction rolls back if any validation fails

**Audit Event**: `proposal_decision_recorded`
```json
{
  "proposal_id": "prop-001",
  "decision": "approved",
  "organization_id": "org-alpha",
  "cluster_id": "cluster-001",
  "node_id": "node-001",
  "target_id": "target-001",
  "decided_by_sub": "user-001",
  "decided_by_organization_id": "org-alpha",
  "decided_at": "2026-08-01T00:00:00Z"
}
```

**Test Coverage**:
- `Exocomp.MissionControl.Security.ApprovalsSecurityTest`: "organization mismatch", "audit attribution"

---

### 6. Arbitrary Actions/Paths Prevention

**Threat Model**: An attacker attempts to execute arbitrary actions, shell commands, or paths through a malicious proposal payload.

**Boundary**: Only typed, policy-validated actions are accepted. Action IDs must match a preconfigured catalog. No arbitrary paths or command injection is possible.

**Enforcement Points**:
- `Approvals.approve/4`: Payload contains only immutable action ID, parameters, and metadata
- Command generation: The approval command contains only typed fields, no shell strings or paths
- Node-side policy: The coordinator re-validates the action and evidence locally before execution (separate from Mission Control)

**Note**: This boundary spans from Mission Control through the coordinator to the node. Mission Control's role is to reject approvals for unknown action IDs and to re-validate proposals.

**Audit Event**: `action_execution_initiated`
```json
{
  "action_id": "service.restart",
  "node_id": "node-001",
  "parameters": {"service": "exocomp-coordinator"},
  "proposal_id": "prop-001",
  "authorized_by_sub": "user-001"
}
```

**Test Coverage**:
- `Exocomp.MissionControl.Security.ApprovalsSecurityTest`: "audit attribution"
- Integration tests verify end-to-end action validation

---

### 7. Approval Freshness and Replay Prevention

**Threat Model**: An attacker captures a signed approval and replays it to execute an action multiple times, or approves a proposal after evidence has become stale.

**Boundaries**:
- Proposals have an expiry timestamp; approvals cannot be issued for expired proposals
- Proposals have evidence freshness guarantees; approvals cannot be issued if evidence is stale
- Each approval generates a unique command ID; duplicate command IDs are idempotent on the cluster side
- Approval tokens are short-lived and cannot be re-used

**Enforcement Points**:
- `Approvals.approve/4`: Checks `ensure_decidable/2` to verify proposal is not expired and evidence is fresh
- Command generation: Each approval creates exactly one command in the outbox with a unique command ID
- Cluster side: Commands are acknowledged by cluster sequence number; duplicate commands are idempotent

**Audit Event**: `proposal_approval_rejected_expired`
```json
{
  "proposal_id": "prop-001",
  "failure_reason": "proposal_expired",
  "expires_at": "2026-07-31T23:00:00Z",
  "attempt_time": "2026-08-01T00:00:00Z"
}
```

**Audit Event**: `proposal_approval_rejected_evidence_stale`
```json
{
  "proposal_id": "prop-001",
  "failure_reason": "evidence_stale",
  "evidence_fresh_until": "2026-07-31T23:00:00Z",
  "attempt_time": "2026-08-01T00:00:00Z"
}
```

**Test Coverage**:
- `Exocomp.MissionControl.Security.ApprovalsSecurityTest`: "stale/expired approvals", "terminal proposal state"
- Coordinator-side tests verify idempotency and command deduplication

---

### 8. Webhook Signature Verification

**Threat Model**: An attacker sends a forged webhook event claiming to be from Mission Control, or an attacker intercepts a webhook and modifies its body without re-signing.

**Boundaries**:
- Each webhook endpoint is configured with a shared secret (never transmitted)
- Payloads are signed with HMAC-SHA256(secret, event_id + timestamp + body)
- Consumers must verify the signature using their copy of the secret
- Timestamps are included in the signature and must fall within the consumer's acceptable replay window (typically 5-15 minutes)
- Each event ID is unique; consumers use event ID for idempotency

**Enforcement Points**:
- `MissionControl.Webhooks.Signer`: Generates signatures using HMAC-SHA256
- Webhook delivery: Signatures are computed before transmission
- Consumer-side: Verification is consumer's responsibility (documented in operational guide)

**Webhook Signature Format**:
```
X-MC-Signature: sha256=<base64-encoded-hmac>
X-MC-Event-ID: evt-001
X-MC-Timestamp: 2026-08-01T00:00:00Z
```

**Payload (never modified after signing)**:
```json
{
  "event_id": "evt-001",
  "event_type": "proposal.approved",
  "timestamp": "2026-08-01T00:00:00Z",
  "organization_id": "org-alpha",
  "data": {
    "proposal_id": "prop-001",
    "cluster_id": "cluster-001",
    "decision": "approved"
  }
}
```

**Test Coverage**:
- `Exocomp.MissionControl.Webhooks.SignerTest`: Signature generation and verification (consumer-side testing)

---

### 9. Secret and Redaction Boundaries

**Threat Model**: An attacker extracts secrets, credentials, or private keys from logs, audit trails, or crash reports.

**Boundaries**:
- OIDC client credentials and deployment keys come from the runtime secret store (not checked into source)
- Webhook signing secrets are encrypted at rest and shown only once at creation time
- Tokens (enrollment, approval) are never logged or stored in plaintext; only digests are persisted
- Audit events redact sensitive fields: only safe metadata (sub, org, IDs, timestamps) is emitted
- Error messages use generic error codes (e.g., "token not found") for timing-resistant rejection

**Enforcement Points**:
- `EnrollmentToken.redact_state/1`: Strips digests from GenServer state snapshots
- `Approvals.actor_audit/3`: Constructs audit records with immutable, non-secret fields only
- `Logger` configuration: Redaction filters remove secrets from all log output
- Webhook secrets: Stored encrypted with application master key

**Redacted Fields**:
- Token plaintext and digests
- OIDC client credentials
- Webhook secrets
- Private key material (never in audit)
- Raw log data and arbitrary file contents

**Non-Redacted Fields** (safe in audit):
- Operator stable identity (sub, display_name, organization_id)
- Resource IDs (proposal_id, cluster_id, node_id, task_id)
- Action IDs and parameter keys (not sensitive values, unless application-specific)
- Timestamps and sequence numbers
- Failure codes and reason enums

**Test Coverage**:
- `Exocomp.Coordinator.Security.EnrollmentTokenSecurityTest`: "redaction"
- `Exocomp.MissionControl.Security.ApprovalsSecurityTest`: "audit attribution"

---

### 10. Role-Based Access Control (RBAC)

**Threat Model**: A viewer attempts to approve actions, an operator attempts to configure OIDC, or a non-existent role is injected via claims.

**Boundaries**:
- Viewer: read-only access to fleet, incidents, conversations, and audit trails
- Operator: viewer access + acknowledge/assign/snooze/chat/approve/deny/resolve
- Admin: operator access + cluster enrollment/revocation, OIDC rolemapping, retention, webhook administration

**Enforcement Points**:
- `Authorization.authorize/3`: Enforces role matrix for each action
- Plug middleware: All HTTP endpoints use `require_role/2` plug
- LiveView: All view updates check role before rendering

**Audit Event**: `authorization_failed_insufficient_role`
```json
{
  "operator_sub": "user-001",
  "operator_role": "viewer",
  "required_role": "operator",
  "action": "approve",
  "resource_type": "proposal"
}
```

**Test Coverage**:
- `Exocomp.MissionControl.Security.ApprovalsSecurityTest`: "insufficient role rejection"
- `Exocomp.MissionControl.AuthorizationTest`: Full role matrix testing

---

## Audit Event Format and Schema

All audit events follow a common structure:

```json
{
  "event_type": "string",
  "timestamp": "ISO8601",
  "organization_id": "string",
  "operator_sub": "string (if applicable)",
  "correlation_id": "string",
  "resource_type": "string",
  "resource_id": "string",
  "failure_reason": "string (if applicable)",
  "metadata": {}
}
```

**Retention**: Audit events are retained for one year (configurable per organization).

---

## Quality Gates and Verification

### Make Targets

All security boundaries are verified by:

```bash
make security  # Run all security tests
make compliance-check  # Governance and license checks
make fmt-check  # Code formatting
make lint  # Static analysis
```

### Test Coverage

Security tests are located in:
- `apps/exocomp_mission_control/test/exocomp/mission_control/security/`
- `apps/exocomp_coordinator/test/exocomp/coordinator/security/`

Each test module explicitly names the boundary it tests and includes both positive (should succeed) and negative (should fail) cases.

---

## Release Checklist

Before releasing Mission Control, verify:

- [ ] All security tests pass (`make security`)
- [ ] All compliance checks pass (`make compliance-check`)
- [ ] All code is formatted (`make fmt-check`)
- [ ] All linters pass (`make lint`)
- [ ] Audit trails are verified in integration tests
- [ ] Secret redaction is verified in logs and crash reports
- [ ] Cross-organization isolation is verified with multi-org tests
- [ ] Certificate revocation is tested with manual revocation flow
- [ ] Enrollment token replay is tested with persistence/restart
- [ ] Webhook signatures are tested with consumer verification script
- [ ] OIDC claim validation is tested with forged claims
- [ ] Approval expiry and evidence freshness are tested with time mocking

---

## Future Hardening

Potential additional boundaries for future hardening (out of scope for this release):

- Rate limiting on enrollment, approval, and webhook endpoints
- Proof-of-work or captcha on sensitive operations
- Encrypted proposal bodies for end-to-end secrecy
- Hardware security module (HSM) integration for root key protection
- Distributed denial-of-service (DDoS) protection
- Geo-fencing or IP allowlisting for cluster connections
