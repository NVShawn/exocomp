---
id: EXOCOMP-8
type: feature
status: Open
priority: 1
title: Implement A2A 1.0 shared protocol types and fixtures
parent: EXOCOMP-1
children: []
blocked_by:
- EXOCOMP-7
labels:
- focus-complete:duplicate_detector
- needs:feature
assignee: null
created_at: '2026-07-23T19:08:53.749492Z'
updated_at: '2026-07-23T20:26:03.534309Z'
work_branch: epic-EXOCOMP-1
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 364f519a-253b-4a3c-9946-6b1e85412192
oompah.work_branch: epic-EXOCOMP-1
oompah.task_costs:
  total_input_tokens: 20
  total_output_tokens: 3749
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 20
      output_tokens: 3749
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 20
    output_tokens: 3749
    cost_usd: 0.0
    recorded_at: '2026-07-23T20:25:59.424210+00:00'
---
## Summary

Plan: [Milestone 1 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-1-node-agent.md)

Goal
Implement A2A 1.0 shared protocol types and fixtures.

Implementation
Pin the official A2A 1.0 schemas used by Exocomp; implement HTTP+JSON codecs for Agent Card, Message, Task, Part, Artifact, task states, standard errors, and A2A-Version handling; keep types in shared umbrella code.

Testing
Add fixture round-trip tests, invalid payload tests, required-field tests, media-type tests, and version negotiation tests.

Acceptance Criteria
- [ ] Official valid fixtures round-trip without semantic loss.
- [ ] Malformed or unsupported input returns the correct bounded A2A error.
- [ ] A2A-Version values other than supported 1.0 fail as designed.
- [ ] All shared protocol tests pass.

Quality Gate
Run the focused tests and all repository Make targets affected by this change.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-23 20:24
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 20:24
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 20:25
---
Understanding: Acting as Duplicate Investigator for EXOCOMP-8 (Implement A2A 1.0 shared protocol types and fixtures). Searched .oompah/tasks, plans/, docs/, and README.md for related tasks. Reviewed EXOCOMP-1 (parent epic), EXOCOMP-7 (blocker, now Done), EXOCOMP-9 through EXOCOMP-13 (sibling M1 children). No duplicate found.
---
author: oompah
created: 2026-07-23 20:25
---
Focus handoff: duplicate_detector

**Outcome:** No duplicate confirmed. EXOCOMP-8 is a unique task with no overlap in the existing task graph.

**Evidence reviewed:**
- Searched all plans and docs for A2A, protocol types, codec, fixture, and shared types keywords
- Reviewed EXOCOMP-7 (scaffold — Done): covers umbrella, build, OTP apps, Make gates — no protocol type implementation
- Reviewed EXOCOMP-9 (node config and mTLS): covers config, identity, TLS — not A2A codec/types
- Reviewed EXOCOMP-10 through EXOCOMP-13: Linux diagnostics, llama.cpp, A2A service, M1 verification — none cover shared protocol types layer
- Confirmed via plans/milestone-1-node-agent.md lines 180–181: the protocol fixture suite (EXOCOMP-8 scope) is explicitly a separate deliverable from the node A2A service (EXOCOMP-12)
- EXOCOMP-7 is Done; its unblock of EXOCOMP-8 clears the stated dependency

**Relevant files:**
- plans/milestone-1-node-agent.md — lines 128–181 (A2A Interface and test sections), lines 16 and 47 (A2A 1.0 scope)
- Branch epic-EXOCOMP-1 contains the scaffold from EXOCOMP-7 (apps/exocomp_core, apps/exocomp_node, apps/exocomp_coordinator, Makefile, mix.exs)

**Remaining work:**
1. Pin A2A 1.0 schemas (Agent Card, Message, Task, Part, Artifact, task states, standard errors)
2. Implement HTTP+JSON codecs for each type in shared umbrella code (apps/exocomp_core or a new apps/exocomp_protocol)
3. Implement A2A-Version header handling (accept 1.0, reject others with bounded error)
4. Add ExUnit tests: fixture round-trips, invalid payload tests, required-field tests, media-type tests, version negotiation tests
5. Verify make test, make lint, make fmt-check pass

**Risks:**
- EXOCOMP-7 landed all three OTP apps but the protocol app location (exocomp_core vs separate protocol app) needs to be confirmed against the plan; milestone-1 says 'shared umbrella code'
- The official A2A 1.0 JSON schema source should be pinned/vendored

**Recommended next focus:** feature — this is a straightforward implementation of A2A 1.0 protocol types and test suite in Elixir
---
author: oompah
created: 2026-07-23 20:26
---
Agent completed successfully in 98s (3769 tokens)
---
author: oompah
created: 2026-07-23 20:26
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/default]
- Turns: 32, Tool calls: 24
- Tokens: 20 in / 3.7K out [3.8K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 38s
- Log: EXOCOMP-8__20260723T202424Z.jsonl
---
author: oompah
created: 2026-07-23 20:26
---
Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
<!-- COMMENTS:END -->
