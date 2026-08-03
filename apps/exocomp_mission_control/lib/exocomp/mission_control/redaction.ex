# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.Redaction do
  @moduledoc """
  Redacts sensitive information from audit events and webhook payloads.

  Secrets, private keys, tokens, and arbitrary raw logs must never be
  persisted in audit events or transmitted via webhooks. This module provides
  a single redaction implementation used consistently before both audit
  serialization and webhook delivery.

  ## Redaction Strategy

  Fields are matched by name against a list of sensitive patterns:
  - Exact matches: `api_key`, `authorization`, `cookie`, `credential`,
    `credentials`, `password`, `passwd`, `private_key`, `secret`, `token`
  - Suffix matches: any field ending in `_api_key`, `_authorization`,
    `_cookie`, `_credential`, `_credentials`, `_password`, `_passwd`,
    `_private_key`, `_secret`, `_token`

  Field names are normalized to lowercase and with hyphens replaced by
  underscores before matching (e.g., `Private-Key` and `private_key` are
  treated equivalently).

  Matching fields are replaced with the string `"[REDACTED]"` regardless of
  their original value or type. The redaction is applied recursively to all
  nested maps and lists.

  ## Usage

  ```elixir
  # Redact before audit serialization
  safe_event = Redaction.redact(audit_event)

  # Redact webhook payload
  safe_payload = Redaction.redact(webhook_json)
  ```
  """

  @redacted "[REDACTED]"

  @sensitive_keys ~w(
    api_key
    authorization
    cookie
    credential
    credentials
    password
    passwd
    private_key
    raw_log
    raw_logs
    secret
    token
  )

  @doc """
  Redacts sensitive fields from a value recursively.

  Accepts any term. For maps and lists, recursively applies redaction to
  nested values. Atom keys in maps are converted to strings; string keys are
  preserved.

  Returns a redacted copy; the input is not modified.
  """
  @spec redact(term()) :: term()
  def redact(value), do: redact_value(value)

  @doc """
  Checks whether a field name (as a string or atom) is considered sensitive.

  Useful for conditional redaction logic or for audit trail generation. Returns
  true if the field matches any sensitive pattern.
  """
  @spec sensitive_key?(term()) :: boolean()
  def sensitive_key?(key) do
    normalized =
      key
      |> to_string()
      |> String.downcase()
      |> String.replace("-", "_")

    Enum.any?(@sensitive_keys, fn sensitive ->
      normalized == sensitive or String.ends_with?(normalized, "_" <> sensitive)
    end)
  end

  # Private helpers

  defp redact_value(%_{} = struct), do: struct |> Map.from_struct() |> redact_value()

  defp redact_value(map) when is_map(map) do
    Map.new(map, fn {key, value} ->
      # Convert key to string for consistency in checking
      key_str = to_string(key)

      if sensitive_key?(key_str) do
        {key, @redacted}
      else
        {key, redact_value(value)}
      end
    end)
  end

  defp redact_value(list) when is_list(list), do: Enum.map(list, &redact_value/1)
  defp redact_value(value), do: value
end
