---
id: EXOCOMP-225
type: task
status: Open
priority: 1
title: Define the privileged broker request protocol and action registry
parent: EXOCOMP-211
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-127
- EXOCOMP-213
- EXOCOMP-219
labels: []
assignee: null
created_at: '2026-08-03T14:26:19.439901Z'
updated_at: '2026-08-03T15:38:37.166277Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
review_head: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: c99fdb2c23291f7f8ad063eb214d12a0b9d33c1e86d3b0e71c0d786042540952
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: a0b63ece-3422-4e50-ac18-98bf22cd44e1
  claim_owner: 2dcc53e1-cdcd-4522-a08d-de6ce4222a8c
  claimed_at: '2026-08-03T15:38:35.917878+00:00'
  claim_expires_at: '2026-08-03T16:08:35.917878+00:00'
  retry_count: 0
  retry_after: null
  owner_resolved_at: null
  owner_login: null
  owner_resolution_reason: ''
---
## Summary

Plan: plans/hierarchical-management-modes.md

Deliverable: Generalize the shipped restricted profile helper into one privileged execution broker with a bounded versioned stdin protocol and a closed action registry.

Acceptance criteria:
- The broker has no command-line arguments and reads one length-bounded request from stdin.
- Requests identify schema version, action ID, exact target, node, canonical service key when applicable, policy bundle, and signed action permit.
- The registry contains only compiled typed actions and fixed executable/argument builders.
- Unknown fields, versions, actions, targets, duplicate fields, malformed encoding, trailing data, and oversized requests fail before execution.
- No shell or arbitrary executable/argv interface exists.

Tests: Add parser, registry, size, malformed-input, unknown-action, shell-metacharacter, fuzz-corpus, and fixed-argv snapshot tests; run the focused broker Make target plus make test, make fmt-check, and make lint.

Out of scope: Signature verification, policy resolution, installer changes, and individual action migration.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

