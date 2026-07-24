---
id: EXOCOMP-88
type: feature
status: Done
priority: 1
title: Resolve inventory hostnames into normalized address candidates
parent: EXOCOMP-15
children: []
blocked_by: []
labels:
- focus-complete:duplicate_detector
- focus-complete:frontend
assignee: null
created_at: '2026-07-24T02:42:48.305068Z'
updated_at: '2026-07-24T03:18:05.712989Z'
work_branch: epic-EXOCOMP-2
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: b38c5125-1d98-463c-91df-021324387e5d
oompah.work_branch: epic-EXOCOMP-2
oompah.task_costs:
  total_input_tokens: 40
  total_output_tokens: 8957
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 40
      output_tokens: 8957
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 22
    output_tokens: 4926
    cost_usd: 0.0
    recorded_at: '2026-07-24T02:52:32.459298+00:00'
  - profile: default
    model: unknown
    input_tokens: 18
    output_tokens: 4031
    cost_usd: 0.0
    recorded_at: '2026-07-24T03:07:57.066106+00:00'
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
author: oompah
created: 2026-07-24 03:07
---
Focus handoff: frontend

**Outcome:** No frontend work exists or is needed for this task. EXOCOMP-88 is a pure Elixir/OTP backend feature — a supervised GenServer (Exocomp.Coordinator.Resolver) for DNS hostname resolution. The Frontend Developer focus has nothing to contribute here and is handing off immediately.

**Evidence:**
- No HTML/CSS/JS/JSX/TSX files exist anywhere in this repository
- All code is Elixir (mix.exs, .ex/.exs files in apps/)
- plans/milestone-2-coordinator.md describes a fully backend DNS resolution pipeline with OTP supervisors, ETS, GenServers

**Relevant files for the feature agent:**
- plans/milestone-2-coordinator.md — §Inventory and Discovery defines the resolution contract
- EXOCOMP-14 branch (commit 7ab7dc6) — has Inventory, Registry, Audit, Health modules (NOT yet on this branch)
- apps/exocomp_coordinator/lib/exocomp/coordinator/application.ex — stub supervisor on current branch; full supervisor is on EXOCOMP-14
- apps/exocomp_coordinator/ — target location for Resolver implementation

**Remaining work (for feature agent):**
1. Merge/cherry-pick EXOCOMP-14 (commit 7ab7dc6) onto this branch to get Inventory/Registry/Audit foundation
2. Implement Exocomp.Coordinator.Resolver GenServer:
   - Read hostnames from Exocomp.Coordinator.Inventory
   - Resolve IPv4+IPv6 with forward DNS only (no reverse DNS), using injectable resolver (e.g. :inet.getaddrs/2 wrapped behind a behaviour for testability)
   - Normalize and deduplicate results deterministically (sort by address string)
   - Store resolved addresses as CANDIDATES only — do NOT write to Registry.addresses (that is EXOCOMP-89's job)
   - Report structured audit/health events on success AND failure
   - Refresh on inventory changes
3. Handle error cases: NXDOMAIN, empty result, timeout, generic error
4. Write ExUnit tests using deterministic resolver fakes (no real DNS)
5. Run make quality gates

**Risks:**
- The EXOCOMP-14 branch diverges significantly from current HEAD — diff shows many files removed; careful merge strategy needed
- :inet.getaddrs/2 returns different tuple formats for inet vs inet6 — need both address families
- Candidates must be stored separately from Registry.addresses (the Registry may need a candidates field added)

**Recommended next focus:** feature
---
author: oompah
created: 2026-07-24 03:07
---
Agent completed successfully in 102s (4049 tokens)
---
author: oompah
created: 2026-07-24 03:07
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/default]
- Turns: 27, Tool calls: 21
- Tokens: 18 in / 4.0K out [4.0K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 42s
- Log: EXOCOMP-88__20260724T030617Z.jsonl
---
author: oompah
created: 2026-07-24 03:08
---
Focus handoff from `frontend` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-24 03:08
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-24 03:08
---
Focus: Maintenance Engineer
---
author: oompah
created: 2026-07-24 03:08
---
Understanding: I'm the Maintenance Engineer focus agent for EXOCOMP-88. The previous focus agents (duplicate_detector, frontend) have determined this is a pure Elixir/OTP backend feature with no duplicates. My job is to implement the Exocomp.Coordinator.Resolver GenServer. Plan: (1) check current branch state and EXOCOMP-14 foundation availability, (2) explore existing code, (3) implement the Resolver module with injectable DNS backend, (4) write ExUnit tests with deterministic fakes, (5) run quality gates and push.
---
author: oompah
created: 2026-07-24 03:11
---
Discovery: Cherry-picked EXOCOMP-14 (commit 7ab7dc6) onto epic-EXOCOMP-15 cleanly — Audit, Registry, Inventory, Health, Error, and InventoryNode modules are now present. Implementation plan: (1) Add candidate_addresses field + put_candidates/3 to Registry; (2) Implement Resolver GenServer with injectable resolver_fn, dual-stack (inet+inet6) forward-only DNS, deterministic normalization/dedup, and Audit events; (3) Add Resolver to Application supervisor; (4) Write resolver_test.exs with fake resolver fns covering success/multiple-addrs/changed/NXDOMAIN/timeout/error/inventory-refresh. No existing code conflicts. candidates stay separate from Registry.addresses per spec.
---
author: oompah
created: 2026-07-24 03:17
---
Implementation: Cherry-picked EXOCOMP-14 foundation (Audit/Registry/Inventory/Health/Error/InventoryNode) then implemented Exocomp.Coordinator.Resolver GenServer. Key decisions: (1) Injectable resolver_fn option (defaults to :inet.getaddrs/2) for test isolation; (2) Dual-stack: resolves :inet (IPv4) and :inet6 (IPv6) separately, combines results; (3) Normalizes via :inet.ntoa/1, Enum.uniq + Enum.sort for deterministic dedup; (4) Stores in Registry.candidate_addresses (new field), never touches Registry.addresses; (5) Emits :dns_resolved or :dns_resolution_failed Audit events per node per sweep; (6) Gracefully handles NXDOMAIN/timeout/empty/servfail; (7) Added Registry.put_candidates/3 API; (8) Added Resolver to Application supervisor after Inventory.
---
author: oompah
created: 2026-07-24 03:17
---
Verification: All quality gates pass. make test: 133 total tests (10 excluded for systemd integration), 0 failures. make lint: fmt-check clean, warnings-as-errors clean. Resolver tests (11 cases) cover: IPv4 success, multiple IPv4+IPv6, dedup, address-set change, NXDOMAIN, timeout, empty-ok, servfail, multi-node, inventory refresh, empty inventory. All fake-resolver tests use no real DNS. Registry.addresses field verified to remain [] after resolution (candidates only).
---
author: oompah
created: 2026-07-24 03:18
---
Completion: Delivered Exocomp.Coordinator.Resolver — a supervised, dependency-injectable DNS resolver GenServer. Reads hostnames from Inventory, resolves IPv4+IPv6 forward-only, normalizes+deduplicates deterministically, stores as candidate_addresses in Registry (never touches Registry.addresses), and emits structured :dns_resolved/:dns_resolution_failed Audit events. 11 focused ExUnit tests with fake resolver fns cover all required scenarios. EXOCOMP-14 foundation cherry-picked onto epic-EXOCOMP-15. Pushed to origin/epic-EXOCOMP-15.
---
<!-- COMMENTS:END -->
