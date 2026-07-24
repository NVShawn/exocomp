---
id: EXOCOMP-92
type: task
status: In Progress
priority: 1
title: Add multi-node discovery and polling integration coverage
parent: EXOCOMP-15
children: []
blocked_by:
- EXOCOMP-88
- EXOCOMP-89
- EXOCOMP-90
- EXOCOMP-91
labels: []
assignee: null
created_at: '2026-07-24T02:43:19.301040Z'
updated_at: '2026-07-24T04:02:26.135372Z'
work_branch: epic-EXOCOMP-2
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: d99a5474-6eb8-4710-836e-c637378b17e3
oompah.work_branch: epic-EXOCOMP-2
---
## Summary

Add the cross-component verification suite for EXOCOMP-15 after DNS, authenticated probing, scheduling, and concurrent execution land. Use at least three controllable TLS node fixtures and a deterministic DNS/resolver seam to exercise healthy, degraded/slow, stale, unreachable, and wrong-identity nodes; multiple addresses; DNS address changes accepted only after successful mTLS verification; failed address changes retaining the last verified address; bounded concurrent polling; per-node timeout isolation; exponential backoff; and recovery without blocking unrelated nodes. Assert Registry reachability, addresses, Agent Card metadata, failure counters, last-attempt/last-success timestamps, and next eligible poll times, plus relevant redacted audit events. Avoid wall-clock sleeps where injectable clocks/events suffice. Run the focused coordinator suite and every affected Make quality gate (test, lint, fmt-check, and build if applicable), documenting any true environment-only exclusions.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-24 04:01
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 04:01
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-24 04:01
---
Understanding: Screening EXOCOMP-92 for duplication before any implementation. I will search task records and design docs for existing multi-node discovery/polling integration coverage, then inspect full candidate task histories to distinguish prerequisite component tests from an already-covered cross-component suite.
---
author: oompah
created: 2026-07-24 04:02
---
Discovery: No duplicate confirmed. Reviewed full records for EXOCOMP-15, EXOCOMP-20, and prerequisite children EXOCOMP-88 through EXOCOMP-91. EXOCOMP-15 is the parent that intentionally decomposed this suite into EXOCOMP-92; EXOCOMP-88/89/90/91 contain component-level DNS, probe, scheduling, and concurrency tests, while EXOCOMP-20 is broader milestone verification spanning enrollment, diagnostics, restart, and all M2 criteria. Repository search shows separate Resolver/NodeProber/Registry unit coverage but no existing cross-component multi-node TLS discovery/polling suite. EXOCOMP-92 uniquely owns that integration boundary.
---
<!-- COMMENTS:END -->
