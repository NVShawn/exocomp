# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.ClusterProfile.Default do
  @moduledoc "The baseline cluster profile shipped in every Exocomp release."

  @behaviour Exocomp.ClusterProfile

  @id "default"
  @version 1

  @impl true
  def id, do: @id

  @impl true
  def version, do: @version

  @impl true
  def node_discovery_capability do
    %{
      enabled: true,
      mode: :static_inventory,
      sources: [:configured_inventory],
      dynamic_membership: false
    }
  end

  @impl true
  def expected_services(_context), do: {:ok, []}

  @impl true
  def health_reduction(observations) when is_list(observations) do
    statuses = Enum.map(observations, &observation_status/1)

    status =
      cond do
        :unreachable in statuses -> :unreachable
        :stale in statuses -> :stale
        :degraded in statuses -> :degraded
        statuses != [] and Enum.all?(statuses, &(&1 == :healthy)) -> :healthy
        true -> :unknown
      end

    %{status: status, observation_count: length(observations)}
  end

  def health_reduction(_observations), do: %{status: :unknown, observation_count: 0}

  @impl true
  def supported_typed_actions, do: ["restart_service", "vacuum_logs"]

  @impl true
  def redaction_metadata do
    %{
      sensitive_fields: ["token", "secret", "password", "private_key"],
      redact_nested_maps: true,
      max_value_bytes: 4_096
    }
  end

  defp observation_status(%{status: status})
       when status in [:healthy, :degraded, :stale, :unreachable],
       do: status

  defp observation_status(%{"status" => status})
       when status in ["healthy", "degraded", "stale", "unreachable"],
       do: String.to_existing_atom(status)

  defp observation_status(_observation), do: :unknown
end
