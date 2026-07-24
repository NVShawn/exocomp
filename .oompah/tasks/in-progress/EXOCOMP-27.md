---
id: EXOCOMP-27
type: feature
status: In Progress
priority: 1
title: Integrate remediation lifecycle with A2A tasks and audit
parent: EXOCOMP-3
children: []
blocked_by:
- EXOCOMP-18
- EXOCOMP-22
- EXOCOMP-24
- EXOCOMP-25
labels: []
assignee: null
created_at: '2026-07-23T19:10:13.340897Z'
updated_at: '2026-07-24T18:24:32.615937Z'
work_branch: epic-EXOCOMP-3
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 203eb2b3-bf49-4a2a-8f20-eed106761f31
oompah.work_branch: epic-EXOCOMP-3
---
## Summary

Plan: [Milestone 3 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-3-safety-validation.md)

Goal
Integrate remediation lifecycle with A2A tasks and audit.

Implementation
Connect structured proposals, fresh evidence, policy decisions, input-required approval state, execution, verification, and terminal artifacts; enforce audit-before-action; redact model output; expose typed remediation skills without exposing executors directly.

Testing
Test allow, deny, approval/deny/timeout, stale evidence, audit unavailable before action, post-action audit failure, cancellation, malformed proposal, model bypass attempts, and correlated artifact history.

Acceptance Criteria
- [ ] LLM proposals cannot skip validation, approval, execution restrictions, or verification.
- [ ] State-changing work does not start without durable intent audit.
- [ ] Every transition is represented in A2A task history and correlated audit.
- [ ] Focused lifecycle tests pass.

Quality Gate
Run the focused tests and all repository Make targets affected by this change.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-24 18:24
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 18:24
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->
