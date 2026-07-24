---
id: EXOCOMP-107
type: task
status: Open
priority: null
title: Implement node-agent enrollment client, credential installer, and renewal scheduler
  (EXOCOMP-17 gap)
parent: null
children: []
blocked_by: []
labels: []
assignee: null
created_at: '2026-07-24T19:29:40.430811Z'
updated_at: '2026-07-24T22:20:12.066331Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

EXOCOMP-17 was marked Done but the node-side enrollment implementation was never delivered. M2-CRIT-3 and M2-CRIT-4 can only verify the coordinator-side path (token issuance, one-time consumption, replay rejection, PKI leaf cert from CSR). The following node-agent components are missing:\n\n- Enrollment client: node calls coordinator enrollment endpoint with node ID and CSR\n- Atomic credential installer: atomically writes received chain PEM + private key\n- Renewal scheduler: monitors cert expiry and triggers renewal before deadline\n\nEnd-to-end enrollment handshake tests (node calling coordinator enrollment endpoint) cannot run until this lands.\n\nSee gap note in apps/exocomp_coordinator/test/integration/m2_acceptance_test.exs moduledoc.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

