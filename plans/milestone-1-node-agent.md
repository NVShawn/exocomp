# Milestone 1: Prototype Elixir Node Agent

## Status

Proposed

Target date: 2026-08-15

## Outcome

Milestone 1 delivers a diagnostic-only Exocomp node agent as a self-contained
Elixir/OTP release. The agent publishes an Agent2Agent (A2A) 1.0 HTTP+JSON
interface, collects local Linux and systemd diagnostics, and supervises a
local llama.cpp inference process. It cannot modify host state.

This milestone establishes the shared Elixir umbrella, A2A protocol types, and
build and test conventions used by every later milestone.

## Goals

- Build an Elixir umbrella that produces separate node and coordinator OTP
  releases.
- Package the Erlang runtime in each release.
- Serve diagnostic A2A skills over HTTPS with mutual TLS.
- Collect CPU, memory, disk, uptime, and systemd service state.
- Supervise a pinned `llama-server` companion process and validate structured
  model output.
- Fail closed when identity, protocol, inference, or diagnostic inputs are
  invalid.

## Non-Goals

- Service restarts or any other host mutation.
- Coordinator discovery and orchestration.
- Production certificate enrollment.
- Streaming A2A responses or push notifications.
- Arbitrary shell commands or arbitrary filesystem access.

## Technical Baseline

- Elixir 1.20 on Erlang/OTP 28, with exact patch versions and builder image
  digests pinned when the umbrella is created.
- An umbrella containing shared core/protocol code, a node application, and a
  coordinator application.
- Bandit/Plug for HTTPS serving and OTP `:ssl`, `:public_key`, and `:crypto`
  for transport and identity primitives.
- A2A specification version 1.0 using the HTTP+JSON binding and
  `application/a2a+json`.
- `llama-server` from a pinned llama.cpp build, bound to loopback only.
- Qwen2.5 1.5B Instruct in GGUF Q4_K_M form, addressed through a configurable
  model path and verified checksum.
- Linux with systemd. No BEAM distribution is exposed between hosts.

## Architecture

```mermaid
flowchart LR
    Client[A2A client] -->|mTLS HTTP+JSON| Server[Node A2A server]
    Server --> Tasks[Task registry]
    Tasks --> Diagnostics[Diagnostic collectors]
    Tasks --> Proposals[Proposal service]
    Proposals --> LlamaClient[llama.cpp client]
    LlamaClient -->|loopback HTTP| Llama[llama-server]
    Diagnostics --> Proc[/proc and /sys]
    Diagnostics --> Systemd[systemctl show]
```

The node supervision tree isolates the HTTPS listener, task registry,
diagnostic collectors, and native inference process. A llama.cpp crash may
degrade inference-backed skills but must not terminate diagnostics or the node
release.

## Runtime Configuration

Configuration is loaded from environment variables and a versioned JSON file.
Startup validation rejects unknown schema versions and inconsistent identity
settings.

Required settings:

- Stable node ID.
- HTTPS listen address and port.
- Node certificate, private key, and trust-root paths.
- Allowed diagnostic service names.
- llama.cpp executable and model paths plus expected checksums.
- Inference timeout, task-history limit, and diagnostic command timeout.

Private-key files must be owned by the Exocomp service account and must not be
group- or world-readable. The operational listener does not start without a
valid certificate chain and a node ID matching the certificate identity.
Milestone 1 tests use fixture certificates; production enrollment is defined
in Milestone 2.

## Diagnostic Model

Collectors return versioned maps with:

- Observation timestamp and node ID.
- Source and collector version.
- Measurements with explicit units.
- Per-field availability and errors.
- Collection duration.

CPU, memory, and uptime use `/proc`; filesystem capacity uses OS filesystem
statistics; optional hardware data may use `/sys`. Service inspection invokes
`systemctl show` with an argv list, fixed property names, and a timeout. No
collector invokes a shell or accepts an arbitrary command from an API caller
or model.

Partial collector failures are returned as structured errors. They do not
erase successful observations or crash the request process.

## Inference Integration

The node starts `llama-server` as a monitored OS process using an OTP Port or a
dedicated process supervisor. It waits for readiness before advertising
inference-backed availability and applies restart backoff after repeated
crashes.

The model receives a fixed system prompt, bounded diagnostic context, and a
closed list of proposal identifiers. Output must match a versioned proposal
schema. Invalid, truncated, timed-out, or unknown output is recorded as a
failed proposal and never interpreted as a command.

The model has no execution interface. It can describe observations and suggest
a known remediation intent for later policy processing.

## A2A Interface

The node serves:

- `GET /.well-known/agent-card.json`
- `POST /message:send`
- `GET /tasks/{id}`
- `GET /tasks`
- `POST /tasks/{id}:cancel`

Every operational request requires mTLS and `A2A-Version: 1.0`. The server
uses standard A2A `Message`, `Task`, `Part`, `Artifact`, state, and error
objects. Exocomp results use versioned `DataPart` payloads.

Initial skills:

- `exocomp.system.diagnose`
- `exocomp.service.diagnose`
- `exocomp.remediation.propose`

The Agent Card declares streaming and push notifications unsupported. Requests
for unsupported optional operations return the A2A
`UnsupportedOperationError`.

Tasks are held in bounded in-memory storage. Cancellation stops queued work
and records a terminal canceled state. Completed history is evicted by age and
count. A restart may make an old task unavailable.

## Failure and Security Behavior

- Reject unauthenticated clients before request decoding.
- Bound request body size, task history, diagnostic output, model context, and
  all timeouts.
- Return protocol errors without leaking key paths, raw certificates, command
  output unrelated to the request, or model internals.
- Treat unavailable inference as a degraded skill, not a reason to fabricate a
  proposal.
- Emit structured audit events for authentication outcome, task transitions,
  collector failures, model calls, and redacted model output.
- Never mutate the host in this milestone.

## Test Strategy

Unit tests cover configuration, A2A codecs and error mappings, collectors,
proposal validation, task transitions, and secret redaction. Collector tests
use fixture files and stubbed argv execution.

Integration tests run the node against fixture certificates, a fake
llama-server, and a disposable systemd test environment. They cover mTLS
rejection, valid diagnostics, inference timeout, invalid output, native process
restart, cancellation, concurrent requests, and bounded history.

A protocol fixture suite pins the A2A 1.0 schemas used by Exocomp and checks
round trips and version negotiation.

## Acceptance Criteria

- [ ] M1-CRIT-1: `make build`, `make test`, `make lint`, and `make fmt-check`
      pass from a clean checkout using the pinned toolchain.
- [ ] M1-CRIT-2: Both node and coordinator release skeletons build with ERTS
      included, and the node release starts without development tooling.
- [ ] M1-CRIT-3: An authenticated A2A 1.0 client retrieves the Agent Card and
      receives a schema-valid system diagnostic artifact.
- [ ] M1-CRIT-4: CPU, memory, disk, uptime, and allow-listed service
      observations are unit-tested, use no shell, and return bounded structured
      failures.
- [ ] M1-CRIT-5: llama.cpp timeout, invalid output, and process crashes cannot
      produce an executable action or terminate the node agent.
- [ ] M1-CRIT-6: Missing or invalid mTLS identity prevents the operational
      listener from starting, and unauthenticated calls are rejected.
- [ ] M1-CRIT-7: The end-to-end test proves the node agent makes no host state
      changes.

