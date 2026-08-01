# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0

defmodule Exocomp.MissionControl.Retention.Policy do
  @moduledoc """
  Organization-level retention policy configuration.

  Defines how long different types of data are retained per organization:
  - Status history: defaults to 90 days, configurable with validated bounds
  - Incidents, conversations, proposals: defaults to 1 year, configurable
  - Audit events: defaults to 1 year, configurable

  All retention durations are specified in days and must satisfy configured
  minimum and maximum bounds to prevent accidental data loss or unbounded retention.
  """

  @typedoc "Organization identifier"
  @type org_id :: binary

  @typedoc "Retention duration in days"
  @type days :: pos_integer

  @typedoc """
  Organization retention policy.

  Fields:
  - org_id: organization scope
  - status_history_days: retention period for status history (default 90)
  - incident_days: retention period for incidents/conversations/proposals (default 365)
  - audit_days: retention period for audit events (default 365)
  - min_status_history_days: minimum allowed retention for status history (default 1)
  - max_status_history_days: maximum allowed retention for status history (default 3650 = ~10 years)
  - min_incident_days: minimum allowed retention for incidents
  - max_incident_days: maximum allowed retention for incidents
  - updated_at: timestamp when policy was last updated
  """
  @type t :: %__MODULE__{
          org_id: org_id,
          status_history_days: days,
          incident_days: days,
          audit_days: days,
          min_status_history_days: days,
          max_status_history_days: days,
          min_incident_days: days,
          max_incident_days: days,
          updated_at: DateTime.t()
        }

  defstruct [
    :org_id,
    :updated_at,
    status_history_days: 90,
    incident_days: 365,
    audit_days: 365,
    min_status_history_days: 1,
    max_status_history_days: 3650,
    min_incident_days: 1,
    max_incident_days: 3650
  ]

  @default_status_history_days 90
  @default_incident_days 365
  @default_audit_days 365
  @default_min_days 1
  @default_max_days 3650

  @doc """
  Create a new retention policy with defaults.

  All values default to the configured defaults and are immediately validated.
  """
  @spec new(org_id) :: {:ok, t} | {:error, String.t()}
  def new(org_id) when is_binary(org_id) and byte_size(org_id) > 0 do
    policy = %__MODULE__{
      org_id: org_id,
      status_history_days: @default_status_history_days,
      incident_days: @default_incident_days,
      audit_days: @default_audit_days,
      min_status_history_days: @default_min_days,
      max_status_history_days: @default_max_days,
      min_incident_days: @default_min_days,
      max_incident_days: @default_max_days,
      updated_at: DateTime.utc_now()
    }

    validate(policy)
  end

  def new(_) do
    {:error, "invalid org_id: must be a non-empty binary"}
  end

  @doc """
  Create a retention policy with custom retention days.

  All fields are validated. Retention days must fall within configured bounds.
  """
  @spec with_retention(
          org_id,
          status_history_days: days,
          incident_days: days,
          audit_days: days
        ) :: {:ok, t} | {:error, String.t()}
  def with_retention(org_id, opts \\ []) when is_list(opts) do
    with {:ok, base_policy} <- new(org_id) do
      updated = %{
        base_policy
        | status_history_days:
            Keyword.get(opts, :status_history_days, @default_status_history_days),
          incident_days: Keyword.get(opts, :incident_days, @default_incident_days),
          audit_days: Keyword.get(opts, :audit_days, @default_audit_days),
          updated_at: DateTime.utc_now()
      }

      validate(updated)
    end
  end

  @doc """
  Set custom bounds for retention days.

  Bounds define the minimum and maximum allowed retention durations.
  The current retention days must satisfy the new bounds.
  """
  @spec with_bounds(
          t,
          min_status_history_days: days,
          max_status_history_days: days,
          min_incident_days: days,
          max_incident_days: days
        ) :: {:ok, t} | {:error, String.t()}
  def with_bounds(policy, opts \\ []) when is_list(opts) do
    updated = %{
      policy
      | min_status_history_days:
          Keyword.get(opts, :min_status_history_days, policy.min_status_history_days),
        max_status_history_days:
          Keyword.get(opts, :max_status_history_days, policy.max_status_history_days),
        min_incident_days: Keyword.get(opts, :min_incident_days, policy.min_incident_days),
        max_incident_days: Keyword.get(opts, :max_incident_days, policy.max_incident_days),
        updated_at: DateTime.utc_now()
    }

    validate(updated)
  end

  @doc """
  Validate a retention policy.

  Ensures:
  - Organization ID is non-empty
  - All retention durations are positive integers
  - Retention durations fall within their configured bounds
  - Bounds are sensible (min <= max)
  """
  @spec validate(t) :: {:ok, t} | {:error, String.t()}
  def validate(%__MODULE__{} = policy) do
    with :ok <- validate_org_id(policy.org_id),
         :ok <- validate_retention_days(policy.status_history_days),
         :ok <- validate_retention_days(policy.incident_days),
         :ok <- validate_retention_days(policy.audit_days),
         :ok <- validate_bounds(policy.min_status_history_days, policy.max_status_history_days),
         :ok <- validate_bounds(policy.min_incident_days, policy.max_incident_days),
         :ok <-
           validate_within_bounds(
             policy.status_history_days,
             policy.min_status_history_days,
             policy.max_status_history_days,
             "status_history_days"
           ),
         :ok <-
           validate_within_bounds(
             policy.incident_days,
             policy.min_incident_days,
             policy.max_incident_days,
             "incident_days"
           ),
         :ok <-
           validate_within_bounds(
             policy.audit_days,
             policy.min_incident_days,
             policy.max_incident_days,
             "audit_days"
           ) do
      {:ok, policy}
    end
  end

  defp validate_org_id(org_id) when is_binary(org_id) and byte_size(org_id) > 0, do: :ok
  defp validate_org_id(_), do: {:error, "invalid org_id: must be a non-empty binary"}

  defp validate_retention_days(days) when is_integer(days) and days > 0, do: :ok
  defp validate_retention_days(_), do: {:error, "retention days must be a positive integer"}

  defp validate_bounds(min, max) when is_integer(min) and is_integer(max) and min <= max, do: :ok
  defp validate_bounds(_, _), do: {:error, "min must be <= max"}

  defp validate_within_bounds(value, min, max, field_name) do
    if value >= min and value <= max do
      :ok
    else
      {:error, "#{field_name} must be between #{min} and #{max}, got #{value}"}
    end
  end

  @doc """
  Calculate the cutoff datetime for retention.

  Returns the oldest datetime that should be retained based on the current time
  and the retention policy. Records with observed_at (or created_at) before
  this cutoff should be deleted.
  """
  @spec cutoff_datetime(t, :status_history | :incident | :audit) :: DateTime.t()
  def cutoff_datetime(policy, data_type) do
    days =
      case data_type do
        :status_history -> policy.status_history_days
        :incident -> policy.incident_days
        :audit -> policy.audit_days
      end

    DateTime.utc_now()
    |> DateTime.add(-days * 86400, :second)
  end
end
