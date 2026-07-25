---
id: EXOCOMP-111
type: chore
status: In Progress
priority: 1
title: Recover omitted M1 A2A codec and fixture work
parent: EXOCOMP-110
children: []
blocked_by: []
labels:
- focus-complete:duplicate_detector
- needs:chore
assignee: null
created_at: '2026-07-25T17:58:20.183018Z'
updated_at: '2026-07-25T18:31:39.156531Z'
work_branch: epic-EXOCOMP-110
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: c088e933-f5c4-4489-b6bc-9f8f2e575b3e
oompah.work_branch: epic-EXOCOMP-110
oompah.task_costs:
  total_input_tokens: 11
  total_output_tokens: 3503
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 11
      output_tokens: 3503
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 11
    output_tokens: 3503
    cost_usd: 0.0
    recorded_at: '2026-07-25T18:31:26.141248+00:00'
---
## Summary

Recover the stranded EXOCOMP-49 and EXOCOMP-51 commits onto the EXOCOMP-110 shared recovery branch based on current main. Preserve the later A2A router/type changes already on main while integrating JSON codec/version handling, protocol fixtures, and focused tests. Resolve conflicts semantically, run the affected Make targets and full project tests where available, and verify the recovered files are present in the recovery branch.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-25 18:29
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-25 18:30
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-25 18:31
---
Duplicate screening result: No duplicate confirmed.

EXOCOMP-111 is a unique task — it is a purpose-built child of the EXOCOMP-110 recovery epic and has no counterpart among existing tasks.

Reviewed candidates:
- EXOCOMP-49 (Implement A2A 1.0 JSON codecs, error mapping, and version handling) — Status: Needs Human. This is a SOURCE task whose work needs to be recovered, not a duplicate of EXOCOMP-111.
- EXOCOMP-51 (Pin A2A 1.0 fixture files and add comprehensive protocol test suite) — Status: Needs Human. Same situation — source task flagged for recovery via EXOCOMP-111.
- EXOCOMP-110 (Recover completed work omitted from merged epics) — parent epic of EXOCOMP-111; different scope (entire audit across all stranded tasks).
- EXOCOMP-112, 113, 114, 115, 116 — sibling children of EXOCOMP-110 covering different deliverable groups (benchmarks, acceptance/fault injection, governance, undelivered work, verification).

Evidence: Both EXOCOMP-49 and EXOCOMP-51 have comments dated 2026-07-25 18:29 explicitly directing recovery via EXOCOMP-111. The EXOCOMP-49 branch (stranded work) and EXOCOMP-51 branch (stranded work) are visible in local branches but not on main (git log shows neither EXOCOMP-49 nor EXOCOMP-51 commits landed on main). EXOCOMP-111 is the correct and sole vehicle for this recovery.

Focus handoff: duplicate_detector

Outcome: No duplicate. EXOCOMP-111 is uniquely scoped to recover EXOCOMP-49 (codec.ex, version.ex, Jason dep, Makefile Hex bootstrap) and EXOCOMP-51 (10 fixture JSON files, 4 ExUnit test modules) onto the epic-EXOCOMP-110 branch based on current main.

Relevant findings:
- Local branches EXOCOMP-49 and EXOCOMP-51 (marked +) exist and contain completed work that never merged to main
- Current branch is epic-EXOCOMP-110 (worktree confirmed) — correct landing target
- Main's latest commits show no A2A codec/version/fixture deliverables
- EXOCOMP-49 delivered: apps/exocomp_core/lib/exocomp/a2a/codec.ex, version.ex; tests; Jason dep in mix.exs; mix.lock; Makefile Hex bootstrap
- EXOCOMP-51 delivered: apps/exocomp_core/test/fixtures/a2a/ (10 JSON files); test/exocomp/a2a/fixture_test.exs, invalid_payload_test.exs, version_negotiation_test.exs, media_type_test.exs; parse_content_type patched to strip params; 103 tests total

Remaining work: Cherry-pick or merge EXOCOMP-49 and EXOCOMP-51 commits onto epic-EXOCOMP-110, resolve any conflicts semantically (preserve main's A2A router/type changes), run make test && make lint && make fmt-check, verify all recovered files present.

Risks: The A2A router/type changes already on main may conflict with codec.ex field mappings — semantic conflict resolution required. Hex bootstrap in Makefile may conflict if Makefile was modified on main.

Recommended next focus: chore (git recovery, conflict resolution, quality gate verification).
---
author: oompah
created: 2026-07-25 18:31
---
Agent completed successfully in 97s (3514 tokens)
---
author: oompah
created: 2026-07-25 18:31
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/default]
- Turns: 22, Tool calls: 15
- Tokens: 11 in / 3.5K out [3.5K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 37s
- Log: EXOCOMP-111__20260725T183001Z.jsonl
---
author: oompah
created: 2026-07-25 18:31
---
Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
<!-- COMMENTS:END -->
