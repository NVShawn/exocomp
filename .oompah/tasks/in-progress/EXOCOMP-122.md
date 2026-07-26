---
id: EXOCOMP-122
type: feature
status: In Progress
priority: 2
title: Add a shipped-artifact M5 performance qualification gate
parent: EXOCOMP-117
children: []
blocked_by: []
labels:
- focus-complete:duplicate_detector
assignee: null
created_at: '2026-07-26T03:58:34.780590Z'
updated_at: '2026-07-26T06:28:28.168297Z'
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
author: oompah
created: 2026-07-26 06:27
---
Discovery: Duplicate screening found no confirmed duplicate. Reviewed EXOCOMP-5, EXOCOMP-35, EXOCOMP-38, EXOCOMP-40, EXOCOMP-47, EXOCOMP-112, EXOCOMP-117, and EXOCOMP-123 in full where tracker history exists. EXOCOMP-35/38 delivered harness components and a fake-server short target; EXOCOMP-112 recovered host-profile/sampler pieces; EXOCOMP-40 nominally called for baselines/gates but has no delivery comments and its shipped-artifact outcome was disproven by signed v0.1.0-rc.2 evidence. EXOCOMP-47 and EXOCOMP-117 explicitly establish EXOCOMP-122 as a corrective remediation child, while EXOCOMP-123 is the downstream requalification task.
---
author: oompah
created: 2026-07-26 06:27
---
Implementation: No code or documentation was changed, as required by the duplicate_detector focus. The worktree remains clean; this run only inspected repository evidence and tracker records and will add the focus-complete routing label.
---
author: oompah
created: 2026-07-26 06:28
---
Verification: Repository checks corroborate a distinct undelivered gap: make help exposes only bench-llama-short and labels it as requiring no real llama-server; the focused workload tests use Bench.Test.FakeLlamaServer; docs/release-evidence/v0.1.0-rc.2 records M5 FAIL because no shipped-artifact Make gate or baseline exists. No tests were run because this screening made no source changes. git status is clean and up to date with origin/epic-EXOCOMP-117.
---
author: oompah
created: 2026-07-26 06:28
---
Focus handoff: duplicate_detector — (1) Outcome: no duplicate confirmed; EXOCOMP-122 is the remediation vehicle for an M5 shipped-artifact gap proven after earlier M5 tasks were merged. (2) Evidence: reviewed tracker records EXOCOMP-5/35/38/40/47/112/117/123; Makefile:181 defines only fake-compatible bench-llama-short; apps/bench/test/bench/workload/llama_inference_test.exs explicitly uses FakeLlamaServer; docs/release-evidence/v0.1.0-rc.2/README.md:52 records the missing shipped-artifact gate and baseline. EXOCOMP-40 is the closest title/scope match, but contains no implementation history and predates the signed failure evidence; EXOCOMP-117 intentionally created this distinct corrective child. (3) Remaining work/risks: implement real installed node/coordinator/llama-server short and full targets, artifact and host identity capture, versioned amd64/arm64 baselines, deterministic metric/budget failure behavior, CI/docs/evidence integration, and tests. Full verification requires exact candidate artifacts on clean amd64 and full-system arm64 guests; emulated performance-only failures remain inconclusive under existing qualification policy. (4) Recommended next focus: feature.
---
author: oompah
created: 2026-07-26 06:28
---
Completion: Duplicate investigation is complete. No duplicate was archived, no repository changes were made, and focus-complete:duplicate_detector is set. EXOCOMP-122 remains In Progress for a fresh feature-focused implementation run using the recorded handoff.
---
<!-- COMMENTS:END -->
