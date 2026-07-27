---
id: EXOCOMP-126
type: task
status: In Progress
priority: 1
title: Complete failed-service recovery through the A2A workflow
parent: null
children: []
blocked_by: []
labels:
- focus-complete:duplicate_detector
assignee: null
created_at: '2026-07-27T16:09:25.749059Z'
updated_at: '2026-07-27T16:20:06.098205Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 0822dc44-8a71-49e9-a76c-08b077dcf419
oompah.task_costs:
  total_input_tokens: 1984473
  total_output_tokens: 6448
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 1984473
      output_tokens: 6448
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 1984473
    output_tokens: 6448
    cost_usd: 0.0
    recorded_at: '2026-07-27T16:18:55.563667+00:00'
---
## Summary

Triggered by: EXOCOMP-124

Close M4-CRIT-2. The recovery engine, restricted systemd execution, live fixture recovery, verification, and audit are on main, but the accepted recovery is invoked directly rather than through a complete authenticated A2A task workflow. Wire detection/diagnosis/recovery through the node and coordinator A2A surfaces, add end-to-end coverage using the fixture service, run relevant Make gates, and merge the evidence to main.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-27 16:15
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-27 16:15
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-27 16:16
---
Understanding: duplicate screening only. I will search tracker/docs for existing failed-service recovery and authenticated A2A workflow work, then inspect each plausible task's full description/comments before deciding whether EXOCOMP-126 duplicates prior scope. I will not implement code during this focus.
---
author: oompah
created: 2026-07-27 16:18
---
Discovery: duplicate screening found no confirmed duplicate. Closest full records reviewed were EXOCOMP-27, 30, 31, 32, 34, 115, 123, 124, and parent EXOCOMP-4. EXOCOMP-31/115 delivered the direct FailedService engine; EXOCOMP-27 provides generic remediation lifecycle infrastructure; EXOCOMP-32 is the approval-required active/degraded flow; EXOCOMP-34 and 123 own milestone/release verification. EXOCOMP-124 explicitly created EXOCOMP-126 after finding M4-CRIT-2 still open. Current source corroborates the gap: the node A2A codec/dispatcher exposes only diagnose/propose skills, the coordinator codec/dispatcher/card intentionally excludes remediation, and m4_acceptance_test.exs calls FailedService.recover directly.
---
author: oompah
created: 2026-07-27 16:18
---
Focus handoff: duplicate_detector

1. Outcome: No duplicate confirmed. EXOCOMP-126 is a corrective integration task for the authenticated end-to-end A2A recovery path that prior M4 and release work did not deliver.

2. Evidence: Searched recovery/A2A/M4-CRIT-2 terms in plans/docs and the git-backed tracker branch because this checkout has no .oompah/tasks directory. Read full tracker records for EXOCOMP-4, 27, 30, 31, 32, 34, 115, 123, and 124. EXOCOMP-31/115 implement Exocomp.Node.Recovery.FailedService; EXOCOMP-27 supplies generic coordinator remediation lifecycle; EXOCOMP-32 supplies the active/degraded approval flow; EXOCOMP-34 and 123 are verification/qualification scopes. EXOCOMP-124 opened this task specifically for the remaining M4-CRIT-2 gap. Source evidence: apps/exocomp_node/lib/exocomp/node/a2a/codec.ex, skills/dispatcher.ex, and handlers/agent_card_handler.ex expose diagnosis/proposal only; the corresponding coordinator codec/dispatcher/card explicitly exclude remediation; apps/exocomp_node/test/integration/m4_acceptance_test.exs invokes FailedService.recover directly.

3. Remaining work/risks: Add an authenticated recovery skill/task contract across node and coordinator A2A surfaces; bridge detection and diagnosis into FailedService without bypassing task/audit/idempotency controls; advertise and validate only the intended recovery capability; add an end-to-end fixture-service test proving request, node execution, stability verification, artifacts/history, and audit correlation. Preserve the existing one-attempt and restricted-executor invariants.

4. Recommended next focus: feature.
---
author: oompah
created: 2026-07-27 16:18
---
Agent completed successfully in 189s (1990921 tokens)
---
author: oompah
created: 2026-07-27 16:18
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/default]
- Turns: 1, Tool calls: 27
- Tokens: 2.0M in / 6.4K out [2.0M total]
- Cost: $0.0000
- Exit: normal, Duration: 3m 9s
- Log: EXOCOMP-126__20260727T161550Z.jsonl
---
author: oompah
created: 2026-07-27 16:18
---
Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-27 16:19
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-27 16:19
---
Focus: Software Engineer
---
author: oompah
created: 2026-07-27 16:20
---
Understanding: The task requires wiring the failed-service recovery through the complete A2A task workflow (node + coordinator) rather than calling FailedService.recover directly as in m4_acceptance_test.exs. The gap: (1) node A2A codec/dispatcher only exposes diagnose/propose skills, not a recovery skill; (2) coordinator codec/dispatcher only exposes cluster health/diagnose; (3) m4_acceptance_test.exs calls FailedService.recover directly, bypassing the A2A HTTP surface.

Plan:
1. Add exocomp.service.recover skill to node: codec, dispatcher, agent card, new skill handler
2. Add exocomp.cluster.recover skill to coordinator: codec, dispatcher, agent card, new skill handler that routes to node via DiagnosticClient pattern  
3. Update the m4_acceptance_test to call through the A2A router (or write a new end-to-end test proving the full flow)
4. Run relevant make gates
---
<!-- COMMENTS:END -->
