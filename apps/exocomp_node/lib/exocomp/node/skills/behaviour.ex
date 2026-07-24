defmodule Exocomp.Node.Skills.Behaviour do
  @moduledoc """
  Callback contract for all skill handler modules.

  Each skill module must implement `execute/2`, which receives:
  - `params` — the skill-specific parameters map extracted from the incoming A2A message.
  - `context` — the task execution context map (metadata, task_id, etc.).

  Returns `{:ok, artifact}` on success or `{:error, reason}` on failure.
  """

  alias Exocomp.A2A.Artifact

  @callback execute(params :: map(), context :: map()) ::
              {:ok, Artifact.t()} | {:error, term()}
end
