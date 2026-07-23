# exocomp-fixture

Intentionally crashable fixture service for Milestone 4 systemd recovery
integration tests.  It is **not** intended for production use.

## What it does

`bin/exocomp-fixture` is a Python 3 daemon that:

- Serves a minimal HTTP health endpoint (default `http://127.0.0.1:8877/health`)
  returning `{"status":"ok"}` or `{"status":"degraded"}`.
- Writes a workload marker file (`$FIXTURE_STATE_DIR/workload.marker`) on every
  poll cycle, proving the process is alive and doing work.
- Reads a mode-control file (`$FIXTURE_STATE_DIR/mode`) and changes behaviour
  accordingly within the poll interval (default 1 s).

## Modes

| Mode              | Behaviour |
|-------------------|-----------|
| `active`          | Healthy, normal operation. Health endpoint returns `{"status":"ok"}` with HTTP 200. |
| `degraded`        | Process stays alive; health endpoint returns `{"status":"degraded"}` with HTTP 503. Demonstrates that health can disagree with systemd active state. |
| `failed`          | Exits immediately with code 1. systemd marks the unit as failed. |
| `flapping`        | Exits immediately with code 1, triggering rapid restart cycles. |
| `restart-failure` | Exits immediately with code 1 every time, exhausting `StartLimitBurst`. |

The default mode (when the mode file is absent) is `active`.

## Usage

```sh
# Start on the default port in the default state directory:
./bin/exocomp-fixture

# Custom port and state directory:
./bin/exocomp-fixture --port 9000 --state-dir /tmp/fixture

# Using environment variables:
FIXTURE_PORT=9000 FIXTURE_STATE_DIR=/tmp/fixture ./bin/exocomp-fixture
```

### Switching modes at runtime

```sh
# Enter degraded mode (process stays alive, health returns unhealthy):
echo degraded > /run/exocomp-fixture/mode

# Return to healthy:
echo active > /run/exocomp-fixture/mode

# Trigger a clean exit with code 1:
echo failed > /run/exocomp-fixture/mode
```

## Environment variables

| Variable               | Default                  | Description |
|------------------------|--------------------------|-------------|
| `FIXTURE_PORT`         | `8877`                   | HTTP bind port |
| `FIXTURE_ADDR`         | `127.0.0.1`              | HTTP bind address |
| `FIXTURE_STATE_DIR`    | `/run/exocomp-fixture`   | Directory for mode file and workload marker |
| `FIXTURE_POLL_INTERVAL`| `1.0`                    | Mode-file poll interval in seconds |

## CLI flags

All environment variables have corresponding CLI flags that take precedence:

```
--port PORT
--addr ADDR
--state-dir DIR
--poll-interval SECONDS
```

## Health endpoint

```
GET /health
```

| Mode       | Status code | Body                     |
|------------|-------------|--------------------------|
| `active`   | 200         | `{"status": "ok"}`       |
| `degraded` | 503         | `{"status": "degraded"}` |

All other paths return HTTP 404.

## Tests

Tests live in `test/test_fixture.py` and require Python 3.11+.  They launch
the fixture as a subprocess and exercise all modes and transitions without
needing systemd.

```sh
# Via Makefile:
make test-fixture-service

# Directly:
python3 -m pytest test/fixtures/exocomp_fixture/test/test_fixture.py -v
```

## Related tasks

- **EXOCOMP-69** — this daemon script (prerequisite)
- **EXOCOMP-70** — systemd unit file, installer, and cleanup
- **EXOCOMP-71** — ExUnit integration tests that use this fixture
- **EXOCOMP-29** — parent feature: M4 systemd recovery fixture
