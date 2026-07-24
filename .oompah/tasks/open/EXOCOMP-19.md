---
id: EXOCOMP-19
type: feature
status: Open
priority: 1
title: Expose coordinator cluster A2A service
parent: EXOCOMP-2
children: []
blocked_by:
- EXOCOMP-15
- EXOCOMP-18
labels:
- focus-complete:duplicate_detector
- focus-complete:chore
- needs:feature
assignee: null
created_at: '2026-07-23T19:09:32.508992Z'
updated_at: '2026-07-24T18:30:34.717494Z'
work_branch: epic-EXOCOMP-2
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 2cba563c-1f5e-4ab9-8244-614994f682fe
oompah.work_branch: epic-EXOCOMP-2
oompah.task_costs:
  total_input_tokens: 396055
  total_output_tokens: 6422
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 396055
      output_tokens: 6422
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 395947
    output_tokens: 1827
    cost_usd: 0.0
    recorded_at: '2026-07-24T18:25:38.164152+00:00'
  - profile: default
    model: unknown
    input_tokens: 108
    output_tokens: 4595
    cost_usd: 0.0
    recorded_at: '2026-07-24T18:30:33.197521+00:00'
---
## Summary

Plan: [Milestone 2 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-2-coordinator.md)

Goal
Expose coordinator cluster A2A service.

Implementation
Publish a coordinator Agent Card with exocomp.cluster.health and exocomp.cluster.diagnose; support A2A send/get/list/cancel using shared types; authorize inventory selections; aggregate bounded partial results; declare streaming/push unsupported; expose no remediation execution.

Testing
Run shared protocol fixtures plus tests for selection authorization, partial results, cancellation, mTLS, unsupported capabilities, version negotiation, and concurrent callers.

Acceptance Criteria
- [ ] Agent Card and endpoints conform to pinned A2A 1.0 fixtures.
- [ ] Authenticated callers receive correlated cluster results.
- [ ] Unauthorized node selection is rejected.
- [ ] No execution/remediation skill is reachable.
- [ ] Focused tests pass.

Quality Gate
Run the focused tests and all repository Make targets affected by this change.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-24 18:24
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 18:24
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-24 18:24
---
Understanding: Screening EXOCOMP-19 for duplication before any implementation. I will search native tasks and project design/docs for coordinator cluster A2A scope, then inspect each plausible task's full description/comments and either archive as duplicate or hand off with evidence.
---
author: oompah
created: 2026-07-24 18:25
---
Discovery: No duplicate confirmed. Closest candidates were read in full: EXOCOMP-18 owns internal coordinator fan-out/orchestration, correlation, partial-result collection, cancellation propagation, and audit; it explicitly defines EXOCOMP-19 as the distinct external Agent Card/HTTP authorization surface. EXOCOMP-12 is the analogous node A2A service, but targets node-only skills and node task handling. EXOCOMP-15 owns DNS discovery/polling, and EXOCOMP-20 is milestone-wide verification. The authoritative plan's A2A Interface section uniquely assigns the coordinator Agent Card plus message send and task get/list/cancel, version negotiation, bounded history, and unsupported streaming/push to this task.
---
author: oompah
created: 2026-07-24 18:25
---
Focus handoff: duplicate_detector

Outcome: Duplicate screening found no duplicate; EXOCOMP-19 remains valid and needs implementation.

Evidence: The required repository search was run for coordinator/A2A/cluster skill terms. This checkout has no .oompah/tasks directory, so full candidate descriptions and comments were verified with tracker views. EXOCOMP-18 is complementary internal orchestration and explicitly treats EXOCOMP-19 as its external service layer; EXOCOMP-12 is the node-side analogue; EXOCOMP-15 is DNS/polling; EXOCOMP-20 is end-to-end milestone verification. plans/milestone-2-coordinator.md lines 118-158 separates Coordinator Task Flow from the A2A Interface and assigns this task the cluster Agent Card, send/get/list/cancel, version negotiation, bounded history, and unsupported streaming/push behavior.

Relevant files/decisions: plans/milestone-2-coordinator.md (Coordinator Task Flow and A2A Interface); apps/exocomp_core shared A2A types/fixtures; apps/exocomp_node provides the prior node-service pattern; apps/exocomp_coordinator is the implementation surface. Preserve the boundary: handlers authorize inventory selections and delegate to EXOCOMP-18 orchestration; do not expose remediation execution.

Remaining work/risks: Implement and test the coordinator service against pinned A2A 1.0 fixtures, including mTLS, authorization, correlated partial results, cancellation, unsupported capabilities, version negotiation, and concurrency. The branch reports behind origin/main and contains pre-existing untracked apps/exocomp_coordinator/tmp/ content; the implementation agent should reconcile prerequisites and preserve that content.

