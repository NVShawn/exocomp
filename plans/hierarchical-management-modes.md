# Hierarchical Observe/Manage Policy

## Status

Proposed

Target date: TBD

Depends on: complete delivery of
[Milestone 7: Exocomp Mission Control](mission-control.md) and its oompah
umbrella epic `EXOCOMP-127`.

## Outcome

Exocomp provides an organization-wide management policy with global,
per-cluster, per-cluster/service, per-node, and per-node/service toggles.
Every toggle is either `observe` or `manage`, the default is `observe`, and
more-specific policy overrides less-specific policy.

`observe` allows status collection, diagnostics, alerts, conversations, and
non-executable remedy proposals. It forbids every state-changing action.
`manage` makes an action eligible but never bypasses an installed action
catalog, allow-list, cluster profile, evidence, approval, idempotency,
cooldown, verification, or audit requirement.

## Goals

- Make a new or upgraded installation fail closed in `observe` until an admin
  explicitly enables management.
- Apply policy consistently to service, node, and cluster mutations.
- Allow centralized configuration without making Mission Control an execution
  credential holder.
- Expire cached management authority after a bounded Mission Control outage.
- Enforce `observe` at the privileged operating-system boundary, not only in
  UI or application code.
- Show operators which rule produced every effective decision.

## Non-Goals

- Expanding an installed action catalog, service allow-list, profile action,
  or operating-system privilege.
- An arbitrary command or argument interface.
- A global emergency lock that ignores all more-specific rules. Under this
  hierarchy, a more-specific `manage` may override a less-specific `observe`.
- Interrupting or rolling back an operating-system action after the privileged
  broker has accepted it.
- Starting implementation before all Mission Control work under
  `EXOCOMP-127` is complete.

## Policy Model

The policy value is one of:

- `observe` — collect evidence and discuss or propose remedies, but reject
  every mutation.
- `manage` — permit the existing safety pipeline to consider a mutation.

The supported scopes are:

| Scope | Required identity | Example |
|---|---|---|
| Global | Organization | All clusters in one organization |
| Cluster | Cluster | Cluster A |
| Cluster/service | Cluster and service key | `ceph:osd` across Cluster A |
| Node | Cluster and node | Node 3 in Cluster A |
| Node/service | Cluster, node, and service key | `ceph:osd` on Node 3 |

Canonical service keys are stable policy identities rather than display
names. Ordinary systemd units use `systemd:<unit>`, such as
`systemd:nginx.service`. Shipped cluster profiles define keys such as
`ceph:mon`, `ceph:mgr`, and `ceph:osd` and map local daemon instances to those
keys. A node/service rule covers all local instances of the logical service.

### Resolution

For a service-targeted action, resolve policy as follows:

1. Use node/service when present.
2. Otherwise evaluate node and cluster/service as peer scopes. Use their
   common value when they agree; use `observe` when they disagree; use the
   one present when only one exists.
3. Otherwise use cluster.
4. Otherwise use organization-global.
5. Otherwise use the implicit default `observe`.

For a node-level action without a service key, use node, cluster, global, then
implicit `observe`. For a cluster-level action associated with a service, use
cluster/service, cluster, global, then implicit `observe`.

Removing an override means inheritance from the next matching scope. It does
not create an implicit `observe` rule. Every resolution returns the effective
mode, winning scope or peer conflict, policy version, and matched rules.

## Mission Control Interfaces

Mission Control stores organization-scoped policy rows containing scope,
cluster and node IDs where applicable, canonical service key where
applicable, mode, monotonic organization policy version, actor, and
timestamps. Database constraints require exactly the identity fields allowed
for each scope and one rule per scope identity.

The versioned API supports listing, resolving, creating, updating, and
deleting overrides. Organization identity comes from the authenticated
session and cannot be supplied by payload. Mutation requests use optimistic
version checks so concurrent admins cannot silently overwrite each other.

Authorization is:

- Admins may set `observe` or `manage` and remove any override.
- Operators may only make policy equally or more restrictive. They cannot set
  `manage` or remove an override when inheritance would broaden authority.
