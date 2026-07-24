---
id: EXOCOMP-91
type: feature
status: Open
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
updated_at: '2026-07-24T02:49:33.715040Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Implement the supervised health poller that selects Registry nodes whose next_eligible_poll_at is due and runs independent DNS/probe jobs with bounded concurrency. Support at least three simultaneous polls, enforce a per-node timeout, prevent duplicate in-flight polls for one node, and ensure a slow, crashed, or unreachable node cannot delay scheduling or completion of unrelated nodes. Feed typed probe outcomes through the scheduling/state-transition API, update Agent Card version/supported skills and health timestamps atomically, clean up timed-out/crashed workers, and continue polling after worker or poller restart. Make interval, jitter, concurrency, timeouts, clock, resolver, and probe adapters configurable for deterministic tests. Cover the concurrency bound, three overlapping polls, isolation from slow/unreachable nodes, timeout cleanup, no duplicate work, and continued scheduling/recovery; wire the supervisor tree and run affected Make targets.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

