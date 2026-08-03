---
id: EXOCOMP-243
type: bug
status: Open
priority: 2
title: Remove peer-completion race from discovery polling test
parent: null
children: []
blocked_by: []
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-08-03T17:22:52.388724Z'
updated_at: '2026-08-03T17:28:40.828006Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
review_head: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 08c45398fd051cf1c3ffd50d5d7fb3fc0141712ef7815a361d42df4eb09927d0
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: f6ad4945-cfd1-426e-8ddf-8e61ca36e0d2
  claim_owner: 8a58fb27-42d0-40cf-8dc2-70615b9783dc
  claimed_at: '2026-08-03T17:28:31.763345+00:00'
  claim_expires_at: '2026-08-03T17:58:31.763345+00:00'
  retry_count: 0
  retry_after: null
  owner_resolved_at: null
  owner_login: null
  owner_resolution_reason: ''
oompah.agent_run_id: 8f0fa165-ccdd-48ab-b266-59889427dbae
---
## Summary

Triggered by: EXOCOMP-92

The full make test gate is nondeterministic in apps/exocomp_coordinator/test/exocomp/coordinator/multi_node_discovery_polling_test.exs. The test 'unreachable node retains previously verified addresses and increments failure counter' waits only for the unreachable echo result, then immediately asserts that independently scheduled foxtrot is healthy. Under valid task interleavings foxtrot remains :unknown for that instant and the gate fails. Synchronize on the peer outcome (or complete poller drain) before asserting it, while retaining assertions that the unreachable node preserves its verified address and increments its failure counter. Reproduce with repeated focused runs and verify make test and make lint pass.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-03 17:26
---
Operator workaround is validated and published in merge commit 24f84e9459c72cb9354dc47e6f531118e14fcfaa on epic-EXOCOMP-132. The test now waits for the independently scheduled peer result before asserting it. The focused case passed 50 repeat-until-failure runs; full make test passed 682 tests plus release smoke tests, and make lint passed. Permanent repair still belongs on the authoritative parent/main path, so this task is being returned to Open for normal server implementation/integration.
---
author: oompah
created: 2026-08-03 17:28
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-03 17:28
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->
