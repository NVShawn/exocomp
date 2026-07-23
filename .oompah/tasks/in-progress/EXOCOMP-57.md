---
id: EXOCOMP-57
type: task
status: In Progress
priority: null
title: Generate test fixture certificates and config files
parent: EXOCOMP-9
children: []
blocked_by: []
labels:
- focus-complete:duplicate_detector
assignee: null
created_at: '2026-07-23T20:39:48.111110Z'
updated_at: '2026-07-23T21:05:58.578188Z'
work_branch: epic-EXOCOMP-1
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 98927511-64d5-43c5-95e0-7cb1fbbcdd77
oompah.work_branch: epic-EXOCOMP-1
oompah.task_costs:
  total_input_tokens: 667432
  total_output_tokens: 14108
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 667432
      output_tokens: 14108
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 667413
    output_tokens: 3949
    cost_usd: 0.0
    recorded_at: '2026-07-23T20:51:54.272799+00:00'
  - profile: standard
    model: unknown
    input_tokens: 19
    output_tokens: 10159
    cost_usd: 0.0
    recorded_at: '2026-07-23T21:03:59.222371+00:00'
---
## Summary

### Goal
Create the test infrastructure needed by EXOCOMP-9's implementation tasks: fixture TLS certificates and sample JSON config files.

### Context
EXOCOMP-9 requires mTLS with a node certificate whose SAN matches the configured node ID. All implementation tasks need fixture certs to run tests. The Elixir scaffold is in apps/exocomp_node/ (from EXOCOMP-7). Config and identity tests share a common fixture set.

### Implementation

