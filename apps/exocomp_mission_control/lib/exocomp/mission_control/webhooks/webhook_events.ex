# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.WebhookEvents do
  @moduledoc """
  Durable webhook event dispatch, delivery, and admin inspection.

  ## Dispatch flow

  1. Redact the payload using the Mission Control audit boundary.
  2. Serialize the redacted payload to the canonical JSON body.
  3. Persist a `WebhookEvent` record with a unique, organization-scoped
     event ID and the exact JSON bytes used for signing.
  4. Find all enabled `WebhookEndpoint` records subscribed to the event type.
  5. For each matching endpoint: decrypt its secret, create a `WebhookAttempt`
     record, attempt immediate delivery, and persist the outcome.

  ## Retry

  Callers schedule retries by polling `due_retries/1` and calling
  `process_attempt/2` for each returned attempt.

  ## Replay

  Admins create a new delivery attempt for a retained event via `replay/5`.
  The event's stored `body_json` is used verbatim so the re-delivered request
  body is byte-identical to what was originally signed.

  ## Redaction

  Payload fields matching the `Redaction` sensitive-key list are replaced with
  `"[REDACTED]"` before persistence and delivery. This is identical to the
  audit-event boundary.
  """

  require Logger

  import Ecto.Query

  alias Exocomp.MissionControl.{
    Authorization,
    Identity.Operator,
    OrganizationScope,
    Redaction,
    Repo,
    WebhookEndpoint,
    WebhookEndpoints.Encryption
  }

  alias Exocomp.MissionControl.Webhooks.{
    Delivery,
    WebhookAttempt,
    WebhookEvent
  }

  # Default per-endpoint delivery timeout in milliseconds.
  @default_timeout_ms 30_000

  @type dispatch_result ::
          {:ok, WebhookEvent.t(), [WebhookAttempt.t()]} | {:error, term()}

  @type replay_result ::
          {:ok, WebhookAttempt.t()} | {:error, term()}

  # ---------------------------------------------------------------------------
  # Public API
  # ---------------------------------------------------------------------------

  @doc """
  Dispatches a new webhook event to all enabled, subscribed endpoints.

  The payload is redacted before persistence or delivery. Returns the persisted
  event and a list of delivery attempt records (one per matching endpoint).

  Options:
  - `:repo` — Ecto repository to use (default: `Repo`).
  - `:http_adapter` — HTTP client module for testing (default: `:httpc`).
  - `:timeout_ms` — per-delivery timeout in milliseconds (default: 30_000).
  """
  @spec dispatch(
          organization_id :: String.t(),
          event_type :: String.t(),
          payload :: map(),
          opts :: keyword()
        ) :: dispatch_result()
  def dispatch(organization_id, event_type, payload, opts \\ [])
      when is_binary(organization_id) and is_binary(event_type) and is_map(payload) and
             is_list(opts) do
    repo = Keyword.get(opts, :repo, Repo)

    with {:ok, org_id} <- OrganizationScope.require_id(organization_id),
         {:ok, event} <- persist_event(repo, org_id, event_type, payload) do
      endpoints = find_enabled_endpoints(repo, org_id, event_type)
      now = DateTime.utc_now()

      attempts =
        Enum.map(endpoints, fn endpoint ->
          deliver_to_endpoint(repo, event, endpoint, now, opts)
        end)

      {:ok, event, attempts}
    end
  end

  @doc """
  Creates a new delivery attempt for a retained event (admin replay).

  An admin operator is required. The stored `body_json` is used verbatim
  so the re-delivered body is byte-identical to the originally signed content.

  Options:
  - `:repo` — Ecto repository to use (default: `Repo`).
  - `:http_adapter` — HTTP client module for testing.
  - `:timeout_ms` — per-delivery timeout in milliseconds (default: 30_000).
  """
  @spec replay(
          operator :: Operator.t() | nil,
          organization_id :: String.t(),
          event_id :: String.t(),
          endpoint_id :: String.t(),
          opts :: keyword()
        ) :: replay_result()
  def replay(operator, organization_id, event_id, endpoint_id, opts \\ [])
      when is_binary(organization_id) and is_binary(event_id) and is_binary(endpoint_id) and
             is_list(opts) do
    :ok = Authorization.authorize!(operator, organization_id, :administer)
    repo = Keyword.get(opts, :repo, Repo)

    with {:ok, org_id} <- OrganizationScope.require_id(organization_id),
         {:ok, event} <- get_event_scoped(repo, org_id, event_id),
         {:ok, endpoint} <- get_endpoint_scoped(repo, org_id, endpoint_id) do
      now = DateTime.utc_now()
      attempt = deliver_to_endpoint(repo, event, endpoint, now, opts)
      {:ok, attempt}
    end
  end

  @doc """
  Lists webhook events for an organization, newest first.

  Options:
  - `:repo` — Ecto repository to use (default: `Repo`).
  - `:limit` — maximum number of records to return (default: 100).
  """
  @spec list_events(organization_id :: String.t(), opts :: keyword()) ::
          {:ok, [WebhookEvent.t()]} | {:error, :organization_required}
  def list_events(organization_id, opts \\ []) when is_list(opts) do
    repo = Keyword.get(opts, :repo, Repo)
    limit = Keyword.get(opts, :limit, 100)

    with {:ok, org_id} <- OrganizationScope.require_id(organization_id) do
      events =
        WebhookEvent
        |> OrganizationScope.query(org_id)
        |> order_by([e], desc: e.inserted_at, desc: e.id)
        |> limit(^limit)
        |> repo.all()

      {:ok, events}
    end
  end

  @doc """
  Returns one event with all its delivery attempts, scoped to org.

  Options:
  - `:repo` — Ecto repository to use (default: `Repo`).
  """
  @spec get_event_with_attempts(
          organization_id :: String.t(),
          event_id :: String.t(),
          opts :: keyword()
        ) :: {:ok, WebhookEvent.t(), [WebhookAttempt.t()]} | {:error, term()}
  def get_event_with_attempts(organization_id, event_id, opts \\ [])
      when is_binary(organization_id) and is_binary(event_id) and is_list(opts) do
    repo = Keyword.get(opts, :repo, Repo)

    with {:ok, org_id} <- OrganizationScope.require_id(organization_id),
         {:ok, event} <- get_event_scoped(repo, org_id, event_id) do
      attempts =
        WebhookAttempt
        |> where([a], a.webhook_event_id == ^event.id)
        |> order_by([a], asc: a.inserted_at)
        |> repo.all()

      {:ok, event, attempts}
    end
  end

  @doc """
  Returns pending attempts whose `next_retry_at` is in the past.

  Suitable for a background job that polls for due work.
  """
  @spec due_retries(opts :: keyword()) :: [WebhookAttempt.t()]
  def due_retries(opts \\ []) do
    repo = Keyword.get(opts, :repo, Repo)
    now = DateTime.utc_now()

    WebhookAttempt
    |> where([a], a.status == :pending and a.next_retry_at <= ^now)
    |> order_by([a], asc: a.next_retry_at)
    |> repo.all()
  end

  @doc """
  Processes one pending retry attempt.

  Fetches the associated event and endpoint, decrypts the secret, delivers,
  and updates the attempt record.
  """
  @spec process_attempt(attempt_id :: String.t(), opts :: keyword()) ::
          {:ok, WebhookAttempt.t()} | {:error, term()}
  def process_attempt(attempt_id, opts \\ []) when is_binary(attempt_id) and is_list(opts) do
    repo = Keyword.get(opts, :repo, Repo)

    with {:ok, uuid} <- Ecto.UUID.cast(attempt_id) do
      attempt = repo.get(WebhookAttempt, uuid)
      event = attempt && repo.get(WebhookEvent, attempt.webhook_event_id)
      endpoint = attempt && event && repo.get(WebhookEndpoint, attempt.webhook_endpoint_id)

      cond do
        is_nil(attempt) -> {:error, :not_found}
        is_nil(event) -> {:error, :not_found}
        is_nil(endpoint) -> {:error, :not_found}
        true ->
          now = DateTime.utc_now()
          updated = execute_delivery(repo, attempt, event, endpoint, now, opts)
          {:ok, updated}
      end
    else
      :error -> {:error, :invalid_id}
    end
  end

  # ---------------------------------------------------------------------------
  # Private helpers
  # ---------------------------------------------------------------------------

  defp persist_event(repo, organization_id, event_type, raw_payload) do
    redacted_payload = Redaction.redact(raw_payload)
    body_json = Jason.encode!(redacted_payload)
    event_id = WebhookEvent.generate_event_id()

    changeset =
      WebhookEvent.changeset(%WebhookEvent{}, %{
        organization_id: organization_id,
        event_id: event_id,
        event_type: event_type,
        payload: redacted_payload,
        body_json: body_json
      })

    case repo.insert(changeset) do
      {:ok, event} ->
        {:ok, event}

      {:error, %Ecto.Changeset{} = cs} ->
        Logger.warning("Failed to persist webhook event",
          organization_id: organization_id,
          event_type: event_type,
          errors: inspect(cs.errors)
        )

        {:error, cs}
    end
  end

  defp find_enabled_endpoints(repo, organization_id, event_type) do
    WebhookEndpoint
    |> OrganizationScope.query(organization_id)
    |> where([ep], ep.enabled == true)
    |> where([ep], ^event_type in ep.subscribed_event_types)
    |> repo.all()
  end

  defp deliver_to_endpoint(repo, event, endpoint, now, opts) do
    attempt_number = next_attempt_number(repo, event.id, endpoint.id)
    timestamp = Delivery.format_timestamp(now)

    {:ok, attempt} =
      %WebhookAttempt{}
      |> WebhookAttempt.changeset(%{
        webhook_event_id: event.id,
        webhook_endpoint_id: endpoint.id,
        status: :pending,
        attempt_number: attempt_number,
        delivery_timestamp: timestamp
      })
      |> repo.insert()

    execute_delivery(repo, attempt, event, endpoint, now, opts)
  end

  defp execute_delivery(repo, attempt, event, endpoint, now, opts) do
    timestamp = attempt.delivery_timestamp || Delivery.format_timestamp(now)
    aad = endpoint.organization_id <> "\0" <> endpoint.id
    timeout_ms = Keyword.get(opts, :timeout_ms, @default_timeout_ms)

    case Encryption.decrypt(
           endpoint.encrypted_secret,
           endpoint.encrypted_secret_version,
           aad
         ) do
      {:ok, plaintext_secret} ->
        case Delivery.deliver(endpoint.url, plaintext_secret, event, timestamp, timeout_ms, opts) do
          {:ok, http_status} ->
            attrs = outcome_attrs(http_status, event, attempt, now)
            update_attempt(repo, attempt, attrs)

          {:error, reason} ->
            attrs = error_attrs(reason, event, attempt, now)
            update_attempt(repo, attempt, attrs)
        end

      {:error, reason} ->
        Logger.error("Failed to decrypt webhook endpoint secret",
          endpoint_id: endpoint.id,
          reason: inspect(reason)
        )

        update_attempt(repo, attempt, %{
          status: :terminal_failure,
          error_reason: "secret_decryption_failed"
        })
    end
  end

  # 2xx: success
  defp outcome_attrs(http_status, _event, _attempt, _now)
       when http_status >= 200 and http_status < 300 do
    %{status: :success, http_status: http_status}
  end

  # Non-2xx: check for terminal failure vs retryable
  defp outcome_attrs(http_status, event, attempt, now) do
    event_naive = datetime_to_naive(event.inserted_at)
    now_naive = datetime_to_naive(now)
    terminal? = WebhookAttempt.terminal_failure?(%{attempt | http_status: http_status}, event_naive, now_naive)

    if terminal? do
      %{status: :terminal_failure, http_status: http_status}
    else
      next_retry = WebhookAttempt.next_retry_time(attempt.attempt_number, now_naive)
      %{status: :failed, http_status: http_status, next_retry_at: naive_to_utc(next_retry)}
    end
  end

  # Network-level errors (no HTTP status)
  defp error_attrs(reason, event, attempt, now) do
    event_naive = datetime_to_naive(event.inserted_at)
    now_naive = datetime_to_naive(now)
    terminal? = WebhookAttempt.terminal_failure?(%{attempt | http_status: nil}, event_naive, now_naive)

    if terminal? do
      %{status: :terminal_failure, error_reason: inspect(reason)}
    else
      next_retry = WebhookAttempt.next_retry_time(attempt.attempt_number, now_naive)
      %{status: :failed, error_reason: inspect(reason), next_retry_at: naive_to_utc(next_retry)}
    end
  end

  defp update_attempt(repo, attempt, attrs) do
    attempt
    |> WebhookAttempt.changeset(attrs)
    |> repo.update!()
  end

  defp next_attempt_number(repo, event_id, endpoint_id) do
    count =
      WebhookAttempt
      |> where([a], a.webhook_event_id == ^event_id and a.webhook_endpoint_id == ^endpoint_id)
      |> repo.aggregate(:count, :id)

    count + 1
  end

  defp get_event_scoped(repo, organization_id, event_id) do
    case WebhookEvent
         |> OrganizationScope.query(organization_id)
         |> where([e], e.event_id == ^event_id)
         |> repo.one() do
      %WebhookEvent{} = event -> {:ok, event}
      nil -> {:error, :event_not_found}
    end
  end

  defp get_endpoint_scoped(repo, organization_id, endpoint_id) do
    with {:ok, endpoint_uuid} <- Ecto.UUID.cast(endpoint_id) do
      case WebhookEndpoint
           |> OrganizationScope.query(organization_id)
           |> where([ep], ep.id == ^endpoint_uuid)
           |> repo.one() do
        %WebhookEndpoint{} = endpoint -> {:ok, endpoint}
        nil -> {:error, :endpoint_not_found}
      end
    else
      :error -> {:error, :endpoint_not_found}
    end
  end

  defp datetime_to_naive(%DateTime{} = dt), do: DateTime.to_naive(dt)
  defp datetime_to_naive(%NaiveDateTime{} = n), do: n

  defp naive_to_utc(%NaiveDateTime{} = n), do: DateTime.from_naive!(n, "Etc/UTC")
end
