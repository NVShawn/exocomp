# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.RemediationAdapter.Router do
  @moduledoc "Routes remediation proposals to an adapter by their typed action ID."

  @behaviour Exocomp.Coordinator.RemediationAdapter

  alias Exocomp.Coordinator.RemediationAdapter.{CephDaemonRestart, FailClosed}

  @impl true
  def validate_proposal(proposal), do: adapter(proposal).validate_proposal(proposal)

  @impl true
  def collect_evidence(proposal), do: adapter(proposal).collect_evidence(proposal)

  @impl true
  def decide(proposal, evidence), do: adapter(proposal).decide(proposal, evidence)

  @impl true
  def execute(action, evidence, approval), do: adapter(action).execute(action, evidence, approval)

  @impl true
  def verify(action, evidence, result), do: adapter(action).verify(action, evidence, result)

  defp adapter(value) when is_map(value) do
    case Map.get(value, "action_id") || Map.get(value, :action_id) do
      "restart_failed_daemon" -> CephDaemonRestart
      _ -> FailClosed
    end
  end

  defp adapter(_), do: FailClosed
end
