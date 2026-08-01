# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.HealthController do
  @moduledoc "HTTP health probes with deliberately redacted response bodies."

  use Phoenix.Controller
  require Logger

  alias Exocomp.MissionControl.Health

  @doc "Backward-compatible health endpoint; equivalent to liveness."
  def health(conn, _params) do
    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> Plug.Conn.send_resp(200, ~s({"status":"ok"}))
  end

  @doc "Unauthenticated process liveness probe."
  def liveness(conn, _params), do: json(conn, Health.liveness())

  @doc "Readiness probe, with an optional constant-time bearer-token guard."
  def readiness(conn, _params) do
    if authorized?(conn) do
      report = Health.evaluate()
      status = if report.ready?, do: 200, else: 503

      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.send_resp(status, Jason.encode!(public_report(report)))
    else
      Logger.warning("Mission Control readiness probe authorization failed")

      conn
      |> Plug.Conn.put_resp_header("www-authenticate", "Bearer")
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.send_resp(401, ~s({"status":"unauthorized"}))
    end
  end

  defp public_report(%{status: status, ready?: ready?, checks: checks}) do
    %{
      status: Atom.to_string(status),
      ready: ready?,
      checks: Map.new(checks, fn {key, value} -> {key, Atom.to_string(value)} end)
    }
  end

  defp authorized?(conn) do
    case Application.get_env(:exocomp_mission_control, :readiness_token) do
      nil ->
        true

      "" ->
        true

      expected ->
        case Plug.Conn.get_req_header(conn, "authorization") do
          ["Bearer " <> actual] -> secure_compare(expected, actual)
          _ -> false
        end
    end
  end

  defp secure_compare(left, right) when is_binary(left) and is_binary(right) do
    byte_size(left) == byte_size(right) and Plug.Crypto.secure_compare(left, right)
  end

  defp secure_compare(_left, _right), do: false
end
