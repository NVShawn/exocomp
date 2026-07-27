# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Node.Recovery.ServiceEvidence do
  @moduledoc """
  Collects fresh systemd state and configured loopback application health as
  target-bound recovery evidence.
  """

  alias Exocomp.Node.Collectors.Systemd
  alias Exocomp.Recovery.Evidence

  @spec collect(String.t(), String.t()) :: {:ok, Evidence.t()} | {:error, term()}
  def collect(node_id, service) do
    collector =
      Application.get_env(:exocomp_node, :service_recover_systemd_collector, fn services ->
        Systemd.collect(allowed_services: services)
      end)

    observation = collector.([service])
    prefix = service |> String.replace(".", "_") |> String.replace("-", "_")

    with {:ok, active_state} <- measurement(observation, :"#{prefix}_activestate"),
         {:ok, sub_state} <- measurement(observation, :"#{prefix}_substate"),
         {:ok, health} <- application_health(service, active_state, sub_state) do
      {:ok,
       Evidence.new(
         node_id,
         service,
         %{active_state: active_state, sub_state: sub_state, health: health},
         collector_version: "systemd-http-1"
       )}
    end
  end

  defp application_health(_service, active_state, sub_state)
       when active_state != "active" or sub_state != "running",
       do: {:ok, "unhealthy"}

  defp application_health(service, _active_state, _sub_state) do
    checks = Application.get_env(:exocomp_node, :service_health_checks, %{})

    case Map.fetch(checks, service) do
      {:ok, url} ->
        request =
          Application.get_env(
            :exocomp_node,
            :service_recover_health_request,
            &request_health/1
          )

        request.(url)

      :error ->
        {:error, {:health_check_not_configured, service}}
    end
  end

  defp request_health(url) do
    case :httpc.request(
           :get,
           {String.to_charlist(url), []},
           [timeout: 2_000, connect_timeout: 2_000],
           body_format: :binary
         ) do
      {:ok, {{_version, status, _reason}, _headers, _body}} when status in 200..299 ->
        {:ok, "healthy"}

      _other ->
        {:ok, "unhealthy"}
    end
  end

  defp measurement(%{measurements: measurements}, key) do
    case Map.get(measurements, key) do
      %{value: value} -> {:ok, value}
      %{error: error, reason: reason} -> {:error, {error, reason}}
      nil -> {:error, {:missing_measurement, key}}
    end
  end
end
