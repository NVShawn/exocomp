# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.Proposal do
  @moduledoc """
  A typed, bounded remedy proposal awaiting an operator decision.

  A proposal's `status` is deliberately separate from execution.  In
  particular, `approved` means only that an operator accepted the proposal;
  execution is reported by the cluster later and is never inferred here.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @statuses ~w(pending approved denied expired failed executed)

  @type t :: %__MODULE__{
          proposal_id: String.t(),
          organization_id: String.t(),
          cluster_id: String.t(),
          task_id: String.t() | nil,
          correlation_id: String.t() | nil,
          node_id: String.t() | nil,
          target_id: String.t() | nil,
          action_id: String.t(),
          parameters: map(),
          evidence_refs: map() | list(),
          evidence_hash: String.t() | nil,
          evidence_observed_at: DateTime.t() | nil,
          evidence_fresh_until: DateTime.t() | nil,
          evidence_expires_at: DateTime.t() | nil,
          evidence_freshness_until: DateTime.t() | nil,
          expires_at: DateTime.t(),
          status: String.t(),
          decision: String.t() | nil,
          decided_at: DateTime.t() | nil,
          decided_by_sub: String.t() | nil,
          decided_by_display_name: String.t() | nil,
          decided_by_organization_id: String.t() | nil,
          decision_correlation_id: String.t() | nil,
          decision_actor: map() | nil,
          denial_reason: String.t() | nil,
          approval_command_id: String.t() | nil
        }

  @primary_key false
  schema "proposals" do
    field(:proposal_id, :string, primary_key: true)
    field(:organization_id, :string)
    field(:cluster_id, :string)
    field(:task_id, :string)
    field(:correlation_id, :string)
    field(:node_id, :string)
    field(:target_id, :string)
    field(:action_id, :string)
    field(:parameters, :map, default: %{})
    field(:evidence_refs, :map, default: %{})
    field(:evidence_hash, :string)
    field(:evidence_observed_at, :utc_datetime_usec)
    field(:evidence_fresh_until, :utc_datetime_usec)
    field(:evidence_expires_at, :utc_datetime_usec)
    field(:evidence_freshness_until, :utc_datetime_usec)
    field(:expires_at, :utc_datetime_usec)
    field(:status, :string, default: "pending")
    field(:decision, :string)
    field(:decided_at, :utc_datetime_usec)
    field(:decided_by_sub, :string)
    field(:decided_by_display_name, :string)
    field(:decided_by_organization_id, :string)
    field(:decision_correlation_id, :string)
    field(:decision_actor, :map)
    field(:denial_reason, :string)
    field(:approval_command_id, :string)

    timestamps(type: :utc_datetime_usec)
  end

  @doc "The statuses understood by the Mission Control approval context."
  @spec statuses() :: [String.t()]
  def statuses, do: @statuses

  @doc "Returns whether a proposal has reached a state that cannot be decided."
  @spec terminal?(t() | map()) :: boolean()
  def terminal?(%__MODULE__{status: status}), do: terminal_status?(status)
  def terminal?(%{status: status}), do: terminal_status?(status)
  def terminal?(_proposal), do: true

  @doc false
  @spec pending?(t() | map()) :: boolean()
  def pending?(%{status: status}), do: normalize_status(status) == "pending"
  def pending?(_proposal), do: false

  @doc false
  @spec changeset(t() | Ecto.Changeset.t(), map()) :: Ecto.Changeset.t()
  def changeset(proposal, attrs) do
    proposal
    |> cast(attrs, [
      :proposal_id,
      :organization_id,
      :cluster_id,
      :task_id,
      :correlation_id,
      :node_id,
      :target_id,
      :action_id,
      :parameters,
      :evidence_refs,
      :evidence_hash,
      :evidence_observed_at,
      :evidence_fresh_until,
      :evidence_expires_at,
      :evidence_freshness_until,
      :expires_at,
      :status,
      :decision,
      :decided_at,
      :decided_by_sub,
      :decided_by_display_name,
      :decided_by_organization_id,
      :decision_correlation_id,
      :decision_actor,
      :denial_reason,
      :approval_command_id
    ])
    |> validate_required([:proposal_id, :organization_id, :cluster_id, :action_id, :expires_at])
    |> validate_inclusion(:status, @statuses)
    |> validate_change(:parameters, &map_field/2)
    |> validate_change(:evidence_refs, &map_or_list_field/2)
    |> validate_change(:decision_actor, &map_field/2)
    |> validate_length(:denial_reason, max: 4_096)
  end

  defp terminal_status?(status), do: normalize_status(status) != "pending"

  defp normalize_status(status) when is_atom(status), do: Atom.to_string(status)
  defp normalize_status(status) when is_binary(status), do: status
  defp normalize_status(_status), do: nil

  defp map_field(:parameters, value) when is_map(value), do: []
  defp map_field(:decision_actor, value) when is_map(value), do: []
  defp map_field(field, _value), do: [{field, "must be a map"}]

  defp map_or_list_field(:evidence_refs, value) when is_map(value) or is_list(value), do: []
  defp map_or_list_field(field, _value), do: [{field, "must be a map or list"}]
end
