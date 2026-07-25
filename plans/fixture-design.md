# Systemd Recovery Fixture Design

## Purpose

The `exocomp-fixture` service is an isolated, intentionally crashable systemd
service used exclusively for M4 integration testing. It lets tests exercise
every required service state without touching operator services or persistent
data.

## File Layout

```
test/fixtures/exocomp_fixture/
├── README.md                   # Usage, environment requirements
├── bin/
│   └── exocomp-fixture         # Service daemon (bash or Python)
├── exocomp-fixture.service     # systemd unit file
├── install.sh                  # Idempotent installer (requires root)
└── cleanup.sh                  # Idempotent cleanup (scoped to fixture resources)
```

All fixture resources live under:

| Path | Purpose |
|------|---------|
| `/etc/systemd/system/exocomp-fixture.service` | Unit file (installer places, cleanup removes) |
| `/usr/local/bin/exocomp-fixture` | Service daemon (installer places, cleanup removes) |
| `/run/exocomp-fixture/` | RuntimeDirectory: workload marker + control socket |
| `127.0.0.1:8877` | Health HTTP endpoint (configurable via environment variable) |

No other paths are written by the fixture.

## Service Modes

The daemon is put into a mode by writing a keyword to
`/run/exocomp-fixture/mode`:

| Mode | systemd state | Health endpoint | Description |
|------|--------------|-----------------|-------------|
| `active` | active/running | `{"status":"ok"}` | Normal operation |
| `degraded` | active/running | `{"status":"degraded"}` | Process alive, app unhealthy |
| `failed` | failed | — (process exits) | Exits nonzero immediately |
| `flapping` | cycling active↔failed | `{"status":"ok"}` (when up) | Restarts rapidly |
| `restart-failure` | failed/start-limit-hit | — | Exits immediately on every start, exhausts StartLimitBurst |

The `degraded` mode is the key case that proves health can disagree with
systemd's active state (M4-CRIT-1 / acceptance criterion).

## Health Endpoint

Runs on `127.0.0.1:$FIXTURE_HEALTH_PORT` (default 8877). Endpoints:

- `GET /health` → `200 {"status":"ok"}` or `503 {"status":"degraded"}`
- `GET /mode` → `200 {"mode":"<current-mode>"}`

The endpoint responds even when the service is degraded. It stops responding
only when the process exits (failed / restart-failure modes).

## Workload Marker

`/run/exocomp-fixture/workload.marker` is written every 5 seconds with the
current timestamp. Absence of this file proves the service is not actively
running.

## State-Control Interface

Tests control the fixture mode by:

1. Writing the mode keyword to `/run/exocomp-fixture/mode`
2. Sending SIGUSR1 to the daemon PID (optional, for immediate response)

Or via the installer:

```bash
exocomp-fixture --set-mode degraded
```

## Installer / Cleanup

`install.sh` is idempotent: safe to run multiple times. It:

1. Copies the unit file to `/etc/systemd/system/exocomp-fixture.service`
2. Copies the daemon to `/usr/local/bin/exocomp-fixture` (chmod +x)
3. Runs `systemctl daemon-reload`
4. Runs `systemctl enable --now exocomp-fixture`

`cleanup.sh` is idempotent: safe to run on a clean system. It:

1. Runs `systemctl stop exocomp-fixture` (ignores failure if not running)
2. Runs `systemctl disable exocomp-fixture` (ignores failure if not enabled)
3. Removes `/etc/systemd/system/exocomp-fixture.service`
4. Removes `/usr/local/bin/exocomp-fixture`
5. Removes `/run/exocomp-fixture/` (runtime dir)
6. Runs `systemctl daemon-reload`

Cleanup does NOT touch any file outside the above list.

## ExUnit Test Structure

Tests live in `test/integration/fixture_test.exs` (umbrella root) or the
`exocomp_node` app's integration test suite. They are tagged `@tag :systemd`
and skipped in standard CI.

Required test cases:

| Test | Verifies |
|------|---------|
| install/start | Fixture reaches active state |
| stop/start | Controllable via systemctl |
| crash (failed mode) | systemd reports failed |
| degrade | systemd active + health degraded simultaneously |
| flap | Repeated restart events visible via systemctl |
| restart-failure | StartLimitBurst exhausted; systemd reports failed |
| cleanup | All fixture resources removed; non-fixture services untouched |
| health-vs-systemd divergence | Health 503 while systemctl is-active = active |
| repeated setup | Idempotent install+cleanup cycle succeeds N times |
| non-fixture isolation | No non-fixture unit files or paths modified |

## Environment Requirements

Systemd fixture tests require:

- A Linux VM (QEMU/KVM recommended) running a systemd-based distribution, **or**
- A privileged container (`--privileged`) with systemd as PID 1

Standard Docker containers without privilege cannot host a functioning systemd.
See `docs/testing-systemd-fixture.md` for step-by-step environment setup.

## Child Tasks

This design is implemented by:

- **EXOCOMP-69** — Fixture service daemon script
- **EXOCOMP-70** — systemd unit file + installer/cleanup scripts (depends on EXOCOMP-69)
- **EXOCOMP-71** — ExUnit integration tests (depends on EXOCOMP-69, EXOCOMP-70)
- **EXOCOMP-72** — VM/container environment documentation

Together these satisfy EXOCOMP-29 (M4-CRIT-1) and enable EXOCOMP-31 and
EXOCOMP-33.
