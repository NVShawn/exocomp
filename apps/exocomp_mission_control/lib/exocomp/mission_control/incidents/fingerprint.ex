# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.Incidents.Fingerprint do
  @moduledoc """
  Builds the stable identity of an incident.

  Fingerprints are SHA-256 digests of the six incident identity fields. Values
  are length-prefixed before hashing, so changing a field cannot create an
  accidental delimiter collision. No event payload, secret, or raw log is
  included in the digest.
  """

  @fields [:organization_id, :cluster_id, :alert_type, :source, :target_type, :target_identity]

  @type attributes :: map() | keyword()

  @doc """
  Returns a lowercase, 64-character SHA-256 fingerprint.

  The same six identity values always produce the same result. The explicit
  six-argument form is useful at protocol boundaries where the values are
  already individually validated.
  """
  @spec build(attributes()) :: String.t()
  def build(attributes) when is_map(attributes) or is_list(attributes) do
    @fields
    |> Enum.map(&fetch_value!(attributes, &1))
    |> build_values()
  end

  @spec build(String.t(), String.t(), String.t(), String.t(), String.t(), String.t()) ::
          String.t()
  def build(organization_id, cluster_id, alert_type, source, target_type, target_identity)
      when is_binary(organization_id) and is_binary(cluster_id) and is_binary(alert_type) and
             is_binary(source) and is_binary(target_type) and is_binary(target_identity) do
    build_values([organization_id, cluster_id, alert_type, source, target_type, target_identity])
  end

  @doc "Alias for callers that describe the digest as an incident identity."
  @spec for(attributes()) :: String.t()
  def for(attributes), do: build(attributes)

  @doc "Alias for callers that describe the digest as a generated fingerprint."
  @spec generate(attributes()) :: String.t()
  def generate(attributes), do: build(attributes)

  defp build_values(values) do
    canonical =
      ["incident-fingerprint-v1" | values]
      |> Enum.map_join(<<>>, fn value -> <<byte_size(value)::unsigned-big-64, value::binary>> end)

    :crypto.hash(:sha256, canonical)
    |> Base.encode16(case: :lower)
  end

  defp fetch_value!(attributes, field) do
    value =
      case attributes do
        %{} -> Map.get(attributes, field)
        list when is_list(list) -> Keyword.get(list, field)
      end

    if is_binary(value) do
      value
    else
      raise ArgumentError, "#{field} must be a binary"
    end
  end
end
