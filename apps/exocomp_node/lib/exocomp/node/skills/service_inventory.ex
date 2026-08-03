# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Node.Skills.ServiceInventory do
  @moduledoc """
  Skill handler for `exocomp.service.inventory`.

  Discovers enabled and enabled-runtime systemd service units and returns
  their current state, type, and configuration. Filters to exclude unit types
  that should not be expected to run long-term.

  ## Configuration

  - `:service_inventory_timeout_ms` (Application config, `:exocomp_node`) —
    total collection timeout in milliseconds (default 10_000).
  - `:service_inventory_collector` (Application config, `:exocomp_node`) —
    0-arity function `fn () -> observation end` injected for tests.

  ## Params

  This skill takes no parameters.

    %{}

  ## Errors

  - `{:error, :timeout}` — collection did not complete within the timeout.
  """

  @behaviour Exocomp.Node.Skills.Behaviour

  alias Exocomp.A2A.{Artifact, DataPart}

  @default_timeout_ms 10_000

  @impl true
  def execute(_params, _context) do
    collect_and_build()
  end

  # ---------------------------------------------------------------------------
  # Collection
  # ---------------------------------------------------------------------------

  defp collect_and_build do
    timeout_ms =
      Application.get_env(:exocomp_node, :service_inventory_timeout_ms, @default_timeout_ms)

    collector =
      Application.get_env(
        :exocomp_node,
        :service_inventory_collector,
        &default_collect/0
      )

    task = Task.async(fn -> collector.() end)

    case Task.yield(task, timeout_ms) || Task.shutdown(task, :brutal_kill) do
      {:ok, observation} ->
        build_artifact(observation)

      nil ->
        {:error, :timeout}
    end
  end

  defp default_collect do
    Exocomp.Node.Collectors.ServiceInventory.collect()
  end

  # ---------------------------------------------------------------------------
  # Artifact construction
  # ---------------------------------------------------------------------------

  defp build_artifact(observation) do
    data = %{
      "schema_version" => "1",
      "skill" => "exocomp.service.inventory",
      "observations" => %{
        "enabled_services" => observation_to_serializable(observation)
      }
    }

    artifact = %Artifact{
      artifactId: generate_artifact_id(),
      name: "service-inventory",
      parts: [%DataPart{data: data}]
    }

    {:ok, artifact}
  end

  defp observation_to_serializable(obs) when is_map(obs) do
    Map.new(obs, fn {k, v} -> {to_string(k), v} end)
  end

  defp observation_to_serializable(other), do: %{"error" => inspect(other)}

  defp generate_artifact_id do
    "service-inventory-#{System.unique_integer([:positive, :monotonic])}"
  end
end
