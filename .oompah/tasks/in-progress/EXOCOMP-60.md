---
id: EXOCOMP-60
type: task
status: In Progress
priority: null
title: Implement mTLS Bandit listener startup with fail-closed identity gate (Exocomp.Node.Listener)
parent: EXOCOMP-9
children: []
blocked_by:
- EXOCOMP-57
- EXOCOMP-58
labels: []
assignee: null
created_at: '2026-07-23T20:41:00.937857Z'
updated_at: '2026-07-23T22:27:25.905303Z'
work_branch: epic-EXOCOMP-1
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: f322272b-d2f1-4d0b-9dcc-47a386470a28
oompah.work_branch: epic-EXOCOMP-1
---
## Summary

### Goal
Implement \`Exocomp.Node.Listener\` — the OTP supervisor/GenServer that starts the Bandit HTTPS server only after all config and identity checks pass, and supports atomic config reload.

### Context
The Elixir scaffold is in \`apps/exocomp_node/\` (from EXOCOMP-7). Config is loaded by \`Exocomp.Node.Config\` (EXOCOMP-58). Identity is validated by \`Exocomp.Node.Identity\` (EXOCOMP-59). Fixture certs are in \`apps/exocomp_node/test/fixtures/certs/\` (EXOCOMP-57). This module wires the config and identity modules into the node application's supervision tree.

### Dependencies
Add to \`apps/exocomp_node/mix.exs\`:
- \`{:bandit, "~> 1.0"}\`
- \`{:plug, "~> 1.17"}\` (Bandit's HTTP adapter)

### Implementation

### Module: \`Exocomp.Node.Listener\`
File: \`apps/exocomp_node/lib/exocomp/node/listener.ex\`

This is a \`GenServer\`. It owns the Bandit child process via \`start_link\` inside its own \`init/1\`.

\`\`\`
init(opts) ->
  1. Config.load(opts[:config_path]) -> {:ok, config} | crash with {:stop, reason}
  2. Identity.validate(config)       -> :ok             | crash with {:stop, reason}
  3. build_tls_opts(config)          -> ssl_opts
  4. Bandit.start_link(plug: ExocompNode.Plug.Stub, scheme: :https, port: config.listen_port, thousand_island_options: [transport_options: ssl_opts])
  5. Store bandit_pid in state
\`\`\`

TLS options (passed to \`:ssl\` via \`thousand_island_options: [transport_options: ssl_opts]\`):
\`\`\`elixir
[
  certfile: config.tls.cert_path,
  keyfile: config.tls.key_path,
  cacertfile: config.tls.ca_path,
  verify: :verify_peer,
  fail_if_no_peer_cert: true,
  versions: [:'tlsv1.3']
]
\`\`\`

Stub plug for testing: \`Exocomp.Node.Plug.Stub\` — returns 200 OK for health checks.

### Config reload
Implement \`handle_call(:reload, _from, state)\`:
1. Stop the current Bandit child (\`Supervisor.stop/1\` or \`GenServer.stop/1\`)
2. Re-run init steps 1–4
3. Reply \`:ok\` or \`{:error, reason}\` to caller
4. If reload fails, the previous Bandit is already stopped — the listener goes down. The OTP supervisor handles restart.

### Wire into application
In \`Exocomp.Node.Application.start/2\`, add \`Exocomp.Node.Listener\` to the supervision tree:
\`\`\`elixir
children = [
  {Exocomp.Node.Listener, config_path: System.get_env("EXOCOMP_CONFIG_FILE")}
]
Supervisor.start_link(children, strategy: :one_for_one, name: Exocomp.Node.Supervisor)
\`\`\`

### Tests
File: \`apps/exocomp_node/test/exocomp/node/listener_test.exs\`

Use ExUnit's \`start_supervised!/1\` to avoid leaving ports open. All tests use fixture certs from \`test/fixtures/certs/\`.

Required test cases:
- Valid config + valid identity: \`start_supervised!({Listener, config_path: "test/fixtures/config_valid.json"})\` succeeds and the port is open (TCP connect on \`listen_port\`)
- Missing config file: \`start_supervised!\` raises (process fails to start)
- Malformed config: process fails to start
- Unknown config version: process fails to start
- Key file with bad permissions (chmod 0o644 in test): process fails to start
- Invalid cert chain (rogue CA cert): process fails to start
- Wrong SAN (cert SAN does not match node_id in config): process fails to start
- Reload: start listener, call \`GenServer.call(pid, :reload)\`, verify still listening
- Reload with bad new config: reload returns error, listener goes down

### Startup ordering
Make sure \`Exocomp.Node.Application\` in production mode does not crash the entire release if \`EXOCOMP_CONFIG_FILE\` is not set (return a descriptive error, allow the supervisor to record the failure).

### Quality Gate
\`make test\`, \`make lint\`, and \`make fmt-check\` must all pass. Verify that the acceptance criteria hold:
- Insecure or inconsistent identity prevents listener startup ✓
- Valid fixture identity starts the TLS listener ✓
- Secrets and key paths are redacted from errors and logs ✓
- Focused configuration and TLS tests pass ✓

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-23 22:27
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 22:27
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->
