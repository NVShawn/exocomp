defmodule Exocomp.Coordinator.Skills.Dispatcher do
  @moduledoc """
  Routes a coordinator A2A skill_id to the appropriate skill handler module.

  ## Supported skills

  | skill_id                      | Handler module                                    |
  |-------------------------------|---------------------------------------------------|
  | `"exocomp.cluster.health"`    | `Exocomp.Coordinator.Skills.ClusterHealth`        |
  | `"exocomp.cluster.diagnose"`  | `Exocomp.Coordinator.Skills.ClusterDiagnose`      |

  Remediation execution skills are intentionally absent. Any unknown or
  remediation skill ID returns `{:error, :unknown_skill}`.
  """

  alias Exocomp.Coordinator.Skills.{ClusterHealth, ClusterDiagnose}

  @skill_map %{
    "exocomp.cluster.health" => ClusterHealth,
    "exocomp.cluster.diagnose" => ClusterDiagnose
  }

  @doc """
  Dispatch a skill invocation.

  - `skill_id` — the skill identifier string from the A2A message.
  - `params`   — the skill-specific parameter map (may include `node_ids`, `labels`).
  - `context`  — the task execution context map.

  Returns `{:ok, artifact}` or `{:error, reason}`.
  """
  @spec dispatch(String.t(), map(), map()) ::
          {:ok, Exocomp.A2A.Artifact.t()} | {:error, term()}
  def dispatch(skill_id, params \\ %{}, context \\ %{}) do
    case Map.fetch(@skill_map, skill_id) do
      {:ok, handler} ->
        handler.execute(params, context)

      :error ->
        {:error, :unknown_skill}
    end
  end
end
