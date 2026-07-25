# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.DiagnosticGoal do
  @moduledoc """
  A coordinator-side diagnostic goal, tracking the full lifecycle of a
  caller's diagnostic request across all targeted nodes.

  A `DiagnosticGoal` is created when a caller submits a diagnostic request
  through the public coordinator API. It carries a UUIDv4 correlation ID,
  the caller-supplied idempotency key that was used to deduplicate the
  submission, and the aggregated state across all participating nodes.

  ## Goal states

  * `:accepted`    – request accepted and waiting for fan-out to begin.
  * `:dispatching` – coordinator is submitting tasks to individual nodes.
  * `:running`     – at least one node task is in flight.
  * `:completed`   – all node tasks finished (some may have failed).
  * `:failed`      – unrecoverable coordinator-level failure.
  * `:canceled`    – goal was canceled by the caller or coordinator.

  `:completed`, `:failed`, and `:canceled` are terminal states.

  ## Fields

  * `id`              – UUIDv4 correlation ID, immutable after creation.
  * `caller_key`      – caller-supplied idempotency key used for deduplication.
  * `skill_id`        – the diagnostic skill requested.
  * `params`          – skill-specific parameters (map).
  * `state`           – current lifecycle state.
  * `node_outcomes`   – per-node outcome map, keyed by node ID.
  * `artifacts`       – structured A2A artifacts produced by the goal, bounded.
  * `output`          – raw text output, bounded and front-truncated on overflow.
  * `output_truncated`– true when output was trimmed to fit within the bound.
  * `error`           – coordinator-level error info for `:failed` goals.
  * `created_at`      – ISO 8601 UTC timestamp of goal creation.
  * `updated_at`      – ISO 8601 UTC timestamp of the last state change.
  """

  @enforce_keys [:id, :caller_key, :skill_id, :state]

  defstruct id: nil,
            caller_key: nil,
            skill_id: nil,
            params: %{},
            state: nil,
            node_outcomes: %{},
            artifacts: [],
            output: "",
            output_truncated: false,
            error: nil,
            created_at: nil,
            updated_at: nil

  @type state :: :accepted | :dispatching | :running | :completed | :failed | :canceled

  @terminal_states [:completed, :failed, :canceled]

  @type t :: %__MODULE__{
          id: String.t(),
          caller_key: String.t(),
          skill_id: String.t(),
          params: map(),
          state: state(),
          node_outcomes: %{String.t() => Exocomp.Coordinator.NodeOutcome.t()},
          artifacts: [Exocomp.A2A.Artifact.t()],
          output: binary(),
          output_truncated: boolean(),
          error: term(),
          created_at: String.t() | nil,
          updated_at: String.t() | nil
        }

  @doc "Returns true if the goal is in a terminal state."
  @spec terminal?(t()) :: boolean()
  def terminal?(%__MODULE__{state: state}), do: state in @terminal_states
end
