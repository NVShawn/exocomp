---
id: EXOCOMP-25
type: feature
status: In Progress
priority: 1
title: Implement unprivileged systemd executor and exact sudoers policy
parent: EXOCOMP-3
children: []
blocked_by:
- EXOCOMP-21
labels:
- focus-complete:duplicate_detector
assignee: null
created_at: '2026-07-23T19:10:11.402376Z'
updated_at: '2026-07-23T22:47:00.023568Z'
work_branch: epic-EXOCOMP-3
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 37a456ec-a794-4780-a630-b771588aab73
oompah.work_branch: epic-EXOCOMP-3
oompah.task_costs:
  total_input_tokens: 79
  total_output_tokens: 2395
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 79
      output_tokens: 2395
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 52
    output_tokens: 1803
    cost_usd: 0.0
    recorded_at: '2026-07-23T22:16:55.975515+00:00'
  - profile: standard
    model: unknown
    input_tokens: 27
    output_tokens: 592
    cost_usd: 0.0
    recorded_at: '2026-07-23T22:23:26.603314+00:00'
---
## Summary

Plan: [Milestone 3 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-3-safety-validation.md)

Goal
Implement unprivileged systemd executor and exact sudoers policy.

Implementation
Implement action execution under a dedicated unprivileged account; generate exact per-service sudoers entries; map installed action IDs to fixed executable/argv/environment/timeouts; serialize per target; capture bounded output; invoke post-action verification; expose no generic command.

Testing
Test service allow-list, unknown units, shell metacharacters, argv/environment injection, executable path changes, timeout, oversized output, sudo denial, concurrent targets, and generated policy snapshots.

Acceptance Criteria
- [ ] Node release does not run as root.
- [ ] Only installed allow-listed services can reach systemctl.
- [ ] No request/model field becomes shell syntax or arbitrary argv.
- [ ] Privilege policy is minimal and deterministic.
- [ ] Focused executor tests pass.

Quality Gate
Run the focused tests and all repository Make targets affected by this change.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-23 22:14
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 22:15
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 22:16
---
Focus handoff: duplicate_detector

Outcome: No duplicate confirmed. EXOCOMP-25 is a unique task with no coverage overlap in the existing task graph.

Evidence reviewed:
- All M3 siblings (EXOCOMP-22 through EXOCOMP-28) and parent epic EXOCOMP-3:
  - EXOCOMP-22: Policy selection engine (In Progress) — distinct scope
  - EXOCOMP-23: Approval issuance (Open) — distinct scope
  - EXOCOMP-24: Approval replay prevention (Open) — distinct scope
  - EXOCOMP-26: Bounded system-log cleanup action (Open) — covers the specific cleanup action, not executor infrastructure
  - EXOCOMP-27: Lifecycle integration (Open) — A2A integration, not executor
  - EXOCOMP-28: M3 verification (Open) — integration tests, not implementation

- EXOCOMP-10 (Done): Linux and systemd diagnostic *collectors* — reads metrics from systemctl show, read-only, no privilege elevation. Distinct from EXOCOMP-25 which is about *action execution* (restart, remediation) under a dedicated unprivileged account via exact sudoers entries.

- EXOCOMP-70/EXOCOMP-72 (Done): systemd fixture unit file and test environment docs — fixture infrastructure, not executor implementation.

- No code exists yet in apps/ for an executor, sudoers generator, or privilege separation layer.

Relevant design reference: plans/milestone-3-safety-validation.md section 'Privilege Separation' (M3-CRIT-7) and 'Action Catalog' — EXOCOMP-25 implements the executor side of the policy engine.

