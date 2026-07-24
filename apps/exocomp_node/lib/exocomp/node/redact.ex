defmodule Exocomp.Node.Redact do
  @moduledoc """
  Helpers for redacting sensitive configuration field values from logs and
  error messages.

  The following field labels are considered sensitive and must never have their
  values included in error output or log messages:

  - `tls.node_key`   — private TLS key path
  - `tls.ca_cert`    — CA certificate path
  - `tls.node_cert`  — node certificate path

  When building error messages that would otherwise include a field's value,
  use `redact_value/2` to ensure sensitive values are replaced with
  `"[REDACTED]"`.
  """

  @sensitive_labels MapSet.new(["tls.node_key", "tls.ca_cert", "tls.node_cert"])

  @doc """
  Returns `true` if the given field label is considered sensitive.

      iex> Exocomp.Node.Redact.sensitive?("tls.node_key")
      true

      iex> Exocomp.Node.Redact.sensitive?("node_id")
      false
  """
  @spec sensitive?(String.t()) :: boolean()
  def sensitive?(label), do: MapSet.member?(@sensitive_labels, label)

  @doc """
  Returns `"[REDACTED]"` if `label` is sensitive, otherwise returns `value` unchanged.

      iex> Exocomp.Node.Redact.redact_value("tls.node_key", "/path/to/key.pem")
      "[REDACTED]"

      iex> Exocomp.Node.Redact.redact_value("node_id", "my-node")
      "my-node"
  """
  @spec redact_value(String.t(), term()) :: term()
  def redact_value(label, value) do
    if sensitive?(label), do: "[REDACTED]", else: value
  end
end
