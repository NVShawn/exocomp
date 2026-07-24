---
id: EXOCOMP-83
type: task
status: Open
priority: null
title: Make LlamaServer crash tests portable in Alpine builder
parent: null
children: []
blocked_by: []
labels: []
assignee: null
created_at: '2026-07-24T01:03:42.852933Z'
updated_at: '2026-07-24T02:28:13.849698Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Triggered by: EXOCOMP-75

make test fails in apps/exocomp_node/test/exocomp/node/llama_server_test.exs because kill_port_os_process/1 hard-codes /usr/bin/kill, which is absent from the pinned Alpine builder (kill is provided elsewhere by BusyBox). Replace the hard-coded path with a portable mechanism and verify the full Make test gate. Discovered while verifying EXOCOMP-75; coordinator and PKI tests pass.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

