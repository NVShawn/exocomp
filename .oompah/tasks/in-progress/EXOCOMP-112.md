---
id: EXOCOMP-112
type: chore
status: In Progress
priority: 1
title: Recover omitted M5 benchmark host-profile and sampler work
parent: EXOCOMP-110
children: []
blocked_by: []
labels: []
assignee: null
created_at: '2026-07-25T17:58:21.078898Z'
updated_at: '2026-07-25T18:44:37.929565Z'
work_branch: epic-EXOCOMP-110
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 13371ce3-035a-4307-bb3c-ac61bcf9a84e
oompah.work_branch: epic-EXOCOMP-110
---
## Summary

Recover the stranded EXOCOMP-53 and EXOCOMP-56 commits onto the EXOCOMP-110 shared recovery branch based on current main. Preserve existing Bench.Config/raw sample/telemetry work while integrating pinned amd64/arm64 host profiles, Linux host sampling, per-process/cgroup attribution, and tests. Resolve conflicts semantically and run all affected benchmark Make targets and tests.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-25 18:43
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-25 18:43
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-25 18:43
---
Understanding: Investigating EXOCOMP-112 as Duplicate Investigator. The task requests recovering EXOCOMP-53 and EXOCOMP-56 commits (M5 benchmark host-profile and sampler work) onto the EXOCOMP-110 shared recovery branch. Before implementing, I must verify this is not a duplicate of an existing task covering the same recovery work. Searching now for related tasks.
---
author: oompah
created: 2026-07-25 18:44
---
Discovery: Duplicate screening complete. EXOCOMP-112 is NOT a duplicate.

Reviewed candidates:
- EXOCOMP-53 (Needs Human): 'Implement pinned amd64 and arm64 host profiles' — this is a SOURCE task whose stranded work EXOCOMP-112 must recover, not a duplicate.
- EXOCOMP-56 (Needs Human): 'Implement host sampler with per-process/cgroup attribution' — same, source task for recovery.
- EXOCOMP-110 (In Progress): Parent epic covering all omitted work recovery — broader scope, EXOCOMP-112 is a scoped child.
- EXOCOMP-111 (Done): Recovered EXOCOMP-49 + EXOCOMP-51 (M1 A2A codec/fixture work) — different deliverable group, already closed.
- EXOCOMP-113/114/115/116 (Open): Sibling children covering M3/M4 acceptance, M6 governance, undelivered work, and final verification — each a different scope.

No existing task covers the same recovery of EXOCOMP-53 (Bench.HostProfile with amd64-ci.toml/arm64-ci.toml) and EXOCOMP-56 (Bench.HostSampler /proc-based GenServer) onto epic-EXOCOMP-110. EXOCOMP-112 is the sole vehicle for this recovery.

Key facts for implementation agent:
- Source branches: EXOCOMP-53 (commit 2fb102d on branch EXOCOMP-53) and EXOCOMP-56 (commit 9634b10 on branch EXOCOMP-56).
- Target branch: epic-EXOCOMP-110 (HEAD currently at 2da861a after EXOCOMP-111 recovery).
- EXOCOMP-53 delivered: apps/bench/lib/bench/host_profile.ex (detect/0, load/1, compatible?/2 + inline flat-TOML parser), priv/bench/profiles/amd64-ci.toml, priv/bench/profiles/arm64-ci.toml, test/bench/host_profile_test.exs (19 tests).
- EXOCOMP-56 delivered: apps/bench/lib/bench/host_sampler.ex (329-line GenServer for /proc + cgroup v2), updated apps/bench/lib/bench/sample.ex (nil value + tags field), apps/bench/test/bench/host_sampler_test.exs (183-line, 4 tests).
- EXOCOMP-56 is based on EXOCOMP-53 which is based on EXOCOMP-54 (the raw sample model). Recovery order: cherry-pick EXOCOMP-53 commit first, then EXOCOMP-56 commit.
- Run make test, make lint, make fmt-check in apps/bench after integration.
---
<!-- COMMENTS:END -->