### 1. Certificate generation script
Write \`scripts/gen-test-certs.sh\` using openssl that generates:
- A self-signed CA certificate (\`ca.crt\`)
- A node leaf certificate signed by the CA (\`node.crt\` + \`node.key\`), with SAN \`DNS:exocomp-test-node\`
- An alternative node cert whose SAN intentionally mismatches node ID (\`wrong_san.crt\`, \`wrong_san.key\`)
- An expired certificate (\`expired.crt\`, \`expired.key\`) for chain validation tests
- A cert signed by a different (rogue) CA (\`rogue.crt\`, \`rogue.key\`) for trust-root tests

Store all outputs under \`apps/exocomp_node/test/fixtures/certs/\`.
Make sure private key files (\`*.key\`) are mode 0600 after generation.

### 2. JSON config fixture files
Write the following under \`apps/exocomp_node/test/fixtures/\`:
- \`config_valid.json\` — a well-formed version-1 config pointing to the fixture certs
- \`config_missing_fields.json\` — missing required fields
- \`config_unknown_version.json\` — \`"version": 99\`
- \`config_malformed.json\` — invalid JSON (truncated)

### 3. Makefile target
Add a \`gen-test-fixtures\` Make target that runs the cert generation script. Document it with a \`## \` comment so \`make help\` shows it.

### 4. .gitignore note
Add \`apps/exocomp_node/test/fixtures/certs/*.key\` to .gitignore (private keys must not be committed). Commit only the public certs and config fixtures.

Wait — fixture private keys are development-only secrets with no production exposure. They are acceptable to commit for reproducible tests. Remove the gitignore exclusion and document this in a comment in the script.

### Testing
Run \`make gen-test-fixtures\` and verify all files are created with correct permissions. Verify the generated cert's SAN with \`openssl x509 -noout -ext subjectAltName -in apps/exocomp_node/test/fixtures/certs/node.crt\`.

### Acceptance
- \`scripts/gen-test-certs.sh\` is idempotent (running twice does not error)
- All fixture files exist and are checked into git (except note above)
- \`make gen-test-fixtures\` passes in the containerized build environment

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-23 20:50
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 20:50
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 20:51
---
Agent completed successfully in 110s (671362 tokens)
---
author: oompah
created: 2026-07-23 20:51
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/default]
- Turns: 1, Tool calls: 24
- Tokens: 667.4K in / 3.9K out [671.4K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 50s
- Log: EXOCOMP-57__20260723T205006Z.jsonl
---
author: oompah
created: 2026-07-23 20:51
---
Agent completed without landing — no commits found on origin for branch `epic-EXOCOMP-9`. Escalating from 'default' to 'standard'. Retrying in 10s (1/3).
---
author: oompah
created: 2026-07-23 20:52
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-23 20:52
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 21:03
---
Focus handoff: duplicate_detector

**Outcome:** No duplicate found. EXOCOMP-57 is unique.

**Evidence reviewed:**
- Searched all tasks in oompah/state/proj-c260b117 for cert/fixture/TLS/openssl keywords
- EXOCOMP-57 is a child of EXOCOMP-9 (epic: Implement node configuration, identity, and mTLS startup)
- Closest candidates reviewed:
  - EXOCOMP-59 (identity validation: cert chain, SAN, key permissions) — consumes these fixtures, does not create them
  - EXOCOMP-60 (mTLS Bandit listener startup) — implementation that uses fixtures
  - EXOCOMP-17 (node enrollment and certificate renewal) — production feature, not test infrastructure
  - EXOCOMP-8 (A2A 1.0 shared protocol types and fixtures) — A2A protocol types, not TLS certs
  - EXOCOMP-51 (Pin A2A 1.0 fixture files, protocol test suite) — A2A protocol, not TLS
- None of these cover the same scope as EXOCOMP-57

**Remaining work:**
1. Write scripts/gen-test-certs.sh with openssl to generate: ca.crt, node.crt+key (SAN=DNS:exocomp-test-node), wrong_san.crt+key, expired.crt+key, rogue.crt+key — output to apps/exocomp_node/test/fixtures/certs/
2. Create JSON config fixtures: config_valid.json, config_missing_fields.json, config_unknown_version.json, config_malformed.json
3. Add gen-test-fixtures Make target with ## comment
4. Do NOT add *.key to .gitignore (fixture private keys are dev-only, acceptable to commit for reproducible tests — document in script)
5. Verify idempotency and SAN with openssl x509 -noout -ext subjectAltName

**Key risks:**
- Branch is epic-EXOCOMP-9; the apps/exocomp_node/ scaffold from EXOCOMP-7 needs to be merged into this branch first (or work done atop EXOCOMP-7 commits)
- openssl must be available in the containerized build environment
- git pull --rebase from EXOCOMP-7 needed before implementing

**Recommended next focus:** devops — this is a build/test infrastructure task (shell scripts, Makefile target, JSON config files)
---
author: oompah
created: 2026-07-23 21:03
---
Agent completed successfully in 710s (10178 tokens)
---
author: oompah
created: 2026-07-23 21:04
---
Run #2 [attempt=2, profile=standard, role=standard -> Claude/default]
- Turns: 42, Tool calls: 27
- Tokens: 19 in / 10.2K out [10.2K total]
- Cost: $0.0000
- Exit: normal, Duration: 11m 50s
- Log: EXOCOMP-57__20260723T205211Z.jsonl
---
author: oompah
created: 2026-07-23 21:04
---
Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-23 21:04
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-23 21:04
---
Focus: DevOps Engineer
---
author: oompah
created: 2026-07-23 21:05
---
**Understanding:** Creating test fixture infrastructure for EXOCOMP-9's mTLS implementation. Plan:
1. Create EXOCOMP-57 branch from EXOCOMP-7 (which has the apps/exocomp_node/ scaffold)
2. Write scripts/gen-test-certs.sh generating CA, node cert (SAN=DNS:exocomp-test-node), wrong_san, expired, and rogue certs under apps/exocomp_node/test/fixtures/certs/
3. Create JSON config fixtures: config_valid.json, config_missing_fields.json, config_unknown_version.json, config_malformed.json
4. Add gen-test-fixtures Makefile target with ## comment
5. Fixture private keys will be committed (dev-only, acceptable for reproducible tests — documented in script)
6. Verify idempotency and SAN via openssl
---
author: oompah
created: 2026-07-23 21:05
---
**Discovery:** Found EXOCOMP-7 scaffold. apps/exocomp_node/test/ exists but has no fixtures/ directory. scripts/ has smoke-releases.sh and verify-toolchain.sh. Need to create:
- apps/exocomp_node/test/fixtures/certs/ directory with all cert files
- apps/exocomp_node/test/fixtures/ JSON config fixtures  
- scripts/gen-test-certs.sh
- Makefile gen-test-fixtures target
---
<!-- COMMENTS:END -->
