---
id: EXOCOMP-9
type: feature
status: In Progress
priority: 1
title: Implement node configuration, identity, and mTLS startup
parent: EXOCOMP-1
children: []
blocked_by:
- EXOCOMP-7
labels:
- focus-complete:duplicate_detector
- needs:feature
assignee: null
created_at: '2026-07-23T19:08:54.530229Z'
updated_at: '2026-07-23T20:35:16.883411Z'
work_branch: epic-EXOCOMP-1
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 8451c540-7bc6-458e-a46d-20a782296679
oompah.work_branch: epic-EXOCOMP-1
oompah.task_costs:
  total_input_tokens: 478936
  total_output_tokens: 7625
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 478936
      output_tokens: 7625
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 478936
    output_tokens: 7625
    cost_usd: 0.0
    recorded_at: '2026-07-23T20:33:24.937442+00:00'
---
## Summary

Plan: [Milestone 1 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-1-node-agent.md)

Goal
Implement node configuration, identity, and mTLS startup.

Implementation
Implement versioned JSON configuration and environment overrides for node ID, listen address, certificates, trust root, diagnostic service allow-list, llama paths/checksums, and timeouts; validate certificate identity and secure private-key permissions before starting the operational listener.

Testing
Test missing and malformed config, unknown versions, bad permissions, invalid chains, wrong SAN/node ID, atomic reload, and fixture certificates.

Acceptance Criteria
- [ ] Insecure or inconsistent identity prevents listener startup.
- [ ] Valid fixture identity starts the TLS listener.
- [ ] Secrets and key paths are redacted from errors and logs.
- [ ] Focused configuration and TLS tests pass.

Quality Gate
Run the focused tests and all repository Make targets affected by this change.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-23 20:27
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 20:27
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 20:33
---
Agent completed successfully in 345s (486561 tokens)
---
author: oompah
created: 2026-07-23 20:33
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/default]
- Turns: 1, Tool calls: 29
- Tokens: 478.9K in / 7.6K out [486.6K total]
- Cost: $0.0000
- Exit: normal, Duration: 5m 45s
- Log: EXOCOMP-9__20260723T202742Z.jsonl
---
author: oompah
created: 2026-07-23 20:33
---
Agent completed without closing this issue (345s (486561 tokens)). Escalating from 'default' to 'standard'. Retrying in 10s (1/3).
---
author: oompah
created: 2026-07-23 20:33
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-23 20:33
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 20:34
---
Understanding: Acting as Duplicate Investigator for EXOCOMP-9 (Implement node configuration, identity, and mTLS startup). Searched all sibling M1 tasks (EXOCOMP-7 through EXOCOMP-13), reviewed plans/milestone-1-node-agent.md, and checked the prior EXOCOMP-7 duplicate investigator's comprehensive 47-task scan. No duplicate found.
---
author: oompah
created: 2026-07-23 20:35
---
Focus handoff: duplicate_detector

**Outcome:** No duplicate confirmed. EXOCOMP-9 is unique with no overlap in the existing task graph.

**Evidence reviewed:**
- Reviewed EXOCOMP-7 (scaffold, Done): covers umbrella, OTP apps, Make gates — no config/identity/TLS implementation
- Reviewed EXOCOMP-8 (A2A protocol types, In Progress): covers HTTP+JSON codecs, Agent Card, Message/Task types — not configuration loading or mTLS startup
- Reviewed EXOCOMP-10 (Linux/systemd collectors): covers /proc, /sys, systemctl — not identity or TLS
- Reviewed EXOCOMP-11 (llama.cpp supervision): covers model process supervision — not config or TLS
- Reviewed EXOCOMP-12 (Node A2A service): covers exposing HTTP A2A endpoints — depends on mTLS but does not implement config loading, identity validation, or key permission checks
- Reviewed EXOCOMP-13 (M1 verification): covers end-to-end acceptance testing — not implementation
- The EXOCOMP-7 duplicate investigator ran a 47-task scan and found EXOCOMP-9 to be a distinct task
- EXOCOMP-7 (blocker) is now Done, clearing the dependency for EXOCOMP-9

**Relevant files:**
- plans/milestone-1-node-agent.md — 'Runtime Configuration' section (lines ~56–78) and 'Failure and Security Behavior' (lines ~151–163) describe EXOCOMP-9 scope
- Branch epic-EXOCOMP-1 has the scaffold from EXOCOMP-7 (apps/exocomp_core, apps/exocomp_node, Makefile, mix.exs)

**Remaining work:**
1. Implement versioned JSON config loader with env overrides (node ID, listen address, cert/key/trust paths, diagnostic allow-list, llama paths/checksums, timeouts)
2. Validate config schema version; reject unknown versions
3. Validate certificate chain and SAN matches node ID
4. Enforce private-key file permissions (no group/world-readable)
5. Start mTLS Bandit/Plug listener only after all checks pass
6. Redact key paths and cert content from errors and logs
7. Add focused ExUnit tests: missing config, malformed config, unknown version, bad permissions, invalid chain, wrong SAN/node ID, atomic reload, fixture certificates
8. Run make test, make lint, make fmt-check

**Risks:**
- Fixture certificates must be generated for test use; scripts or a mix task may be needed
- The TLS listener setup ties into EXOCOMP-12 (A2A service); EXOCOMP-9 should provide the listener foundation, not the full A2A routing
- Private-key permission checks use POSIX file stat — needs Linux test environment or mocking

**Recommended next focus:** feature — straightforward Elixir/OTP implementation of config loading, identity validation, and mTLS Bandit startup
---
<!-- COMMENTS:END -->
