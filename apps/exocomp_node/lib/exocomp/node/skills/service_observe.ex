# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Node.Skills.ServiceObserve do
  @moduledoc """
  Skill handler for `exocomp.service.observe`.

  Read-only service observation combining systemd state queries with
  optional validated loopback HTTP probes. Returns systemd evidence and
  probe results with timestamps, partial errors, and collector versions.
  Enforces service-count, response-size, and timeout limits.

  The skill cannot execute, enable, disable, or restart units, and does
  not alter the recovery allow-list.

  ## Configuration

  - `:allowed_services` (Application config, `:exocomp_node`) —
    list of permitted service unit names, e.g. `["sshd.service"]`.
    Defaults to `[]`. Requests for services outside this list are rejected.
  - `:service_observe_timeout_ms` (Application config, `:exocomp_node`) —
    total observation timeout in milliseconds (default 15_000).
  - `:service_observe_max_services` (Application config, `:exocomp_node`) —
    maximum number of services per request (default 50).
  - `:service_observe_max_probes` (Application config, `:exocomp_node`) —
    maximum number of HTTP probes per request (default 10).
  - `:service_observe_max_response_bytes` (Application config, `:exocomp_node`) —
    maximum response body size per probe in bytes (default 65_536).
  - `:service_observe_systemd_collector` (Application config, `:exocomp_node`) —
    1-arity function `fn allowed_services -> observation end` injected for tests.
  - `:service_observe_http_prober` (Application config, `:exocomp_node`) —
    3-arity function `fn url, timeout_ms, max_response_bytes -> probe_result end`
    injected for tests.

  ## Params

    %{
      "services" => ["sshd.service", "nginx.service"],
      "probes" => [
        %{"url" => "http://127.0.0.1:8080/health", "timeout_ms" => 5000}
      ]
    }

  ## Errors

  - `{:error, :invalid_params}` — empty service list, any requested service
    not in the allow-list, invalid probe URLs (non-loopback), or limit exceeded.
  - `{:error, :timeout}` — observation did not complete within the timeout.
  """

  @behaviour Exocomp.Node.Skills.Behaviour

  alias Exocomp.A2A.{Artifact, DataPart}

  @default_timeout_ms 15_000
  @default_max_services 50
  @default_max_probes 10
  @default_max_response_bytes 65_536

  @impl true
  def execute(params, _context) do
    with {:ok, services} <- extract_services(params),
         {:ok, probes} <- extract_probes(params),
         :ok <- validate_services(services),
         :ok <- validate_probes(probes),
         :ok <- validate_limits(services, probes) do
      collect_and_build(services, probes)
    end
  end

  # ---------------------------------------------------------------------------
  # Parameter extraction
  # ---------------------------------------------------------------------------

  defp extract_services(%{"services" => services}) when is_list(services) do
    {:ok, services}
  end

  defp extract_services(_params) do
    {:error, :invalid_params}
  end

  defp extract_probes(%{"probes" => probes}) when is_list(probes) do
    {:ok, probes}
  end

  defp extract_probes(%{"probes" => nil}) do
    {:ok, []}
  end

  defp extract_probes(%{} = params) do
    case Map.has_key?(params, "probes") do
      true -> {:error, :invalid_params}
      false -> {:ok, []}
    end
  end

  # ---------------------------------------------------------------------------
  # Validation
  # ---------------------------------------------------------------------------

  defp validate_services([]) do
    {:error, :invalid_params}
  end

  defp validate_services(services) do
    allowed = Application.get_env(:exocomp_node, :allowed_services, [])

    case Enum.reject(services, &(&1 in allowed)) do
      [] -> :ok
      _disallowed -> {:error, :invalid_params}
    end
  end

  defp validate_probes(probes) do
    case Enum.find_value(probes, false, &validate_probe_check/1) do
      false -> :ok
      error -> error
    end
  end

  defp validate_probe_check(%{"url" => url}) when is_binary(url) do
    case is_loopback_url(url) do
      true -> false
      false -> {:error, :invalid_params}
    end
  end

  defp validate_probe_check(_probe) do
    {:error, :invalid_params}
  end

  defp validate_limits(services, probes) do
    max_services = Application.get_env(:exocomp_node, :service_observe_max_services, @default_max_services)
    max_probes = Application.get_env(:exocomp_node, :service_observe_max_probes, @default_max_probes)

    cond do
      length(services) > max_services -> {:error, :invalid_params}
      length(probes) > max_probes -> {:error, :invalid_params}
      true -> :ok
    end
  end

  defp is_loopback_url(url) do
    case URI.parse(url) do
      %URI{host: host, scheme: scheme}
      when scheme in ["http", "https"] and is_binary(host) ->
        String.starts_with?(host, "127.") or host == "localhost" or host == "::1"

      _other ->
        false
    end
  end

  # ---------------------------------------------------------------------------
  # Collection
  # ---------------------------------------------------------------------------

  defp collect_and_build(services, probes) do
    timeout_ms =
      Application.get_env(:exocomp_node, :service_observe_timeout_ms, @default_timeout_ms)

    started_at = DateTime.utc_now()
    started_us = System.monotonic_time(:microsecond)

    # Parallel collection of systemd and HTTP probes
    systemd_task = Task.async(fn -> collect_systemd(services, timeout_ms) end)
    probes_task = Task.async(fn -> collect_probes(probes, timeout_ms) end)

    case {
      Task.yield(systemd_task, timeout_ms) || Task.shutdown(systemd_task, :brutal_kill),
      Task.yield(probes_task, timeout_ms) || Task.shutdown(probes_task, :brutal_kill)
    } do
      {{:ok, {:ok, systemd_obs}}, {:ok, {:ok, probe_results}}} ->
        elapsed_us = System.monotonic_time(:microsecond) - started_us
        build_artifact(started_at, systemd_obs, probe_results, elapsed_us)

      _timeout_or_error ->
        {:error, :timeout}
    end
  end

  defp collect_systemd(services, timeout_ms) do
    collector =
      Application.get_env(
        :exocomp_node,
        :service_observe_systemd_collector,
        &default_systemd_collector/1
      )

    task = Task.async(fn -> collector.(services) end)

    case Task.yield(task, timeout_ms) || Task.shutdown(task, :brutal_kill) do
      {:ok, observation} -> {:ok, observation}
      nil -> {:error, :timeout}
    end
  end

  defp collect_probes([], _timeout_ms) do
    {:ok, []}
  end

  defp collect_probes(probes, timeout_ms) do
    max_response_bytes =
      Application.get_env(
        :exocomp_node,
        :service_observe_max_response_bytes,
        @default_max_response_bytes
      )

    prober =
      Application.get_env(
        :exocomp_node,
        :service_observe_http_prober,
        &default_http_prober/3
      )

    per_probe_timeout = max(1000, div(timeout_ms, length(probes) + 1))

    probe_tasks =
      Enum.map(probes, fn %{"url" => url} ->
        Task.async(fn -> prober.(url, per_probe_timeout, max_response_bytes) end)
      end)

    yields = Task.yield_many(probe_tasks, timeout: timeout_ms)

    Enum.each(yields, fn {task, result} ->
      if result == nil, do: Task.shutdown(task, :brutal_kill)
    end)

    probe_results =
      Enum.map(yields, fn {_task, result} ->
        case result do
          {:ok, probe_result} -> probe_result
          nil -> {:error, "timeout"}
          {:exit, reason} -> {:error, inspect(reason)}
        end
      end)

    {:ok, probe_results}
  end

  defp default_systemd_collector(services) do
    Exocomp.Node.Collectors.Systemd.collect(allowed_services: services)
  end

  defp default_http_prober(url, timeout_ms, max_response_bytes) do
    Exocomp.Node.Collectors.HttpProbe.probe(url, timeout_ms: timeout_ms, max_response_bytes: max_response_bytes)
  end

  # ---------------------------------------------------------------------------
  # Artifact construction
  # ---------------------------------------------------------------------------

  defp build_artifact(started_at, systemd_obs, probe_obs, elapsed_us) do
    data = %{
      "schema_version" => "1",
      "skill" => "exocomp.service.observe",
      "observation_id" => generate_observation_id(),
      "started_at" => DateTime.to_iso8601(started_at),
      "elapsed_us" => elapsed_us,
      "systemd" => observation_to_serializable(systemd_obs),
      "probes" => Enum.map(probe_obs, &probe_to_serializable/1)
    }

    artifact = %Artifact{
      artifactId: generate_artifact_id(),
      name: "service-observe",
      parts: [%DataPart{data: data}]
    }

    {:ok, artifact}
  end

  defp observation_to_serializable(obs) when is_map(obs) do
    Map.new(obs, fn {k, v} ->
      {to_string(k), serialize_value(v)}
    end)
  end

  defp observation_to_serializable(other), do: %{"error" => inspect(other)}

  defp serialize_value(%{measurements: measurements} = obs) when is_map(measurements) do
    %{
      "observed_at" => obs[:observed_at] || obs["observed_at"],
      "source" => inspect(obs[:source] || obs["source"]),
      "collector_version" => obs[:collector_version] || obs["collector_version"],
      "duration_us" => obs[:duration_us] || obs["duration_us"],
      "measurements" => Map.new(measurements, fn {k, v} -> {to_string(k), v} end)
    }
  end

  defp serialize_value(v), do: v

  defp probe_to_serializable({:ok, status, response_time_ms, body_size}) do
    %{
      "status" => status,
      "response_time_ms" => response_time_ms,
      "body_size" => body_size
    }
  end

  defp probe_to_serializable({:error, reason}) do
    %{"error" => to_string(reason)}
  end

  defp generate_artifact_id do
    "service-observe-#{System.unique_integer([:positive, :monotonic])}"
  end

  defp generate_observation_id do
    :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
  end
end
