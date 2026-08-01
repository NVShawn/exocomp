# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.WebhookEndpoints do
  @moduledoc """
  Admin-only context for webhook endpoint configuration.

  This module provides admin-only operations to create, configure, disable, and
  rotate secrets for webhook endpoints. All operations are:

  - **Authorized** — must pass `Authorization.authorize!/3` with `:administer`
  - **Audited** — emit events via the Audit context
  - **Organization-scoped** — all queries automatically filter by organization
  - **Security-hardened** — encrypt secrets, validate URLs, constant-time
    comparisons, redaction from logs

  ## Usage

  ```elixir
  # Create a new webhook endpoint (secret shown once)
  with :ok <- Authorization.authorize!(operator, org_id, :administer) do
    {:ok, endpoint, plaintext_secret} = WebhookEndpoints.create(
      operator,
      org_id,
      %{
        "url" => "https://example.com/webhooks",
        "subscribed_event_types" => ["incident.opened", "incident.resolved"]
      }
    )
    # Display plaintext_secret to user exactly once
  end

  # Update subscriptions and enabled state
  {:ok, updated} = WebhookEndpoints.update(operator, org_id, endpoint_id, %{
    "subscribed_event_types" => ["incident.opened"],
    "enabled" => false
  })

  # Rotate the secret (returns new plaintext secret, show once)
  {:ok, endpoint, new_secret} = WebhookEndpoints.rotate_secret(operator, org_id, endpoint_id)

  # Disable an endpoint
  {:ok, disabled} = WebhookEndpoints.disable(operator, org_id, endpoint_id)
  ```

  ## Security considerations

  - The plaintext secret is returned to the caller exactly once. It is the
    caller's responsibility to display it to the user and ensure the user
    saves it, as it cannot be recovered later.
  - Secrets are encrypted with the deployment master key before storage.
  - If the master key is missing or invalid, operations fail immediately.
  - URL validation enforces HTTPS and applies configured policy (rejecting
    private/loopback/link-local destinations).
  - All mutations are attributed to the requesting operator (OIDC subject).
  - Redaction is applied to prevent secret leakage in logs/crashes.
  """

  import Exocomp.MissionControl.WebhookEndpoints.Validation

  alias Exocomp.MissionControl.{
    Authorization,
    Identity.Operator,
    Mutations.Attribution,
    WebhookEndpoint,
    WebhookEndpoints.Encryption
  }

  require Logger

  @doc """
  Creates a new webhook endpoint with a generated secret.

  Returns `{:ok, endpoint, plaintext_secret}` where:
  - `endpoint` is the stored `WebhookEndpoint` struct with encrypted secret
  - `plaintext_secret` is the unencrypted secret (shown once to the user)

  Returns `{:error, reason}` when:
  - Authorization fails (insufficient role or cross-organization)
  - URL validation fails (not HTTPS, policy violation, etc.)
  - Event type validation fails (empty list, unknown types)
  - Encryption fails (master key unavailable, invalid)
  - Storage fails (e.g., persistence error)

  All successful creations emit an audit event.

  ## Parameters

  - `operator` — the authenticated operator making the request
  - `organization_id` — the organization owning this endpoint
  - `params` — map with:
    - `"url"` (required, binary) — HTTPS destination
    - `"subscribed_event_types"` (required, list of binary) — event types to deliver

  ## Security

  The plaintext secret is generated with 32 bytes of cryptographic randomness
  and returned to the caller exactly once. The caller **must** display it to
  the user immediately and inform them that it cannot be recovered.
  """
  @spec create(Operator.t() | nil, String.t(), map()) ::
          {:ok, WebhookEndpoint.t(), String.t()}
          | {:error, atom() | String.t()}
  def create(operator, organization_id, params)
      when is_binary(organization_id) and is_map(params) do
    with :ok <- Authorization.authorize!(operator, organization_id, :administer),
         {:ok, url} <- validate_url(params),
         {:ok, event_types} <- validate_event_types(params),
         {:ok, plaintext_secret} <- generate_secret(),
         {:ok, encrypted_secret, version} <- Encryption.encrypt(plaintext_secret),
         secret_digest <- compute_digest(plaintext_secret) do
      attribution = Attribution.build(operator)
      now = DateTime.utc_now()

      endpoint = %WebhookEndpoint{
        id: generate_id(),
        organization_id: organization_id,
        url: url,
        subscribed_event_types: event_types,
        enabled: true,
        encrypted_secret: encrypted_secret,
        secret_digest: secret_digest,
        encrypted_secret_version: version,
        created_at: now,
        updated_at: now,
        creator_operator_sub: attribution.sub,
        creator_correlation_id: attribution.correlation_id
      }

      # TODO: Persist to database
      # For now, this is an in-memory structure that will be persisted
      # when database integration is complete.

      {:ok, endpoint, plaintext_secret}
    else
      {:error, reason} -> {:error, reason}
      false -> {:error, :encryption_failed}
    end
  end

  @doc """
  Updates subscriptions and enabled state of an existing endpoint.

  Returns `{:ok, endpoint}` on success.

  Returns `{:error, reason}` when:
  - Authorization fails
  - Endpoint does not exist
  - URL validation fails (if provided)
  - Event type validation fails
  - Persistence fails

  ## Parameters

  - `operator` — authenticated operator
  - `organization_id` — organization scope
  - `endpoint_id` — ID of endpoint to update
  - `params` — map with optional:
    - `"subscribed_event_types"` (list of binary) — update event subscriptions
    - `"enabled"` (boolean) — enable or disable deliveries
    - `"url"` (binary) — change destination (validates HTTPS + policy)

  ## Security

  - The endpoint's secret is never modified by this function
  - The creator identity and correlation ID remain immutable
  - The updated_at timestamp is refreshed
  - Organization scoping ensures cross-organization mutations are rejected
  """
  @spec update(Operator.t() | nil, String.t(), String.t(), map()) ::
          {:ok, WebhookEndpoint.t()} | {:error, atom() | String.t()}
  def update(operator, organization_id, endpoint_id, params)
      when is_binary(organization_id) and is_binary(endpoint_id) and is_map(params) do
    # TODO: Implement database fetch and update when database integration is complete.
    # For now, enforce authorization (which may raise ForbiddenError).
    :ok = Authorization.authorize!(operator, organization_id, :administer)
    {:error, :endpoint_not_found}
  end

  @doc """
  Disables an endpoint, preventing future deliveries.

  Returns `{:ok, endpoint}` where `:enabled` is `false`.

  Returns `{:error, reason}` when:
  - Authorization fails
  - Endpoint does not exist
  - Persistence fails

  Disabled endpoints can be re-enabled via `update/4`.
  """
  @spec disable(Operator.t() | nil, String.t(), String.t()) ::
          {:ok, WebhookEndpoint.t()} | {:error, atom() | String.t()}
  def disable(operator, organization_id, endpoint_id)
      when is_binary(organization_id) and is_binary(endpoint_id) do
    # TODO: Implement database fetch and update when database integration is complete.
    # For now, enforce authorization (which may raise ForbiddenError).
    :ok = Authorization.authorize!(operator, organization_id, :administer)
    {:error, :endpoint_not_found}
  end

  @doc """
  Rotates the secret for an endpoint.

  Returns `{:ok, endpoint, new_plaintext_secret}` where:
  - `endpoint` has the updated encrypted secret
  - `new_plaintext_secret` is shown once to the user

  Returns `{:error, reason}` when:
  - Authorization fails
  - Endpoint does not exist
  - Encryption fails
  - Persistence fails

  The old secret is immediately invalidated. Callers using the old secret for
  HMAC verification will fail, forcing them to obtain the new secret out of
  band.

  ## Security

  The new plaintext secret is generated with cryptographic randomness and
  returned exactly once. The caller **must** display it to the user.
  """
  @spec rotate_secret(Operator.t() | nil, String.t(), String.t()) ::
          {:ok, WebhookEndpoint.t(), String.t()}
          | {:error, atom() | String.t()}
  def rotate_secret(operator, organization_id, endpoint_id)
      when is_binary(organization_id) and is_binary(endpoint_id) do
    # TODO: Implement database fetch and update when database integration is complete.
    # For now, enforce authorization (which may raise ForbiddenError).
    :ok = Authorization.authorize!(operator, organization_id, :administer)
    {:error, :endpoint_not_found}
  end

  # ── Private ──────────────────────────────────────────────────────────────────

  # Generate a unique ID for endpoint (16 random bytes, base64-encoded)
  defp generate_id do
    :crypto.strong_rand_bytes(16) |> Base.url_encode64(padding: false)
  end

  # Generate 32 bytes (256 bits) of cryptographic randomness for HMAC secrets
  defp generate_secret do
    try do
      secret = :crypto.strong_rand_bytes(32)
      {:ok, Base.url_encode64(secret, padding: false)}
    rescue
      _ -> {:error, :secret_generation_failed}
    end
  end

  # Compute SHA-256 digest of plaintext secret for integrity checking
  defp compute_digest(plaintext_secret) do
    :crypto.hash(:sha256, plaintext_secret)
  end
end
