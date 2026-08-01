---
id: EXOCOMP-201
type: task
status: In Progress
priority: 1
title: Implement the restricted profile-action helper
parent: EXOCOMP-186
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-195
labels: []
assignee: null
created_at: '2026-07-30T21:38:30.593722Z'
updated_at: '2026-08-01T15:21:17.413591Z'
work_branch: epic-EXOCOMP-186--task-EXOCOMP-201
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: b8ce017944128249b205044439d160a5a29da009a085f6b671c4e3e05e5b4fc0
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-01T14:16:37.424003+00:00'
  matched_identifiers: []
  evidence: "Based on my thorough investigation, I have completed the duplicate screening\
    \ for EXOCOMP-201.\n\n## Investigation Summary\n\nI searched the codebase comprehensively\
    \ for any existing, active tasks or implementations that might duplicate this\
    \ work:\n\n1. **Searched `.oompah/tasks` directory** - No matches for profile-action,\
    \ privileged helper, or related concepts\n2. **Searched `plans/` and `docs/`**\
    \ - Found the Mission Control planning document (`plans/mission-control.md`) but\
    \ no specific reference to a profile-action helper implementation\n3. **Searched\
    \ across all apps** - No existing helper code, systemctl integrations, or compiled\
    \ privileged binaries related to profile-action execution\n4. **Searched for related\
    \ keywords** - No matches for:\n   - \"profile-action\" or similar\n   - \"privileged\
    \ helper\"\n   - \"restart_failed_daemon\"\n   - \"profile recovery authority\"\
    \n   - Any related validation or Ceph daemon management code\n\n## Findings\n\n\
    - The Mission Control plan exists and establishes the architectural context\n\
    - This task is part of the EXOCOMP-186 (Mission Control) epic\n- No active, open\
    \ task covers the implementation of a restricted profile-action helper with:\n\
    \  - Versioned bounded stdin protocol\n  - Strict profile/action/unit validation\n\
    \  - Ceph unit restart capabilities\n  - Security restrictions against shell metacharacters\
    \ and arbitrary execution\n\nThe task appears to be a **new, original implementation**\
    \ not covered by any existing active task.\n\n---\n\n**Focus handoff: duplicate_detector**\n\
    \n**Duplicate preflight verdict: no_duplicate**\n\n**Matches: none**\n\n**Evidence:**\
    \ Comprehensive search of `.oompah/tasks`, `plans/`, and `apps/` directories found\
    \ no existing active task implementing a restricted profile-action helper. The\
    \ Mission Control planning document (`plans/mission-control.md`) establishes architectural\
    \ context but does not detail this privileged helper implementation. No compiled\
    \ helpers, Ceph daemon management code, or related validation logic exists in\
    \ the codebas"
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 0
  retry_after: null
oompah.agent_run_id: cd1d87c7-a2e8-45e3-beeb-79db0a7505e8
oompah.work_branch: epic-EXOCOMP-186--task-EXOCOMP-201
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-186--task-EXOCOMP-201
  base_branch: epic-EXOCOMP-186
  base_sha: ab25e80c7dae6afdf9e0b9f0f99ad82a0728462b
  updated_at: '2026-08-01T15:09:04.884275+00:00'
oompah.task_costs:
  total_input_tokens: 138
  total_output_tokens: 4578
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 138
      output_tokens: 4578
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 138
    output_tokens: 4578
    cost_usd: 0.0
    recorded_at: '2026-08-01T14:16:37.414136+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-201__20260801T141435Z
    provider_id: prov-651d553c
    provider_name: Claude
    model_id: haiku
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-186--task-EXOCOMP-201
    source_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
    completed_at: '2026-08-01T14:16:37.431408+00:00'
---
## Summary

Plan: plans/mission-control.md, profile recovery authority.

Deliverable: Add a small compiled privileged helper with a versioned bounded stdin protocol and no command-line arguments.

Acceptance criteria:
- Accept only shipped profile IDs, typed action IDs, and strictly validated target unit names.
- Ceph v1 supports only restart_failed_daemon for recognized Ceph unit forms.
- Recheck that the target unit is loaded and already inactive or failed before executing fixed systemctl argv.
- Reject active units, unknown actions, oversized input, extra fields, malformed encoding, and shell metacharacters.
- Never invoke a shell or accept an arbitrary executable or argument list.

Tests: Add parser and validator unit tests plus negative tests for injection, malformed requests, active units, non-Ceph units, timeout, and subprocess failure; run the focused Make gate added by the task.

Out of scope: Installer integration, coordinator policy, broad Ceph repair, and Mission Control.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 14:14
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 14:14
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-01 14:16
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/haiku]
- Turns: 47, Tool calls: 25
- Tokens: 138 in / 4.6K out [4.7K total]
- Cost: $0.0000
- Exit: normal, Duration: 2m 10s
- Log: EXOCOMP-201__20260801T141435Z.jsonl
---
author: oompah
created: 2026-08-01 15:09
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-08-01 15:09
---
Focus: Security Auditor
---
author: oompah
created: 2026-08-01 15:09
---
Understanding: implement a versioned, bounded stdin-only privileged helper that allowlists shipped profile/action IDs and Ceph unit forms, rechecks inactive/failed state, and executes only fixed systemctl argv; add parser/validator and negative security tests, then run the focused Make gate.
---
author: oompah
created: 2026-08-01 15:21
---
Implementation: added apps/exocomp_node/priv/profile_action_helper.{h,c} and native tests, hardened Make targets build-profile-action-helper/test-profile-action-helper, and documented the bounded stdin protocol and execution boundary in docs/profile-action-helper.md. Production execution uses sanitized fixed environment, bounded output, hard timeout, and no shell/PATH lookup.
---
author: oompah
created: 2026-08-01 15:21
---
Discovery: the parent profile registry is compiled/static and currently exposes default v1; no helper existed. The secure boundary is implemented as a standalone C helper with a fixed Ceph v1 capability table, strict ASCII tab protocol, allowlisted daemon-unit grammar, exact LoadState/ActiveState recheck, and direct fixed-path execve.
---
<!-- COMMENTS:END -->
