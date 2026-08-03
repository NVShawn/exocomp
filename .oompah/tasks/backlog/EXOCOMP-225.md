---
id: EXOCOMP-225
type: task
status: Backlog
priority: 1
title: Define the privileged broker request protocol and action registry
parent: EXOCOMP-211
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-127
labels: []
assignee: null
created_at: '2026-08-03T14:26:19.439901Z'
updated_at: '2026-08-03T14:29:24.644366Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
review_head: null
merged_at: null
oompah.start_blocked_by: *id001
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