- Viewers may inspect configured and effective policy only.

An observe-to-manage change requires a normal confirmation dialog showing the
scope, current value, inherited value, and resulting effective value. The UI
shows configured and effective modes, winning scope, peer conflicts, policy
version, cluster acknowledgement, and lease expiry. Observe-mode proposals
remain visible but approval and execution controls are disabled.

All policy mutations and effective-mode transitions are durable audit events.

## Policy Distribution and Leases

Mission Control sends immutable, cluster-specific policy bundles through the
existing durable command outbox. Each bundle contains its schema version,
organization and cluster identity, applicable rules, monotonic policy version,
issue and expiry times, and signing-key ID. A dedicated online Ed25519 policy
key signs the canonical bundle. Key rotation supports an overlap period in
which the current and immediately previous verification keys are trusted.

The default lease is five minutes. An organization admin may configure it
from 60 to 3,600 seconds. Renewal defaults to 60 seconds and must remain below
half the lease lifetime.

The coordinator validates identity, signature, schema, version monotonicity,
and lease before atomically replacing its protected cached bundle. Missing,
malformed, replayed, wrong-cluster, signature-invalid, or expired policy
resolves entirely to `observe`.

A disconnected cluster retains `manage` only until its current lease expires.
Expiry immediately switches it to `observe`, invalidates pending execution,
and produces durable local audit state. Reconnection reports the fallback and
accepts only a fresh bundle. A manage policy received after reconnect is
configuration, not a queued approval, and requires a new valid lease.

Heartbeats and status snapshots carry applied policy version, lease expiry,
enforcement protocol version, and effective-mode summary. Mission Control
records policy applied, rejected, expired, and fallback transitions.

## Enforcement

```mermaid
flowchart LR
    MC[Mission Control policy] -->|signed leased bundle| C[Coordinator]
    C -->|bundle + signed action permit| N[Node safety gate]
    N -->|bounded stdin request| B[Privileged execution broker]
    B -->|fixed typed argv| OS[Operating system]
```

Policy is checked independently at four boundaries:

1. Mission Control rejects approval or execution commands whose effective
   mode is `observe`.
2. The coordinator resolves policy again before proposing, approving,
   signing, or dispatching an action.
3. The node requires a fresh bundle and action permit before entering a
   state-changing workflow.
4. A root-owned execution broker verifies policy and action authorization
   immediately before mutation.

All current and future mutations, including service restart, Ceph profile
actions, and journal vacuum, use the broker. Sudoers grants the Exocomp node
account only the exact broker path with no arguments. Direct `systemctl`,
`journalctl`, profile-helper, shell, and wildcard mutation entries are removed.

The broker accepts a bounded, versioned stdin protocol. It independently:

- Verifies the Mission Control policy signature, identities, version, lease,
  service key, and effective mode using the shared deterministic resolver.
- Verifies the coordinator-signed node, action, exact target, service key,
  evidence hash, idempotency ID, and expiry.
- Requires `manage` and all existing action-catalog, allow-list/profile,
  current-state, and fixed-argument checks.
- Executes no shell and accepts no arbitrary executable or argument list.

Execution permits expire within 60 seconds and never after the policy lease.
No policy, no permit, any verification failure, or resolver disagreement
denies the action as `observe`.

Policy changes apply to work not yet accepted by the broker. An action already
accepted completes verification and records `policy_changed_during_execution`.
Changing to `observe` invalidates pending approvals and queued execution
commands but leaves diagnostics, conversations, and proposals available.

Nodes that do not advertise the management-policy and broker protocol versions
remain `observe`. Mission Control cannot activate `manage` for a scope that
would include an unsupported node.

## Migration and Rollout

Implementation begins only after `EXOCOMP-127` is complete.

1. Add policy persistence, resolver, API, audit, and read-only UI while all
   targets still report implicit `observe`.
2. Add signing, durable bundle distribution, coordinator cache, lease expiry,
   and status reporting.
3. Package the broker and migrate every mutation path before allowing policy
   editing.
4. Remove direct mutation sudo privileges and verify mixed-version nodes stay
   `observe`.
