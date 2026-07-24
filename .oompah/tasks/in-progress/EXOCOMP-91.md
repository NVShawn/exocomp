---
id: EXOCOMP-91
type: feature
status: In Progress
priority: 1
title: Run bounded concurrent node polls with per-node isolation
parent: EXOCOMP-15
children: []
blocked_by:
- EXOCOMP-89
- EXOCOMP-90
labels: []
assignee: null
created_at: '2026-07-24T02:43:11.382930Z'
updated_at: '2026-07-24T03:51:23.136794Z'
work_branch: epic-EXOCOMP-2
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: b1604bee-3f1d-4946-9c2b-cbd255e10cb2
oompah.work_branch: epic-EXOCOMP-2
---
## Summary

Implement the supervised health poller that selects Registry nodes whose next_eligible_poll_at is due and runs independent DNS/probe jobs with bounded concurrency. Support at least three simultaneous polls, enforce a per-node timeout, prevent duplicate in-flight polls for one node, and ensure a slow, crashed, or unreachable node cannot delay scheduling or completion of unrelated nodes. Feed typed probe outcomes through the scheduling/state-transition API, update Agent Card version/supported skills and health timestamps atomically, clean up timed-out/crashed workers, and continue polling after worker or poller restart. Make interval, jitter, concurrency, timeouts, clock, resolver, and probe adapters configurable for deterministic tests. Cover the concurrency bound, three overlapping polls, isolation from slow/unreachable nodes, timeout cleanup, no duplicate work, and continued scheduling/recovery; wire the supervisor tree and run affected Make targets.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-24 03:51
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 03:51
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-24 03:51
---
Understanding: I am the Duplicate Investigator for EXOCOMP-91 ('Run bounded concurrent node polls with per-node isolation'). My role is to check whether this issue is a duplicate of any existing task before any implementation begins. I will search the task tracker and docs for similar topics: health polling, concurrent polls, DNS probes, per-node isolation, bounded concurrency, Registry nodes, supervisor trees.
---
<!-- COMMENTS:END -->
