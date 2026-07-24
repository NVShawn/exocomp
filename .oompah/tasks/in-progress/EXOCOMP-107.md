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
labels:
- focus-complete:duplicate_detector
assignee: null
created_at: '2026-07-24T19:29:40.430811Z'
updated_at: '2026-07-24T22:23:29.182394Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 841f1307-4e83-4d6d-a3f6-80c18e397c0c
oompah.task_costs:
  total_input_tokens: 799526
  total_output_tokens: 3354
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 799526
      output_tokens: 3354
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 799526
    output_tokens: 3354
    cost_usd: 0.0
    recorded_at: '2026-07-24T22:22:04.561964+00:00'
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
author: oompah
created: 2026-07-24 22:21
---
Discovery: Duplicate screening found no confirmed duplicate. The closest task is EXOCOMP-17, whose stated umbrella scope included node enrollment/renewal, but its full history shows the planner only created/delivered EXOCOMP-87 (coordinator-only CSR validation/leaf issuance) before EXOCOMP-17 was marked Merged. EXOCOMP-20 subsequently verified and documented the exact gap and created EXOCOMP-107 as corrective follow-up. Full histories reviewed for EXOCOMP-17, EXOCOMP-20, EXOCOMP-76, EXOCOMP-77, and EXOCOMP-87: EXOCOMP-76/77 supply coordinator token/PKI boundaries and explicitly exclude node-side enrollment; EXOCOMP-87 contains no HTTP/network/node client code. Tracker-state and source searches found no separate enrollment client, atomic credential installer, or renewal scheduler. Therefore archiving EXOCOMP-107 as duplicate-of:EXOCOMP-17 would leave known missing implementation unowned.
---
author: oompah
created: 2026-07-24 22:21
---
Focus handoff: duplicate_detector

Outcome: No duplicate confirmed. EXOCOMP-107 is a necessary gap-remediation task and should proceed to feature implementation.

Evidence and decisions: Searched the git-backed tracker branch oompah/state/proj-c260b117 plus plans/docs for enrollment, renewal, CSR, node-agent, credential installation, and scheduler terms. Full tracker histories reviewed: EXOCOMP-17 (intended umbrella but prematurely merged after delivering only child EXOCOMP-87), EXOCOMP-20 (acceptance work that explicitly found and filed this gap), EXOCOMP-76 (coordinator durable token service), EXOCOMP-77 (coordinator PKI/token integration expressly excluding node-side enrollment), and EXOCOMP-87 (pure coordinator CSR/leaf issuer with no HTTP/network code). Current source search under apps/exocomp_node and apps/exocomp_coordinator finds no enrollment client, credential installer, or renewal scheduler. The referenced M2 acceptance file is absent from this branch because EXOCOMP-107 currently tracks origin/main, but EXOCOMP-20's tracker history records that file and its gap note on the integrated epic branch.

Relevant files/areas: plans/milestone-2-coordinator.md; apps/exocomp_node/lib/exocomp/node/ identity/config/application code; coordinator EnrollmentToken and PKI.Issuer contracts from EXOCOMP-76/87; apps/exocomp_coordinator/test/integration/m2_acceptance_test.exs once prerequisite M2 commits are integrated.

Remaining work/risks: Feature implementation must first ensure this branch contains the merged coordinator token/PKI/issuer work, then add the node-local key/CSR enrollment client, crash-safe atomic chain+key installation preserving old valid credentials, expiry-driven authenticated renewal scheduling, coordinator enrollment/renewal HTTP boundaries if still absent, and focused/end-to-end tests. Preserve private-key locality, strict permissions, pinned-root bootstrap, replay rejection, and old-credential fallback on every failure.

Recommended next focus: feature. No repository files were changed; git status is clean.
---
author: oompah
created: 2026-07-24 22:22
---
Agent completed successfully in 104s (802880 tokens)
---
author: oompah
created: 2026-07-24 22:22
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/default]
- Turns: 1, Tool calls: 17
- Tokens: 799.5K in / 3.4K out [802.9K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 44s
- Log: EXOCOMP-107__20260724T222022Z.jsonl
---
author: oompah
created: 2026-07-24 22:22
---
Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-24 22:22
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-24 22:22
---
Focus: Security Auditor
---
author: oompah
created: 2026-07-24 22:22
---
Understanding: Security review will map the node enrollment, credential installation, and renewal trust boundaries against OWASP-style risks: bootstrap authentication/token replay, TLS server verification, CSR/node-ID binding, malicious or malformed certificate responses, private-key exposure, filesystem races/symlink attacks, crash consistency, renewal authentication, retry amplification, and secret logging. I will inspect the current branch and relevant plans/contracts, record actionable security acceptance criteria, and hand off to feature implementation because the node-side components are currently absent.
---
author: oompah
created: 2026-07-24 22:23
---
Discovery: The current branch is origin/main and contains none of the prerequisite coordinator enrollment/PKI modules; those exist only on origin/epic-EXOCOMP-2. That integrated branch exposes EnrollmentToken and PKI.Issuer as internal services but has no HTTP enrollment or renewal route, so a node client currently has no callable boundary. Existing apps/exocomp_node/lib/exocomp/node/identity.ex validates key mode, leaf-to-root path, and DNS SAN, but does not prove the private key matches the leaf certificate, rejects neither symlinks/non-regular key files nor ownership surprises, and reads only one leaf certificate (not a returned intermediate chain). These are security-critical requirements for the new installer rather than evidence that the requested components already exist.
---
<!-- COMMENTS:END -->