Remaining work and risks:
1. Implement Elixir modules for the restricted executor: map installed action IDs to fixed executable/argv/environment/timeouts; no generic command exposure.
2. Generate per-service exact sudoers entries for configured allow-listed services only.
3. Serialize per-target; capture bounded output.
4. Invoke post-action verification hooks.
5. Test service allow-list, unknown units, shell metacharacters, argv/environment injection, executable path changes, timeout, oversized output, sudo denial, concurrent targets, and generated sudoers snapshots.
6. Ensure the node runtime account is not root.
7. Blocker: EXOCOMP-21 (type system) is Done — unblocked. EXOCOMP-22 (policy selection) is In Progress but executor can be built independently and wired later.

Recommended next focus: feature
---
author: oompah
created: 2026-07-23 22:16
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/default]
- Turns: 0, Tool calls: 34
- Tokens: 52 in / 1.8K out [1.9K total]
- Cost: $0.0000
- Exit: terminated, Duration: 1m 57s
- Log: EXOCOMP-25__20260723T221501Z.jsonl
---
author: oompah
created: 2026-07-23 22:17
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-23 22:17
---
Focus: Security Auditor
---
author: oompah
created: 2026-07-23 22:23
---
Run #2 [attempt=2, profile=standard, role=standard -> Claude/default]
- Turns: 0, Tool calls: 16
- Tokens: 27 in / 592 out [619 total]
- Cost: $0.0000
- Exit: terminated, Duration: 6m 17s
- Log: EXOCOMP-25__20260723T221711Z.jsonl
---
author: oompah
created: 2026-07-23 22:23
---
Retrying (attempt #2, agent: standard)
---
author: oompah
created: 2026-07-23 22:23
---
Focus: Security Auditor
---
author: oompah
created: 2026-07-23 22:25
---
Understanding: As Security Auditor implementing EXOCOMP-25, I will build the unprivileged systemd executor and sudoers policy engine for exocomp_node. The codebase is an Elixir umbrella project. No executor code exists yet.

Scope:
1. Action catalog — typed map of action IDs to fixed executable/argv/env/timeout (no shell, no arbitrary commands)
2. Sudoers generator — render exact per-service and per-action sudoers entries from installed allow-list; no user-controlled input
3. Restricted executor — argv-based process invocation, bounded output capture, per-target serialization, post-action verification hook
4. Security invariants tested: shell metacharacter injection, argv injection, env injection, executable path changes, unknown units, timeout, oversized output, sudo denial, concurrent targets, sudoers snapshots

Key security decisions:
- Service names come ONLY from installed allow-list (config), never from request fields
- Process invocation uses System.cmd/Port with explicit argv list — no shell expansion
- Environment is fixed per action definition — no caller-supplied env vars
- Output capped at configured byte limit; excess causes error result
- Timeouts enforced via Task.yield with hard kill
- Sudoers entries name exact executable path, exact args pattern — no wildcards
- Running account check: verify EUID != 0 at startup

Will implement in apps/exocomp_node/lib/exocomp/node/ with unit tests in apps/exocomp_node/test/.
---
author: oompah
created: 2026-07-23 22:28
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 22:28
---
Focus: Security Auditor
---
author: oompah
created: 2026-07-23 22:33
---
Understanding: Implementing EXOCOMP-25 — unprivileged systemd executor and exact sudoers policy.

Codebase context:
- Elixir umbrella project: apps/exocomp_node, exocomp_core, exocomp_coordinator
- apps/exocomp_node/lib/exocomp/node/ currently has only application.ex
- Integration tests (fixture_test.exs) exist for systemd fixture service — distinct from this task
- No executor, sudoers, or privilege-separation code exists yet

Implementation plan:
1. Exocomp.Node.ActionCatalog — Fixed map of action IDs to typed definitions (executable, argv-builder, fixed env, timeout, output limit). Only :restart_service and :vacuum_logs. No generic command.
2. Exocomp.Node.OsCommander — Behavior + SystemCommander (System.cmd, argv list, no shell). Injectable in tests via Application config.
3. Exocomp.Node.Executor — Validates action+target against catalog+allow-list, acquires per-target lock, runs subprocess with fixed argv/env/timeout, caps output, invokes post-action verifier.
4. Exocomp.Node.ExecutorLock — GenServer for per-target serialization (rejects concurrent executions on same target).
5. Exocomp.Node.SudoersPolicy — Generates exact sudoers entries from allow-listed service names. Empty allow-list → no privileged entries.
6. Exocomp.Node.Privilege — Checks EUID != 0 at startup.

Security invariants enforced:
- Service names validated by strict regex before any subprocess; only allow-listed names proceed
- argv built from catalog definition (pre-validated target), never from raw request/model fields
- Environment is fixed per action; no caller-supplied env
- Output capped at 64 KB; excess causes error result
- Timeout enforced via Task.yield + brutal kill
- Sudoers entries name exact executable path and exact arg prefix — no wildcards
- No shell expansion: System.cmd with explicit argv list

Tests will cover: service allow-list, unknown units, shell metacharacters, argv injection, env injection, executable path immutability, timeout, oversized output, sudo denial (non-zero exit), concurrent targets, and sudoers snapshot.
---
author: oompah
created: 2026-07-23 22:46
---
Implementation: Implemented unprivileged systemd executor and exact sudoers policy in apps/exocomp_node/.

New modules (lib/exocomp/node/):
- action_catalog.ex: Fixed typed catalog for :restart_service and :vacuum_logs. Strict service-name regex (alphanumeric + hyphen/underscore/dot/at-sign only) rejects all shell metacharacters unconditionally before the allow-list is consulted. No generic command action.
- os_commander.ex: OsCommander behaviour + SystemCommander (System.cmd with explicit argv list, no shell). Injectable via Application env for tests — accepts both module atom and 3-arity function closure.
- executor.ex: Validates action+target against catalog+allow-list; acquires per-target serialization lock; builds argv from catalog (never from caller strings); passes fixed env only; enforces timeout and 64KB output limit; invokes post-action verifier; releases lock in 'after' clause.
- executor_lock.ex: GenServer for per-target serialization; rejects concurrent executions on same target; started under application supervisor.
- sudoers_policy.ex: Generates exact NOPASSWD entries for each allow-listed service; no wildcards; deterministic output; account name validated against strict POSIX regex; empty allow-list produces only vacuum entry or empty string.
- privilege.ex: Checks EUID != 0 via 'id -u'; raises RuntimeError if root.

Updated: application.ex (starts ExecutorLock), mix.exs (adds test/support to elixirc_paths).

Test coverage: 124 tests covering service allow-list, 11 shell metacharacter injection vectors, argv/env injection invariants, executable path immutability, timeout, oversized output, sudo denial, concurrent target serialization, post-action verification, verifier failure, sudoers policy snapshots, account validation, and privilege check.
---
author: oompah
created: 2026-07-23 22:47
---
Verification: All quality gates pass.

make test: 124/124 tests pass (0 failures)
- exocomp_core: 2 passed
- exocomp_coordinator: 1 passed
- exocomp_node: 121 passed (includes 11 metacharacter injection tests, 4 argv/env invariant tests, timeout/output-limit/sudo-denial tests, concurrent serialization, verifier tests, sudoers snapshots, privilege check)

make lint: passes (format check + warnings-as-errors compile)

Release builds: both exocomp_node and exocomp_coordinator release successfully under MIX_ENV=test.

Acceptance criteria status:
- Node release does not run as root: Privilege.check_not_root!/0 in application; tested
- Only allow-listed services can reach systemctl: enforced in ActionCatalog.lookup/3; tested with 11 injection vectors
- No request/model field becomes shell syntax or arbitrary argv: argv built from catalog only; regex rejects metacharacters before allow-list; tested
- Privilege policy is minimal and deterministic: SudoersPolicy generates exact NOPASSWD entries per-service, no wildcards; snapshot tested
- Focused executor tests pass: 121 new tests in exocomp_node, all passing
---
<!-- COMMENTS:END -->
