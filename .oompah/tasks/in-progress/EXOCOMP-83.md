---
id: EXOCOMP-83
type: task
status: In Progress
priority: null
title: Make LlamaServer crash tests portable in Alpine builder
parent: null
children: []
blocked_by: []
labels:
- focus-complete:duplicate_detector
assignee: null
created_at: '2026-07-24T01:03:42.852933Z'
updated_at: '2026-07-24T02:29:37.314514Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 45c72423-1de0-4805-a64e-304814c1e5dc
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
<!-- COMMENTS:END -->
