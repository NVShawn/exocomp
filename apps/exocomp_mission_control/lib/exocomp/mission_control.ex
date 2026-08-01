# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl do
  @moduledoc """
  Top-level Mission Control context.

  Defines data structures and operations for the Mission Control domain.
  """

  alias Exocomp.MissionControl.Proposal

  @doc """
  Represents a proposal state for LiveView rendering.

  The `ready` field indicates whether approval controls should be enabled:
  - `true` when cluster is connected, proposal not expired, evidence not stale
  - `false` when offline, expired, stale, or terminal
  """
  @type proposal_state ::
          :pending | :approved | :denied | :offline | :expired | :stale | :terminal

  @doc """
  Represents a timeline event in the proposal lifecycle.

  Events are ordered by timestamp and show:
  - Decision: operator approved/denied
  - Command delivery: cluster acknowledged the command
  - Execution: cluster started executing the action
  - Verification: cluster verified the result
  - Terminal: final outcome (success, failure)
  """
  @type timeline_event :: %{
          type:
            :decision
            | :command_delivery
            | :execution
            | :verification
            | :terminal,
          timestamp: DateTime.t(),
          result: :success | :failure | nil,
          error: String.t() | nil,
          artifacts: map()
        }

  @doc """
  Render state for a proposal with decision controls.

  Includes proposal details, current state, and decision timeline.
  """
  @type proposal_view :: %{
          proposal_id: String.t(),
          cluster_id: String.t(),
          target_id: String.t(),
          action_id: String.t(),
          parameters: map(),
          evidence_hash: String.t(),
          evidence_age_seconds: integer(),
          risk: String.t(),
          disruption: String.t(),
          rationale: String.t(),
          policy_result: String.t(),
          expires_at: DateTime.t(),
          state: proposal_state(),
          timeline: [timeline_event()],
          decision: %{
            decision_type: :approved | :denied | nil,
            decided_by: String.t() | nil,
            decided_at: DateTime.t() | nil
          }
        }

  @doc """
  Determines whether approval controls should be enabled for a proposal.

  Returns `false` when:
  - Cluster is offline
  - Proposal has expired
  - Evidence freshness window has elapsed
  - Proposal is in terminal state
  """
  @spec controls_enabled?(proposal_state()) :: boolean()
  def controls_enabled?(:pending), do: true
  def controls_enabled?(:approved), do: false
  def controls_enabled?(:denied), do: false
  def controls_enabled?(:offline), do: false
  def controls_enabled?(:expired), do: false
  def controls_enabled?(:stale), do: false
  def controls_enabled?(:terminal), do: false

  @doc """
  Determines which operator actions are allowed based on role and state.

  Viewers cannot approve or deny. Operators and admins can when controls
  are enabled and there is no concurrent decision conflict.
  """
  @spec can_approve?(user_role :: atom(), proposal_state(), has_decision :: boolean()) ::
          boolean()
  def can_approve?(role, state, has_decision)
      when role in [:operator, :admin] and not has_decision do
    controls_enabled?(state)
  end

  def can_approve?(_, _, _), do: false

  @spec can_deny?(user_role :: atom(), proposal_state(), has_decision :: boolean()) ::
          boolean()
  def can_deny?(role, state, has_decision)
      when role in [:operator, :admin] and not has_decision do
    controls_enabled?(state)
  end

  def can_deny?(_, _, _), do: false
end
