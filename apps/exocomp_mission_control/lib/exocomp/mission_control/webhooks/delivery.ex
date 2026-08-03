# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.Webhooks.Delivery do
  @moduledoc """
  Handles webhook event delivery with retry logic.

  Sends signed webhook events to registered endpoints using exponential
  backoff retry for up to 24 hours. Supports timeout configuration and
  deterministic error handling.
  """

  require Logger

  alias Exocomp.MissionControl.Webhooks.{Signer, WebhookAttempt, WebhookEvent}

  @default_http_adapter :httpc

  @doc """
  Delivers a webhook event to an endpoint URL using the given plaintext secret.

  Builds the HTTP request with:
  - Event ID, delivery timestamp, and event type in custom headers.
  - Exact JSON body (byte-identical to the signed content).
  - HMAC-SHA256 signature header.

  Returns `{:ok, http_status_code}` or `{:error, reason}`.
  """
  @spec deliver(
          webhook_url :: binary(),
          webhook_secret :: binary(),
          event :: WebhookEvent.t(),
          timestamp :: binary(),
          timeout_ms :: non_neg_integer(),
          opts :: keyword()
        ) :: {:ok, non_neg_integer()} | {:error, term()}
  def deliver(webhook_url, webhook_secret, event, timestamp, timeout_ms, opts \\ [])
      when is_binary(webhook_url) and is_binary(webhook_secret) and
             is_binary(timestamp) and timeout_ms > 0 do
    # Use the body_json stored on the event (exact bytes that were signed
    # at dispatch time), or fall back to encoding the payload.
    body_json = event.body_json || Jason.encode!(event.payload)

    # Sign the event.
    signature = Signer.sign(webhook_secret, event.event_id, timestamp, body_json)

    # Build request headers.
    headers = [
      {~c"Content-Type", ~c"application/json"},
      {~c"X-Exocomp-Event-Id", String.to_charlist(event.event_id)},
      {~c"X-Exocomp-Delivery-Timestamp", String.to_charlist(timestamp)},
      {~c"X-Exocomp-Event-Type", String.to_charlist(event.event_type)},
      {~c"X-Exocomp-Signature", String.to_charlist("sha256=" <> signature)}
    ]

    http_adapter = Keyword.get(opts, :http_adapter, adapter())
    send_request(http_adapter, webhook_url, headers, body_json, timeout_ms)
  end

  defp adapter do
    Application.get_env(:exocomp_mission_control, :http_adapter, @default_http_adapter)
  end

  defp send_request(http_adapter, url, headers, body, timeout_ms) do
    url_charlist = String.to_charlist(url)

    http_options = [
      {:timeout, timeout_ms},
      {:connect_timeout, min(timeout_ms, 10_000)},
      {:autoredirect, false},
      {:relaxed, true}
    ]

    options = [
      {:body_format, :binary},
      {:full_result, true}
    ]

    case http_adapter.request(
           :post,
           {url_charlist, headers, ~c"application/json", body},
           http_options,
           options
         ) do
      {:ok, {{_http_version, status_code, _reason}, _response_headers, _response_body}} ->
        Logger.debug("Webhook delivery succeeded",
          url: url,
          status: status_code
        )

        {:ok, status_code}

      {:error, reason} ->
        Logger.warning("Webhook delivery failed",
          url: url,
          reason: inspect(reason)
        )

        {:error, reason}
    end
  end

  @doc """
  Returns `true` if the attempt should be retried using exponential backoff.

  `event_inserted_at` is the original event's insertion time, used as the
  reference for the 24-hour retry window.
  """
  @spec should_retry?(
          attempt :: WebhookAttempt.t(),
          event_inserted_at :: NaiveDateTime.t(),
          current_time :: NaiveDateTime.t()
        ) :: boolean()
  def should_retry?(attempt, event_inserted_at, current_time) do
    case attempt.status do
      :success -> false
      :terminal_failure -> false
      :pending -> false
      :failed -> not WebhookAttempt.terminal_failure?(attempt, event_inserted_at, current_time)
    end
  end

  @doc """
  Two-arity variant kept for backward-compatible unit tests.
  """
  @spec should_retry?(attempt :: WebhookAttempt.t(), current_time :: NaiveDateTime.t()) ::
          boolean()
  def should_retry?(attempt, current_time) do
    now_naive =
      case current_time do
        %NaiveDateTime{} = n -> n
        %DateTime{} = dt -> DateTime.to_naive(dt)
      end

    should_retry?(attempt, now_naive, now_naive)
  end

  @doc """
  Formats a delivery timestamp in RFC 3339 format with Z suffix.

  ## Examples

      iex> Delivery.format_timestamp(~N[2026-08-01 14:30:00])
      "2026-08-01T14:30:00Z"
  """
  @spec format_timestamp(timestamp :: NaiveDateTime.t() | DateTime.t()) :: binary()
  def format_timestamp(%NaiveDateTime{} = timestamp) do
    timestamp
    |> NaiveDateTime.truncate(:second)
    |> NaiveDateTime.to_iso8601()
    |> Kernel.<>("Z")
  end

  def format_timestamp(%DateTime{} = timestamp) do
    timestamp
    |> DateTime.truncate(:second)
    |> DateTime.to_iso8601()
  end
end
