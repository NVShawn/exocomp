# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.Webhooks.Delivery do
  @moduledoc """
  Handles webhook event delivery with retry logic.

  Sends signed webhook events to registered endpoints with exponential backoff
  retry for up to 24 hours. Supports timeout configuration and deterministic
  error handling.
  """

  require Logger

  alias Exocomp.MissionControl.Webhooks.{Signer, WebhookAttempt, WebhookEvent}

  @http_adapter Application.compile_env(:exocomp_mission_control, :http_adapter, :httpc)

  @doc """
  Delivers a webhook event to an endpoint.

  Builds the HTTP request with:
  - Event ID, delivery timestamp, and event type in headers
  - Exact JSON body (byte-identical to signed content)
  - HMAC-SHA256 signature

  Returns `{:ok, response_status}` or `{:error, reason}`.
  """
  @spec deliver(
          webhook_url :: binary,
          webhook_secret :: binary,
          event :: WebhookEvent.t(),
          timestamp :: binary,
          timeout_ms :: non_neg_integer
        ) :: {:ok, non_neg_integer} | {:error, term}
  def deliver(webhook_url, webhook_secret, event, timestamp, timeout_ms)
      when is_binary(webhook_url) and is_binary(webhook_secret) and
             is_binary(timestamp) and timeout_ms > 0 do
    # Convert payload to JSON (exact bytes used for signature)
    body_json = Jason.encode!(event.payload)

    # Sign the event
    signature = Signer.sign(webhook_secret, event.event_id, timestamp, body_json)

    # Build request headers
    headers = [
      {~c'Content-Type', ~c'application/json'},
      {~c'X-Exocomp-Event-Id', String.to_charlist(event.event_id)},
      {~c'X-Exocomp-Delivery-Timestamp', String.to_charlist(timestamp)},
      {~c'X-Exocomp-Event-Type', String.to_charlist(event.event_type)},
      {~c'X-Exocomp-Signature', String.to_charlist(signature)}
    ]

    # Send the request
    send_request(webhook_url, headers, body_json, timeout_ms)
  end

  defp send_request(url, headers, body, timeout_ms) do
    url_charlist = String.to_charlist(url)

    http_options = [
      {:timeout, timeout_ms},
      {:connect_timeout, timeout_ms},
      {:autoredirect, false},
      {:relaxed, true}
    ]

    options = [
      {:body_format, :binary},
      {:full_result, true}
    ]

    case @http_adapter.request(
           :post,
           {url_charlist, headers, ~c'application/json', body},
           http_options,
           options
         ) do
      {:ok, {{_http_version, status_code, _reason}, _response_headers, _response_body}} ->
        Logger.debug("Webhook delivery successful", %{
          url: url,
          status: status_code
        })

        {:ok, status_code}

      {:error, reason} ->
        Logger.warning("Webhook delivery failed", %{
          url: url,
          reason: inspect(reason)
        })

        {:error, reason}
    end
  end

  @doc """
  Determines if an attempt should be retried.

  Returns `true` if the attempt should be retried with exponential backoff,
  `false` if it's a terminal failure or success.
  """
  @spec should_retry?(attempt :: WebhookAttempt.t(), current_time :: NaiveDateTime.t()) ::
          boolean
  def should_retry?(attempt, current_time) do
    case attempt.status do
      :success -> false
      :terminal_failure -> false
      :pending -> false
      :failed -> not WebhookAttempt.terminal_failure?(attempt, current_time)
    end
  end

  @doc """
  Formats delivery timestamp in RFC 3339 format with Z suffix.

  ## Examples

      iex> timestamp = ~N[2026-08-01 14:30:00]
      iex> formatted = Delivery.format_timestamp(timestamp)
      iex> String.ends_with?(formatted, "Z")
      true
  """
  @spec format_timestamp(timestamp :: NaiveDateTime.t()) :: binary
  def format_timestamp(%NaiveDateTime{} = timestamp) do
    timestamp
    |> NaiveDateTime.truncate(:second)
    |> NaiveDateTime.to_iso8601()
    |> Kernel.<>("Z")
  end
end
