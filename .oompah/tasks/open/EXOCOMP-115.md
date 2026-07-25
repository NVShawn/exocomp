---
id: EXOCOMP-115
type: feature
status: Open
priority: 1
title: Implement exocomp work falsely marked Merged without delivery
parent: EXOCOMP-110
children: []
blocked_by:
- EXOCOMP-111
- EXOCOMP-112
- EXOCOMP-113
- EXOCOMP-114
labels: []
assignee: null
created_at: '2026-07-25T17:58:24.080768Z'
updated_at: '2026-07-25T19:03:17.214459Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Implement the scopes that never landed or never ran: EXOCOMP-31 automatic already-failed service recovery, EXOCOMP-45 operator/PKI/policy guides, EXOCOMP-46 upgrade/rollback/backup/removal lifecycle and tests, EXOCOMP-47 clean-host release qualification, and EXOCOMP-66 deterministic node/coordinator archives and build identity manifests. Build on the recovered EXOCOMP-110 branch, satisfy the original acceptance criteria, and run all relevant Make targets.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-25 19:03
---
Verification environment hint: the completed EXOCOMP-112 recovery proved the pinned Make gates work through the already-running Podman service. Create an empty ignored/temporary storage config, then run with CONTAINERS_STORAGE_CONF=<that-file>, XDG_RUNTIME_DIR=/home/shedwards/.oompah/tmp/<task>-runtime, DOCKER_HOST=, and CONTAINER_ENGINE='podman --remote --url unix:///run/user/1000/podman/podman.sock'. For make test, also pass _CONTAINER_USER_FLAG=--userns=keep-id. Remove the temporary config/runtime before committing. This passed fmt-check, lint, all 1,487 tests, both release builds, and smoke tests on EXOCOMP-112.
---
<!-- COMMENTS:END -->
