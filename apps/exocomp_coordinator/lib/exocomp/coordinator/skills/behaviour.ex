defmodule Exocomp.Coordinator.Skills.Behaviour do
  @moduledoc """
  Callback contract for all coordinator skill handler modules.

  Each skill module must implement `execute/2`, which receives:
  - `params`  — the skill-specific parameters map extracted from the incoming A2A message.
                May include `"node_ids"` or `"labels"` for inventory selection.
  - `context` — the task execution context map (metadata, task_id, etc.).

  Returns `{:ok, artifact}` on success or `{:error, reason}` on failure.
  Partial results (some nodes succeeded, some failed) are represented as a
  successful return with structured error entries inside the artifact.
  """

  alias Exocomp.A2A.Artifact

  @callback execute(params :: map(), context :: map()) ::
              {:ok, Artifact.t()} | {:error, term()}
end
