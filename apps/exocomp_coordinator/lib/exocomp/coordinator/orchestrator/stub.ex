defmodule Exocomp.Coordinator.Orchestrator.Stub do
  @moduledoc """
  Stub orchestrator used when the real EXOCOMP-18 orchestration layer is not
  yet available.

  Returns an empty node list for both health and diagnose fan-outs. The real
  orchestrator will fan out A2A tasks to all inventory-selected nodes and
  collect correlated partial results.
  """

  @doc """
  Fan out a health check to cluster nodes.

  Returns a map of `node_id => node_result` where each node result is a map
  containing at minimum `"status"` (one of `"healthy"`, `"degraded"`, `"unreachable"`).
  Partial failures are represented as `{"status": "unreachable", "error": "..."}`.
  """
  @spec fan_out_health(map()) :: map()
  def fan_out_health(_params), do: %{}

  @doc """
  Fan out a diagnostic collection to cluster nodes.

  Returns a map of `node_id => node_result` where each node result is a map
  containing `"status"` and optional `"observations"`. Unreachable nodes
  produce `{"status": "unreachable", "error": "..."}`.
  """
  @spec fan_out_diagnose(map()) :: map()
  def fan_out_diagnose(_params), do: %{}
end
