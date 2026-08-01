---
id: EXOCOMP-159
type: task
status: In Progress
priority: 1
title: Implement the coordinator exocomp.cluster.chat skill
parent: EXOCOMP-132
children: []
blocked_by:
- EXOCOMP-145
- EXOCOMP-139
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:16:17.558974Z'
updated_at: '2026-08-01T12:38:52.524937Z'
work_branch: epic-EXOCOMP-132--task-EXOCOMP-159
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 08c25940ce751cca2648d6e0ea31d3752d9b48a646b57a15a0dab31445053147
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-01T12:38:27.522933+00:00'
  matched_identifiers: []
  evidence: "Based on my comprehensive search of the codebase, I have found:\n\n1.\
    \ **EXOCOMP-159 is the decomposition task** for implementing the `exocomp.cluster.chat`\
    \ skill, which is part of Milestone 7 (Mission Control) as described in `plans/mission-control.md`.\n\
    \n2. **No duplicate task exists** in the repository. The specific feature described\
    \ in EXOCOMP-159's acceptance criteria:\n   - Add `exocomp.cluster.chat` to the\
    \ coordinator Agent Card and A2A dispatcher\n   - Build bounded model input from\
    \ system prompt, thread context, and diagnostics\n   - Call local OpenAI-compatible\
    \ inference endpoint\n   - Validate schema-constrained output with Markdown, citations,\
    \ and typed proposals\n\n3. **This is distinct from prior work**: Earlier milestones\
    \ (M1-M6) do not include this chat skill. Milestone 2 established the Agent Card\
    \ and A2A infrastructure with only `exocomp.cluster.health` and `exocomp.cluster.diagnose`.\
    \ EXOCOMP-159 adds a new skill specific to Mission Control conversations.\n\n\
    4. **No existing implementation**: Searches across `.oompah`, `docs`, `plans`,\
    \ and the entire repository show no existing implementation of `cluster.chat`\
    \ or related conversation infrastructure.\n\n5. **Related dependencies exist**:\
    \ The issue correctly identifies EXOCOMP-145 and EXOCOMP-139 as blockers, suggesting\
    \ this is properly positioned in the decomposition hierarchy.\n\n**Conclusion:**\
    \ EXOCOMP-159 is a fresh, specific implementation task with no active duplicate\
    \ in the tracker.\n\n---\n\n## Focus handoff: duplicate_detector\n\n**Duplicate\
    \ preflight verdict: no_duplicate**\n\n**Matches: none**\n\n**Evidence:** Comprehensive\
    \ search across `.oompah/tasks`, `docs`, and `plans` found no existing task covering\
    \ the `exocomp.cluster.chat` skill implementation. The mission-control.md design\
    \ document specifies this feature as part of Milestone 7, distinct from earlier\
    \ milestones' Agent Card capabilities. No repository code implements cluster conversation\
    \ reasoning, inference endpoint integration, or schema-validated proposa"
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 0
  retry_after: null
oompah.agent_run_id: 9f8d32f2-7e1d-4d03-b760-64328acff0bb
oompah.work_branch: epic-EXOCOMP-132--task-EXOCOMP-159
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-132--task-EXOCOMP-159
  base_branch: epic-EXOCOMP-132
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T12:38:50.250161+00:00'
oompah.task_costs:
  total_input_tokens: 10
  total_output_tokens: 874
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 10
      output_tokens: 874
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 10
    output_tokens: 874
    cost_usd: 0.0
    recorded_at: '2026-08-01T12:38:27.516573+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-159__20260801T123656Z
    provider_id: prov-651d553c
    provider_name: Claude
    model_id: haiku
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-132--task-EXOCOMP-159
    source_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
    completed_at: '2026-08-01T12:38:27.529728+00:00'
---
## Summary

Plan: plans/mission-control.md, Conversations and Cluster-Local Reasoning.

Deliverables:
- Add exocomp.cluster.chat to the coordinator Agent Card and A2A dispatcher.
- Build bounded model input from the fixed system prompt, recent thread context, and fresh typed diagnostics.
- Call the configured local OpenAI-compatible inference endpoint.
- Validate schema-constrained output containing Markdown, evidence citations, and at most one typed proposal.

Acceptance:
- Tests cover valid reply, no model configured, timeout, invalid/truncated schema, stale evidence, missing citation, oversized context, and model crash.
- The skill exposes no arbitrary command or file access.

Out of scope: Mission Control persistence and executing proposals.
Quality gate: focused coordinator/A2A tests plus make test, make fmt-check, and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 12:36
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 12:36
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-01 12:38
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/haiku]
- Turns: 40, Tool calls: 20
- Tokens: 10 in / 874 out [884 total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 38s
- Log: EXOCOMP-159__20260801T123656Z.jsonl
---
author: oompah
created: 2026-08-01 12:38
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-08-01 12:38
---
Focus: Maintenance Engineer
---
<!-- COMMENTS:END -->
