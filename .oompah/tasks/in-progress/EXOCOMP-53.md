---
id: EXOCOMP-53
type: task
status: In Progress
priority: null
title: Implement pinned amd64 and arm64 host profiles
parent: EXOCOMP-35
children: []
blocked_by: []
labels: []
assignee: null
created_at: '2026-07-23T20:36:53.820999Z'
updated_at: '2026-07-23T21:31:02.771738Z'
work_branch: epic-EXOCOMP-5
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 32fca3e4-d258-41c2-9860-0d09ee969fc7
oompah.work_branch: epic-EXOCOMP-5
---
## Summary

In apps/bench, implement Bench.HostProfile — a module defining the static reference host profiles for amd64 and arm64, plus runtime host detection and compatibility enforcement. Each profile records: architecture, CPU model/count, RAM, kernel version, Linux distribution, libc version, power/performance governor, and container/VM boundary. Implement: Bench.HostProfile.detect/0 to detect the current host, Bench.HostProfile.load/1 to load a named profile from config, Bench.HostProfile.compatible?/2 to verify two profiles are comparable (same arch required; raise if not). Ship two reference profile YAML/TOML files: priv/bench/profiles/amd64-ci.toml and priv/bench/profiles/arm64-ci.toml. Test cases: detect returns a well-formed struct, compatible? returns false for amd64 vs arm64, incompatible profiles produce descriptive errors, missing profile file returns {:error, :not_found}. Reference: plans/milestone-5-performance.md (Benchmark Environments section).

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-23 21:31
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 21:31
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->
