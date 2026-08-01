# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.Incidents.Grouping do
  @moduledoc """
  Deterministic grouping of related incidents.

  Grouping is deliberately a projection over incident records. It never
  changes an incident's ID, fingerprint, or lifecycle state, and it does not
  infer a cause. Two incidents are related only when their organization,
  alert type, service, and software version match and their timestamps are no
  more than the configured window apart.

  Service and software version are optional metadata. Missing values are
  represented explicitly as `nil`; they are not wildcards. This means a
  missing value can match another missing value, but never a known value.
  """

  @default_window_seconds 300

  @type incident :: map()
  @type options :: keyword()
  @type key :: %{
          organization_id: term(),
          alert_type: term(),
          service: term(),
          software_version: term(),
          window_start: DateTime.t()
        }
  @type summary :: %{
          alert_type: term(),
          service: term(),
          software_version: term(),
          incident_count: non_neg_integer(),
          first_occurred_at: DateTime.t() | nil,
          last_occurred_at: DateTime.t() | nil,
          text: String.t()
        }
  @type group :: %{key: key(), incidents: [incident()], summary: summary()}

  @doc "Returns the stable key for an incident in a configured time bucket."
  @spec key(incident(), options()) :: key()
  def key(incident, opts \\ []) when is_map(incident) do
    timestamp = timestamp!(incident)
    window_seconds = window_seconds!(opts)
    window_microseconds = window_seconds * 1_000_000
    unix_microseconds = DateTime.to_unix(timestamp, :microsecond)
    bucket = Integer.floor_div(unix_microseconds, window_microseconds) * window_microseconds

    %{
      organization_id: value(incident, :organization_id),
      alert_type: value(incident, :alert_type),
      service: optional(value(incident, :service)),
      software_version: optional(value(incident, :software_version)),
      window_start: DateTime.from_unix!(bucket, :microsecond)
    }
  end

  @doc "Aliases `key/2` with names used by grouping callers."
  @spec group_key(incident(), options()) :: key()
  def group_key(incident, opts \\ []), do: key(incident, opts)

  @spec key_for(incident(), options()) :: key()
  def key_for(incident, opts \\ []), do: key(incident, opts)

  @doc "Returns true when two incidents satisfy every grouping rule."
  @spec related?(incident(), incident(), options()) :: boolean()
  def related?(left, right, opts \\ []) when is_map(left) and is_map(right) do
    same_attributes?(left, right) and within_window?(left, right, window_seconds!(opts))
  end

  @doc "Groups incidents by deterministic attributes and time bucket."
  @spec group([incident()], options()) :: [group()]
  def group(incidents, opts \\ []) when is_list(incidents) do
    window_seconds = window_seconds!(opts)

    incidents
    |> Enum.sort_by(&sort_key/1)
    |> Enum.reduce([], fn incident, groups ->
      case groups do
        [%{anchor: anchor, members: members} | rest] = current_group ->
          if same_attributes?(anchor, incident) and
               within_window?(anchor, incident, window_seconds) do
            [%{anchor: anchor, members: [incident | members]} | rest]
          else
            [%{anchor: incident, members: [incident]} | current_group]
          end

        [] ->
          [%{anchor: incident, members: [incident]}]
      end
    end)
    |> Enum.reverse()
    |> Enum.map(fn %{anchor: anchor, members: members} ->
      group_key = key(anchor, opts)
      members = Enum.reverse(members)

      %{key: group_key, incidents: members, summary: summary(group_key, members)}
    end)
    |> Enum.sort_by(&group_sort_key/1)
  end

  @doc "Alias for `group/2`."
  @spec groups([incident()], options()) :: [group()]
  def groups(incidents, opts \\ []), do: group(incidents, opts)

  @doc "Returns incidents related to `target`, in deterministic order."
  @spec related(incident(), [incident()], options()) :: [incident()]
  def related(target, incidents, opts \\ []) when is_map(target) and is_list(incidents) do
    incidents
    |> Enum.filter(&related?(target, &1, opts))
    |> Enum.sort_by(&sort_key/1)
  end

  @doc "Builds a deterministic, display-safe summary for one group."
  @spec summary(key(), [incident()]) :: summary()
  def summary(group_key, incidents) when is_map(group_key) and is_list(incidents) do
    ordered = Enum.sort_by(incidents, &sort_key/1)
    first = ordered |> List.first() |> timestamp_or_nil()
    last = ordered |> List.last() |> timestamp_or_nil()
    count = length(ordered)
    service = display_value(group_key.service, "unknown service")
    version = display_value(group_key.software_version, "unknown version")

    %{
      alert_type: group_key.alert_type,
      service: group_key.service,
      software_version: group_key.software_version,
      incident_count: count,
      first_occurred_at: first,
      last_occurred_at: last,
      text:
        "#{display_value(group_key.alert_type, "unknown alert")} on #{service} " <>
          "(#{version}) — #{count} #{pluralize(count, "incident", "incidents")}"
    }
  end

  @doc "Returns only the display text from a group summary."
  @spec display_summary(group()) :: String.t()
  def display_summary(%{key: group_key, incidents: incidents}),
    do: display_summary(group_key, incidents)

  @spec display_summary(key(), [incident()]) :: String.t()

  def display_summary(group_key, incidents),
    do: summary(group_key, incidents).text

  @doc "Returns the configured default grouping window in seconds."
  @spec default_window_seconds() :: pos_integer()
  def default_window_seconds, do: @default_window_seconds

  defp same_attributes?(left, right) do
    value(left, :organization_id) == value(right, :organization_id) and
      value(left, :alert_type) == value(right, :alert_type) and
      optional(value(left, :service)) == optional(value(right, :service)) and
      optional(value(left, :software_version)) == optional(value(right, :software_version))
  end

  defp within_window?(left, right, window_seconds) do
    left_timestamp = timestamp!(left)
    right_timestamp = timestamp!(right)

    DateTime.diff(left_timestamp, right_timestamp, :microsecond) |> abs() <=
      window_seconds * 1_000_000
  end

  defp window_seconds!(opts) when is_list(opts) do
    value =
      Keyword.get(opts, :window_seconds, Keyword.get(opts, :window, @default_window_seconds))

    validate_window_seconds(value)
  end

  defp window_seconds!(value) when is_integer(value), do: validate_window_seconds(value)

  defp window_seconds!(_opts),
    do: raise(ArgumentError, "window_seconds must be a positive integer")

  defp validate_window_seconds(value) when is_integer(value) and value > 0, do: value

  defp validate_window_seconds(_value),
    do: raise(ArgumentError, "window_seconds must be a positive integer")

  defp sort_key(incident) do
    timestamp = timestamp!(incident)

    {
      DateTime.to_unix(timestamp, :microsecond),
      value(incident, :id) || "",
      value(incident, :organization_id) || ""
    }
  end

  defp group_sort_key(%{key: key, incidents: [first | _]}) do
    {DateTime.to_unix(key.window_start, :microsecond), sort_key(first), key_tuple(key)}
  end

  defp key_tuple(key),
    do: {key.organization_id, key.alert_type, key.service, key.software_version}

  defp timestamp!(incident) do
    case timestamp_or_nil(incident) do
      %DateTime{} = timestamp -> timestamp
      nil -> raise ArgumentError, "incident must include a DateTime timestamp"
    end
  end

  defp timestamp_or_nil(nil), do: nil

  defp timestamp_or_nil(incident) when is_map(incident) do
    [:occurred_at, :opened_at, :updated_at]
    |> Enum.find_value(fn field ->
      case value(incident, field) do
        %DateTime{} = timestamp -> timestamp
        _value -> nil
      end
    end)
  end

  defp value(map, key), do: Map.get(map, key, Map.get(map, Atom.to_string(key)))

  defp optional(value) when is_binary(value) and byte_size(value) > 0, do: value
  defp optional(_value), do: nil

  defp display_value(value, _fallback) when is_binary(value) and byte_size(value) > 0, do: value
  defp display_value(_value, fallback), do: fallback

  defp pluralize(1, singular, _plural), do: singular
  defp pluralize(_count, _singular, plural), do: plural
end
