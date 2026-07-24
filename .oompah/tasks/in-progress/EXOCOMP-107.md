---
id: EXOCOMP-107
type: task
status: In Progress
priority: null
title: Implement node-agent enrollment client, credential installer, and renewal scheduler
  (EXOCOMP-17 gap)
parent: null
children: []
blocked_by: []
labels: []
assignee: null
created_at: '2026-07-24T19:29:40.430811Z'
updated_at: '2026-07-24T22:20:33.381243Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 271b568f-6901-4d23-8cd8-8aca084211c3
---
## Summary

EXOCOMP-17 was marked Done but the node-side enrollment implementation was never delivered. M2-CRIT-3 and M2-CRIT-4 can only verify the coordinator-side path (token issuance, one-time consumption, replay rejection, PKI leaf cert from CSR). The following node-agent components are missing:\n\n- Enrollment client: node calls coordinator enrollment endpoint with node ID and CSR\n- Atomic credential installer: atomically writes received chain PEM + private key\n- Renewal scheduler: monitors cert expiry and triggers renewal before deadline\n\nEnd-to-end enrollment handshake tests (node calling coordinator enrollment endpoint) cannot run until this lands.\n\nSee gap note in apps/exocomp_coordinator/test/integration/m2_acceptance_test.exs moduledoc.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-24 22:20
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 22:20
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-24 22:20
---
Understanding: Screening EXOCOMP-107 for duplication before any implementation. I will search existing enrollment, node-agent, credential-installation, renewal, CSR, and EXOCOMP-17 tasks, then inspect the full descriptions/comments of plausible candidates. If no task already owns all of this node-side gap, I will record evidence and hand off to an implementation focus without modifying code.
---
<!-- COMMENTS:END -->
