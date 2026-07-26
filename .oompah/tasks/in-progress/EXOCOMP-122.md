---
id: EXOCOMP-122
type: feature
status: In Progress
priority: 2
title: Add a shipped-artifact M5 performance qualification gate
parent: EXOCOMP-117
children: []
blocked_by: []
labels: []
assignee: null
created_at: '2026-07-26T03:58:34.780590Z'
updated_at: '2026-07-26T06:24:43.974230Z'
work_branch: epic-EXOCOMP-117
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 56619550-d780-4a97-ba9e-11d11063a16e
oompah.work_branch: epic-EXOCOMP-117
---
## Summary

Context
The v0.1.0-rc.2 qualification could find only bench-llama-short, which uses a fake server. There is no documented Make target or versioned baseline that measures the installed node, coordinator, and real llama-server release payload for M5 acceptance.

Implementation
Add short and full Make targets that run the M5 harness against shipped release artifacts, record pinned host profiles and versioned amd64 and arm64 baselines, separate BEAM control-plane usage from llama.cpp, and enforce documented regression budgets with clear failed-metric output. Integrate the full target into release qualification docs and evidence collection.

Testing
Cover harness configuration, artifact identity, host-profile capture, baseline selection, threshold pass and fail behavior, missing metric failure, and result reproducibility. Exercise the short target in CI and the full target on clean amd64 and full-system arm64 guests using the exact candidate artifacts.

Acceptance Criteria
- Documented Make targets run the real shipped processes rather than fake-only fixtures.
- Versioned baselines and raw evidence identify artifact and host profile.
- A threshold regression fails with the exact metric and budget.
- Both architecture qualification runs satisfy every applicable M5 criterion.
- Focused tests and relevant Make gates pass.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-26 06:24
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-26 06:24
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-26 06:24
---
Understanding: This focus is limited to duplicate screening. I will search existing task records and project documentation for M5 performance gates, shipped-artifact benchmarks, architecture baselines, and release qualification work; I will inspect every plausible task in full before deciding whether EXOCOMP-122 duplicates it. No implementation changes will be made in this run.
---
<!-- COMMENTS:END -->
