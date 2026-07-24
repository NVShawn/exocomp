---
id: EXOCOMP-83
type: task
status: Done
priority: null
title: Make LlamaServer crash tests portable in Alpine builder
parent: null
children: []
blocked_by: []
labels:
- focus-complete:duplicate_detector
assignee: null
created_at: '2026-07-24T01:03:42.852933Z'
updated_at: '2026-07-24T02:38:43.001516Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: bcc9304b-2907-48d3-aa3c-8f807ce7072f
oompah.task_costs:
  total_input_tokens: 316433
  total_output_tokens: 2433
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 316433
      output_tokens: 2433
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 316433
    output_tokens: 2433
    cost_usd: 0.0
    recorded_at: '2026-07-24T02:29:43.452878+00:00'
---
## Summary

Triggered by: EXOCOMP-75

make test fails in apps/exocomp_node/test/exocomp/node/llama_server_test.exs because kill_port_os_process/1 hard-codes /usr/bin/kill, which is absent from the pinned Alpine builder (kill is provided elsewhere by BusyBox). Replace the hard-coded path with a portable mechanism and verify the full Make test gate. Discovered while verifying EXOCOMP-75; coordinator and PKI tests pass.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-24 02:28
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 02:28
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-24 02:28
---
Understanding: Screening whether the Alpine LlamaServer crash-test failure caused by hard-coded /usr/bin/kill is already covered by an existing task. I will search task records and project docs by LlamaServer, Alpine, kill_port_os_process, and /usr/bin/kill, then inspect any candidate task's full state before deciding duplicate vs implementation handoff.
---
author: oompah
created: 2026-07-24 02:29
---
Discovery: No duplicate confirmed. EXOCOMP-64 is the closest task: it created the focused LlamaServer crash tests and explicitly chose System.cmd kill -TERM for OS-process simulation, but its completed scope was the original 11-scenario suite and it reported tests passing in its then-current environment. EXOCOMP-62 implemented the LlamaServer supervisor and only smoke tests; EXOCOMP-75 implemented coordinator PKI and merely discovered/filed this unrelated Alpine failure. Repository evidence pinpoints apps/exocomp_node/test/exocomp/node/llama_server_test.exs:61-65, where kill_port_os_process/1 invokes /usr/bin/kill. No reviewed task covers making that helper BusyBox/Alpine-portable or rerunning the current full make test gate.
---
author: oompah
created: 2026-07-24 02:29
---
Focus handoff: duplicate_detector

Outcome: Duplicate screening found no duplicate; EXOCOMP-83 is a distinct portability regression and should proceed to implementation.

Evidence reviewed: EXOCOMP-64 created the LlamaServer crash tests and introduced the hard-coded System.cmd("/usr/bin/kill", ...), but did not cover Alpine portability. EXOCOMP-62 covers the LlamaServer OTP supervisor, not this test helper. EXOCOMP-75 covers coordinator PKI and is only the source of the full-gate discovery. Project docs confirm make test runs in an unprivileged Alpine builder.

Relevant file: apps/exocomp_node/test/exocomp/node/llama_server_test.exs, helper kill_port_os_process/1 around lines 61-65; its two crash tests exercise the helper.

Remaining work/risks: replace the absolute executable path with a portable kill mechanism while preserving TERM semantics and deterministic crash/restart assertions; use existing Make targets and run the full make test gate. Ensure the regression is demonstrably covered in the pinned Alpine builder rather than only on the host.

Recommended next focus: test.
---
author: oompah
created: 2026-07-24 02:29
---
Agent completed successfully in 74s (318866 tokens)
---
author: oompah
created: 2026-07-24 02:29
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/default]
- Turns: 1, Tool calls: 15
- Tokens: 316.4K in / 2.4K out [318.9K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 14s
- Log: EXOCOMP-83__20260724T022831Z.jsonl
---
author: oompah
created: 2026-07-24 02:29
---
Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-24 02:29
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-24 02:29
---
Focus: Test Engineer
---
author: oompah
created: 2026-07-24 02:30
---
Understanding: The LlamaServer crash-test helper hard-codes /usr/bin/kill, which is unavailable in the pinned Alpine builder. I will inspect Make targets and test conventions, reproduce the failure, replace the absolute path with a PATH-resolved portable mechanism while preserving TERM behavior, then run focused and full make test gates.
---
author: oompah
created: 2026-07-24 02:30
---
Discovery: apps/exocomp_node/test/exocomp/node/llama_server_test.exs:61 hard-codes System.cmd("/usr/bin/kill", ...). The helper is exercised by two behavioral crash tests covering restart/recovery and supervisor isolation. The pinned make test target runs these inside Alpine 3.24.1, where PATH-based BusyBox kill is available but /usr/bin/kill is not.
---
author: oompah
created: 2026-07-24 02:33
---
Run #1 [attempt=1, profile=standard, role=standard -> Codex/default]
- Turns: 0, Tool calls: 25
- Tokens: 0 in / 0 out [0 total]
- Cost: $0.0000
- Exit: terminated, Duration: 3m 19s
- Log: EXOCOMP-83__20260724T022954Z.jsonl
---
author: oompah
created: 2026-07-24 02:33
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 02:33
---
Focus: Test Engineer
---
author: oompah
created: 2026-07-24 02:34
---
Understanding: Picking up the interrupted test-focused run. I will inspect any partial worktree changes, replace the hard-coded /usr/bin/kill with a PATH-resolved portable TERM mechanism, prove the existing crash tests exercise the regression, run focused and full Make test gates in the pinned Alpine builder, then commit, push, and close the task.
---
author: oompah
created: 2026-07-24 02:34
---
Discovery: The worktree is clean and no partial fix was left behind. apps/exocomp_node/test/exocomp/node/llama_server_test.exs:64 invokes System.cmd("/usr/bin/kill", ...); the helper is behaviorally exercised by the restart/recovery and supervisor-isolation crash tests. make test is the project-defined Alpine builder gate, and Alpine exposes BusyBox kill through PATH rather than /usr/bin/kill.
---
author: oompah
created: 2026-07-24 02:34
---
Implementation: Updated kill_port_os_process/1 to call System.cmd("kill", ...) instead of the non-portable absolute /usr/bin/kill path. This preserves explicit TERM semantics and lets Erlang resolve the executable from PATH, where Alpine’s BusyBox kill is available. The two existing behavioral crash tests remain the regression coverage and exercise the helper end to end.
---
author: oompah
created: 2026-07-24 02:37
---
Verification: In the pinned Alpine 3.24.1 builder, the focused LlamaServer suite passes 8/8 with the fix. Negative regression proof: temporarily restoring /usr/bin/kill makes exactly the two crash tests fail with Erlang :enoent/invalid port name; restoring PATH-based kill makes them pass. Full make test also passes: bench 55, core 2, coordinator 1, node 49 (10 integration/systemd excluded), followed by successful node/coordinator release assembly and smoke startup.
---
author: oompah
created: 2026-07-24 02:38
---
Completion: Delivered and pushed commit 8c067f2 on origin/EXOCOMP-83. LlamaServer crash tests now resolve kill through PATH for BusyBox/Alpine portability while retaining TERM behavior. Focused regression proof and the full make test/release smoke gate pass; the branch is clean and up to date with origin. No follow-up work identified.
---
<!-- COMMENTS:END -->
