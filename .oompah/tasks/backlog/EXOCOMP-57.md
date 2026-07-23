---
id: EXOCOMP-57
type: task
status: Backlog
priority: null
title: Generate test fixture certificates and config files
parent: EXOCOMP-9
children: []
blocked_by: []
labels: []
assignee: null
created_at: '2026-07-23T20:39:48.111110Z'
updated_at: '2026-07-23T20:39:48.111110Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
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

