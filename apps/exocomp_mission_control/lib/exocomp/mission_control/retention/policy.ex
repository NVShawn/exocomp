# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0

defmodule Exocomp.MissionControl.Retention.Policy do
  @moduledoc """
  Defines retention policies for Mission Control data.

  Retention policies specify which data types are retained and for how long:
  - Status history: 90 days (configurable)
  - Incidents: 1 year (configurable)
  - Conversations: 1 year (configurable)
  - Proposals: 1 year (configurable)
  - Audit events: 1 year (configurable)
  - Webhook event history: 1 year (configurable)

  All timestamps are in UTC. Policies are organization-scoped.
  """

  @typedoc """
  Retention duration in days.
  """
  @type days :: pos_integer()

  @typedoc """
  Retention policy configuration for an organization.
  """
  @type t :: %{
          organization_id: String.t(),
          status_history_days: days(),
          incidents_days: days(),
          conversations_days: days(),
          proposals_days: days(),
          audit_events_days: days(),
          webhook_events_days: days()
        }

  @doc """
  Create a new retention policy with defaults.

  Defaults:
  - Status history: 90 days
  - All others: 365 days (1 year)
  """
  @spec new(organization_id :: String.t()) :: t()
  def new(organization_id) do
    %{
      organization_id: organization_id,
      status_history_days: 90,
      incidents_days: 365,
      conversations_days: 365,
      proposals_days: 365,
      audit_events_days: 365,
      webhook_events_days: 365
    }
  end

  @doc """
  Calculate the cutoff timestamp for a given data type.

  Returns a DateTime representing the oldest timestamp that should be retained.
  Data older than this should be deleted.
  """
  @spec cutoff_timestamp(policy :: t(), type :: atom(), now :: DateTime.t()) :: DateTime.t()
  def cutoff_timestamp(policy, type, now) do
    days = days_for_type(policy, type)
    DateTime.add(now, -days, :day)
  end

  @doc """
  Get the retention days for a specific data type.
  """
  @spec days_for_type(policy :: t(), type :: atom()) :: days()
  def days_for_type(policy, :status_history), do: policy.status_history_days
  def days_for_type(policy, :incidents), do: policy.incidents_days
  def days_for_type(policy, :conversations), do: policy.conversations_days
  def days_for_type(policy, :proposals), do: policy.proposals_days
  def days_for_type(policy, :audit_events), do: policy.audit_events_days
  def days_for_type(policy, :webhook_events), do: policy.webhook_events_days

  @doc """
  Return all retention data types that are managed by the policy.
  """
  @spec data_types() :: [atom()]
  def data_types do
    [:status_history, :incidents, :conversations, :proposals, :audit_events, :webhook_events]
  end
end
