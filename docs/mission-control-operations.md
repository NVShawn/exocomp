# Mission Control OCI image

Mission Control is published as a Linux OCI image containing the production
`mission_control` OTP release. The image is built in the same architecture-
specific, digest-pinned Elixir/OTP builder as the other Exocomp releases:

```sh
make build-mission-control-amd64
make build-mission-control-arm64
```

Each build writes a manifest, SHA-256 checksum file, SPDX SBOM, SLSA
provenance statement, and license-coverage report under
`dist/mission-control/`. The final image contains the compiled release, the
project and dependency notices, and no source tree, build tools, credentials,
or test fixtures. `make inspect-mission-control-deps-amd64` (or `-arm64`)
inspects the release's ELF dependencies before an image is published.

## Runtime contract

Run the image as UID `10001:10001` with a read-only root filesystem. Mount the
two documented state paths and provide a tmpfs for `/tmp`:

```sh
docker run --rm --read-only \
  --tmpfs /tmp:rw,nosuid,nodev \
  --mount type=volume,source=mission-control-state,target=/var/lib/exocomp/mission-control \
  --mount type=volume,source=mission-control-logs,target=/var/log/exocomp/mission-control \
  --env-file /run/secrets/mission-control.env \
  --publish 4000:4000 \
  exocomp/mission-control:0.1.0-amd64 server
```

The environment file must provide `DATABASE_URL`, `SECRET_KEY_BASE`, and
`RELEASE_COOKIE`. The entrypoint rejects a missing value before starting the
release and never prints secret values. The application-specific OIDC and PKI
secrets are supplied through the same external secret mechanism; no secret is
accepted as a build argument or embedded in the image.

The only supported entrypoint commands are:

```sh
# Run once, as a release eval; this does not require Mix or Elixir.
docker run --rm --read-only --tmpfs /tmp:rw,nosuid,nodev \
  --mount type=volume,source=mission-control-state,target=/var/lib/exocomp/mission-control \
  --env-file /run/secrets/mission-control.env \
  exocomp/mission-control:0.1.0-amd64 migrate

# Start the web server and supervision tree.
docker run --rm --read-only --tmpfs /tmp:rw,nosuid,nodev \
  --mount type=volume,source=mission-control-state,target=/var/lib/exocomp/mission-control \
  --mount type=volume,source=mission-control-logs,target=/var/log/exocomp/mission-control \
  --env-file /run/secrets/mission-control.env \
  exocomp/mission-control:0.1.0-amd64 server
```

Migrations are intentionally separate from server startup so a replica
restart never races a schema migration. Run `migrate` exactly once per image
upgrade, wait for exit status zero, then roll the server replicas. A restart
reuses the mounted state and database and runs only `server`.

The image healthcheck invokes `Exocomp.MissionControl.Release.healthcheck/0`. It must
report ready only after the database pool and application supervision tree are
healthy. The image exposes port 4000; TLS termination and OIDC ingress policy
remain deployment concerns.

## PostgreSQL packaging test

The integration harness starts a disposable PostgreSQL container, invokes the
release migration once, starts the image with `--read-only`, checks the
readiness healthcheck, restarts it, and verifies that the missing-secret path
fails closed:

```sh
make test-mission-control-image \
  IMAGE=exocomp/mission-control:0.1.0-amd64 \
  POSTGRES_IMAGE=docker.io/library/postgres:16.4@sha256:<verified-digest>
```

The PostgreSQL image must be supplied with a complete digest. The harness
generates disposable credentials at runtime, never writes them to the
repository, and removes its containers, volumes, and network on exit.
# Mission Control operations

Mission Control exposes local service probes and aggregate Prometheus metrics
from the same HTTP listener as the operator service.

## Health probes

| Endpoint | Purpose | Success | Failure |
|---|---|---:|---:|
| `GET /health` | Backward-compatible liveness probe | `200` | — |
| `GET /health/live` | Process liveness; independent of PostgreSQL and clusters | `200` | — |
| `GET /health/ready` | Database connectivity, migration state, and critical local workers | `200` | `401` when guarded or `503` when not ready |

Liveness returns only `{"status":"ok"}`. Readiness returns fixed check names
(`database`, `migrations`, and `supervision`) and fixed states; it never
includes database errors, credentials, tenant records, cluster IDs, or node
IDs. Set `EXOCOMP_READINESS_TOKEN` to require a bearer token for readiness.
The token is compared in constant time and is never included in a response.

Readiness intentionally does not require any cluster connection. A cluster may
be disconnected while the control plane is ready to accept local work.

## Prometheus

`GET /metrics` returns Prometheus text exposition format. The metric schema is
defined by `Exocomp.MissionControl.Metrics.definitions/0`; labels are limited
to fixed lifecycle values such as `state`, `outcome`, `severity`, and
`status`. Cluster, node, organization, tenant, URL, session, and event IDs are
not labels.

The exported families cover connection state, event ingest outcomes and lag,
incidents, conversation/proposal latency, command state, webhook outcomes,
database pool/queue state, retention status, and desired-service/recovery
qualification outcomes.
