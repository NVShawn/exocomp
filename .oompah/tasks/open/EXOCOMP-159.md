---
id: EXOCOMP-159
type: task
status: Open
priority: 1
title: Implement the coordinator exocomp.cluster.chat skill
parent: EXOCOMP-132
children: []
blocked_by:
- EXOCOMP-145
- EXOCOMP-139
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:16:17.558974Z'
updated_at: '2026-08-01T11:49:21.933725Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Plan: plans/mission-control.md, Conversations and Cluster-Local Reasoning.

Deliverables:
- Add exocomp.cluster.chat to the coordinator Agent Card and A2A dispatcher.
- Build bounded model input from the fixed system prompt, recent thread context, and fresh typed diagnostics.
- Call the configured local OpenAI-compatible inference endpoint.
- Validate schema-constrained output containing Markdown, evidence citations, and at most one typed proposal.

Acceptance:
- Tests cover valid reply, no model configured, timeout, invalid/truncated schema, stale evidence, missing citation, oversized context, and model crash.
- The skill exposes no arbitrary command or file access.

Out of scope: Mission Control persistence and executing proposals.
Quality gate: focused coordinator/A2A tests plus make test, make fmt-check, and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

