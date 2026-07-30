---
id: EXOCOMP-182
type: task
status: Backlog
priority: 1
title: Build the two-cluster Mission Control qualification scenario
parent: EXOCOMP-135
children: []
blocked_by: []
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:18:50.264411Z'
updated_at: '2026-07-30T14:18:50.264411Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Plan: plans/mission-control.md, Test Strategy.

Deliverables:
- Automate the planned two-cluster scenario: connect and report nodes; open/deduplicate a failed-service incident; converse with the cluster-local model; receive a cited typed proposal; approve once; revalidate, execute once, verify, and report the audit timeline.
- Force disconnect/reconnect during the scenario.
- Capture machine-readable results and raw evidence.

Acceptance:
- No duplicate incident, message, approval, or execution appears.
- Every timeline item shares the expected correlation chain.
- Failure at any step exits nonzero with the failed phase and retained evidence path.

Out of scope: 100-cluster load and release publication.
Quality gate: a dedicated noninteractive Make qualification target.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

