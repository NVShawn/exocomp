---
id: EXOCOMP-96
type: task
status: Backlog
priority: null
title: 'Implement precondition re-check: verify current evidence matches token evidence_hash'
parent: EXOCOMP-24
children: []
blocked_by: []
labels: []
assignee: null
created_at: '2026-07-24T03:12:36.235284Z'
updated_at: '2026-07-24T03:12:36.235284Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

### Goal

Implement \`Exocomp.Node.Safety.PreconditionChecker\` — re-evaluate the current system state at execution time and verify it matches the preconditions that were present when the coordinator issued the approval token.

### Context

The approval token binds an \`evidence_hash\` field: the SHA-256 hash of the canonical evidence map collected when the policy engine produced \`approval_required\`. If the system state has changed since approval (e.g. a service state changed, disk usage changed, the target was already restarted), executing the approved action would be unsafe or incorrect.

This task implements the node-side re-check: collect fresh evidence, hash it the same way the coordinator did, and compare with the token's \`evidence_hash\`. A mismatch blocks execution.

The \`ApprovalToken.hash_evidence/1\` function from EXOCOMP-86 (branch \`EXOCOMP-86\`) produces the canonical hash. The \`Exocomp.Node.Safety.Evidence\` type from EXOCOMP-21 (branch \`EXOCOMP-21\`) defines the evidence struct and validation.

### Implementation

Create \`apps/exocomp_node/lib/exocomp/node/safety/precondition_checker.ex\` containing \`Exocomp.Node.Safety.PreconditionChecker\`.

### Evidence collection

Define a behaviour or protocol for evidence collection by action type:

- \`:restart_service\` — collect systemd unit state (active, sub-state) for the target unit using \`systemctl show\` (the same approach used by EXOCOMP-10 diagnostic collectors on branch \`EXOCOMP-10\`). The evidence map should include at minimum: \`active_state\`, \`sub_state\`, \`unit_name\`, \`collected_at\`.
- \`:vacuum_logs\` — collect current disk usage figures (filesystem bytes available for the relevant path). Include: \`available_bytes\`, \`total_bytes\`, \`path\`, \`collected_at\`.

Evidence collection must:
- Use deterministic, unprivileged read-only system APIs
- Use the same canonical field names and value formats as the coordinator used when computing the original \`evidence_hash\`
- Be injectable for unit tests (via Application config, similar to \`OsCommander\` in EXOCOMP-25)

**Critical**: the canonical form of the evidence map must be **identical** to whatever the coordinator hashed. If the coordinator used \`Exocomp.Coordinator.Safety.ApprovalToken.hash_evidence/1\`, the node must produce the exact same map with the exact same keys and value types before hashing. Coordinate field names and value formats between this task and EXOCOMP-23 (the coordinator issuance task).

### Verification

\`\`\`elixir
@spec verify(token :: ApprovalToken.t(), action_id :: atom(), target :: String.t()) ::
  :ok | {:error, :precondition_changed} | {:error, {:collection_failed, reason :: term()}}
\`\`\`

1. Collect fresh evidence for the given \`action_id\` and \`target\`
2. Compute \`ApprovalToken.hash_evidence/1\` on the fresh evidence map
3. Compare with \`token.evidence_hash\`
4. If they match → return \`:ok\`
5. If they differ → return \`{:error, :precondition_changed}\`
6. If evidence collection fails → return \`{:error, {:collection_failed, reason}}\` (fail closed — do NOT proceed if evidence cannot be collected)

### Tests

File: \`apps/exocomp_node/test/exocomp/node/safety/precondition_checker_test.exs\`

Cover:
- Evidence unchanged between approval and re-check → \`:ok\`
- Service state changed (e.g. active→inactive) between approval and re-check → \`{:error, :precondition_changed}\`
- Any field in the evidence map changed → \`{:error, :precondition_changed}\`
- Evidence collection failure → fail closed with \`{:error, {:collection_failed, ...}}\`
- Mock evidence collector injectable via Application config
- Hash comparison is byte-for-byte (not semantic)
- Different field order in evidence map still hashes identically (canonical encoding handles this)

### Prerequisites

- EXOCOMP-86 branch (for \`ApprovalToken.hash_evidence/1\`)
- EXOCOMP-21 branch (for \`Exocomp.Node.Safety.Evidence\` type definitions)
- EXOCOMP-25 branch (reference for how EXOCOMP-10 evidence collectors work, injectable OsCommander pattern)

### Quality gate

Run \`make test\` and \`make lint\` before closing.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