5. Enable admin policy editing and explicitly opt qualification scopes into
   `manage`.
6. Qualify both architectures before enabling production management.

Upgrade creates no `manage` rule. Existing action allow-lists remain
authorization ceilings but cannot execute until an admin explicitly enables
management. Downgrade tooling refuses to restore an older release with direct
sudo mutation paths unless an administrator explicitly follows the documented
privilege rollback procedure.

## Test Strategy

Unit tests exhaustively cover all scopes, inheritance, deletion, peer conflict,
canonical service mapping, absent rules, and deterministic resolution.

Mission Control tests cover organization isolation, optimistic concurrency,
RBAC including indirectly broadening deletion, confirmation behavior, audit,
and configured-versus-effective rendering.

Protocol and coordinator tests cover canonical signing, wrong identity,
replay, stale version, clock skew, configurable lease bounds, renewal, expiry,
restart recovery, disconnect fallback, key rotation, acknowledgement, and
status reporting.

Broker security tests cover direct invocation, malformed and oversized input,
forged signatures, mismatched targets and service keys, expired permits,
resolver disagreement, shell metacharacters, unknown actions, and fixed-argv
execution. Installer tests prove no direct mutation sudo entry remains.

End-to-end tests prove every mutation path fails in `observe` while status,
diagnostics, alerts, chat, and proposals continue. They exercise every scope,
peer conflict, explicit node/service override, disconnected lease expiry,
mixed-version nodes, policy changes during execution, and upgrade from a
previous managed installation.

Release qualification exercises two clusters and shipped amd64 and arm64
artifacts. It starts fully in `observe`, enables selected `manage` scopes,
executes exactly the permitted typed actions, and proves all other targets
remain unable to change state.

## Acceptance Criteria

- [ ] MP-CRIT-1: With no stored policy, every target resolves to `observe` and
      every mutation fails at Mission Control, coordinator, node, and broker.
- [ ] MP-CRIT-2: Global, cluster, cluster/service, node, and node/service rules
      resolve deterministically, including observe-wins node versus
      cluster/service disagreement.
- [ ] MP-CRIT-3: Observe mode preserves status, diagnostics, alerts, chat, and
      proposals while disabling approvals and execution.
- [ ] MP-CRIT-4: Admin, operator-restriction, viewer, organization-isolation,
      optimistic-concurrency, and audit tests pass for every policy mutation.
- [ ] MP-CRIT-5: Signed policy bundles are durable, identity-bound,
      version-monotonic, replay-resistant, and acknowledged by coordinators.
- [ ] MP-CRIT-6: A disconnected cluster falls back to `observe` no later than
      its configured lease expiry and cannot reuse expired management authority.
- [ ] MP-CRIT-7: Every state-changing action uses the privileged broker and no
      direct mutation sudo privilege remains after fresh install or upgrade.
- [ ] MP-CRIT-8: The broker independently rejects invalid policy, invalid
      permits, resolver disagreement, arbitrary commands, and unauthorized
      targets before operating-system execution.
- [ ] MP-CRIT-9: `manage` never expands installed action catalogs,
      allow-lists, profile permissions, or deterministic safety policy.
- [ ] MP-CRIT-10: Unsupported or mixed-version nodes remain `observe`, are
      visible to operators, and cannot be included in a manage activation.
- [ ] MP-CRIT-11: Upgrade from an existing installation produces no implicit
      manage rule and requires explicit admin opt-in before recovery resumes.
- [ ] MP-CRIT-12: Two-cluster amd64 and arm64 qualification proves all five
      scopes, lease expiry, permitted action execution, and observe-mode denial
      using shipped artifacts.

## Implementation Tracking

Oompah epic `EXOCOMP-208` owns implementation status, with area epics for the
policy model and interfaces (`EXOCOMP-209`), distribution and leases
(`EXOCOMP-210`), privileged enforcement (`EXOCOMP-211`), and qualification
(`EXOCOMP-212`). The implementation epic, every area epic, and every leaf task
have a hard-start dependency on the complete Mission Control umbrella epic
`EXOCOMP-127`.
