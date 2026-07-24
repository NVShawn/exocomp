---
id: EXOCOMP-89
type: feature
status: Done
priority: 1
title: Verify node mTLS identity and safely adopt resolved addresses
parent: EXOCOMP-15
children: []
blocked_by:
- EXOCOMP-88
labels:
- focus-complete:duplicate_detector
assignee: null
created_at: '2026-07-24T02:42:56.090929Z'
updated_at: '2026-07-24T03:31:35.052954Z'
work_branch: epic-EXOCOMP-2
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: a44df019-a626-4f60-a5ac-ed7e94641fca
oompah.work_branch: epic-EXOCOMP-2
oompah.task_costs:
  total_input_tokens: 515838
  total_output_tokens: 2419
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 515838
      output_tokens: 2419
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 515838
    output_tokens: 2419
    cost_usd: 0.0
    recorded_at: '2026-07-24T03:19:50.983157+00:00'
---
## Summary

Implement the authenticated node probe boundary for coordinator discovery. Connect to explicit DNS-resolved IP candidates while retaining the configured hostname as identity/SNI context, validate the peer chain against coordinator trust, and require the configured certificate_identity (for example the expected URI SAN) without consulting reverse DNS. Fetch and validate the node Agent Card and health response with a per-request timeout, trying multiple resolved addresses without allowing an identity mismatch to pass. Update Registry.addresses only after both DNS resolution and mTLS identity verification succeed; preserve the last verified addresses on DNS, transport, certificate, or payload failure. Return typed outcomes for healthy, degraded, timeout, unreachable, and identity mismatch, and emit redacted audit events. Add focused TLS tests for correct/wrong identity, multiple addresses, changed-address adoption, failed-change preservation, and malformed/failed Agent Card or health responses. Build on EXOCOMP-12 and EXOCOMP-14 and run affected Make targets.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-24 03:18
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 03:18
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-24 03:18
---
Understanding: Screening EXOCOMP-89 for duplication before any implementation. I will search existing tasks and project docs for authenticated coordinator probes, mTLS identity verification, resolved-address adoption, typed probe outcomes, and Agent Card/health validation; then inspect full candidate task records to determine whether any one task covers the same underlying work.
---
author: oompah
created: 2026-07-24 03:19
---
Discovery: Duplicate screening found no confirmed duplicate. Full tracker records reviewed: EXOCOMP-15 is the parent epic and explicitly decomposes authenticated probing into EXOCOMP-89; EXOCOMP-88 only resolves and stores DNS candidates without adopting Registry.addresses; EXOCOMP-90 owns scheduling/backoff/state transitions; EXOCOMP-91 owns bounded concurrent execution; EXOCOMP-92 owns cross-component integration verification. EXOCOMP-12 provides the node-side mTLS A2A/Agent Card service, while EXOCOMP-14 provides Inventory/Registry/Audit infrastructure. The milestone-2 plan specifically requires hostname identity context, no reverse-DNS trust, and address adoption only after DNS plus mTLS verification, which is uniquely EXOCOMP-89's implementation boundary.
---
author: oompah
created: 2026-07-24 03:19
---
Focus handoff: duplicate_detector

Outcome: No duplicate confirmed. EXOCOMP-89 is the distinct authenticated probe/address-adoption child of EXOCOMP-15 and should proceed to implementation.

Evidence and decisions: The required repository search found the governing contract in plans/milestone-2-coordinator.md lines 69-71: retain hostname identity context, never trust reverse DNS, and adopt address changes only after DNS resolution plus mTLS verification. The checkout has no .oompah/tasks directory, so full descriptions/comments were validated through tracker views. EXOCOMP-88 produces normalized candidate_addresses only; EXOCOMP-89 must authenticate and adopt them. EXOCOMP-12 supplies the node Agent Card/mTLS endpoint and EXOCOMP-14 supplies Registry/Audit. EXOCOMP-90, 91, and 92 separately own scheduling/state transitions, concurrency/isolation, and integration coverage.

Relevant files: plans/milestone-2-coordinator.md; apps/exocomp_coordinator/lib/exocomp/coordinator/ (Resolver, Registry, Audit, supervision); node-side A2A/TLS implementation from EXOCOMP-12.

