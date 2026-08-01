# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Node.Skills.Dispatcher do
  @moduledoc """
  Routes an A2A skill_id to the appropriate skill handler module.

  ## Supported skills

  | skill_id                        | Handler module                               |
  |---------------------------------|----------------------------------------------|
  | `"exocomp.system.diagnose"`     | `Exocomp.Node.Skills.SystemDiagnose`         |
  | `"exocomp.service.diagnose"`    | `Exocomp.Node.Skills.ServiceDiagnose`        |
  | `"exocomp.profile.inspect"`     | `Exocomp.Node.Skills.ProfileInspect`         |
  | `"exocomp.remediation.propose"` | `Exocomp.Node.Skills.RemediationPropose`     |
  | `"exocomp.service.recover"`     | `Exocomp.Node.Skills.ServiceRecover`         |

  Unknown skill IDs return `{:error, :unknown_skill}`.
  """

  alias Exocomp.Node.Skills.{
    SystemDiagnose,
    ServiceDiagnose,
    ProfileInspect,
    RemediationPropose,
    ServiceRecover
  }

  @skill_map %{
    "exocomp.system.diagnose" => SystemDiagnose,
    "exocomp.service.diagnose" => ServiceDiagnose,
    "exocomp.profile.inspect" => ProfileInspect,
    "exocomp.remediation.propose" => RemediationPropose,
    "exocomp.service.recover" => ServiceRecover
  }

  @doc """
  Dispatch a skill invocation.

  - `skill_id` — the skill identifier string from the A2A message.
  - `params`   — the skill-specific parameter map.
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
