---
id: EXOCOMP-11
type: feature
status: Backlog
priority: 1
title: Supervise llama.cpp and validate structured proposals
parent: EXOCOMP-1
children: []
blocked_by: []
labels: []
assignee: null
created_at: '2026-07-23T19:08:56.242530Z'
updated_at: '2026-07-23T19:08:56.242530Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Plan: [Milestone 1 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-1-node-agent.md)

Goal
Supervise llama.cpp and validate structured proposals.

Implementation
Supervise a pinned loopback-only llama-server process with readiness checks, bounded restart backoff, and independent failure isolation; implement the Qwen2.5 proposal client with fixed prompt, bounded context, timeouts, checksum validation, and strict versioned output schema.

Testing
Use a fake llama-server to test startup, readiness, valid proposal, invalid JSON/schema, timeout, crash/restart, backoff, unavailable model, and output redaction.

Acceptance Criteria
- [ ] A llama.cpp crash cannot terminate node diagnostics or the BEAM.
- [ ] Only schema-valid known proposal IDs are returned.
- [ ] Invalid, timed-out, or unavailable inference never yields an executable action.
- [ ] Focused supervisor/client tests pass.

Quality Gate
Run the focused tests and all repository Make targets affected by this change.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