Remaining work and risks: Implement explicit-IP TLS connections while preserving configured hostname for SNI/identity, validate trust chain and configured certificate_identity without reverse DNS, validate Agent Card and health payloads under per-request timeout across multiple candidates, expose typed outcomes, emit redacted audit events, and update Registry.addresses only after complete success while preserving prior verified addresses on every failure. Add focused TLS/payload/address-change tests and run affected Make targets. Identity mismatch must never be bypassed by trying another candidate as though it were merely unreachable.

Recommended next focus: feature.
---
author: oompah
created: 2026-07-24 03:19
---
Agent completed successfully in 87s (518257 tokens)
---
author: oompah
created: 2026-07-24 03:19
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/default]
- Turns: 1, Tool calls: 14
- Tokens: 515.8K in / 2.4K out [518.3K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 27s
- Log: EXOCOMP-89__20260724T031827Z.jsonl
---
author: oompah
created: 2026-07-24 03:19
---
Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-24 03:19
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 03:20
---
Focus: Test Engineer
---
author: oompah
created: 2026-07-24 03:20
---
Understanding: I am the Test Engineer for EXOCOMP-89. My role is to write focused tests for the authenticated node probe boundary: mTLS identity verification, safe address adoption, typed probe outcomes, and audit event emission. I will first explore the codebase to understand what implementation exists (from any prior feature agents), find existing test patterns, then write comprehensive tests covering: correct/wrong TLS identity, multiple resolved addresses, changed-address adoption and failed-change preservation, malformed/failed Agent Card or health responses, and all typed outcomes (healthy, degraded, timeout, unreachable, identity_mismatch). I will run the affected Make targets to verify tests pass before closing.
---
author: oompah
created: 2026-07-24 03:23
---
Discovery: The NodeProber module (EXOCOMP-89's feature) has not yet been implemented. Latest commit is EXOCOMP-88 (DNS Resolver). I will implement both the NodeProber module and its comprehensive test suite. Key files: apps/exocomp_coordinator/lib/exocomp/coordinator/ (Registry, Audit, Inventory.Node), test patterns from resolver_test.exs and audit_test.exs. Design: NodeProber uses injectable probe_fn (like Resolver's resolver_fn) so tests avoid real network. Outcomes: :healthy/:degraded/:timeout/:unreachable/:identity_mismatch. Identity mismatch halts probing immediately. Registry.addresses updated only on success; preserved on all failures.
---
author: oompah
created: 2026-07-24 03:31
---
Implementation: Added NodeProber module (apps/exocomp_coordinator/lib/exocomp/coordinator/node_prober.ex) and test suite (test/exocomp/coordinator/node_prober_test.exs). Key design decisions: (1) Injectable probe_fn following the Resolver pattern — tests inject a fake transport, production uses real mTLS client. (2) Identity mismatch halts the entire probe immediately and is not retried on other candidates. (3) Registry.addresses updated only when verified_addresses is non-empty; all failures preserve previous value. (4) Health status field determines :healthy vs :degraded outcome. (5) Audit events emitted for all outcomes including error_details for mismatch. (6) Audit/Registry unavailability (process exit) is caught and never propagates to callers.
---
author: oompah
created: 2026-07-24 03:31
---
Verification: make test passes cleanly — 59 coordinator tests pass (32 new NodeProber tests + 27 pre-existing), make lint passes with no new warnings. All 32 NodeProber test cases pass covering: correct/wrong identity, multiple addresses, changed-address adoption, failed-change preservation (no candidates, timeout, unreachable, mismatch), degraded health, malformed responses, all typed outcomes, audit events for every outcome type, Registry isolation between nodes, and probe_result struct completeness.
---
author: oompah
created: 2026-07-24 03:31
---
Completion: EXOCOMP-89 delivered. NodeProber module implements the authenticated node probe boundary per milestone-2-coordinator.md spec: explicit-IP TLS connections (injectable), hostname-as-SNI identity context, no reverse-DNS trust, typed outcomes (:healthy/:degraded/:timeout/:unreachable/:identity_mismatch), Registry.addresses adopted only after full verification, prior addresses preserved on all failure paths, redacted audit events via Audit.emit/3. 32 focused ExUnit tests cover all required scenarios. make test and make lint both pass. Pushed to epic-EXOCOMP-15.
---
<!-- COMMENTS:END -->
