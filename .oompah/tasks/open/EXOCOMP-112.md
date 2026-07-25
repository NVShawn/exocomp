---
id: EXOCOMP-112
type: chore
status: Open
priority: 1
title: Recover omitted M5 benchmark host-profile and sampler work
parent: EXOCOMP-110
children: []
blocked_by: []
labels: []
assignee: null
created_at: '2026-07-25T17:58:21.078898Z'
updated_at: '2026-07-25T18:29:44.588818Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Recover the stranded EXOCOMP-53 and EXOCOMP-56 commits onto the EXOCOMP-110 shared recovery branch based on current main. Preserve existing Bench.Config/raw sample/telemetry work while integrating pinned amd64/arm64 host profiles, Linux host sampling, per-process/cgroup attribution, and tests. Resolve conflicts semantically and run all affected benchmark Make targets and tests.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

