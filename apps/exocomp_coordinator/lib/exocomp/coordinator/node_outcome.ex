defmodule Exocomp.Coordinator.NodeOutcome do
  @moduledoc """
  Per-node outcome record within a coordinator diagnostic goal.

  A `NodeOutcome` tracks the state of a single node's participation in a
  diagnostic goal: whether the node was dispatched, what result it produced,
  any structured artifacts, and any error encountered.

  `state` transitions from `:pending` (initial, not yet dispatched) through
  active states to one of the terminal states:

  * `:pending`     – goal accepted; node task not yet submitted downstream.
  * `:running`     – downstream A2A task submitted and in progress.
  * `:succeeded`   – node task completed with a usable result.
  * `:failed`      – node task completed with an error or unusable result.
  * `:unreachable` – node could not be contacted at dispatch or went away.
  * `:canceled`    – goal was canceled before or during node execution.

  `result` and `error` carry free-form caller data (maps, binary, etc.) and
  are not validated here. `artifacts` are structured A2A artifacts produced
  by the node task.
  """

  defstruct node_id: nil,
            state: :pending,
            result: nil,
            error: nil,
            artifacts: [],
            updated_at: nil

  @type state :: :pending | :running | :succeeded | :failed | :unreachable | :canceled

  @terminal_states [:succeeded, :failed, :unreachable, :canceled]

  @type t :: %__MODULE__{
          node_id: String.t(),
          state: state(),
          result: term(),
          error: term(),
          artifacts: [Exocomp.A2A.Artifact.t()],
          updated_at: String.t() | nil
        }

  @doc "Returns true if the outcome is in a terminal state."
  @spec terminal?(t()) :: boolean()
  def terminal?(%__MODULE__{state: state}), do: state in @terminal_states
end
