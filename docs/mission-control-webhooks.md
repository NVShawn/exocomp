# Mission Control Webhook Configuration

Mission Control stores organization-scoped webhook endpoint configuration. HTTP
delivery is a separate capability; this document covers secure configuration
only.

## Deployment master key

Set `MISSION_CONTROL_WEBHOOK_MASTER_KEY` in the deployment secret store before
an administrator creates or rotates an endpoint. Its value must be standard
base64 encoding of exactly 32 random bytes. For example, generate the value in
a secure operator environment and put the output directly into the secret
store:

```bash
openssl rand -base64 32
```

Do not commit this value, place it in a unit file, print it in diagnostics, or
add it to an endpoint URL. Mission Control fails closed when the key is absent
or malformed. Keep the key stable: deployment-master-key rotation requires a
dedicated re-encryption procedure and is not performed by endpoint secret
rotation.

## Endpoint safety controls

Only administrators in the endpoint's organization can create, update,
disable, or rotate an endpoint. Endpoint URLs must use HTTPS and cannot embed
credentials or sensitive query parameters. The default outbound policy rejects
loopback, private, link-local, multicast, unspecified, and other reserved IPv4
and IPv6 destinations. Hostnames are checked against every A and AAAA response
before configuration is saved.

Application configuration may additionally specify exact or `*.suffix` blocked
domains and blocked IP/CIDR ranges:

```elixir
config :exocomp_mission_control, Exocomp.MissionControl.WebhookEndpoints.Policy,
  blocked_domains: ["*.internal.example"],
  blocked_ips: ["8.8.8.0/24"]
```

Invalid policy configuration fails closed.

## Signing secrets

Creation and secret rotation each show a newly generated HMAC secret once.
Copy it to the receiving integration immediately; it cannot be displayed
again. Mission Control stores only AES-256-GCM ciphertext bound to that
endpoint and organization. Plaintext signing secrets are excluded from the
endpoint record and its audit events.