Recommended next focus: feature.
---
author: oompah
created: 2026-07-24 18:25
---
Agent completed successfully in 74s (397774 tokens)
---
author: oompah
created: 2026-07-24 18:25
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/default]
- Turns: 1, Tool calls: 12
- Tokens: 395.9K in / 1.8K out [397.8K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 14s
- Log: EXOCOMP-19__20260724T182427Z.jsonl
---
author: oompah
created: 2026-07-24 18:25
---
Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-24 18:25
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 18:25
---
Focus: Maintenance Engineer
---
author: oompah
created: 2026-07-24 18:28
---
Understanding: Dispatched as Maintenance Engineer. The task is EXOCOMP-19: expose coordinator cluster A2A service. After a git pull --rebase to sync 29 commits from origin/main, the code base now has a fully-implemented node A2A service (apps/exocomp_node) with: A2ARouter (Plug.Router), NodeTaskRegistry, A2A.Codec, AgentCardHandler, and Skills.Dispatcher — all with tests. The coordinator app (apps/exocomp_coordinator) has only an empty application.ex and one test. This is fundamentally a feature implementation task, not a maintenance task. My maintenance role will: (1) update the coordinator mix.exs to add the same dependencies the node uses (bandit, plug, jason), ensuring the feature agent can implement against the right deps, then (2) hand off to a feature agent with full context.
---
author: oompah
created: 2026-07-24 18:28
---
Discovery: After rebase to origin/main, the codebase has a fully-implemented node A2A service to use as a pattern. Key files: apps/exocomp_node/lib/exocomp/node/a2a_router.ex (Plug.Router with mTLS + version gating), apps/exocomp_node/lib/exocomp/node/a2a/codec.ex (encode/decode), apps/exocomp_node/lib/exocomp/node/task_registry.ex (GenServer bounded history), apps/exocomp_node/lib/exocomp/node/handlers/agent_card_handler.ex. The coordinator app (apps/exocomp_coordinator) has only application.ex and one test. The coordinator mix.exs is missing bandit, plug, and jason — the same HTTP deps the node uses, which are already in mix.lock. Maintenance work: add those deps to coordinator mix.exs. Feature work (for next agent): implement coordinator A2A router, agent card, task registry, codec, config/listener — following node patterns but exposing exocomp.cluster.health and exocomp.cluster.diagnose, and delegating to EXOCOMP-18 orchestration.
---
author: oompah
created: 2026-07-24 18:29
---
Implementation: Added bandit, plug, and jason deps to apps/exocomp_coordinator/mix.exs and expanded extra_applications to include inets, crypto, public_key, ssl. These are required for the A2A HTTP service implementation and were already pinned in mix.lock. Committed and pushed to epic-EXOCOMP-2. The coordinator tmp/ directory (apps/exocomp_coordinator/tmp/) contains ExUnit artifacts from prior test runs (Exocomp.Coordinator.AuditTest and Exocomp.Coordinator.InventoryTest tmp dirs) suggesting those modules were implemented and tested in a parallel environment. They are preserved as untracked; the feature agent should evaluate whether to commit or .gitignore them.
---
author: oompah
created: 2026-07-24 18:30
---
Focus handoff: chore

Outcome: Maintenance work complete. Updated apps/exocomp_coordinator/mix.exs to add bandit, plug, jason, and OTP networking/crypto extra_applications. Branch synced from origin/main (was 29 commits behind). Committed and pushed to epic-EXOCOMP-2.

Relevant files/decisions:
- apps/exocomp_coordinator/mix.exs — updated with HTTP deps (bandit ~>1.0, plug ~>1.17, jason ~>1.4)
- apps/exocomp_node/lib/exocomp/node/a2a_router.ex — A2ARouter pattern to follow (Plug.Router with mTLS authenticate_mtls plug, require_a2a_version plug, JSONBodyParser, routes: GET /.well-known/agent-card.json, POST /message:send, GET /tasks, GET /tasks/:id, POST /tasks/:id [with :cancel suffix], POST /message/stream → UnsupportedOperationError, POST /tasks/:id/resubscribe → UnsupportedOperationError)
- apps/exocomp_node/lib/exocomp/node/a2a/codec.ex — Codec encode/decode helpers
- apps/exocomp_node/lib/exocomp/node/task_registry.ex — TaskRegistry GenServer (bounded history, get/list/submit/cancel/transition/register_worker)
- apps/exocomp_node/lib/exocomp/node/handlers/agent_card_handler.ex — AgentCardHandler pattern
- apps/exocomp_node/lib/exocomp/node/listener.ex — Bandit mTLS HTTPS listener GenServer
- apps/exocomp_coordinator/tmp/ — Untracked ExUnit tmp dirs from prior test runs of Exocomp.Coordinator.AuditTest and Exocomp.Coordinator.InventoryTest; investigate whether these represent in-progress implementation artifacts

Remaining work/risks:
1. Implement Exocomp.Coordinator.A2ARouter exposing exocomp.cluster.health and exocomp.cluster.diagnose (NOT remediation execution per plans/milestone-2-coordinator.md)
2. Implement Exocomp.Coordinator.Handlers.AgentCardHandler with cluster skills
3. Reuse or mirror TaskRegistry for coordinator task lifecycle (or alias from node if shared)
4. Implement Codec for coordinator (cluster skills use different params than node skills)
5. Implement authorization of inventory selections (reject unauthorized node selections)
6. Aggregate bounded partial results from nodes (EXOCOMP-18 orchestration delegate)
7. Implement Exocomp.Coordinator.Config and Listener (mirrors node pattern; coordinator.json template in release/templates/coordinator.json uses bind/tls/pki fields, different from node config shape)
8. Tests: selection authorization, partial results, cancellation, mTLS, unsupported capabilities, version negotiation, concurrent callers, no-remediation path
9. Check apps/exocomp_coordinator/tmp/ for any usable in-progress code
10. Run make test and make lint after implementation

Architecture boundary: handlers authorize inventory selections and delegate to EXOCOMP-18 orchestration; MUST NOT expose remediation execution skills.

Recommended next focus: feature.
---
author: oompah
created: 2026-07-24 18:30
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/default]
- Turns: 0, Tool calls: 86
- Tokens: 108 in / 4.6K out [4.7K total]
- Cost: $0.0000
- Exit: terminated, Duration: 4m 43s
- Log: EXOCOMP-19__20260724T182552Z.jsonl
---
<!-- COMMENTS:END -->
