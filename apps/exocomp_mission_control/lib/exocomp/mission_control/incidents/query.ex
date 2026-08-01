# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.Incidents.Query do
  @moduledoc """
  Read projections used by the incident UI.

  The incident store is currently an in-memory, organization-scoped reducer.
  Keeping filtering and pagination here gives the LiveViews the same bounded
  query contract a database-backed adapter can implement later.
  """

  alias Exocomp.MissionControl.Incidents

  @default_page_size 20

  @type row :: %{
          incident: map(),
          events: list(),
          severity: String.t(),
          labels: [String.t()]
        }

  @spec page(String.t(), keyword() | map(), pos_integer(), pos_integer(), GenServer.server()) ::
          %{
            rows: [row()],
            page: pos_integer(),
            page_size: pos_integer(),
            total: non_neg_integer(),
            total_pages: pos_integer()
          }
  def page(
        organization_id,
        filters \\ [],
        page \\ 1,
        page_size \\ @default_page_size,
        server \\ Incidents
      )

  def page(organization_id, filters, page, page_size, server)
      when is_binary(organization_id) and is_integer(page) and page > 0 and is_integer(page_size) and
             page_size > 0 do
    rows =
      organization_id
      |> Incidents.list(server)
      |> Enum.map(&row(&1, server))
      |> Enum.filter(&matches?(&1, filters))
      |> Enum.sort_by(&sort_key/1, :desc)

    total = length(rows)
    total_pages = max(1, ceil(total / page_size))
    page = min(page, total_pages)

    %{
      rows: Enum.slice(rows, (page - 1) * page_size, page_size),
      page: page,
      page_size: page_size,
      total: total,
      total_pages: total_pages
    }
  end

  @spec row(map(), GenServer.server()) :: row()
  def row(incident, server \\ Incidents) do
    events = Incidents.events(incident.id, server)
    metadata = Enum.find_value(events, %{}, &metadata/1)

    %{
      incident: incident,
      events: events,
      severity: normalize_severity(Map.get(metadata, "severity", "unknown")),
      labels: normalize_labels(Map.get(metadata, "labels", []))
    }
  end

  defp matches?(row, filters) do
    filters = Map.new(filters)
    incident = row.incident

    match_value?(filters["severity"], row.severity) and
      match_value?(filters["status"], Atom.to_string(incident.state)) and
      match_value?(filters["cluster"], incident.cluster_id) and
      match_label?(filters["label"], row.labels)
  end

  defp match_value?(nil, _value), do: true
  defp match_value?("", _value), do: true
  defp match_value?(value, current), do: value == current

  defp match_label?(nil, _labels), do: true
  defp match_label?("", _labels), do: true
  defp match_label?(value, labels), do: value in labels

  defp metadata(%{payload: payload}) when is_map(payload) do
    if Map.has_key?(payload, "severity") or Map.has_key?(payload, "labels"), do: payload
  end

  defp metadata(_event), do: nil

  defp normalize_labels(labels) when is_list(labels), do: Enum.filter(labels, &is_binary/1)
  defp normalize_labels(_labels), do: []

  defp normalize_severity(value) when is_binary(value) and byte_size(value) > 0, do: value
  defp normalize_severity(_value), do: "unknown"

  defp sort_key(%{incident: incident}), do: {incident.updated_at, incident.id}
end
