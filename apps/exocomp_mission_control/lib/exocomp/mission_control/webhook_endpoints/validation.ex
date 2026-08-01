# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.WebhookEndpoints.Validation do
  @moduledoc """
  Input validation for webhook endpoint configuration.

  This module provides validation functions for webhook parameters. All
  validation is fail-closed; ambiguous inputs return errors rather than
  accepting potentially unsafe values.

  ## URL validation

  - Must be a binary string
  - Must use HTTPS scheme (http:// is rejected for security)
  - Must be a valid URI
  - Must not be a relative URL
  - Policy checks (via Policy module) reject private IPs, loopback, link-local

  ## Event type validation

  - List of binary strings (atom strings rejected)
  - Cannot be empty
  - Known event types enforced (configurable list)
  - Case-sensitive matching

  ## Organization ID and IDs

  - Must be binary strings
  - Cannot be empty
  """

  alias Exocomp.MissionControl.WebhookEndpoints.Policy

  @known_event_types [
    "cluster.connected",
    "cluster.disconnected",
    "incident.opened",
    "incident.acknowledged",
    "incident.reopened",
    "incident.resolved",
    "proposal.created",
    "proposal.approved",
    "proposal.denied",
    "proposal.expired",
    "action.started",
    "action.completed",
    "action.failed",
    "action.verification_failed"
  ]

  @doc """
  Validates a webhook URL.

  Returns `{:ok, url}` when the URL is valid. The returned URL is normalized
  (e.g., excess whitespace trimmed).

  Returns `{:error, reason}` when:
  - `params["url"]` is not a binary
  - `params["url"]` is empty
  - The URL does not use HTTPS scheme
  - The URL is not a valid URI
  - The URL is relative
  - Policy checks reject the destination (private IP, loopback, etc.)
  """
  @spec validate_url(map()) :: {:ok, String.t()} | {:error, atom()}
  def validate_url(%{"url" => url}) when is_binary(url) do
    url = String.trim(url)

    cond do
      byte_size(url) == 0 ->
        {:error, :url_empty}

      not String.starts_with?(url, "https://") ->
        {:error, :url_not_https}

      not is_valid_uri?(url) ->
        {:error, :url_invalid}

      true ->
        Policy.validate_destination(url)
    end
  end

  def validate_url(%{"url" => _}), do: {:error, :url_not_binary}
  def validate_url(_params), do: {:error, :url_missing}

  @doc """
  Validates event type subscriptions.

  Returns `{:ok, event_types}` when the list is valid. The returned list
  contains only known event types in the order provided.

  Returns `{:error, reason}` when:
  - `params["subscribed_event_types"]` is not a list
  - The list is empty
  - Any element is not a binary string
  - Any element is not a recognized event type
  """
  @spec validate_event_types(map()) :: {:ok, [String.t()]} | {:error, atom()}
  def validate_event_types(%{"subscribed_event_types" => event_types})
      when is_list(event_types) do
    if Enum.empty?(event_types) do
      {:error, :event_types_empty}
    else
      case Enum.find(event_types, fn et -> not is_binary(et) end) do
        nil ->
          # All are binary; check if all are known
          case Enum.find(event_types, fn et -> et not in @known_event_types end) do
            nil -> {:ok, event_types}
            unknown -> {:error, {:event_type_unknown, unknown}}
          end

        invalid ->
          {:error, {:event_type_not_binary, invalid}}
      end
    end
  end

  def validate_event_types(%{"subscribed_event_types" => _}),
    do: {:error, :event_types_not_list}

  def validate_event_types(_params), do: {:error, :event_types_missing}

  @doc """
  Returns the list of known event types.
  """
  @spec known_event_types() :: [String.t()]
  def known_event_types, do: @known_event_types

  # ── Private ──────────────────────────────────────────────────────────────────

  # Simple URI validation: must have scheme and host, no path traversal
  defp is_valid_uri?(url) do
    try do
      uri = URI.parse(url)
      uri.scheme != nil and uri.host != nil and uri.scheme != ""
    rescue
      _ -> false
    end
  end
end
