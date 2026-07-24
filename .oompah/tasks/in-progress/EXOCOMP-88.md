---
id: EXOCOMP-88
type: feature
status: In Progress
priority: 1
title: Resolve inventory hostnames into normalized address candidates
parent: EXOCOMP-15
children: []
blocked_by: []
labels:
- focus-complete:duplicate_detector
assignee: null
created_at: '2026-07-24T02:42:48.305068Z'
updated_at: '2026-07-24T03:07:23.539352Z'
work_branch: epic-EXOCOMP-2
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: d2153cdd-a31c-43cb-8b89-1d04f7b6c960
oompah.work_branch: epic-EXOCOMP-2
oompah.task_costs:
  total_input_tokens: 22
  total_output_tokens: 4926
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 22
      output_tokens: 4926
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 22
    output_tokens: 4926
    cost_usd: 0.0
    recorded_at: '2026-07-24T02:52:32.459298+00:00'
---
## Summary

Implement the coordinator DNS discovery component described in plans/milestone-2-coordinator.md. Add a supervised, dependency-injectable resolver that reads configured hostnames from Exocomp.Coordinator.Inventory, resolves all IPv4/IPv6 addresses with normal DNS (never reverse DNS), normalizes/deduplicates deterministic results, and reports resolution success/failure as structured audit/health events. Keep resolved results as candidates until an authenticated probe approves adoption; DNS success alone must not replace Registry.addresses. Cover successful resolution, multiple addresses, address-set changes, empty/NXDOMAIN/timeout/error results, and refresh after inventory changes using deterministic resolver fakes. Integrate with the EXOCOMP-14 Inventory/Registry/Audit foundation and run focused tests plus affected Make targets.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-24 02:49
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 02:49
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-24 02:51
---
Understanding: Duplicate screening initiated for EXOCOMP-88 (Resolve inventory hostnames into normalized address candidates). Searching for any existing tasks covering DNS hostname resolution, IPv4/IPv6 address normalization/deduplication, and address candidate tracking in the coordinator context.
---
author: oompah
created: 2026-07-24 02:51
---
Discovery: No duplicate confirmed. Full review of all candidate tasks:

**EXOCOMP-14 (Done):** Scaffolds coordinator Inventory (JSON parsing), ETS Registry, Audit sink, and Health — foundational infrastructure only. No DNS resolver, no address normalization, no resolution event reporting. EXOCOMP-88 explicitly builds on this foundation.

**EXOCOMP-15 (Open, parent):** Broader task covering DNS discovery AND concurrent node polling. EXOCOMP-88 is a properly decomposed child of EXOCOMP-15 for the specific DNS resolution sub-component.

**EXOCOMP-89 (Open, sibling):** Handles mTLS identity verification and adoption of resolved addresses — distinct from this task's scope. EXOCOMP-88 produces candidates; EXOCOMP-89 approves them.

**EXOCOMP-90/91/92 (Open, siblings):** Cover polling scheduling/backoff/state, bounded concurrency, and multi-node integration — none overlap with DNS resolution.

**EXOCOMP-16/17/18/19/20:** PKI, enrollment, orchestration, A2A service, milestone verification — no DNS resolution overlap.

EXOCOMP-88 uniquely owns: supervised DNS resolver GenServer, hostname-to-IPv4/IPv6 resolution (no reverse DNS), normalization/deduplication, candidate state management (candidates only, not direct Registry.addresses replacement), and audit/health events for resolution success/failure. This scope is not covered anywhere else in the task graph.
---
author: oompah
created: 2026-07-24 02:52
---
Focus handoff: duplicate_detector

**Outcome:** No duplicate confirmed. EXOCOMP-88 is a unique, well-scoped child task of EXOCOMP-15 covering DNS hostname resolution into address candidates. No existing task covers this specific functionality.

**Evidence reviewed:**
- EXOCOMP-14 (Done): inventory/registry/audit scaffold — no DNS resolver
- EXOCOMP-15 (Open): parent task for DNS discovery + polling (EXOCOMP-88 is a child)
- EXOCOMP-89 (Open): mTLS verification and address adoption — sibling, not duplicate
- EXOCOMP-90/91/92: poll scheduling, concurrency, integration — no DNS overlap
- EXOCOMP-16/17/18/19/20: PKI, enrollment, orchestration, A2A service — no overlap

**Relevant files:**
- plans/milestone-2-coordinator.md — §Inventory and Discovery: 'Normal DNS resolution supplies addresses. The coordinator retains the hostname as identity context and does not trust reverse DNS. Address changes are adopted on successful resolution and mTLS verification.'
- apps/exocomp_coordinator/lib/exocomp/coordinator/application.ex — OTP supervisor stub (from EXOCOMP-14)
- origin/EXOCOMP-14 (commit 7ab7dc6) — has Inventory, Registry, Audit, Health modules; feature agent should rebase on this
- EXOCOMP-89 — sibling task; EXOCOMP-88's candidates feed into EXOCOMP-89's adoption logic

**Remaining work:**
1. Implement `Exocomp.Coordinator.Resolver` GenServer reading hostnames from Inventory, resolving forward DNS (IPv4+IPv6), normalizing/deduplicating, storing as candidates
2. Report structured resolution success/failure audit/health events
3. Handle NXDOMAIN/empty/timeout/error cases
4. Refresh resolution on inventory changes
5. Test with deterministic resolver fakes (no real DNS)
6. Ensure candidates are NOT written to Registry.addresses (that's EXOCOMP-89's job)

**Risks:**
- The current epic-EXOCOMP-2 branch does NOT yet include EXOCOMP-14 commits (still on origin/EXOCOMP-14); feature agent must check branch state and merge/rebase if needed
- The resolver should use `:inet.getaddrs/2` or `:inet_res` for DNS lookups; prefer `:inet.getaddrs` for fake-ability via process injection
- Elixir's `:inet.getaddrs` returns both A and AAAA records when passed `:inet6` — need both families

**Recommended next focus:** feature
---
author: oompah
created: 2026-07-24 02:52
---
Agent completed successfully in 167s (4948 tokens)
---
author: oompah
created: 2026-07-24 02:52
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/default]
- Turns: 39, Tool calls: 27
- Tokens: 22 in / 4.9K out [4.9K total]
- Cost: $0.0000
- Exit: normal, Duration: 2m 47s
- Log: EXOCOMP-88__20260724T024949Z.jsonl
---
author: oompah
created: 2026-07-24 02:52
---
Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-24 03:06
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 03:06
---
Focus: Frontend Developer
---
author: oompah
created: 2026-07-24 03:06
---
Understanding: I've been dispatched as a Frontend Developer focus agent. Before proceeding, I need to assess whether there is any UI/frontend work in this task. The description calls for implementing an Elixir GenServer (Exocomp.Coordinator.Resolver) for DNS hostname resolution — a pure backend feature. Let me explore the codebase to confirm there is no frontend component here before handing off.
---
author: oompah
created: 2026-07-24 03:07
---
Discovery: Confirmed — this task has zero frontend/UI components. The entire project is a pure Elixir/OTP application (no HTML, CSS, JavaScript, or any web frontend files exist). EXOCOMP-88 requires implementing Exocomp.Coordinator.Resolver, a backend GenServer for DNS hostname resolution into address candidates.

Key findings:
- Current branch (epic-EXOCOMP-2) does NOT yet include EXOCOMP-14 foundation (Inventory/Registry/Audit/Health modules) — the feature agent must cherry-pick or merge commit 7ab7dc6 from the EXOCOMP-14 branch first
- apps/exocomp_coordinator/lib/exocomp/coordinator/application.ex is currently a stub (no children) on this branch, but EXOCOMP-14 has the full supervisor with Audit, Registry, Inventory
- The EXOCOMP-14 branch has all the scaffolding modules needed as dependencies for the Resolver
- plans/milestone-2-coordinator.md confirms: DNS supplies addresses, coordinator does not trust reverse DNS, address changes are candidates until mTLS verification (EXOCOMP-89)
- No UI, no frontend, no web layer — handing off to feature agent immediately.
---
<!-- COMMENTS:END -->
